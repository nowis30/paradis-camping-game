-- WoodcuttingFeedback.server.lua
-- Se branche sur les prompts des troncs et du feu de camp pour envoyer des RemoteEvents
-- afin de déclencher les animations/feedback visuels côté client sans modifier tes scripts existants.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Attendre PlayerProgressService
local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local PlayerProgressService = shared.PlayerProgressService or waitForShared("PlayerProgressService")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local woodcutHitEvent = remotesFolder:FindFirstChild("WoodcutHit")
local woodcutBreakEvent = remotesFolder:FindFirstChild("WoodcutBreak")
local campfireFedEvent = remotesFolder:FindFirstChild("CampfireFed")
local logsUpdatedEvent = remotesFolder:FindFirstChild("LogsUpdated")

-- Paramètres par défaut si aucun script de tronc ne gère la logique
local LOGS_PER_TREE = 30 -- nombre de bûches par arbre
local HITS_PER_LOG = 5 -- nombre de coups de hache pour obtenir 1 bûche (de base)
local DEFAULT_HITS = LOGS_PER_TREE * HITS_PER_LOG -- 150 coups totaux de base
local RESPAWN_TIME = 15 -- secondes

local function fireLogsUpdated(player)
	if logsUpdatedEvent then
		logsUpdatedEvent:FireAllClients(player, player:GetAttribute("Logs"))
	end
end

-- Fonction pour faire disparaître progressivement les parts de l'arbre
local function hideTreeParts(node, percentage)
	-- Séparer les parts: tronc (LogPart) vs le reste (feuillage/branches)
	local trunkParts = {}
	local otherParts = {}
	
	for _, desc in ipairs(node:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Transparency < 1 then
			if desc.Name == "LogPart" then
				table.insert(trunkParts, desc)
			else
				table.insert(otherParts, desc)
			end
		end
	end
	
	local allParts = {}
	-- Ordre: d'abord le feuillage/branches, PUIS le tronc à la fin
	for _, part in ipairs(otherParts) do
		table.insert(allParts, part)
	end
	for _, part in ipairs(trunkParts) do
		table.insert(allParts, part)
	end
	
	if #allParts == 0 then return end
	
	-- Calcule combien de parts doivent être cachées
	local partsToHide = math.floor(#allParts * percentage)
	
	-- Cache les parts dans l'ordre (feuillage d'abord, tronc en dernier)
	local hiddenCount = 0
	for i = 1, #allParts do
		if hiddenCount >= partsToHide then break end
		
		local part = allParts[i]
		if not part:GetAttribute("_OriginalTransparency") then
			-- Sauvegarder la transparence originale
			part:SetAttribute("_OriginalTransparency", part.Transparency)
		end
		
		part.Transparency = 1
		part.CanCollide = false
		hiddenCount += 1
	end
end

-- Fonction pour restaurer toutes les parts de l'arbre
local function restoreTreeParts(node)
	for _, desc in ipairs(node:GetDescendants()) do
		if desc:IsA("BasePart") then
			local originalTransparency = desc:GetAttribute("_OriginalTransparency")
			if originalTransparency then
				desc.Transparency = originalTransparency
				desc.CanCollide = true
				desc:SetAttribute("_OriginalTransparency", nil)
			end
		end
	end
end

local function handleLogCut(player, node)
	print("[WoodcuttingFeedback] 🪓 handleLogCut appelé -", player.Name, "coupe", node.Name)
	-- Essaie d'utiliser les attributs existants, sinon applique un fallback simple
	local isActive = node:GetAttribute("IsActive")
	if isActive == false then return end

	if isActive == nil then
		-- Par défaut, on considère le tronc actif
		node:SetAttribute("IsActive", true)
	end

	local hitsRemaining = node:GetAttribute("HitsRemaining")
	local logsObtained = node:GetAttribute("LogsObtained") or 0
	
	if hitsRemaining == nil then
		-- Fallback simplifié: 1er coup initialise les PV
		hitsRemaining = DEFAULT_HITS
		node:SetAttribute("HitsRemaining", hitsRemaining)
		node:SetAttribute("LogsObtained", 0)
	end

	-- Puissance de la hache influence le nombre de points retirés
	local axePower = player:GetAttribute("AxePower") or 1
	local hitPower = axePower -- La puissance de la hache = nombre de coups retirés
	
	-- Applique un coup
	local oldHits = hitsRemaining
	hitsRemaining -= hitPower
	node:SetAttribute("HitsRemaining", math.max(0, hitsRemaining))

	-- Calculer combien de bûches le joueur obtient avec ces coups
	local totalHitsDone = DEFAULT_HITS - hitsRemaining
	local newLogsTotal = math.floor(totalHitsDone / HITS_PER_LOG)
	local logsToGive = newLogsTotal - logsObtained
	
	if logsToGive > 0 then
		-- Donner les bûches au joueur
		local currentLogs = player:GetAttribute("Logs") or 0
		player:SetAttribute("Logs", currentLogs + logsToGive)
		node:SetAttribute("LogsObtained", newLogsTotal)
		print(string.format("[Woodcutting] %s obtient %d bûche(s) de '%s' (total: %d/%d)", 
			player.Name, logsToGive, node.Name, newLogsTotal, LOGS_PER_TREE))
		
		-- Incrémente les stats de woodcutting pour les achievements
		if PlayerProgressService then
			PlayerProgressService.IncrementStat(player, "LogsCut", logsToGive)
		end
		
		fireLogsUpdated(player)
	end

	-- Calculer le pourcentage de dégâts (pour faire disparaître des parts)
	-- On fait disparaître l'arbre en 30 étapes (1 étape = 1 bûche obtenue)
	local damagePercentage = newLogsTotal / LOGS_PER_TREE
	hideTreeParts(node, damagePercentage)

	-- Feedback coup
	if woodcutHitEvent then
		woodcutHitEvent:FireAllClients(node, player)
	end

	-- Vérifier si l'arbre est complètement coupé
	if hitsRemaining <= 0 or newLogsTotal >= LOGS_PER_TREE then
		node:SetAttribute("IsActive", false)

		-- Feedback casse totale
		if woodcutBreakEvent then
			woodcutBreakEvent:FireAllClients(node, player)
		end

		print(string.format("[Woodcutting] %s a complètement coupé '%s' -> %d bûches obtenues au total", 
			player.Name, node.Name, newLogsTotal))

		-- Respawn après 15 secondes
		task.delay(RESPAWN_TIME, function()
			if node and node.Parent then
				-- Restaurer toutes les parts de l'arbre
				restoreTreeParts(node)
				node:SetAttribute("IsActive", true)
				node:SetAttribute("HitsRemaining", DEFAULT_HITS)
				node:SetAttribute("LogsObtained", 0)
				print(string.format("[Woodcutting] '%s' respawn - arbre restauré", node.Name))
			end
		end)
	end
end

local function connectPrompt(prompt, node)
	if not prompt or not prompt:IsA("ProximityPrompt") then return end
	if prompt:GetAttribute("__BoundWoodcut") then return end
	prompt:SetAttribute("__BoundWoodcut", true)

	print("[WoodcuttingFeedback] ✅ ProximityPrompt connecté sur", node.Name)

	prompt.Triggered:Connect(function(player)
		print("[WoodcuttingFeedback] 🪓 ProximityPrompt déclenché par", player.Name, "sur", node.Name)
		-- Si un autre script a déjà géré le coup, on enverra au moins le feedback
		-- et un fallback pour que le joueur ressente une progression.
		handleLogCut(player, node)
	end)
end

-- Petite fonction utilitaire pour connecter les troncs à l'événement
local function connectLogPrompts()
	local folder = Workspace:FindFirstChild("WoodcuttingNodes")
	if not folder then
		warn("[WoodcuttingFeedback] ❌ WoodcuttingNodes manquant: impossible d'envoyer feedback coupe")
		return
	end
	print("[WoodcuttingFeedback] 🌲 Connexion des ProximityPrompts sur", #folder:GetChildren(), "LogNodes")
	-- Connecte prompts existants
	for _, node in ipairs(folder:GetChildren()) do
		if node:IsA("Model") then
			for _, desc in ipairs(node:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					connectPrompt(desc, node)
				end
			end
		end
	end
	-- Connecte aussi les nouveaux prompts ajoutés plus tard
	folder.ChildAdded:Connect(function(node)
		if node:IsA("Model") then
			node.DescendantAdded:Connect(function(desc)
				if desc:IsA("ProximityPrompt") then
					connectPrompt(desc, node)
				end
			end)
			for _, desc in ipairs(node:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					connectPrompt(desc, node)
				end
			end
		end
	end)
end

-- Connexion du feu de camp (juste pour feedback visuel alimentation)
local function connectCampfirePrompt()
	local campfire = Workspace:FindFirstChild("Campfire")
	if not campfire then
		warn("Campfire manquant")
		return
	end
	local fireBase = campfire:FindFirstChild("FireBase")
	if not fireBase then
		warn("FireBase manquant dans Campfire")
		return
	end
	local prompt
	for _, child in ipairs(fireBase:GetChildren()) do
		if child:IsA("ProximityPrompt") then
			prompt = child; break
		end
	end
	if not prompt then
		warn("ProximityPrompt manquant sur FireBase")
		return
	end
	-- Désactivé: maintenant géré par CampfireService.server.lua
	-- prompt.Triggered:Connect(function(player)
	-- 	if campfireFedEvent then
	-- 		campfireFedEvent:FireAllClients(player, player:GetAttribute("Logs"))
	-- 	end
	-- 	task.defer(function()
	-- 		if logsUpdatedEvent then
	-- 			logsUpdatedEvent:FireAllClients(player, player:GetAttribute("Logs"))
	-- 		end
	-- 	end)
	-- end)
end

-- Écoute globale de changements d'attribut Logs pour mise à jour transport visuel
local function connectLogsAttribute()
	Players.PlayerAdded:Connect(function(player)
		player.AttributeChanged:Connect(function(attr)
			if attr == "Logs" and logsUpdatedEvent then
				logsUpdatedEvent:FireAllClients(player, player:GetAttribute("Logs"))
			end
		end)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		p.AttributeChanged:Connect(function(attr)
			if attr == "Logs" and logsUpdatedEvent then
				logsUpdatedEvent:FireAllClients(p, p:GetAttribute("Logs"))
			end
		end)
	end
end

connectToolActivated()
connectLogPrompts()
connectCampfirePrompt()
connectLogsAttribute()

print("[WoodcuttingFeedback] ✅ Système de coupe activé (Tool.Activated + ProximityPrompts)")
