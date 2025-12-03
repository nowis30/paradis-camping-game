-- CampingProgressionUI.lua
-- Interface client pour acheter et améliorer les objets de camping

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Config et remotes
local CampingItemsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CampingItemsConfig"))
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local campingRemote = remotesFolder:WaitForChild("CampingProgressionRemote")

-- UI principale
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CampingProgressionUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Bouton pour ouvrir/fermer le menu
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 120, 0, 50)
toggleButton.Position = UDim2.new(1, -130, 0.5, -100)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 120, 180)
toggleButton.BorderSizePixel = 0
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "🏕️ Camping"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextSize = 18
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = toggleButton

-- Frame principale (cachée par défaut)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 500)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 15)
mainCorner.Parent = mainFrame

-- Header
local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(40, 120, 180)
header.BorderSizePixel = 0
header.Font = Enum.Font.GothamBold
header.Text = "🏕️ Amélioration du Camping"
header.TextColor3 = Color3.new(1, 1, 1)
header.TextSize = 24
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 15)
headerCorner.Parent = header

-- Bouton fermer
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 20
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- ScrollingFrame pour les catégories d'objets
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = mainFrame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 10)
scrollLayout.Parent = scrollFrame

-- Fonction pour créer une carte d'objet
local function createItemCard(itemData)
	local card = Instance.new("Frame")
	card.Name = itemData.Id
	card.Size = UDim2.new(1, -10, 0, 120)
	card.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	card.BorderSizePixel = 0
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card
	
	-- Nom de l'objet
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 300, 0, 30)
	nameLabel.Position = UDim2.new(0, 15, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = itemData.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	nameLabel.TextSize = 20
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card
	
	-- Niveau
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0, 100, 0, 25)
	levelLabel.Position = UDim2.new(0, 15, 0, 45)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.Text = "Niveau " .. itemData.Level
	levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	levelLabel.TextSize = 16
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = card
	
	-- Revenu
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(0, 250, 0, 25)
	incomeLabel.Position = UDim2.new(0, 15, 0, 70)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.Text = "💰 Revenu: +" .. itemData.BaseIncome .. " $/tick"
	incomeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	incomeLabel.TextSize = 16
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.Parent = card
	
	-- Coût
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Size = UDim2.new(0, 200, 0, 25)
	costLabel.Position = UDim2.new(0, 15, 0, 92)
	costLabel.BackgroundTransparency = 1
	costLabel.Font = Enum.Font.Gotham
	costLabel.Text = "💵 Coût: " .. itemData.Cost .. " $"
	costLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	costLabel.TextSize = 16
	costLabel.TextXAlignment = Enum.TextXAlignment.Left
	costLabel.Parent = card
	
	-- Prérequis
	local prereqLabel = Instance.new("TextLabel")
	prereqLabel.Name = "PrereqLabel"
	prereqLabel.Size = UDim2.new(0.5, -100, 0, 60)
	prereqLabel.Position = UDim2.new(0, 280, 0, 45)
	prereqLabel.BackgroundTransparency = 1
	prereqLabel.Font = Enum.Font.Gotham
	prereqLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	prereqLabel.TextSize = 14
	prereqLabel.TextXAlignment = Enum.TextXAlignment.Left
	prereqLabel.TextYAlignment = Enum.TextYAlignment.Top
	prereqLabel.TextWrapped = true
	prereqLabel.Parent = card
	
	local prereqText = "🔓 Prérequis:\n"
	if itemData.Prerequisites.MinCash and itemData.Prerequisites.MinCash > 0 then
		prereqText = prereqText .. "• " .. itemData.Prerequisites.MinCash .. " $ minimum\n"
	end
	if itemData.Prerequisites.Achievements and #itemData.Prerequisites.Achievements > 0 then
		for _, achId in ipairs(itemData.Prerequisites.Achievements) do
			local achInfo = CampingItemsConfig.Achievements[achId]
			prereqText = prereqText .. "• " .. (achInfo and achInfo.DisplayName or achId) .. "\n"
		end
	end
	if prereqText == "🔓 Prérequis:\n" then
		prereqText = prereqText .. "Aucun"
	end
	prereqLabel.Text = prereqText
	
	-- Bouton acheter
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0, 120, 0, 40)
	buyButton.Position = UDim2.new(1, -135, 0.5, -20)
	buyButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	buyButton.BorderSizePixel = 0
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Text = "ACHETER"
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.TextSize = 18
	buyButton.Parent = card
	
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton
	
	-- Action du bouton
	buyButton.MouseButton1Click:Connect(function()
		campingRemote:FireServer("PurchaseItem", itemData.Id)
		buyButton.Text = "⏳ Achat..."
		buyButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
		task.wait(1)
		buyButton.Text = "ACHETER"
		buyButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	end)
	
	return card
end

-- Fonction pour créer une section de catégorie
local function createCategorySection(categoryName, items)
	local section = Instance.new("Frame")
	section.Name = categoryName
	section.Size = UDim2.new(1, 0, 0, 50)
	section.BackgroundColor3 = Color3.fromRGB(50, 130, 200)
	section.BorderSizePixel = 0
	section.AutomaticSize = Enum.AutomaticSize.Y
	
	local sectionCorner = Instance.new("UICorner")
	sectionCorner.CornerRadius = UDim.new(0, 10)
	sectionCorner.Parent = section
	
	-- Titre de catégorie
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 0, 40)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "📦 " .. categoryName
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 22
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = section
	
	-- Container pour les items
	local itemsContainer = Instance.new("Frame")
	itemsContainer.Name = "ItemsContainer"
	itemsContainer.Size = UDim2.new(1, -10, 0, 0)
	itemsContainer.Position = UDim2.new(0, 5, 0, 50)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.AutomaticSize = Enum.AutomaticSize.Y
	itemsContainer.Parent = section
	
	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	itemsLayout.Padding = UDim.new(0, 8)
	itemsLayout.Parent = itemsContainer
	
	-- Ajouter les items
	for _, itemData in ipairs(items) do
		local card = createItemCard(itemData)
		card.Parent = itemsContainer
	end
	
	return section
end

-- Initialiser l'UI avec toutes les catégories
local function initializeUI()
	-- Organiser les items par catégorie
	local categories = {}
	for _, itemData in pairs(CampingItemsConfig.Items) do
		local catName = itemData.Category
		if not categories[catName] then
			categories[catName] = {}
		end
		table.insert(categories[catName], itemData)
	end
	
	-- Trier les items par niveau dans chaque catégorie
	for catName, items in pairs(categories) do
		table.sort(items, function(a, b)
			return a.Level < b.Level
		end)
	end
	
	-- Créer les sections dans l'ordre
	local orderedCategories = {"Trailer", "BBQ", "PicnicTable", "Campfire", "TreesDecor", "DecorRock"}
	for _, catName in ipairs(orderedCategories) do
		if categories[catName] then
			local section = createCategorySection(catName, categories[catName])
			section.Parent = scrollFrame
		end
	end
	
	-- Ajuster la taille du scroll
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 10)
	scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- Toggle l'UI
local function toggleUI()
	mainFrame.Visible = not mainFrame.Visible
end

toggleButton.MouseButton1Click:Connect(toggleUI)
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Initialiser
initializeUI()

print("[CampingProgressionUI] Interface initialisée")
