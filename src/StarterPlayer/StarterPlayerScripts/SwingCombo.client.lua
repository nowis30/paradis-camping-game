local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local swingFolder = remotesFolder:WaitForChild("SwingGame")
local comboEvent = swingFolder:WaitForChild("SwingComboUpdate")

-- ScreenGui setup
local gui = Instance.new("ScreenGui")
gui.Name = "SwingComboGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Name = "Container"
frame.BackgroundTransparency = 0.25
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Size = UDim2.fromOffset(220, 42)
frame.Position = UDim2.new(0.5, 0, 0, 20)
frame.Parent = gui

local label = Instance.new("TextLabel")
label.Name = "ComboLabel"
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(240, 240, 240)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Text = "" -- hidden until first combo
label.Parent = frame

local function showCombo(comboCount, reward)
    label.Text = string.format("Combo x%d  +%d$", comboCount, reward)
    gui.Parent = player:WaitForChild("PlayerGui")
    frame.BackgroundColor3 = comboCount > 1 and Color3.fromRGB(45, 90, 180) or Color3.fromRGB(25,25,25)
    frame.Visible = true
    label.TextTransparency = 0
    frame.BackgroundTransparency = 0.25

    local fadeDelay = 2.5
    task.delay(fadeDelay, function()
        if not label.Parent then return end
        local tween = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})
        tween:Play()
        local tween2 = TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        tween2:Play()
        tween.Completed:Connect(function()
            frame.Visible = false
        end)
    end)
end

comboEvent.OnClientEvent:Connect(showCombo)
