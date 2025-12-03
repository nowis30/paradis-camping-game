--[[
    EconomyConfig
    Décrit les coûts et revenus générés par chaque type d'objet plaçable.
    Simon peut modifier librement ce fichier pour ajuster l'équilibrage.
]]

local EconomyConfig = {
    General = {
        StartingCash = 250,
        CashCap = 250000,
        MaintenanceTaxRate = 0.03,
        MaintenanceIntervalSeconds = 600,
    },
    Objects = {
        GrassTile = {
            Cost = 5,
            IncomePerSecond = 0.05,
            UnlockAtIncome = 0,
        },
        GravelTile = {
            Cost = 8,
            IncomePerSecond = 0.08,
            UnlockAtIncome = 0,
        },
        TreeBlock = {
            Cost = 25,
            IncomePerSecond = 0.4,
            UnlockAtIncome = 0.3,
        },
        RockBlock = {
            Cost = 30,
            IncomePerSecond = 0.35,
            UnlockAtIncome = 0.3,
        },
        FenceSegment = {
            Cost = 12,
            IncomePerSecond = 0.1,
            UnlockAtIncome = 0.1,
        },
        Balancoire = {
            Cost = 80,
            IncomePerSecond = 1.2,
            UnlockAtIncome = 0.6,
        },
        LightPost = {
            Cost = 40,
            IncomePerSecond = 0.6,
            UnlockAtIncome = 0.5,
        },
        Bench = {
            Cost = 20,
            IncomePerSecond = 0.1,
            UnlockAtIncome = 0,
        },
        TablePicnic = {
            Cost = 35,
            IncomePerSecond = 0.2,
            UnlockAtIncome = 0,
        },
        BBQGrill = {
            Cost = 50,
            IncomePerSecond = 0.25,
            UnlockAtIncome = 0.2,
        },
        Lantern = {
            Cost = 15,
            IncomePerSecond = 0.08,
            UnlockAtIncome = 0,
        },
        TentSmall = {
            Cost = 60,
            IncomePerSecond = 0.5,
            UnlockAtIncome = 0.3,
        },
        TentLarge = {
            Cost = 90,
            IncomePerSecond = 0.8,
            UnlockAtIncome = 0.5,
        },
        FlowerPot = {
            Cost = 8,
            IncomePerSecond = 0.05,
            UnlockAtIncome = 0,
        },
        Bush = {
            Cost = 10,
            IncomePerSecond = 0.06,
            UnlockAtIncome = 0,
        },
        SignWood = {
            Cost = 12,
            IncomePerSecond = 0.02,
            UnlockAtIncome = 0,
        },
        Campfire = {
            Cost = 45,
            IncomePerSecond = 0.35,
            UnlockAtIncome = 0.2,
        },
        TravelTrailer1961 = {
            Cost = 250,
            IncomePerSecond = 2.2,
            UnlockAtIncome = 1.2,
        },
        ArbreVert = {
            Cost = 35,
            IncomePerSecond = 0.5,
            UnlockAtIncome = 0.25,
        },
        ArbreRose = {
            Cost = 40,
            IncomePerSecond = 0.55,
            UnlockAtIncome = 0.3,
        },
        Arbre_Gros = {
            Cost = 55,
            IncomePerSecond = 0.9,
            UnlockAtIncome = 0.5,
        },
        Arbre_Petit = {
            Cost = 20,
            IncomePerSecond = 0.25,
            UnlockAtIncome = 0.15,
        },
        -- Arbre à bois (LogNode) avec revenus; le coût réel est calculé dynamiquement
        LogNode = {
            Cost = 1000, -- Coût de base affiché; le placement calculera 1000 x10 par arbre supplémentaire
            IncomePerSecond = 1.0, -- Revenu par seconde par arbre
            UnlockAtIncome = 0.0,
        },
        -- Poissons décoratifs (aucun revenu, coût nul)
        Common = {
            Cost = 0,
            IncomePerSecond = 0,
            UnlockAtIncome = 0,
        },
        rare = {
            Cost = 0,
            IncomePerSecond = 0,
            UnlockAtIncome = 0,
        },
        legendaire = {
            Cost = 0,
            IncomePerSecond = 0,
            UnlockAtIncome = 0,
        },
    },

    ConstructionObjects = {
        MurBoisSimple = {
            Cost = 5,
            IncomePerSecond = 0.05,
            UnlockAtIncome = 0,
        },
        MurBoisFenetre = {
            Cost = 12,
            IncomePerSecond = 0.12,
            UnlockAtIncome = 0.1,
        },
        PlancherBois = {
            Cost = 10,
            IncomePerSecond = 0.12,
            UnlockAtIncome = 0.1,
        },
        ToitBois = {
            Cost = 25,
            IncomePerSecond = 0.35,
            UnlockAtIncome = 0.5,
        },
        CabanePleine = {
            Cost = 180,
            IncomePerSecond = 3.4,
            UnlockAtIncome = 1.5,
        },
        MurBoisPorte = {
            Cost = 18,
            IncomePerSecond = 0.22,
            UnlockAtIncome = 0.2,
        },
    },

    Defaults = {
        Cost = 0,
        IncomePerSecond = 0,
        UnlockAtIncome = 0,
    },

    Boosts = {
        Enabled = true,
        IntervalSeconds = 420,
        RandomJitterSeconds = 90,
        Events = {
            {
                Name = "Visite de campeurs",
                Multiplier = 2,
                DurationSeconds = 60,
            },
            {
                Name = "Soleil radieux",
                Multiplier = 1.5,
                DurationSeconds = 75,
            },
            {
                Name = "Festival du bois",
                Multiplier = 2.5,
                DurationSeconds = 45,
            },
        },
    },
}

local Defaults = EconomyConfig.Defaults

local function cloneEntry(entry)
    if not entry then
        return {
            Cost = Defaults.Cost,
            IncomePerSecond = Defaults.IncomePerSecond,
            UnlockAtIncome = Defaults.UnlockAtIncome,
        }
    end
    return {
        Cost = tonumber(entry.Cost) or Defaults.Cost,
        IncomePerSecond = tonumber(entry.IncomePerSecond) or Defaults.IncomePerSecond,
        UnlockAtIncome = tonumber(entry.UnlockAtIncome) or Defaults.UnlockAtIncome,
    }
end

function EconomyConfig.GetObjectEconomy(objectType)
    return cloneEntry(EconomyConfig.Objects[objectType])
end

function EconomyConfig.GetConstructionEconomy(modelName)
    return cloneEntry(EconomyConfig.ConstructionObjects[modelName])
end

function EconomyConfig.Resolve(catalog, objectId)
    if catalog == "Construction" then
        return EconomyConfig.GetConstructionEconomy(objectId)
    end
    return EconomyConfig.GetObjectEconomy(objectId)
end

return EconomyConfig
