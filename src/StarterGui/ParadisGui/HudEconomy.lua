--[[
    HudEconomy
    Crée un panneau HUD minimaliste pour afficher l'argent et le revenu passif.
]]

local HudEconomy = {}

function HudEconomy.create(parent)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HudEconomy"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.Size = UDim2.new(0.45, 0, 0, 125)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 0.2
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = frame

    local cashLabel = Instance.new("TextLabel")
    cashLabel.Name = "CashLabel"
    cashLabel.Size = UDim2.new(1, -10, 0, 24)
    cashLabel.BackgroundTransparency = 1
    cashLabel.Font = Enum.Font.GothamBold
    cashLabel.TextScaled = true
    cashLabel.TextXAlignment = Enum.TextXAlignment.Left
    cashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cashLabel.Text = "Argent : 0 $"
    cashLabel.Parent = frame

    local incomeLabel = Instance.new("TextLabel")
    incomeLabel.Name = "IncomeLabel"
    incomeLabel.Size = UDim2.new(1, -10, 0, 20)
    incomeLabel.BackgroundTransparency = 1
    incomeLabel.Font = Enum.Font.Gotham
    incomeLabel.TextScaled = true
    incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    incomeLabel.TextColor3 = Color3.fromRGB(150, 240, 150)
    incomeLabel.Text = "+0 $ / sec"
    incomeLabel.Parent = frame

    local boostLabel = Instance.new("TextLabel")
    boostLabel.Name = "BoostLabel"
    boostLabel.Size = UDim2.new(1, -10, 0, 18)
    boostLabel.BackgroundTransparency = 1
    boostLabel.Font = Enum.Font.Gotham
    boostLabel.TextScaled = true
    boostLabel.TextXAlignment = Enum.TextXAlignment.Left
    boostLabel.TextColor3 = Color3.fromRGB(255, 219, 120)
    boostLabel.Text = "Boost : Aucun"
    boostLabel.Parent = frame

    local logsLabel = Instance.new("TextLabel")
    logsLabel.Name = "LogsLabel"
    logsLabel.Size = UDim2.new(1, -10, 0, 20)
    logsLabel.BackgroundTransparency = 1
    logsLabel.Font = Enum.Font.GothamBold
    logsLabel.TextScaled = true
    logsLabel.TextXAlignment = Enum.TextXAlignment.Left
    logsLabel.TextColor3 = Color3.fromRGB(160, 120, 80)
    logsLabel.Text = "🪵 Bûches : 0"
    logsLabel.Parent = frame

    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveButton"
    saveButton.Size = UDim2.new(0.9, 0, 0, 24)
    saveButton.BackgroundColor3 = Color3.fromRGB(55, 140, 85)
    saveButton.TextColor3 = Color3.new(1, 1, 1)
    saveButton.Font = Enum.Font.GothamBold
    saveButton.TextScaled = true
    saveButton.Text = "Sauvegarder"
    saveButton.Parent = frame

    return {
        ScreenGui = screenGui,
        CashLabel = cashLabel,
        IncomeLabel = incomeLabel,
        BoostLabel = boostLabel,
        LogsLabel = logsLabel,
        SaveButton = saveButton,
    }
end

return HudEconomy
