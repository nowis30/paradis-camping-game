--[[
    CampConfig
    Décrit le terrain de camping "Paradis" sous forme de données.
    Toute la génération (sol, routes, parcelles, aire commune) repose sur ces valeurs.
    Modifier ce fichier suffit pour remodeler complètement la carte sans toucher au code.
]]

local CampConfig = {}

--[[
    Description du sol principal du camping.
    La position correspond au centre du Part généré par WorldGenerator.
]]
CampConfig.Ground = {
    Size = Vector3.new(520, 2, 520),
    Position = Vector3.new(0, -1, 0),
    Material = Enum.Material.Grass,
    Color = Color3.fromRGB(70, 155, 90),
}

-- Aire commune centrale : terrain de jeux + espace de rassemblement.
CampConfig.CommonArea = {
    Center = Vector3.new(0, 1, -20),
    Size = Vector3.new(90, 2, 90),
    Material = Enum.Material.Grass,
    Color = Color3.fromRGB(95, 170, 95),
    PlaygroundSpots = {
        { Name = "PlaygroundSpot", Size = Vector3.new(25, 2, 25), Offset = Vector3.new(-15, 1, -10), Material = Enum.Material.Sand, Color = Color3.fromRGB(225, 197, 105) },
        { Name = "GameSpot1", Size = Vector3.new(18, 1.5, 18), Offset = Vector3.new(20, 0.75, 10), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(168, 132, 84) },
    },
}

-- Grand plan d'eau pour l'ambiance camping (lac/piscine naturelle).
CampConfig.Lake = {
    Center = Vector3.new(0, 0.5, -110),
    Size = Vector3.new(70, 3, 46),
    Material = Enum.Material.SmoothPlastic,
    Color = Color3.fromRGB(26, 142, 171),
    Transparency = 0.2,
    Reflectance = 0.05,
}

-- Spawn principal des joueurs.
CampConfig.Spawn = {
    CFrame = CFrame.new(0, 4, -210),
    Size = Vector3.new(14, 1, 14),
    Material = Enum.Material.WoodPlanks,
    Color = Color3.fromRGB(163, 132, 92),
}

-- Routes internes : chaque entrée décrit un segment rectiligne.
-- From/To doivent être alignés sur Y pour garantir des routes plates.
CampConfig.Roads = {
    {
        Name = "MainRoad",
        From = Vector3.new(-200, 0, 0),
        To = Vector3.new(200, 0, 0),
        Width = 12,
        Material = Enum.Material.Asphalt,
        Color = Color3.fromRGB(45, 45, 45),
    },
    {
        Name = "NorthLoop",
        From = Vector3.new(-40, 0, 50),
        To = Vector3.new(160, 0, 160),
        Width = 8,
        Material = Enum.Material.Concrete,
        Color = Color3.fromRGB(60, 60, 60),
    },
    {
        Name = "SouthLoop",
        From = Vector3.new(20, 0, -40),
        To = Vector3.new(-180, 0, -170),
        Width = 8,
        Material = Enum.Material.Concrete,
        Color = Color3.fromRGB(60, 60, 60),
    },
    {
        Name = "LakeSpur",
        From = Vector3.new(0, 0, -20),
        To = Vector3.new(0, 0, -140),
        Width = 7,
        Material = Enum.Material.Asphalt,
        Color = Color3.fromRGB(52, 52, 52),
    },
}

-- Bandes de parcelles. Chaque entrée décrit les parcelles alignées sur une route.
-- PlotSize = Vector2.new(longueur le long de la route, profondeur vers l'extérieur).
CampConfig.PlotBands = {
    {
        RoadName = "MainRoad",
        Side = "Left",
        PlotCount = 8,
        PlotSize = Vector2.new(22, 16),
        OffsetFromRoad = 8,
        StartOffsetAlongRoad = 30,
        SpacingAlongRoad = 28,
    },
    {
        RoadName = "MainRoad",
        Side = "Right",
        PlotCount = 8,
        PlotSize = Vector2.new(22, 16),
        OffsetFromRoad = 8,
        StartOffsetAlongRoad = 30,
        SpacingAlongRoad = 28,
    },
    {
        RoadName = "NorthLoop",
        Side = "Right",
        PlotCount = 6,
        PlotSize = Vector2.new(20, 14),
        OffsetFromRoad = 7,
        StartOffsetAlongRoad = 16,
        SpacingAlongRoad = 24,
    },
    {
        RoadName = "SouthLoop",
        Side = "Left",
        PlotCount = 6,
        PlotSize = Vector2.new(20, 14),
        OffsetFromRoad = 7,
        StartOffsetAlongRoad = 18,
        SpacingAlongRoad = 24,
    },
    {
        RoadName = "LakeSpur",
        Side = "Left",
        PlotCount = 4,
        PlotSize = Vector2.new(24, 18),
        OffsetFromRoad = 10,
        StartOffsetAlongRoad = 26,
        SpacingAlongRoad = 28,
    },
}

CampConfig.PlotDefaults = {
    BaseThickness = 0.6,
    BaseMaterial = Enum.Material.Grass,
    BaseColor = Color3.fromRGB(88, 170, 105),
    SelectionColor = Color3.fromRGB(245, 203, 66),
    EntryOffset = 2, -- distance entre le bord route et le panneau
}

CampConfig.Signage = {
    PostHeight = 6,
    PostSize = Vector3.new(1.5, 6, 1.5),
    BoardSize = Vector3.new(8, 4, 0.6),
    BillboardSize = UDim2.new(0, 220, 0, 80),
    TextSize = 18,
    EntryOffset = 2.5,
}

-- Valeurs historiques conservées pour compatibilité avec d'autres services.
do
    local groundPos = CampConfig.Ground.Position or Vector3.new()
    local groundSize = CampConfig.Ground.Size or Vector3.new()
    local surfaceY = groundPos.Y + (groundSize.Y / 2)
    CampConfig.CAMP_CENTER = Vector3.new(groundPos.X, surfaceY, groundPos.Z)
end
CampConfig.LOBBY_SPAWN = CampConfig.Spawn.CFrame

-- Paramètres gameplay déjà existants
CampConfig.MAX_OBJECTS_PER_PLOT = 120
CampConfig.BUILD_GRID_SIZE = 2
CampConfig.TRAILER_CELL_SIZE = 4
CampConfig.TRAILER_CATEGORY_LEVEL = {
    Foundation = 0,
    Wall = 1,
    Roof = 2,
}
CampConfig.TRAILER_LEVEL_BASE = {
    [0] = 0,
    [1] = 1,
    [2] = 7,
}

return CampConfig
