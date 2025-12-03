--[[
    PlotService
    Génère le camping, gère les parcelles et le processus de réservation côté serveur.
    Toutes les informations sont exposées via shared.ParadisPlotService pour les autres scripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local CampConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CampConfig"))
local BuildRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuildRemotes"))

local ParadisServerFolder = ServerScriptService:FindFirstChild("ParadisServer") or script.Parent
local WorldGenerator = require(ParadisServerFolder:WaitForChild("CampingWorldGenerator"))
-- Accès au service via 'shared' (le service est un Script, pas un ModuleScript)
local function getCampsiteDefaultsService()
    return shared.ParadisCampsiteDefaultsService
end

local plotsById = {}
local playerToPlot = {}

local function getDataService()
    return shared.ParadisDataService
end

local function getPlacementService()
    return shared.ParadisPlacementService
end

local function getTrailerService()
    return shared.ParadisTrailerService
end

local function getPlotSurfaceY(plot)
    if plot then
        if plot.BaseHeight then
            return plot.BaseHeight
        end
        if plot.BasePart then
            local base = plot.BasePart
            return base.Position.Y + (base.Size.Y / 2)
        end
    end
    return plot and plot.Center and plot.Center.Y or 0
end

local function destroyOwnerSign(plot)
    if plot.SignBoard then
        plot.SignBoard:Destroy()
        plot.SignBoard = nil
    end
    if plot.SignPost then
        plot.SignPost:Destroy()
        plot.SignPost = nil
    end
    plot.SignBillboard = nil
end

local function clearPlot(plot)
    if plot.Container then
        plot.Container:ClearAllChildren()
    end
    plot.PlacedObjects = {}
    plot.PlayerData = nil
    plot.TrailerParts = {}
    plot.TrailerFolder = nil
    plot.TrailerCells = nil
    plot.TrailerModels = nil
    destroyOwnerSign(plot)
    if plot.Prompt then
        plot.Prompt.Enabled = true
    end
end

local function ensureOwnerSign(plot)
    if plot.SignBoard and plot.SignBoard.Parent then
        return plot.SignBoard
    end

    local signage = CampConfig.Signage or {}
    local postHeight = signage.PostHeight or (signage.PostSize and signage.PostSize.Y) or 6
    local postSize = signage.PostSize or Vector3.new(1.5, postHeight, 1.5)

    local signPost = Instance.new("Part")
    signPost.Name = "PlotSign_" .. plot.Id
    signPost.Size = postSize
    signPost.Material = Enum.Material.WoodPlanks
    signPost.Color = Color3.fromRGB(150, 112, 66)
    signPost.Anchored = true
    signPost.CanCollide = false
    signPost.Parent = Workspace

    local board = Instance.new("Part")
    board.Name = "SignBoard"
    board.Size = signage.BoardSize or Vector3.new(8, 4, 0.6)
    board.Material = Enum.Material.Wood
    board.Color = Color3.fromRGB(120, 80, 40)
    board.Anchored = true
    board.CanCollide = false
    board.Parent = Workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlotBillboard"
    billboard.Size = signage.BillboardSize or UDim2.new(0, 220, 0, 80)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
    billboard.MaxDistance = 140
    billboard.AlwaysOnTop = true
    billboard.Parent = board

    local label = Instance.new("TextLabel")
    label.Name = "StatusLabel"
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextColor3 = Color3.fromRGB(200, 255, 200)
    label.Parent = billboard

    -- Ajouter un ProximityPrompt pour voir les détails du camping
    local detailsPrompt = Instance.new("ProximityPrompt")
    detailsPrompt.Name = "CampingDetailsPrompt"
    detailsPrompt.ActionText = "Voir les détails"
    detailsPrompt.ObjectText = "Camping"
    detailsPrompt.HoldDuration = 0
    detailsPrompt.MaxActivationDistance = 12
    detailsPrompt.RequiresLineOfSight = false
    detailsPrompt.Parent = board
    
    plot.SignPost = signPost
    plot.SignBoard = board
    plot.SignBillboard = billboard
    plot.DetailsPrompt = detailsPrompt
    return board
end

local function positionOwnerSign(plot)
    if not plot.SignPost then
        return
    end
    local cframe = plot.FootprintCFrame or (plot.BasePart and plot.BasePart.CFrame) or CFrame.new(plot.Center or Vector3.new())
    local sizeZ = (plot.Size and plot.Size.Y) or (plot.BasePart and plot.BasePart.Size.Z) or 0
    local signage = CampConfig.Signage or {}
    local offset = signage.OwnerOffset or 6
    local forward = cframe.LookVector
    local center = cframe.Position
    local halfDepth = sizeZ / 2
    local distance = halfDepth + offset
    local baseHeight = getPlotSurfaceY(plot)
    local postHeight = signage.PostHeight or (signage.PostSize and signage.PostSize.Y) or 6
    local postThickness = (signage.PostSize and signage.PostSize.Z) or 1.5

    local postPosition = Vector3.new(center.X, baseHeight + postHeight / 2, center.Z) + forward * distance
    plot.SignPost.CFrame = CFrame.lookAt(postPosition, postPosition + forward)
    plot.SignBoard.CFrame = plot.SignPost.CFrame * CFrame.new(0, postHeight * 0.35, -postThickness / 2 - 0.3)
end

local function updateSignDisplay(plot)
    if plot.OwnerUserId then
        ensureOwnerSign(plot)
        positionOwnerSign(plot)
        if plot.Prompt then
            plot.Prompt.Enabled = false
        end
        -- Activer le prompt des détails seulement si la parcelle est occupée
        if plot.DetailsPrompt then
            plot.DetailsPrompt.Enabled = true
            plot.DetailsPrompt:SetAttribute("PlotId", plot.Id)
            plot.DetailsPrompt:SetAttribute("OwnerUserId", plot.OwnerUserId)
        end
        local statusLabel = plot.SignBillboard and plot.SignBillboard:FindFirstChild("StatusLabel")
        if statusLabel then
            local player = Players:GetPlayerByUserId(plot.OwnerUserId)
            local ownerName = player and player.Name or "?"
            statusLabel.Text = string.format("Camping de %s", ownerName)
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
        end
    else
        if plot.Prompt then
            plot.Prompt.Enabled = true
        end
        -- Désactiver le prompt des détails si la parcelle est vide
        if plot.DetailsPrompt then
            plot.DetailsPrompt.Enabled = false
        end
        destroyOwnerSign(plot)
    end
end

local function isPositionInsidePlot(plot, position)
    if not (plot and plot.FootprintCFrame and plot.Size) then
        return false
    end
    local localPos = plot.FootprintCFrame:PointToObjectSpace(position)
    local halfWidth = plot.Size.X / 2
    local halfDepth = plot.Size.Y / 2
    return math.abs(localPos.X) <= halfWidth and math.abs(localPos.Z) <= halfDepth
end

local function attemptClaim(player, plotId)
    local plot = plotsById[plotId]
    if not plot then
        return false, "Parcelle inconnue"
    end
    if plot.OwnerUserId and plot.OwnerUserId ~= player.UserId then
        return false, "Parcelle déjà occupée"
    end

    -- Libère l'ancienne parcelle du joueur
    local previousPlot = playerToPlot[player]
    if previousPlot and previousPlot ~= plot then
        previousPlot.OwnerUserId = nil
        clearPlot(previousPlot)
        updateSignDisplay(previousPlot)
    end

    plot.OwnerUserId = player.UserId
    playerToPlot[player] = plot

    local dataService = getDataService()
    local playerData
    if dataService and dataService.LoadPlayerData then
        playerData = dataService.LoadPlayerData(player.UserId)
    end
    if not playerData and dataService and dataService.GetDefaultData then
        playerData = dataService.GetDefaultData()
    end
    playerData = playerData or {
        Objects = {},
        TrailerParts = {},
    }
    playerData.Objects = playerData.Objects or {}
    playerData.TrailerParts = playerData.TrailerParts or {}

    plot.PlayerData = playerData
    plot.PlacedObjects = playerData.Objects
    plot.TrailerParts = playerData.TrailerParts
    plot.TrailerCells = nil
    plot.TrailerFolder = nil
    plot.TrailerModels = nil

    local placementService = getPlacementService()
    if placementService and placementService.OnPlotClaimed then
        placementService.OnPlotClaimed(player, plot, playerData)
    elseif plot.Container then
        plot.Container:ClearAllChildren()
    end

    local trailerService = getTrailerService()
    local trailerHandled = false
    if trailerService and trailerService.OnPlotClaimed then
        trailerService.OnPlotClaimed(player, plot, playerData)
        trailerHandled = true
    end

    -- ✅ NOUVEAU : Générer le kit de camping par défaut
    local CampsiteDefaultsService = getCampsiteDefaultsService()
    local campsiteGenerated = false
    if CampsiteDefaultsService and CampsiteDefaultsService.SpawnDefaultCampsiteForPlot then
        -- Passer plot.Container (Folder) qui contient les objets, pas BasePart
        campsiteGenerated = CampsiteDefaultsService.SpawnDefaultCampsiteForPlot(plot.Container, player)
    end
    if campsiteGenerated then
        print("[PlotService] Kit de camping généré pour", player.Name, "sur parcelle", plot.Id)
    end

    updateSignDisplay(plot)

    BuildRemotes.PlotAssigned:FireClient(player, {
        PlotId = plot.Id,
        Center = plot.Center,
        Size = plot.Size,
        BaseHeight = getPlotSurfaceY(plot),
    })
    BuildRemotes.PlacedObjectsUpdated:FireClient(player, plot.PlacedObjects)
    if not trailerHandled then
        BuildRemotes.TrailerStateUpdated:FireClient(player, plot.TrailerParts)
    end

    return true, "Parcelle attribuée"
end

local function createPlotFromDefinition(definition)
    local defaults = CampConfig.PlotDefaults or {}
    local plotId = definition.Id
    local basePart = definition.BasePart
    if not (plotId and basePart) then
        warn("[Paradis] Définition de parcelle invalide", definition)
        return
    end

    basePart.Name = "Plot_" .. plotId

    local border = Instance.new("SelectionBox")
    border.Color3 = defaults.SelectionColor or Color3.fromRGB(245, 203, 66)
    border.LineThickness = 0.02
    border.Adornee = basePart
    border.Parent = basePart

    local container = Instance.new("Folder")
    container.Name = "PlotContainer_" .. plotId
    container.Parent = basePart

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Réserver"
    prompt.ObjectText = "Parcelle"
    prompt.HoldDuration = 0.25
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
    prompt.RequiresLineOfSight = false
    prompt.Parent = basePart

    local plotData = {
        Id = plotId,
        Center = definition.Center,
        Size = definition.Size,
        FootprintCFrame = definition.FootprintCFrame,
        BasePart = basePart,
        BaseHeight = definition.BaseHeight or (basePart.Position.Y + basePart.Size.Y / 2),
        Container = container,
        OwnerUserId = nil,
        SignBoard = nil,
        SignBillboard = nil,
        Prompt = prompt,
        PlacedObjects = {},
        PlayerData = nil,
        TrailerParts = {},
        TrailerFolder = nil,
        TrailerCells = nil,
        TrailerModels = nil,
    }

    prompt.Triggered:Connect(function(player)
        attemptClaim(player, plotId)
    end)

    plotsById[plotId] = plotData
    updateSignDisplay(plotData)
end

BuildRemotes.RequestClaim.OnServerInvoke = function(player, plotId)
    return attemptClaim(player, plotId)
end

Players.PlayerRemoving:Connect(function(player)
    local plot = playerToPlot[player]
    if plot and plot.OwnerUserId == player.UserId then
        plot.OwnerUserId = nil
        clearPlot(plot)
        updateSignDisplay(plot)
    end
    playerToPlot[player] = nil
end)

local function init()
    print("[PlotService] 🚀 Initialisation du service des parcelles...")
    
    local generated = WorldGenerator.GetGeneratedPlots()
    if #generated == 0 then
        warn("[PlotService] ❌ Aucun plot généré. Vérifier CampConfig.PlotBands.")
        return
    end

    print("[PlotService] 📦 Génération de", #generated, "parcelles...")
    
    for _, plotDefinition in ipairs(generated) do
        createPlotFromDefinition(plotDefinition)
    end
    
    print("[PlotService] ✅", #generated, "parcelles créées avec succès!")
    
    -- Afficher les parcelles pour debug
    for id, plot in pairs(plotsById) do
        print(string.format("[PlotService] 📍 Plot %s - Position: %s", id, tostring(plot.Center)))
    end
end

init()

shared.ParadisPlotService = {
    GetPlotForPlayer = function(player)
        return playerToPlot[player]
    end,
    GetPlotById = function(plotId)
        return plotsById[plotId]
    end,
    GetAllPlots = function()
        local plots = {}
        for _, plot in pairs(plotsById) do
            table.insert(plots, plot)
        end
        return plots
    end,
    ClaimPlot = attemptClaim,
    IsPositionInsidePlot = isPositionInsidePlot,
}

print("[PlotService] 🎯 Service exposé dans shared.ParadisPlotService")

-- ✅ Attribuer automatiquement une parcelle libre au joueur à l'entrée du jeu
Players.PlayerAdded:Connect(function(player)
    -- Attendre que le personnage soit chargé et que les services soient prêts
    task.wait(3) -- Augmenté à 3 secondes pour laisser plus de temps
    
    -- Vérifier que le joueur n'a pas déjà une parcelle
    if playerToPlot[player] then
        print("[PlotService] ✅", player.Name, "a déjà une parcelle")
        return
    end
    
    -- Compter les parcelles disponibles
    local availablePlots = 0
    for _, plot in pairs(plotsById) do
        if not plot.OwnerUserId then
            availablePlots = availablePlots + 1
        end
    end
    
    local totalPlots = 0
    for _ in pairs(plotsById) do totalPlots += 1 end
    print("[PlotService] 📊 Parcelles disponibles:", availablePlots, "sur", totalPlots)
    
    -- Trouver et attribuer une parcelle libre
    for _, plot in pairs(plotsById) do
        if not plot.OwnerUserId then
            local success, message = attemptClaim(player, plot.Id)
            if success then
                print("[PlotService] ✅ Parcelle auto-attribuée à", player.Name, "- Plot", plot.Id)
            else
                warn("[PlotService] ❌ Échec auto-attribution pour", player.Name, ":", message)
            end
            break
        end
    end
end)

-- ✅ Pour les joueurs déjà dans le jeu au démarrage du serveur
task.spawn(function()
    task.wait(5) -- Attendre que tout soit initialisé
    
    for _, player in ipairs(Players:GetPlayers()) do
        if not playerToPlot[player] then
            print("[PlotService] 🔄 Attribution différée pour", player.Name)
            
            for _, plot in pairs(plotsById) do
                if not plot.OwnerUserId then
                    local success, message = attemptClaim(player, plot.Id)
                    if success then
                        print("[PlotService] ✅ Parcelle différée attribuée à", player.Name, "- Plot", plot.Id)
                    else
                        warn("[PlotService] ❌ Échec attribution différée pour", player.Name, ":", message)
                    end
                    break
                end
            end
        end
    end
end)
