# 🐟 Guide : Ajouter de beaux poissons à la pêche

## 📦 Structure ReplicatedStorage

Créez cette structure dans **ReplicatedStorage** :

```
ReplicatedStorage
└── FishModels
    ├── Common
    │   ├── Perche (Model)
    │   ├── Truite (Model)
    │   └── PoissonChat (Model)
    ├── Rare
    │   ├── Saumon (Model)
    │   ├── Brochet (Model)
    │   └── Carpe (Model)
    └── Legendaire
        ├── Espadon (Model)
        ├── Requin (Model)
        └── PoissonLune (Model)
```

## 🎨 Méthode 1 : Utiliser le Toolbox Roblox

1. Ouvrez **Roblox Studio**
2. Ouvrez la **Toolbox** : `View → Toolbox`
3. Recherchez : `"fish mesh"`, `"poisson"`, `"sea creatures"`
4. Trouvez des modèles gratuits qui vous plaisent
5. **Insérez-les dans Workspace** pour les tester
6. **Déplacez-les dans ReplicatedStorage/FishModels/**
7. Organisez-les dans les bons dossiers (Common/Rare/Legendaire)

### Modèles recommandés à chercher :
- "Animated Fish"
- "Low Poly Fish"
- "Cartoon Fish"
- "Realistic Fish"

## 🛠️ Méthode 2 : Créer vos propres poissons

### Script pour générer des poissons simples et colorés :

1. **Ouvrez Roblox Studio**
2. **Copiez ce script** dans Command Bar (View → Command Bar)
3. **Exécutez-le** pour créer automatiquement tous les poissons

```lua
-- Script à exécuter dans Command Bar pour créer les poissons

local RS = game:GetService("ReplicatedStorage")

-- Créer le dossier principal
local fishModels = RS:FindFirstChild("FishModels") or Instance.new("Folder")
fishModels.Name = "FishModels"
fishModels.Parent = RS

-- Fonction pour créer un poisson
local function createFish(name, color, size, meshId)
    local model = Instance.new("Model")
    model.Name = name
    
    -- Corps du poisson
    local body = Instance.new("MeshPart")
    body.Name = "Body"
    body.Size = size
    body.Color = color
    body.Material = Enum.Material.SmoothPlastic
    body.CanCollide = false
    body.Anchored = true
    
    -- Utiliser un mesh de poisson si disponible
    if meshId then
        body.MeshId = meshId
    end
    
    -- Ajouter de la brillance
    local surfaceGui = Instance.new("SurfaceAppearance")
    surfaceGui.Parent = body
    
    body.Parent = model
    model.PrimaryPart = body
    
    -- Nageoires
    local fin1 = Instance.new("Part")
    fin1.Name = "FinLeft"
    fin1.Size = Vector3.new(size.X * 0.3, size.Y * 0.1, size.Z * 0.4)
    fin1.Color = color
    fin1.Material = Enum.Material.SmoothPlastic
    fin1.CanCollide = false
    fin1.Anchored = true
    fin1.CFrame = body.CFrame * CFrame.new(-size.X * 0.4, 0, 0)
    fin1.Parent = model
    
    local fin2 = fin1:Clone()
    fin2.Name = "FinRight"
    fin2.CFrame = body.CFrame * CFrame.new(size.X * 0.4, 0, 0)
    fin2.Parent = model
    
    -- Queue
    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(size.X * 0.6, size.Y * 0.8, size.Z * 0.2)
    tail.Color = color
    tail.Material = Enum.Material.SmoothPlastic
    tail.CanCollide = false
    tail.Anchored = true
    tail.CFrame = body.CFrame * CFrame.new(0, 0, size.Z * 0.6)
    tail.Parent = model
    
    -- Yeux
    local eye1 = Instance.new("Part")
    eye1.Name = "EyeLeft"
    eye1.Shape = Enum.PartType.Ball
    eye1.Size = Vector3.new(size.X * 0.15, size.X * 0.15, size.X * 0.15)
    eye1.Color = Color3.fromRGB(255, 255, 255)
    eye1.Material = Enum.Material.Neon
    eye1.CanCollide = false
    eye1.Anchored = true
    eye1.CFrame = body.CFrame * CFrame.new(-size.X * 0.25, size.Y * 0.2, -size.Z * 0.4)
    eye1.Parent = model
    
    local eye2 = eye1:Clone()
    eye2.Name = "EyeRight"
    eye2.CFrame = body.CFrame * CFrame.new(size.X * 0.25, size.Y * 0.2, -size.Z * 0.4)
    eye2.Parent = model
    
    return model
end

-- POISSONS COMMUNS (petits, couleurs ternes)
local commonFolder = Instance.new("Folder")
commonFolder.Name = "Common"
commonFolder.Parent = fishModels

createFish("Perche", Color3.fromRGB(120, 140, 100), Vector3.new(1, 0.6, 2)).Parent = commonFolder
createFish("Truite", Color3.fromRGB(180, 160, 140), Vector3.new(0.9, 0.5, 1.8)).Parent = commonFolder
createFish("PoissonChat", Color3.fromRGB(100, 90, 80), Vector3.new(1.1, 0.7, 2.2)).Parent = commonFolder

-- POISSONS RARES (moyens, couleurs vives)
local rareFolder = Instance.new("Folder")
rareFolder.Name = "Rare"
rareFolder.Parent = fishModels

createFish("Saumon", Color3.fromRGB(255, 140, 120), Vector3.new(1.3, 0.8, 2.8)).Parent = rareFolder
createFish("Brochet", Color3.fromRGB(100, 180, 100), Vector3.new(1.4, 0.7, 3.2)).Parent = rareFolder
createFish("Carpe", Color3.fromRGB(220, 180, 100), Vector3.new(1.5, 1, 3)).Parent = rareFolder

-- POISSONS LÉGENDAIRES (grands, couleurs éclatantes)
local legendaireFolder = Instance.new("Folder")
legendaireFolder.Name = "Legendaire"
legendaireFolder.Parent = fishModels

createFish("Espadon", Color3.fromRGB(50, 100, 200), Vector3.new(2, 1.2, 5)).Parent = legendaireFolder
createFish("Requin", Color3.fromRGB(80, 90, 110), Vector3.new(2.5, 1.5, 6)).Parent = legendaireFolder
createFish("PoissonLune", Color3.fromRGB(255, 200, 50), Vector3.new(3, 3, 3)).Parent = legendaireFolder

print("✅ Tous les poissons ont été créés dans ReplicatedStorage/FishModels")
```

## 🎬 Méthode 3 : Utiliser des Mesh IDs professionnels

Remplacez les MeshIds dans le script ci-dessus par ces IDs gratuits :

```lua
-- Mesh IDs de poissons Roblox
local fishMeshes = {
    Trout = "rbxassetid://5065067523",      -- Truite
    Bass = "rbxassetid://5065067715",       -- Bar
    Salmon = "rbxassetid://5065067863",     -- Saumon
    Shark = "rbxassetid://1090398809",      -- Requin
    Swordfish = "rbxassetid://5065068034",  -- Espadon
}
```

## 🔧 Test en jeu

Une fois les poissons créés :

1. **Compilez avec Rojo** : `rojo build --output "ParadisDesParcelles.rbxlx"`
2. **Ouvrez dans Roblox Studio**
3. **Vérifiez** que `ReplicatedStorage/FishModels` existe
4. **Testez la pêche** - les poissons devraient apparaître aléatoirement
5. **Ajustez les tailles/couleurs** selon vos préférences

## 🎨 Personnalisation

### Ajouter des effets visuels :

```lua
-- Ajouter un effet de brillance
local sparkles = Instance.new("Sparkles")
sparkles.SparkleColor = Color3.fromRGB(100, 200, 255)
sparkles.Parent = body

-- Ajouter une traînée de particules
local trail = Instance.new("Trail")
trail.Color = ColorSequence.new(color)
trail.Lifetime = 0.5
-- etc.
```

### Ajouter des animations :

Les poissons peuvent être animés en ajoutant un script dans le modèle qui fait bouger la queue et les nageoires.

## ⚙️ Configuration actuelle

Votre système utilise 3 catégories :
- **Common** : 50% de chance, récompense 10$
- **Rare** : 35% de chance, récompense 25$
- **Legendaire** : 15% de chance, récompense 100$

Le système choisit aléatoirement un modèle dans le dossier correspondant.

## 🎁 Assets recommandés (Toolbox)

Recherchez ces créateurs sur le Toolbox :
- "Low Poly Fish Pack"
- "Animated Sea Creatures"
- "Cartoon Ocean Animals"
- "Fish Collection Free"

## 📝 Notes importantes

- Assurez-vous que chaque Model a une **PrimaryPart** définie
- Les poissons doivent être **Anchored = false** ou **CanCollide = false**
- Gardez les modèles **légers** (peu de triangles) pour les performances
- Testez que les poissons s'affichent bien à la fin de la pêche

Bon ajout de poissons ! 🐟✨
