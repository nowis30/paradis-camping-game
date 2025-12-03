-- PlayerSetup.server.lua
-- Initialise les attributs nécessaires au mini-jeu de coupe de bois
-- et garantit l'existence de leaderstats/Money.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- On requiert le module Rewards pour réutiliser ensureLeaderstats
local Rewards = require(ServerScriptService.Utils.Rewards)

-- Valeurs par défaut
local DEFAULT_AXE_POWER = 1
local DEFAULT_LOGS = 0

-- Fonction utilitaire pour initialiser un attribut s'il n'existe pas déjà
local function ensureAttribute(player, attrName, defaultValue)
	if player:GetAttribute(attrName) == nil then
		player:SetAttribute(attrName, defaultValue)
	end
end

-- Initialise tous les attributs et leaderstats d'un joueur nouvellement arrivé
local function onPlayerAdded(player)
	-- Assure leaderstats + Money
	Rewards.ensureLeaderstats(player)
	-- Assure AxePower
	ensureAttribute(player, "AxePower", DEFAULT_AXE_POWER)
	-- Assure Logs (stock de bûches transportées par le joueur)
	ensureAttribute(player, "Logs", DEFAULT_LOGS)
end

-- Connexion de l'événement
Players.PlayerAdded:Connect(onPlayerAdded)

-- Pour le cas où le script est rechargé alors que des joueurs sont déjà présents
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end
