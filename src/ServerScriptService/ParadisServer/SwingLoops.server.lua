-- Simple swing loop tracker for Paradis
-- Counts full 360° rotations of a swing and awards +5 Money to each seated player per loop
-- NOTE: Adjust the model name and pivot selection below if needed

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Attendre PlayerProgressService
local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local PlayerProgressService = shared.PlayerProgressService or waitForShared("PlayerProgressService")

-- CONFIG
local SWING_MODEL_NAME = "Swing" -- Change this if your swing is named differently
local PIVOT_NAME = "Attachment1" -- The rotating part (cordes/ropes attachment)
local REWARD_PER_LOOP = 5 -- Adjust reward here

-- Debug: liste tous les enfants de Workspace
print("[SwingLoops] Recherche du modèle '" .. SWING_MODEL_NAME .. "' dans Workspace...")
print("[SwingLoops] Enfants actuels de Workspace:")
for _, child in ipairs(Workspace:GetChildren()) do
	print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
end

-- Locate swing model (or wait for it to be created in Studio)
local swing: Instance? = Workspace:FindFirstChild(SWING_MODEL_NAME)
if not swing then
	print("[SwingLoops] '" .. SWING_MODEL_NAME .. "' pas trouvé, attente...")
	swing = Workspace:WaitForChild(SWING_MODEL_NAME)
end
print("[SwingLoops] Swing trouvé: " .. swing.Name)

-- Collect Seat instances directly under the swing (or descendants)
local seats: { Seat } = {}
for _, inst in ipairs(swing:GetDescendants()) do
	if inst:IsA("Seat") then
		table.insert(seats, inst)
	end
end

-- Identify pivot part used for rotation measurement
local function findFirstBasePart(container: Instance): BasePart?
	if container:IsA("BasePart") then
		return container
	end
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") then
			return d
		end
	end
	return nil
end

local pivotPart: BasePart? = nil
local pivotCandidate = swing:FindFirstChild(PIVOT_NAME)
if pivotCandidate then
	pivotPart = findFirstBasePart(pivotCandidate)
end
if not pivotPart then
	-- fallback: use the swing's PrimaryPart or first BasePart we can find
	if (swing :: any).PrimaryPart then
		pivotPart = (swing :: any).PrimaryPart
	else
		pivotPart = findFirstBasePart(swing)
	end
end

if not pivotPart then
	warn("[SwingLoops] Could not find a pivot BasePart. Please set PIVOT_NAME or swing.PrimaryPart")
	return
end

-- Track rotation angle around Y by default. If your swing rotates around a different axis,
-- swap angle extraction (X/Y/Z) below.
local _, lastAngleY, _ = pivotPart.CFrame:ToEulerAnglesYXZ()
local accumulated = 0.0

local TWO_PI = math.pi * 2

local function rewardSeatedPlayers()
	for _, seat in ipairs(seats) do
		local humanoid = seat.Occupant
		if humanoid then
			local character = humanoid.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				-- Ajouter l'argent via leaderstats
				if player:FindFirstChild("leaderstats") then
					local ls = player.leaderstats
					local money = ls and ls:FindFirstChild("Money")
					if money and money:IsA("IntValue") then
						money.Value += REWARD_PER_LOOP
					end
				end
				
				-- Incrémenter le compteur de loops pour les achievements
				if PlayerProgressService then
					PlayerProgressService.IncrementStat(player, "SwingLoops", 1)
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	if not pivotPart or not pivotPart.Parent then return end
	local _, angleY, _ = pivotPart.CFrame:ToEulerAnglesYXZ()
	local delta = angleY - lastAngleY
	-- normalize to [-pi, pi]
	if delta > math.pi then
		delta -= TWO_PI
	elseif delta < -math.pi then
		delta += TWO_PI
	end
	accumulated += math.abs(delta)
	lastAngleY = angleY

	if accumulated >= TWO_PI then
		accumulated -= TWO_PI
		rewardSeatedPlayers()
	end
end)
