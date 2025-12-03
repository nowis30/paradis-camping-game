-- FishmongerClient.client.lua
-- UI simple de poissonnerie pour vendre les poissons

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FishingShopRemotes = require(Remotes:WaitForChild("FishingShopRemotes"))

local fishUI
local invLabels = {}

local function createUI()
    fishUI = Instance.new("ScreenGui")
    fishUI.Name = "FishmongerGui"
    fishUI.ResetOnSpawn = false
    fishUI.Enabled = false
    fishUI.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0.88, 0, 0.6, 0)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(40,40,45)
    panel.BorderSizePixel = 0
    panel.Parent = fishUI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 32)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Text = "🐟 Poissonnerie"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -20, 0, 130)
    list.Position = UDim2.new(0, 10, 0, 44)
    list.BackgroundTransparency = 1
    list.Parent = panel

    local function addRow(idx, labelText, fishType)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.Position = UDim2.new(0, 0, 0, (idx-1)*44)
        row.BackgroundTransparency = 1
        row.Parent = list

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 18
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Color3.fromRGB(230,230,230)
        label.Text = labelText .. ": 0"
        label.Parent = row
        invLabels[fishType] = label

        local sellOne = Instance.new("TextButton")
        sellOne.Size = UDim2.new(0.18, 0, 1, 0)
        sellOne.Position = UDim2.new(0.62, 5, 0, 0)
        sellOne.BackgroundColor3 = Color3.fromRGB(70,120,70)
        sellOne.Font = Enum.Font.GothamBold
        sellOne.TextSize = 16
        sellOne.TextColor3 = Color3.fromRGB(255,255,255)
        sellOne.Text = "Vendre 1"
        sellOne.Parent = row
        sellOne.MouseButton1Click:Connect(function()
            FishingShopRemotes.SellFish:FireServer(fishType, 1)
            task.wait(0.2)
            update()
        end)

        local sellAll = Instance.new("TextButton")
        sellAll.Size = UDim2.new(0.18, 0, 1, 0)
        sellAll.Position = UDim2.new(0.82, 5, 0, 0)
        sellAll.BackgroundColor3 = Color3.fromRGB(160,90,70)
        sellAll.Font = Enum.Font.GothamBold
        sellAll.TextSize = 16
        sellAll.TextColor3 = Color3.fromRGB(255,255,255)
        sellAll.Text = "Tout"
        sellAll.Parent = row
        sellAll.MouseButton1Click:Connect(function()
            FishingShopRemotes.SellFish:FireServer(fishType)
            task.wait(0.2)
            update()
        end)
    end

    addRow(1, "Commun", "Common")
    addRow(2, "Rare", "rare")
    addRow(3, "Légendaire", "legendaire")

    local sellAllBtn = Instance.new("TextButton")
    sellAllBtn.Size = UDim2.new(0, 150, 0, 36)
    sellAllBtn.Position = UDim2.new(0, 10, 1, -46)
    sellAllBtn.BackgroundColor3 = Color3.fromRGB(200,120,60)
    sellAllBtn.Font = Enum.Font.GothamBold
    sellAllBtn.TextSize = 18
    sellAllBtn.TextColor3 = Color3.fromRGB(255,255,255)
    sellAllBtn.Text = "Tout vendre"
    sellAllBtn.Parent = panel
    sellAllBtn.MouseButton1Click:Connect(function()
        FishingShopRemotes.SellAllFish:FireServer()
        task.wait(0.2)
        update()
    end)

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 36, 0, 36)
    close.Position = UDim2.new(1, -46, 0, 10)
    close.BackgroundColor3 = Color3.fromRGB(200,60,60)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 18
    close.TextColor3 = Color3.fromRGB(255,255,255)
    close.Text = "✕"
    close.Parent = panel
    close.MouseButton1Click:Connect(function()
        fishUI.Enabled = false
    end)
end

function update()
    local ok, gear = pcall(function()
        return FishingShopRemotes.GetGear:InvokeServer()
    end)
    if ok and gear and gear.FishInventory then
        invLabels.Common.Text = "Commun: " .. tostring(gear.FishInventory.Common or 0)
        invLabels.rare.Text = "Rare: " .. tostring(gear.FishInventory.rare or 0)
        invLabels.legendaire.Text = "Légendaire: " .. tostring(gear.FishInventory.legendaire or 0)
    end
end

local function open()
    if not fishUI then createUI() end
    update()
    fishUI.Enabled = true
end

-- Détecter un PNJ ou modèle nommé "Fishmonger" ou "Poissonnerie" et ajouter un prompt
local function setupNPC(model)
    if not model:IsA("Model") then return end
    if not (string.find(string.lower(model.Name), "fishmonger") or string.find(string.lower(model.Name), "poisson")) then return end
    local targetPart = model.PrimaryPart
    if not targetPart then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then targetPart = d break end
        end
    end
    if not targetPart then return end
    local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Vendre poissons"
        prompt.ObjectText = "🐟 Poissonnerie"
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 18
        prompt.Parent = targetPart
    end
    prompt.Triggered:Connect(function(player)
        if player == LocalPlayer then open() end
    end)
end

for _, m in ipairs(workspace:GetChildren()) do setupNPC(m) end
workspace.ChildAdded:Connect(setupNPC)

-- Touche raccourci (O)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.O then
        open()
    end
end)
