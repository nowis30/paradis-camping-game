-- AxeLegendaryPurchase.server.lua
-- Gère l'achat Robux (Developer Product) pour la hache légendaire via MarketplaceService.ProcessReceipt.
-- Nécessite que ProductId dans AxeUpgradeConfig.Tiers (Power=5) soit correctement renseigné.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AxeConfig = require(ReplicatedStorage.Config.AxeUpgradeConfig)
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local upgradeEvent = remotesFolder:WaitForChild("AxeUpgradeSucceeded")
local legendaryFailEvent = remotesFolder:WaitForChild("LegendaryPurchaseFailed")

local legendaryTier
for _, tier in ipairs(AxeConfig.Tiers) do
	if tier.Power == 5 then
		legendaryTier = tier
		break
	end
end

local PRODUCT_ID = legendaryTier and legendaryTier.ProductId or 0

if PRODUCT_ID == 0 then
	warn("[AxeLegendaryPurchase] ProductId légendaire non configuré.")
end

-- Fonction utilitaire pour appliquer la hache légendaire
local function grantLegendaryAxe(player)
	if not player then return end
	if (player:GetAttribute("AxePower") or 1) >= 5 then return end
	player:SetAttribute("AxePower", 5)
	upgradeEvent:FireAllClients(player, 5, legendaryTier and legendaryTier.Name or "Hache Légendaire")
end

-- ProcessReceipt callback
function MarketplaceService.ProcessReceipt(receiptInfo)
	-- Vérifie correspondance ProductId
	if receiptInfo.ProductId ~= PRODUCT_ID then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Laisse autres scripts gérer si ce n'est pas notre produit
	end
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	grantLegendaryAxe(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Sécurité: si un joueur rejoint après avoir acheté mais avant attribution (rare)
Players.PlayerAdded:Connect(function(player)
	-- On pourrait vérifier un DataStore séparé pour achats, laissé simple ici
end)
