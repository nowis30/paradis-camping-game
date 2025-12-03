--[[
    PlayerProgressService.lua
    Gère les achievements et objets possédés par chaque joueur
    Sauvegarde en mémoire (pas de DataStore pour l'instant)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Données de progression par joueur
local playerData = {} -- [UserId] = { Achievements = {}, OwnedItems = {}, Stats = {} }

local PlayerProgressService = {}

-- Initialiser un joueur
local function initializePlayer(player)
    local userId = player.UserId
    if not playerData[userId] then
        playerData[userId] = {
            Achievements = {}, -- { AchievementId = true, ... }
            OwnedItems = {
                -- Objets de départ (niveau 1 de chaque catégorie)
                Trailer = "Trailer_1",
                BBQ = "BBQ_1",
                PicnicTable = "PicnicTable_1",
                TreesGroup = "TreesDecor_1",
                DecorRock = "DecorRock_1",
                Campfire = "Campfire_1",
            },
            Stats = {
                FishCaught = 0,
                RareFishCaught = 0,
                LegendaryFishCaught = 0,
                LogsCut = 0,
                MazesCompleted = 0,
                SwingLoops = 0,
            },
        }
        print(string.format("[PlayerProgress] 🎁 %s initialisé avec objets de départ", player.Name))
    end
    return playerData[userId]
end

-- Initialiser le joueur quand il rejoint
Players.PlayerAdded:Connect(function(player)
    initializePlayer(player)
end)

-- Nettoyer quand un joueur quitte
Players.PlayerRemoving:Connect(function(player)
    -- On garde les données en mémoire pour cette session
    -- Plus tard: sauvegarder dans DataStore
end)

-- ============ ACHIEVEMENTS ============

function PlayerProgressService.UnlockAchievement(player, achievementId)
    local data = initializePlayer(player)
    
    if data.Achievements[achievementId] then
        return false, "Achievement déjà débloqué"
    end
    
    data.Achievements[achievementId] = true
    print(string.format("[PlayerProgress] 🏆 %s a débloqué: %s", player.Name, achievementId))
    
    -- TODO: Notifier le joueur avec une UI
    
    return true
end

function PlayerProgressService.HasAchievement(player, achievementId)
    local data = initializePlayer(player)
    return data.Achievements[achievementId] == true
end

function PlayerProgressService.GetAllAchievements(player)
    local data = initializePlayer(player)
    local list = {}
    for achievementId, _ in pairs(data.Achievements) do
        table.insert(list, achievementId)
    end
    return list
end

-- ============ OBJETS POSSÉDÉS ============

function PlayerProgressService.SetOwnedItem(player, category, itemId)
    local data = initializePlayer(player)
    data.OwnedItems[category] = itemId
    print(string.format("[PlayerProgress] %s possède maintenant: %s (%s)", player.Name, itemId, category))
end

function PlayerProgressService.GetOwnedItem(player, category)
    local data = initializePlayer(player)
    return data.OwnedItems[category]
end

function PlayerProgressService.GetAllOwnedItems(player)
    local data = initializePlayer(player)
    return data.OwnedItems
end

-- ============ STATS ============

function PlayerProgressService.IncrementStat(player, statName, amount)
    local data = initializePlayer(player)
    amount = amount or 1
    
    if data.Stats[statName] then
        data.Stats[statName] = data.Stats[statName] + amount
        
        -- Auto-unlock achievements basés sur les stats
        if statName == "RareFishCaught" and data.Stats[statName] >= 1 then
            PlayerProgressService.UnlockAchievement(player, "CaughtRareFish")
        elseif statName == "LegendaryFishCaught" and data.Stats[statName] >= 1 then
            PlayerProgressService.UnlockAchievement(player, "CaughtLegendaryFish")
        elseif statName == "MazesCompleted" and data.Stats[statName] >= 1 then
            PlayerProgressService.UnlockAchievement(player, "CompletedMaze")
        elseif statName == "SwingLoops" and data.Stats[statName] >= 10 then
            PlayerProgressService.UnlockAchievement(player, "CompletedSwingLoops")
        elseif statName == "LogsCut" and data.Stats[statName] >= 50 then
            PlayerProgressService.UnlockAchievement(player, "WoodMaster")
        end
        
        return data.Stats[statName]
    end
    
    return 0
end

function PlayerProgressService.GetStat(player, statName)
    local data = initializePlayer(player)
    return data.Stats[statName] or 0
end

-- ============ INCOME TOTAL ============

function PlayerProgressService.GetTotalIncomePerTick(player)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CampingItemsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CampingItemsConfig"))
    
    local data = initializePlayer(player)
    local totalIncome = 0
    
    for category, itemId in pairs(data.OwnedItems) do
        local itemData = CampingItemsConfig.GetItem(itemId)
        if itemData then
            totalIncome = totalIncome + (itemData.BaseIncome or 0)
        end
    end
    
    return totalIncome
end

-- ============ INITIALISATION AU JOIN ============

Players.PlayerAdded:Connect(function(player)
    initializePlayer(player)
    print(string.format("[PlayerProgress] Joueur initialisé: %s", player.Name))
end)

-- Initialiser les joueurs déjà présents
for _, player in ipairs(Players:GetPlayers()) do
    initializePlayer(player)
end

shared.PlayerProgressService = PlayerProgressService
return PlayerProgressService
