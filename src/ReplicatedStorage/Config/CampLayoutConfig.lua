--[[
    CampLayoutConfig
    Variante "camping-lignes" : deux grandes avenues parallèles et un lac décentré.
    Les parcelles sont plus grandes et moins nombreuses.
]]

local CampLayoutConfig = {}

CampLayoutConfig.Ground = {
    Size = Vector3.new(820, 1, 520),
    Position = Vector3.new(0, 0, 0),
    Material = Enum.Material.Grass,
    Color = Color3.fromRGB(72, 168, 94),
}

CampLayoutConfig.SurroundingWater = {
    Size = Vector3.new(1200, 2, 900),
    Position = Vector3.new(0, -1, 0),
    Material = Enum.Material.Water,
    Color = Color3.fromRGB(40, 130, 170),
    Transparency = 0.25,
}

CampLayoutConfig.Lake = {
    Size = Vector3.new(80, 1.5, 80),
    Position = Vector3.new(-255, 0.75, 30),
    Material = Enum.Material.Water,
    Color = Color3.fromRGB(30, 120, 165),
    Transparency = 0.2,
}

CampLayoutConfig.Spawn = {
    Position = Vector3.new(-340, 3, -70),
    Size = Vector3.new(12, 1, 12),
    Orientation = Vector3.new(0, 90, 0),
}

CampLayoutConfig.Transform = {
    MirrorX = true,
}

CampLayoutConfig.RoadPolylines = {
    {
        Name = "TopRow",
        Width = 10,
        Points = {
            Vector3.new(-400, 0.2, 140),
            Vector3.new(400, 0.2, 140),
        },
    },
    {
        Name = "BottomRow",
        Width = 10,
        Points = {
            Vector3.new(-400, 0.2, -140),
            Vector3.new(400, 0.2, -140),
        },
    },
}

CampLayoutConfig.PlotBands = {
    {
        RoadName = "TopRow",
        Side = "Top", -- Seulement en haut de la route
        PairCount = 4, -- 4 parcelles en haut (retire celle à gauche près du lac)
        PlotSize = Vector2.new(78, 60),
        OffsetFromRoad = 36,
        StartOffset = 150, -- Décalé vers la droite pour éviter le lac
        SpacingAlongRoad = 110,
    },
    {
        RoadName = "BottomRow",
        Side = "Bottom", -- Seulement en bas de la route
        PairCount = 4, -- 4 parcelles en bas (retire celle à gauche près du lac)
        PlotSize = Vector2.new(78, 60),
        OffsetFromRoad = 36,
        StartOffset = 150, -- Décalé vers la droite pour éviter le lac
        SpacingAlongRoad = 110,
    },
}

CampLayoutConfig.PlotAppearance = {
    Thickness = 0.7,
    Material = Enum.Material.Grass,
    Color = Color3.fromRGB(100, 185, 115),
    BorderColor = Color3.fromRGB(255, 225, 140),
    SignPostColor = Color3.fromRGB(176, 130, 80),
    SignBoardColor = Color3.fromRGB(125, 85, 45),
}

return CampLayoutConfig
