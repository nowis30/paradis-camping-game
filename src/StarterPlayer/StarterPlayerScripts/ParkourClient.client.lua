local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ParkourRemotes = ReplicatedStorage:WaitForChild("ParkourRemotes")
local StartParkour = ParkourRemotes:WaitForChild("StartParkour")
local FinishParkour = ParkourRemotes:WaitForChild("FinishParkour")
local CancelParkour = ParkourRemotes:WaitForChild("CancelParkour")
local UpdateTimer = ParkourRemotes:WaitForChild("UpdateTimer")
local ParkourResult = ParkourRemotes:WaitForChild("ParkourResult")

local inParkour = false

-- Créer l'UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ParkourGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Frame du timer (en haut au centre)
local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.Size = UDim2.new(0.35, 0, 0.08, 0)
timerFrame.Position = UDim2.new(0.325, 0, 0.05, 0)
timerFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
timerFrame.BorderSizePixel = 0
timerFrame.Visible = false
timerFrame.Parent = screenGui

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 10)
timerCorner.Parent = timerFrame

local timerStroke = Instance.new("UIStroke")
timerStroke.Color = Color3.fromRGB(255, 200, 50)
timerStroke.Thickness = 3
timerStroke.Parent = timerFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 1, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "⏱️ 0.00 s"
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = timerFrame

-- Bouton Quitter
local quitButton = Instance.new("TextButton")
quitButton.Name = "QuitButton"
quitButton.Size = UDim2.new(0.15, 0, 0.06, 0)
quitButton.Position = UDim2.new(0.425, 0, 0.14, 0)
quitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
quitButton.BorderSizePixel = 0
quitButton.Text = "❌ QUITTER"
quitButton.TextColor3 = Color3.new(1, 1, 1)
quitButton.TextScaled = true
quitButton.Font = Enum.Font.GothamBold
quitButton.Visible = false
quitButton.Parent = screenGui

local quitCorner = Instance.new("UICorner")
quitCorner.CornerRadius = UDim.new(0, 8)
quitCorner.Parent = quitButton

-- Meilleur temps (en haut à droite)
local bestFrame = Instance.new("Frame")
bestFrame.Name = "BestFrame"
bestFrame.Size = UDim2.new(0.25, 0, 0.07, 0)
bestFrame.Position = UDim2.new(0.73, 0, 0.05, 0)
bestFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
bestFrame.BorderSizePixel = 0
bestFrame.Visible = false
bestFrame.Parent = screenGui

local bestCorner = Instance.new("UICorner")
bestCorner.CornerRadius = UDim.new(0, 8)
bestCorner.Parent = bestFrame

local bestLabel = Instance.new("TextLabel")
bestLabel.Size = UDim2.new(1, 0, 1, 0)
bestLabel.BackgroundTransparency = 1
bestLabel.Text = "🏆 Meilleur: --"
bestLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
bestLabel.TextScaled = true
bestLabel.Font = Enum.Font.GothamBold
bestLabel.Parent = bestFrame

-- Panel de résultats
local resultFrame = Instance.new("Frame")
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(0.45, 0, 0.5, 0)
resultFrame.Position = UDim2.new(0.275, 0, 0.25, 0)
resultFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
resultFrame.BorderSizePixel = 0
resultFrame.Visible = false
resultFrame.Parent = screenGui

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 12)
resultCorner.Parent = resultFrame

local resultStroke = Instance.new("UIStroke")
resultStroke.Color = Color3.fromRGB(100, 150, 255)
resultStroke.Thickness = 3
resultStroke.Parent = resultFrame

local resultTitle = Instance.new("TextLabel")
resultTitle.Size = UDim2.new(0.9, 0, 0.15, 0)
resultTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
resultTitle.BackgroundTransparency = 1
resultTitle.Text = "PARCOURS TERMINÉ!"
resultTitle.TextColor3 = Color3.fromRGB(100, 255, 150)
resultTitle.TextScaled = true
resultTitle.Font = Enum.Font.GothamBold
resultTitle.Parent = resultFrame

local medalLabel = Instance.new("TextLabel")
medalLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
medalLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
medalLabel.BackgroundTransparency = 1
medalLabel.Text = "🥇 OR"
medalLabel.TextColor3 = Color3.new(1, 1, 1)
medalLabel.TextScaled = true
medalLabel.Font = Enum.Font.GothamBold
medalLabel.Parent = resultFrame

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
timeLabel.Position = UDim2.new(0.05, 0, 0.48, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "Temps: 45.32 s"
timeLabel.TextColor3 = Color3.new(1, 1, 1)
timeLabel.TextScaled = true
timeLabel.Font = Enum.Font.Gotham
timeLabel.Parent = resultFrame

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
cashLabel.Position = UDim2.new(0.05, 0, 0.63, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "Récompense: 1000$"
cashLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
cashLabel.TextScaled = true
cashLabel.Font = Enum.Font.GothamBold
cashLabel.Parent = resultFrame

local recordLabel = Instance.new("TextLabel")
recordLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
recordLabel.Position = UDim2.new(0.05, 0, 0.78, 0)
recordLabel.BackgroundTransparency = 1
recordLabel.Text = "🎉 NOUVEAU RECORD!"
recordLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
recordLabel.TextScaled = true
recordLabel.Font = Enum.Font.GothamBold
recordLabel.Visible = false
recordLabel.Parent = resultFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.4, 0, 0.12, 0)
closeButton.Position = UDim2.new(0.3, 0, 0.85, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
closeButton.BorderSizePixel = 0
closeButton.Text = "FERMER"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = resultFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Mettre à jour le meilleur temps
local function updateBestTime()
    local bestTime = player:GetAttribute("BestParkourTime")
    if bestTime then
        bestLabel.Text = string.format("🏆 Meilleur: %.2f s", bestTime)
        bestFrame.Visible = inParkour
    else
        bestLabel.Text = "🏆 Meilleur: --"
        bestFrame.Visible = false
    end
end

-- Démarrer le parcours (appelé par le serveur via zone de départ)
StartParkour.OnClientInvoke = function()
    if inParkour then
        return
    end
    
    local success, message = StartParkour:InvokeServer()
    if success then
        inParkour = true
        timerFrame.Visible = true
        quitButton.Visible = true
        updateBestTime()
    end
end

-- Finir le parcours (appelé par le serveur via zone d'arrivée)
FinishParkour.OnClientInvoke = function()
    if not inParkour then
        return
    end
    
    local success, message = FinishParkour:InvokeServer()
end

-- Mise à jour du timer
UpdateTimer.OnClientEvent:Connect(function(text)
    timerLabel.Text = text
end)

-- Résultat du parcours
ParkourResult.OnClientEvent:Connect(function(result)
    inParkour = false
    timerFrame.Visible = false
    quitButton.Visible = false
    bestFrame.Visible = false
    
    if result.success then
        medalLabel.Text = result.medal
        timeLabel.Text = string.format("Temps: %.2f s", result.time)
        cashLabel.Text = string.format("Récompense: %d$", result.cash)
        recordLabel.Visible = result.newRecord or false
        resultFrame.Visible = true
        
        -- Fermer automatiquement après 10 secondes
        task.delay(10, function()
            resultFrame.Visible = false
        end)
        
        updateBestTime()
    end
end)

-- Bouton quitter
quitButton.Activated:Connect(function()
    if inParkour then
        CancelParkour:InvokeServer()
        inParkour = false
        timerFrame.Visible = false
        quitButton.Visible = false
        bestFrame.Visible = false
    end
end)

-- Bouton fermer résultat
closeButton.Activated:Connect(function()
    resultFrame.Visible = false
end)

-- Mise à jour initiale
updateBestTime()

print("✅ ParkourClient chargé")
