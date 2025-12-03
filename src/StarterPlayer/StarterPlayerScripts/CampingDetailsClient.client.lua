--[[
    CampingDetailsClient.client.lua
    Gère l'interaction avec les pancartes des parcelles et affiche l'interface des détails
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Attendre les remotes
local CampingDetailsRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CampingDetailsRemotes"))
local GetCampingDetails = CampingDetailsRemotes.GetCampingDetails
local RequestPurchaseItem = CampingDetailsRemotes.RequestPurchaseItem
local CampingDetailsUpdated = CampingDetailsRemotes.CampingDetailsUpdated

-- Attendre la GUI
local campingDetailsGui = playerGui:WaitForChild("CampingDetailsGui")
local mainFrame = campingDetailsGui:WaitForChild("MainFrame")
local closeButton = mainFrame:WaitForChild("CloseButton")
local titleLabel = mainFrame:WaitForChild("TitleLabel")
local incomeLabel = mainFrame:WaitForChild("IncomeLabel")
local cashLabel = mainFrame:WaitForChild("CashLabel")
local ownedItemsFrame = mainFrame:WaitForChild("OwnedItemsFrame")
local upgradesFrame = mainFrame:WaitForChild("UpgradesFrame")
local statusLabel = mainFrame:WaitForChild("StatusLabel")

local currentCampingData = nil

-- Fonction pour créer un élément d'objet possédé
local function createOwnedItemElement(itemData)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = string.format("✅ %s (Niv. %d) - +%d $/tick", 
        itemData.DisplayName, 
        itemData.Level, 
        itemData.Income)
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(200, 255, 200)
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    return frame
end

-- Fonction pour créer un élément d'upgrade
local function createUpgradeElement(upgradeData)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 90)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    -- Titre de l'upgrade
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -100, 0, 20)
    titleLabel.Position = UDim2.new(0, 8, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = string.format("%s (Niv. %d)", upgradeData.DisplayName, upgradeData.Level)
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    -- Income de l'upgrade
    local incomeLabel = Instance.new("TextLabel")
    incomeLabel.Size = UDim2.new(1, -100, 0, 15)
    incomeLabel.Position = UDim2.new(0, 8, 0, 25)
    incomeLabel.BackgroundTransparency = 1
    incomeLabel.Text = string.format("💰 +%d $/tick", upgradeData.Income)
    incomeLabel.TextSize = 12
    incomeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    incomeLabel.Font = Enum.Font.Gotham
    incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    incomeLabel.Parent = frame
    
    -- Achievements requis
    local achievementsText = ""
    for i, achievement in ipairs(upgradeData.Achievements) do
        local icon = achievement.Completed and "✅" or "❌"
        achievementsText = achievementsText .. icon .. " " .. achievement.Name
        if i < #upgradeData.Achievements then
            achievementsText = achievementsText .. ", "
        end
    end
    
    local achievementsLabel = Instance.new("TextLabel")
    achievementsLabel.Size = UDim2.new(1, -100, 0, 15)
    achievementsLabel.Position = UDim2.new(0, 8, 0, 42)
    achievementsLabel.BackgroundTransparency = 1
    achievementsLabel.Text = achievementsText
    achievementsLabel.TextSize = 11
    achievementsLabel.TextColor3 = upgradeData.HasAllAchievements and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150)
    achievementsLabel.Font = Enum.Font.Gotham
    achievementsLabel.TextXAlignment = Enum.TextXAlignment.Left
    achievementsLabel.TextWrapped = true
    achievementsLabel.Parent = frame
    
    -- Coût
    local costLabel = Instance.new("TextLabel")
    costLabel.Size = UDim2.new(1, -100, 0, 15)
    costLabel.Position = UDim2.new(0, 8, 0, 60)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = string.format("💵 Coût : %d $", upgradeData.Cost)
    costLabel.TextSize = 12
    costLabel.TextColor3 = upgradeData.CanAfford and Color3.fromRGB(255, 255, 150) or Color3.fromRGB(255, 100, 100)
    costLabel.Font = Enum.Font.Gotham
    costLabel.TextXAlignment = Enum.TextXAlignment.Left
    costLabel.Parent = frame
    
    -- Bouton améliorer
    local buyButton = Instance.new("TextButton")
    buyButton.Size = UDim2.new(0, 80, 0, 30)
    buyButton.Position = UDim2.new(1, -88, 0, 30)
    buyButton.Text = "Améliorer"
    buyButton.TextSize = 13
    buyButton.Font = Enum.Font.GothamBold
    buyButton.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = buyButton
    
    -- Déterminer si le bouton est actif
    local canPurchase = upgradeData.CanAfford and upgradeData.HasAllAchievements
    
    if canPurchase then
        buyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        buyButton.MouseButton1Click:Connect(function()
            buyButton.Text = "..."
            buyButton.Enabled = false
            RequestPurchaseItem:FireServer(upgradeData.ItemId)
            
            -- Attendre un peu puis réactualiser
            task.wait(0.5)
            refreshCampingDetails()
        end)
    else
        buyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        buyButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        buyButton.Enabled = false
        
        if not upgradeData.HasAllAchievements then
            buyButton.Text = "🔒 Succès"
        elseif not upgradeData.CanAfford then
            buyButton.Text = "🔒 Argent"
        end
    end
    
    return frame
end

-- Fonction pour rafraîchir les détails du camping
function refreshCampingDetails()
    local success, campingData = pcall(function()
        return GetCampingDetails:InvokeServer()
    end)
    
    if not success or not campingData then
        statusLabel.Text = "❌ Erreur lors du chargement des données"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    currentCampingData = campingData
    
    -- Mettre à jour le titre
    titleLabel.Text = string.format("Camping de %s", campingData.PlayerName)
    
    -- Mettre à jour l'income
    incomeLabel.Text = string.format("💰 Revenue : +%d $ / tick", campingData.TotalIncome)
    
    -- Mettre à jour le cash
    cashLabel.Text = string.format("💵 Argent disponible : %d $", campingData.Cash)
    
    -- Nettoyer les anciennes listes
    for _, child in ipairs(ownedItemsFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for _, child in ipairs(upgradesFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Afficher les objets possédés
    if #campingData.OwnedItems == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 30)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "Aucun objet pour l'instant"
        emptyLabel.TextSize = 14
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.Font = Enum.Font.GothamItalic
        emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
        emptyLabel.Parent = ownedItemsFrame
    else
        for _, item in ipairs(campingData.OwnedItems) do
            local element = createOwnedItemElement(item)
            element.Parent = ownedItemsFrame
        end
    end
    
    -- Afficher les upgrades disponibles
    if #campingData.AvailableUpgrades == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 40)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "Aucune amélioration disponible\nVotre camping est au maximum !"
        emptyLabel.TextSize = 14
        emptyLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
        emptyLabel.Font = Enum.Font.GothamItalic
        emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
        emptyLabel.Parent = upgradesFrame
    else
        for _, upgrade in ipairs(campingData.AvailableUpgrades) do
            local element = createUpgradeElement(upgrade)
            element.Parent = upgradesFrame
        end
    end
    
    statusLabel.Text = ""
end

-- Fonction pour ouvrir la GUI
local function openCampingDetailsGui()
    campingDetailsGui.Enabled = true
    refreshCampingDetails()
end

-- Fonction pour fermer la GUI
local function closeCampingDetailsGui()
    campingDetailsGui.Enabled = false
    currentCampingData = nil
end

-- Connecter le bouton fermer
closeButton.MouseButton1Click:Connect(closeCampingDetailsGui)

-- Écouter les mises à jour du serveur
CampingDetailsUpdated.OnClientEvent:Connect(function()
    if campingDetailsGui.Enabled then
        refreshCampingDetails()
    end
end)

-- Fonction pour connecter les ProximityPrompts
local function connectProximityPrompts()
    local workspace = game:GetService("Workspace")
    
    -- Surveiller tous les ProximityPrompts dans le workspace
    local function onDescendantAdded(descendant)
        if descendant:IsA("ProximityPrompt") and descendant.Name == "CampingDetailsPrompt" then
            descendant.Triggered:Connect(function()
                openCampingDetailsGui()
            end)
        end
    end
    
    -- Connecter les prompts existants
    for _, descendant in ipairs(workspace:GetDescendants()) do
        onDescendantAdded(descendant)
    end
    
    -- Surveiller les nouveaux prompts
    workspace.DescendantAdded:Connect(onDescendantAdded)
end

-- Initialiser
connectProximityPrompts()

print("[CampingDetailsClient] ✅ Client initialisé")
