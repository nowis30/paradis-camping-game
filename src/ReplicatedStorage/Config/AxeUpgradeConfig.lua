-- AxeUpgradeConfig.lua
-- Définit les paliers d'amélioration de la hache.
-- Chaque palier: Power (AxePower joueur), Cost (Money requis), Name (affichage)

local AxeUpgradeConfig = {
    -- Chaque palier peut définir:
    -- Cost: coût en Money (si présent et pas CostRobux)
    -- CostRobux: booléen si achat uniquement Robux (Developer Product)
    -- ProductId: ID du Developer Product (remplacer par le vrai)
    -- FireRequirement: niveau minimal de FireLevel (campfire) requis
    Tiers = {
        {Power = 1, Cost = 0, Name = "Hache Basique", FireRequirement = 0},
        {Power = 2, Cost = 50, Name = "Hache Renforcée", FireRequirement = 0},
        {Power = 3, Cost = 150, Name = "Hache Acier", FireRequirement = 10},
        {Power = 4, Cost = 400, Name = "Hache Mythique", FireRequirement = 30},
        {Power = 5, Cost = 1000, Name = "Hache Légendaire", FireRequirement = 50}, -- Achat avec argent du jeu
    }
}

return AxeUpgradeConfig