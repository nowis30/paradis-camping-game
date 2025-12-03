--[[
    ShopClient
    UI minimaliste permettant d'acheter et de placer des objets décoratifs
    (arbres, roulottes, décorations) uniquement sur la parcelle du joueur.
    DÉSACTIVÉ: fonctionnalité retirée.
]]

do return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")
local ShopConfig = require(ConfigFolder:WaitForChild("ShopConfig"))
local BuildRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuildRemotes"))

local ShopObjects = ReplicatedStorage:FindFirstChild("ShopObjects")
if not ShopObjects then
    ShopObjects = Instance.new("Folder")
    ShopObjects.Name = "ShopObjects"
    ShopObjects.Parent = ReplicatedStorage
    warn("[Paradis][ShopClient] Dossier 'ShopObjects' manquant, créé vide.")
end

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local ShopRemotes = RemotesFolder:WaitForChild("ShopRemotes")
local PlaceShopItem = ShopRemotes:WaitForChild("PlaceShopItem")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ShopToggle"
toggleButton.Size = UDim2.new(0, 180, 0, 44)
toggleButton.Position = UDim2.new(0, 24, 1, -68)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 110, 90)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.Text = "Boutique"
toggleButton.Visible = false
toggleButton.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.Size = UDim2.new(0, 320, 0, 380)
panel.Position = UDim2.new(0, 24, 1, -420)
panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 6)
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "🌲 Décorer le terrain"
title.Parent = panel

local infoLabel = Instance.new("TextLabel")
infoLabel.BackgroundTransparency = 1
infoLabel.Size = UDim2.new(1, -20, 0, 48)
infoLabel.Position = UDim2.new(0, 10, 0, 46)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 16
infoLabel.TextColor3 = Color3.fromRGB(190, 220, 200)
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Text = "Choisissez un élément décoratif puis cliquez pour placer. Touche R pour tourner."
infoLabel.Parent = panel

local selectedLabel = Instance.new("TextLabel")
selectedLabel.BackgroundTransparency = 1
selectedLabel.Size = UDim2.new(1, -20, 0, 32)
selectedLabel.Position = UDim2.new(0, 10, 0, 94)
selectedLabel.Font = Enum.Font.GothamSemibold
selectedLabel.TextSize = 18
selectedLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Text = "Aucun objet sélectionné"
selectedLabel.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Name = "ItemsList"
list.Size = UDim2.new(1, -20, 1, -140)
list.Position = UDim2.new(0, 10, 0, 130)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ScrollBarThickness = 6
list.BackgroundTransparency = 0.1
list.BackgroundColor3 = Color3.fromRGB(30, 36, 46)
list.BorderSizePixel = 0
list.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

local function updateListCanvas()
    list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateListCanvas)

local currentPlot
local selectedItemId
local selectedItemDef
local currentRotation = 0
local placementCFrame
local ghostModel
local ghostHalfHeight = 3
local gridSize = 4
local placementCooldown = 0.4
local lastPlacement = 0

local function clearGhost()
    if ghostModel then
        ghostModel:Destroy()
        ghostModel = nil
    end
    placementCFrame = nil
end

local function applyGhostAppearance(model)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
            desc.CastShadow = false
            desc.Material = Enum.Material.ForceField
            desc.Color = Color3.fromRGB(120, 220, 255)
            desc.Transparency = 0.5
        elseif desc:IsA("Decal") or desc:IsA("Texture") then
            desc.Transparency = 0.5
        end
    end
end

local function selectItem(itemId)
    local def = ShopConfig.Items[itemId]
    selectedItemId = def and def.Id or nil
    selectedItemDef = def
    currentRotation = 0
    placementCFrame = nil
    clearGhost()

    if not def then
        selectedLabel.Text = "Aucun objet sélectionné"
        return
    end

    local template = ShopObjects:FindFirstChild(def.ModelName)
    if not template then
        selectedLabel.Text = "Modèle introuvable"
        warn("[Paradis][ShopClient] Modèle introuvable:", def.ModelName)
        return
    end

    ghostModel = template:Clone()
    applyGhostAppearance(ghostModel)
    ghostModel.Parent = workspace
    local _, size = ghostModel:GetBoundingBox()
    ghostHalfHeight = size.Y / 2
    selectedLabel.Text = string.format("%s - %d$", def.DisplayName or def.Id, def.Cost or 0)
end

local function buildItemButtons()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local bucket = {}
    for _, def in pairs(ShopConfig.Items or {}) do
        table.insert(bucket, def)
    end
    table.sort(bucket, function(a, b)
        if a.Category == b.Category then
            return (a.DisplayName or a.Id) < (b.DisplayName or b.Id)
        end
        return (a.Category or "") < (b.Category or "")
    end)

    local currentCategory
    local order = 0
    for _, def in ipairs(bucket) do
        if def.Category ~= currentCategory then
            currentCategory = def.Category
            order += 1
            local header = Instance.new("TextLabel")
            header.Name = "CategoryHeader"
            header.Size = UDim2.new(1, -4, 0, 26)
            header.BackgroundTransparency = 1
            header.TextColor3 = Color3.fromRGB(200, 220, 230)
            header.Font = Enum.Font.GothamSemibold
            header.TextXAlignment = Enum.TextXAlignment.Left
            header.TextSize = 18
            header.Text = string.upper(currentCategory or "Autre")
            header.LayoutOrder = order
            header.Parent = list
        end

        order += 1
        local button = Instance.new("TextButton")
        button.Name = "ItemButton"
        button.Size = UDim2.new(1, -4, 0, 56)
        button.BackgroundColor3 = Color3.fromRGB(50, 60, 70)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.Gotham
        button.TextSize = 16
        button.TextWrapped = true
        button.LayoutOrder = order
        button.AutoButtonColor = true
        button.Text = string.format("%s\n%d $", def.DisplayName or def.Id, def.Cost or 0)
        button.Parent = list

        button.MouseButton1Click:Connect(function()
            selectItem(def.Id)
        end)
    end

    updateListCanvas()
end

buildItemButtons()

local function clampToPlot(position)
    if not currentPlot then
        return nil
    end
    local center = currentPlot.Center
    local size = currentPlot.Size
    if not center or not size then
        return nil
    end
    local halfX = size.X / 2 - 1
    local halfZ = size.Y / 2 - 1
    if halfX <= 0 or halfZ <= 0 then
        return nil
    end
    local dx = math.clamp(position.X - center.X, -halfX, halfX)
    local dz = math.clamp(position.Z - center.Z, -halfZ, halfZ)
    local snappedX = math.round(dx / gridSize) * gridSize
    local snappedZ = math.round(dz / gridSize) * gridSize
    snappedX = math.clamp(snappedX, -halfX, halfX)
    snappedZ = math.clamp(snappedZ, -halfZ, halfZ)
    local baseHeight = currentPlot.BaseHeight or center.Y
    local y = baseHeight + ghostHalfHeight
    return Vector3.new(center.X + snappedX, y, center.Z + snappedZ)
end

local function updateGhostPosition()
    if not (ghostModel and currentPlot and selectedItemId) then
        placementCFrame = nil
        if ghostModel then
            ghostModel:PivotTo(CFrame.new(0, -1000, 0))
        end
        return
    end

    local hit = mouse.Hit
    if not hit then
        return
    end
    local clamped = clampToPlot(hit.Position)
    if not clamped then
        placementCFrame = nil
        ghostModel:PivotTo(CFrame.new(0, -1000, 0))
        return
    end

    placementCFrame = CFrame.new(clamped) * CFrame.Angles(0, math.rad(currentRotation), 0)
    ghostModel:PivotTo(placementCFrame)
end

local function attemptPlacement()
    if not (selectedItemId and placementCFrame and currentPlot) then
        return
    end
    if tick() - lastPlacement < placementCooldown then
        return
    end
    lastPlacement = tick()
    PlaceShopItem:FireServer(selectedItemId, placementCFrame)
end

local function setPanelVisible(state)
    panel.Visible = state
    if not state then
        clearGhost()
    elseif selectedItemId then
        selectItem(selectedItemId)
    end
end

toggleButton.MouseButton1Click:Connect(function()
    setPanelVisible(not panel.Visible)
end)

BuildRemotes.PlotAssigned.OnClientEvent:Connect(function(plotData)
    currentPlot = plotData
    toggleButton.Visible = true
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.R and panel.Visible and selectedItemId then
        currentRotation = (currentRotation + 45) % 360
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and panel.Visible and selectedItemId then
        attemptPlacement()
    end
end)

RunService.RenderStepped:Connect(function()
    if panel.Visible then
        updateGhostPosition()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    clearGhost()
    placementCFrame = nil
end)
