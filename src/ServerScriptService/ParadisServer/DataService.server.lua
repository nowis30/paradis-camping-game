--[[
    DataService
    Responsable de la persistance simple des aménagements en DataStore.
    Les autres scripts y accèdent via shared.ParadisDataService.
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PersistentPlayerData = require(script.Parent:WaitForChild("PersistentPlayerData"))

local configFolder = ReplicatedStorage:WaitForChild("Config")
local CampConfig = require(configFolder:WaitForChild("CampConfig"))
local EconomyConfig = require(configFolder:WaitForChild("EconomyConfig"))

local STORE_NAME = "ParadisPlots_v2"
local store

local DEFAULT_CASH = (EconomyConfig.General and EconomyConfig.General.StartingCash) or 0

local DEFAULT_DATA = {
    Objects = {},
    TrailerParts = {},
    Cash = DEFAULT_CASH,
    FishingGear = {
        CurrentRod = "Basic",
        CurrentBait = "Standard",
        BaitUses = 5,
        OwnedRods = {Basic = true},
        FishInventory = {Common = 0, rare = 0, legendaire = 0},
    },
}

local function deepCopyTable(tbl)
    local clone = {}
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            clone[key] = deepCopyTable(value)
        else
            clone[key] = value
        end
    end
    return clone
end

local function logDataStoreError(action, userId, err)
    warn(string.format("[Paradis][DataStore][%s][User:%s] %s", action, tostring(userId), tostring(err)))
end

local STUDIO_READ_ONLY = RunService:IsStudio()
local success, result = pcall(function()
    if STUDIO_READ_ONLY then return nil end -- On ne crée pas de DataStore effectif en Studio si API désactivé
    return DataStoreService:GetDataStore(STORE_NAME)
end)
if success then
    store = result
    if STUDIO_READ_ONLY then
        warn("[Paradis][DataStore] Mode Studio détecté: lecture/écriture DataStore désactivées (utilisation cache seulement).")
    end
else
    logDataStoreError("Init", "-", result)
end

local function normalizeData(data)
    if type(data) ~= "table" then
        data = deepCopyTable(DEFAULT_DATA)
    end
    data.Objects = type(data.Objects) == "table" and data.Objects or {}
    data.TrailerParts = type(data.TrailerParts) == "table" and data.TrailerParts or {}
    local cash = tonumber(data.Cash)
    if cash == nil then
        cash = DEFAULT_CASH
    end
    data.Cash = cash
    
    -- Normaliser FishingGear
    if type(data.FishingGear) ~= "table" then
        data.FishingGear = deepCopyTable(DEFAULT_DATA.FishingGear)
    else
        data.FishingGear.CurrentRod = data.FishingGear.CurrentRod or "Basic"
        data.FishingGear.CurrentBait = data.FishingGear.CurrentBait or "Standard"
        data.FishingGear.BaitUses = tonumber(data.FishingGear.BaitUses) or 5
        if type(data.FishingGear.OwnedRods) ~= "table" then
            data.FishingGear.OwnedRods = {Basic = true}
        end
        if type(data.FishingGear.FishInventory) ~= "table" then
            data.FishingGear.FishInventory = {Common = 0, rare = 0, legendaire = 0}
        end
    end
    
    return data
end

local function getDefaultData()
    return deepCopyTable(DEFAULT_DATA)
end

local persistence = PersistentPlayerData.new({
    readOnly = STUDIO_READ_ONLY,
    attempts = 3,
    wait = task.wait,
    defaults = getDefaultData,
    normalize = normalizeData,
    read = function(userId)
        if not store then error("DataStore unavailable") end
        return store:GetAsync(tostring(userId))
    end,
    write = function(userId, data)
        if not store then error("DataStore unavailable") end
        store:SetAsync(tostring(userId), data)
    end,
    onLoadFailure = function(userId, err)
        logDataStoreError("Load", userId, err)
        local player = Players:GetPlayerByUserId(userId)
        if player then
            player:SetAttribute("ParadisDataLoaded", false)
            player:Kick("Ta sauvegarde est temporairement inaccessible. Reconnecte-toi dans quelques instants; tes données existantes sont préservées.")
        end
    end,
    onSaveFailure = function(userId, err)
        logDataStoreError("Save", userId, err)
    end,
})

local function loadPlayerData(userId)
    local data, loaded = persistence.Load(userId)
    local player = Players:GetPlayerByUserId(userId)
    if player then player:SetAttribute("ParadisDataLoaded", loaded) end
    return data, loaded
end

-- Register before publishing the API so a reconnect can retry a failed read.
-- Keep a healthy cache: a departing player's final save may still be in flight.
Players.PlayerAdded:Connect(function(player)
    persistence.ResetFailed(player.UserId)
end)
Players.PlayerRemoving:Connect(function(player)
    task.delay(30, function()
        if not Players:GetPlayerByUserId(player.UserId) then persistence.Reset(player.UserId) end
    end)
end)

shared.ParadisDataService = {
    LoadPlayerData = loadPlayerData,
    SavePlayerData = persistence.Save,
    GetDefaultData = getDefaultData,
}
