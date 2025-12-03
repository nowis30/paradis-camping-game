local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")
local CampLayoutConfig = require(ConfigFolder:WaitForChild("CampLayoutConfig"))
local MiniGamesConfig = require(ConfigFolder:WaitForChild("MiniGamesConfig"))

local CampingWorldGenerator = {}

local worldFolders = {}
local roadsByName = {}
local generatedPlots = {}
local hasGenerated = false
local transform = CampLayoutConfig.Transform or {}
local offset = transform.Offset

local function applyPosition(vec)
    if not vec then
        return vec
    end
    local x, y, z = vec.X, vec.Y, vec.Z
    if transform.MirrorX then
        x = -x
    end
    if offset then
        x += offset.X or 0
        y += offset.Y or 0
        z += offset.Z or 0
    end
    return Vector3.new(x, y, z)
end

local function getOrCreateWorkspaceFolder(name)
    if worldFolders[name] then
        return worldFolders[name]
    end
    local folder = Workspace:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = Workspace
    end
    folder:ClearAllChildren()
    worldFolders[name] = folder
    return folder
end

local function createGround()
    local cfg = CampLayoutConfig.Ground
    if not cfg then
        return
    end
    local folder = getOrCreateWorkspaceFolder("CampingTerrain")
    local part = Instance.new("Part")
    part.Name = "Ground"
    part.Anchored = true
    part.Size = cfg.Size or Vector3.new(400, 1, 400)
    part.Position = applyPosition(cfg.Position or Vector3.new())
    part.Material = cfg.Material or Enum.Material.Grass
    part.Color = cfg.Color or Color3.fromRGB(90, 170, 90)
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = folder
    print("[Paradis][CampingWorldGenerator] Sol posé.")
end

local function createSurroundingWater()
    local cfg = CampLayoutConfig.SurroundingWater
    if not cfg then
        return
    end
    local folder = getOrCreateWorkspaceFolder("CampingTerrain")
    local part = Instance.new("Part")
    part.Name = "IslandWater"
    part.Anchored = true
    part.Size = cfg.Size or Vector3.new(1200, 2, 900)
    part.Position = applyPosition(cfg.Position or Vector3.new())
    part.Material = cfg.Material or Enum.Material.Water
    part.Color = cfg.Color or Color3.fromRGB(40, 130, 170)
    part.Transparency = cfg.Transparency or 0.2
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = folder
    print("[Paradis][CampingWorldGenerator] Eaux périphériques posées.")
end

local function createLake()
    local cfg = CampLayoutConfig.Lake
    if not cfg then
        return
    end
    local folder = getOrCreateWorkspaceFolder("CampingTerrain")
    local part = Instance.new("Part")
    part.Name = "Lake"
    part.Anchored = true
    part.Size = cfg.Size or Vector3.new(200, 2, 100)
    part.Position = applyPosition(cfg.Position or Vector3.new(0, 0.5, 0))
    part.Material = cfg.Material or Enum.Material.Water
    part.Color = cfg.Color or Color3.fromRGB(20, 120, 150)
    part.Transparency = cfg.Transparency or 0.1
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = folder
    print("[Paradis][CampingWorldGenerator] Lac créé.")
end

local function createFishingSpots()
    local fishingCfg = MiniGamesConfig and MiniGamesConfig.FishingGame
    if not fishingCfg then
        return
    end

    local fishingFolder = getOrCreateWorkspaceFolder("FishingArea")
    for _, spotCfg in ipairs(fishingCfg.Spots or {}) do
        local spot = Instance.new("Part")
        spot.Name = spotCfg.Name or "FishingSpot"
        spot.Anchored = true
        spot.Size = Vector3.new(4, 1, 4)
        spot.Position = applyPosition(spotCfg.Position)
        spot.Material = Enum.Material.WoodPlanks
        spot.Color = Color3.fromRGB(180, 140, 90)
        spot.Parent = fishingFolder

        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "FishPrompt"
        prompt.ObjectText = "Jeu de pêche"
        prompt.ActionText = "Pêcher"
        prompt.MaxActivationDistance = 10
        prompt.Parent = spot
    end

    print(string.format("[Paradis][World] Spots de pêche générés : %d", #fishingCfg.Spots))
end

local function buildRoadSegments(roadCfg)
        local rawPoints = roadCfg.Points or {}
        local points = table.create(#rawPoints)
        for i, point in ipairs(rawPoints) do
		points[i] = applyPosition(point)
        end
    local totalLength = 0
    local segments = {}
    local roadsFolder = getOrCreateWorkspaceFolder("Roads")
    for i = 1, #points - 1 do
        local a = points[i]
        local b = points[i + 1]
        local delta = b - a
        local length = delta.Magnitude
        if length > 1 then
            local forward = delta.Unit
            local right = Vector3.new(forward.Z, 0, -forward.X)
            if right.Magnitude < 1e-3 then
                right = Vector3.new(-forward.Y, forward.X, 0)
            end
            right = right.Unit

            local segmentPart = Instance.new("Part")
            segmentPart.Name = string.format("%s_%02d", roadCfg.Name or "Road", i)
            segmentPart.Anchored = true
            segmentPart.Material = Enum.Material.Asphalt
            segmentPart.Color = Color3.fromRGB(35, 35, 35)
            segmentPart.Size = Vector3.new(roadCfg.Width or 8, 1, length)
            segmentPart.CFrame = CFrame.lookAt(a + delta / 2, a + delta / 2 + forward)
            segmentPart.Parent = roadsFolder

            table.insert(segments, {
                StartPoint = a,
                Length = length,
                Direction = forward,
                Right = right,
                Accumulated = totalLength,
                EndPoint = b,
            })
            totalLength += length
        end
    end

    roadsByName[roadCfg.Name] = {
        Name = roadCfg.Name,
        Width = roadCfg.Width or 8,
        Segments = segments,
        TotalLength = totalLength,
        PointCount = #points,
    }
end

local function createRoads()
    roadsByName = {}
    local polylines = CampLayoutConfig.RoadPolylines or {}
    for _, roadCfg in ipairs(polylines) do
        buildRoadSegments(roadCfg)
    end
    print(string.format("[Paradis][CampingWorldGenerator] %d routes générées.", #polylines))
end

local function getDistanceForPointIndex(road, index)
    if not road or not road.PointCount then
        return 0
    end
    local clamped = math.clamp(index, 1, road.PointCount)
    local dist = 0
    for segIndex = 1, math.max(0, clamped - 1) do
        local seg = road.Segments[segIndex]
        if not seg then
            break
        end
        dist += seg.Length
    end
    return dist
end

local function getPointAlong(road, distance)
    if not road then
        return Vector3.new(), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)
    end
    local target = math.clamp(distance, 0, road.TotalLength)
    for _, segment in ipairs(road.Segments) do
        if target <= segment.Length then
            local point = segment.StartPoint + segment.Direction * target
            return point, segment.Direction, segment.Right
        else
            target -= segment.Length
        end
    end
    local lastSegment = road.Segments[#road.Segments]
    if lastSegment then
        return lastSegment.EndPoint, lastSegment.Direction, lastSegment.Right
    end
    return Vector3.new(), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)
end

local function resolveIndex(pointCount, indexValue, default)
    if not indexValue then
        return default
    end
    local result = indexValue
    if indexValue < 0 then
        result = pointCount + indexValue
    end
    return math.clamp(result, 1, pointCount)
end

local function getSideMultipliers(side)
    if side == "Both" then
        return { -1, 1 }
    elseif side == "Left" or side == "Lake" then
        return { -1 }
    elseif side == "Right" or side == "Inside" then
        return { 1 }
    else
        return { 1 }
    end
end

local function createPlotPart(plotFolder, center, forward, right, band, plotIndex, sideTag)
    local appearance = CampLayoutConfig.PlotAppearance or {}
    local size = band.PlotSize or Vector2.new(12, 8)
    local thickness = appearance.Thickness or 0.6
    local base = Instance.new("Part")
    base.Anchored = true
    base.Name = string.format("Plot_%s_%s_%02d", band.RoadName, sideTag or "Side", plotIndex)
    base.Size = Vector3.new(size.X, thickness, size.Y)
    base.Material = appearance.Material or Enum.Material.Grass
    base.Color = appearance.Color or Color3.fromRGB(92, 180, 115)
    base.CFrame = CFrame.fromMatrix(center + Vector3.new(0, thickness / 2, 0), forward.Unit, Vector3.new(0, 1, 0), -right.Unit)
    base.Parent = plotFolder

    local border = Instance.new("SelectionBox")
    border.Name = "PlotBorder"
    border.LineThickness = 0.03
    border.Color3 = appearance.BorderColor or Color3.fromRGB(240, 210, 120)
    border.Adornee = base
    border.Parent = base

    -- Pancartes désactivées (signPost et signBoard commentés)
    --[[
    local signPost = Instance.new("Part")
    signPost.Name = base.Name .. "_Post"
    signPost.Anchored = true
    signPost.Size = Vector3.new(0.8, 6, 0.8)
    signPost.Material = Enum.Material.WoodPlanks
    signPost.Color = appearance.SignPostColor or Color3.fromRGB(170, 120, 70)
    local outward = right.Unit
    signPost.CFrame = CFrame.new(center - outward * (size.Y / 2 + 2) + Vector3.new(0, 3, 0))
    signPost.Parent = plotFolder

    local signBoard = Instance.new("Part")
    signBoard.Name = base.Name .. "_Sign"
    signBoard.Anchored = true
    signBoard.Size = Vector3.new(4.5, 2.4, 0.4)
    signBoard.Material = Enum.Material.Wood
    signBoard.Color = appearance.SignBoardColor or Color3.fromRGB(120, 80, 40)
    signBoard.CFrame = signPost.CFrame * CFrame.new(0, 1, -1.2)
    signBoard.Parent = plotFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlotBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = signBoard

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = "Parcelle libre"
    label.TextColor3 = Color3.fromRGB(220, 255, 200)
    label.Parent = billboard
    ]]

    return base, size
end

local function createPlots()
    table.clear(generatedPlots)
    local plotsFolder = getOrCreateWorkspaceFolder("CampingPlots")
    local total = 0

    for _, band in ipairs(CampLayoutConfig.PlotBands or {}) do
        local road = roadsByName[band.RoadName]
        if road and road.TotalLength > 0 then
            local startIndex = resolveIndex(road.PointCount, band.StartIndex or 1, 1)
            local endIndex = resolveIndex(road.PointCount, band.EndIndex or road.PointCount, road.PointCount)
            local startDistance = getDistanceForPointIndex(road, startIndex) + (band.StartOffset or 0)
            local endDistance = getDistanceForPointIndex(road, endIndex)
            endDistance = math.max(endDistance - (band.EndOffset or 0), startDistance + 10)

            local usableLength = math.max(0, endDistance - startDistance)
            local iterationCount = math.max(0, band.PairCount or band.PlotCount or 0)
            if iterationCount > 0 and usableLength > 5 then
                local spacing = band.SpacingAlongRoad or ((band.PlotSize and band.PlotSize.X) or 12) + 4
                spacing = math.max(10, math.min(spacing, usableLength / iterationCount))
                local offset = startDistance + spacing * 0.5
                local sides = getSideMultipliers(band.Side)
                local depth = (band.PlotSize and band.PlotSize.Y) or 8

                for i = 1, iterationCount do
                    local distance = offset + (i - 1) * spacing
                    if distance > endDistance then
                        break
                    end
                    for _, sideMultiplier in ipairs(sides) do
                        local point, forward, right = getPointAlong(road, distance)
                        local outward = right.Unit * sideMultiplier
                        local center = point + outward * ((band.OffsetFromRoad or 8) + depth / 2)
                        local base, footprintSize = createPlotPart(plotsFolder, center, forward, outward, band, i, sideMultiplier > 0 and "Right" or "Left")
                        table.insert(generatedPlots, {
                            Id = base.Name,
                            Center = center,
                            Forward = forward,
                            Right = outward,
                            BasePart = base,
                            FootprintCFrame = base.CFrame,
                            Size = Vector2.new(footprintSize.X, footprintSize.Y),
                            Band = band.RoadName,
                        })
                        total += 1
                    end
                end
            end
        else
            warn(string.format("[Paradis][CampingWorldGenerator] Route '%s' introuvable pour bande de parcelles.", tostring(band.RoadName)))
        end
    end

    print(string.format("[Paradis][CampingWorldGenerator] %d parcelles créées.", total))
end

local function createSpawn()
    local cfg = CampLayoutConfig.Spawn or {}
    local folder = getOrCreateWorkspaceFolder("CampingTerrain")
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "CampingSpawn"
    spawn.Anchored = true
    spawn.Size = cfg.Size or Vector3.new(8, 1, 8)
    spawn.Position = applyPosition(cfg.Position or Vector3.new(0, 3, 0))
    spawn.Orientation = cfg.Orientation or Vector3.new()
    spawn.Transparency = 0.2
    spawn.Neutral = true
    spawn.Parent = folder
end

function CampingWorldGenerator.GetGeneratedPlots()
    if not hasGenerated then
        CampingWorldGenerator.Generate()
    end
    return generatedPlots
end

function CampingWorldGenerator.Generate()
    if hasGenerated then
        return generatedPlots
    end

    print("[Paradis][CampingWorldGenerator] Génération du camping Soleil Levant...")
    local baseplate = Workspace:FindFirstChild("Baseplate")
    if baseplate then
        baseplate:Destroy()
    end
    createSurroundingWater()
    createGround()
    createLake()
    createRoads()
    createPlots()
    createSpawn()
    -- createFishingSpots() -- Désactivé : spots de pêche placés manuellement
    hasGenerated = true
    print("[Paradis][CampingWorldGenerator] Génération terminée.")
    return generatedPlots
end

return CampingWorldGenerator
