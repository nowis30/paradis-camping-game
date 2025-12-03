--[[
    MoveDecorToReplicatedStorage.server.lua
    Déplace automatiquement les modèles de décor du Workspace vers ReplicatedStorage
    pour qu'ils soient accessibles par le système de progression
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Créer le dossier AmenagementCamping s'il n'existe pas
local amenagementFolder = ReplicatedStorage:FindFirstChild("AmenagementCamping")
if not amenagementFolder then
    amenagementFolder = Instance.new("Folder")
    amenagementFolder.Name = "AmenagementCamping"
    amenagementFolder.Parent = ReplicatedStorage
    print("[MoveDecor] ✅ Dossier AmenagementCamping créé dans ReplicatedStorage")
end

-- Fonction pour nettoyer les scripts indésirables dans un modèle
local function cleanModel(model)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") then
            desc:Destroy()
        end
    end
end

-- Liste des modèles à déplacer
local modelNames = {
    -- Trailers
    "Trailer_1", "Trailer_2", "Trailer_3",
    -- BBQ
    "BBQ_1", "BBQ_2", "BBQ_3",
    -- Tables
    "PicnicTable_1", "PicnicTable_2", "PicnicTable_3",
    -- Arbres
    "Tree_1", "Tree_2", "Tree_3",
    -- Rochers
    "DecorRock_2", "DecorRock_3",
    -- Feux de camp
    "Campfire_1", "Campfire_2", "Campfire_3",
}

local movedCount = 0
local alreadyExistsCount = 0

-- Chercher dans Workspace et Workspace.AmenagementCamping
local searchLocations = {
    Workspace,
    Workspace:FindFirstChild("AmenagementCamping")
}

for _, modelName in ipairs(modelNames) do
    -- Vérifier si le modèle existe déjà dans ReplicatedStorage
    if amenagementFolder:FindFirstChild(modelName) then
        alreadyExistsCount = alreadyExistsCount + 1
    else
        local found = false
        
        -- Chercher dans chaque emplacement
        for _, location in ipairs(searchLocations) do
            if location then
                local model = location:FindFirstChild(modelName)
                if model and model:IsA("Model") then
                    -- Nettoyer les scripts problématiques
                    cleanModel(model)
                    
                    -- Déplacer vers ReplicatedStorage
                    model.Parent = amenagementFolder
                    movedCount = movedCount + 1
                    found = true
                    print("[MoveDecor] ✅", modelName, "déplacé vers ReplicatedStorage")
                    break
                end
            end
        end
        
        if not found then
            warn("[MoveDecor] ⚠️", modelName, "introuvable dans Workspace")
        end
    end
end

print(string.format("[MoveDecor] 📦 Résumé: %d modèles déplacés, %d déjà présents", movedCount, alreadyExistsCount))
