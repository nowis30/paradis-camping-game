--[[
    FishingShopClient
    Interface du Pro Shop pour acheter cannes et appâts
]]

print("[FishingShopClient] Script démarré!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("[FishingShopClient] Services chargés")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config", 10)
if not ConfigFolder then
    warn("[FishingShopClient] Config folder non trouvé!")
    return
end

local FishingGearConfig = require(ConfigFolder:WaitForChild("FishingGearConfig", 10))
if not FishingGearConfig then
    warn("[FishingShopClient] FishingGearConfig non trouvé!")
    return
end
print("[FishingShopClient] FishingGearConfig chargé")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not RemotesFolder then
    warn("[FishingShopClient] Remotes folder non trouvé!")
    return
end

local FishingShopRemotes = require(RemotesFolder:WaitForChild("FishingShopRemotes", 10))
if not FishingShopRemotes then
    warn("[FishingShopClient] FishingShopRemotes non trouvé!")
    return
end
print("[FishingShopClient] Remotes chargés")

-- Remotes de construction pour connaître l'état d'aménagement (build mode)
local BuildRemotes = require(RemotesFolder:WaitForChild("BuildRemotes", 10))
local buildModeActive = false
local proShopPrompts = {}

local function setShopActive(active)
    -- Active/Désactive les prompts et ferme le panneau si désactivé
    for _, prompt in ipairs(proShopPrompts) do
        if prompt and prompt.Parent then
            prompt.Enabled = active
        end
    end
    if not active then
        panel.Visible = false
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishingShopGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

-- Panel principal
local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.Size = UDim2.new(0.92, 0, 0.82, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

-- Titre
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 0, 42)
title.Position = UDim2.new(0, 8, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(100, 200, 255)
title.Text = "🎣 PRO SHOP - Équipement de pêche"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

-- Bouton fermer
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 38, 0, 38)
closeButton.Position = UDim2.new(1, -44, 0, 8)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeButton.Text = "✖"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextScaled = true
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- Section Cannes
local rodsSection = Instance.new("Frame")
rodsSection.Size = UDim2.new(0.48, 0, 1, -64)
rodsSection.Position = UDim2.new(0.01, 0, 0, 56)
rodsSection.BackgroundColor3 = Color3.fromRGB(30, 36, 46)
rodsSection.BorderSizePixel = 0
rodsSection.Parent = panel

local rodsSectionCorner = Instance.new("UICorner")
rodsSectionCorner.CornerRadius = UDim.new(0, 8)
rodsSectionCorner.Parent = rodsSection

local rodsTitle = Instance.new("TextLabel")
rodsTitle.Size = UDim2.new(1, -10, 0, 30)
rodsTitle.Position = UDim2.new(0, 5, 0, 4)
rodsTitle.BackgroundTransparency = 1
rodsTitle.Font = Enum.Font.GothamBold
rodsTitle.TextScaled = true
rodsTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
rodsTitle.Text = "🎣 Cannes à pêche"
rodsTitle.TextXAlignment = Enum.TextXAlignment.Left
rodsTitle.Parent = rodsSection

local rodsScroll = Instance.new("ScrollingFrame")
rodsScroll.Size = UDim2.new(1, -10, 1, -40)
rodsScroll.Position = UDim2.new(0, 5, 0, 36)
rodsScroll.BackgroundTransparency = 1
rodsScroll.BorderSizePixel = 0
rodsScroll.ScrollBarThickness = 8
rodsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
rodsScroll.Parent = rodsSection

local rodsLayout = Instance.new("UIListLayout")
rodsLayout.Padding = UDim.new(0, 8)
rodsLayout.Parent = rodsScroll

-- Section Appâts
local baitsSection = Instance.new("Frame")
baitsSection.Size = UDim2.new(0.48, 0, 0, 350)
baitsSection.Position = UDim2.new(0.51, 0, 0, 70)
baitsSection.BackgroundColor3 = Color3.fromRGB(30, 36, 46)
baitsSection.BorderSizePixel = 0
baitsSection.Parent = panel

local baitsSectionCorner = Instance.new("UICorner")
baitsSectionCorner.CornerRadius = UDim.new(0, 8)
baitsSectionCorner.Parent = baitsSection

local baitsTitle = Instance.new("TextLabel")
baitsTitle.Size = UDim2.new(1, -10, 0, 35)
baitsTitle.Position = UDim2.new(0, 5, 0, 5)
baitsTitle.BackgroundTransparency = 1
baitsTitle.Font = Enum.Font.GothamBold
baitsTitle.TextSize = 22
baitsTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
baitsTitle.Text = "🪱 Appâts"
baitsTitle.TextXAlignment = Enum.TextXAlignment.Left
baitsTitle.Parent = baitsSection

local baitsScroll = Instance.new("ScrollingFrame")
baitsScroll.Size = UDim2.new(1, -10, 1, -45)
baitsScroll.Position = UDim2.new(0, 5, 0, 40)
baitsScroll.BackgroundTransparency = 1
baitsScroll.BorderSizePixel = 0
baitsScroll.ScrollBarThickness = 6
baitsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
baitsScroll.Parent = baitsSection

local baitsLayout = Instance.new("UIListLayout")
baitsLayout.Padding = UDim.new(0, 8)
baitsLayout.Parent = baitsScroll

-- Status bar
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -20, 0, 60)
statusBar.Position = UDim2.new(0, 10, 1, -70)
statusBar.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
statusBar.BorderSizePixel = 0
statusBar.Parent = panel

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 1, 0)
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.TextSize = 18
statusLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Canne: Basic | Appât: Aucun (0 restant) | Cash: 0$"
statusLabel.Parent = statusBar

local currentGear = {
    CurrentRod = "Basic",
    CurrentBait = "Standard",
    BaitUses = 5,
    OwnedRods = {Basic = true},
    Cash = 0,
    FishInventory = {Common = 0, rare = 0, legendaire = 0},
}

local function updateStatusBar()
    local rodName = FishingGearConfig.Rods[currentGear.CurrentRod].DisplayName or currentGear.CurrentRod
    local baitName = FishingGearConfig.Baits[currentGear.CurrentBait].DisplayName or "Aucun"
    local inv = currentGear.FishInventory or {Common = 0, rare = 0, legendaire = 0}
    statusLabel.Text = string.format("🎣 Canne: %s | 🪱 Appât: %s (%d) | 🐟 Stock: C:%d R:%d L:%d | 💰 %d$", 
        rodName, baitName, currentGear.BaitUses, inv.Common or 0, inv.rare or 0, inv.legendaire or 0, currentGear.Cash)
end

local function refreshGear()
    local gear = FishingShopRemotes.GetGear:InvokeServer()
    if gear then
        currentGear = gear
        updateStatusBar()
        buildUI()
    end
end

local function createRodButton(rodId, rodDef)
    local owned = currentGear.OwnedRods[rodId] == true
    local isCurrent = currentGear.CurrentRod == rodId
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 100)
    btn.BackgroundColor3 = isCurrent and Color3.fromRGB(50, 120, 80) or Color3.fromRGB(50, 60, 70)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = not owned
    btn.Parent = rodsScroll
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 24)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = rodDef.DisplayName
    nameLabel.Parent = btn
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 16)
    descLabel.Position = UDim2.new(0, 5, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Text = rodDef.Description
    descLabel.Parent = btn
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -10, 0, 32)
    statsLabel.Position = UDim2.new(0, 5, 0, 48)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.GothamMedium
    statsLabel.TextSize = 13
    statsLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextWrapped = true
    statsLabel.Text = string.format("Vitesse: x%.1f | Légendaire: +%d%% | Bonus rare: +%d", 
        rodDef.SpeedMultiplier, rodDef.LegendaryChance * 100, rodDef.RareBonus)
    statsLabel.Parent = btn
    
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(0, 100, 0, 20)
    priceLabel.Position = UDim2.new(1, -105, 1, -25)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 16
    priceLabel.TextColor3 = owned and Color3.fromRGB(100, 255, 100) or (rodDef.RobuxPrice and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(255, 220, 80))
    priceLabel.TextXAlignment = Enum.TextXAlignment.Right
    if owned then
        priceLabel.Text = "✓ Possédée"
    elseif rodDef.RobuxPrice then
        priceLabel.Text = "🔶 " .. rodDef.RobuxPrice .. " R$"
    else
        priceLabel.Text = rodDef.Cost .. " $"
    end
    priceLabel.Parent = btn
    
    if not owned then
        btn.MouseButton1Click:Connect(function()
            if rodDef.RobuxPrice then
                warn("[FishingShopClient] Achat Robux pour Master: fonctionnalité à implémenter (Developer Product ID requis)")
                -- TODO: game:GetService("MarketplaceService"):PromptProductPurchase(LocalPlayer, MASTER_ROD_PRODUCT_ID)
            else
                FishingShopRemotes.BuyRod:FireServer(rodId)
                task.wait(0.2)
                refreshGear()
            end
        end)
    end
end

local function createBaitButton(baitId, baitDef)
    -- Vérifier si c'est un appât poisson et si le joueur en a en stock
    local isFishBait = baitDef.RequiredFish ~= nil
    local fishCount = 0
    if isFishBait and currentGear.FishInventory then
        fishCount = currentGear.FishInventory[baitDef.RequiredFish] or 0
    end
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 100)
    btn.BackgroundColor3 = Color3.fromRGB(50, 60, 70)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = baitsScroll
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 24)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = baitDef.DisplayName
    nameLabel.Parent = btn
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 16)
    descLabel.Position = UDim2.new(0, 5, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Text = baitDef.Description
    descLabel.Parent = btn
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -10, 0, 32)
    statsLabel.Position = UDim2.new(0, 5, 0, 48)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.GothamMedium
    statsLabel.TextSize = 13
    statsLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextWrapped = true
    statsLabel.Text = string.format("Récompense: x%.1f | Légendaire: +%d%% | %d utilisations", 
        baitDef.RewardMultiplier, baitDef.LegendaryBoost * 100, baitDef.UsesPerPurchase)
    statsLabel.Parent = btn
    
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(0, 120, 0, 20)
    priceLabel.Position = UDim2.new(1, -125, 1, -25)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 16
    priceLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    if isFishBait then
        if fishCount > 0 then
            priceLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            priceLabel.Text = string.format("🐟 Stock: %d", fishCount)
        else
            priceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            priceLabel.Text = "Aucun en stock"
            btn.AutoButtonColor = false
        end
    else
        priceLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
        priceLabel.Text = baitId == "None" and "Gratuit" or (baitDef.Cost .. " $")
    end
    priceLabel.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        if baitId == "None" then
            return
        end
        
        if isFishBait then
            -- Utiliser un poisson comme appât
            if fishCount > 0 then
                FishingShopRemotes.UseFishAsBait:FireServer(baitDef.RequiredFish)
                task.wait(0.2)
                refreshGear()
            end
        else
            -- Acheter un appât normal
            FishingShopRemotes.BuyBait:FireServer(baitId)
            task.wait(0.2)
            refreshGear()
        end
    end)
end

function buildUI()
    for _, child in ipairs(rodsScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, child in ipairs(baitsScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Créer boutons cannes triés par coût
    local rodsList = {}
    for id, def in pairs(FishingGearConfig.Rods) do
        table.insert(rodsList, {id = id, def = def})
    end
    table.sort(rodsList, function(a, b) return a.def.Cost < b.def.Cost end)
    
    for _, rod in ipairs(rodsList) do
        createRodButton(rod.id, rod.def)
    end
    
    -- Créer boutons appâts triés par coût
    local baitsList = {}
    for id, def in pairs(FishingGearConfig.Baits) do
        table.insert(baitsList, {id = id, def = def})
    end
    table.sort(baitsList, function(a, b) return a.def.Cost < b.def.Cost end)
    
    for _, bait in ipairs(baitsList) do
        createBaitButton(bait.id, bait.def)
    end
    
    rodsScroll.CanvasSize = UDim2.new(0, 0, 0, rodsLayout.AbsoluteContentSize.Y + 10)
    baitsScroll.CanvasSize = UDim2.new(0, 0, 0, baitsLayout.AbsoluteContentSize.Y + 10)
end

closeButton.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- Détecter les ProShop dans le workspace
local function setupProShop(proShop)
    -- Chercher une Part : d'abord PrimaryPart, sinon n'importe quelle BasePart
    local targetPart = proShop.PrimaryPart
    if not targetPart then
        -- Chercher récursivement dans le modèle
        for _, descendant in ipairs(proShop:GetDescendants()) do
            if descendant:IsA("BasePart") then
                targetPart = descendant
                break
            end
        end
    end
    
    if not targetPart then
        warn("[FishingShopClient] Aucune Part trouvée dans:", proShop.Name)
        return
    end
    
    local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Ouvrir le Pro Shop"
        prompt.ObjectText = "🎣 Pro Shop"
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 15
        prompt.RequiresLineOfSight = false
        prompt.Style = Enum.ProximityPromptStyle.Default
        prompt.Enabled = not buildModeActive
        prompt.Parent = targetPart
        print("[FishingShopClient] ProximityPrompt créé sur:", targetPart.Name, "dans", proShop.Name)
    else
        print("[FishingShopClient] ProximityPrompt existant trouvé sur:", targetPart.Name)
        prompt.Enabled = not buildModeActive
    end
    table.insert(proShopPrompts, prompt)
    
    prompt.Triggered:Connect(function(player)
        if player == LocalPlayer then
            print("[FishingShopClient] Pro Shop ouvert par:", player.Name)
            if shared.ParadisOpenProShop then
                shared.ParadisOpenProShop()
            else
                -- Fallback: ancienne UI (désactivée par défaut)
                panel.Visible = true
                refreshGear()
            end
        end
    end)
end

-- Fonction pour scanner le workspace et setup les ProShop
local function scanForProShops()
    local found = 0
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Model") and (descendant.Name == "ProShop" or descendant.Name == "Pro Shop" or descendant.Name == "ProShop_Cabin") then
            setupProShop(descendant)
            print("[FishingShopClient] Pro Shop trouvé:", descendant.Name)
            found = found + 1
        end
    end
    if found == 0 then
        warn("[FishingShopClient] Aucun Pro Shop trouvé dans le workspace!")
    end
    return found
end

-- Écouter les nouveaux ProShop
workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Model") and (descendant.Name == "ProShop" or descendant.Name == "Pro Shop" or descendant.Name == "ProShop_Cabin") then
        task.wait(0.1)
        setupProShop(descendant)
        print("[FishingShopClient] Nouveau Pro Shop détecté:", descendant.Name)
    end
end)

-- Attendre que le personnage soit chargé puis chercher les ProShop
local function initializeProShop()
    task.wait(2)
    print("[FishingShopClient] Scan du workspace pour les ProShop...")
    scanForProShops()
    refreshGear()
end

-- Démarrer l'initialisation
task.spawn(initializeProShop)

-- Re-scanner quand le personnage respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    scanForProShops()
end)

print("[Paradis][FishingShopClient] Interface Pro Shop chargée")

-- Écouter les changements de mode d'aménagement pour masquer la boutique
if BuildRemotes and BuildRemotes.ToggleBuildMode then
    BuildRemotes.ToggleBuildMode.OnClientEvent:Connect(function(state)
        buildModeActive = state and true or false
        setShopActive(not buildModeActive)
    end)
end
