-- Leaderstats for Paradis
-- Creates leaderstats/Money for each player and reuses the same value for all game systems

local Players = game:GetService("Players")

local function setupLeaderstats(player: Player)
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
end

Players.PlayerAdded:Connect(setupLeaderstats)
for _, plr in ipairs(Players:GetPlayers()) do
	setupLeaderstats(plr)
end
