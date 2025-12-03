-- GiveAxe.server.lua
-- Donne la hache appropriée selon le niveau AxePower du joueur
-- Utilise les modèles Axe, Axe1, Axe2 du Workspace

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AXE_TOOL_NAME = "Axe"

-- Trouve le template de hache selon la puissance
local function getAxeTemplate(power)
	local axeName = "Axe"
	if power >= 3 then
		axeName = "Axe2"
	elseif power >= 2 then
		axeName = "Axe1"
	end
	
	-- Chercher dans ReplicatedStorage d'abord
	local template = ReplicatedStorage:FindFirstChild(axeName)
	if template and template:IsA("Tool") then
		return template
	end
	
	-- Chercher dans Workspace et déplacer vers ReplicatedStorage
	template = Workspace:FindFirstChild(axeName)
	if template and template:IsA("Tool") then
		print("[GiveAxe] Déplacement de", axeName, "vers ReplicatedStorage")
		template.Parent = ReplicatedStorage
		return template
	end
	
	-- Fallback: créer une hache basique
	warn("[GiveAxe] Template", axeName, "introuvable, création d'une hache basique")
	local tool = Instance.new("Tool")
	tool.Name = AXE_TOOL_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 4, 1)
	handle.Color = Color3.fromRGB(92, 64, 51)
	handle.Material = Enum.Material.Wood
	handle.Parent = tool

	tool.Parent = ReplicatedStorage
	return tool
end

-- Donne la hache appropriée selon AxePower
local function giveAxe(player)
	if not player.Character then return end
	
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	
	-- Supprimer l'ancienne hache si elle existe
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name == "Axe" or tool.Name == "Axe1" or tool.Name == "Axe2") then
			tool:Destroy()
		end
	end
	
	-- Dans le personnage aussi
	if player.Character then
		for _, tool in ipairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name == "Axe" or tool.Name == "Axe1" or tool.Name == "Axe2") then
				tool:Destroy()
			end
		end
	end
	
	-- Donner la nouvelle hache selon AxePower
	local power = player:GetAttribute("AxePower") or 1
	local template = getAxeTemplate(power)
	if template then
		local clone = template:Clone()
		clone:SetAttribute("Power", power)
		clone.Parent = backpack
		print("[GiveAxe]", player.Name, "reçoit", clone.Name, "(Power:", power .. ")")
	end
end

Players.PlayerAdded:Connect(function(player)
	-- Sur changement de puissance, donner la nouvelle hache
	player.AttributeChanged:Connect(function(attr)
		if attr == "AxePower" then
			print("[GiveAxe] AxePower changé pour", player.Name, "- Nouvelle hache donnée")
			giveAxe(player)
		end
	end)
	
	player.CharacterAdded:Connect(function(character)
		-- Attendre que le personnage soit complètement chargé
		if not character:FindFirstChild("Humanoid") then
			character:WaitForChild("Humanoid", 5)
		end
		task.wait(0.5) -- Petit délai pour que Backpack soit créé
		giveAxe(player)
	end)
	
	-- Donner la hache si le personnage existe déjà
	if player.Character then
		task.spawn(function()
			task.wait(0.5)
			giveAxe(player)
		end)
	end
end)

-- Pour les joueurs déjà présents si le script est rechargé
for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		giveAxe(p)
	end
end
