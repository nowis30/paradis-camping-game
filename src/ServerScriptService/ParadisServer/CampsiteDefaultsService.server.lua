--[[
    CampsiteDefaultsService
    Service qui génère automatiquement le kit de camping par défaut sur les parcelles
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CampsiteDefaultsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CampsiteDefaultsConfig"))
local CampsiteDefaultsService = {}

-- Cache du dossier de construction
local constructionFolder = nil

local function getConstructionFolder()
    if constructionFolder and constructionFolder.Parent then
        return constructionFolder
    end
    local folder = ReplicatedStorage:FindFirstChild("ConstructionObjet")
        or ReplicatedStorage:FindFirstChild("Construction Objet")
    if not folder then
        warn("[Paradis][CampsiteDefaults] Dossier 'ConstructionObjet' introuvable")
    end
    constructionFolder = folder
    return constructionFolder
end

-- Crée un placeholder simple si le modèle n'existe pas
local function createPlaceholder(def)
    local size = CampsiteDefaultsConfig.PlaceholderSizes[def.Id] or Vector3.new(4, 2, 4)
    local color = CampsiteDefaultsConfig.PlaceholderColors[def.Id] or Color3.fromRGB(150, 150, 150)
    local material = CampsiteDefaultsConfig.PlaceholderMaterials[def.Id] or Enum.Material.SmoothPlastic
    
    local model = Instance.new("Model")
    model.Name = def.Id
    
    local part = Instance.new("Part")
    part.Name = "Base"
    part.Size = size
    part.Anchored = true
    part.CanCollide = true
    part.Color = color
    part.Material = material
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = model
    
    model.PrimaryPart = part
    
    return model
end

-- Fonction principale : génère le kit de camping pour une parcelle
function CampsiteDefaultsService.SpawnDefaultCampsiteForPlot(plotModel, ownerPlayer)
    if not plotModel then
        warn("[Paradis][CampsiteDefaults] PlotModel nil")
        return false
    end
    
    print("[Paradis][CampsiteDefaults] Génération du kit de camping pour", plotModel.Name)
    
    -- 1) Trouver le centre/root de la parcelle
    local rootPart
    if typeof(plotModel) == "Instance" and plotModel:IsA("BasePart") then
        rootPart = plotModel
    elseif plotModel:IsA("Folder") then
        -- Si c'est un Folder (Container), chercher le parent qui a un BasePart
        local parent = plotModel.Parent
        if parent and parent:IsA("BasePart") then
            rootPart = parent
        else
            rootPart = parent and parent:FindFirstChildWhichIsA("BasePart", true)
        end
    else
        rootPart = plotModel:FindFirstChild("PlotCenter") 
            or plotModel:FindFirstChild("BasePart")
            or plotModel:FindFirstChildWhichIsA("BasePart", true)
    end
    
    if not rootPart then
        warn("[Paradis][CampsiteDefaults] Pas de root pour la parcelle:", plotModel.Name)
        return false
    end
    
    -- 2) Créer ou trouver le dossier pour les objets de camping
    local campsiteFolder = plotModel:FindFirstChild("CampsiteObjects")
    if not campsiteFolder then
        campsiteFolder = Instance.new("Folder")
        campsiteFolder.Name = "CampsiteObjects"
        campsiteFolder.Parent = plotModel
    end
    
    -- 3) Parcourir chaque objet par défaut
    local constructFolder = getConstructionFolder()
    
    -- ⚠️ DÉSACTIVÉ: Le système de progression via PlayerProgressService gère maintenant les objets
    -- Les objets de départ sont donnés via PlayerProgressService.OwnedItems
    print("[Paradis][CampsiteDefaults] ⚠️ Génération automatique désactivée - utiliser le système de progression")
    return true
    
    --[[ ANCIEN CODE DÉSACTIVÉ
    for _, def in ipairs(CampsiteDefaultsConfig.DefaultObjects) do
        -- Vérifier si l'objet existe déjà
        if campsiteFolder:FindFirstChild(def.Id) then
            print("[Paradis][CampsiteDefaults] Objet déjà existant:", def.Id)
            continue
        end
        
        -- Chercher le template ou créer un placeholder
        local template = nil
        if constructFolder then
            template = constructFolder:FindFirstChild(def.ModelName)
        end
        
        local newModel
        if template and template:IsA("Model") then
            newModel = template:Clone()
            print("[Paradis][CampsiteDefaults] Objet cloné depuis template:", def.ModelName)
        else
            newModel = createPlaceholder(def)
            print("[Paradis][CampsiteDefaults] Placeholder créé pour:", def.Id)
        end
        
        newModel.Name = def.Id
        newModel.Parent = campsiteFolder
        
        -- Positionner le modèle
        local targetCFrame = rootPart.CFrame * def.Offset
        
        if newModel.PrimaryPart then
            newModel:SetPrimaryPartCFrame(targetCFrame)
        else
            -- Fallback avec PivotTo
            local basePart = newModel:FindFirstChildWhichIsA("BasePart", true)
            if basePart then
                newModel:PivotTo(targetCFrame)
            end
        end
        
        -- Sécurité : tous les objets sont ancrés
        for _, part in ipairs(newModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                part.CanCollide = true
            end
        end
        
        -- Ajouter les attributs pour le système
        newModel:SetAttribute("CampsiteObjectId", def.Id)
        newModel:SetAttribute("UpgradeLevel", 1)
        newModel:SetAttribute("IsDefaultCampsiteObject", true)
        newModel:SetAttribute("IsLocked", true)
        
        if ownerPlayer then
            newModel:SetAttribute("OwnerUserId", ownerPlayer.UserId)
        end
        
        print("[Paradis][CampsiteDefaults] ✅ Objet créé:", def.Id, "à la position", targetCFrame.Position)
    end
    
    print("[Paradis][CampsiteDefaults] ✅ Kit de camping généré avec succès pour", plotModel.Name)
    return true
    --]]
end

-- Fonction pour vérifier si un objet fait partie du kit de camping par défaut
function CampsiteDefaultsService.IsDefaultCampsiteObject(model)
    if not model then return false end
    
    -- Vérifier si c'est dans le dossier CampsiteObjects
    local parent = model.Parent
    if parent and parent.Name == "CampsiteObjects" then
        return true
    end
    
    -- Vérifier l'attribut
    return model:GetAttribute("IsDefaultCampsiteObject") == true
end

-- Fonction pour vérifier si un objet est verrouillé
function CampsiteDefaultsService.IsLockedObject(model)
    if not model then return false end
    return model:GetAttribute("IsLocked") == true
end

-- Exposer l'API au reste du jeu (scripts et modules)
shared.ParadisCampsiteDefaultsService = CampsiteDefaultsService

return CampsiteDefaultsService
