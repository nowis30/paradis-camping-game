# 📦 Comment remplir l'inventaire du Pro Shop

## 🏠 Créer la cabane Pro Shop dans Roblox Studio

### Option 1 : Modèle simple (recommandé)
1. Dans **Workspace**, crée un **Model** nommé `ProShop` ou `ProShop_Cabin`
2. À l'intérieur, ajoute des **Parts** pour construire ta cabane :
   - Plancher : `Part` de 20×1×20 studs
   - Murs : 4 `Parts` de 20×10×1 studs
   - Toit : `WedgePart` ou `Part` incliné
   - Enseigne : `Part` avec un `SurfaceGui` contenant "🎣 PRO SHOP"
3. **Définis une PrimaryPart** :
   - Sélectionne le Model `ProShop`
   - Dans Propriétés, trouve `PrimaryPart`
   - Choisis le plancher ou un mur principal
4. **Le ProximityPrompt sera ajouté automatiquement** par le script client quand tu testes

### Option 2 : Modèle détaillé
1. Crée un **Model** nommé `ProShop_Cabin`
2. Construis une cabane avec :
   - Structure (murs, toit, porte)
   - Décoration intérieure (comptoir, étagères avec cannes à pêche)
   - Éclairage (`PointLight` dans des lampes)
3. Ajoute une PrimaryPart (comme ci-dessus)
4. Le script détectera automatiquement le modèle

---

## 📍 Placement recommandé
- **Près du lac** : les joueurs viennent pêcher puis acheter du matériel
- **Accessible facilement** : pas caché derrière des arbres
- **Position** : par exemple `Vector3.new(50, 0, 100)` (ajuste selon ton terrain)

---

## 🔧 Structure minimale dans l'Explorer

```
Workspace
└── ProShop (Model)
    ├── Floor (Part) ← PrimaryPart
    ├── WallFront (Part)
    ├── WallBack (Part)
    ├── WallLeft (Part)
    ├── WallRight (Part)
    └── Roof (WedgePart)
```

---

## 🎣 Vérification
Une fois le modèle créé :
1. Lance le jeu (F5)
2. Approche-toi de la cabane
3. Tu devrais voir apparaître : **"[E] Ouvrir le Pro Shop 🎣 Pro Shop"**
4. Appuie sur **E** pour ouvrir l'interface

---

## 🐟 Inventaire de poissons - Comment ça marche

### Remplissage automatique
L'inventaire de poissons se remplit **automatiquement** quand tu pêches :
- Chaque poisson capturé est ajouté au stock
- Message : `"Common (+10$) [5 en stock]"`
- Visible dans la barre de statut du Pro Shop : `🐟 Stock: C:5 R:2 L:0`

### Utilisation comme appât
1. Va au **Pro Shop**
2. Dans la section **🪱 Appâts**, tu verras :
   - **Poisson Common (appât)** : `🐟 Stock: X` (si tu en as)
   - **Poisson rare (appât)** : `🐟 Stock: X` (si tu en as)
3. Clique sur l'appât poisson pour l'équiper
4. Cela consomme **1 poisson** de ton stock et te donne **1 utilisation** d'appât amélioré

### Stratégie
- **Common** → utilise comme appât pour attraper des **rare**
- **rare** → utilise comme appât pour attraper des **legendaire**
- **legendaire** → garde-les (récompense 100$) ou utilise-les si tu veux maximiser tes chances futures

---

## 🛠️ Script de génération (optionnel)

Si tu veux générer la cabane automatiquement au lancement, ajoute ce code dans `CampingWorldGenerator.lua` :

```lua
local function createProShop()
    local proShop = Instance.new("Model")
    proShop.Name = "ProShop_Cabin"
    
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(20, 1, 20)
    floor.Position = Vector3.new(50, 0.5, 100) -- Position à ajuster
    floor.Anchored = true
    floor.BrickColor = BrickColor.new("Dark stone grey")
    floor.Material = Enum.Material.Wood
    floor.Parent = proShop
    
    proShop.PrimaryPart = floor
    
    -- Ajoute murs, toit, etc. ici
    
    proShop.Parent = workspace
    print("[WorldGen] Pro Shop créé")
end

-- Appelle après la génération du terrain
createProShop()
```

---

## ✅ Résumé
1. **Crée un Model** nommé `ProShop` dans Workspace
2. **Ajoute des Parts** pour former une cabane
3. **Définis la PrimaryPart**
4. Le **ProximityPrompt** s'ajoute automatiquement
5. L'**inventaire de poissons** se remplit en pêchant (automatique)
6. **Utilise les poissons** capturés comme appâts améliorés dans le Pro Shop
