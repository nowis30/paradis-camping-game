--[[
    InitGui.client.lua
    Initialise l'interface des détails du camping
]]

local gui = script.Parent
-- Les propriétés sont déjà définies dans init.meta.json

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 500, 0, 600)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

-- Arrondir les coins
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Bouton fermer
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "✕"
closeButton.TextSize = 24
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Titre
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -100, 0, 50)
titleLabel.Position = UDim2.new(0, 20, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Camping de [Joueur]"
titleLabel.TextSize = 26
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

-- Income display
local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(1, -40, 0, 30)
incomeLabel.Position = UDim2.new(0, 20, 0, 65)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "💰 Revenue : +0 $ / tick"
incomeLabel.TextSize = 18
incomeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
incomeLabel.Font = Enum.Font.Gotham
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Parent = mainFrame

-- Cash display
local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(1, -40, 0, 30)
cashLabel.Position = UDim2.new(0, 20, 0, 95)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "💵 Argent disponible : 0 $"
cashLabel.TextSize = 16
cashLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
cashLabel.Font = Enum.Font.Gotham
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = mainFrame

-- Séparateur 1
local separator1 = Instance.new("Frame")
separator1.Name = "Separator1"
separator1.Size = UDim2.new(1, -40, 0, 2)
separator1.Position = UDim2.new(0, 20, 0, 130)
separator1.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
separator1.BorderSizePixel = 0
separator1.Parent = mainFrame

-- Titre section objets possédés
local ownedTitleLabel = Instance.new("TextLabel")
ownedTitleLabel.Name = "OwnedTitleLabel"
ownedTitleLabel.Size = UDim2.new(1, -40, 0, 30)
ownedTitleLabel.Position = UDim2.new(0, 20, 0, 140)
ownedTitleLabel.BackgroundTransparency = 1
ownedTitleLabel.Text = "📦 Objets possédés"
ownedTitleLabel.TextSize = 18
ownedTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ownedTitleLabel.Font = Enum.Font.GothamBold
ownedTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
ownedTitleLabel.Parent = mainFrame

-- ScrollingFrame pour les objets possédés
local ownedScrollFrame = Instance.new("ScrollingFrame")
ownedScrollFrame.Name = "OwnedItemsFrame"
ownedScrollFrame.Size = UDim2.new(1, -40, 0, 120)
ownedScrollFrame.Position = UDim2.new(0, 20, 0, 175)
ownedScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ownedScrollFrame.BorderSizePixel = 0
ownedScrollFrame.ScrollBarThickness = 6
ownedScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ownedScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ownedScrollFrame.Parent = mainFrame

local ownedCorner = Instance.new("UICorner")
ownedCorner.CornerRadius = UDim.new(0, 8)
ownedCorner.Parent = ownedScrollFrame

local ownedLayout = Instance.new("UIListLayout")
ownedLayout.SortOrder = Enum.SortOrder.LayoutOrder
ownedLayout.Padding = UDim.new(0, 5)
ownedLayout.Parent = ownedScrollFrame

local ownedPadding = Instance.new("UIPadding")
ownedPadding.PaddingLeft = UDim.new(0, 10)
ownedPadding.PaddingRight = UDim.new(0, 10)
ownedPadding.PaddingTop = UDim.new(0, 10)
ownedPadding.PaddingBottom = UDim.new(0, 10)
ownedPadding.Parent = ownedScrollFrame

-- Séparateur 2
local separator2 = Instance.new("Frame")
separator2.Name = "Separator2"
separator2.Size = UDim2.new(1, -40, 0, 2)
separator2.Position = UDim2.new(0, 20, 0, 305)
separator2.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
separator2.BorderSizePixel = 0
separator2.Parent = mainFrame

-- Titre section upgrades
local upgradesTitleLabel = Instance.new("TextLabel")
upgradesTitleLabel.Name = "UpgradesTitleLabel"
upgradesTitleLabel.Size = UDim2.new(1, -40, 0, 30)
upgradesTitleLabel.Position = UDim2.new(0, 20, 0, 315)
upgradesTitleLabel.BackgroundTransparency = 1
upgradesTitleLabel.Text = "⬆️ Améliorations disponibles"
upgradesTitleLabel.TextSize = 18
upgradesTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradesTitleLabel.Font = Enum.Font.GothamBold
upgradesTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
upgradesTitleLabel.Parent = mainFrame

-- ScrollingFrame pour les upgrades
local upgradesScrollFrame = Instance.new("ScrollingFrame")
upgradesScrollFrame.Name = "UpgradesFrame"
upgradesScrollFrame.Size = UDim2.new(1, -40, 0, 220)
upgradesScrollFrame.Position = UDim2.new(0, 20, 0, 350)
upgradesScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
upgradesScrollFrame.BorderSizePixel = 0
upgradesScrollFrame.ScrollBarThickness = 6
upgradesScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
upgradesScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
upgradesScrollFrame.Parent = mainFrame

local upgradesCorner = Instance.new("UICorner")
upgradesCorner.CornerRadius = UDim.new(0, 8)
upgradesCorner.Parent = upgradesScrollFrame

local upgradesLayout = Instance.new("UIListLayout")
upgradesLayout.SortOrder = Enum.SortOrder.LayoutOrder
upgradesLayout.Padding = UDim.new(0, 8)
upgradesLayout.Parent = upgradesScrollFrame

local upgradesPadding = Instance.new("UIPadding")
upgradesPadding.PaddingLeft = UDim.new(0, 10)
upgradesPadding.PaddingRight = UDim.new(0, 10)
upgradesPadding.PaddingTop = UDim.new(0, 10)
upgradesPadding.PaddingBottom = UDim.new(0, 10)
upgradesPadding.Parent = upgradesScrollFrame

-- Label de statut (messages d'erreur/succès)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -40, 0, 20)
statusLabel.Position = UDim2.new(0, 20, 1, -30)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = mainFrame

print("[CampingDetailsGui] ✅ Interface créée")
