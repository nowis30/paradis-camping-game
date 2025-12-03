--[[
    TrailerBuildService
    Gère le mode de construction de roulotte modulaire (solage, murs, toit).
    Dispose d'une grille par parcelle et applique les règles d'empilement/rotation.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local CampConfig = require(configFolder:WaitForChild("CampConfig"))
local TrailerPartsConfig = require(configFolder:WaitForChild("TrailerPartsConfig"))
local BuildRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuildRemotes"))

local CELL_SIZE = CampConfig.TRAILER_CELL_SIZE or 4
local CATEGORY_LEVEL = CampConfig.TRAILER_CATEGORY_LEVEL or { Foundation = 0, Wall = 1, Roof = 2 }
local LEVEL_BASE = CampConfig.TRAILER_LEVEL_BASE or { [0] = 0 }

local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local PlotApi = waitForShared("ParadisPlotService")
local DataApi = waitForShared("ParadisDataService")

local TrailerService = {}

local function clampRotation(value)
    local snapped = math.floor((tonumber(value) or 0) / 90 + 0.5) * 90
    snapped %= 360
    if snapped < 0 then
        snapped += 360
    end
    return snapped
end

local function getGridOrigin(plot)
    return Vector3.new(
        plot.Center.X - (plot.Size.X / 2),
        plot.Center.Y,
        plot.Center.Z - (plot.Size.Y / 2)
    )
end

local function getGridLimits(plot)
    local cellsX = math.floor(plot.Size.X / CELL_SIZE)
    local cellsZ = math.floor(plot.Size.Y / CELL_SIZE)
    return cellsX, cellsZ
end

local function getCellKey(x, z)
    return string.format("%d:%d", x, z)
end

local function getFootprint(def, rotation)
    local gridSize = def.GridSize or Vector2.new(1, 1)
    local sizeX = math.max(1, math.floor(gridSize.X + 0.0001))
    local sizeZ = math.max(1, math.floor(gridSize.Y + 0.0001))
    if rotation % 180 ~= 0 then
        sizeX, sizeZ = sizeZ, sizeX
    end
    return sizeX, sizeZ
end

local function computeWorldTransform(plot, originX, originZ, def, rotation)
    local sizeX, sizeZ = getFootprint(def, rotation)
    local origin = getGridOrigin(plot)
    local width = sizeX * CELL_SIZE
    local depth = sizeZ * CELL_SIZE
    local centerX = origin.X + (originX * CELL_SIZE) + (width / 2)
    local centerZ = origin.Z + (originZ * CELL_SIZE) + (depth / 2)
    local level = CATEGORY_LEVEL[def.Category] or 0
    local baseHeight = (LEVEL_BASE and LEVEL_BASE[level]) or 0
    local centerY = plot.Center.Y + baseHeight + (def.Height / 2)
    local cframe = CFrame.new(centerX, centerY, centerZ) * CFrame.Angles(0, math.rad(rotation), 0)
    local worldSize = Vector3.new(width, def.Height, depth)
    return cframe, worldSize, sizeX, sizeZ, level
end

local function ensureTrailerFolder(plot)
    if not plot.Container then
        return nil
    end
    if plot.TrailerFolder and plot.TrailerFolder.Parent == plot.Container then
        return plot.TrailerFolder
    end
    local folder = Instance.new("Folder")
    folder.Name = "TrailerParts"
    folder.Parent = plot.Container
    plot.TrailerFolder = folder
    return folder
end

local function ensurePlotState(plot)
    plot.PlayerData = plot.PlayerData or {}
    plot.PlayerData.TrailerParts = plot.PlayerData.TrailerParts or plot.TrailerParts or {}
    plot.TrailerParts = plot.PlayerData.TrailerParts
    plot.TrailerCells = plot.TrailerCells or {}
    plot.TrailerModels = plot.TrailerModels or {}
    ensureTrailerFolder(plot)
end

local function resetOccupancy(plot)
    plot.TrailerCells = {}
end

local function addOccupancy(plot, record)
    plot.TrailerCells = plot.TrailerCells or {}
    local levelCells = plot.TrailerCells[record.Level]
    if not levelCells then
        levelCells = {}
        plot.TrailerCells[record.Level] = levelCells
    end
    for x = 0, record.SizeX - 1 do
        for z = 0, record.SizeZ - 1 do
            local key = getCellKey(record.OriginX + x, record.OriginZ + z)
            levelCells[key] = record
        end
    end
end

local function removeOccupancy(plot, record)
    if not plot.TrailerCells or not plot.TrailerCells[record.Level] then
        return
    end
    local levelCells = plot.TrailerCells[record.Level]
    for x = 0, record.SizeX - 1 do
        for z = 0, record.SizeZ - 1 do
            local key = getCellKey(record.OriginX + x, record.OriginZ + z)
            if levelCells[key] == record then
                levelCells[key] = nil
            end
        end
    end
end

local function rebuildOccupancy(plot)
    resetOccupancy(plot)
    for _, record in ipairs(plot.TrailerParts) do
        local def = TrailerPartsConfig[record.PartId]
        if def then
            local rotation = clampRotation(record.Rotation or 0)
            local sizeX, sizeZ = getFootprint(def, rotation)
            record.Rotation = rotation
            record.SizeX = sizeX
            record.SizeZ = sizeZ
            record.Level = CATEGORY_LEVEL[def.Category] or 0
            record.Category = def.Category
            addOccupancy(plot, record)
        end
    end
end

local function finalizeModel(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = true
            descendant.TopSurface = Enum.SurfaceType.Smooth
            descendant.BottomSurface = Enum.SurfaceType.Smooth
        end
    end
end

local builders = {}

local function createBaseModel(def, size, thicknessScale)
    local model = Instance.new("Model")
    model.Name = def.DisplayName or def.Id
    local primary = Instance.new("Part")
    primary.Name = "Segment"
    local thickness = thicknessScale and math.max(0.5, size.Z * thicknessScale) or size.Z
    primary.Size = Vector3.new(size.X, size.Y, thickness)
    primary.Material = def.Material or Enum.Material.Metal
    primary.Color = def.Color or Color3.fromRGB(255, 255, 255)
    primary.Parent = model
    model.PrimaryPart = primary
    finalizeModel(model)
    return model, primary
end

builders.FoundationFloor = function(def, size)
    local model = Instance.new("Model")
    model.Name = def.DisplayName or def.Id
    local base = Instance.new("Part")
    base.Name = "Foundation"
    base.Size = size
    base.Material = def.Material or Enum.Material.Concrete
    base.Color = def.Color or Color3.fromRGB(200, 200, 200)
    base.Parent = model
    model.PrimaryPart = base
    finalizeModel(model)
    return model
end

builders.WallSimple = function(def, size)
    local model, primary = createBaseModel(def, size, 0.35)
    primary.Color = def.Color or Color3.fromRGB(235, 212, 170)
    return model
end

builders.WallWindow = function(def, size)
    local model, primary = createBaseModel(def, size, 0.35)
    primary.Color = def.Color or Color3.fromRGB(220, 220, 235)
    local window = Instance.new("Part")
    window.Name = "Window"
    window.Size = Vector3.new(math.max(2, size.X - 2), math.max(2, size.Y - 2), math.max(0.5, primary.Size.Z * 0.6))
    window.Material = Enum.Material.Glass
    window.Color = def.SecondaryColor or Color3.fromRGB(150, 200, 255)
    window.Transparency = 0.4
    window.Parent = model
    model.PrimaryPart = primary
    finalizeModel(model)
    return model
end

builders.WallDoor = function(def, size)
    local model, primary = createBaseModel(def, size, 0.35)
    primary.Color = def.Color or Color3.fromRGB(240, 220, 180)
    local door = Instance.new("Part")
    door.Name = "Door"
    door.Size = Vector3.new(math.max(2, size.X * 0.35), math.max(3, size.Y - 2), math.max(0.5, primary.Size.Z * 0.9))
    door.Color = def.SecondaryColor or Color3.fromRGB(120, 120, 120)
    door.Material = Enum.Material.Wood
    door.Parent = model
    model.PrimaryPart = primary
    finalizeModel(model)
    return model
end

builders.RoofSimple = function(def, size)
    local model = Instance.new("Model")
    model.Name = def.DisplayName or def.Id
    local wedge = Instance.new("WedgePart")
    wedge.Name = "Roof"
    wedge.Size = size
    wedge.Material = def.Material or Enum.Material.Metal
    wedge.Color = def.Color or Color3.fromRGB(210, 90, 70)
    wedge.Parent = model
    model.PrimaryPart = wedge
    finalizeModel(model)
    return model
end

local function spawnRecordModel(plot, record)
    local def = TrailerPartsConfig[record.PartId]
    if not def then
        return
    end
    local folder = ensureTrailerFolder(plot)
    if not folder then
        return
    end
    local rotation = clampRotation(record.Rotation or 0)
    local cframe, worldSize = computeWorldTransform(plot, record.OriginX, record.OriginZ, def, rotation)
    local builder = builders[def.ModelType]
    if not builder then
        warn("[Paradis] Aucun builder pour", def.ModelType)
        return
    end
    local model = builder(def, worldSize)
    if not model.PrimaryPart then
        return
    end
    model.Parent = folder
    model:PivotTo(cframe)
    model:SetAttribute("TrailerPartId", record.Id)
    for _, descendant in ipairs(model:GetDescendants()) do
        descendant:SetAttribute("TrailerPartId", record.Id)
    end
    plot.TrailerModels[record.Id] = model
end

local function destroyRecordModel(plot, recordId)
    if not plot.TrailerModels then
        return
    end
    local model = plot.TrailerModels[recordId]
    if model then
        model:Destroy()
        plot.TrailerModels[recordId] = nil
    end
end

local function broadcastState(player, plot)
    BuildRemotes.TrailerStateUpdated:FireClient(player, plot.TrailerParts)
end

local function savePlot(plot)
    if not plot.OwnerUserId then
        return
    end
    if DataApi and DataApi.SavePlayerData then
        plot.PlayerData.Objects = plot.PlacedObjects
        plot.PlayerData.TrailerParts = plot.TrailerParts
        DataApi.SavePlayerData(plot.OwnerUserId, plot.PlayerData)
    end
end

local function findRecord(plot, recordId)
    if not plot.TrailerParts then
        return nil
    end
    for index, record in ipairs(plot.TrailerParts) do
        if record.Id == recordId then
            return record, index
        end
    end
    return nil
end

local function validateOverlap(plot, level, originX, originZ, sizeX, sizeZ)
    if not plot.TrailerCells or not plot.TrailerCells[level] then
        return true
    end
    local levelCells = plot.TrailerCells[level]
    for x = 0, sizeX - 1 do
        for z = 0, sizeZ - 1 do
            local key = getCellKey(originX + x, originZ + z)
            if levelCells[key] then
                return false
            end
        end
    end
    return true
end

local function validateSupport(plot, def, level, originX, originZ, sizeX, sizeZ)
    if level == 0 then
        return true
    end
    if not def.CanStackOn or #def.CanStackOn == 0 then
        return false
    end
    local allowed = {}
    for _, category in ipairs(def.CanStackOn) do
        allowed[category] = true
    end
    local below = plot.TrailerCells and plot.TrailerCells[level - 1]
    if not below then
        return false
    end
    for x = 0, sizeX - 1 do
        for z = 0, sizeZ - 1 do
            local key = getCellKey(originX + x, originZ + z)
            local supportRecord = below[key]
            if not supportRecord or not allowed[supportRecord.Category] then
                return false
            end
        end
    end
    return true
end

local function hasDependentsAbove(plot, record)
    if not plot.TrailerCells then
        return false
    end
    local aboveLevel = plot.TrailerCells[record.Level + 1]
    if not aboveLevel then
        return false
    end
    for x = 0, record.SizeX - 1 do
        for z = 0, record.SizeZ - 1 do
            local key = getCellKey(record.OriginX + x, record.OriginZ + z)
            if aboveLevel[key] then
                return true
            end
        end
    end
    return false
end

local function handleTrailerPlacement(player, payload)
    local plot = PlotApi.GetPlotForPlayer(player)
    if not plot then
        return false, "Aucune parcelle"
    end
    ensurePlotState(plot)

    if type(payload) ~= "table" then
        return false, "Requête invalide"
    end

    local partId = payload.PartId
    local def = TrailerPartsConfig[partId]
    if not def then
        return false, "Pièce inconnue"
    end

    local gridPosition = payload.GridPosition
    if type(gridPosition) ~= "table" then
        return false, "Position invalide"
    end
    local originX = math.floor(tonumber(gridPosition.x) or math.huge)
    local originZ = math.floor(tonumber(gridPosition.z) or math.huge)
    if originX == math.huge or originZ == math.huge then
        return false, "Coordonnées invalides"
    end

    local rotation = clampRotation(payload.Rotation or 0)
    local _, _, sizeX, sizeZ, level = computeWorldTransform(plot, originX, originZ, def, rotation)
    local maxX, maxZ = getGridLimits(plot)
    if originX < 0 or originZ < 0 or originX + sizeX > maxX or originZ + sizeZ > maxZ then
        return false, "En dehors de la parcelle"
    end

    if not validateOverlap(plot, level, originX, originZ, sizeX, sizeZ) then
        return false, "Une pièce occupe déjà cet emplacement"
    end
    if not validateSupport(plot, def, level, originX, originZ, sizeX, sizeZ) then
        return false, "Structure insuffisante pour empiler"
    end

    local record = {
        Id = HttpService:GenerateGUID(false),
        PartId = def.Id,
        OriginX = originX,
        OriginZ = originZ,
        Rotation = rotation,
        Level = level,
        SizeX = sizeX,
        SizeZ = sizeZ,
        Category = def.Category,
    }

    table.insert(plot.TrailerParts, record)
    addOccupancy(plot, record)
    spawnRecordModel(plot, record)

    savePlot(plot)
    broadcastState(player, plot)
    return true
end

local function handleTrailerRemoval(player, recordId)
    local plot = PlotApi.GetPlotForPlayer(player)
    if not plot then
        return false, "Aucune parcelle"
    end
    ensurePlotState(plot)

    if type(recordId) ~= "string" or recordId == "" then
        return false, "Id invalide"
    end

    local record, index = findRecord(plot, recordId)
    if not record then
        return false, "Pièce introuvable"
    end

    if hasDependentsAbove(plot, record) then
        return false, "Retirez d'abord les éléments supérieurs"
    end

    removeOccupancy(plot, record)
    destroyRecordModel(plot, record.Id)
    table.remove(plot.TrailerParts, index)

    savePlot(plot)
    broadcastState(player, plot)
    return true
end

function TrailerService.OnPlotClaimed(player, plot, playerData)
    ensurePlotState(plot)
    local folder = ensureTrailerFolder(plot)
    if folder then
        folder:ClearAllChildren()
    end
    plot.TrailerModels = {}
    rebuildOccupancy(plot)
    for _, record in ipairs(plot.TrailerParts) do
        spawnRecordModel(plot, record)
    end
    broadcastState(player, plot)
end

BuildRemotes.TrailerRequestPlacement.OnServerInvoke = function(player, payload)
    return handleTrailerPlacement(player, payload or {})
end

BuildRemotes.TrailerRequestRemove.OnServerInvoke = function(player, recordId)
    return handleTrailerRemoval(player, recordId)
end

shared.ParadisTrailerService = TrailerService
