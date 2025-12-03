-- ProShopService.server.lua
-- Gère les achats dans la boutique ProShop (haches permanentes et bûches magiques temporaires)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ProShopConfig = require(ReplicatedStorage.Config.ProShopConfig)
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local requestPurchaseFunc = remotesFolder:WaitForChild("RequestProShopPurchase")
local getDataFunc = remotesFolder:WaitForChild("GetProShopData")
local purchaseResultEvent = remotesFolder:WaitForChild("ProShopPurchaseResult")
local magicLogExpiredEvent = remotesFolder:WaitForChild("MagicLogExpired")

-- Stockage des bûches magiques actives par joueur
-- Structure: playerMagicLogs[userId] = {count = N, expiryTime = tick() + duration}
local playerMagicLogs = {}

-- Fonction pour initialiser les attributs du joueur
local function initializePlayerAttributes(player)
	if not player:GetAttribute("Money") then
		player:SetAttribute("Money", 0)
	end
	if not player:GetAttribute("MagicLogs") then
		player:SetAttribute("MagicLogs", 0)
	end
	
	-- Restaurer les bûches magiques si elles existent encore
	local userId = player.UserId
	if playerMagicLogs[userId] then
		local data = playerMagicLogs[userId]
		if data.expiryTime > tick() then
			player:SetAttribute("MagicLogs", data.count)
		else
			-- Expirées, nettoyer
			playerMagicLogs[userId] = nil
			player:SetAttribute("MagicLogs", 0)
		end
	end
end

-- Fonction pour obtenir les données de la boutique pour un joueur
local function getProShopData(player)
	return {
		products = ProShopConfig.Products,
		playerMoney = player:GetAttribute("Money") or 0,
		playerAxePower = player:GetAttribute("AxePower") or 1,
		playerMagicLogs = player:GetAttribute("MagicLogs") or 0,
		magicLogExpiry = playerMagicLogs[player.UserId] and playerMagicLogs[player.UserId].expiryTime or nil
	}
end

-- Fonction pour traiter l'achat d'une hache
local function purchaseAxe(player, product)
	local currentAxePower = player:GetAttribute("AxePower") or 1
	
	-- Vérifier si le joueur a déjà cette hache ou mieux
	if currentAxePower >= product.AxePower then
		return false, "Vous possédez déjà cette hache ou une meilleure!"
	end
	
	-- Vérifier l'argent
	local playerMoney = player:GetAttribute("Money") or 0
	if playerMoney < product.Price then
		return false, "Argent insuffisant! Il vous faut " .. product.Price .. " pièces."
	end
	
	-- Déduire l'argent et donner la hache
	player:SetAttribute("Money", playerMoney - product.Price)
	player:SetAttribute("AxePower", product.AxePower)
	
	print("[ProShopService] " .. player.Name .. " a acheté " .. product.Name .. " (Power: " .. product.AxePower .. ")")
	return true, "Hache achetée avec succès! ✨"
end

-- Fonction pour traiter l'achat de bûches magiques
local function purchaseMagicLogs(player, product)
	-- Vérifier l'argent
	local playerMoney = player:GetAttribute("Money") or 0
	if playerMoney < product.Price then
		return false, "Argent insuffisant! Il vous faut " .. product.Price .. " pièces."
	end
	
	-- Déduire l'argent
	player:SetAttribute("Money", playerMoney - product.Price)
	
	-- Ajouter les bûches magiques
	local currentMagicLogs = player:GetAttribute("MagicLogs") or 0
	local newTotal = currentMagicLogs + product.Quantity
	player:SetAttribute("MagicLogs", newTotal)
	
	-- Initialiser ou mettre à jour le timer d'expiration (24h à partir de maintenant)
	local userId = player.UserId
	local expiryTime = tick() + ProShopConfig.MAGIC_LOG_DURATION
	
	if not playerMagicLogs[userId] then
		playerMagicLogs[userId] = {count = newTotal, expiryTime = expiryTime}
		
		-- Démarrer un timer pour notifier l'expiration
		task.delay(ProShopConfig.MAGIC_LOG_DURATION, function()
			if Players:FindFirstChild(player.Name) then
				player:SetAttribute("MagicLogs", 0)
				magicLogExpiredEvent:FireClient(player)
				print("[ProShopService] Bûches magiques de " .. player.Name .. " ont expiré")
			end
			playerMagicLogs[userId] = nil
		end)
	else
		-- Mettre à jour le count, garder le timer existant
		playerMagicLogs[userId].count = newTotal
	end
	
	print("[ProShopService] " .. player.Name .. " a acheté " .. product.Quantity .. " bûche(s) magique(s)")
	return true, product.Quantity .. " bûche(s) magique(s) ajoutée(s)! ✨ (24h)"
end

-- Handler pour les demandes d'achat
requestPurchaseFunc.OnServerInvoke = function(player, productId)
	local product = ProShopConfig.GetProductById(productId)
	
	if not product then
		return {success = false, message = "Produit introuvable!"}
	end
	
	local success, message
	
	if product.ProductType == ProShopConfig.ProductTypes.AXE then
		success, message = purchaseAxe(player, product)
	elseif product.ProductType == ProShopConfig.ProductTypes.MAGIC_LOG then
		success, message = purchaseMagicLogs(player, product)
	else
		return {success = false, message = "Type de produit inconnu!"}
	end
	
	-- Notifier le client du résultat
	purchaseResultEvent:FireClient(player, {
		success = success,
		message = message,
		productId = productId
	})
	
	return {success = success, message = message}
end

-- Handler pour obtenir les données de la boutique
getDataFunc.OnServerInvoke = function(player)
	return getProShopData(player)
end

-- Initialiser les joueurs déjà présents
for _, player in ipairs(Players:GetPlayers()) do
	initializePlayerAttributes(player)
end

-- Initialiser les nouveaux joueurs
Players.PlayerAdded:Connect(function(player)
	initializePlayerAttributes(player)
end)

-- Nettoyer les données quand un joueur quitte
Players.PlayerRemoving:Connect(function(player)
	-- Note: Dans un vrai jeu, sauvegarder playerMagicLogs[userId] dans DataStore
	-- Pour l'instant, les bûches magiques sont perdues à la déconnexion
end)

print("[ProShopService] Service initialisé - " .. #ProShopConfig.Products .. " produits disponibles")
