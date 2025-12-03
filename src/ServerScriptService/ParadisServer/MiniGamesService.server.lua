local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")

local function buildDefaultMiniGamesConfig()
    return {
        SwingGame = {
            PivotPosition = Vector3.new(-120, 8, 60),
            SeatOffset = Vector3.new(0, -6, 0),
            RewardPerFullLoop = 5,
            MinRadius = 3,
            PushAngularImpulse = 4,
            ForwardKeys = { Enum.KeyCode.W, Enum.KeyCode.Up },
            BackwardKeys = { Enum.KeyCode.S, Enum.KeyCode.Down },
            ModelName = "Swing",
            PivotName = "SwingPivot",
            SeatName = "Seat",
            AutoCreateModel = false,
            Swings = {
                {
                    ModelName = "Swing",
                    PivotName = "SwingPivot",
                    SeatName = "Seat",
                },
                {
                    ModelName = "Swing2",
                    PivotName = "SwingPivot",
                    SeatName = "Seat",
                },
            },
            ComboWindowSeconds = 3,
            ComboBonusPerLoop = 2,
        },
        FishingGame = {
            Spots = {
                { Name = "FishingSpot1", Position = Vector3.new(-60, 1, -150) },
                { Name = "FishingSpot2", Position = Vector3.new(-20, 1, -170) },
                { Name = "FishingSpot3", Position = Vector3.new(20, 1, -180) },
                { Name = "FishingSpot4", Position = Vector3.new(60, 1, -170) },
                { Name = "FishingSpot5", Position = Vector3.new(100, 1, -160) },
            },
            FishRewards = {
                Small = { Label = "Petit poisson", MinReward = 3, MaxReward = 7 },
                Medium = { Label = "Poisson moyen", MinReward = 8, MaxReward = 15 },
                Large = { Label = "Gros poisson", MinReward = 16, MaxReward = 30 },
                Rare = { Label = "Poisson rare", MinReward = 31, MaxReward = 60 },
            },
            FishProbabilities = {
                Small = 0.45,
                Medium = 0.30,
                Large = 0.20,
                Rare = 0.05,
            },
            CooldownSeconds = 5,
        },
    }
end

local function loadMiniGamesDefaults()
    local paradisFolder = ServerScriptService:FindFirstChild("ParadisServer") or script.Parent
    local module = paradisFolder and paradisFolder:FindFirstChild("MiniGamesConfigDefaults")
    if module and module:IsA("ModuleScript") then
        local ok, data = pcall(require, module)
        if ok and type(data) == "table" then
            return data
        end
        warn("[Paradis][MiniGames] MiniGamesConfigDefaults require a échoué, utilisation des valeurs par défaut locales.", data)
    else
        warn("[Paradis][MiniGames] MiniGamesConfigDefaults absent, utilisation des valeurs par défaut locales.")
    end
    return buildDefaultMiniGamesConfig()
end

local MiniGamesDefaults = loadMiniGamesDefaults()
-- Log réduit: config chargée

local function resolveConfigModule(folder, childName, contextLabel)
    local container = folder:WaitForChild(childName)
    local className = container.ClassName
    -- Module localisé (log silencieux)
    if container:IsA("ModuleScript") then
        return container
    end

    if className == "ModuleScript" then
        return container
    end

    local descendant = container:FindFirstChildWhichIsA("ModuleScript", true)
    if descendant then
        print(string.format("[Paradis][%s] ModuleScript imbriqué utilisé (%s)", contextLabel, descendant:GetFullName()))
        return descendant
    end

    error(string.format("[Paradis][%s] %s doit contenir un ModuleScript", contextLabel, childName))
end

local miniGamesModule = resolveConfigModule(ConfigFolder, "MiniGamesConfig", "MiniGames")
local moduleClone = miniGamesModule
if not miniGamesModule:IsDescendantOf(ServerScriptService) then
    moduleClone = miniGamesModule:Clone()
    moduleClone.Name = "MiniGamesConfig_ServerCopy"
    moduleClone.Parent = ServerScriptService
end

local success, moduleResult = pcall(require, moduleClone)
if moduleClone ~= miniGamesModule then
    moduleClone:Destroy()
end
if not success then
    warn("[Paradis][MiniGames] Impossible de require MiniGamesConfig:", moduleResult)
end
local MiniGamesConfig = success and moduleResult or MiniGamesDefaults

local function waitForShared(key)
    while not shared[key] do
        task.wait()
    end
    return shared[key]
end

local EconomyService = shared.ParadisEconomyService
if not EconomyService then
    task.spawn(function()
        EconomyService = waitForShared("ParadisEconomyService")
    end)
end

local function addCash(player, amount)
    if not player or amount == 0 then
        return
    end

    if EconomyService and typeof(EconomyService.AddCash) == "function" then
        EconomyService.AddCash(player, amount)
        return
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
    if cashValue then
        cashValue.Value += amount
    else
        warn("[Paradis][MiniGames] Impossible d'ajouter de l'argent à", player and player.Name)
    end
end
-- Fishing game -----------------------------------------------------------
local fishingCfg = MiniGamesConfig.FishingGame or {}
local fishingCooldowns = {}
local fishingConnections = {}

local fishProbabilityOrder = {}
for fishType in pairs(fishingCfg.FishProbabilities or {}) do
    table.insert(fishProbabilityOrder, fishType)
end
if #fishProbabilityOrder == 0 then
    fishProbabilityOrder = { "Small", "Medium", "Large", "Rare" }
else
    table.sort(fishProbabilityOrder)
end

local function chooseFishType()
    local r = math.random()
    local cumulative = 0
    for _, fishType in ipairs(fishProbabilityOrder) do
        local prob = fishingCfg.FishProbabilities and fishingCfg.FishProbabilities[fishType] or 0
        cumulative += prob
        if r <= cumulative then
            return fishType
        end
    end
    return fishProbabilityOrder[#fishProbabilityOrder] or "Small"
end

local function handleFishing(player)
    local now = os.time()
    local nextAllowed = fishingCooldowns[player] or 0
    if now < nextAllowed then
        return
    end

    fishingCooldowns[player] = now + (fishingCfg.CooldownSeconds or 5)

    local fishType = chooseFishType()
    local rewards = fishingCfg.FishRewards or {}
    local fishInfo = rewards[fishType] or rewards.Small
    if not fishInfo then
        return
    end

    local reward = math.random(fishInfo.MinReward, fishInfo.MaxReward)
    addCash(player, reward)
    print(string.format("[Paradis][MiniGames] %s a pêché un %s (+%d $)", player.Name, fishInfo.Label, reward))
end

local function bindPrompt(prompt)
    if fishingConnections[prompt] then
        return
    end
    fishingConnections[prompt] = prompt.Triggered:Connect(handleFishing)
end

local function scanFishingArea()
    local folder = Workspace:FindFirstChild("FishingArea")
    if not folder then
        return
    end
    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Name == "FishPrompt" then
            bindPrompt(descendant)
        end
    end
end

-- Système de pêche désactivé : remplacé par FishingSystem.server.lua
--[[
scanFishingArea()
Workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") and descendant.Name == "FishPrompt" then
        bindPrompt(descendant)
    elseif descendant.Name == "FishingArea" then
        task.defer(scanFishingArea)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    fishingCooldowns[player] = nil
end)
]]

print("[Paradis][MiniGames] Mini-jeu de pêche désactivé (voir FishingSystem.server.lua).")
