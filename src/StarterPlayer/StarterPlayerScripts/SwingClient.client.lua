local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local swingFolder = remotesFolder:WaitForChild("SwingGame")
local pushEvent = swingFolder:WaitForChild("PushSwing")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")
local MiniGamesConfig = require(ConfigFolder:WaitForChild("MiniGamesConfig"))
local swingCfg = MiniGamesConfig.SwingGame or {}
local swingSeatNames = {}

local function registerSeatName(name)
    if name and name ~= "" then
        swingSeatNames[name] = true
    end
end

if typeof(swingCfg.Swings) == "table" then
    for _, cfg in ipairs(swingCfg.Swings) do
        registerSeatName(cfg.SeatName)
    end
end

if not next(swingSeatNames) then
    registerSeatName(swingCfg.SeatName)
end

if not next(swingSeatNames) then
    swingSeatNames["SwingSeat"] = true
end

local forwardKeys = {}
for _, keyCode in ipairs(swingCfg.ForwardKeys or {}) do
    forwardKeys[keyCode] = true
end

local backwardKeys = {}
for _, keyCode in ipairs(swingCfg.BackwardKeys or {}) do
    backwardKeys[keyCode] = true
end

local function isOnSwingSeat()
    local character = player.Character
    if not character then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local seatPart = humanoid.SeatPart
    return seatPart ~= nil and swingSeatNames[seatPart.Name]
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end
    if not isOnSwingSeat() then
        return
    end

    local keyCode = input.KeyCode
    if forwardKeys[keyCode] then
        pushEvent:FireServer(1)
    elseif backwardKeys[keyCode] then
        pushEvent:FireServer(-1)
    end
end)
