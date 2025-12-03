local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
        warn("[Paradis][SwingGame] MiniGamesConfigDefaults require a échoué, utilisation des valeurs par défaut locales.", data)
    else
        warn("[Paradis][SwingGame] MiniGamesConfigDefaults absent, utilisation des valeurs par défaut locales.")
    end
    return buildDefaultMiniGamesConfig()
end

local MiniGamesDefaults = loadMiniGamesDefaults()

local function resolveConfigModule(folder, childName, contextLabel)
    local container = folder:WaitForChild(childName)
    local className = container.ClassName
    -- Résolution silencieuse du module de configuration (logs réduits)
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

local miniGamesModule = resolveConfigModule(ConfigFolder, "MiniGamesConfig", "SwingGame")
local moduleClone = miniGamesModule
if not miniGamesModule:IsDescendantOf(ServerScriptService) then
    moduleClone = miniGamesModule:Clone()
    moduleClone.Name = "MiniGamesConfig_ServerCopy"
    moduleClone.Parent = ServerScriptService
end

local success, moduleResult = pcall(require, moduleClone)
if not success then
    warn("[Paradis][SwingGame] Impossible de require MiniGamesConfig:", moduleResult)
end
if moduleClone ~= miniGamesModule then
    moduleClone:Destroy()
end
local MiniGamesConfig = success and moduleResult or MiniGamesDefaults
local swingCfg = (MiniGamesConfig and MiniGamesConfig.SwingGame) or MiniGamesDefaults.SwingGame or {}

local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local EconomyService = shared.ParadisEconomyService
if not EconomyService then
    task.spawn(function()
        EconomyService = waitForShared("ParadisEconomyService")
    end)
end

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local swingFolder = remotesFolder:FindFirstChild("SwingGame")
if not swingFolder then
    swingFolder = Instance.new("Folder")
    swingFolder.Name = "SwingGame"
    swingFolder.Parent = remotesFolder
end

local pushEvent = swingFolder:FindFirstChild("PushSwing")
if not pushEvent then
    pushEvent = Instance.new("RemoteEvent")
    pushEvent.Name = "PushSwing"
    pushEvent.Parent = swingFolder
end

local comboEvent = swingFolder:FindFirstChild("SwingComboUpdate")
if not comboEvent then
    comboEvent = Instance.new("RemoteEvent")
    comboEvent.Name = "SwingComboUpdate"
    comboEvent.Parent = swingFolder
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
        warn("[Paradis][SwingGame] Impossible d'ajouter du Cash à", player.Name)
    end
end

local swingConfigs = {}
if typeof(swingCfg.Swings) == "table" and #swingCfg.Swings > 0 then
    for _, cfg in ipairs(swingCfg.Swings) do
        table.insert(swingConfigs, cfg)
    end
else
    table.insert(swingConfigs, swingCfg)
end

local function getValue(cfg, key)
    if cfg[key] ~= nil then
        return cfg[key]
    end
    return swingCfg[key]
end

local function createRig(cfg)
    return {
        config = cfg,
        model = nil,
        pivot = nil,
        axis = nil,
        forwardBasis = nil,
        upBasis = nil,
        state = {},
        welds = {},
    }
end

local swingRigs = {}
for _, cfg in ipairs(swingConfigs) do
    table.insert(swingRigs, createRig(cfg))
end

local function refreshRig(rig)
    local cfg = rig.config
    local modelName = getValue(cfg, "ModelName") or "SwingGame"
    local model = Workspace:FindFirstChild(modelName, true)
    if not model and modelName ~= "SwingGame" then
        model = Workspace:FindFirstChild("SwingGame", true)
    end
    if not model then
        model = Workspace:FindFirstChild("Swing", true)
    end

    if model and model:IsA("Model") then
        rig.model = model
    else
        rig.model = nil
        rig.pivot = nil
        return
    end

    local pivotName = getValue(cfg, "PivotName")
    local pivot
    if pivotName and pivotName ~= "" then
        pivot = rig.model:FindFirstChild(pivotName, true)
        if pivot and not pivot:IsA("BasePart") then
            pivot = nil
        end
    end
    if not pivot then
        for _, descendant in ipairs(rig.model:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant.Anchored then
                pivot = descendant
                break
            end
        end
    end
    rig.pivot = pivot

    if rig.pivot then
        local axis = rig.pivot.CFrame.RightVector
        if axis.Magnitude < 1e-3 then
            axis = Vector3.new(1, 0, 0)
        else
            axis = axis.Unit
        end

        local function orthonormalize(reference)
            reference = reference - axis * reference:Dot(axis)
            if reference.Magnitude < 1e-3 then
                return nil
            end
            return reference.Unit
        end

        local forward = orthonormalize(rig.pivot.CFrame.LookVector)
        if not forward then
            forward = orthonormalize(rig.pivot.CFrame.UpVector)
        end
        if not forward then
            local fallback = axis:Cross(Vector3.new(0, 1, 0))
            if fallback.Magnitude < 1e-3 then
                fallback = axis:Cross(Vector3.new(1, 0, 0))
            end
            forward = orthonormalize(fallback) or Vector3.new(0, 0, 1)
        end

        local up = axis:Cross(forward)
        if up.Magnitude < 1e-3 then
            local fallback = axis:Cross(Vector3.new(0, 1, 0))
            if fallback.Magnitude < 1e-3 then
                fallback = axis:Cross(Vector3.new(1, 0, 0))
            end
            up = fallback.Unit
        else
            up = up.Unit
        end

        rig.axis = axis
        rig.forwardBasis = forward
        rig.upBasis = up
    else
        rig.axis = nil
        rig.forwardBasis = nil
        rig.upBasis = nil
    end
end

local function ensureRigReady(rig)
    if not rig.model or not rig.model.Parent then
        refreshRig(rig)
    elseif not rig.pivot or not rig.pivot.Parent then
        refreshRig(rig)
    end
    return rig.model ~= nil and rig.model.Parent ~= nil and rig.pivot ~= nil and rig.pivot.Parent ~= nil
end

local function getSeatForPlayerOnRig(player, rig)
    local character = player.Character
    if not character then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    local seatPart = humanoid.SeatPart
    if not seatPart then
        return nil
    end
    if rig.model and seatPart:IsDescendantOf(rig.model) then
        return seatPart
    end
    local seatName = getValue(rig.config, "SeatName")
    if seatName and seatName ~= "" and seatPart.Name == seatName then
        return seatPart
    end
    return nil
end

local function resetSwingState(rig, player)
    local state = rig.state[player]
    if state then
        state.lastAngle = nil
        state.accumulated = 0
        state.comboCount = 0
        state.lastLoopTime = nil
    end
end

local function resetAllStates(rig)
    for player in pairs(rig.state) do
        resetSwingState(rig, player)
    end
end

local function detachPlayerFromSeat(rig, player)
    local weld = rig.welds[player]
    if weld then
        weld:Destroy()
        rig.welds[player] = nil
    end
end

local function attachPlayerToSeat(rig, player, seatPart)
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    rootPart.Anchored = false
    local existing = rig.welds[player]
    if existing then
        if existing.Part0 == seatPart and existing.Part1 == rootPart then
            return
        end
        existing:Destroy()
        rig.welds[player] = nil
    end

    local weld = Instance.new("WeldConstraint")
    weld.Name = "SwingSeatWeld"
    weld.Part0 = seatPart
    weld.Part1 = rootPart
    weld.Parent = seatPart
    rig.welds[player] = weld
end

local function getRigAndSeatForPlayer(player)
    for _, rig in ipairs(swingRigs) do
        if ensureRigReady(rig) then
            local seatPart = getSeatForPlayerOnRig(player, rig)
            if seatPart then
                attachPlayerToSeat(rig, player, seatPart)
                return rig, seatPart
            end
        end
    end
    return nil, nil
end

pushEvent.OnServerEvent:Connect(function(player, direction)
    if direction ~= 1 and direction ~= -1 then
        return
    end

    local rig, seatPart = getRigAndSeatForPlayer(player)
    if not rig or not seatPart then
        return
    end

    local impulseMagnitude = getValue(rig.config, "PushAngularImpulse") or getValue(swingCfg, "PushAngularImpulse") or 0
    if impulseMagnitude <= 0 then
        return
    end

    local axis = rig.axis or (rig.pivot and rig.pivot.CFrame.RightVector)
    local targetPart = seatPart.AssemblyRootPart or seatPart
    if not targetPart then
        return
    end

    local impulse = axis * (impulseMagnitude * direction)
    targetPart:ApplyAngularImpulse(impulse)
end)

RunService.Heartbeat:Connect(function()
    for _, rig in ipairs(swingRigs) do
        if not ensureRigReady(rig) then
            resetAllStates(rig)
            for player in pairs(rig.welds) do
                detachPlayerFromSeat(rig, player)
            end
            continue
        end

        for _, player in ipairs(Players:GetPlayers()) do
            local seatPart = getSeatForPlayerOnRig(player, rig)
            if not seatPart then
                resetSwingState(rig, player)
                detachPlayerFromSeat(rig, player)
                continue
            end

            attachPlayerToSeat(rig, player, seatPart)

            local axis = rig.axis
            local forward = rig.forwardBasis
            local up = rig.upBasis
            if not axis or not forward or not up then
                resetSwingState(rig, player)
                continue
            end

            local pivotPos = rig.pivot.Position
            local seatPos = seatPart.Position
            local relative = seatPos - pivotPos
            local planar = relative - axis * relative:Dot(axis)
            local radius = planar.Magnitude
            if radius < (getValue(rig.config, "MinRadius") or swingCfg.MinRadius or 0) then
                resetSwingState(rig, player)
                continue
            end

            local x = planar:Dot(forward)
            local y = planar:Dot(up)
            local angle = math.atan2(y, x)
            local state = rig.state[player]
            if not state then
                rig.state[player] = {
                    lastAngle = angle,
                    accumulated = 0,
                    comboCount = 0,
                    lastLoopTime = nil,
                }
            else
                local delta = angle - (state.lastAngle or angle)
                if delta > math.pi then
                    delta -= 2 * math.pi
                elseif delta < -math.pi then
                    delta += 2 * math.pi
                end

                state.accumulated += math.deg(math.abs(delta))
                state.lastAngle = angle

                if state.accumulated >= 360 then
                    state.accumulated -= 360
                    local baseReward = getValue(rig.config, "RewardPerFullLoop") or swingCfg.RewardPerFullLoop or 0
                    local comboWindow = getValue(rig.config, "ComboWindowSeconds") or swingCfg.ComboWindowSeconds or 0
                    local comboBonus = getValue(rig.config, "ComboBonusPerLoop") or swingCfg.ComboBonusPerLoop or 0
                    local now = os.clock()

                    if comboWindow > 0 and state.lastLoopTime and (now - state.lastLoopTime) <= comboWindow then
                        state.comboCount = (state.comboCount or 1) + 1
                    else
                        state.comboCount = 1
                    end
                    state.lastLoopTime = now

                    local reward = baseReward
                    if comboBonus > 0 and state.comboCount > 1 then
                        reward += comboBonus * (state.comboCount - 1)
                    end

                    if reward > 0 then
                        addCash(player, reward)
                        comboEvent:FireClient(player, state.comboCount or 1, reward)
                    end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    for _, rig in ipairs(swingRigs) do
        rig.state[player] = nil
        detachPlayerFromSeat(rig, player)
    end
end)

print("[Paradis][SwingGame] Service de balançoire initialisé.")
