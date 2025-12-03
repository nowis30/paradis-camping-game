--[[
    CampsiteDefaultsConfig
    Définit les objets par défaut qui sont automatiquement placés sur chaque parcelle
    quand un joueur la claim.
]]

local CampsiteDefaultsConfig = {}

-- Offsets relatifs au centre de la parcelle
-- Ces objets seront créés automatiquement et ne pourront pas être déplacés
CampsiteDefaultsConfig.DefaultObjects = {
    {
        Id = "Trailer",
        ModelName = "Trailer_Default",
        Offset = CFrame.new(0, 0, -8),  -- Roulotte au fond de la parcelle
        Description = "Roulotte de camping"
    },
    {
        Id = "PicnicTable",
        ModelName = "PicnicTable_Default",
        Offset = CFrame.new(5, 0, 2),  -- Table à droite
        Description = "Table de pique-nique"
    },
    {
        Id = "BBQ",
        ModelName = "BBQ_Default",
        Offset = CFrame.new(-5, 0, 2),  -- BBQ à gauche
        Description = "Barbecue"
    },
    {
        Id = "TreesGroup",
        ModelName = "TreesGroup_Default",
        Offset = CFrame.new(-8, 0, -5),  -- Groupe d'arbres coin gauche
        Description = "Groupe d'arbres"
    },
    {
        Id = "DecorRock",
        ModelName = "Rock_Default",
        Offset = CFrame.new(7, 0, -4),  -- Rocher décoratif coin droit
        Description = "Rocher décoratif"
    },
    {
        Id = "Campfire",
        ModelName = "Campfire_Default",
        Offset = CFrame.new(0, 0, 4),  -- Feu de camp devant
        Description = "Feu de camp"
    },
}

-- Tailles par défaut pour les placeholders (si le modèle n'existe pas)
CampsiteDefaultsConfig.PlaceholderSizes = {
    Trailer = Vector3.new(8, 4, 12),
    PicnicTable = Vector3.new(4, 2, 6),
    BBQ = Vector3.new(2, 3, 2),
    TreesGroup = Vector3.new(6, 8, 6),
    DecorRock = Vector3.new(3, 2, 3),
    Campfire = Vector3.new(3, 1, 3),
}

-- Couleurs par défaut pour les placeholders
CampsiteDefaultsConfig.PlaceholderColors = {
    Trailer = Color3.fromRGB(180, 180, 200),
    PicnicTable = Color3.fromRGB(120, 80, 40),
    BBQ = Color3.fromRGB(60, 60, 60),
    TreesGroup = Color3.fromRGB(50, 120, 50),
    DecorRock = Color3.fromRGB(120, 120, 120),
    Campfire = Color3.fromRGB(100, 50, 20),
}

-- Matériaux par défaut pour les placeholders
CampsiteDefaultsConfig.PlaceholderMaterials = {
    Trailer = Enum.Material.Metal,
    PicnicTable = Enum.Material.Wood,
    BBQ = Enum.Material.Metal,
    TreesGroup = Enum.Material.Grass,
    DecorRock = Enum.Material.Rock,
    Campfire = Enum.Material.Wood,
}

return CampsiteDefaultsConfig
