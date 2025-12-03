local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourRemotes = ReplicatedStorage:WaitForChild("ParkourRemotes")
local StartParkour = ParkourRemotes:WaitForChild("StartParkour")
local FinishParkour = ParkourRemotes:WaitForChild("FinishParkour")
local CancelParkour = ParkourRemotes:WaitForChild("CancelParkour")
local UpdateTimer = ParkourRemotes:WaitForChild("UpdateTimer")
local ParkourResult = ParkourRemotes:WaitForChild("ParkourResult")

-- État des joueurs en parcours
local activePlayers = {}

-- Configuration du parcours aérien difficile
local CHECKPOINT_CONFIG = {
    -- Départ au sol
    {Position = Vector3.new(50, 3, 50), Size = Vector3.new(10, 1, 10), Color = Color3.fromRGB(50, 255, 50), Name = "DÉPART"},
    
    -- Première montée (plateformes en escalier)
    {Position = Vector3.new(60, 8, 60), Size = Vector3.new(6, 1, 6), Color = Color3.fromRGB(255, 200, 50), Name = "Point 1"},
    {Position = Vector3.new(70, 13, 65), Size = Vector3.new(5, 1, 5), Color = Color3.fromRGB(255, 200, 50), Name = "Point 2"},
    {Position = Vector3.new(75, 18, 75), Size = Vector3.new(4, 1, 4), Color = Color3.fromRGB(255, 200, 50), Name = "Point 3"},
    
    -- Saut long en hauteur
    {Position = Vector3.new(85, 23, 85), Size = Vector3.new(5, 1, 5), Color = Color3.fromRGB(255, 150, 50), Name = "Point 4"},
    
    -- Plateformes étroites en zigzag
    {Position = Vector3.new(95, 25, 80), Size = Vector3.new(3, 1, 3), Color = Color3.fromRGB(255, 150, 50), Name = "Point 5"},
    {Position = Vector3.new(100, 27, 90), Size = Vector3.new(3, 1, 3), Color = Color3.fromRGB(255, 150, 50), Name = "Point 6"},
    {Position = Vector3.new(105, 29, 85), Size = Vector3.new(3, 1, 3), Color = Color3.fromRGB(255, 150, 50), Name = "Point 7"},
    
    -- Point culminant
    {Position = Vector3.new(115, 35, 95), Size = Vector3.new(6, 1, 6), Color = Color3.fromRGB(255, 100, 50), Name = "Point 8"},
    
    -- Descente avec sauts précis
    {Position = Vector3.new(120, 30, 105), Size = Vector3.new(4, 1, 4), Color = Color3.fromRGB(255, 100, 50), Name = "Point 9"},
    {Position = Vector3.new(125, 25, 110), Size = Vector3.new(4, 1, 4), Color = Color3.fromRGB(255, 100, 50), Name = "Point 10"},
    {Position = Vector3.new(130, 20, 115), Size = Vector3.new(5, 1, 5), Color = Color3.fromRGB(255, 100, 50), Name = "Point 11"},
    
    -- Sprint final sur plateformes mobiles (simulé par petites plateformes)
    {Position = Vector3.new(135, 15, 125), Size = Vector3.new(3, 1, 3), Color = Color3.fromRGB(255, 50, 50), Name = "Point 12"},
    {Position = Vector3.new(140, 12, 130), Size = Vector3.new(3, 1, 3), Color = Color3.fromRGB(255, 50, 50), Name = "Point 13"},
    {Position = Vector3.new(145, 10, 135), Size = Vector3.new(4, 1, 4), Color = Color3.fromRGB(255, 50, 50), Name = "Point 14"},
    
    -- Arrivée
    {Position = Vector3.new(150, 5, 145), Size = Vector3.new(10, 1, 10), Color = Color3.fromRGB(255, 50, 50), Name = "ARRIVÉE"}
}

-- Récompenses ajustées pour la difficulté
local REWARD_TIERS = {
    {maxTime = 60, cash = 2000, medal = "🥇 OR"},
    {maxTime = 90, cash = 1200, medal = "🥈 ARGENT"},
    {maxTime = 120, cash = 700, medal = "🥉 BRONZE"},
    {maxTime = math.huge, cash = 300, medal = "✅ PARTICIPATION"}
}

local checkpointParts = {}
local startZone = nil
local finishZone = nil

-- Créer toutes les plateformes
local function createCheckpoints()
    local parkourFolder = Instance.new("Folder")
    parkourFolder.Name = "ParkourCourse"
    parkourFolder.Parent = workspace
    
    for i, config in ipairs(CHECKPOINT_CONFIG) do
        local part = Instance.new("Part")
        part.Name = config.Name
        part.Position = config.Position
        part.Size = config.Size
        part.Anchored = true
        part.CanCollide = true
        part.Material = Enum.Material.Neon
        part.Color = config.Color
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        
        -- Ajouter un billboard pour le nom
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "Label"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = part
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = config.Name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
        
        part.Parent = parkourFolder
        
        -- Stocker les zones spéciales
        if i == 1 then
            startZone = part
        elseif i == #CHECKPOINT_CONFIG then
            finishZone = part
        else
            table.insert(checkpointParts, part)
        end
    end
end

-- Calculer la récompense selon le temps
local function calculateReward(elapsedTime)
    for _, tier in ipairs(REWARD_TIERS) do
        if elapsedTime <= tier.maxTime then
            return tier.maxTime, tier.cash, tier.medal
        end
    end
    return REWARD_TIERS[#REWARD_TIERS].maxTime, REWARD_TIERS[#REWARD_TIERS].cash, REWARD_TIERS[#REWARD_TIERS].medal
end

-- Démarrer le parcours
StartParkour.OnServerInvoke = function(player)
    if activePlayers[player.UserId] then
        return false, "Vous êtes déjà en parcours!"
    end
    
    activePlayers[player.UserId] = {
        startTime = tick(),
        checkpoints = {},
        player = player
    }
    
    -- Countdown
    for i = 3, 1, -1 do
        UpdateTimer:FireClient(player, "DÉPART DANS " .. i .. "...")
        task.wait(1)
    end
    
    UpdateTimer:FireClient(player, "GO!")
    task.wait(0.5)
    
    -- Démarrer le timer
    activePlayers[player.UserId].startTime = tick()
    
    return true, "Parcours démarré!"
end

-- Annuler le parcours
CancelParkour.OnServerInvoke = function(player)
    if activePlayers[player.UserId] then
        activePlayers[player.UserId] = nil
        return true, "Parcours annulé"
    end
    return false, "Aucun parcours en cours"
end

-- Finir le parcours
FinishParkour.OnServerInvoke = function(player)
    local data = activePlayers[player.UserId]
    if not data then
        return false, "Aucun parcours en cours"
    end
    
    local elapsedTime = tick() - data.startTime
    local _, cash, medal = calculateReward(elapsedTime)
    
    -- Donner la récompense
    local currentCash = player:GetAttribute("Cash") or 0
    player:SetAttribute("Cash", currentCash + cash)
    
    -- Sauvegarder le meilleur temps
    local bestTime = player:GetAttribute("BestParkourTime")
    if not bestTime or elapsedTime < bestTime then
        player:SetAttribute("BestParkourTime", elapsedTime)
    end
    
    -- Notifier le client
    ParkourResult:FireClient(player, {
        success = true,
        time = elapsedTime,
        medal = medal,
        cash = cash,
        newRecord = not bestTime or elapsedTime < bestTime
    })
    
    activePlayers[player.UserId] = nil
    return true, "Parcours terminé!"
end

-- Détection automatique des zones
if startZone then
    startZone.Touched:Connect(function(hit)
        local char = hit.Parent
        local player = Players:GetPlayerFromCharacter(char)
        if player and not activePlayers[player.UserId] then
            StartParkour:InvokeClient(player)
        end
    end)
end

if finishZone then
    finishZone.Touched:Connect(function(hit)
        local char = hit.Parent
        local player = Players:GetPlayerFromCharacter(char)
        if player and activePlayers[player.UserId] then
            FinishParkour:InvokeClient(player)
        end
    end)
end

-- Boucle de mise à jour du timer
RunService.Heartbeat:Connect(function()
    for userId, data in pairs(activePlayers) do
        local elapsed = tick() - data.startTime
        if data.player and data.player.Parent then
            UpdateTimer:FireClient(data.player, string.format("⏱️ %.2f s", elapsed))
        else
            activePlayers[userId] = nil
        end
    end
end)

-- Créer le parcours au démarrage
createCheckpoints()

print("✅ ParkourService chargé - Parcours aérien difficile créé avec " .. #CHECKPOINT_CONFIG .. " plateformes")
