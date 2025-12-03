--[[
    BuildScreenGui
    Module responsable de la création de l'interface de construction côté client.
    
    ⚠️ DÉSACTIVÉ - Ce module a été remplacé par CampingDetailsGui
    Les objets sont maintenant gérés automatiquement via le système de progression
    et l'interface se trouve sur les pancartes des parcelles.
]]

local GuiFactory = {}

-- Module désactivé mais conservé pour référence
return GuiFactory

local function getOrderedKeys(config, orderProperty, labelProperty)
    local keys = {}
    for key in pairs(config) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        local dataA = config[a] or {}
        local dataB = config[b] or {}
        local orderA = dataA[orderProperty] or math.huge
        local orderB = dataB[orderProperty] or math.huge
        if orderA == orderB then
            local labelA = dataA[labelProperty] or a
            local labelB = dataB[labelProperty] or b
            return labelA < labelB
        end
        return orderA < orderB
    end)
    return keys
end

function GuiFactory.create(playerGui, objectsConfig, trailerConfig)
    trailerConfig = trailerConfig or {}
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ParadisBuildGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 5
    screenGui.Parent = playerGui

    local buildButton = Instance.new("TextButton")
    buildButton.Name = "BuildToggle"
    buildButton.Size = UDim2.new(0.4, 0, 0, 45)
    buildButton.Position = UDim2.new(0.5, 0, 1, -55)
    buildButton.AnchorPoint = Vector2.new(0.5, 1)
    buildButton.BackgroundColor3 = Color3.fromRGB(37, 115, 74)
    buildButton.TextColor3 = Color3.new(1, 1, 1)
    buildButton.Font = Enum.Font.GothamBold
    buildButton.TextScaled = true
    buildButton.Text = "🎨 Décorer le terrain"
    buildButton.Visible = false
    buildButton.Parent = screenGui

    local toolbar = Instance.new("Frame")
    toolbar.Name = "BuildToolbar"
    toolbar.Size = UDim2.new(0.95, 0, 0, 130)
    toolbar.Position = UDim2.new(0.025, 0, 1, -140)
    toolbar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    toolbar.BackgroundTransparency = 0.1
    toolbar.BorderSizePixel = 0
    toolbar.Visible = false
    toolbar.Parent = screenGui

    local buttonScroll = Instance.new("ScrollingFrame")
    buttonScroll.Name = "ButtonScroll"
    buttonScroll.Size = UDim2.new(1, -10, 0, 65)
    buttonScroll.Position = UDim2.new(0, 5, 0, 50)
    buttonScroll.BackgroundTransparency = 1
    buttonScroll.BorderSizePixel = 0
    buttonScroll.ScrollBarThickness = 6
    buttonScroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
    buttonScroll.ScrollingDirection = Enum.ScrollingDirection.X
    buttonScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    buttonScroll.Parent = toolbar

    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Size = UDim2.new(1, 0, 1, 0)
    buttonContainer.Parent = buttonScroll

    local uiList = Instance.new("UIListLayout")
    uiList.FillDirection = Enum.FillDirection.Horizontal
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    uiList.VerticalAlignment = Enum.VerticalAlignment.Center
    uiList.Padding = UDim.new(0, 8)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = buttonContainer

    local buttons = {}
    local orderedObjects = getOrderedKeys(objectsConfig, "Order", "Label")
    for index, objectType in ipairs(orderedObjects) do
        local data = objectsConfig[objectType]
        local btn = Instance.new("TextButton")
        btn.Name = objectType .. "Button"
        btn.Size = UDim2.new(0, 120, 0, 60)
        btn.Text = data.Label or objectType
        btn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.TextWrapped = true
        btn.TextYAlignment = Enum.TextYAlignment.Top
        btn.LayoutOrder = data.Order or index
        btn.AutoButtonColor = false
        btn.Parent = buttonContainer
        
        -- Coins arrondis
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        -- Bordure décorative
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(70, 80, 100)
        btnStroke.Thickness = 2
        btnStroke.Transparency = 0.5
        btnStroke.Parent = btn
        
        -- Gradient subtil
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 60, 75)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 40, 55))
        }
        gradient.Rotation = 90
        gradient.Parent = btn
        
        -- Padding du texte
        local textPadding = Instance.new("UIPadding")
        textPadding.PaddingLeft = UDim.new(0, 6)
        textPadding.PaddingRight = UDim.new(0, 6)
        textPadding.PaddingTop = UDim.new(0, 6)
        textPadding.PaddingBottom = UDim.new(0, 6)
        textPadding.Parent = btn
        
        -- Effet hover
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(60, 70, 90)
            btnStroke.Color = Color3.fromRGB(100, 140, 180)
            btnStroke.Transparency = 0.2
        end)
        
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
            btnStroke.Color = Color3.fromRGB(70, 80, 100)
            btnStroke.Transparency = 0.5
        end)
        
        buttons[objectType] = btn
    end

    local trailerButtons = {}

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0.45, 0, 0, 35)
    statusLabel.Position = UDim2.new(0, 8, 0, 8)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextScaled = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Text = "Sélectionnez un objet"
    statusLabel.Parent = toolbar

    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelPlacement"
    cancelButton.Size = UDim2.new(0.22, 0, 0, 35)
    cancelButton.Position = UDim2.new(1, -8, 0, 8)
    cancelButton.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
    cancelButton.TextColor3 = Color3.new(1, 1, 1)
    cancelButton.Font = Enum.Font.GothamBold
    cancelButton.TextScaled = true
    cancelButton.Text = "Annuler"
    cancelButton.AnchorPoint = Vector2.new(1, 0)
    cancelButton.Parent = toolbar

    local deleteButton = Instance.new("TextButton")
    deleteButton.Name = "DeleteToggle"
    deleteButton.Size = UDim2.new(0.22, 0, 0, 35)
    deleteButton.Position = UDim2.new(1, -8, 0, 8)
    deleteButton.BackgroundColor3 = Color3.fromRGB(200, 120, 40)
    deleteButton.TextColor3 = Color3.new(1, 1, 1)
    deleteButton.Font = Enum.Font.GothamBold
    deleteButton.TextScaled = true
    deleteButton.Text = "Supprimer"
    deleteButton.AnchorPoint = Vector2.new(1, 0)
    deleteButton.Parent = toolbar

    local tutorialFrame = Instance.new("Frame")
    tutorialFrame.Name = "TutorialFrame"
    tutorialFrame.Size = UDim2.new(0.9, 0, 0, 160)
    tutorialFrame.Position = UDim2.new(0.05, 0, 0, 100)
    tutorialFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    tutorialFrame.BackgroundTransparency = 0.1
    tutorialFrame.BorderSizePixel = 0
    tutorialFrame.Visible = true
    tutorialFrame.Parent = screenGui

    local tutorialTitle = Instance.new("TextLabel")
    tutorialTitle.Size = UDim2.new(1, -50, 0, 28)
    tutorialTitle.Position = UDim2.new(0, 12, 0, 10)
    tutorialTitle.BackgroundTransparency = 1
    tutorialTitle.Font = Enum.Font.GothamBold
    tutorialTitle.TextScaled = true
    tutorialTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    tutorialTitle.TextXAlignment = Enum.TextXAlignment.Left
    tutorialTitle.Text = "🏕️ Bienvenue au Paradis du Camping!"
    tutorialTitle.Parent = tutorialFrame

    local tutorialBody = Instance.new("TextLabel")
    tutorialBody.Size = UDim2.new(1, -24, 0, 100)
    tutorialBody.Position = UDim2.new(0, 12, 0, 42)
    tutorialBody.BackgroundTransparency = 1
    tutorialBody.Font = Enum.Font.Gotham
    tutorialBody.TextScaled = true
    tutorialBody.TextColor3 = Color3.fromRGB(235, 235, 235)
    tutorialBody.TextWrapped = true
    tutorialBody.TextXAlignment = Enum.TextXAlignment.Left
    tutorialBody.TextYAlignment = Enum.TextYAlignment.Top
    tutorialBody.Text = "🎯 Joue aux mini-jeux (pêche, labyrinthe, coupe de bois) pour gagner de l'argent et débloquer des achievements!\n💰 Clique sur 'Camping' pour améliorer tes objets (roulottes, BBQ...) qui génèrent du revenu passif.\n🏆 Plus tu joues, plus tu débloques d'améliorations puissantes!"
    tutorialBody.Parent = tutorialFrame

    local tutorialClose = Instance.new("TextButton")
    tutorialClose.Size = UDim2.new(0, 32, 0, 32)
    tutorialClose.Position = UDim2.new(1, -38, 0, 6)
    tutorialClose.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    tutorialClose.TextColor3 = Color3.new(1, 1, 1)
    tutorialClose.Font = Enum.Font.GothamBold
    tutorialClose.TextScaled = true
    tutorialClose.Text = "X"
    tutorialClose.Parent = tutorialFrame

    return {
        ScreenGui = screenGui,
        BuildButton = buildButton,
        Toolbar = toolbar,
        ButtonContainer = buttonContainer,
        ButtonScroll = buttonScroll,
        Buttons = buttons,
        TrailerButtons = trailerButtons,
        StatusLabel = statusLabel,
        CancelButton = cancelButton,
        DeleteButton = deleteButton,
        TutorialFrame = tutorialFrame,
        TutorialClose = tutorialClose,
    }
end

return GuiFactory
