-- AxeUpgradeData.server.lua
-- Sauvegarde et chargement de AxePower via DataStore.
-- Utilise un DataStore simple par UserId.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local STORE_NAME = "AxePowerStore_v1" -- Changer version si structure modifiée
local ds = DataStoreService:GetDataStore(STORE_NAME)

local SAVE_DELAY = 2 -- Anti-spam (pas utilisé intensivement ici)

local function loadAxePower(player)
	local key = "axe_" .. player.UserId
	local success, value = pcall(function()
		return ds:GetAsync(key)
	end)
	if success and typeof(value) == "number" then
		-- Ne baisse pas la puissance si déjà supérieure (sécurité)
		local current = player:GetAttribute("AxePower") or 1
		if value > current then
			player:SetAttribute("AxePower", value)
		elseif current == nil then
			player:SetAttribute("AxePower", value)
		end
	else
		-- Première fois ou erreur --> laisser valeur par défaut
	end
end

local pendingSaves = {}

local function saveAxePower(player)
	local power = player:GetAttribute("AxePower") or 1
	local key = "axe_" .. player.UserId
	local now = os.clock()
	if pendingSaves[player] and now - pendingSaves[player] < SAVE_DELAY then
		return -- Anti spam
	end
	pendingSaves[player] = now
	local success, err = pcall(function()
		ds:SetAsync(key, power)
	end)
	if not success then
		warn("Echec sauvegarde AxePower pour " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("AxePower"):Connect(function()
		saveAxePower(player)
	end)
	-- Charge après un petit délai pour laisser PlayerSetup mettre valeur défaut
	loadAxePower(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveAxePower(player)
end)
