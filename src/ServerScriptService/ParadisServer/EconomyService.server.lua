--[[
    EconomyService
    Gère la monnaie des campeurs, les déblocages, les boosts et la persistance.
    Les autres scripts y accèdent via shared.ParadisEconomyService.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local EconomyConfig = require(configFolder:WaitForChild("EconomyConfig"))
local EconomyRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EconomyRemotes"))

local STARTING_CASH = (EconomyConfig.General and EconomyConfig.General.StartingCash) or 500
local CASH_CAP = (EconomyConfig.General and EconomyConfig.General.CashCap) or math.huge
local MAINTENANCE_RATE = (EconomyConfig.General and EconomyConfig.General.MaintenanceTaxRate) or 0
local MAINTENANCE_INTERVAL = (EconomyConfig.General and EconomyConfig.General.MaintenanceIntervalSeconds) or 0
local AUTOSAVE_INTERVAL = 120

if CASH_CAP <= 0 then
    CASH_CAP = math.huge
end

local BOOST_SETTINGS = EconomyConfig.Boosts or {}

local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local DataService = waitForShared("ParadisDataService")
local PlotService
task.spawn(function()
    PlotService = waitForShared("ParadisPlotService")
end)

local playerEconomy = {}

local boostState = {
    Active = false,
    Name = nil,
    Multiplier = 1,
    EndsAt = 0,
    NextStart = os.clock() + ((BOOST_SETTINGS.IntervalSeconds or 420)),
}

local function getBoostPayload()
    return {
        Active = boostState.Active,
        Name = boostState.Name,
        Multiplier = boostState.Multiplier,
        TimeLeft = boostState.Active and math.max(0, boostState.EndsAt - os.clock()) or 0,
    }
end

local function broadcastBoost()
    local payload = getBoostPayload()
    for _, player in ipairs(Players:GetPlayers()) do
        EconomyRemotes.BoostUpdated:FireClient(player, payload)
    end
end

local function ensureLeaderstats(player)
    local stats = player:FindFirstChild("leaderstats")
    if not stats then
        stats = Instance.new("Folder")
        stats.Name = "leaderstats"
        stats.Parent = player
    end

    local cashValue = stats:FindFirstChild("Cash")
    if not cashValue then
        cashValue = Instance.new("NumberValue")
        cashValue.Name = "Cash"
        cashValue.Value = 0
        cashValue.Parent = stats
    end

    local incomeValue = stats:FindFirstChild("IncomePerSecond")
    if not incomeValue then
        incomeValue = Instance.new("NumberValue")
        incomeValue.Name = "IncomePerSecond"
        incomeValue.Value = 0
        incomeValue.Parent = stats
    end

    return cashValue, incomeValue
end

local function roundCurrency(amount)
    return math.floor((amount or 0) * 100 + 0.5) / 100
end

local function ensureState(player)
    local state = playerEconomy[player]
    if state then
        return state
    end

    local data = DataService.LoadPlayerData(player.UserId)
    local currentCash = tonumber(data.Cash)
    if currentCash == nil then
        currentCash = STARTING_CASH
        data.Cash = currentCash
    end

    state = {
        Cash = currentCash,
        IncomePerSecond = 0,
        Data = data,
        LastMaintenance = os.clock(),
    }
    playerEconomy[player] = state
    return state
end

local function syncLeaderstats(player, state)
    local cashValue, incomeValue = ensureLeaderstats(player)
    cashValue.Value = roundCurrency(state.Cash)
    incomeValue.Value = roundCurrency(state.IncomePerSecond)
end

local function broadcastEconomy(player, state)
    EconomyRemotes.CashUpdated:FireClient(player, roundCurrency(state.Cash))
    EconomyRemotes.IncomeUpdated:FireClient(player, roundCurrency(state.IncomePerSecond))
end

local function persistPlayer(player, state)
    if not state or not state.Data then
        return false, "NO_PLAYER_DATA"
    end
    state.Data.Cash = roundCurrency(state.Cash)
    return DataService.SavePlayerData(player.UserId, state.Data)
end

local function getEconomyEntry(catalog, objectId)
    catalog = catalog == "Construction" and "Construction" or "Objects"
    return EconomyConfig.Resolve(catalog, objectId)
end

local function resolveRecordIncome(record)
    if type(record) ~= "table" then
        return 0
    end
    local catalog = record.Catalog
    local objectId

    if catalog == "Construction" or record.Type == "Construction" then
        catalog = "Construction"
        objectId = record.ConstructionId or record.ObjectId or record.Type
    else
        catalog = "Objects"
        objectId = record.Type or record.ObjectId
    end

    if not objectId then
        return tonumber(record.IncomePerSecond) or 0
    end

    local entry = getEconomyEntry(catalog, objectId)
    if (entry.IncomePerSecond or 0) == 0 then
        return tonumber(record.IncomePerSecond) or 0
    end
    return entry.IncomePerSecond
end

local EconomyAPI = {}

function EconomyAPI.GetEconomyForObject(catalog, objectId)
    if not objectId then
        return EconomyConfig.Defaults or { Cost = 0, IncomePerSecond = 0, UnlockAtIncome = 0 }
    end
    return EconomyConfig.Resolve(catalog == "Construction" and "Construction" or "Objects", objectId)
end

function EconomyAPI.GetCash(player)
    local state = ensureState(player)
    return state.Cash
end

function EconomyAPI.GetIncomePerSecond(player)
    local state = ensureState(player)
    return state.IncomePerSecond
end

function EconomyAPI.HasEnoughCash(player, cost)
    local state = ensureState(player)
    return state.Cash >= (cost or 0)
end

function EconomyAPI.GetUnlockRequirement(catalog, objectId)
    local entry = EconomyAPI.GetEconomyForObject(catalog, objectId)
    return entry.UnlockAtIncome or 0
end

function EconomyAPI.CanUseObject(player, catalog, objectId)
    local required = EconomyAPI.GetUnlockRequirement(catalog, objectId)
    local state = ensureState(player)
    return state.IncomePerSecond >= required, required
end

function EconomyAPI.AddCash(player, amount)
    if not player or not amount or amount == 0 then
        return 0
    end
    local state = ensureState(player)
    local target = roundCurrency(state.Cash + amount)
    target = math.clamp(target, 0, CASH_CAP)
    local applied = roundCurrency(target - state.Cash)
    if applied == 0 and amount ~= 0 then
        return 0
    end
    state.Cash = target
    state.Data.Cash = state.Cash
    syncLeaderstats(player, state)
    broadcastEconomy(player, state)
    return applied
end

function EconomyAPI.AddIncomeSource(player, amount)
    if not player or not amount or amount == 0 then
        return
    end
    local state = ensureState(player)
    state.IncomePerSecond = roundCurrency(math.max(0, state.IncomePerSecond + amount))
    syncLeaderstats(player, state)
    EconomyRemotes.IncomeUpdated:FireClient(player, state.IncomePerSecond)
end

function EconomyAPI.RemoveIncomeSource(player, amount)
    if not amount or amount == 0 then
        return
    end
    EconomyAPI.AddIncomeSource(player, -amount)
end

function EconomyAPI.RecalculateIncome(player, objectList)
    local state = ensureState(player)
    local total = 0

    local list = objectList
    if not list and PlotService and PlotService.GetPlotForPlayer then
        local plot = PlotService.GetPlotForPlayer(player)
        list = plot and plot.PlacedObjects
    end

    if type(list) == "table" then
        for _, record in ipairs(list) do
            total += resolveRecordIncome(record)
        end
    end

    state.IncomePerSecond = roundCurrency(total)
    syncLeaderstats(player, state)
    EconomyRemotes.IncomeUpdated:FireClient(player, state.IncomePerSecond)
    return state.IncomePerSecond
end

function EconomyAPI.GetBoost()
    return getBoostPayload()
end

EconomyRemotes.RequestSnapshot.OnServerInvoke = function(player)
    local state = ensureState(player)
    return {
        Cash = roundCurrency(state.Cash),
        IncomePerSecond = roundCurrency(state.IncomePerSecond),
        Boost = getBoostPayload(),
    }
end

EconomyRemotes.RequestManualSave.OnServerInvoke = function(player)
    local state = ensureState(player)
    local saved, reason = persistPlayer(player, state)
    return {
        Success = saved == true,
        Error = not saved and reason or nil,
        Cash = roundCurrency(state.Cash),
        Timestamp = os.time(),
    }
end

local function handlePlayerAdded(player)
    local state = ensureState(player)
    syncLeaderstats(player, state)
    broadcastEconomy(player, state)
    EconomyRemotes.BoostUpdated:FireClient(player, getBoostPayload())
end

local function handlePlayerRemoving(player)
    local state = playerEconomy[player]
    if state then
        persistPlayer(player, state)
        playerEconomy[player] = nil
    end
end

Players.PlayerAdded:Connect(handlePlayerAdded)
Players.PlayerRemoving:Connect(handlePlayerRemoving)

local function triggerPassiveGain(player, amount)
    if amount == 0 then
        return
    end
    EconomyRemotes.PassiveTick:FireClient(player, amount, boostState.Active and boostState.Name or nil, boostState.Multiplier)
end

local function tryApplyMaintenance(player, state)
    if MAINTENANCE_RATE <= 0 or MAINTENANCE_INTERVAL <= 0 then
        return
    end
    local now = os.clock()
    if now - (state.LastMaintenance or now) < MAINTENANCE_INTERVAL then
        return
    end
    state.LastMaintenance = now
    local tax = roundCurrency(state.Cash * MAINTENANCE_RATE)
    if tax > 0 then
        local applied = EconomyAPI.AddCash(player, -tax)
        if applied ~= 0 then
            EconomyRemotes.PassiveTick:FireClient(player, applied, "Taxe d'entretien", 1)
        end
    end
end

task.spawn(function()
    local lastTick = os.clock()
    while true do
        task.wait(1)
        local now = os.clock()
        local delta = now - lastTick
        lastTick = now
        local multiplier = boostState.Multiplier or 1
        for player, state in pairs(playerEconomy) do
            if state.IncomePerSecond > 0 then
                -- Appliquer le multiplicateur du feu (pénalité si feu < 10)
                local firePenalty = player:GetAttribute("FirePenaltyMultiplier") or 1.0
                local earned = state.IncomePerSecond * multiplier * firePenalty * delta
                local applied = EconomyAPI.AddCash(player, earned)
                if applied ~= 0 then
                    triggerPassiveGain(player, applied)
                end
            end
            tryApplyMaintenance(player, state)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(AUTOSAVE_INTERVAL)
        for player, state in pairs(playerEconomy) do
            persistPlayer(player, state)
        end
    end
end)

local function scheduleNextBoost()
    local interval = BOOST_SETTINGS.IntervalSeconds or 420
    local jitter = BOOST_SETTINGS.RandomJitterSeconds or 0
    if jitter > 0 then
        interval += math.random(-jitter, jitter)
    end
    boostState.NextStart = os.clock() + math.max(60, interval)
end

local function activateBoost()
    if not BOOST_SETTINGS.Enabled then
        return
    end
    local events = BOOST_SETTINGS.Events or {}
    if #events == 0 then
        return
    end
    local event = events[math.random(1, #events)]
    boostState.Active = true
    boostState.Name = event.Name or "Boost"
    boostState.Multiplier = event.Multiplier or 1.5
    local duration = event.DurationSeconds or 45
    boostState.EndsAt = os.clock() + duration
    broadcastBoost()
end

local function clearBoost()
    if not boostState.Active then
        return
    end
    boostState.Active = false
    boostState.Name = nil
    boostState.Multiplier = 1
    boostState.EndsAt = 0
    broadcastBoost()
    scheduleNextBoost()
end

scheduleNextBoost()

task.spawn(function()
    while true do
        task.wait(1)
        local now = os.clock()
        if boostState.Active then
            if now >= boostState.EndsAt then
                clearBoost()
            end
        elseif BOOST_SETTINGS.Enabled and now >= (boostState.NextStart or now + 9999) then
            activateBoost()
        end
    end
end)

shared.ParadisEconomyService = EconomyAPI
