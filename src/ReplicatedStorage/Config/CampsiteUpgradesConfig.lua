--[[
    CampsiteUpgradesConfig
    Configuration des upgrades pour les objets de camping
    (À implémenter complètement plus tard)
]]

local CampsiteUpgradesConfig = {}

-- Structure pour les upgrades futurs
-- Chaque objet peut avoir plusieurs niveaux d'upgrade
CampsiteUpgradesConfig.Upgrades = {
    Trailer = {
        MaxLevel = 5,
        Levels = {
            [1] = { ModelName = "Trailer_Default", Cost = 0, Description = "Roulotte basique" },
            [2] = { ModelName = "Trailer_Upgraded1", Cost = 500, Description = "Roulotte améliorée" },
            [3] = { ModelName = "Trailer_Upgraded2", Cost = 1500, Description = "Roulotte confortable" },
            [4] = { ModelName = "Trailer_Upgraded3", Cost = 3000, Description = "Roulotte luxueuse" },
            [5] = { ModelName = "Trailer_Upgraded4", Cost = 5000, Description = "Roulotte de luxe" },
        }
    },
    PicnicTable = {
        MaxLevel = 3,
        Levels = {
            [1] = { ModelName = "PicnicTable_Default", Cost = 0, Description = "Table basique" },
            [2] = { ModelName = "PicnicTable_Upgraded1", Cost = 300, Description = "Table en bon bois" },
            [3] = { ModelName = "PicnicTable_Upgraded2", Cost = 800, Description = "Table premium" },
        }
    },
    BBQ = {
        MaxLevel = 3,
        Levels = {
            [1] = { ModelName = "BBQ_Default", Cost = 0, Description = "BBQ simple" },
            [2] = { ModelName = "BBQ_Upgraded1", Cost = 400, Description = "BBQ amélioré" },
            [3] = { ModelName = "BBQ_Upgraded2", Cost = 1000, Description = "BBQ professionnel" },
        }
    },
    TreesGroup = {
        MaxLevel = 3,
        Levels = {
            [1] = { ModelName = "TreesGroup_Default", Cost = 0, Description = "Jeunes arbres" },
            [2] = { ModelName = "TreesGroup_Upgraded1", Cost = 200, Description = "Arbres matures" },
            [3] = { ModelName = "TreesGroup_Upgraded2", Cost = 600, Description = "Beaux arbres" },
        }
    },
    DecorRock = {
        MaxLevel = 2,
        Levels = {
            [1] = { ModelName = "Rock_Default", Cost = 0, Description = "Rocher simple" },
            [2] = { ModelName = "Rock_Upgraded1", Cost = 150, Description = "Rocher sculpté" },
        }
    },
    Campfire = {
        MaxLevel = 3,
        Levels = {
            [1] = { ModelName = "Campfire_Default", Cost = 0, Description = "Feu simple" },
            [2] = { ModelName = "Campfire_Upgraded1", Cost = 250, Description = "Foyer aménagé" },
            [3] = { ModelName = "Campfire_Upgraded2", Cost = 700, Description = "Foyer de pierre" },
        }
    },
}

-- Fonction helper pour obtenir les infos d'un niveau d'upgrade
function CampsiteUpgradesConfig.GetUpgradeInfo(objectId, level)
    local upgrades = CampsiteUpgradesConfig.Upgrades[objectId]
    if not upgrades then
        return nil
    end
    return upgrades.Levels[level]
end

-- Fonction helper pour obtenir le niveau max
function CampsiteUpgradesConfig.GetMaxLevel(objectId)
    local upgrades = CampsiteUpgradesConfig.Upgrades[objectId]
    if not upgrades then
        return 1
    end
    return upgrades.MaxLevel
end

return CampsiteUpgradesConfig
