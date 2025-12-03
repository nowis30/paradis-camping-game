-- WoodcuttingAnimations.client.lua
-- Joue une animation de "coup de hache" quand le joueur interagit avec un tronc (ProximityPrompt).
-- Nécessite un AnimationId valide (remplacer PLACEHOLDER_ANIMATION_ID). Utilise une animation basique si non fourni.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local currentHumanoid
local loadedAnimation

-- ID de l'animation à REMPLACER par ta propre animation (format rbxassetid://1234567890)
local SWING_ANIMATION_ID = "rbxassetid://0" -- 0 = aucun; remplace par une vraie ID
local CHOP_SOUND_ID = "rbxassetid://0" -- Remplace par un son de hache (ex: impact bois)
local BREAK_SOUND_ID = "rbxassetid://0" -- Remplace par un son plus fort (craquement)
local CHOP_SOUND_VOLUME = 0.8
local CHOP_SOUND_PITCH = 1
local PARTICLE_ENABLED = true
local PARTICLE_COLOR = ColorSequence.new(Color3.fromRGB(160,120,80), Color3.fromRGB(90,60,40))
local PARTICLE_TEXTURE = "" -- Optionnel: ajoute un asset de sprite de copeaux
local PARTICLE_LIFETIME = NumberRange.new(0.3,0.45)
local PARTICLE_SPEED = NumberRange.new(6,9)
local PARTICLE_EMIT_MIN = 8
local PARTICLE_EMIT_MAX = 12
local CARRY_LOG_MODEL_NAME = "CarryLogVisual" -- Nom interne du modèle visuel transporté
local LOG_ATTACH_OFFSET = Vector3.new(0, -0.5, -1.2) -- Position relative sur le torse

-- RemoteEvents (créés côté serveur dans WoodcutRemotes.lua)
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local woodcutHitEvent = remotesFolder:FindFirstChild("WoodcutHit")
local woodcutBreakEvent = remotesFolder:FindFirstChild("WoodcutBreak")
local campfireFedEvent = remotesFolder:FindFirstChild("CampfireFed")
local logsUpdatedEvent = remotesFolder:FindFirstChild("LogsUpdated")

-- Récupère le Humanoid actuel du joueur
local function getHumanoid()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid
end

-- Charge l'animation si possible
local function ensureAnimationLoaded()
	if loadedAnimation then return end
	local humanoid = getHumanoid()
	if not humanoid then return end
	currentHumanoid = humanoid
	if SWING_ANIMATION_ID ~= "rbxassetid://0" then
		local anim = Instance.new("Animation")
		anim.AnimationId = SWING_ANIMATION_ID
		loadedAnimation = humanoid:LoadAnimation(anim)
	end
end

-- Joue l'animation courte de swing si chargée; sinon petite fallback: change la vitesse de marche brièvement
local function playSwing()
	ensureAnimationLoaded()
	if loadedAnimation then
		loadedAnimation:Play(0.1, 1, 1)
	end
end

-- Crée / met à jour l'affichage visuel des bûches transportées
local function updateCarryVisual(logCount)
	local character = player.Character
	if not character then return end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso then return end

	local existing = character:FindFirstChild(CARRY_LOG_MODEL_NAME)
	if logCount <= 0 then
		if existing then existing:Destroy() end
		return
	end

	if not existing then
		existing = Instance.new("Model")
		existing.Name = CARRY_LOG_MODEL_NAME
		local part = Instance.new("Part")
		part.Name = "LogChunk"
		part.Size = Vector3.new(0.6, 0.6, 1.6)
		part.Color = Color3.fromRGB(92, 64, 51)
		part.Material = Enum.Material.Wood
		part.CanCollide = false
		part.Anchored = false
		part.Parent = existing
		existing.Parent = character

		-- Weld au torse
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = part
		weld.Parent = part
		part.CFrame = torso.CFrame * CFrame.new(LOG_ATTACH_OFFSET)
	end

	-- Ajuste transparence / petite animation quand le nombre change
	local part = existing:FindFirstChild("LogChunk")
	if part then
		part.Transparency = 0
		-- Ajoute un SurfaceGui simple qui montre le nombre
		local gui = part:FindFirstChild("CountGui")
		if not gui then
			gui = Instance.new("SurfaceGui")
			gui.Name = "CountGui"
			gui.Face = Enum.NormalId.Right
			gui.Adornee = part
			gui.Parent = part
			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.fromScale(1,1)
			label.BackgroundTransparency = 1
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.TextColor3 = Color3.fromRGB(255, 225, 200)
			label.Parent = gui
		end
		local label = gui:FindFirstChild("Label")
		if label then
			label.Text = tostring(logCount)
		end
		-- Petit tween d'échelle pour feedback
		local tween = TweenService:Create(part, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(0.7,0.7,1.8)})
		tween:Play()
		task.delay(0.2, function()
			if part then
				part.Size = Vector3.new(0.6,0.6,1.6)
			end
		end)
	end
end

-- Effet visuel sur coup de tronc
local function playHitEffect(node)
	if not node or not node:IsA("Model") then return end
	local part = node:FindFirstChild("LogPart")
	if not part then
		for _, c in ipairs(node:GetChildren()) do
			if c:IsA("BasePart") then part = c; break end
		end
	end
	if not part then return end
	-- Flash de couleur
	local originalColor = part.Color
	part.Color = Color3.fromRGB(160,120,80)
	task.delay(0.1, function()
		if part then
			part.Color = originalColor
		end
	end)

	-- Son d'impact
	if CHOP_SOUND_ID ~= "rbxassetid://0" then
		local sound = part:FindFirstChild("ChopSound")
		if not sound then
			sound = Instance.new("Sound")
			sound.Name = "ChopSound"
			sound.SoundId = CHOP_SOUND_ID
			sound.Volume = CHOP_SOUND_VOLUME
			sound.PlaybackSpeed = CHOP_SOUND_PITCH
			sound.Parent = part
		end
		sound:Play()
	end

	-- Particules de copeaux
	if PARTICLE_ENABLED then
		local emitter = part:FindFirstChild("ChipsEmitter")
		if not emitter then
			emitter = Instance.new("ParticleEmitter")
			emitter.Name = "ChipsEmitter"
			emitter.Texture = PARTICLE_TEXTURE
			emitter.Color = PARTICLE_COLOR
			emitter.Lifetime = PARTICLE_LIFETIME
			emitter.Rate = 0 -- On utilisera Emit
			emitter.Speed = PARTICLE_SPEED
			emitter.Rotation = NumberRange.new(0,360)
			emitter.RotSpeed = NumberRange.new(-80,80)
			emitter.SpreadAngle = Vector2.new(45,45)
			emitter.LightEmission = 0
			emitter.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(1, 0.05)
			}
			emitter.Parent = part
		end
			local axePower = player:GetAttribute("AxePower") or 1
			local baseCount = math.random(PARTICLE_EMIT_MIN, PARTICLE_EMIT_MAX)
			local scaled = math.clamp(math.floor(baseCount * (0.7 + axePower * 0.3)), PARTICLE_EMIT_MIN, PARTICLE_EMIT_MAX * 4)
			emitter:Emit(scaled)
	end
end

-- Effet final de casse (sons + particules boostées + shake caméra)
local function playBreakEffect(node)
	if not node or not node:IsA("Model") then return end
	local part = node:FindFirstChild("LogPart")
	if not part then
		for _, c in ipairs(node:GetChildren()) do
			if c:IsA("BasePart") then part = c; break end
		end
	end
	if not part then return end

	-- Son de casse
	if BREAK_SOUND_ID ~= "rbxassetid://0" then
		local breakSound = part:FindFirstChild("BreakSound")
		if not breakSound then
			breakSound = Instance.new("Sound")
			breakSound.Name = "BreakSound"
			breakSound.SoundId = BREAK_SOUND_ID
			breakSound.Volume = CHOP_SOUND_VOLUME + 0.2
			breakSound.PlaybackSpeed = CHOP_SOUND_PITCH * 0.9
			breakSound.Parent = part
		end
		breakSound:Play()
	end

	-- Burst particules plus intense
	local emitter = part:FindFirstChild("ChipsEmitter")
	if emitter then
		local axePower = player:GetAttribute("AxePower") or 1
		local burst = math.clamp( math.floor( (PARTICLE_EMIT_MAX * 2) * (0.6 + axePower * 0.4) ), PARTICLE_EMIT_MAX, PARTICLE_EMIT_MAX * 6)
		emitter:Emit(burst)
	end

	-- Secousse caméra forte
	cameraShake(true)
end

-- Shake caméra (léger ou fort)
local shaking = false
function cameraShake(isFinal)
	if shaking then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	shaking = true
	local duration = isFinal and 0.35 or 0.18
	local magnitude = isFinal and 0.4 or 0.15
	local startTime = tick()
	local originalCFrame = cam.CFrame
	while tick() - startTime < duration do
		local offset = Vector3.new( (math.random()-0.5)*magnitude, (math.random()-0.5)*magnitude, (math.random()-0.5)*magnitude )
		cam.CFrame = originalCFrame * CFrame.new(offset)
		game:GetService("RunService").RenderStepped:Wait()
	end
	cam.CFrame = originalCFrame
	shaking = false
end

-- Effet visuel quand feu alimenté
local function playCampfireFed(playerWho, remainingLogs)
	-- Peut être étendu: chat message ou particules
	if playerWho == player then
		print("Feu alimenté. Logs restants: " .. tostring(remainingLogs))
	end
end

-- Connexion des RemoteEvents
if woodcutHitEvent then
	woodcutHitEvent.OnClientEvent:Connect(function(node, who)
		if who == player then
			playSwing()
			cameraShake(false)
		end
		playHitEffect(node)
	end)
end

if woodcutBreakEvent then
	woodcutBreakEvent.OnClientEvent:Connect(function(node, who)
		playBreakEffect(node)
	end)
end

if logsUpdatedEvent then
	logsUpdatedEvent.OnClientEvent:Connect(function(p, newCount)
		if p == player then
			updateCarryVisual(newCount or 0)
		end
	end)
end

if campfireFedEvent then
	campfireFedEvent.OnClientEvent:Connect(function(p, logsAfter)
		playCampfireFed(p, logsAfter)
	end)
end

-- Détermine si le prompt appartient à un tronc de WoodcuttingNodes
local function isLogPrompt(prompt)
	local parentPart = prompt.Parent
	if not parentPart or not parentPart:IsA("BasePart") then return false end
	local model = parentPart.Parent
	if not model or not model:IsA("Model") then return false end
	local nodesFolder = workspace:FindFirstChild("WoodcuttingNodes")
	if not nodesFolder then return false end
	return model.Parent == nodesFolder
end

-- Événement : quand un ProximityPrompt est déclenché par ce joueur
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer ~= player then return end
	if isLogPrompt(prompt) then
		playSwing()
		-- Déclenche aussi un effet d'impact local même si le serveur n'a pas encore émis l'event
		local parentPart = prompt.Parent
		local model = parentPart and parentPart.Parent
		if model and model:IsA("Model") then
			playHitEffect(model)
		end
	end
end)

-- Recharge l'animation si le personnage respawn
player.CharacterAdded:Connect(function()
	loadedAnimation = nil
	currentHumanoid = nil
	ensureAnimationLoaded()
	updateCarryVisual(player:GetAttribute("Logs") or 0)
end)

-- Initial update if character already exists
if player.Character then
	updateCarryVisual(player:GetAttribute("Logs") or 0)
end
