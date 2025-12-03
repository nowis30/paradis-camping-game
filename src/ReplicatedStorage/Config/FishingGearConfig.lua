--[[
    FishingGearConfig
    Configuration des cannes à pêche et appâts disponibles dans le Pro Shop.
    Chaque canne et appât modifie les chances de capture et les récompenses.
]]

local FishingGearConfig = {}

-- Cannes à pêche disponibles
FishingGearConfig.Rods = {
    Basic = {
        Id = "Basic",
        DisplayName = "Canne basique",
        Cost = 0,
        Description = "Canne de départ",
        SpeedMultiplier = 1.0,
        LegendaryChance = 0, -- aucune chance de légendaire
        RareBonus = 0,
        Color = Color3.fromRGB(101, 67, 33), -- brun bois
    },
    Advanced = {
        Id = "Advanced",
        DisplayName = "Canne avancée",
        Cost = 150,
        Description = "Canne plus rapide",
        SpeedMultiplier = 0.8, -- 20% plus rapide
        LegendaryChance = 0.02, -- 2% de légendaire
        RareBonus = 5,
        Color = Color3.fromRGB(40, 120, 220), -- bleu
    },
    Pro = {
        Id = "Pro",
        DisplayName = "Canne pro",
        Cost = 500,
        Description = "Pour les experts",
        SpeedMultiplier = 0.6, -- 40% plus rapide
        LegendaryChance = 0.05, -- 5% de légendaire
        RareBonus = 10,
        Color = Color3.fromRGB(200, 150, 40), -- doré
    },
    Master = {
        Id = "Master",
        DisplayName = "Canne master",
        Cost = 2000, -- Achat avec argent du jeu
        Description = "La meilleure canne",
        SpeedMultiplier = 0.5, -- 50% plus rapide
        LegendaryChance = 0.12, -- 12% de légendaire
        RareBonus = 20,
        Color = Color3.fromRGB(160, 40, 200), -- violet prestige
        Shiny = true, -- active effets visuels spéciaux
    },
}

-- Appâts disponibles
FishingGearConfig.Baits = {
    None = {
        Id = "None",
        DisplayName = "Aucun appât",
        Cost = 0,
        Description = "Sans appât",
        RewardMultiplier = 1.0,
        LegendaryBoost = 0,
        UsesPerPurchase = 0, -- illimité
    },
    Standard = {
        Id = "Standard",
        DisplayName = "Appât standard",
        Cost = 10,
        Description = "Appât de base",
        RewardMultiplier = 1.2,
        LegendaryBoost = 0.03,
        UsesPerPurchase = 5,
    },
    FishCommon = {
        Id = "FishCommon",
        DisplayName = "Poisson Common (appât)",
        Cost = 0,
        Description = "Utiliser un poisson Common comme appât",
        RewardMultiplier = 1.3,
        LegendaryBoost = 0.05,
        UsesPerPurchase = 1,
        RequiredFish = "Common",
    },
    Fishrare = {
        Id = "Fishrare",
        DisplayName = "Poisson rare (appât)",
        Cost = 0,
        Description = "Utiliser un poisson rare comme appât",
        RewardMultiplier = 1.6,
        LegendaryBoost = 0.15,
        UsesPerPurchase = 1,
        RequiredFish = "rare",
    },
    Premium = {
        Id = "Premium",
        DisplayName = "Appât premium",
        Cost = 30,
        Description = "Appât de qualité",
        RewardMultiplier = 1.5,
        LegendaryBoost = 0.08,
        UsesPerPurchase = 5,
    },
    Luxury = {
        Id = "Luxury",
        DisplayName = "Appât de luxe",
        Cost = 100,
        Description = "Attire les légendaires",
        RewardMultiplier = 2.0,
        LegendaryBoost = 0.25, -- +25% de chance légendaire
        UsesPerPurchase = 3,
    },
}

FishingGearConfig.DefaultRod = "Basic"
FishingGearConfig.DefaultBait = "Standard"

return FishingGearConfig
