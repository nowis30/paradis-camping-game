-- FishingCodexClient.client.lua
-- Petit codex affichant les poissons vus et à découvrir

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = ReplicatedStorage:WaitForChild("Config")
local FishingGearConfig = require(Config:WaitForChild("FishingGearConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FishingShopRemotes = require(Remotes:WaitForChild("FishingShopRemotes"))

local gui

local function buildUI(seen)
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "FishingCodexGui"
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.88, 0, 0.68, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(35,40,46)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 32)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Text = "📖 Codex des poissons"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -20, 1, -56)
    list.Position = UDim2.new(0, 10, 0, 48)
    list.BackgroundTransparency = 1
    list.Parent = frame

    local function addEntry(idx, name, key)
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.Position = UDim2.new(0, 0, 0, (idx-1)*32)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.Gotham
        row.TextSize = 18
        row.TextXAlignment = Enum.TextXAlignment.Left
        local discovered = seen[key] == true
        row.TextColor3 = discovered and Color3.fromRGB(200,255,200) or Color3.fromRGB(200,200,200)
        row.Text = string.format("%s %s", discovered and "✓" or "?", name)
        row.Parent = list
    end

    local i = 1
    addEntry(i, "Poisson commun", "Common"); i = i + 1
    addEntry(i, "Poisson rare", "rare"); i = i + 1
    addEntry(i, "Poisson légendaire", "legendaire"); i = i + 1

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 36, 0, 36)
    close.Position = UDim2.new(1, -46, 0, 10)
    close.BackgroundColor3 = Color3.fromRGB(200,60,60)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 18
    close.TextColor3 = Color3.fromRGB(255,255,255)
    close.Text = "✕"
    close.Parent = frame
    close.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)
end

local function refresh()
    local ok, seen = pcall(function()
        return FishingShopRemotes.GetCodex:InvokeServer()
    end)
    if not ok then seen = {} end
    buildUI(seen or {})
end

local function toggle()
    if not gui then refresh() end
    gui.Enabled = not gui.Enabled
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.C then
        toggle()
    end
end)
