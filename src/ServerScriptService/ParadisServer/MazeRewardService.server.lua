-- MazeRewardService.server.lua
-- Système de récompense pour le labyrinthe

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Attendre le service d'économie
local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local EconomyService = shared.ParadisEconomyService or waitForShared("ParadisEconomyService")
local PlayerProgressService = shared.PlayerProgressService or waitForShared("PlayerProgressService")

-- ⚙️ CONFIGURATION
local MAZE_REWARD = 100 -- Argent gagné en complétant le labyrinthe
local COOLDOWN_TIME = 300 -- Cooldown de 5 minutes (300 secondes) avant de pouvoir recommencer
local MAZE_FOLDER_NAME = "Maze" -- Nom du dossier du labyrinthe dans Workspace
local START_PART_NAME = "MazeStart" -- Nom de la zone de départ
local END_PART_NAME = "MazeEnd" -- Nom de la zone d'arrivée

-- Suivre les joueurs qui ont complété récemment
local playerCooldowns = {} -- [UserId] = tick() du dernier succès
local playersInMaze = {} -- [UserId] = true si le joueur est entré dans le labyrinthe

-- Afficher un texte flottant au-dessus du joueur
local function showFloatingText(character, text, color)
    if not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(6, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 28
    label.TextColor3 = color or Color3.fromRGB(255, 220, 0)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Text = text
    label.Parent = billboard
    
    game:GetService("Debris"):AddItem(billboard, 3)
end

-- Vérifier si le joueur est en cooldown
local function isOnCooldown(userId)
    local lastTime = playerCooldowns[userId]
    if not lastTime then
        return false
    end
    
    local elapsed = tick() - lastTime
    return elapsed < COOLDOWN_TIME
end

-- Obtenir le temps restant de cooldown
local function getCooldownRemaining(userId)
    local lastTime = playerCooldowns[userId]
    if not lastTime then
        return 0
    end
    
    local elapsed = tick() - lastTime
    local remaining = COOLDOWN_TIME - elapsed
    return math.max(0, remaining)
end

-- Formater le temps en minutes:secondes
local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

-- Gérer l'entrée dans le labyrinthe (zone de départ)
local function onStartTouched(hit, startPart)
    local character = hit.Parent
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    local userId = player.UserId
    
    -- Marquer que le joueur est entré dans le labyrinthe
    if not playersInMaze[userId] then
        playersInMaze[userId] = true
        
        if isOnCooldown(userId) then
            local remaining = getCooldownRemaining(userId)
            showFloatingText(character, "⏰ Cooldown: " .. formatTime(remaining), Color3.fromRGB(255, 100, 100))
            print("[MazeReward]", player.Name, "est en cooldown pour", formatTime(remaining))
        else
            showFloatingText(character, "🏁 Trouve la sortie du labyrinthe!", Color3.fromRGB(100, 200, 255))
            print("[MazeReward]", player.Name, "entre dans le labyrinthe")
        end
    end
end

-- Gérer l'arrivée à la fin du labyrinthe
local function onEndTouched(hit, endPart)
    local character = hit.Parent
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    local userId = player.UserId
    
    -- Vérifier que le joueur est entré par le début
    if not playersInMaze[userId] then
        showFloatingText(character, "⚠️ Tu dois commencer par l'entrée!", Color3.fromRGB(255, 150, 0))
        return
    end
    
    -- Vérifier le cooldown
    if isOnCooldown(userId) then
        local remaining = getCooldownRemaining(userId)
        showFloatingText(character, "⏰ Cooldown: " .. formatTime(remaining), Color3.fromRGB(255, 100, 100))
        return
    end
    
    -- Donner la récompense
    local success = EconomyService.AddMoney(player, MAZE_REWARD)
    
    if success then
        showFloatingText(character, "🎉 +" .. MAZE_REWARD .. " $!", Color3.fromRGB(50, 255, 50))
        print("[MazeReward]", player.Name, "a complété le labyrinthe! Récompense:", MAZE_REWARD .. "$")
        
        -- Incrémente les stats de maze pour les achievements
        if PlayerProgressService then
            PlayerProgressService.IncrementStat(player, "MazesCompleted", 1)
        end
        
        -- Ajouter au cooldown
        playerCooldowns[userId] = tick()
        
        -- Retirer du labyrinthe
        playersInMaze[userId] = nil
        
        -- Effet de particules
        local sparkles = Instance.new("Sparkles")
        sparkles.SparkleColor = Color3.fromRGB(255, 215, 0)
        sparkles.Parent = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        game:GetService("Debris"):AddItem(sparkles, 2)
    else
        warn("[MazeReward] Échec de l'ajout d'argent pour", player.Name)
    end
end

-- Nettoyer quand un joueur quitte
local function onPlayerRemoving(player)
    local userId = player.UserId
    playersInMaze[userId] = nil
    -- On garde le cooldown même après déconnexion (dans cette session serveur)
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Initialisation
wait(3)

local maze = workspace:FindFirstChild(MAZE_FOLDER_NAME)
if not maze then
    warn("[MazeReward] ⚠️ Dossier '" .. MAZE_FOLDER_NAME .. "' introuvable dans Workspace!")
    warn("[MazeReward] Créez un dossier 'Maze' et ajoutez-y deux Parts:")
    warn("[MazeReward]   - 'MazeStart' à l'entrée (toucher = début)")
    warn("[MazeReward]   - 'MazeEnd' à la sortie (toucher = récompense)")
    return
end

-- Trouver la zone de départ
local startPart = maze:FindFirstChild(START_PART_NAME)
if startPart and startPart:IsA("BasePart") then
    startPart.Touched:Connect(function(hit)
        onStartTouched(hit, startPart)
    end)
    startPart.Color = Color3.fromRGB(100, 255, 100) -- Vert pour l'entrée
    startPart.Material = Enum.Material.Neon
    print("[MazeReward] ✅ Zone de départ connectée:", startPart.Name)
else
    warn("[MazeReward] ⚠️ Part '" .. START_PART_NAME .. "' introuvable dans le dossier Maze!")
end

-- Trouver la zone d'arrivée
local endPart = maze:FindFirstChild(END_PART_NAME)
if endPart and endPart:IsA("BasePart") then
    endPart.Touched:Connect(function(hit)
        onEndTouched(hit, endPart)
    end)
    endPart.Color = Color3.fromRGB(255, 215, 0) -- Doré pour la sortie
    endPart.Material = Enum.Material.Neon
    print("[MazeReward] ✅ Zone d'arrivée connectée:", endPart.Name)
else
    warn("[MazeReward] ⚠️ Part '" .. END_PART_NAME .. "' introuvable dans le dossier Maze!")
end

print("[MazeReward] ✅ Système de récompense du labyrinthe initialisé!")
print("[MazeReward] 💰 Récompense:", MAZE_REWARD .. "$")
print("[MazeReward] ⏰ Cooldown:", formatTime(COOLDOWN_TIME))
