-- FILE: GolfKartController.client.lua

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remotes
local remotesFolder = ReplicatedStorage:WaitForChild("GolfKartRemotes")
local ShiftGear = remotesFolder:WaitForChild("ShiftGear")
local SetThrottle = remotesFolder:WaitForChild("SetThrottle")
local SetBrake = remotesFolder:WaitForChild("SetBrake")
local SetSteering = remotesFolder:WaitForChild("SetSteering")
local RequestKartSpawn = remotesFolder:WaitForChild("RequestKartSpawn")
local RequestKartDespawn = remotesFolder:WaitForChild("RequestKartDespawn")
local RequestKartPurchase = remotesFolder:WaitForChild("RequestKartPurchase")
local NotifyKartStatus = remotesFolder:WaitForChild("NotifyKartStatus")

-- State
local isThrottling = false
local isBraking = false
local steeringValue = 0
local currentKart = nil

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GolfKartUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Cadran RPM/Vitesse (centre-haut)
local dashFrame = Instance.new("Frame")
dashFrame.Name = "DashFrame"
dashFrame.Size = UDim2.new(0.3, 0, 0.12, 0)
dashFrame.Position = UDim2.new(0.35, 0, 0.02, 0)
dashFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
dashFrame.BorderSizePixel = 0
dashFrame.Visible = false
dashFrame.Parent = screenGui

local dashCorner = Instance.new("UICorner")
dashCorner.CornerRadius = UDim.new(0, 12)
dashCorner.Parent = dashFrame

local dashStroke = Instance.new("UIStroke")
dashStroke.Color = Color3.fromRGB(200, 200, 200)
dashStroke.Thickness = 3
dashStroke.Parent = dashFrame

-- Vitesse (gauche du cadran)
local gearLabel = Instance.new("TextLabel")
gearLabel.Size = UDim2.new(0.48, 0, 0.5, 0)
gearLabel.Position = UDim2.new(0.01, 0, 0.05, 0)
gearLabel.BackgroundTransparency = 1
gearLabel.Text = "GEAR\n1"
gearLabel.TextColor3 = Color3.new(1, 1, 1)
gearLabel.TextScaled = true
gearLabel.Font = Enum.Font.GothamBold
gearLabel.Parent = dashFrame

-- RPM (droite du cadran)
local rpmLabel = Instance.new("TextLabel")
rpmLabel.Size = UDim2.new(0.48, 0, 0.5, 0)
rpmLabel.Position = UDim2.new(0.51, 0, 0.05, 0)
rpmLabel.BackgroundTransparency = 1
rpmLabel.Text = "RPM\n1000"
rpmLabel.TextColor3 = Color3.new(1, 1, 1)
rpmLabel.TextScaled = true
rpmLabel.Font = Enum.Font.GothamBold
rpmLabel.Parent = dashFrame

-- Barre RPM colorée
local rpmBarBg = Instance.new("Frame")
rpmBarBg.Size = UDim2.new(0.96, 0, 0.25, 0)
rpmBarBg.Position = UDim2.new(0.02, 0, 0.68, 0)
rpmBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
rpmBarBg.BorderSizePixel = 0
rpmBarBg.Parent = dashFrame

local rpmBarBgCorner = Instance.new("UICorner")
rpmBarBgCorner.CornerRadius = UDim.new(0, 6)
rpmBarBgCorner.Parent = rpmBarBg

local rpmBarFg = Instance.new("Frame")
rpmBarFg.Size = UDim2.new(0, 0, 1, 0)
rpmBarFg.BackgroundColor3 = Color3.new(1, 1, 1)
rpmBarFg.BorderSizePixel = 0
rpmBarFg.Parent = rpmBarBg

local rpmBarFgCorner = Instance.new("UICorner")
rpmBarFgCorner.CornerRadius = UDim.new(0, 6)
rpmBarFgCorner.Parent = rpmBarFg

-- Pédale de frein (bas-gauche)
local brakeFrame = Instance.new("ImageLabel")
brakeFrame.Name = "BrakePedal"
brakeFrame.Size = UDim2.new(0.08, 0, 0.12, 0)
brakeFrame.Position = UDim2.new(0.05, 0, 0.85, 0)
brakeFrame.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
brakeFrame.BorderSizePixel = 0
brakeFrame.Visible = false
brakeFrame.Parent = screenGui

local brakeCorner = Instance.new("UICorner")
brakeCorner.CornerRadius = UDim.new(0, 12)
brakeCorner.Parent = brakeFrame

local brakeLabel = Instance.new("TextLabel")
brakeLabel.Size = UDim2.new(1, 0, 0.4, 0)
brakeLabel.Position = UDim2.new(0, 0, 0.55, 0)
brakeLabel.BackgroundTransparency = 1
brakeLabel.Text = "BRAKE\nS"
brakeLabel.TextColor3 = Color3.new(1, 1, 1)
brakeLabel.TextScaled = true
brakeLabel.Font = Enum.Font.GothamBold
brakeLabel.Parent = brakeFrame

-- Pédale de gaz (bas-gauche, à côté du frein)
local gasFrame = Instance.new("ImageLabel")
gasFrame.Name = "GasPedal"
gasFrame.Size = UDim2.new(0.08, 0, 0.12, 0)
gasFrame.Position = UDim2.new(0.14, 0, 0.85, 0)
gasFrame.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
gasFrame.BorderSizePixel = 0
gasFrame.Visible = false
gasFrame.Parent = screenGui

local gasCorner = Instance.new("UICorner")
gasCorner.CornerRadius = UDim.new(0, 12)
gasCorner.Parent = gasFrame

local gasLabel = Instance.new("TextLabel")
gasLabel.Size = UDim2.new(1, 0, 0.4, 0)
gasLabel.Position = UDim2.new(0, 0, 0.55, 0)
gasLabel.BackgroundTransparency = 1
gasLabel.Text = "GAS\nW"
gasLabel.TextColor3 = Color3.new(1, 1, 1)
gasLabel.TextScaled = true
gasLabel.Font = Enum.Font.GothamBold
gasLabel.Parent = gasFrame

-- Shifter (bas-droite)
local shifterFrame = Instance.new("Frame")
shifterFrame.Name = "Shifter"
shifterFrame.Size = UDim2.new(0.1, 0, 0.15, 0)
shifterFrame.Position = UDim2.new(0.88, 0, 0.82, 0)
shifterFrame.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
shifterFrame.BorderSizePixel = 0
shifterFrame.Visible = false
shifterFrame.Parent = screenGui

local shifterCorner = Instance.new("UICorner")
shifterCorner.CornerRadius = UDim.new(0, 12)
shifterCorner.Parent = shifterFrame

local shifterStroke = Instance.new("UIStroke")
shifterStroke.Color = Color3.fromRGB(150, 150, 150)
shifterStroke.Thickness = 3
shifterStroke.Parent = shifterFrame

local shifterLabel = Instance.new("TextLabel")
shifterLabel.Size = UDim2.new(1, 0, 0.5, 0)
shifterLabel.Position = UDim2.new(0, 0, 0.05, 0)
shifterLabel.BackgroundTransparency = 1
shifterLabel.Text = "SHIFT"
shifterLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
shifterLabel.TextScaled = true
shifterLabel.Font = Enum.Font.GothamBold
shifterLabel.Parent = shifterFrame

local shifterKey = Instance.new("TextLabel")
shifterKey.Size = UDim2.new(1, 0, 0.4, 0)
shifterKey.Position = UDim2.new(0, 0, 0.55, 0)
shifterKey.BackgroundTransparency = 1
shifterKey.Text = "E"
shifterKey.TextColor3 = Color3.fromRGB(255, 200, 50)
shifterKey.TextScaled = true
shifterKey.Font = Enum.Font.GothamBold
shifterKey.Parent = shifterFrame

-- Notification label
local notifLabel = Instance.new("TextLabel")
notifLabel.Size = UDim2.new(0.4, 0, 0.08, 0)
notifLabel.Position = UDim2.new(0.3, 0, 0.1, 0)
notifLabel.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
notifLabel.BackgroundTransparency = 0.3
notifLabel.Text = ""
notifLabel.TextColor3 = Color3.new(1, 1, 1)
notifLabel.TextScaled = true
notifLabel.Font = Enum.Font.GothamBold
notifLabel.Visible = false
notifLabel.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 8)
notifCorner.Parent = notifLabel

-- 🎮 CONTRÔLES TACTILES POUR MOBILE
local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Bouton Gauche (steering left)
local leftButton = Instance.new("TextButton")
leftButton.Name = "LeftButton"
leftButton.Size = UDim2.new(0, 80, 0, 80)
leftButton.Position = UDim2.new(0, 20, 1, -180)
leftButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
leftButton.Text = "◀"
leftButton.TextSize = 40
leftButton.TextColor3 = Color3.new(1, 1, 1)
leftButton.Font = Enum.Font.GothamBold
leftButton.Visible = false
leftButton.Parent = screenGui

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 10)
leftCorner.Parent = leftButton

-- Bouton Droite (steering right)
local rightButton = Instance.new("TextButton")
rightButton.Name = "RightButton"
rightButton.Size = UDim2.new(0, 80, 0, 80)
rightButton.Position = UDim2.new(0, 110, 1, -180)
rightButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
rightButton.Text = "▶"
rightButton.TextSize = 40
rightButton.TextColor3 = Color3.new(1, 1, 1)
rightButton.Font = Enum.Font.GothamBold
rightButton.Visible = false
rightButton.Parent = screenGui

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 10)
rightCorner.Parent = rightButton

-- Bouton Gaz (throttle)
local throttleButton = Instance.new("TextButton")
throttleButton.Name = "ThrottleButton"
throttleButton.Size = UDim2.new(0, 80, 0, 80)
throttleButton.Position = UDim2.new(1, -190, 1, -180)
throttleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
throttleButton.Text = "⬆"
throttleButton.TextSize = 40
throttleButton.TextColor3 = Color3.new(1, 1, 1)
throttleButton.Font = Enum.Font.GothamBold
throttleButton.Visible = false
throttleButton.Parent = screenGui

local throttleCorner = Instance.new("UICorner")
throttleCorner.CornerRadius = UDim.new(0, 10)
throttleCorner.Parent = throttleButton

-- Bouton Frein (brake)
local brakeButton = Instance.new("TextButton")
brakeButton.Name = "BrakeButton"
brakeButton.Size = UDim2.new(0, 80, 0, 80)
brakeButton.Position = UDim2.new(1, -100, 1, -180)
brakeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
brakeButton.Text = "⬇"
brakeButton.TextSize = 40
brakeButton.TextColor3 = Color3.new(1, 1, 1)
brakeButton.Font = Enum.Font.GothamBold
brakeButton.Visible = false
brakeButton.Parent = screenGui

local brakeButtonCorner = Instance.new("UICorner")
brakeButtonCorner.CornerRadius = UDim.new(0, 10)
brakeButtonCorner.Parent = brakeButton

-- Bouton Shift (changement de vitesse)
local shiftButton = Instance.new("TextButton")
shiftButton.Name = "ShiftButton"
shiftButton.Size = UDim2.new(0, 100, 0, 60)
shiftButton.Position = UDim2.new(0.5, -50, 0, 150)
shiftButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
shiftButton.Text = "SHIFT ⬆"
shiftButton.TextSize = 24
shiftButton.TextColor3 = Color3.fromRGB(0, 0, 0)
shiftButton.Font = Enum.Font.GothamBold
shiftButton.Visible = false
shiftButton.Parent = screenGui

local shiftButtonCorner = Instance.new("UICorner")
shiftButtonCorner.CornerRadius = UDim.new(0, 10)
shiftButtonCorner.Parent = shiftButton

-- Gestion des boutons tactiles
leftButton.MouseButton1Down:Connect(function()
    steeringValue = -1
    SetSteering:FireServer(-1)
    leftButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
end)

leftButton.MouseButton1Up:Connect(function()
    if steeringValue == -1 then
        steeringValue = 0
        SetSteering:FireServer(0)
    end
    leftButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
end)

rightButton.MouseButton1Down:Connect(function()
    steeringValue = 1
    SetSteering:FireServer(1)
    rightButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
end)

rightButton.MouseButton1Up:Connect(function()
    if steeringValue == 1 then
        steeringValue = 0
        SetSteering:FireServer(0)
    end
    rightButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
end)

throttleButton.MouseButton1Down:Connect(function()
    if not isThrottling then
        isThrottling = true
        SetThrottle:FireServer(true)
    end
    throttleButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
end)

throttleButton.MouseButton1Up:Connect(function()
    if isThrottling then
        isThrottling = false
        SetThrottle:FireServer(false)
    end
    throttleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
end)

brakeButton.MouseButton1Down:Connect(function()
    if not isBraking then
        isBraking = true
        SetBrake:FireServer(true)
    end
    brakeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
end)

brakeButton.MouseButton1Up:Connect(function()
    if isBraking then
        isBraking = false
        SetBrake:FireServer(false)
    end
    brakeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

shiftButton.MouseButton1Click:Connect(function()
    ShiftGear:FireServer()
end)

-- Find current kart
local function findPlayerKart()
    local character = player.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoid.SeatPart then return nil end
    
    local seat = humanoid.SeatPart
    if seat.Name == "DriverSeat" then
        return seat.Parent
    end
    
    return nil
end

-- Update UI
local function updateUI()
    local kart = findPlayerKart()
    
    if kart and kart.PrimaryPart then
        currentKart = kart
        dashFrame.Visible = true
        brakeFrame.Visible = true
        gasFrame.Visible = true
        shifterFrame.Visible = true
        
        -- Afficher les boutons tactiles sur mobile
        if isTouchDevice then
            leftButton.Visible = true
            rightButton.Visible = true
            throttleButton.Visible = true
            brakeButton.Visible = true
            shiftButton.Visible = true
        end
        
        local gear = kart.PrimaryPart:GetAttribute("Gear") or 1
        local rpm = kart.PrimaryPart:GetAttribute("RPM") or 1000
        
        gearLabel.Text = "GEAR\n" .. gear
        rpmLabel.Text = "RPM\n" .. rpm
        
        local rpmPercent = math.clamp((rpm - 1000) / (7000 - 1000), 0, 1)
        rpmBarFg.Size = UDim2.new(rpmPercent, 0, 1, 0)
        
        if rpm >= 6500 then
            rpmBarFg.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        elseif rpm >= 6000 then
            rpmBarFg.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        elseif rpm >= 5000 then
            rpmBarFg.BackgroundColor3 = Color3.fromRGB(255, 255, 50)
        else
            rpmBarFg.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        -- Effet visuel pédale gaz
        if isThrottling then
            gasFrame.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        else
            gasFrame.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end
        
        -- Effet visuel pédale frein
        if isBraking then
            brakeFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        else
            brakeFrame.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        end
    else
        currentKart = nil
        dashFrame.Visible = false
        brakeFrame.Visible = false
        gasFrame.Visible = false
        shifterFrame.Visible = false
        
        -- Masquer les boutons tactiles
        leftButton.Visible = false
        rightButton.Visible = false
        throttleButton.Visible = false
        brakeButton.Visible = false
        shiftButton.Visible = false
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
        if not isThrottling then
            isThrottling = true
            SetThrottle:FireServer(true)
        end
    elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
        if not isBraking then
            isBraking = true
            SetBrake:FireServer(true)
        end
    elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
        steeringValue = -1
        SetSteering:FireServer(-1)
    elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
        steeringValue = 1
        SetSteering:FireServer(1)
    elseif input.KeyCode == Enum.KeyCode.E then
        ShiftGear:FireServer()
    elseif input.KeyCode == Enum.KeyCode.F then
        if currentKart then
            RequestKartDespawn:FireServer()
        else
            RequestKartSpawn:FireServer()
        end
    elseif input.KeyCode == Enum.KeyCode.B then
        RequestKartPurchase:FireServer()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
        if isThrottling then
            isThrottling = false
            SetThrottle:FireServer(false)
        end
    elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
        if isBraking then
            isBraking = false
            SetBrake:FireServer(false)
        end
    elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
        if steeringValue == -1 then
            steeringValue = 0
            SetSteering:FireServer(0)
        end
    elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
        if steeringValue == 1 then
            steeringValue = 0
            SetSteering:FireServer(0)
        end
    end
end)

-- Notification handler
NotifyKartStatus.OnClientEvent:Connect(function(message)
    notifLabel.Text = message
    notifLabel.Visible = true
    
    task.delay(3, function()
        notifLabel.Visible = false
    end)
end)

-- Update loop
RunService.RenderStepped:Connect(function()
    updateUI()
end)

print("✅ GolfKartController chargé")
