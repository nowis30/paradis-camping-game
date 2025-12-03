--[[
    CampingDetailsService.server.lua
    Service serveur qui fournit les détails du camping aux clients
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Attendre les services nécessaires
local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local PlayerProgressService = waitForShared("PlayerProgressService")
local EconomyService = waitForShared("ParadisEconomyService")
local PlotService = waitForShared("ParadisPlotService")
local CampingProgressionService = waitForShared("ParadisCampingProgressionService")

local CampingItemsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CampingItemsConfig"))
local CampingDetailsRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CampingDetailsRemotes"))

local CampingDetailsService = {}

-- Helper: Obtenir le nom d'achievement en français
local function getAchievementName(achievementId)
    local names = {
        CaughtRareFish = "Pêcher un poisson rare",
        CaughtLegendaryFish = "Pêcher un poisson légendaire",
        CompletedMaze = "Terminer le labyrinthe",
        CompletedSwingLoops = "Faire 10 tours de balançoire",
        WoodMaster = "Couper 100 bûches",
    }
    return names[achievementId] or achievementId
end

-- Helper: Calculer l'income total du joueur
local function calculateTotalIncome(player)
    local ownedItems = PlayerProgressService.GetAllOwnedItems(player)
    if not ownedItems then
        warn("[CampingDetailsService] ⚠️ OwnedItems nil pour", player.Name)
        return 0
    end
    
    local totalIncome = 0
    
    for category, itemId in pairs(ownedItems) do
        local itemData = CampingItemsConfig.Items[itemId]
        if itemData and itemData.BaseIncome then
            totalIncome = totalIncome + itemData.BaseIncome
            print(string.format("[CampingDetailsService] 💵 %s - %s: +%d$/tick", player.Name, itemData.DisplayName, itemData.BaseIncome))
        end
    end
    
    print(string.format("[CampingDetailsService] 💰 Revenu total de %s: %d$/tick", player.Name, totalIncome))
    return totalIncome
end

-- Helper: Obtenir tous les upgrades possibles pour un joueur
local function getAvailableUpgrades(player)
    local ownedItems = PlayerProgressService.GetAllOwnedItems(player)
    local upgrades = {}
    
    -- Parcourir toutes les catégories
    for category, _ in pairs(CampingItemsConfig.Categories) do
        local currentItemId = ownedItems[category]
        local currentLevel = 0
        
        -- Trouver le niveau actuel
        if currentItemId then
            local currentItem = CampingItemsConfig.Items[currentItemId]
            if currentItem then
                currentLevel = currentItem.Level
            end
        end
        
        -- Chercher le prochain niveau
        local nextLevel = currentLevel + 1
        local nextItemId = nil
        
        -- Trouver l'item du prochain niveau dans cette catégorie
        for itemId, itemData in pairs(CampingItemsConfig.Items) do
            if itemData.Category == category and itemData.Level == nextLevel then
                nextItemId = itemId
                break
            end
        end
        
        if nextItemId then
            local nextItem = CampingItemsConfig.Items[nextItemId]
            if nextItem then
                -- Vérifier les prérequis
                local cash = EconomyService.GetCash and EconomyService.GetCash(player) or 0
                local hasEnoughCash = cash >= nextItem.Cost
                local hasMinCash = cash >= nextItem.Prerequisites.MinCash
                
                local missingAchievements = {}
                local hasAllAchievements = true
                
                for _, achievementId in ipairs(nextItem.Prerequisites.Achievements or {}) do
                    if not PlayerProgressService.HasAchievement(player, achievementId) then
                        hasAllAchievements = false
                        table.insert(missingAchievements, {
                            Id = achievementId,
                            Name = getAchievementName(achievementId),
                            Completed = false,
                        })
                    else
                        table.insert(missingAchievements, {
                            Id = achievementId,
                            Name = getAchievementName(achievementId),
                            Completed = true,
                        })
                    end
                end
                
                table.insert(upgrades, {
                    ItemId = nextItemId,
                    Category = category,
                    Level = nextLevel,
                    DisplayName = nextItem.DisplayName,
                    Cost = nextItem.Cost,
                    Income = nextItem.BaseIncome,
                    CanAfford = hasEnoughCash,
                    HasMinCash = hasMinCash,
                    HasAllAchievements = hasAllAchievements,
                    Achievements = missingAchievements,
                })
            end
        end
    end
    
    return upgrades
end

-- Fonction principale : Obtenir les détails du camping pour un joueur
function CampingDetailsService.GetCampingDetails(player)
    print("[CampingDetailsService] 📋 GetCampingDetails appelé pour", player.Name)
    
    if not player or not player:IsA("Player") then
        warn("[CampingDetailsService] ❌ Joueur invalide")
        return nil
    end
    
    local plot = PlotService.GetPlotForPlayer(player)
    if not plot then
        warn("[CampingDetailsService] ❌ Parcelle introuvable pour", player.Name)
        -- Retourner des données par défaut au lieu de nil
        return {
            PlayerName = player.Name,
            PlotId = "None",
            Cash = 0,
            TotalIncome = 0,
            OwnedItems = {},
            AvailableUpgrades = {},
        }
    end
    
    print("[CampingDetailsService] ✅ Parcelle trouvée:", plot.Id, "pour", player.Name)
    
    local ownedItems = PlayerProgressService.GetAllOwnedItems(player)
    if not ownedItems then
        warn("[CampingDetailsService] ❌ OwnedItems nil pour", player.Name)
        ownedItems = {}
    end
    
    local totalIncome = calculateTotalIncome(player)
    local cash = EconomyService.GetCash and EconomyService.GetCash(player) or 0
    
    -- Construire la liste des objets possédés avec détails
    local ownedItemsDetails = {}
    for category, itemId in pairs(ownedItems) do
        local itemData = CampingItemsConfig.Items[itemId]
        if itemData then
            table.insert(ownedItemsDetails, {
                Category = category,
                ItemId = itemId,
                Level = itemData.Level,
                DisplayName = itemData.DisplayName,
                Income = itemData.BaseIncome,
            })
        end
    end
    
    -- Obtenir les upgrades disponibles
    local availableUpgrades = getAvailableUpgrades(player)
    
    local result = {
        PlayerName = player.Name,
        PlotId = plot.Id,
        Cash = cash,
        TotalIncome = totalIncome,
        OwnedItems = ownedItemsDetails,
        AvailableUpgrades = availableUpgrades,
    }
    
    print(string.format("[CampingDetailsService] 📊 Détails envoyés à %s: %d objets, %d upgrades disponibles, %d$ cash, +%d$/tick", 
        player.Name, #ownedItemsDetails, #availableUpgrades, cash, totalIncome))
    
    return result
end

-- Initialiser le RemoteFunction
CampingDetailsRemotes.GetCampingDetails.OnServerInvoke = function(player)
    return CampingDetailsService.GetCampingDetails(player)
end

-- Initialiser le RemoteEvent pour les achats
CampingDetailsRemotes.RequestPurchaseItem.OnServerEvent:Connect(function(player, itemId)
    if not itemId then
        warn("[CampingDetailsService] RequestPurchaseItem reçu sans itemId")
        return
    end
    
    -- Appeler le service de progression pour l'achat
    local success, message = CampingProgressionService.PurchaseItem(player, itemId)
    
    if success then
        print(string.format("[CampingDetailsService] ✅ %s a acheté %s", player.Name, itemId))
        
        -- Notifier le client pour rafraîchir la GUI
        CampingDetailsRemotes.CampingDetailsUpdated:FireClient(player)
    else
        warn(string.format("[CampingDetailsService] ❌ Échec achat pour %s: %s", player.Name, message or "Erreur inconnue"))
        
        -- Optionnel : envoyer l'erreur au client (pourrait être ajouté plus tard)
        -- Pour l'instant le client va simplement rafraîchir et voir que rien n'a changé
        CampingDetailsRemotes.CampingDetailsUpdated:FireClient(player)
    end
end)

-- Exposer le service
shared.ParadisCampingDetailsService = CampingDetailsService

print("[CampingDetailsService] ✅ Service initialisé")

return CampingDetailsService
