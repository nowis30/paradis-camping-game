--[[
    FishingTensionMiniGame
    Mini-jeu de tension de ligne : le joueur doit ramener le poisson sans casser la ligne
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local FishingTensionMiniGame = {}

-- Configuration du mini-jeu selon la rareté (progression continue en tirant)
local MINIGAME_CONFIG = {
    Common = {
        ReelRate = 20, -- % de progression par seconde si on tire sans être dans le rouge
        TensionIncreaseRate = 18, -- vitesse d'augmentation tension/sec quand le joueur tire
        TensionDecreaseRate = 45, -- vitesse de diminution quand le joueur relâche
        FishPullFrequency = 3.0, -- secondes entre chaque coup du poisson
        FishPullStrength = 22, -- augmentation tension lors d'un coup
        DangerZone = 70, -- tension à partir de laquelle la zone devient rouge
        BreakPoint = 100, -- tension max avant rupture
    },
    rare = {
        ReelRate = 16,
        TensionIncreaseRate = 20,
        TensionDecreaseRate = 40,
        FishPullFrequency = 2.5,
        FishPullStrength = 28,
        DangerZone = 70,
        BreakPoint = 100,
    },
    legendaire = {
        ReelRate = 12,
        TensionIncreaseRate = 22,
        TensionDecreaseRate = 35,
        FishPullFrequency = 2.0,
        FishPullStrength = 35,
        DangerZone = 70,
        BreakPoint = 100,
    },
}

-- Créer l'UI du mini-jeu
local function createMiniGameUI(player)
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishingTensionGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.Parent = playerGui
    
    -- Conteneur principal (plus grand pour mobile)
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0.9, 0, 0, 280)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    container.BorderSizePixel = 0
    container.Parent = screenGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 12)
    containerCorner.Parent = container
    
    -- Titre
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(255, 220, 100)
    title.Text = "⚡ TENSION DE LIGNE"
    title.Parent = container
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(1, -20, 0, 30)
    instructions.Position = UDim2.new(0, 10, 0, 45)
    instructions.BackgroundTransparency = 1
    instructions.Font = Enum.Font.Gotham
    instructions.TextScaled = true
    instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
    instructions.Text = "Maintenez [E] ou BOUTON pour tirer • Relâchez dans le rouge!"
    instructions.Parent = container
    
    -- Barre de tension (fond) - plus grande
    local tensionBarBg = Instance.new("Frame")
    tensionBarBg.Name = "TensionBarBg"
    tensionBarBg.Size = UDim2.new(1, -40, 0, 60)
    tensionBarBg.Position = UDim2.new(0, 20, 0, 80)
    tensionBarBg.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
    tensionBarBg.BorderSizePixel = 0
    tensionBarBg.Parent = container
    
    local tensionBarCorner = Instance.new("UICorner")
    tensionBarCorner.CornerRadius = UDim.new(0, 8)
    tensionBarCorner.Parent = tensionBarBg
    
    -- Barre de tension (remplissage)
    local tensionBar = Instance.new("Frame")
    tensionBar.Name = "TensionBar"
    tensionBar.Size = UDim2.new(0, 0, 1, 0)
    tensionBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    tensionBar.BorderSizePixel = 0
    tensionBar.Parent = tensionBarBg
    
    local tensionBarFillCorner = Instance.new("UICorner")
    tensionBarFillCorner.CornerRadius = UDim.new(0, 8)
    tensionBarFillCorner.Parent = tensionBar
    
    -- Indicateur de zone de danger (rouge)
    local dangerZone = Instance.new("Frame")
    dangerZone.Name = "DangerZone"
    dangerZone.Size = UDim2.new(0.2, 0, 1, 0)
    dangerZone.Position = UDim2.new(0.8, 0, 0, 0)
    dangerZone.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    dangerZone.BackgroundTransparency = 0.7
    dangerZone.BorderSizePixel = 0
    dangerZone.Parent = tensionBarBg
    
    local dangerCorner = Instance.new("UICorner")
    dangerCorner.CornerRadius = UDim.new(0, 8)
    dangerCorner.Parent = dangerZone
    
    -- Label de tension
    local tensionLabel = Instance.new("TextLabel")
    tensionLabel.Size = UDim2.new(1, 0, 1, 0)
    tensionLabel.BackgroundTransparency = 1
    tensionLabel.Font = Enum.Font.GothamBold
    tensionLabel.TextScaled = true
    tensionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    tensionLabel.Text = "0%"
    tensionLabel.Parent = tensionBarBg
    
    local tensionTextSize = Instance.new("UITextSizeConstraint")
    tensionTextSize.MaxTextSize = 28
    tensionTextSize.Parent = tensionLabel
    
    -- Barre de progression (fond) - plus grande
    local progressBarBg = Instance.new("Frame")
    progressBarBg.Name = "ProgressBarBg"
    progressBarBg.Size = UDim2.new(1, -40, 0, 50)
    progressBarBg.Position = UDim2.new(0, 20, 0, 150)
    progressBarBg.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
    progressBarBg.BorderSizePixel = 0
    progressBarBg.Parent = container

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 8)
    progressCorner.Parent = progressBarBg

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBarBg

    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 8)
    progressFillCorner.Parent = progressBar

    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.Size = UDim2.new(1, 0, 1, 0)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Font = Enum.Font.GothamBold
    progressLabel.TextScaled = true
    progressLabel.TextColor3 = Color3.fromRGB(220, 235, 255)
    progressLabel.Text = "Progrès: 0%"
    progressLabel.Parent = progressBarBg
    
    local progressTextSize = Instance.new("UITextSizeConstraint")
    progressTextSize.MaxTextSize = 24
    progressTextSize.Parent = progressLabel

    -- Label d'avertissement poisson qui tire
    local warningLabel = Instance.new("TextLabel")
    warningLabel.Name = "WarningLabel"
    warningLabel.Size = UDim2.new(1, -20, 0, 40)
    warningLabel.Position = UDim2.new(0, 10, 0, 210)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.TextScaled = true
    warningLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    warningLabel.Text = ""
    warningLabel.Visible = false
    warningLabel.Parent = container
    
    local warningTextSize = Instance.new("UITextSizeConstraint")
    warningTextSize.MaxTextSize = 22
    warningTextSize.Parent = warningLabel
    
    -- Bouton tactile pour mobile
    local touchButton = Instance.new("TextButton")
    touchButton.Name = "TouchButton"
    touchButton.Size = UDim2.new(0.4, 0, 0, 70)
    touchButton.Position = UDim2.new(0.3, 0, 1, 10)
    touchButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    touchButton.Text = "TIRER\n[E]"
    touchButton.Font = Enum.Font.GothamBold
    touchButton.TextScaled = true
    touchButton.TextColor3 = Color3.new(1, 1, 1)
    touchButton.BorderSizePixel = 0
    touchButton.Parent = container
    
    local touchBtnCorner = Instance.new("UICorner")
    touchBtnCorner.CornerRadius = UDim.new(0, 12)
    touchBtnCorner.Parent = touchButton
    
    local touchBtnStroke = Instance.new("UIStroke")
    touchBtnStroke.Color = Color3.fromRGB(50, 100, 50)
    touchBtnStroke.Thickness = 3
    touchBtnStroke.Parent = touchButton
    
    return screenGui, touchButton
end

-- Exécuter le mini-jeu
function FishingTensionMiniGame.Run(player, fishRarity)
    local config = MINIGAME_CONFIG[fishRarity] or MINIGAME_CONFIG.Common
    
    local gui, touchButton = createMiniGameUI(player)
    local container = gui.Container
    local tensionBar = container.TensionBarBg.TensionBar
    local tensionLabel = container.TensionBarBg:FindFirstChild("TextLabel")
    local progressBar = container.ProgressBarBg.ProgressBar
    local progressLabel = container.ProgressBarBg.ProgressLabel
    local warningLabel = container.WarningLabel
    local instructions = container.Instructions
    
    local tension = 0 -- 0 à 100
    local reelProgress = 0 -- 0 à 100
    local isPulling = false
    local fishIsPulling = false
    local gameOver = false
    local success = false
    local inDangerZone = false -- pour suivre si on est dans le rouge
    
    -- Ancrer le joueur pendant la pêche
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local originalAnchor = false
    local originalCFrame
    
    if rootPart then
        originalAnchor = rootPart.Anchored
        originalCFrame = rootPart.CFrame
        rootPart.Anchored = true
        
        -- Orienter vers l'eau (cherche le lac)
        local lake
        local terrainFolder = workspace:FindFirstChild("CampingTerrain")
        if terrainFolder then
            lake = terrainFolder:FindFirstChild("Lake")
        end
        lake = lake or workspace:FindFirstChild("Lake")
        
        if lake and lake:IsA("BasePart") then
            local lookAtPos = lake.Position
            local direction = (lookAtPos - rootPart.Position) * Vector3.new(1, 0, 1) -- Ignore Y
            if direction.Magnitude > 0 then
                local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + direction.Unit)
                rootPart.CFrame = targetCFrame
            end
        end
    end
    
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
    
    -- Connexion input (touche E)
    local UserInputService = game:GetService("UserInputService")
    local inputConnection
    local inputEndConnection
    
    -- Fallback 1: lier l'action via ContextActionService (plus fiable que InputBegan sur certaines UIs)
    local function reelAction(actionName, inputState, inputObject)
        if gameOver then return end
        if inputState == Enum.UserInputState.Begin then
            isPulling = true
        elseif inputState == Enum.UserInputState.End then
            isPulling = false
        end
    end
    ContextActionService:BindAction("FishingReel", reelAction, true, Enum.KeyCode.E)
    
    -- Fallback 2: connections directes au cas où CAS est désactivé par autre script
    inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if gameOver then return end
        if input.KeyCode == Enum.KeyCode.E then
            isPulling = true
        end
    end)
    inputEndConnection = UserInputService.InputEnded:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.E then
            isPulling = false
        end
    end)
    
    -- Bouton tactile pour mobile
    local touchBtnDown, touchBtnUp
    touchBtnDown = touchButton.MouseButton1Down:Connect(function()
        if gameOver then return end
        isPulling = true
        touchButton.BackgroundColor3 = Color3.fromRGB(150, 255, 150)
    end)
    touchBtnUp = touchButton.MouseButton1Up:Connect(function()
        isPulling = false
        touchButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    end)
    
    -- Boucle de coups du poisson (asynchrone)
    task.spawn(function()
        while not gameOver do
            task.wait(config.FishPullFrequency)
            if gameOver then break end
            
            -- Le poisson tire sur la ligne
            fishIsPulling = true
            tension = math.min(100, tension + config.FishPullStrength)
            
            -- Avertissement visuel
            warningLabel.Text = "🐟 LE POISSON TIRE! Relâchez!"
            warningLabel.Visible = true
            container.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
            
            task.wait(0.8)
            fishIsPulling = false
            warningLabel.Visible = false
            container.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
        end
    end)
    
    -- Boucle principale du mini-jeu (progression continue)
    local RunService = game:GetService("RunService")
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if gameOver then return end
        
        -- Mise à jour de la tension
        if isPulling then
            -- Le joueur tire : augmente tension
            tension = math.min(100, tension + config.TensionIncreaseRate * dt)
        else
            -- Le joueur relâche : réduit tension rapidement
            tension = math.max(0, tension - config.TensionDecreaseRate * dt)
        end
        
        -- Détecter quand on entre/sort de la zone de danger
        inDangerZone = tension >= config.DangerZone

        -- Progression du remorquage
        -- Progresse si on tire et que la tension est sous la zone rouge
        if isPulling and not inDangerZone then
            local rate = config.ReelRate
            -- Si le poisson tire, progresser plus lentement (mais pas 0)
            if fishIsPulling then
                rate = rate * 0.35
            end
            reelProgress = math.min(100, reelProgress + rate * dt)
        end
        
        -- Vérifier rupture de ligne (seulement si on atteint le point de rupture)
        if tension >= config.BreakPoint then
            gameOver = true
            success = false
            warningLabel.Text = "💔 LIGNE CASSÉE!"
            warningLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            warningLabel.Visible = true
            container.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
        end
        
        -- Vérifier succès (progression atteinte)
        if reelProgress >= 100 then
            gameOver = true
            success = true
            warningLabel.Text = "🎣 POISSON ATTRAPÉ!"
            warningLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
            warningLabel.Visible = true
            container.BackgroundColor3 = Color3.fromRGB(20, 80, 80)
        end
        
        -- Fallback 3: si pour une raison quelconque ni CAS ni events ne déclenchent, tester l'état de la touche en polling
        if UserInputService:IsKeyDown(Enum.KeyCode.E) and not gameOver then
            isPulling = true
        end

        -- Mettre à jour l'UI
        local tensionPercent = tension / 100
        tensionBar.Size = UDim2.new(tensionPercent, 0, 1, 0)
        tensionLabel.Text = math.floor(tension) .. "% tension"
        progressBar.Size = UDim2.new(reelProgress / 100, 0, 1, 0)
        progressLabel.Text = "Progrès: " .. math.floor(reelProgress) .. "%"
        
        -- Couleur dynamique de la barre selon le seuil de danger
        if tension < config.DangerZone then
            tensionBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        elseif tension < 85 then
            tensionBar.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
        else
            tensionBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        end
        
        -- Mettre à jour les instructions en temps réel
        if inDangerZone then
            instructions.Text = "⚠️ RELÂCHEZ MAINTENANT!"
            instructions.TextColor3 = Color3.fromRGB(255, 100, 100)
            touchButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
            touchButton.Text = "RELÂCHEZ!"
        elseif isPulling then
            instructions.Text = "Tirez pour ramener (restez sous le rouge)"
            instructions.TextColor3 = Color3.fromRGB(200, 255, 200)
            touchButton.BackgroundColor3 = Color3.fromRGB(150, 255, 150)
        else
            instructions.Text = "Maintenez pour tirer • Progrès en zone sûre"
            instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
            touchButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            touchButton.Text = "TIRER\n[E]"
        end
    end)
    
    -- Attendre fin du jeu
    while not gameOver do
        task.wait(0.1)
    end
    
    -- Nettoyage
    connection:Disconnect()
    if inputConnection then inputConnection:Disconnect() end
    if inputEndConnection then inputEndConnection:Disconnect() end
    if touchBtnDown then touchBtnDown:Disconnect() end
    if touchBtnUp then touchBtnUp:Disconnect() end
    ContextActionService:UnbindAction("FishingReel")
    
    -- Restaurer le mouvement du joueur
    if rootPart then
        rootPart.Anchored = originalAnchor
    end
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
    
    task.wait(2)
    gui:Destroy()
    
    return success
end

return FishingTensionMiniGame
