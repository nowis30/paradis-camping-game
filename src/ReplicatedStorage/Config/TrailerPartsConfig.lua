--[[
    TrailerPartsConfig
    Décrit toutes les pièces modulaires utilisables pour construire une roulotte personnalisée.
    Chaque entrée définit les métadonnées nécessaires au placement (grille, empilement, hauteur, etc.).
    NB : GridSize est exprimé en nombre de cellules (CampConfig.TRAILER_CELL_SIZE).
]]

local TrailerParts = {
    FoundationFloor = {
        Id = "FoundationFloor",
        DisplayName = "Solage",
        Category = "Foundation",
        GridSize = Vector2.new(4, 4),
        Height = 1,
        CanStackOn = {},
        ModelType = "FoundationFloor",
        Material = Enum.Material.Concrete,
        Color = Color3.fromRGB(200, 200, 200),
        Cost = 75,
    },
    WallSimple = {
        Id = "WallSimple",
        DisplayName = "Mur",
        Category = "Wall",
        GridSize = Vector2.new(4, 1),
        Height = 6,
        CanStackOn = { "Foundation" },
        ModelType = "WallSimple",
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(235, 212, 170),
        Cost = 45,
    },
    WallWindow = {
        Id = "WallWindow",
        DisplayName = "Mur fenêtre",
        Category = "Wall",
        GridSize = Vector2.new(4, 1),
        Height = 6,
        CanStackOn = { "Foundation" },
        ModelType = "WallWindow",
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(230, 230, 255),
        SecondaryColor = Color3.fromRGB(120, 180, 255),
        Cost = 55,
    },
    WallDoor = {
        Id = "WallDoor",
        DisplayName = "Mur porte",
        Category = "Wall",
        GridSize = Vector2.new(4, 1),
        Height = 6,
        CanStackOn = { "Foundation" },
        ModelType = "WallDoor",
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(240, 220, 180),
        SecondaryColor = Color3.fromRGB(120, 120, 120),
        Cost = 60,
    },
    RoofSimple = {
        Id = "RoofSimple",
        DisplayName = "Toit",
        Category = "Roof",
        GridSize = Vector2.new(4, 4),
        Height = 2,
        CanStackOn = { "Wall" },
        ModelType = "RoofSimple",
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(210, 90, 70),
        Cost = 50,
    },
}

return TrailerParts
