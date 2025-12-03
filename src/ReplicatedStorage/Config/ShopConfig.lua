--[[
    ShopConfig
    Décrit les objets achetables (arbres, roulottes, décorations) pour la boutique de parcelles.
    Chaque entrée référence un modèle stocké dans ReplicatedStorage.ShopObjects.
]]

local ShopConfig = {}

ShopConfig.Items = {
    Arbre_Petit = {
        Id = "Arbre_Petit",
        DisplayName = "Petit arbre",
        ModelName = "Arbre_Petit",
        Category = "Arbre",
        Cost = 25,
    },
    Arbre_Gros = {
        Id = "Arbre_Gros",
        DisplayName = "Gros arbre",
        ModelName = "Arbre_Gros",
        Category = "Arbre",
        Cost = 60,
    },
    Roulotte_Classique = {
        Id = "Roulotte_Classique",
        DisplayName = "Roulotte classique",
        ModelName = "Roulotte_Classique",
        Category = "Roulotte",
        Cost = 200,
    },
    Roulotte_Luxe = {
        Id = "Roulotte_Luxe",
        DisplayName = "Roulotte luxe",
        ModelName = "Roulotte_Luxe",
        Category = "Roulotte",
        Cost = 500,
    },
    Balancoire_Simple = {
        Id = "Balancoire_Simple",
        DisplayName = "Balançoire",
        ModelName = "Balancoire_Simple",
        Category = "Deco",
        Cost = 80,
    },
    Roche_Grande = {
        Id = "Roche_Grande",
        DisplayName = "Roche",
        ModelName = "Roche_Grande",
        Category = "Deco",
        Cost = 20,
    },
}

ShopConfig.Defaults = {
    Cost = 0,
    Category = "Autre",
}

return ShopConfig
