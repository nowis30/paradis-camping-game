-- ProShopClient.client.lua
-- Interface utilisateur pour la boutique ProShop

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ProShopConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ProShopConfig"))
local FishingGearConfig = nil
local FishingShopRemotes = nil

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local requestPurchaseFunc = remotesFolder:WaitForChild("RequestProShopPurchase")
local getDataFunc = remotesFolder:WaitForChild("GetProShopData")
local purchaseResultEvent = remotesFolder:WaitForChild("ProShopPurchaseResult")
local refreshEvent = remotesFolder:WaitForChild("ProShopRefresh")
local magicLogExpiredEvent = remotesFolder:WaitForChild("MagicLogExpired")

-- Remotes karts
local kartRemotesFolder = ReplicatedStorage:WaitForChild("GolfKartRemotes")
local RequestKartPurchase = kartRemotesFolder:WaitForChild("RequestKartPurchase")
local RequestKartSpawn = kartRemotesFolder:WaitForChild("RequestKartSpawn")
local RequestKartDespawn = kartRemotesFolder:WaitForChild("RequestKartDespawn")
local RequestKartUpgrade = kartRemotesFolder:WaitForChild("RequestKartUpgrade")
local NotifyKartStatus = kartRemotesFolder:WaitForChild("NotifyKartStatus")

-- État de l'UI
local isShopOpen = false
local shopGui
local shopData
local gearSummaryLabel

-- Configuration karts
local KART_COST = 200
local UPGRADE_COST = 150
local KART_UPGRADES = {
	{id = "engine", name = "Moteur", icon = "⚙️", desc = "Vitesse maximale"},
	{id = "battery", name = "Batterie", icon = "🔋", desc = "Accélération"},
	{id = "tires", name = "Pneus", icon = "🛞", desc = "Adhérence"}
}

-- Création de l'UI
local function createShopUI()
	-- ScreenGui principal
	shopGui = Instance.new("ScreenGui")
	shopGui.Name = "ProShopGui"
	shopGui.ResetOnSpawn = false
	shopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	shopGui.Enabled = false
	
	-- Frame de fond semi-transparent
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = shopGui
	
	-- Frame principale de la boutique
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.92, 0, 0.85, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = backdrop
	
	-- Corner arrondi
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Titre
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -55, 0, 42)
	title.Position = UDim2.new(0, 12, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "🏪 ProShop - Boutique"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainFrame
	
	-- Bouton fermer
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 38, 0, 38)
	closeButton.Position = UDim2.new(1, -44, 0, 8)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextScaled = true
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Text = "✕"
	closeButton.Parent = mainFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	-- Affichage argent du joueur
	local moneyDisplay = Instance.new("TextLabel")
	moneyDisplay.Name = "MoneyDisplay"
	moneyDisplay.Size = UDim2.new(0.42, 0, 0, 28)
	moneyDisplay.Position = UDim2.new(0, 12, 0, 54)
	moneyDisplay.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	moneyDisplay.Font = Enum.Font.Gotham
	moneyDisplay.TextScaled = true
	moneyDisplay.TextColor3 = Color3.fromRGB(255, 215, 0)
	moneyDisplay.Text = "💰 Argent: 0"
	moneyDisplay.Parent = mainFrame
	
	local moneyCorner = Instance.new("UICorner")
	moneyCorner.CornerRadius = UDim.new(0, 6)
	moneyCorner.Parent = moneyDisplay

	-- Résumé équipement pêche (canne/appât)
	gearSummaryLabel = Instance.new("TextLabel")
	gearSummaryLabel.Name = "GearSummary"
	gearSummaryLabel.Size = UDim2.new(1, -24, 0, 18)
	gearSummaryLabel.Position = UDim2.new(0, 12, 0, 86)
	gearSummaryLabel.BackgroundTransparency = 1
	gearSummaryLabel.Font = Enum.Font.Gotham
	gearSummaryLabel.TextScaled = true
	gearSummaryLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
	gearSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	gearSummaryLabel.Text = "🎣 Canne: ? | 🪱 Appât: ?"
	gearSummaryLabel.Parent = mainFrame
	
	-- Affichage bûches magiques
	local magicLogsDisplay = Instance.new("TextLabel")
	magicLogsDisplay.Name = "MagicLogsDisplay"
	magicLogsDisplay.Size = UDim2.new(0.5, 0, 0, 28)
	magicLogsDisplay.Position = UDim2.new(0.46, 0, 0, 54)
	magicLogsDisplay.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	magicLogsDisplay.Font = Enum.Font.Gotham
	magicLogsDisplay.TextScaled = true
	magicLogsDisplay.TextColor3 = Color3.fromRGB(138, 43, 226)
	magicLogsDisplay.Text = "✨ Bûches magiques: 0"
	magicLogsDisplay.Parent = mainFrame
	
	local magicCorner = Instance.new("UICorner")
	magicCorner.CornerRadius = UDim.new(0, 6)
	magicCorner.Parent = magicLogsDisplay
	
	-- ScrollingFrame pour les produits
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ProductsScroll"
	scrollFrame.Size = UDim2.new(1, -24, 1, -120)
	scrollFrame.Position = UDim2.new(0, 12, 0, 108)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 10
	scrollFrame.Parent = mainFrame
	
	-- Layout pour les produits
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = scrollFrame
	
	-- Connexion du bouton fermer
	closeButton.MouseButton1Click:Connect(function()
		closeShop()
	end)
	
	shopGui.Parent = playerGui
	
	return mainFrame
end

-- Créer une carte produit
local function createProductCard(product, parent, shopData)
	local card = Instance.new("Frame")
	card.Name = "ProductCard_" .. product.Id
	card.Size = UDim2.new(1, 0, 0, 75)
	card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 0
	card.Parent = parent
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card
	
	-- Icône
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 32
	icon.Text = product.Icon
	icon.Parent = card
	
	-- Nom et description
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 300, 0, 25)
	nameLabel.Position = UDim2.new(0, 80, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = product.Name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card
	
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0, 300, 0, 20)
	descLabel.Position = UDim2.new(0, 80, 0, 40)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.Text = product.Description
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = card
	
	-- Bouton achat
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0, 120, 0, 50)
	buyButton.Position = UDim2.new(1, -130, 0.5, 0)
	buyButton.AnchorPoint = Vector2.new(0, 0.5)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 16
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.Text = "💰 " .. product.Price
	buyButton.Parent = card
	
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton
	
	-- Vérifier si le joueur peut acheter
	local canAfford = shopData.playerMoney >= product.Price
	local alreadyOwned = false
	
	if product.ProductType == ProShopConfig.ProductTypes.AXE then
		alreadyOwned = shopData.playerAxePower >= product.AxePower
	end
	
	if alreadyOwned then
		buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		buyButton.Text = "✓ Possédé"
		buyButton.Active = false
	elseif not canAfford then
		buyButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		buyButton.Active = true
	end
	
	-- Connexion achat
	buyButton.MouseButton1Click:Connect(function()
		if alreadyOwned then return end
		
		buyButton.Text = "..."
		local result = requestPurchaseFunc:InvokeServer(product.Id)
		
		if result.success then
			-- Rafraîchir la boutique
			task.wait(0.5)
			refreshShop()
		else
			buyButton.Text = "💰 " .. product.Price
		end
	end)
	
	return card
end

-- Section header
local function addSectionHeader(parent, text)
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -10, 0, 28)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 20
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = Color3.fromRGB(255, 220, 120)
	header.Text = text
	header.Parent = parent
	return header
end

-- Créer carte achat kart
local function createKartPurchaseCard(parent)
	local card = Instance.new("Frame")
	card.Name = "KartPurchaseCard"
	card.Size = UDim2.new(1, 0, 0, 140)
	card.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
	card.BorderSizePixel = 0
	card.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card
	
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 80, 0, 80)
	icon.Position = UDim2.new(0, 10, 0, 30)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 48
	icon.Text = "🏎️"
	icon.Parent = card
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -110, 0, 25)
	title.Position = UDim2.new(0, 100, 0, 15)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Text = "Kart de Golf"
	title.TextColor3 = Color3.fromRGB(100, 200, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card
	
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -110, 0, 45)
	desc.Position = UDim2.new(0, 100, 0, 42)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.Gotham
	desc.TextScaled = true
	desc.Text = "Transmission 5 vitesses • Zones RPM\nCourses drag avec récompenses"
	desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Parent = card
	
	local price = Instance.new("TextLabel")
	price.Size = UDim2.new(0, 100, 0, 22)
	price.Position = UDim2.new(0, 100, 0, 92)
	price.BackgroundTransparency = 1
	price.Font = Enum.Font.GothamBold
	price.TextScaled = true
	price.Text = KART_COST .. "$"
	price.TextColor3 = Color3.fromRGB(100, 255, 100)
	price.TextXAlignment = Enum.TextXAlignment.Left
	price.Parent = card
	
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 110, 0, 38)
	buyBtn.Position = UDim2.new(1, -120, 0, 92)
	buyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextScaled = true
	buyBtn.Text = "ACHETER"
	buyBtn.TextColor3 = Color3.new(1, 1, 1)
	buyBtn.BorderSizePixel = 0
	buyBtn.Parent = card
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = buyBtn
	
	buyBtn.Activated:Connect(function()
		RequestKartPurchase:FireServer()
	end)
	
	return card
end

-- Créer carte upgrade kart
local function createKartUpgradeCard(upgradeData, parent)
	local card = Instance.new("Frame")
	card.Name = "KartUpgrade_" .. upgradeData.id
	card.Size = UDim2.new(1, 0, 0, 85)
	card.BackgroundColor3 = Color3.fromRGB(60, 65, 75)
	card.BorderSizePixel = 0
	card.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card
	
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextScaled = true
	icon.Text = upgradeData.icon
	icon.Parent = card
	
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0, 140, 0, 22)
	name.Position = UDim2.new(0, 70, 0, 15)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.Text = upgradeData.name
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = card
	
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -80, 0, 18)
	desc.Position = UDim2.new(0, 70, 0, 40)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.Gotham
	desc.TextScaled = true
	desc.Text = upgradeData.desc
	desc.TextColor3 = Color3.fromRGB(180, 180, 180)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = card
	
	local price = Instance.new("TextLabel")
	price.Size = UDim2.new(0, 90, 0, 18)
	price.Position = UDim2.new(0, 70, 0, 60)
	price.BackgroundTransparency = 1
	price.Font = Enum.Font.GothamBold
	price.TextScaled = true
	price.Text = UPGRADE_COST .. "$ /niv"
	price.TextColor3 = Color3.fromRGB(100, 255, 100)
	price.TextXAlignment = Enum.TextXAlignment.Left
	price.Parent = card
	
	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Size = UDim2.new(0, 95, 0, 32)
	upgradeBtn.Position = UDim2.new(1, -105, 0.5, 0)
	upgradeBtn.AnchorPoint = Vector2.new(0, 0.5)
	upgradeBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	upgradeBtn.Font = Enum.Font.GothamBold
	upgradeBtn.TextScaled = true
	upgradeBtn.Text = "AMÉLIORER"
	upgradeBtn.TextColor3 = Color3.new(1, 1, 1)
	upgradeBtn.BorderSizePixel = 0
	upgradeBtn.Parent = card
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = upgradeBtn
	
	upgradeBtn.Activated:Connect(function()
		RequestKartUpgrade:FireServer({type = upgradeData.id, levels = 1})
	end)
	
	return card
end

-- Créer carte actions kart
local function createKartActionsCard(parent)
	local card = Instance.new("Frame")
	card.Name = "KartActions"
	card.Size = UDim2.new(1, 0, 0, 75)
	card.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
	card.BorderSizePixel = 0
	card.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card
	
	local spawnBtn = Instance.new("TextButton")
	spawnBtn.Size = UDim2.new(0.48, 0, 0, 50)
	spawnBtn.Position = UDim2.new(0.01, 0, 0.5, 0)
	spawnBtn.AnchorPoint = Vector2.new(0, 0.5)
	spawnBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	spawnBtn.Font = Enum.Font.GothamBold
	spawnBtn.TextScaled = true
	spawnBtn.Text = "🚗 SORTIR"
	spawnBtn.TextColor3 = Color3.new(1, 1, 1)
	spawnBtn.BorderSizePixel = 0
	spawnBtn.Parent = card
	
	local spawnCorner = Instance.new("UICorner")
	spawnCorner.CornerRadius = UDim.new(0, 8)
	spawnCorner.Parent = spawnBtn
	
	spawnBtn.Activated:Connect(function()
		RequestKartSpawn:FireServer()
	end)
	
	local despawnBtn = Instance.new("TextButton")
	despawnBtn.Size = UDim2.new(0.48, 0, 0, 50)
	despawnBtn.Position = UDim2.new(0.51, 0, 0.5, 0)
	despawnBtn.AnchorPoint = Vector2.new(0, 0.5)
	despawnBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	despawnBtn.Font = Enum.Font.GothamBold
	despawnBtn.TextScaled = true
	despawnBtn.Text = "📦 RANGER"
	despawnBtn.TextColor3 = Color3.new(1, 1, 1)
	despawnBtn.BorderSizePixel = 0
	despawnBtn.Parent = card
	
	local despawnCorner = Instance.new("UICorner")
	despawnCorner.CornerRadius = UDim.new(0, 8)
	despawnCorner.Parent = despawnBtn
	
	despawnBtn.Activated:Connect(function()
		RequestKartDespawn:FireServer()
	end)
	
	return card
end

-- Carte canne à pêche
local function createRodCard(rodId, rodDef, parent, gear)
	local card = Instance.new("Frame")
	card.Name = "RodCard_" .. rodId
	card.Size = UDim2.new(1, 0, 0, 80)
	card.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 26
	icon.Text = "🎣"
	icon.TextColor3 = rodDef.Color or Color3.fromRGB(200,200,200)
	icon.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 320, 0, 24)
	nameLabel.Position = UDim2.new(0, 80, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
	nameLabel.Text = rodDef.DisplayName
	nameLabel.Parent = card

	local stats = string.format("Vitesse x%.1f | Légendaire +%d%% | Rare +%d", 1/rodDef.SpeedMultiplier, math.floor((rodDef.LegendaryChance or 0)*100), rodDef.RareBonus or 0)
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0, 360, 0, 20)
	descLabel.Position = UDim2.new(0, 80, 0, 40)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextColor3 = Color3.fromRGB(200,200,200)
	descLabel.Text = stats
	descLabel.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 140, 0, 44)
	btn.Position = UDim2.new(1, -150, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0, 0.5)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Parent = card

	local owned = (gear.OwnedRods and gear.OwnedRods[rodId]) == true
	local isCurrent = gear.CurrentRod == rodId
	if isCurrent then
		btn.BackgroundColor3 = Color3.fromRGB(90, 140, 90)
		btn.Text = "✓ Équipée"
		btn.Active = false
	elseif owned then
		btn.BackgroundColor3 = Color3.fromRGB(80, 120, 180)
		btn.Text = "Équiper"
		btn.Active = true
		btn.MouseButton1Click:Connect(function()
			if FishingShopRemotes and FishingShopRemotes.SetCurrentRod then
				FishingShopRemotes.SetCurrentRod:FireServer(rodId)
				task.wait(0.3)
				refreshShop()
			end
		end)
	else
		if rodDef.RobuxPrice and rodDef.RobuxPrice > 0 then
			btn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
			btn.Text = "🔶 " .. tostring(rodDef.RobuxPrice) .. " R$"
		else
			btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			btn.Text = "💰 " .. tostring(rodDef.Cost or 0)
		end
		btn.Active = true
		btn.MouseButton1Click:Connect(function()
			if rodDef.RobuxPrice and rodDef.RobuxPrice > 0 then
				warn("[ProShopClient] Achat Robux non implémenté pour:", rodId)
				return
			end
			if FishingShopRemotes then
				FishingShopRemotes.BuyRod:FireServer(rodId)
				task.wait(0.3)
				refreshShop()
			end
		end)
	end

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	return card
end

-- Carte appât
local function createBaitCard(baitId, baitDef, parent, gear)
	local card = Instance.new("Frame")
	card.Name = "BaitCard_" .. baitId
	card.Size = UDim2.new(1, 0, 0, 80)
	card.BackgroundColor3 = Color3.fromRGB(55, 50, 60)
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 26
	icon.Text = "🪱"
	icon.TextColor3 = Color3.fromRGB(255, 220, 100)
	icon.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 320, 0, 24)
	nameLabel.Position = UDim2.new(0, 80, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
	nameLabel.Text = baitDef.DisplayName
	nameLabel.Parent = card

	local stats = string.format("Récompense x%.1f | Légendaire +%d%% | %d utilisations", baitDef.RewardMultiplier or 1, math.floor((baitDef.LegendaryBoost or 0)*100), baitDef.UsesPerPurchase or 0)
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0, 360, 0, 20)
	descLabel.Position = UDim2.new(0, 80, 0, 40)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextColor3 = Color3.fromRGB(200,200,200)
	descLabel.Text = stats
	descLabel.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 140, 0, 44)
	btn.Position = UDim2.new(1, -150, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0, 0.5)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Parent = card

	local isFishBait = baitDef.RequiredFish ~= nil
	local fishCount = 0
	if isFishBait and gear.FishInventory then
		fishCount = gear.FishInventory[baitDef.RequiredFish] or 0
	end

	if baitId == "None" then
		btn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
		btn.Text = "Gratuit"
		btn.Active = false
	elseif isFishBait then
		if fishCount > 0 then
			btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
			btn.Text = string.format("Utiliser (🐟 x%d)", fishCount)
			btn.Active = true
			btn.MouseButton1Click:Connect(function()
				FishingShopRemotes.UseFishAsBait:FireServer(baitDef.RequiredFish)
				task.wait(0.2)
				refreshShop()
			end)
		else
			btn.BackgroundColor3 = Color3.fromRGB(160, 80, 80)
			btn.Text = "Pas de poisson"
			btn.Active = false
		end
	else
		btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		btn.Text = "💰 " .. tostring(baitDef.Cost or 0)
		btn.Active = true
		btn.MouseButton1Click:Connect(function()
			FishingShopRemotes.BuyBait:FireServer(baitId)
			task.wait(0.2)
			refreshShop()
		end)
	end

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	return card
end

-- Rafraîchir la boutique
function refreshShop()
	if not isShopOpen then return end
	
	shopData = getDataFunc:InvokeServer()

	-- Charger configs/Remotes pêche si pas faits
	if not FishingGearConfig then
		local ok1, mod = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("FishingGearConfig"))
		end)
		if ok1 then FishingGearConfig = mod end
	end
	if not FishingShopRemotes then
		local ok2, mod2 = pcall(function()
			return require(remotesFolder:WaitForChild("FishingShopRemotes"))
		end)
		if ok2 then FishingShopRemotes = mod2 end
	end

	local currentGear = {CurrentRod = "?", CurrentBait = "?", BaitUses = 0, OwnedRods = {}, FishInventory = {}}
	if FishingShopRemotes and FishingShopRemotes.GetGear then
		local ok3, result = pcall(function()
			return FishingShopRemotes.GetGear:InvokeServer()
		end)
		if ok3 and result then
			currentGear = result
		end
	end
	
	-- Mettre à jour l'affichage argent
	local moneyDisplay = shopGui.Backdrop.MainFrame:FindFirstChild("MoneyDisplay")
	if moneyDisplay then
		moneyDisplay.Text = "💰 Argent: " .. shopData.playerMoney
	end
	
	-- Mettre à jour l'affichage bûches magiques
	local magicDisplay = shopGui.Backdrop.MainFrame:FindFirstChild("MagicLogsDisplay")
	if magicDisplay then
		local expiryText = ""
		if shopData.magicLogExpiry and shopData.playerMagicLogs > 0 then
			local timeLeft = math.floor((shopData.magicLogExpiry - tick()) / 3600)
			expiryText = string.format(" (%dh restantes)", math.max(0, timeLeft))
		end
		magicDisplay.Text = "✨ Bûches magiques: " .. shopData.playerMagicLogs .. expiryText
	end
	
	-- Recréer les cartes produits
	local scrollFrame = shopGui.Backdrop.MainFrame:FindFirstChild("ProductsScroll")
	if scrollFrame then
		-- Supprimer anciennes cartes
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
			if child:IsA("TextLabel") and child.Name == "SectionHeader" then
				child:Destroy()
			end
		end
		
		-- Créer nouvelles cartes
		for _, product in ipairs(ProShopConfig.Products) do
			createProductCard(product, scrollFrame, shopData)
		end

		-- Section Karts de Golf
		local kartHeader = addSectionHeader(scrollFrame, "🏎️ Karts de Golf")
		kartHeader.Name = "SectionHeader"
		createKartPurchaseCard(scrollFrame)
		
		-- Upgrades kart
		local upgradeHeader = addSectionHeader(scrollFrame, "⚡ Améliorations Kart")
		upgradeHeader.Name = "SectionHeader"
		for _, upgrade in ipairs(KART_UPGRADES) do
			createKartUpgradeCard(upgrade, scrollFrame)
		end
		
		-- Actions kart
		local actionHeader = addSectionHeader(scrollFrame, "🚗 Actions Kart")
		actionHeader.Name = "SectionHeader"
		createKartActionsCard(scrollFrame)

		-- Section cannes à pêche
		if FishingGearConfig then
			local headerR = addSectionHeader(scrollFrame, "🎣 Cannes à pêche")
			headerR.Name = "SectionHeader"
			-- Trier par coût
			local rodsList = {}
			for id, def in pairs(FishingGearConfig.Rods) do
				table.insert(rodsList, {id = id, def = def})
			end
			table.sort(rodsList, function(a,b) return (a.def.Cost or 0) < (b.def.Cost or 0) end)
			for _, item in ipairs(rodsList) do
				createRodCard(item.id, item.def, scrollFrame, currentGear)
			end

			-- Section appâts
			local headerB = addSectionHeader(scrollFrame, "🪱 Appâts")
			headerB.Name = "SectionHeader"
			local baitsList = {}
			for id, def in pairs(FishingGearConfig.Baits) do
				table.insert(baitsList, {id = id, def = def})
			end
			table.sort(baitsList, function(a,b) return (a.def.Cost or 0) < (b.def.Cost or 0) end)
			for _, item in ipairs(baitsList) do
				createBaitCard(item.id, item.def, scrollFrame, currentGear)
			end
		end
		
		-- Ajuster taille du scroll
		local listLayout = scrollFrame:FindFirstChildOfClass("UIListLayout")
		if listLayout then
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
		end
	end

	-- Mettre à jour le résumé équipement pêche
	if gearSummaryLabel then
		local rodName = tostring(currentGear.CurrentRod or "?")
		if FishingGearConfig and FishingGearConfig.Rods and FishingGearConfig.Rods[currentGear.CurrentRod] then
			rodName = FishingGearConfig.Rods[currentGear.CurrentRod].DisplayName or rodName
		end
		local baitName = tostring(currentGear.CurrentBait or "?")
		if FishingGearConfig and FishingGearConfig.Baits and FishingGearConfig.Baits[currentGear.CurrentBait] then
			baitName = FishingGearConfig.Baits[currentGear.CurrentBait].DisplayName or baitName
		end
		local uses = tonumber(currentGear.BaitUses or 0) or 0
		gearSummaryLabel.Text = string.format("🎣 Canne: %s | 🪱 Appât: %s (%d)", rodName, baitName, uses)
	end
end

-- Ouvrir la boutique
function openShop()
	if isShopOpen then return end
	
	isShopOpen = true
	
	if not shopGui then
		createShopUI()
	end
	
	shopGui.Enabled = true
	refreshShop()
end

-- Fermer la boutique
function closeShop()
	if not isShopOpen then return end
	
	isShopOpen = false
	if shopGui then
		shopGui.Enabled = false
	end
end

-- Écouter les résultats d'achat
purchaseResultEvent.OnClientEvent:Connect(function(result)
	if result.success then
		-- Afficher message de succès
		local notif = Instance.new("ScreenGui")
		notif.ResetOnSpawn = false
		notif.Parent = playerGui
		
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 300, 0, 60)
		frame.Position = UDim2.new(0.5, 0, 0.1, 0)
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		frame.Parent = notif
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 1, -20)
		label.Position = UDim2.new(0, 10, 0, 10)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 18
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = result.message
		label.TextWrapped = true
		label.Parent = frame
		
		task.delay(3, function()
			notif:Destroy()
		end)
	else
		-- Afficher message d'erreur
		warn("[ProShopClient] Achat échoué:", result.message)
	end
end)

-- Écouter l'expiration des bûches magiques
magicLogExpiredEvent.OnClientEvent:Connect(function()
	local notif = Instance.new("ScreenGui")
	notif.ResetOnSpawn = false
	notif.Parent = playerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 60)
	frame.Position = UDim2.new(0.5, 0, 0.1, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
	frame.Parent = notif
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, -20)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = "⏰ Vos bûches magiques ont expiré!"
	label.TextWrapped = true
	label.Parent = frame
	
	task.delay(4, function()
		notif:Destroy()
	end)
	
	if isShopOpen then
		refreshShop()
	end
end)

-- Touche pour ouvrir/fermer la boutique (P)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	
	if input.KeyCode == Enum.KeyCode.P then
		if isShopOpen then
			closeShop()
		else
			openShop()
		end
	end
end)

print("[ProShopClient] Client initialisé - Appuyez sur P pour ouvrir la boutique")

-- Exposer une fonction globale pour ouvrir depuis d'autres scripts (ex: prompt ProShop)
shared.ParadisOpenProShop = openShop
shared.ParadisCloseProShop = closeShop

-- Nettoyage de toute ancienne UI d'amélioration de hache si encore présente en Studio
task.defer(function()
	local pg = playerGui
	local old = pg:FindFirstChild("AxeUpgradeGui")
	if old then
		old:Destroy()
	end
	-- Supprime les anciens panneaux "UpgradeBillboard" sur la hache
	local function cleanTool(container)
		if not container then return end
		for _, child in ipairs(container:GetDescendants()) do
			if child:IsA("BillboardGui") and child.Name == "UpgradeBillboard" then
				child:Destroy()
			end
		end
	end
	cleanTool(player.Character)
	cleanTool(player:FindFirstChild("Backpack"))
	player.CharacterAdded:Connect(function(char)
		cleanTool(char)
	end)
end)
