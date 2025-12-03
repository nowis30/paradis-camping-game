-- Module de gestion des récompenses et de l'argent des joueurs
-- Fournit ensureLeaderstats(player) et addMoney(player, baseAmount)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rewards = {}

-- Assure que leaderstats/Money existent
function Rewards.ensureLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local money = leaderstats:FindFirstChild("Money")
	if not money then
		money = Instance.new("IntValue")
		money.Name = "Money"
		money.Value = 0
		money.Parent = leaderstats
	end
	return leaderstats, money
end

-- Ajoute de l'argent en appliquant le multiplicateur global du feu
function Rewards.addMoney(player, baseAmount)
	local _, money = Rewards.ensureLeaderstats(player)
	local multiplier = 1.0
	local globalMult = ReplicatedStorage:FindFirstChild("GlobalCoinMultiplier")
	if globalMult and globalMult:IsA("NumberValue") then
		multiplier = tonumber(globalMult.Value) or 1.0
	end
	local finalAmount = math.floor(baseAmount * multiplier + 0.5)
	money.Value = money.Value + finalAmount
	return finalAmount
end

return Rewards