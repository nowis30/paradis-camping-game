-- CampfireService.server.lua
-- Gère le feu de camp : diminution progressive, alimentation avec bûches, effets visuels

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function waitForShared(key)
	while not shared[key] do
		RunService.Heartbeat:Wait()
	end
	return shared[key]
end

local EconomyService = waitForShared("ParadisEconomyService")

-- Configuration
local FIRE_DECREASE_RATE = 2 -- FireLevel diminue de 2 toutes les X secondes (plus rapide)
local FIRE_DECREASE_INTERVAL = 10 -- secondes (diminue plus souvent)
local FIRE_MAX_LEVEL = 100
local FIRE_MIN_LEVEL = 0
local LOGS_PER_FUEL = 1 -- nombre de bûches consommées par alimentation
local FIRE_GAIN_PER_LOG = 20 -- augmentation de FireLevel par bûche

-- Configuration corde de bois
local WOODPILE_MAX_CAPACITY = 50 -- capacité maximale de la corde
local WOODPILE_POSITION_OFFSET = Vector3.new(30, 0, 0) -- position relative au feu (30 studs)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local campfireFedEvent = remotesFolder:FindFirstChild("CampfireFed")
local logsUpdatedEvent = remotesFolder:FindFirstChild("LogsUpdated")

-- Références
local campfire = Workspace:WaitForChild("Campfire", 10)
if not campfire then
	warn("[CampfireService] Campfire introuvable dans Workspace")
	return
end

local fireLevel = campfire:FindFirstChild("FireLevel")
if not fireLevel then
	fireLevel = Instance.new("NumberValue")
	fireLevel.Name = "FireLevel"
	fireLevel.Value = 20 -- Niveau initial
	fireLevel.Parent = campfire
end

-- Corde de bois (WoodPile)
local woodPileStored = campfire:FindFirstChild("WoodPileStored")
if not woodPileStored then
	woodPileStored = Instance.new("IntValue")
	woodPileStored.Name = "WoodPileStored"
	woodPileStored.Value = 0
	woodPileStored.Parent = campfire
end

-- Trouver une part pour le feu (cherche FireBase, Fire, ou n'importe quelle BasePart)
local firePart = campfire:FindFirstChild("FireBase") 
	or campfire:FindFirstChild("Fire") 
	or campfire:FindFirstChildOfClass("BasePart")

if not firePart then
	warn("[CampfireService] Aucune part trouvée dans Campfire pour créer le ProximityPrompt!")
end

-- Chercher ou créer les effets visuels
local fireEffect = campfire:FindFirstChildOfClass("Fire", true) -- cherche récursivement
local pointLight = campfire:FindFirstChildOfClass("PointLight", true)

-- Créer le Fire effect s'il n'existe pas
if not fireEffect and firePart then
	fireEffect = Instance.new("Fire")
	fireEffect.Name = "CampfireFire"
	fireEffect.Size = 8
	fireEffect.Heat = 8
	fireEffect.Color = Color3.fromRGB(255, 150, 50)
	fireEffect.SecondaryColor = Color3.fromRGB(200, 80, 30)
	fireEffect.Parent = firePart
	print("[CampfireService] ✓ Fire effect créé sur " .. firePart.Name)
end

-- Créer le PointLight s'il n'existe pas
if not pointLight and firePart then
	pointLight = Instance.new("PointLight")
	pointLight.Name = "CampfireLight"
	pointLight.Brightness = 2
	pointLight.Range = 30
	pointLight.Color = Color3.fromRGB(255, 150, 50)
	pointLight.Parent = firePart
	print("[CampfireService] ✓ PointLight créé sur " .. firePart.Name)
end

-- Création visuelle de la corde de bois
local woodPileModel
local function createWoodPile()
	if campfire:FindFirstChild("WoodPile") then
		woodPileModel = campfire:FindFirstChild("WoodPile")
		return
	end
	
	woodPileModel = Instance.new("Model")
	woodPileModel.Name = "WoodPile"
	
	local basePos = campfire:GetPivot().Position + WOODPILE_POSITION_OFFSET
	
	-- Base de la corde
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 0.5, 3)
	base.Position = basePos
	base.Anchored = true
	base.Color = Color3.fromRGB(70, 50, 40)
	base.Material = Enum.Material.Wood
	base.CanCollide = false -- Ne pas gêner le joueur
	base.Parent = woodPileModel
	
	print(string.format("[CampfireService] WoodPile créé à position: %s", tostring(basePos)))
	
	-- ProximityPrompt pour déposer des bûches
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Déposer des bûches"
	prompt.ObjectText = "Corde de bois"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12 -- Distance augmentée
	prompt.RequiresLineOfSight = false -- Visible même à travers objets
	prompt.Parent = base
	
	-- Label affichant le stock
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = base
	
	-- Titre
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 20
	titleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	titleLabel.Text = "📦 RÉSERVE DE BOIS"
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.Parent = billboardGui
	
	-- Stock
	local label = Instance.new("TextLabel")
	label.Name = "StockLabel"
	label.Size = UDim2.new(1, 0, 0.6, 0)
	label.Position = UDim2.new(0, 0, 0.4, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 28
	label.TextColor3 = Color3.fromRGB(150, 220, 100)
	label.Text = "🪵 0/" .. WOODPILE_MAX_CAPACITY
	label.TextStrokeTransparency = 0.5
	label.Parent = billboardGui
	
	woodPileModel.Parent = campfire
	woodPileModel:PivotTo(CFrame.new(basePos))
	
	print("[CampfireService] ✓ Corde de bois créée et visible avec BillboardGui '📦 RÉSERVE DE BOIS'")
end

-- Mise à jour visuelle de la corde selon le stock
local function updateWoodPileVisuals()
	if not woodPileModel then return end
	
	local stored = woodPileStored.Value
	local base = woodPileModel:FindFirstChild("Base")
	if not base then return end
	
	-- Mettre à jour le label
	local billboardGui = base:FindFirstChildOfClass("BillboardGui")
	if billboardGui then
		local label = billboardGui:FindFirstChild("StockLabel")
		if label then
			label.Text = string.format("🪵 %d/%d", stored, WOODPILE_MAX_CAPACITY)
		end
	end
	
	-- Supprimer anciens logs visuels
	for _, child in ipairs(woodPileModel:GetChildren()) do
		if child.Name == "LogVisual" then
			child:Destroy()
		end
	end
	
	-- Ajouter des bûches visuelles (par paquets de 5)
	local visualCount = math.min(math.floor(stored / 5), 10)
	for i = 1, visualCount do
		local log = Instance.new("Part")
		log.Name = "LogVisual"
		log.Size = Vector3.new(0.5, 0.5, 1.5)
		log.Color = Color3.fromRGB(92, 64, 51)
		log.Material = Enum.Material.Wood
		log.Anchored = true
		log.CanCollide = false
		
		-- Position aléatoire sur la pile
		local offsetX = (math.random() - 0.5) * 3
		local offsetZ = (math.random() - 0.5) * 2
		local offsetY = 0.5 + (i * 0.3)
		log.Position = base.Position + Vector3.new(offsetX, offsetY, offsetZ)
		log.Orientation = Vector3.new(0, math.random(0, 360), 90)
		
		log.Parent = woodPileModel
	end
end

-- Mise à jour visuelle du feu selon le niveau
local function updateFireVisuals()
	local level = fireLevel.Value
	local intensity = math.clamp(level / FIRE_MAX_LEVEL, 0, 1)
	
	if fireEffect then
		-- Diminution TRÈS progressive et visible de la flamme de 100 à 0
		if level <= 10 then
			-- Entre 10 et 0: diminution dramatique
			local smallIntensity = level / 10 -- 1.0 à niveau 10, 0.0 à niveau 0
			
			-- Taille diminue fortement: de 8 studs (niveau 10) à 0.5 stud (niveau 0)
			fireEffect.Size = 0.5 + (7.5 * smallIntensity)
			fireEffect.Heat = 0.5 + (7.5 * smallIntensity)
			
			-- Couleur: orange (10) -> rouge sombre (5) -> brun rougeâtre (0)
			local red = 255
			local green = math.floor(20 + (130 * smallIntensity)) -- 20 à 150
			local blue = math.floor(10 + (10 * smallIntensity)) -- 10 à 20
			fireEffect.Color = Color3.fromRGB(red, green, blue)
			
			local secRed = math.floor(100 + (55 * smallIntensity)) -- 100 à 155
			local secGreen = math.floor(10 + (40 * smallIntensity)) -- 10 à 50
			local secBlue = 5
			fireEffect.SecondaryColor = Color3.fromRGB(secRed, secGreen, secBlue)
			
			-- Désactiver complètement la flamme à 0
			fireEffect.Enabled = level > 0
			
		elseif level <= 30 then
			-- Entre 11 et 30: flamme faible mais visible
			local midIntensity = (level - 10) / 20 -- 0.0 à 1.0
			
			fireEffect.Size = 8 + (6 * midIntensity) -- 8 à 14 studs
			fireEffect.Heat = 8 + (6 * midIntensity)
			
			-- Couleur: orange moyen -> orange vif
			fireEffect.Color = Color3.fromRGB(255, 150 + (50 * midIntensity), 30 + (20 * midIntensity))
			fireEffect.SecondaryColor = Color3.fromRGB(200, 80 + (40 * midIntensity), 20)
			fireEffect.Enabled = true
			
		else
			-- Au-dessus de 30: flamme normale à intense
			local highIntensity = (level - 30) / 70 -- 0.0 à 1.0
			
			fireEffect.Size = 14 + (12 * highIntensity) -- 14 à 26 studs
			fireEffect.Heat = 14 + (12 * highIntensity)
			
			-- Couleur: orange vif -> jaune éclatant
			local green = 200 + (55 * highIntensity) -- 200 à 255
			local blue = 50 + (20 * highIntensity) -- 50 à 70
			fireEffect.Color = Color3.fromRGB(255, green, blue)
			fireEffect.SecondaryColor = Color3.fromRGB(255, 120 + (80 * highIntensity), 40)
			fireEffect.Enabled = true
		end
	end
	
	if pointLight then
		-- Lumière suit la même progression
		if level <= 10 then
			local smallIntensity = level / 10
			pointLight.Brightness = 0.2 + (1.3 * smallIntensity) -- 0.2 à 1.5
			pointLight.Range = 3 + (12 * smallIntensity) -- 3 à 15 studs
			
			-- Couleur: rouge sombre quand faible
			local green = math.floor(50 + (100 * smallIntensity))
			pointLight.Color = Color3.fromRGB(255, green, 50)
			pointLight.Enabled = level > 0
			
		elseif level <= 30 then
			local midIntensity = (level - 10) / 20
			pointLight.Brightness = 1.5 + (1.5 * midIntensity) -- 1.5 à 3.0
			pointLight.Range = 15 + (15 * midIntensity) -- 15 à 30 studs
			pointLight.Color = Color3.fromRGB(255, 150 + (50 * midIntensity), 80)
			pointLight.Enabled = true
			
		else
			local highIntensity = (level - 30) / 70
			pointLight.Brightness = 3 + (2 * highIntensity) -- 3.0 à 5.0
			pointLight.Range = 30 + (20 * highIntensity) -- 30 à 50 studs
			pointLight.Color = Color3.fromRGB(255, 200 + (55 * highIntensity), 100)
			pointLight.Enabled = true
		end
	end
end

-- Calculer le multiplicateur de revenu basé sur le niveau du feu
local function getFireIncomeMultiplier()
	local level = fireLevel.Value
	if level >= 10 then
		return 1.0 -- Revenu normal
	else
		-- Entre 0 et 9: multiplicateur = level / 10
		-- 9 = 0.9, 5 = 0.5, 0 = 0.0
		return level / 10
	end
end

-- Appliquer la pénalité de revenu à tous les joueurs
local function applyFirePenaltyToAllPlayers()
	local multiplier = getFireIncomeMultiplier()
	
	for _, player in ipairs(Players:GetPlayers()) do
		if EconomyService and EconomyService.RecalculateIncome then
			local baseIncome = EconomyService.RecalculateIncome(player, nil)
			-- Stocker le multiplicateur comme attribut pour que EconomyService puisse l'utiliser
			player:SetAttribute("FirePenaltyMultiplier", multiplier)
		end
	end
end

-- Diminution progressive du feu
local function startFireDecay()
	while true do
		task.wait(FIRE_DECREASE_INTERVAL)
		
		if fireLevel.Value > FIRE_MIN_LEVEL then
			local oldLevel = fireLevel.Value
			fireLevel.Value = math.max(FIRE_MIN_LEVEL, fireLevel.Value - FIRE_DECREASE_RATE)
			updateFireVisuals()
			print(string.format("[CampfireService] Feu diminue -> FireLevel=%d", fireLevel.Value))
			
			-- Si on passe sous 10 ou qu'on change de niveau sous 10, recalculer les revenus
			if oldLevel >= 10 and fireLevel.Value < 10 then
				applyFirePenaltyToAllPlayers()
				print("[CampfireService] ⚠️ Feu faible! Revenus réduits.")
			elseif fireLevel.Value < 10 then
				applyFirePenaltyToAllPlayers()
			end
		end
	end
end

-- Connexion au ProximityPrompt de la corde pour déposer des bûches
local function connectWoodPilePrompt()
	task.wait(0.5) -- Attendre que la corde soit créée
	if not woodPileModel then return end
	
	local base = woodPileModel:FindFirstChild("Base")
	if not base then return end
	
	local prompt = base:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then return end
	
	prompt.Triggered:Connect(function(player)
		local currentLogs = player:GetAttribute("Logs") or 0
		
		if currentLogs < 1 then
			-- Pas de bûches
			return
		end
		
		if woodPileStored.Value >= WOODPILE_MAX_CAPACITY then
			-- Corde pleine
			return
		end
		
		-- Déposer bûches
		local toDeposit = math.min(currentLogs, WOODPILE_MAX_CAPACITY - woodPileStored.Value)
		player:SetAttribute("Logs", currentLogs - toDeposit)
		woodPileStored.Value = woodPileStored.Value + toDeposit
		
		updateWoodPileVisuals()
		
		print(string.format("[CampfireService] %s a déposé %d bûches -> Stock=%d", 
			player.Name, toDeposit, woodPileStored.Value))
		
		if logsUpdatedEvent then
			logsUpdatedEvent:FireAllClients(player, player:GetAttribute("Logs"))
		end
		
		-- Message flottant
		local character = player.Character
		if character then
			local head = character:FindFirstChild("Head")
			if head then
				local billboardGui = Instance.new("BillboardGui")
				billboardGui.Size = UDim2.new(0, 200, 0, 50)
				billboardGui.StudsOffset = Vector3.new(0, 3, 0)
				billboardGui.AlwaysOnTop = true
				billboardGui.Parent = head
				
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.GothamBold
				label.TextSize = 20
				label.TextColor3 = Color3.fromRGB(150, 220, 100)
				label.Text = "📦 +" .. toDeposit .. " stockées"
				label.TextStrokeTransparency = 0.5
				label.Parent = billboardGui
				
				task.delay(2, function()
					billboardGui:Destroy()
				end)
			end
		end
	end)
end

-- Connexion au ProximityPrompt pour alimenter le feu
local function connectFuelPrompt()
	if not firePart then
		warn("[CampfireService] Aucune part trouvée dans Campfire - impossible de créer ProximityPrompt")
		return
	end
	
	-- Supprimer tous les anciens ProximityPrompts pour éviter les conflits
	for _, oldPrompt in ipairs(firePart:GetChildren()) do
		if oldPrompt:IsA("ProximityPrompt") then
			print(string.format("[CampfireService] Suppression ancien ProximityPrompt: %s", oldPrompt.Name))
			oldPrompt:Destroy()
		end
	end
	
	-- Créer le nouveau prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Alimenter le feu"
	prompt.ObjectText = "Feu de camp"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 25 -- Distance pour feu géant
	prompt.RequiresLineOfSight = false
	prompt.Parent = firePart
	print(string.format("[CampfireService] ProximityPrompt créé sur %s (distance: 25 studs)", firePart.Name))
	
	prompt.Triggered:Connect(function(player)
		-- Priorité 1: bûches magiques (bonus +50)
		local magicLogs = player:GetAttribute("MagicLogs") or 0
		if magicLogs >= LOGS_PER_FUEL then
			local oldLevel = fireLevel.Value
			player:SetAttribute("MagicLogs", magicLogs - LOGS_PER_FUEL)
			local ProShopConfig = require(ReplicatedStorage.Config.ProShopConfig)
			local magicBonus = ProShopConfig.MAGIC_LOG_FIRE_BONUS
			fireLevel.Value = math.min(FIRE_MAX_LEVEL, fireLevel.Value + magicBonus)
			updateFireVisuals()
			
			-- Restaurer revenus si on repasse au-dessus de 10
			if oldLevel < 10 and fireLevel.Value >= 10 then
				applyFirePenaltyToAllPlayers()
				print("[CampfireService] ✓ Feu ranimé! Revenus restaurés.")
			end
			
			print(string.format("[CampfireService] %s a alimenté avec bûche magique -> FireLevel=%d (+%d)", 
				player.Name, fireLevel.Value, magicBonus))
			
			-- Feedback visuel
			if campfireFedEvent then
				campfireFedEvent:FireAllClients(player, player:GetAttribute("Logs"))
			end
			
			-- Message flottant
			local character = player.Character
			if character then
				local head = character:FindFirstChild("Head")
				if head then
					local billboardGui = Instance.new("BillboardGui")
					billboardGui.Size = UDim2.new(0, 200, 0, 50)
					billboardGui.StudsOffset = Vector3.new(0, 3, 0)
					billboardGui.AlwaysOnTop = true
					billboardGui.Parent = head
					
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamBold
					label.TextSize = 20
					label.TextColor3 = Color3.fromRGB(138, 43, 226)
					label.Text = "✨ +" .. magicBonus .. " Feu (magique!)"
					label.TextStrokeTransparency = 0.5
					label.Parent = billboardGui
					
					task.delay(2, function()
						billboardGui:Destroy()
					end)
				end
			end
			return
		end
		
		-- Priorité 2: utiliser la corde de bois si disponible
		if woodPileStored.Value >= LOGS_PER_FUEL then
			local oldLevel = fireLevel.Value
			woodPileStored.Value = woodPileStored.Value - LOGS_PER_FUEL
			fireLevel.Value = math.min(FIRE_MAX_LEVEL, fireLevel.Value + FIRE_GAIN_PER_LOG)
			updateFireVisuals()
			updateWoodPileVisuals()
			
			-- Restaurer revenus si on repasse au-dessus de 10
			if oldLevel < 10 and fireLevel.Value >= 10 then
				applyFirePenaltyToAllPlayers()
				print("[CampfireService] ✓ Feu ranimé! Revenus restaurés.")
			end
			
			print(string.format("[CampfireService] %s a alimenté le feu depuis la corde -> FireLevel=%d, Stock=%d", 
				player.Name, fireLevel.Value, woodPileStored.Value))
			
			-- Feedback visuel
			if campfireFedEvent then
				campfireFedEvent:FireAllClients(player, player:GetAttribute("Logs"))
			end
			
			-- Message flottant
			local character = player.Character
			if character then
				local head = character:FindFirstChild("Head")
				if head then
					local billboardGui = Instance.new("BillboardGui")
					billboardGui.Size = UDim2.new(0, 200, 0, 50)
					billboardGui.StudsOffset = Vector3.new(0, 3, 0)
					billboardGui.AlwaysOnTop = true
					billboardGui.Parent = head
					
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamBold
					label.TextSize = 20
					label.TextColor3 = Color3.fromRGB(255, 150, 50)
					label.Text = "🔥 +" .. FIRE_GAIN_PER_LOG .. " Feu (corde)"
					label.TextStrokeTransparency = 0.5
					label.Parent = billboardGui
					
					task.delay(2, function()
						billboardGui:Destroy()
					end)
				end
			end
			return
		end
		
		-- Priorité 3: utiliser les bûches du joueur
		local currentLogs = player:GetAttribute("Logs") or 0
		
		if currentLogs < LOGS_PER_FUEL then
			-- Pas assez de bûches
			if campfireFedEvent then
				campfireFedEvent:FireClient(player, "❌ Pas assez de bûches! (Inventaire: " .. currentLogs .. ", Corde: " .. woodPileStored.Value .. ")")
			end
			return
		end
		
		-- Consommer bûches et augmenter feu
		local oldLevel = fireLevel.Value
		player:SetAttribute("Logs", currentLogs - LOGS_PER_FUEL)
		fireLevel.Value = math.min(FIRE_MAX_LEVEL, fireLevel.Value + FIRE_GAIN_PER_LOG)
		updateFireVisuals()
		
		-- Restaurer revenus si on repasse au-dessus de 10
		if oldLevel < 10 and fireLevel.Value >= 10 then
			applyFirePenaltyToAllPlayers()
			print("[CampfireService] ✓ Feu ranimé! Revenus restaurés.")
		end
		
		print(string.format("[CampfireService] %s a alimenté le feu -> FireLevel=%d, Logs=%d", 
			player.Name, fireLevel.Value, player:GetAttribute("Logs")))
		
		-- Feedback visuel
		if campfireFedEvent then
			campfireFedEvent:FireAllClients(player, player:GetAttribute("Logs"))
		end
		if logsUpdatedEvent then
			logsUpdatedEvent:FireAllClients(player, player:GetAttribute("Logs"))
		end
		
		-- Message flottant
		local character = player.Character
		if character then
			local head = character:FindFirstChild("Head")
			if head then
				local billboardGui = Instance.new("BillboardGui")
				billboardGui.Size = UDim2.new(0, 200, 0, 50)
				billboardGui.StudsOffset = Vector3.new(0, 3, 0)
				billboardGui.AlwaysOnTop = true
				billboardGui.Parent = head
				
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.GothamBold
				label.TextSize = 20
				label.TextColor3 = Color3.fromRGB(255, 150, 50)
				label.Text = "🔥 +" .. FIRE_GAIN_PER_LOG .. " Feu"
				label.TextStrokeTransparency = 0.5
				label.Parent = billboardGui
				
				task.delay(2, function()
					billboardGui:Destroy()
				end)
			end
		end
	end)
end

-- Initialisation
createWoodPile()
updateFireVisuals()
updateWoodPileVisuals()
connectFuelPrompt()
connectWoodPilePrompt()
task.spawn(startFireDecay)

print("[CampfireService] Service initialisé - FireLevel:", fireLevel.Value, "WoodPile:", woodPileStored.Value)

-- Mise à jour visuelle en continu si le niveau change manuellement
fireLevel:GetPropertyChangedSignal("Value"):Connect(updateFireVisuals)
woodPileStored:GetPropertyChangedSignal("Value"):Connect(updateWoodPileVisuals)
