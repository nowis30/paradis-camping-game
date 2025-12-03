-- RoadBuilder.server.lua
-- Génère des rues autour du camping

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CampConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CampConfig"))

wait(2)

local campingTerrain = workspace:WaitForChild("CampingTerrain", 10)
if not campingTerrain then
    warn("[RoadBuilder] CampingTerrain introuvable!")
    return
end

-- CampingTerrain est un Folder, utiliser une position de base ou chercher un objet référence
local center = Vector3.new(0, 0, 0)
if campingTerrain:IsA("BasePart") then
    center = campingTerrain.Position
elseif campingTerrain:IsA("Model") and campingTerrain.PrimaryPart then
    center = campingTerrain.PrimaryPart.Position
else
    -- Utiliser la position du centre du camping depuis CampConfig
    center = CampConfig.CampCenter or Vector3.new(0, 0, 0)
end
print("[RoadBuilder] Centre du camping:", center)

local ROAD_WIDTH = 12
local ROAD_HEIGHT = 0.3
local ROAD_COLOR = Color3.fromRGB(60, 60, 60)
local ROAD_MATERIAL = Enum.Material.Asphalt

-- Dossier pour les rues
local roadsFolder = Instance.new("Folder")
roadsFolder.Name = "Roads"
roadsFolder.Parent = workspace

-- Fonction pour créer une section de rue
local function createRoadSection(name, size, cframe)
    local road = Instance.new("Part")
    road.Name = name
    road.Size = size
    road.CFrame = cframe
    road.Anchored = true
    road.CanCollide = true
    road.Color = ROAD_COLOR
    road.Material = ROAD_MATERIAL
    road.TopSurface = Enum.SurfaceType.Smooth
    road.BottomSurface = Enum.SurfaceType.Smooth
    road.Parent = roadsFolder
    return road
end

-- Fonction pour créer une ligne blanche au centre de la route
local function createCenterLine(name, roadCFrame, roadLength, roadWidth)
    local line = Instance.new("Part")
    line.Name = name
    line.Size = Vector3.new(roadLength, ROAD_HEIGHT + 0.1, 0.3)
    line.CFrame = roadCFrame
    line.Anchored = true
    line.CanCollide = false
    line.Color = Color3.fromRGB(255, 255, 255)
    line.Material = Enum.Material.SmoothPlastic
    line.TopSurface = Enum.SurfaceType.Smooth
    line.BottomSurface = Enum.SurfaceType.Smooth
    line.Parent = roadsFolder
    return line
end

print("[RoadBuilder] Création du réseau de rues...")

-- Distance du centre pour placer les rues (juste à l'extérieur de la zone de camping)
local roadDistance = 180

-- Rue NORD (horizontale)
local roadNorth = createRoadSection(
    "RoadNorth",
    Vector3.new(400, ROAD_HEIGHT, ROAD_WIDTH),
    CFrame.new(center.X, center.Y + ROAD_HEIGHT/2, center.Z - roadDistance)
)
createCenterLine("CenterLineNorth", roadNorth.CFrame, 400, ROAD_WIDTH)

-- Rue SUD (horizontale)
local roadSouth = createRoadSection(
    "RoadSouth",
    Vector3.new(400, ROAD_HEIGHT, ROAD_WIDTH),
    CFrame.new(center.X, center.Y + ROAD_HEIGHT/2, center.Z + roadDistance)
)
createCenterLine("CenterLineSouth", roadSouth.CFrame, 400, ROAD_WIDTH)

-- Rue OUEST (verticale)
local roadWest = createRoadSection(
    "RoadWest",
    Vector3.new(ROAD_WIDTH, ROAD_HEIGHT, 360),
    CFrame.new(center.X - roadDistance, center.Y + ROAD_HEIGHT/2, center.Z)
)
createCenterLine("CenterLineWest", roadWest.CFrame, 360, ROAD_WIDTH)

-- Rue EST (verticale)
local roadEast = createRoadSection(
    "RoadEast",
    Vector3.new(ROAD_WIDTH, ROAD_HEIGHT, 360),
    CFrame.new(center.X + roadDistance, center.Y + ROAD_HEIGHT/2, center.Z)
)
createCenterLine("CenterLineEast", roadEast.CFrame, 360, ROAD_WIDTH)

-- Intersections (coins)
local intersectionSize = Vector3.new(ROAD_WIDTH, ROAD_HEIGHT, ROAD_WIDTH)

createRoadSection(
    "IntersectionNW",
    intersectionSize,
    CFrame.new(center.X - roadDistance, center.Y + ROAD_HEIGHT/2, center.Z - roadDistance)
)

createRoadSection(
    "IntersectionNE",
    intersectionSize,
    CFrame.new(center.X + roadDistance, center.Y + ROAD_HEIGHT/2, center.Z - roadDistance)
)

createRoadSection(
    "IntersectionSW",
    intersectionSize,
    CFrame.new(center.X - roadDistance, center.Y + ROAD_HEIGHT/2, center.Z + roadDistance)
)

createRoadSection(
    "IntersectionSE",
    intersectionSize,
    CFrame.new(center.X + roadDistance, center.Y + ROAD_HEIGHT/2, center.Z + roadDistance)
)

print("[RoadBuilder] Réseau de rues créé avec succès!")
