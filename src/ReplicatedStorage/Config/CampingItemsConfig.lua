--[[
    CampingItemsConfig.lua
    Configuration de tous les objets de camping progressifs (Roulottes, BBQ, etc.)
    Chaque objet a des niveaux avec coûts, income et prérequis (achievements)
]]

local CampingItemsConfig = {}

-- Liste de tous les objets de camping par niveaux
CampingItemsConfig.Items = {
    -- ============ ROULOTTES (TRAILERS) ============
    Trailer_1 = {
        Id = "Trailer_1",
        Category = "Trailer",
        Level = 1,
        DisplayName = "Roulotte usagée",
        ModelName = "Trailer_1", -- Modèle dans AmenagementCamping
        BaseIncome = 5,
        Cost = 100,
        Prerequisites = {
            MinCash = 0,
            Achievements = {}, -- Aucun achievement requis pour niveau 1
        },
    },
    Trailer_2 = {
        Id = "Trailer_2",
        Category = "Trailer",
        Level = 2,
        DisplayName = "Roulotte familiale",
        ModelName = "Trailer_2", -- Modèle dans AmenagementCamping
        BaseIncome = 15,
        Cost = 500,
        Prerequisites = {
            MinCash = 300,
            Achievements = { "CaughtRareFish" }, -- Doit avoir pêché un rare
        },
    },
    Trailer_3 = {
        Id = "Trailer_3",
        Category = "Trailer",
        Level = 3,
        DisplayName = "Roulotte deluxe",
        ModelName = "Trailer_3", -- Modèle dans AmenagementCamping
        BaseIncome = 40,
        Cost = 2000,
        Prerequisites = {
            MinCash = 1000,
            Achievements = { "CaughtLegendaryFish", "CompletedMaze" },
        },
    },
    Trailer_4 = {
        Id = "Trailer_4",
        Category = "Trailer",
        Level = 4,
        DisplayName = "Roulotte luxe",
        ModelName = "Trailer_3",
        BaseIncome = 100,
        Cost = 5000,
        Prerequisites = {
            MinCash = 3000,
            Achievements = { "CaughtLegendaryFish", "CompletedMaze", "CompletedSwingLoops", "WoodMaster" },
        },
    },

    -- ============ BBQ ============
    BBQ_1 = {
        Id = "BBQ_1",
        Category = "BBQ",
        Level = 1,
        DisplayName = "Petit BBQ rouillé",
        ModelName = "BBQ_1",
        BaseIncome = 2,
        Cost = 50,
        Prerequisites = {
            MinCash = 0,
            Achievements = {},
        },
    },
    BBQ_2 = {
        Id = "BBQ_2",
        Category = "BBQ",
        Level = 2,
        DisplayName = "BBQ famille",
        ModelName = "BBQ_2",
        BaseIncome = 6,
        Cost = 200,
        Prerequisites = {
            MinCash = 150,
            Achievements = { "CompletedSwingLoops" },
        },
    },
    BBQ_3 = {
        Id = "BBQ_3",
        Category = "BBQ",
        Level = 3,
        DisplayName = "BBQ professionnel",
        ModelName = "BBQ_3",
        BaseIncome = 15,
        Cost = 800,
        Prerequisites = {
            MinCash = 500,
            Achievements = { "CompletedSwingLoops", "WoodMaster" },
        },
    },

    -- ============ TABLE PICNIC ============
    PicnicTable_1 = {
        Id = "PicnicTable_1",
        Category = "PicnicTable",
        Level = 1,
        DisplayName = "Table basique",
        ModelName = "PicnicTable_1",
        BaseIncome = 1,
        Cost = 30,
        Prerequisites = {
            MinCash = 0,
            Achievements = {},
        },
    },
    PicnicTable_2 = {
        Id = "PicnicTable_2",
        Category = "PicnicTable",
        Level = 2,
        DisplayName = "Grande table familiale",
        ModelName = "PicnicTable_2",
        BaseIncome = 3,
        Cost = 150,
        Prerequisites = {
            MinCash = 100,
            Achievements = { "CaughtRareFish" },
        },
    },
    PicnicTable_3 = {
        Id = "PicnicTable_3",
        Category = "PicnicTable",
        Level = 3,
        DisplayName = "Table de luxe",
        ModelName = "PicnicTable_3",
        BaseIncome = 8,
        Cost = 600,
        Prerequisites = {
            MinCash = 400,
            Achievements = { "CaughtLegendaryFish", "CompletedMaze" },
        },
    },

    -- ============ ARBRES DÉCORATIFS ============
    TreesDecor_1 = {
        Id = "TreesDecor_1",
        Category = "TreesGroup",
        Level = 1,
        DisplayName = "Arbustes simples",
        ModelName = "Tree_1",
        BaseIncome = 1,
        Cost = 20,
        Prerequisites = {
            MinCash = 0,
            Achievements = {},
        },
    },
    TreesDecor_2 = {
        Id = "TreesDecor_2",
        Category = "TreesGroup",
        Level = 2,
        DisplayName = "Bosquet verdoyant",
        ModelName = "Tree_2",
        BaseIncome = 3,
        Cost = 100,
        Prerequisites = {
            MinCash = 50,
            Achievements = { "WoodMaster" },
        },
    },
    TreesDecor_3 = {
        Id = "TreesDecor_3",
        Category = "TreesGroup",
        Level = 3,
        DisplayName = "Forêt miniature",
        ModelName = "Tree_3",
        BaseIncome = 7,
        Cost = 400,
        Prerequisites = {
            MinCash = 250,
            Achievements = { "WoodMaster", "CompletedSwingLoops" },
        },
    },

    -- ============ ROCHE DÉCORATIVE ============
    DecorRock_1 = {
        Id = "DecorRock_1",
        Category = "DecorRock",
        Level = 1,
        DisplayName = "Petite pierre",
        ModelName = "DecorRock_2",
        BaseIncome = 0.5,
        Cost = 10,
        Prerequisites = {
            MinCash = 0,
            Achievements = {},
        },
    },
    DecorRock_2 = {
        Id = "DecorRock_2",
        Category = "DecorRock",
        Level = 2,
        DisplayName = "Gros rocher",
        ModelName = "DecorRock_3",
        BaseIncome = 2,
        Cost = 80,
        Prerequisites = {
            MinCash = 50,
            Achievements = { "CompletedMaze" },
        },
    },

    -- ============ FEU DE CAMP ============
    Campfire_1 = {
        Id = "Campfire_1",
        Category = "Campfire",
        Level = 1,
        DisplayName = "Petit feu",
        ModelName = "Campfire_1",
        BaseIncome = 3,
        Cost = 40,
        Prerequisites = {
            MinCash = 0,
            Achievements = {},
        },
    },
    Campfire_2 = {
        Id = "Campfire_2",
        Category = "Campfire",
        Level = 2,
        DisplayName = "Grand feu de camp",
        ModelName = "Campfire_2",
        BaseIncome = 8,
        Cost = 250,
        Prerequisites = {
            MinCash = 150,
            Achievements = { "WoodMaster" },
        },
    },
    Campfire_3 = {
        Id = "Campfire_3",
        Category = "Campfire",
        Level = 3,
        DisplayName = "Feu éternel",
        ModelName = "Campfire_3",
        BaseIncome = 20,
        Cost = 1000,
        Prerequisites = {
            MinCash = 600,
            Achievements = { "WoodMaster", "CaughtLegendaryFish" },
        },
    },
}

-- Catégories d'objets et leurs slots par défaut
CampingItemsConfig.Categories = {
    Trailer = {
        SlotName = "TrailerSlot",
        DefaultOffset = CFrame.new(0, 0, -8),
        Description = "Roulotte de camping",
    },
    BBQ = {
        SlotName = "BBQSlot",
        DefaultOffset = CFrame.new(-5, 0, 2),
        Description = "Barbecue",
    },
    PicnicTable = {
        SlotName = "PicnicTableSlot",
        DefaultOffset = CFrame.new(5, 0, 2),
        Description = "Table de pique-nique",
    },
    TreesGroup = {
        SlotName = "TreesSlot",
        DefaultOffset = CFrame.new(-8, 0, -5),
        Description = "Groupe d'arbres",
    },
    DecorRock = {
        SlotName = "RockSlot",
        DefaultOffset = CFrame.new(7, 0, -4),
        Description = "Rocher décoratif",
    },
    Campfire = {
        SlotName = "CampfireSlot",
        DefaultOffset = CFrame.new(0, 0, 4),
        Description = "Feu de camp",
    },
}

-- Liste des achievements disponibles
CampingItemsConfig.Achievements = {
    CaughtRareFish = {
        Id = "CaughtRareFish",
        DisplayName = "Pêcheur chanceux",
        Description = "Attraper un poisson rare",
        Icon = "🐟",
    },
    CaughtLegendaryFish = {
        Id = "CaughtLegendaryFish",
        DisplayName = "Maître pêcheur",
        Description = "Attraper un poisson légendaire",
        Icon = "🏆",
    },
    CompletedMaze = {
        Id = "CompletedMaze",
        DisplayName = "Explorateur du labyrinthe",
        Description = "Terminer le labyrinthe",
        Icon = "🗺️",
    },
    CompletedSwingLoops = {
        Id = "CompletedSwingLoops",
        DisplayName = "Acrobate",
        Description = "Faire 10 tours complets sur la balançoire",
        Icon = "🎪",
    },
    WoodMaster = {
        Id = "WoodMaster",
        DisplayName = "Bûcheron expert",
        Description = "Couper 50 bûches",
        Icon = "🪓",
    },
}

-- Fonctions utilitaires
function CampingItemsConfig.GetItem(itemId)
    return CampingItemsConfig.Items[itemId]
end

function CampingItemsConfig.GetItemsByCategory(category)
    local items = {}
    for itemId, itemData in pairs(CampingItemsConfig.Items) do
        if itemData.Category == category then
            table.insert(items, itemData)
        end
    end
    -- Trier par niveau
    table.sort(items, function(a, b) return a.Level < b.Level end)
    return items
end

function CampingItemsConfig.GetNextLevel(currentItemId)
    local current = CampingItemsConfig.GetItem(currentItemId)
    if not current then return nil end
    
    local categoryItems = CampingItemsConfig.GetItemsByCategory(current.Category)
    for i, item in ipairs(categoryItems) do
        if item.Level == current.Level + 1 then
            return item
        end
    end
    return nil
end

return CampingItemsConfig
