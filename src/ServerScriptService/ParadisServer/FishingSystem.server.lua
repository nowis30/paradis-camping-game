-- FishingSystem.server.lua

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")
local FishingGearConfig = require(ConfigFolder:WaitForChild("FishingGearConfig"))

-- Nom du dossier qui contient tes 5 spots dans Workspace
local FISHING_FOLDER_NAME = "FishingArea"

-- Animation IDs - Animations de pêche Roblox par défaut
local CAST_ANIMATION_ID = "rbxassetid://3541114300"   -- animation lancer la ligne
local REEL_ANIMATION_ID = "rbxassetid://3541114300"   -- animation remonter le poisson (même anim pour l'instant)

-- Types de poissons et récompenses
local fishTypes = {
    { name = "Common", reward = 10, weight = 50 },
    { name = "rare", reward = 25, weight = 35 },
    { name = "legendaire", reward = 100, weight = 15 },
}

-- Assure qu'on a leaderstats.Money pour un joueur
-- Utilise le service d’économie central pour ajouter du cash
local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local EconomyService = shared.ParadisEconomyService or waitForShared("ParadisEconomyService")
local FishingShopService = waitForShared("ParadisFishingShopService")
local PlayerProgressService = shared.PlayerProgressService or waitForShared("PlayerProgressService")

-- Joue une animation sur le personnage (si un ID est fourni)
local function playAnimation(character, animationId)
    if not animationId or animationId == "" then
        return nil
    end

    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animationId

    local track = humanoid:LoadAnimation(anim)
    track:Play()
    return track
end

-- Petit texte au-dessus de la tête du joueur (style Money GUI)
local function showFloatingText(character, text)
    if not character then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(4, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 24
    label.TextColor3 = Color3.fromRGB(150, 240, 150)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Text = text
    label.Parent = billboard

    Debris:AddItem(billboard, 2.5)
end

-- Empêche un joueur de lancer 40 pêches en même temps
local activeFishing = {} -- [player] = true pendant la pêche

-- Création ou clonage d'un modèle de poisson depuis ReplicatedStorage/FishModels
local FISH_MODELS_ROOT = "FishModels"
local fishModelMap = {
    ["Common"] = "Common",
    ["rare"] = "Rare",
    ["legendaire"] = "Legendaire",
}

local function pickModelFromFolder(folder)
    if not folder then return nil end
    local modelCandidates = {}
    local partCandidates = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            table.insert(modelCandidates, child)
        elseif child:IsA("Folder") then
            -- Cherche d'abord un Model
            local m = child:FindFirstChildWhichIsA("Model")
            if m then
                table.insert(modelCandidates, m)
            end
            -- Sinon, accepte un BasePart/MeshPart à l'intérieur
            local p = child:FindFirstChildWhichIsA("BasePart", true)
            if p then
                table.insert(partCandidates, p)
            end
        elseif child:IsA("BasePart") then
            table.insert(partCandidates, child)
        end
    end
    if #modelCandidates > 0 then
        return modelCandidates[math.random(1, #modelCandidates)]
    end
    if #partCandidates > 0 then
        return partCandidates[math.random(1, #partCandidates)]
    end
    return nil
end

local function getFishModelsRoot()
    local replicated = game:GetService("ReplicatedStorage")
    local root = replicated:FindFirstChild(FISH_MODELS_ROOT)
    if root then return root end
    local ok, waited = pcall(function()
        return replicated:WaitForChild(FISH_MODELS_ROOT, 3)
    end)
    if ok then return waited end
    return nil
end

local function createFishVisual(fishInfo)
    print("[FishingSystem] Création visuelle pour:", fishInfo.name)
    local root = getFishModelsRoot()
    if not root then
        warn("[FishingSystem] ❌ Dossier FishModels introuvable après attente !")
    else
        print("[FishingSystem] ✅ FishModels disponible")
    end
    
    local groupName = fishModelMap[fishInfo.name]
    print("[FishingSystem] Recherche du dossier:", groupName)
    local groupFolder = root and root:FindFirstChild(groupName)
    -- Recherche insensible à la casse si non trouvé exactement
    if root and not groupFolder then
        for _, child in ipairs(root:GetChildren()) do
            if string.lower(child.Name) == string.lower(groupName) then
                groupFolder = child
                break
            end
        end
    end
    if root and not groupFolder then
        -- Essayer une attente courte si la réplication du dossier est tardive
        local ok, gf = pcall(function()
            return root:WaitForChild(groupName, 1)
        end)
        if ok then groupFolder = gf end
    end
    if not groupFolder and root then
        warn("[FishingSystem] ❌ Dossier", groupName, "introuvable (après retry). Contenu de FishModels:")
        for _, child in ipairs(root:GetChildren()) do
            warn("  -", child.Name, "(", child.ClassName, ")")
        end
    elseif groupFolder then
        print("[FishingSystem] ✅ Dossier prêt:", groupFolder.Name, "—", #groupFolder:GetChildren(), "enfants")
    end
    
    local template = pickModelFromFolder(groupFolder)
    if template then
        print("[FishingSystem] ✅ Modèle sélectionné:", template.Name)
        local clone
        if template:IsA("Model") then
            clone = template:Clone()
        else
            -- Si c'est un MeshPart/BasePart, l'envelopper dans un Model
            local partClone = template:Clone()
            clone = Instance.new("Model")
            clone.Name = template.Name .. "_Model"
            partClone.Anchored = true
            partClone.CanCollide = false
            partClone.Parent = clone
            clone.PrimaryPart = partClone
        end
        -- Assurer une PrimaryPart, y compris si les pièces sont imbriquées (recherche récursive)
        if not clone.PrimaryPart then
            local primary = clone:FindFirstChildWhichIsA("BasePart", true)
            if primary then
                clone.PrimaryPart = primary
            else
                warn("[FishingSystem] ⚠️ Aucun BasePart trouvé dans le modèle:", clone.Name, "— création d'un Root invisible")
                local root = Instance.new("Part")
                root.Name = "Root"
                root.Size = Vector3.new(1, 1, 1)
                root.Transparency = 1
                root.Anchored = true
                root.CanCollide = false
                root.Parent = clone
                clone.PrimaryPart = root
            end
        end
        -- Rendre toutes les parties non collidables pour l’animation de sortie
        for _, desc in ipairs(clone:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored = true
                desc.CanCollide = false
            end
        end
        -- Effets brillants si légendaire
        if fishInfo.name == "legendaire" then
            for _, part in ipairs(clone:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Neon
                    part.Color = Color3.fromRGB(255, 215, 80)
                end
            end
            if clone.PrimaryPart then
                local glow = Instance.new("PointLight")
                glow.Range = 12
                glow.Brightness = 2.5
                glow.Color = Color3.fromRGB(255, 230, 120)
                glow.Parent = clone.PrimaryPart
                local sparkle = Instance.new("ParticleEmitter")
                sparkle.Texture = "rbxassetid://258128463"
                sparkle.Rate = 18
                sparkle.Lifetime = NumberRange.new(0.5, 1)
                sparkle.Speed = NumberRange.new(0.2, 0.6)
                sparkle.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.25),
                    NumberSequenceKeypoint.new(0.5, 0.35),
                    NumberSequenceKeypoint.new(1, 0)
                })
                sparkle.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.05),
                    NumberSequenceKeypoint.new(0.8, 0.4),
                    NumberSequenceKeypoint.new(1, 1)
                })
                sparkle.Parent = clone.PrimaryPart
            end
        end
        return clone, 1
    end
    -- Fallback procédural si aucun modèle
    warn("[FishingSystem] ⚠️ Utilisation du fallback procédural pour:", fishInfo.name)
    local sizeScale
    local color
    if fishInfo.name == "Common" then
        sizeScale = 1.0
        color = Color3.fromRGB(180, 200, 220)
    elseif fishInfo.name == "rare" then
        sizeScale = 1.4
        color = Color3.fromRGB(255, 165, 80)
    else
        sizeScale = 2.2
        color = Color3.fromRGB(255, 215, 0)
    end

    local model = Instance.new("Model")
    model.Name = "FishVisual"

    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(1.6 * sizeScale, 0.8 * sizeScale, 0.9 * sizeScale)
    body.Material = Enum.Material.SmoothPlastic
    body.Color = color
    body.Anchored = true
    body.CanCollide = false
    body.Parent = model
    if fishInfo.name == "legendaire" then
        body.Material = Enum.Material.Neon
        body.Color = Color3.fromRGB(255, 215, 80)
        local glow = Instance.new("PointLight")
        glow.Range = 12
        glow.Brightness = 2.5
        glow.Color = body.Color
        glow.Parent = body
        local sparkle = Instance.new("ParticleEmitter")
        sparkle.Texture = "rbxassetid://258128463"
        sparkle.Rate = 16
        sparkle.Lifetime = NumberRange.new(0.5, 0.9)
        sparkle.Speed = NumberRange.new(0.3, 0.7)
        sparkle.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.22),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0)
        })
        sparkle.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(0.7, 0.45),
            NumberSequenceKeypoint.new(1, 1)
        })
        sparkle.Parent = body
    end

    local tail = Instance.new("WedgePart")
    tail.Name = "Tail"
    tail.Size = Vector3.new(0.8 * sizeScale, 0.6 * sizeScale, 0.2 * sizeScale)
    tail.Material = Enum.Material.SmoothPlastic
    tail.Color = color:Lerp(Color3.fromRGB(250, 250, 250), 0.2)
    tail.Anchored = true
    tail.CanCollide = false
    tail.Parent = model

    local finTop = Instance.new("WedgePart")
    finTop.Name = "TopFin"
    finTop.Size = Vector3.new(0.5 * sizeScale, 0.3 * sizeScale, 0.2 * sizeScale)
    finTop.Material = Enum.Material.SmoothPlastic
    finTop.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.3)
    finTop.Anchored = true
    finTop.CanCollide = false
    finTop.Parent = model

    local finBottom = Instance.new("WedgePart")
    finBottom.Name = "BottomFin"
    finBottom.Size = Vector3.new(0.5 * sizeScale, 0.3 * sizeScale, 0.2 * sizeScale)
    finBottom.Material = Enum.Material.SmoothPlastic
    finBottom.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.3)
    finBottom.Anchored = true
    finBottom.CanCollide = false
    finBottom.Parent = model

    model.PrimaryPart = body
    return model, sizeScale
end

local function positionFishParts(model)
    local body = model:FindFirstChild("Body")
    local tail = model:FindFirstChild("Tail")
    local finTop = model:FindFirstChild("TopFin")
    local finBottom = model:FindFirstChild("BottomFin")
    if not body then return end
    local cf = body.CFrame
    if tail then tail.CFrame = cf * CFrame.new(0.9, 0, 0) end
    if finTop then finTop.CFrame = cf * CFrame.new(0, 0.4, 0) end
    if finBottom then finBottom.CFrame = cf * CFrame.new(0, -0.35, 0) end
end

local function startFishing(player)
    if activeFishing[player] then
        return
    end
    activeFishing[player] = true

    local character = player.Character
    if not character then
        activeFishing[player] = nil
        return
    end

    -- Création visuelle de la canne à pêche (couleur selon le niveau)
    local fishingRod = Instance.new("Tool")
    fishingRod.Name = "CannePeche"
    fishingRod.RequiresHandle = true
    fishingRod.CanBeDropped = false
    fishingRod.Grip = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)
    
    -- Manche de la canne (partie basse)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2, 3, 0.2)
    handle.Material = Enum.Material.Wood
    -- Couleur par défaut (Basic) avant application réelle
    handle.Color = Color3.fromRGB(101, 67, 33)
    handle.Parent = fishingRod
    
    -- Partie haute de la canne (plus fine)
    local rodTop = Instance.new("Part")
    rodTop.Name = "RodTop"
    rodTop.Size = Vector3.new(0.15, 2.5, 0.15)
    rodTop.Material = Enum.Material.SmoothPlastic
    rodTop.Color = Color3.fromRGB(150, 150, 150)
    rodTop.CanCollide = false
    rodTop.Parent = fishingRod
    
    local weld1 = Instance.new("WeldConstraint")
    weld1.Part0 = handle
    weld1.Part1 = rodTop
    weld1.Parent = rodTop
    
    rodTop.CFrame = handle.CFrame * CFrame.new(0, 2.75, 0)
    
    -- Moulinet
    local reel = Instance.new("Part")
    reel.Name = "Reel"
    reel.Size = Vector3.new(0.4, 0.4, 0.4)
    reel.Shape = Enum.PartType.Cylinder
    reel.Material = Enum.Material.Metal
    reel.Color = Color3.fromRGB(192, 192, 192)
    reel.CanCollide = false
    reel.Parent = fishingRod
    
    local weld2 = Instance.new("WeldConstraint")
    weld2.Part0 = handle
    weld2.Part1 = reel
    weld2.Parent = reel
    
    reel.CFrame = handle.CFrame * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90))
    
    fishingRod.Parent = character
    character.Humanoid:EquipTool(fishingRod)

    -- Appliquer la couleur spécifique de la canne choisie (après Equip pour éviter latence)
    local gearForColor = FishingShopService.GetPlayerGear(player.UserId)
    local rodDefColor = FishingGearConfig.Rods[gearForColor.CurrentRod]
    if rodDefColor and rodDefColor.Color then
        local col = rodDefColor.Color
        -- Appliquer sur toutes les parties (on laisse le moulinet métallique mais on peut teinter légèrement)
        handle.Color = col
        rodTop.Color = col:lerp(Color3.new(1,1,1), 0.25) -- partie haute légèrement éclaircie
        -- Moulinet : conserver métal, option : teinte légère
        reel.Color = col:lerp(Color3.fromRGB(192,192,192), 0.6)
    end

    -- Effets spéciaux pour canne Master brillante
    if rodDefColor and rodDefColor.Shiny then
        -- Ajuster dimensions
        handle.Size = Vector3.new(0.25, 3.3, 0.25)
        rodTop.Size = Vector3.new(0.18, 3.1, 0.18)
        rodTop.Material = Enum.Material.Neon
        -- Lumière
        local light = Instance.new("PointLight")
        light.Name = "MasterGlow"
        light.Range = 10
        light.Brightness = 2.2
        light.Color = rodTop.Color
        light.Parent = rodTop
        -- Particules scintillantes
        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Name = "MasterSparkle"
        sparkles.LightEmission = 0.7
        sparkles.Texture = "rbxassetid://258128463"
        sparkles.Rate = 12
        sparkles.Lifetime = NumberRange.new(0.4, 0.8)
        sparkles.Speed = NumberRange.new(0.5, 1.2)
        sparkles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(0.4, 0.25),
            NumberSequenceKeypoint.new(1, 0)
        })
        sparkles.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.8, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        })
        sparkles.Parent = rodTop
    end

    -- Animation de lancer
    local castTrack = playAnimation(character, CAST_ANIMATION_ID)
    task.wait(1.2)

    -- Récupérer l'équipement du joueur pour le temps d'attente
    local gear = FishingShopService.GetPlayerGear(player.UserId)
    local rodDef = FishingGearConfig.Rods[gear.CurrentRod] or FishingGearConfig.Rods.Basic
    
    -- Temps d'attente modifié par la canne (1.5 à 3.5 secondes * speedMultiplier)
    local baseWaitTime = math.random(15, 35) / 10
    local waitTime = baseWaitTime * rodDef.SpeedMultiplier
    task.wait(waitTime)
    
    local baitDef = FishingGearConfig.Baits[gear.CurrentBait] or FishingGearConfig.Baits.None
    
    -- Consommer un appât si utilisé
    if gear.CurrentBait ~= "None" and gear.BaitUses > 0 then
        FishingShopService.ConsumeBait(player.UserId)
    end
    
    -- Calculer les chances avec bonus de canne et appât
    local legendaryChance = rodDef.LegendaryChance + baitDef.LegendaryBoost
    local rareBonus = rodDef.RareBonus
    
    -- Déterminer le type de poisson avec chances modifiées
    local fishInfo
    local roll = math.random(1, 100)
    
    if roll <= (legendaryChance * 100) then
        -- Légendaire
        fishInfo = fishTypes[3]
    elseif roll <= (legendaryChance * 100 + 35 + rareBonus) then
        -- Rare
        fishInfo = fishTypes[2]
    else
        -- Common
        fishInfo = fishTypes[1]
    end
    
    -- Appliquer multiplicateur de récompense de l'appât
    local reward = math.floor(fishInfo.reward * baitDef.RewardMultiplier)

    -- ===== MINI-JEU DE TENSION DE LIGNE (côté client) =====
    local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
    local startMiniGameEvent = remotesFolder:WaitForChild("StartFishingMiniGame")
    local resultEvent = remotesFolder:WaitForChild("FishingMiniGameResult")
    
    -- Envoie au client pour démarrer le mini-jeu
    startMiniGameEvent:FireClient(player, fishInfo.name)
    
    -- Attente du résultat (timeout 60s)
    local miniGameSuccess = false
    local resultReceived = false
    
    local connection
    connection = resultEvent.OnServerEvent:Connect(function(plr, success)
        if plr == player and not resultReceived then
            resultReceived = true
            miniGameSuccess = success
            connection:Disconnect()
        end
    end)
    
    local timeoutTask = task.delay(60, function()
        if not resultReceived then
            resultReceived = true
            miniGameSuccess = false
            connection:Disconnect()
        end
    end)
    
    -- Attend résultat
    while not resultReceived do
        task.wait(0.1)
    end
    
    if not miniGameSuccess then
        -- Échec du mini-jeu : ligne cassée, pas de poisson
        if castTrack then castTrack:Stop() end
        if fishingRod and fishingRod.Parent then
            fishingRod:Destroy()
        end
        activeFishing[player] = nil
        showFloatingText(character, "💔 La ligne a cassé!")
        return
    end
    
    -- Incrémente les stats de pêche pour les achievements
    if PlayerProgressService then
        PlayerProgressService.IncrementStat(player, "FishCaught", 1)
        
        if fishInfo.name == "legendaire" then
            PlayerProgressService.IncrementStat(player, "LegendaryFishCaught", 1)
        elseif fishInfo.name == "rare" then
            PlayerProgressService.IncrementStat(player, "RareFishCaught", 1)
        end
    end
    
    -- Animation de remonter avec effet visuel du poisson
    local reelTrack = playAnimation(character, REEL_ANIMATION_ID)
    task.wait(0.5)
    
    -- Crée un poisson visuel "réaliste" sortant de l'eau
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        if fishingRod then fishingRod:Destroy() end
        activeFishing[player] = nil
        return
    end
    
    local fishModel, scale = createFishVisual(fishInfo)
    local body = fishModel.PrimaryPart
    
    -- Trouver la surface de l'eau (lac généré)
    local lake
    local terrainFolder = workspace:FindFirstChild("CampingTerrain")
    if terrainFolder then
        lake = terrainFolder:FindFirstChild("Lake")
    end
    lake = lake or workspace:FindFirstChild("Lake")

    local surfaceY
    if lake and lake:IsA("BasePart") then
        surfaceY = lake.Position.Y + (lake.Size.Y / 2)
    else
        surfaceY = hrp.Position.Y - 2 -- fallback
    end

    -- Point d’émergence devant le joueur, à la surface de l’eau
    local emergePos = (hrp.CFrame * CFrame.new(0, 0, -6)).Position
    emergePos = Vector3.new(emergePos.X, surfaceY - 0.8, emergePos.Z)
    body.CFrame = CFrame.new(emergePos) * CFrame.Angles(0, math.rad(180), 0)
    fishModel.Parent = workspace
    positionFishParts(fishModel)

    -- Effet d’éclaboussure
    local splash = Instance.new("ParticleEmitter")
    splash.Texture = "rbxassetid://241876227"
    splash.Speed = NumberRange.new(6, 10)
    splash.Lifetime = NumberRange.new(0.3, 0.7)
    splash.Rate = 150
    splash.EmissionDirection = Enum.NormalId.Top
    splash.Parent = body
    
    -- Tween d’émergence (monte puis arc vers le joueur)
    local infoRise = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local targetRise = { CFrame = body.CFrame * CFrame.new(0, 2.2, 0) }
    local tweenRise = TweenService:Create(body, infoRise, targetRise)
    tweenRise:Play()
    tweenRise.Completed:Wait()

    positionFishParts(fishModel)
    local infoArc = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local arcTargetPos = (hrp.CFrame * CFrame.new(0, 2.5, -2)).Position
    local tweenArc = TweenService:Create(body, infoArc, { CFrame = CFrame.new(arcTargetPos) * CFrame.Angles(0, math.rad(160), 0) })
    tweenArc:Play()
    tweenArc.Completed:Wait()
    positionFishParts(fishModel)

    -- Arrêt des particules
    splash.Enabled = false
    Debris:AddItem(splash, 1)

    -- Donne l'argent au joueur via le service d'économie (met à jour le GUI Cash)
    EconomyService.AddCash(player, reward)
    
    -- Ajouter le poisson à l'inventaire pour utilisation future comme appât
    local fishCount = FishingShopService.AddFishToInventory(player.UserId, fishInfo.name)

    -- Feedback visuel
    local message = string.format("%s (+%d$) [%d en stock]", fishInfo.name, reward, fishCount)
    showFloatingText(character, message)
    
    -- Nettoyage
    fishModel:Destroy()
    
    task.wait(0.5)
    
    if castTrack then castTrack:Stop() end
    if reelTrack then reelTrack:Stop() end
    
    if fishingRod and fishingRod.Parent then
        fishingRod:Destroy()
    end

    activeFishing[player] = nil
end

-- Ajoute leaderstats/Money pour les nouveaux joueurs
-- La création des leaderstats (Cash/Income) est gérée par EconomyService

-- Ajoute un ProximityPrompt "Pêcher" à chaque spot dans Workspace.FishingSpots
local function setupFishingSpots()
    local fishingFolder = workspace:FindFirstChild(FISHING_FOLDER_NAME)
    if not fishingFolder then
        print("[FishingSystem] Dossier '" .. FISHING_FOLDER_NAME .. "' introuvable, attente...")
        fishingFolder = workspace:WaitForChild(FISHING_FOLDER_NAME, 10)
        if not fishingFolder then
            print("[FishingSystem] Création du dossier '" .. FISHING_FOLDER_NAME .. "' vide.")
            fishingFolder = Instance.new("Folder")
            fishingFolder.Name = FISHING_FOLDER_NAME
            fishingFolder.Parent = workspace
        end
    end

    for _, spot in ipairs(fishingFolder:GetChildren()) do
        if spot:IsA("Model") or spot:IsA("BasePart") then
            local targetPart
            if spot:IsA("BasePart") then
                targetPart = spot
            else
                targetPart = spot.PrimaryPart or spot:FindFirstChildWhichIsA("BasePart")
            end

            if targetPart then
                local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")
                if not prompt then
                    prompt = Instance.new("ProximityPrompt")
                    prompt.ObjectText = "Pêche"
                    prompt.ActionText = "Pêcher"
                    prompt.HoldDuration = 0.5
                    prompt.MaxActivationDistance = 10
                    prompt.Parent = targetPart
                end

                prompt.Triggered:Connect(function(player)
                    startFishing(player)
                end)
            else
                warn("Impossible de trouver une partie cible pour un spot de pêche: " .. spot.Name)
            end
        end
    end
end

setupFishingSpots()
