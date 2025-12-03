-- FILE: GolfKartSystem.server.lua

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Pads
local startPad = workspace:WaitForChild("DragStartPad")
local finishPad = workspace:WaitForChild("DragFinishPad")
-- Note: Pas de pad de magasin, on utilise le ProShop existant côté jeu

-- Kart template (ton kart dans Workspace)
local kartTemplate = workspace:WaitForChild("Kart")
print("✅ Kart template trouvé:", kartTemplate.Name)

-- Kart folder
local kartFolder = Instance.new("Folder")
kartFolder.Name = "GolfKarts"
kartFolder.Parent = workspace

-- Remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("GolfKartRemotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "GolfKartRemotes"
    remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name, className)
    local remote = remotesFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new(className)
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote
end

local ShiftGear = getOrCreateRemote("ShiftGear", "RemoteEvent")
local SetThrottle = getOrCreateRemote("SetThrottle", "RemoteEvent")
local SetBrake = getOrCreateRemote("SetBrake", "RemoteEvent")
local SetSteering = getOrCreateRemote("SetSteering", "RemoteEvent")
local RequestKartSpawn = getOrCreateRemote("RequestKartSpawn", "RemoteEvent")
local RequestKartDespawn = getOrCreateRemote("RequestKartDespawn", "RemoteEvent")
local RequestKartPurchase = getOrCreateRemote("RequestKartPurchase", "RemoteEvent")
local NotifyKartStatus = getOrCreateRemote("NotifyKartStatus", "RemoteEvent")
local RequestKartUpgrade = getOrCreateRemote("RequestKartUpgrade", "RemoteEvent") -- {type="engine|battery|tires", levels=1}

-- Constants
local RPM_MIN = 1000
local RPM_MAX = 7000
local RPM_YELLOW = 5000
local RPM_GREEN = 6000
local RPM_RED = 6500

local EARLY_SHIFT_THRESHOLD = 4000

local BOOST_YELLOW = 1.15
local BOOST_GREEN = 1.35
local BOOST_RED_PENALTY = 0.85
local BOOST_EARLY = 1.0

local BASE_SPEED = 40
local KART_COST = 200

local GEAR_RATIOS = {
    [1] = 0.4,
    [2] = 0.6,
    [3] = 0.8,
    [4] = 1.0,
    [5] = 1.2,
}

-- Torque curve
local function getTorqueFactor(rpm)
    if rpm < 1000 then
        return 0.2
    elseif rpm < 3000 then
        return 0.6
    elseif rpm < 5000 then
        return 0.9
    elseif rpm < 6000 then
        return 1.1
    elseif rpm < 6500 then
        return 1.3
    else
        return 0
    end
end

-- Player state
local playerState = {}

-- Create kart model (clone ton kart existant)
local function createKartModel(player)
    -- Clone ton kart
    local model = kartTemplate:Clone()
    model.Name = player.Name .. "_GolfKart"
    
    -- Trouve ou crée le PrimaryPart
    local base = model.PrimaryPart or model:FindFirstChild("Base") or model:FindFirstChildWhichIsA("BasePart")
    if not base then
        warn("Aucune part principale trouvée dans le kart!")
        return nil
    end
    
    -- S'assure que c'est le PrimaryPart
    if not model.PrimaryPart then
        model.PrimaryPart = base
    end
    
    -- Trouve le siège
    local seat = model:FindFirstChild("VehicleSeat", true) or model:FindFirstChild("Seat", true) or model:FindFirstChild("DriveSeat", true)
    if not seat then
        warn("Aucun siège trouvé dans le kart!")
        return nil
    end
    
    -- Configure le siège pour notre système
    if seat:IsA("VehicleSeat") then
        seat.MaxSpeed = 0
        seat.Torque = 0
        seat.TurnSpeed = 0
    end
    
    -- Ajoute BodyVelocity et BodyGyro si pas déjà présents
    local bodyVelocity = base:FindFirstChildOfClass("BodyVelocity")
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(500000, 0, 500000)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.P = 1250
        bodyVelocity.Parent = base
    end
    
    local bodyGyro = base:FindFirstChildOfClass("BodyGyro")
    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(0, 5000, 0)
        bodyGyro.P = 1000
        bodyGyro.D = 100
        bodyGyro.Parent = base
    end
    
    -- Attributes pour le système
    base:SetAttribute("Gear", 1)
    base:SetAttribute("RPM", RPM_MIN)
    base:SetAttribute("IsRacing", false)
    
    model.Parent = kartFolder
    
    print("✅ Kart cloné pour", player.Name)
    return model
end

-- Spawn kart
local function spawnKartForPlayer(player, cframe)
    local state = playerState[player]
    if not state then return end
    
    if state.kartModel then
        state.kartModel:Destroy()
        state.kartModel = nil
    end
    
    -- Orientation: calculer direction vers la ligne d'arrivée
    local startPos = cframe.Position
    local finishPos = finishPad:GetPivot().Position
    local direction = (finishPos - startPos).Unit
    local lookCFrame = CFrame.lookAt(startPos, startPos + direction)
    
    local model = createKartModel(player)
    model:SetPrimaryPartCFrame(lookCFrame)
    state.kartModel = model
    
    task.wait(0.1)
    
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local seat = model:FindFirstChild("DriverSeat", true)
        if humanoid and seat and hrp then
            -- Téléporter le personnage dans le kart
            hrp.CFrame = lookCFrame * CFrame.new(0, 3, 0)
            task.wait(0.1)
            seat:Sit(humanoid)
        end
    end
end

-- Handle gear shift
local function handleShiftGear(player)
    local state = playerState[player]
    if not state then return end
    if not state.hasKart or not state.kartModel then return end
    if state.gear >= 5 then return end
    
    local rpm = state.rpm
    local boost = 1.0
    
    if rpm >= RPM_GREEN and rpm < RPM_RED then
        boost = BOOST_GREEN
    elseif rpm >= RPM_YELLOW and rpm < RPM_GREEN then
        boost = BOOST_YELLOW
    elseif rpm >= RPM_RED then
        boost = BOOST_RED_PENALTY
    elseif rpm < EARLY_SHIFT_THRESHOLD then
        boost = BOOST_EARLY
    end
    
    state.shiftBoost = boost
    state.gear += 1
    state.rpm = math.clamp(rpm * 0.6, RPM_MIN, RPM_RED - 100)
end

-- Handle throttle
local function handleSetThrottle(player, isDown)
    local state = playerState[player]
    if not state then return end
    if not state.hasKart or not state.kartModel then return end
    state.throttle = isDown and 1 or 0
end

-- Handle brake
local function handleSetBrake(player, isDown)
    local state = playerState[player]
    if not state then return end
    if not state.hasKart or not state.kartModel then return end
    state.brake = isDown and 1 or 0
end

-- Handle steering
local function handleSetSteering(player, value)
    local state = playerState[player]
    if not state then return end
    if not state.hasKart or not state.kartModel then return end
    state.steering = math.clamp(value, -1, 1)
end

-- Handle kart purchase
local function handleKartPurchase(player)
    local state = playerState[player]
    if not state then return end
    if state.hasKart then
        NotifyKartStatus:FireClient(player, "Vous avez déjà un kart!")
        return
    end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    local coins = leaderstats and leaderstats:FindFirstChild("Coins")
    if not coins then return end
    
    if coins.Value >= KART_COST then
        coins.Value -= KART_COST
        state.hasKart = true
        NotifyKartStatus:FireClient(player, "Kart acheté pour " .. KART_COST .. "$!")
        
        -- Spawn immédiat du kart sur la ligne de départ
        local spawnCFrame = startPad:GetPivot() * CFrame.new(0, 1, -5)
        spawnKartForPlayer(player, spawnCFrame)
    else
        NotifyKartStatus:FireClient(player, "Pas assez d'argent! Coût: " .. KART_COST .. "$")
    end
end

-- Handle kart spawn
local function handleKartSpawn(player)
    local state = playerState[player]
    if not state then return end
    if not state.hasKart then
        NotifyKartStatus:FireClient(player, "Vous devez acheter un kart d'abord!")
        return
    end
    -- Toujours spawn à la ligne de départ du drag
    local spawnCFrame = startPad:GetPivot() * CFrame.new(0, 1, -5)
    spawnKartForPlayer(player, spawnCFrame)
end

-- Handle kart despawn
local function handleKartDespawn(player)
    local state = playerState[player]
    if not state then return end
    
    if state.kartModel then
        state.kartModel:Destroy()
        state.kartModel = nil
        NotifyKartStatus:FireClient(player, "Kart rangé")
    end
end

-- Player added
Players.PlayerAdded:Connect(function(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    local coins = leaderstats:FindFirstChild("Coins")
    if not coins then
        coins = Instance.new("IntValue")
        coins.Name = "Coins"
        coins.Value = 500
        coins.Parent = leaderstats
    end
    
    playerState[player] = {
        hasKart = false,
        kartModel = nil,
        gear = 1,
        rpm = RPM_MIN,
        throttle = 0,
        brake = 0,
        steering = 0,
        shiftBoost = 1.0,
        isRacing = false,
        raceStartTime = 0,
        bestDragTime = nil,
        upgrades = {engine=0, battery=0, tires=0},
    }
end)

-- Player removing
Players.PlayerRemoving:Connect(function(player)
    local state = playerState[player]
    if state and state.kartModel then
        state.kartModel:Destroy()
    end
    playerState[player] = nil
end)

-- Connect remotes
ShiftGear.OnServerEvent:Connect(handleShiftGear)
SetThrottle.OnServerEvent:Connect(handleSetThrottle)
SetBrake.OnServerEvent:Connect(handleSetBrake)
SetSteering.OnServerEvent:Connect(handleSetSteering)
RequestKartPurchase.OnServerEvent:Connect(handleKartPurchase)
RequestKartSpawn.OnServerEvent:Connect(handleKartSpawn)
RequestKartDespawn.OnServerEvent:Connect(handleKartDespawn)
RequestKartUpgrade.OnServerEvent:Connect(function(player, upgrade)
    -- upgrade = {type="engine"|"battery"|"tires", levels = number}
    local state = playerState[player]
    if not state then return end
    if not state.hasKart then
        NotifyKartStatus:FireClient(player, "Achetez un kart avant les améliorations.")
        return
    end
    local utype = typeof(upgrade) == "table" and upgrade.type or nil
    local levels = typeof(upgrade) == "table" and tonumber(upgrade.levels) or 0
    if not utype or levels == 0 then return end
    if utype ~= "engine" and utype ~= "battery" and utype ~= "tires" then return end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    local coins = leaderstats and leaderstats:FindFirstChild("Coins")
    if not coins then return end
    
    -- Coût simple: 150$ par niveau d'upgrade
    local costPerLevel = 150
    local cost = costPerLevel * math.abs(levels)
    if coins.Value < cost then
        NotifyKartStatus:FireClient(player, "Pas assez d'argent pour l'upgrade ("..cost.."$)")
        return
    end
    coins.Value -= cost
    state.upgrades[utype] = (state.upgrades[utype] or 0) + levels
    NotifyKartStatus:FireClient(player, string.format("Upgrade %s %+d (reste %d$)", utype, levels, coins.Value))
end)


-- Drag start pad
local startPadPart = startPad:IsA("BasePart") and startPad or startPad:FindFirstChildWhichIsA("BasePart", true)
if not startPadPart then
    warn("[GolfKartSystem] DragStartPad n'a pas de BasePart, système de course désactivé")
else
    startPadPart.Touched:Connect(function(hit)
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    local state = playerState[player]
    if not state or not state.hasKart then return end
    if state.isRacing then return end
    
    if not state.kartModel or not state.kartModel.Parent then
        local spawnCFrame = startPadPart.CFrame * CFrame.new(0, 1, -5)
        spawnKartForPlayer(player, spawnCFrame)
        task.wait(0.2)
    end
    
    state.gear = 1
    state.rpm = RPM_MIN
    state.shiftBoost = 1.0
    state.isRacing = true
    state.raceStartTime = tick()
    
    if state.kartModel then
        state.kartModel.PrimaryPart:SetAttribute("IsRacing", true)
    end
    
    NotifyKartStatus:FireClient(player, "Course lancée! Go!")
    end)
end

-- Drag finish pad (handle Model or BasePart)
local finishPadPart = finishPad:IsA("BasePart") and finishPad or finishPad:FindFirstChildWhichIsA("BasePart", true)
if not finishPadPart then
    warn("[GolfKartSystem] DragFinishPad n'a pas de BasePart, arrivée désactivée")
else
finishPadPart.Touched:Connect(function(hit)
    local character = hit.Parent
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    local state = playerState[player]
    if not state or not state.isRacing then return end
    
    local elapsed = tick() - state.raceStartTime
    state.isRacing = false
    
    if state.kartModel then
        state.kartModel.PrimaryPart:SetAttribute("IsRacing", false)
    end
    
    local reward = math.max(10, math.floor(200 - elapsed * 10))
    local leaderstats = player:FindFirstChild("leaderstats")
    local coins = leaderstats and leaderstats:FindFirstChild("Coins")
    if coins then
        coins.Value += reward
    end
    
    if not state.bestDragTime or elapsed < state.bestDragTime then
        state.bestDragTime = elapsed
        NotifyKartStatus:FireClient(player, string.format("🏁 Nouveau record: %.2fs! +%d$", elapsed, reward))
    else
        NotifyKartStatus:FireClient(player, string.format("🏁 Temps: %.2fs! +%d$", elapsed, reward))
    end
end)
end

-- Main engine loop
RunService.Heartbeat:Connect(function(dt)
    for player, state in pairs(playerState) do
        if state.kartModel and state.kartModel.Parent then
            -- Gestion RPM
            if state.throttle > 0 then
                state.rpm = state.rpm + (800 * state.gear) * dt
            elseif state.brake > 0 then
                state.rpm = state.rpm - 300 * dt
            else
                state.rpm = state.rpm - 600 * dt
            end
            
            state.rpm = math.clamp(state.rpm, RPM_MIN, RPM_MAX)
            
            local torque = getTorqueFactor(state.rpm)
            local gearRatio = GEAR_RATIOS[state.gear] or 1.0
            local upgradeMultiplier = 1 + state.upgrades.engine * 0.1 + state.upgrades.battery * 0.05 + state.upgrades.tires * 0.03
            
            local speed = BASE_SPEED * gearRatio * torque * state.shiftBoost * upgradeMultiplier
            
            -- Si brake, vitesse négative (marche arrière)
            if state.brake > 0 and state.throttle == 0 then
                speed = -BASE_SPEED * 0.3
            end
            
            local base = state.kartModel.PrimaryPart
            local seat = state.kartModel:FindFirstChild("DriverSeat", true)
            
            if seat and seat.Occupant then
                local forward = seat.CFrame.LookVector
                local bodyVel = base:FindFirstChildOfClass("BodyVelocity")
                if bodyVel then
                    -- Mouvement: throttle = avant, brake = arrière
                    if state.throttle > 0 then
                        bodyVel.Velocity = forward * speed
                    elseif state.brake > 0 then
                        bodyVel.Velocity = forward * speed  -- speed est déjà négatif si brake
                    else
                        bodyVel.Velocity = Vector3.zero
                    end
                end
                
                local bodyGyro = base:FindFirstChildOfClass("BodyGyro")
                if bodyGyro then
                    -- Rotation basée sur steering et vitesse
                    if state.steering ~= 0 then
                        local currentSpeed = bodyVel.Velocity.Magnitude
                        local turnRate = state.steering * 3 * dt * (currentSpeed / 10 + 0.5)
                        local currentCFrame = bodyGyro.CFrame
                        bodyGyro.CFrame = currentCFrame * CFrame.Angles(0, turnRate, 0)
                    else
                        bodyGyro.CFrame = seat.CFrame
                    end
                end
            else
                local bodyVel = base:FindFirstChildOfClass("BodyVelocity")
                if bodyVel then
                    bodyVel.Velocity = Vector3.zero
                end
            end
            
            state.shiftBoost = state.shiftBoost + (1 - state.shiftBoost) * math.min(5 * dt, 1)
            
            base:SetAttribute("Gear", state.gear)
            base:SetAttribute("RPM", math.floor(state.rpm))
            base:SetAttribute("IsRacing", state.isRacing)
        end
    end
end)

print("✅ GolfKartSystem chargé")
