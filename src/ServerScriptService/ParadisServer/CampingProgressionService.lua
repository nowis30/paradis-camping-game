--[[
    CampingProgressionService.lua
    Gère les achats/upgrades d'objets de camping et l'income automatique
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Attendre les services nécessaires
local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local PlayerProgressService = waitForShared("PlayerProgressService")
local EconomyService = shared.ParadisEconomyService or waitForShared("ParadisEconomyService")
local PlotService = shared.ParadisPlotService or waitForShared("ParadisPlotService")

local CampingItemsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CampingItemsConfig"))

-- Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local campingProgressionRemote = remotesFolder:FindFirstChild("CampingProgressionRemote")
if not campingProgressionRemote then
    campingProgressionRemote = Instance.new("RemoteEvent")
    campingProgressionRemote.Name = "CampingProgressionRemote"
    campingProgressionRemote.Parent = remotesFolder
end

local CampingProgressionService = {}

-- ============ INITIALISATION DES OBJETS DE DÉPART ============

function CampingProgressionService.InitializePlayerObjects(player)
    print("[CampingProgression] 🔄 Début initialisation pour", player.Name)
    
    -- Attendre que le joueur ait une parcelle
    local plot = PlotService.GetPlotForPlayer(player)
    if not plot then
        print("[CampingProgression] ⏳ Attente de la parcelle pour", player.Name)
        task.wait(1)
        plot = PlotService.GetPlotForPlayer(player)
        if not plot then
            warn("[CampingProgression] ❌ Parcelle introuvable pour", player.Name)
            return
        end
    end
    
    print("[CampingProgression] ✓ Parcelle trouvée:", plot.Id, "pour", player.Name)
    
    -- Récupérer tous les objets possédés
    local ownedItems = PlayerProgressService.GetAllOwnedItems(player)
    if not ownedItems then
        warn("[CampingProgression] ❌ OwnedItems introuvable pour", player.Name)
        return
    end
    
    print("[CampingProgression] ✓ OwnedItems récupérés:", #ownedItems, "objets pour", player.Name)
    print("[CampingProgression] 🏭 Initialisation des objets pour", player.Name)
    
    -- Placer chaque objet possédé
    local placedCount = 0
    for category, itemId in pairs(ownedItems) do
        print("[CampingProgression] 📦 Tentative placement:", itemId, "dans catégorie", category)
        local itemData = CampingItemsConfig.Items[itemId]
        if itemData then
            local success = updateItemOnPlot(player, itemData)
            if success then
                placedCount = placedCount + 1
                print("[CampingProgression] ✅", itemData.DisplayName, "placé pour", player.Name)
            else
                warn("[CampingProgression] ⚠️ Échec placement de", itemData.DisplayName)
            end
        else
            warn("[CampingProgression] ❌ ItemData introuvable pour", itemId)
        end
    end
    
    print(string.format("[CampingProgression] ✅ Objets initialisés pour %s: %d/%d placés", player.Name, placedCount, #ownedItems))
end

-- ============ VÉRIFICATIONS ============

local function canAffordItem(player, itemData)
    local cash = EconomyService.GetCash and EconomyService.GetCash(player) or 0
    return cash >= itemData.Cost
end

local function hasAllAchievements(player, requiredAchievements)
    for _, achievementId in ipairs(requiredAchievements) do
        if not PlayerProgressService.HasAchievement(player, achievementId) then
            return false, achievementId
        end
    end
    return true
end

local function meetsPrerequisites(player, itemData)
    -- Vérifier le cash minimum
    local cash = EconomyService.GetCash and EconomyService.GetCash(player) or 0
    if cash < itemData.Prerequisites.MinCash then
        return false, string.format("Argent minimum requis: %d$", itemData.Prerequisites.MinCash)
    end
    
    -- Vérifier les achievements
    local hasAchievements, missingAchievement = hasAllAchievements(player, itemData.Prerequisites.Achievements)
    if not hasAchievements then
        return false, string.format("Achievement requis: %s", missingAchievement or "inconnu")
    end
    
    return true
end

-- ============ PLACEMENT VISUEL ============

local function getPlaceholderModel(itemData)
    local model = Instance.new("Model")
    model.Name = itemData.Id .. "_Placeholder"
    
    local part = Instance.new("Part")
    part.Name = "Root"
    part.Size = Vector3.new(4, 4, 4)
    part.Color = Color3.fromRGB(150, 150, 150)
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = true
    part.Parent = model
    
    -- BillboardGui avec le nom
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = itemData.DisplayName
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    model.PrimaryPart = part
    return model
end

local function getModelForItem(itemData)
    -- Chercher d'abord dans AmenagementCamping (priorité)
    local amenagementCamping = ReplicatedStorage:FindFirstChild("AmenagementCamping")
    if amenagementCamping then
        local model = amenagementCamping:FindFirstChild(itemData.ModelName)
        if model and model:IsA("Model") then
            print("[CampingProgression] ✓ Modèle trouvé:", itemData.ModelName, "dans AmenagementCamping")
            return model:Clone()
        end
    end
    
    -- Fallback: chercher dans ConstructionObjet
    local constructionObjet = ReplicatedStorage:FindFirstChild("ConstructionObjet")
    if constructionObjet then
        local model = constructionObjet:FindFirstChild(itemData.ModelName)
        if model and model:IsA("Model") then
            print("[CampingProgression] ✓ Modèle trouvé:", itemData.ModelName, "dans ConstructionObjet")
            return model:Clone()
        end
    end
    
    -- Fallback: créer un placeholder
    warn(string.format("[CampingProgression] ⚠️ Modèle introuvable: %s, utilisation placeholder", itemData.ModelName))
    return getPlaceholderModel(itemData)
end

local function updateItemOnPlot(player, itemData)
    local plot = PlotService.GetPlotForPlayer(player)
    if not plot then
        warn("[CampingProgression] Parcelle introuvable pour", player.Name)
        return false
    end
    
    local container = plot.Container
    if not container then
        warn("[CampingProgression] Container introuvable pour parcelle", plot.Id)
        return false
    end
    
    -- Trouver le dossier CampsiteObjects (créé par CampsiteDefaultsService)
    local campsiteObjects = container:FindFirstChild("CampsiteObjects")
    if not campsiteObjects then
        warn("[CampingProgression] CampsiteObjects introuvable, création...")
        campsiteObjects = Instance.new("Folder")
        campsiteObjects.Name = "CampsiteObjects"
        campsiteObjects.Parent = container
    end
    
    -- Déterminer la position du slot
    local category = itemData.Category
    local categoryInfo = CampingItemsConfig.Categories[category]
    if not categoryInfo then
        warn("[CampingProgression] Catégorie inconnue:", category)
        return false
    end
    
    -- Supprimer l'ancien objet de cette catégorie
    for _, child in ipairs(campsiteObjects:GetChildren()) do
        if child:GetAttribute("CampsiteObjectId") == category then
            child:Destroy()
        end
    end
    
    -- Créer le nouveau modèle
    local model = getModelForItem(itemData)
    if not model then
        return false
    end
    
    -- Positionner sur la parcelle
    local rootPart = plot.BasePart
    if not rootPart then
        warn("[CampingProgression] BasePart introuvable pour parcelle", plot.Id)
        return false
    end
    
    local offset = categoryInfo.DefaultOffset
    local targetCFrame = rootPart.CFrame * offset
    
    -- Ancrer toutes les parts
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = true
        end
    end
    
    -- Positionner le modèle
    if model.PrimaryPart then
        model:SetPrimaryPartCFrame(targetCFrame)
    else
        model:MoveTo(targetCFrame.Position)
    end
    
    -- Ajouter des attributs
    model:SetAttribute("CampsiteObjectId", category)
    model:SetAttribute("ItemId", itemData.Id)
    model:SetAttribute("ItemLevel", itemData.Level)
    model:SetAttribute("IsDefaultCampsiteObject", true)
    model:SetAttribute("IsLocked", false) -- Déverrouillé car possédé par le joueur
    model:SetAttribute("OwnerUserId", player.UserId)
    
    model.Parent = campsiteObjects
    
    print(string.format("[CampingProgression] ✅ Objet placé: %s pour %s", itemData.DisplayName, player.Name))
    return true
end

-- ============ ACHAT/UPGRADE ============

function CampingProgressionService.PurchaseItem(player, itemId)
    local itemData = CampingItemsConfig.GetItem(itemId)
    if not itemData then
        return false, "Objet inconnu"
    end
    
    -- Vérifier les prérequis
    local meetsPrerequis, prereqMessage = meetsPrerequisites(player, itemData)
    if not meetsPrerequis then
        return false, prereqMessage
    end
    
    -- Vérifier l'upgrade cohérent (doit posséder le niveau précédent)
    local currentItemId = PlayerProgressService.GetOwnedItem(player, itemData.Category)
    if itemData.Level > 1 then
        if not currentItemId then
            return false, "Vous devez d'abord acheter le niveau 1"
        end
        
        local currentItem = CampingItemsConfig.GetItem(currentItemId)
        if not currentItem or currentItem.Level ~= itemData.Level - 1 then
            return false, string.format("Vous devez d'abord avoir le niveau %d", itemData.Level - 1)
        end
    end
    
    -- Vérifier le cash
    if not canAffordItem(player, itemData) then
        return false, string.format("Pas assez d'argent (%d$ requis)", itemData.Cost)
    end
    
    -- Retirer le cash
    if EconomyService.AddCash then
        EconomyService.AddCash(player, -itemData.Cost)
    end
    
    -- Mettre à jour l'objet possédé
    PlayerProgressService.SetOwnedItem(player, itemData.Category, itemData.Id)
    
    -- Placer visuellement sur la parcelle
    updateItemOnPlot(player, itemData)
    
    print(string.format("[CampingProgression] ✅ %s a acheté: %s (-%d$)", player.Name, itemData.DisplayName, itemData.Cost))
    return true, string.format("Acheté: %s", itemData.DisplayName)
end

-- ============ REMOTE EVENT HANDLER ============

campingProgressionRemote.OnServerEvent:Connect(function(player, action, ...)
    if action == "PurchaseItem" then
        local itemId = ...
        local success, message = CampingProgressionService.PurchaseItem(player, itemId)
        
        -- Renvoyer le résultat au client (via autre remote si nécessaire)
        if success then
            print(string.format("[CampingProgression] ✅ Achat réussi pour %s", player.Name))
        else
            warn(string.format("[CampingProgression] ❌ Achat échoué pour %s: %s", player.Name, message))
        end
    end
end)

-- ============ VÉRIFICATION FEU DE CAMP ============

local function isCampfireActive()
    -- Chercher le feu de camp dans Workspace
    local campfire = game.Workspace:FindFirstChild("Campfire")
    if not campfire then
        return false -- Pas de feu = pas de revenu
    end
    
    local fireLevel = campfire:FindFirstChild("FireLevel")
    if not fireLevel or not fireLevel:IsA("NumberValue") then
        return false
    end
    
    -- Le feu est actif si le niveau est > 10 (seuil critique)
    return fireLevel.Value > 10
end

-- ============ INCOME AUTOMATIQUE ============

local INCOME_TICK_INTERVAL = 5 -- secondes entre chaque tick d'income

task.spawn(function()
    print("[CampingProgression] 🔥 Boucle de revenu TIC démarrée (intervalle:", INCOME_TICK_INTERVAL, "secondes)")
    while true do
        task.wait(INCOME_TICK_INTERVAL)
        
        -- Vérifier l'état du feu AVANT de distribuer les revenus
        local fireActive = isCampfireActive()
        print("[CampingProgression] 💰 Tick de revenu - Feu actif:", fireActive)
        
        for _, player in ipairs(Players:GetPlayers()) do
            local income = PlayerProgressService.GetTotalIncomePerTick(player)
            if income > 0 then
                if fireActive then
                    -- Feu actif → donner le revenu
                    if EconomyService.AddCash then
                        EconomyService.AddCash(player, income)
                        print(string.format("[CampingProgression] ✅ %s reçoit %d$ (revenu TIC)", player.Name, income))
                        
                        -- Notifier le client via RemoteEvent
                        local economyRemotes = remotesFolder:FindFirstChild("EconomyRemotes")
                        if economyRemotes then
                            local grantIncome = economyRemotes:FindFirstChild("GrantIncome")
                            if grantIncome and grantIncome:IsA("RemoteEvent") then
                                grantIncome:FireClient(player, income)
                            end
                        end
                    end
                else
                    -- Feu éteint → notifier le joueur
                    print(string.format("[CampingProgression] ⚠️ Feu éteint! Pas de revenu pour %s", player.Name))
                end
            end
        end
    end
end)

-- ============ INITIALISATION DES JOUEURS ============

-- Initialiser les objets pour les joueurs qui rejoignent
Players.PlayerAdded:Connect(function(player)
    -- Attendre que le joueur ait une parcelle (PlotService s'en occupe)
    task.spawn(function()
        -- Attendre un peu que PlotService attribue la parcelle
        task.wait(2)
        CampingProgressionService.InitializePlayerObjects(player)
    end)
end)

-- Initialiser pour les joueurs déjà présents
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        task.wait(2)
        CampingProgressionService.InitializePlayerObjects(player)
    end)
end

print("[CampingProgression] ✅ Service initialisé - Income tick:", INCOME_TICK_INTERVAL, "secondes")

shared.CampingProgressionService = CampingProgressionService
return CampingProgressionService
