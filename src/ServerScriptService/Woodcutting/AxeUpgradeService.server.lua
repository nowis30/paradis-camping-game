-- AxeUpgradeService.server.lua
-- Gère les demandes d'amélioration de la hache (augmentation AxePower) contre de l'argent.
-- Utilise AxeUpgradeConfig pour déterminer le prochain palier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Rewards = require(ServerScriptService.Utils.Rewards)
local AxeConfig = require(ReplicatedStorage.Config.AxeUpgradeConfig)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local requestFunction = remotesFolder:WaitForChild("RequestAxeUpgrade")
local upgradeEvent = remotesFolder:WaitForChild("AxeUpgradeSucceeded")
local requestLegendaryFunction = remotesFolder:WaitForChild("RequestLegendaryUpgrade")
local legendaryFailEvent = remotesFolder:WaitForChild("LegendaryPurchaseFailed")

-- Trouve l'index du palier correspondant à la puissance actuelle.
local function findCurrentTierIndex(power)
	for i, tier in ipairs(AxeConfig.Tiers) do
		if tier.Power == power then
			return i
		end
	end
	return nil
end

-- Renvoie le prochain palier si disponible.
local function getNextTier(power)
	local idx = findCurrentTierIndex(power)
	if not idx then
		-- Si la puissance actuelle ne correspond pas à un palier, on cherche le plus proche inférieur
		local candidate
		for i, tier in ipairs(AxeConfig.Tiers) do
			if power >= tier.Power then
				candidate = i
			end
		end
		if candidate and AxeConfig.Tiers[candidate + 1] then
			return AxeConfig.Tiers[candidate + 1]
		end
		return nil
	end
	return AxeConfig.Tiers[idx + 1]
end

-- Applique les changements visuels à l'outil (couleur/size) selon power
local function applyToolVisual(tool, power)
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local colors = {
		[1] = Color3.fromRGB(92,64,51),      -- Basique
		[2] = Color3.fromRGB(110,80,55),     -- Renforcée
		[3] = Color3.fromRGB(140,100,70),    -- Acier (bois plus clair + fer?)
		[4] = Color3.fromRGB(170,120,60),    -- Mythique
		[5] = Color3.fromRGB(255,200,70),    -- Légendaire dorée
	}
	handle.Color = colors[power] or handle.Color
	-- Légère variation de taille pour feedback
	local baseSize = Vector3.new(1,4,1)
	local scaleFactor = 1 + (power - 1) * 0.08
	handle.Size = baseSize * scaleFactor
end

-- Met à jour tous les outils du joueur
local function ensureLegendaryTrail(tool, power)
	if power < 5 then
		-- Supprime trail si présent
		local trail = tool:FindFirstChild("LegendaryTrail")
		if trail then trail:Destroy() end
		return
	end
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local trail = tool:FindFirstChild("LegendaryTrail")
	if not trail then
		-- Création des attachments
		local att1 = handle:FindFirstChild("TrailAttachment1")
		if not att1 then
			att1 = Instance.new("Attachment")
			att1.Name = "TrailAttachment1"
			att1.Position = Vector3.new(0, handle.Size.Y/2, 0)
			att1.Parent = handle
		end
		local att2 = handle:FindFirstChild("TrailAttachment2")
		if not att2 then
			att2 = Instance.new("Attachment")
			att2.Name = "TrailAttachment2"
			att2.Position = Vector3.new(0, -handle.Size.Y/2, 0)
			att2.Parent = handle
		end
		trail = Instance.new("Trail")
		trail.Name = "LegendaryTrail"
		trail.Attachment0 = att1
		trail.Attachment1 = att2
		trail.Color = ColorSequence.new(Color3.fromRGB(255,230,120), Color3.fromRGB(255,180,60))
		trail.Lifetime = 0.3
		trail.LightInfluence = 0
		trail.MinLength = 0.02
		trail.Enabled = true
		trail.Parent = tool
	end
end

local function updatePlayerTools(player)
	local power = player:GetAttribute("AxePower") or 1
	-- Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name == "Axe" or tool.Name == "AxeTemplate" then
				tool:SetAttribute("Power", power)
				applyToolVisual(tool, power)
				ensureLegendaryTrail(tool, power)
			end
		end
	end
	-- Character
	if player.Character then
		for _, tool in ipairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name == "Axe" or tool.Name == "AxeTemplate") then
				tool:SetAttribute("Power", power)
				applyToolVisual(tool, power)
				ensureLegendaryTrail(tool, power)
			end
		end
	end
end

-- Listener sur changement AxePower
local function onPlayerAdded(player)
	player.AttributeChanged:Connect(function(attr)
		if attr == "AxePower" then
			updatePlayerTools(player)
		end
	end)
end

for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
	onPlayerAdded(p)
end

game:GetService("Players").PlayerAdded:Connect(onPlayerAdded)

-- RemoteFunction handler
local function getFireLevel()
	local campfire = workspace:FindFirstChild("Campfire")
	if not campfire then return 0 end
	local fireLevel = campfire:FindFirstChild("FireLevel")
	if fireLevel and fireLevel:IsA("NumberValue") then
		return fireLevel.Value
	end
	return 0
end

function requestFunction.OnServerInvoke(player)
	-- Assure leaderstats
	local _, moneyValue = Rewards.ensureLeaderstats(player)
	local currentPower = player:GetAttribute("AxePower") or 1
	local nextTier = getNextTier(currentPower)
	if not nextTier then
		return false, "Aucun palier supérieur disponible."
	end
	-- Si palier Robux, refuser ici (utiliser RequestLegendaryUpgrade)
	if nextTier.CostRobux then
		return false, "Achetable uniquement avec des Robux."
	end
	-- Vérifie feu
	local fireLevel = getFireLevel()
	local required = nextTier.FireRequirement or 0
	if fireLevel < required then
		return false, "Feu insuffisant (" .. fireLevel .. "/" .. required .. ")"
	end
	if moneyValue.Value < (nextTier.Cost or 0) then
		return false, "Pas assez d'argent (" .. moneyValue.Value .. "/" .. nextTier.Cost .. ")"
	end
	-- Débit
	moneyValue.Value = moneyValue.Value - (nextTier.Cost or 0)
	player:SetAttribute("AxePower", nextTier.Power)
	updatePlayerTools(player)
	upgradeEvent:FireAllClients(player, nextTier.Power, nextTier.Name)
	return true, "Amélioration réussie: " .. nextTier.Name .. " (Puissance " .. nextTier.Power .. ")"
end

-- Demande d'achat légendaire (Robux) côté serveur: validation conditions puis renvoie ProductId
function requestLegendaryFunction.OnServerInvoke(player)
	local currentPower = player:GetAttribute("AxePower") or 1
	if currentPower >= 5 then
		return false, "Déjà légendaire." , nil
	end
	local nextTier = getNextTier(currentPower)
	if not nextTier or not nextTier.CostRobux then
		return false, "Palier légendaire indisponible." , nil
	end
	local fireLevel = getFireLevel()
	local required = nextTier.FireRequirement or 0
	if fireLevel < required then
		return false, "Feu insuffisant (" .. fireLevel .. "/" .. required .. ")" , nil
	end
	if not nextTier.ProductId or nextTier.ProductId == 0 then
		return false, "ProductId non configuré." , nil
	end
	return true, "OK", nextTier.ProductId
end