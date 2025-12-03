--[[
    FishingShopService
    Gère les achats de cannes à pêche et d'appâts dans le Pro Shop.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")
local FishingGearConfig = require(ConfigFolder:WaitForChild("FishingGearConfig"))
local FishPrices = require(ConfigFolder:WaitForChild("FishPricesConfig"))
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local FishingShopRemotes = require(RemotesFolder:WaitForChild("FishingShopRemotes"))

local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local DataApi = waitForShared("ParadisDataService")
local EconomyService = waitForShared("ParadisEconomyService")

local FishingShopService = {}

-- Acheter une canne
FishingShopRemotes.BuyRod.OnServerEvent:Connect(function(player, rodId)
    local rodDef = FishingGearConfig.Rods[rodId]
    if not rodDef then
        warn("[FishingShop] Canne inconnue:", rodId)
        return
    end
    
    -- Si achat Robux uniquement, bloquer ici (achat via MarketplaceService côté client)
    if rodDef.RobuxPrice and rodDef.RobuxPrice > 0 then
        warn("[FishingShop] Canne Robux, achat doit passer par MarketplaceService:", rodId)
        return
    end
    
    local userId = player.UserId
    local data = DataApi.LoadPlayerData(userId)
    
    -- Vérifier si déjà possédée
    if data.FishingGear.OwnedRods[rodId] then
        warn("[FishingShop] Canne déjà possédée:", rodId)
        return
    end
    
    -- Vérifier le cash
    local cost = rodDef.Cost
    if data.Cash < cost then
        warn("[FishingShop] Pas assez de cash pour la canne:", rodId)
        return
    end
    
    -- Déduire et ajouter la canne
    data.Cash = data.Cash - cost
    data.FishingGear.OwnedRods[rodId] = true
    data.FishingGear.CurrentRod = rodId
    DataApi.SavePlayerData(userId, data)
    
    -- Mettre à jour le HUD
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local cashValue = leaderstats:FindFirstChild("Cash")
        if cashValue then
            cashValue.Value = data.Cash
        end
    end
    
    print(string.format("[FishingShop] %s a acheté la canne %s pour %d$", player.Name, rodDef.DisplayName, cost))
end)

-- Équiper une canne déjà possédée
FishingShopRemotes.SetCurrentRod.OnServerEvent:Connect(function(player, rodId)
    local rodDef = FishingGearConfig.Rods[rodId]
    if not rodDef then
        warn("[FishingShop] SetCurrentRod: canne inconnue:", rodId)
        return
    end
    local userId = player.UserId
    local data = DataApi.LoadPlayerData(userId)
    if not (data.FishingGear.OwnedRods and data.FishingGear.OwnedRods[rodId]) then
        warn("[FishingShop] SetCurrentRod: non possédée:", rodId)
        return
    end
    data.FishingGear.CurrentRod = rodId
    DataApi.SavePlayerData(userId, data)
    print(string.format("[FishingShop] %s a équipé la canne %s", player.Name, rodDef.DisplayName))
end)

-- Acheter un appât
FishingShopRemotes.BuyBait.OnServerEvent:Connect(function(player, baitId)
    local baitDef = FishingGearConfig.Baits[baitId]
    if not baitDef then
        warn("[FishingShop] Appât inconnu:", baitId)
        return
    end
    
    if baitId == "None" then
        return -- aucun achat nécessaire
    end
    
    local userId = player.UserId
    local data = DataApi.LoadPlayerData(userId)
    
    -- Vérifier le cash
    local cost = baitDef.Cost
    if data.Cash < cost then
        warn("[FishingShop] Pas assez de cash pour l'appât:", baitId)
        return
    end
    
    -- Déduire et ajouter les utilisations
    data.Cash = data.Cash - cost
    data.FishingGear.CurrentBait = baitId
    data.FishingGear.BaitUses = (data.FishingGear.BaitUses or 0) + baitDef.UsesPerPurchase
    DataApi.SavePlayerData(userId, data)
    
    -- Mettre à jour le HUD
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local cashValue = leaderstats:FindFirstChild("Cash")
        if cashValue then
            cashValue.Value = data.Cash
        end
    end
    
    print(string.format("[FishingShop] %s a acheté %s pour %d$ (%d utilisations)", player.Name, baitDef.DisplayName, cost, baitDef.UsesPerPurchase))
end)

-- Obtenir l'équipement actuel
FishingShopRemotes.GetGear.OnServerInvoke = function(player)
    local userId = player.UserId
    local data = DataApi.LoadPlayerData(userId)
    if not data.FishingGear.FishInventory then
        data.FishingGear.FishInventory = {Common = 0, rare = 0, legendaire = 0}
    end
    return {
        CurrentRod = data.FishingGear.CurrentRod,
        CurrentBait = data.FishingGear.CurrentBait,
        BaitUses = data.FishingGear.BaitUses,
        OwnedRods = data.FishingGear.OwnedRods,
        Cash = data.Cash,
        FishInventory = data.FishingGear.FishInventory,
    }
end

FishingShopService.GetPlayerGear = function(userId)
    local data = DataApi.LoadPlayerData(userId)
    return {
        CurrentRod = data.FishingGear.CurrentRod,
        CurrentBait = data.FishingGear.CurrentBait,
        BaitUses = data.FishingGear.BaitUses,
    }
end

FishingShopService.ConsumeBait = function(userId)
    local data = DataApi.LoadPlayerData(userId)
    if data.FishingGear.CurrentBait == "None" or data.FishingGear.CurrentBait == "Standard" then
        return
    end
    
    data.FishingGear.BaitUses = math.max(0, (data.FishingGear.BaitUses or 0) - 1)
    
    -- Si plus d'utilisations, revenir à "Standard"
    if data.FishingGear.BaitUses <= 0 then
        data.FishingGear.CurrentBait = "Standard"
        data.FishingGear.BaitUses = 5
    end
    
    DataApi.SavePlayerData(userId, data)
end

FishingShopService.AddFishToInventory = function(userId, fishType)
    local data = DataApi.LoadPlayerData(userId)
    if not data.FishingGear.FishInventory then
        data.FishingGear.FishInventory = {Common = 0, rare = 0, legendaire = 0}
    end
    
    data.FishingGear.FishInventory[fishType] = (data.FishingGear.FishInventory[fishType] or 0) + 1
    -- Marquer comme vu dans le codex
    data.FishingGear.CodexSeen = data.FishingGear.CodexSeen or {}
    data.FishingGear.CodexSeen[fishType] = true
    DataApi.SavePlayerData(userId, data)
    return data.FishingGear.FishInventory[fishType]
end

FishingShopService.UseFishAsBait = function(userId, fishType)
    local data = DataApi.LoadPlayerData(userId)
    if not data.FishingGear.FishInventory then
        data.FishingGear.FishInventory = {Common = 0, rare = 0, legendaire = 0}
    end
    
    local count = data.FishingGear.FishInventory[fishType] or 0
    if count <= 0 then
        return false
    end
    
    -- Consommer le poisson et équiper l'appât correspondant
    data.FishingGear.FishInventory[fishType] = count - 1
    
    local baitId = "Fish" .. fishType
    local baitDef = FishingGearConfig.Baits[baitId]
    if baitDef then
        data.FishingGear.CurrentBait = baitId
        data.FishingGear.BaitUses = baitDef.UsesPerPurchase
    end
    
    DataApi.SavePlayerData(userId, data)
    return true
end

-- Remote pour utiliser un poisson comme appât
FishingShopRemotes.UseFishAsBait.OnServerEvent:Connect(function(player, fishType)
    local userId = player.UserId
    local success = FishingShopService.UseFishAsBait(userId, fishType)
    
    if success then
        print(string.format("[FishingShop] %s utilise un poisson %s comme appât", player.Name, fishType))
    else
        warn(string.format("[FishingShop] %s n'a pas de poisson %s en stock", player.Name, fishType))
    end
end)

-- Vente poissonnerie: vendre une quantité d'une rareté (par défaut tout)
FishingShopRemotes.SellFish.OnServerEvent:Connect(function(player, fishType, amount)
    local userId = player.UserId
    local data = DataApi.LoadPlayerData(userId)
    if not data.FishingGear.FishInventory then
        return
    end
    if FishPrices[fishType] == nil then
        warn("[FishingShop] SellFish: type inconnu:", fishType)
        return
    end
    local have = data.FishingGear.FishInventory[fishType] or 0
    amount = math.clamp(tonumber(amount) or have, 0, have)
    if amount <= 0 then return end
    local gain = amount * (FishPrices[fishType] or 0)
    data.FishingGear.FishInventory[fishType] = have - amount
    data.Cash = (data.Cash or 0) + gain
    DataApi.SavePlayerData(userId, data)
    -- Mettre à jour leaderstats
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local cash = ls:FindFirstChild("Cash")
        if cash then cash.Value = data.Cash end
    end
    print(string.format("[FishingShop] %s a vendu %d x %s pour %d$", player.Name, amount, fishType, gain))
end)

-- Vente tout
FishingShopRemotes.SellAllFish.OnServerEvent:Connect(function(player)
    local userId = player.UserId
    local data = DataApi.LoadPlayerData(userId)
    if not data.FishingGear.FishInventory then return end
    local total = 0
    for t, cnt in pairs(data.FishingGear.FishInventory) do
        local price = FishPrices[t] or 0
        total = total + (cnt or 0) * price
        data.FishingGear.FishInventory[t] = 0
    end
    if total > 0 then
        data.Cash = (data.Cash or 0) + total
        DataApi.SavePlayerData(userId, data)
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local cash = ls:FindFirstChild("Cash")
            if cash then cash.Value = data.Cash end
        end
        print(string.format("[FishingShop] %s a vendu tout pour %d$", player.Name, total))
    end
end)

-- Codex: renvoyer flags vus
FishingShopRemotes.GetCodex.OnServerInvoke = function(player)
    local data = DataApi.LoadPlayerData(player.UserId)
    data.FishingGear.CodexSeen = data.FishingGear.CodexSeen or {}
    return data.FishingGear.CodexSeen
end

-- Fonction appelée après achat Robux réussi (Developer Product callback)
function FishingShopService.GrantMasterRod(userId)
    local data = DataApi.LoadPlayerData(userId)
    if data.FishingGear.OwnedRods.Master then
        return true -- Déjà possédée
    end
    data.FishingGear.OwnedRods.Master = true
    data.FishingGear.CurrentRod = "Master"
    DataApi.SavePlayerData(userId, data)
    print("[FishingShop] Canne Master accordée via Robux pour userId:", userId)
    return true
end

shared.ParadisFishingShopService = FishingShopService
print("[Paradis][FishingShop] Service initialisé")

return FishingShopService
