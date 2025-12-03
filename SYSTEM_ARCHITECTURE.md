# 🏕️ Paradise - Système de Progression BrainRock

## 📋 Vue d'ensemble

Le jeu Paradise utilise un système de progression type **BrainRock** adapté au camping. Les joueurs obtiennent automatiquement une parcelle, jouent aux mini-jeux pour gagner de l'argent et débloquer des achievements, puis améliorent leurs objets de camping qui génèrent du revenu passif.

## 🔧 Architecture Technique

### Services Principaux

#### 1. **PlayerProgressService** (`ServerScriptService/ParadisServer/`)
Gère la progression de chaque joueur :
- **Achievements** : Déblocage automatique basé sur les stats
- **Objets possédés** : Track les objets de camping par catégorie
- **Stats** : FishCaught, RareFishCaught, LegendaryFishCaught, LogsCut, MazesCompleted, SwingLoops

**Fonctions principales :**
```lua
PlayerProgressService.UnlockAchievement(player, achievementId)
PlayerProgressService.HasAchievement(player, achievementId) -> bool
PlayerProgressService.SetOwnedItem(player, category, itemId)
PlayerProgressService.GetOwnedItem(player, category) -> itemId
PlayerProgressService.IncrementStat(player, statName, amount)
PlayerProgressService.GetTotalIncomePerTick(player) -> number
```

#### 2. **CampingItemsConfig** (`ReplicatedStorage/Config/`)
Configuration de tous les objets de camping :
- **24 objets** répartis en 6 catégories
- Chaque objet a : Id, Category, Level, Cost, BaseIncome, Prerequisites
- **Categories** : Trailer (1-4), BBQ (1-3), PicnicTable (1-3), Campfire (1-3), TreesDecor (1-3), DecorRock (1-2)

**Achievements disponibles :**
- `CaughtRareFish` : 1 poisson rare pêché
- `CaughtLegendaryFish` : 1 poisson légendaire pêché
- `CompletedMaze` : 1 labyrinthe complété
- `CompletedSwingLoops` : 10 tours complets sur la balançoire
- `WoodMaster` : 50 bûches coupées

#### 3. **CampingProgressionService** (`ServerScriptService/ParadisServer/`)
Gère les achats et le revenu automatique :
- Vérifie les prérequis (argent + achievements)
- Valide la progression (doit avoir niveau précédent)
- Place visuellement les objets sur les parcelles
- **Boucle d'income** : distribue l'argent toutes les 5 secondes
- **Vérification du feu** : Si FireLevel ≤ 10 → pas de revenu pour personne

**Remote Event :**
```lua
ReplicatedStorage.Remotes.CampingProgressionRemote
Action: "PurchaseItem", itemId
```

#### 4. **CampfireService** (`ServerScriptService/Woodcutting/`)
Système de feu de camp central :
- **FireLevel** (NumberValue dans Workspace.Campfire)
- Diminue de 2 toutes les 10 secondes
- Alimenté par les joueurs avec des bûches (+20 par bûche)
- **Seuil critique** : FireLevel ≤ 10 → feu presque éteint, pas de revenu

#### 5. **PlotService** (`ServerScriptService/ParadisServer/`)
Gestion des parcelles :
- Attribution automatique au join (2s de délai)
- **Planquette avec nom** : Affiche "Parcelle de [Nom]"
- ProximityPrompt pour réserver manuellement (désactivé si auto-claim)

## 🎮 Intégration Mini-Jeux

### 🎣 Pêche (FishingSystem.server.lua)
**Hook d'achievement** (ligne ~540) :
```lua
-- Après succès du mini-game
if PlayerProgressService then
    PlayerProgressService.IncrementStat(player, "FishCaught", 1)
    
    if fishInfo.name == "legendaire" then
        PlayerProgressService.IncrementStat(player, "LegendaryFishCaught", 1)
    elseif fishInfo.name == "rare" then
        PlayerProgressService.IncrementStat(player, "RareFishCaught", 1)
    end
end
```

### 🧩 Labyrinthe (MazeRewardService.server.lua)
**Hook d'achievement** (ligne ~148) :
```lua
-- Après récompense donnée
if PlayerProgressService then
    PlayerProgressService.IncrementStat(player, "MazesCompleted", 1)
end
```

### 🪓 Coupe de Bois (WoodcuttingFeedback.server.lua)
**Hook d'achievement** (ligne ~135) :
```lua
-- Quand des bûches sont obtenues
if PlayerProgressService then
    PlayerProgressService.IncrementStat(player, "LogsCut", logsToGive)
end
```

### 🎢 Balançoire (SwingLoops.server.lua)
**Hook d'achievement** (ligne ~87) :
```lua
-- Après chaque tour complet
if PlayerProgressService then
    PlayerProgressService.IncrementStat(player, "SwingLoops", 1)
end
```

## 🔥 Système de Feu de Camp

### Fonctionnement
1. **FireLevel** initial : 20
2. **Diminution** : -2 toutes les 10 secondes
3. **Alimentation** : +20 par bûche déposée
4. **Seuil critique** : ≤ 10 (feu presque éteint)
5. **Impact** : Si FireLevel ≤ 10 → **TOUS les joueurs arrêtent de gagner du revenu passif**

### Vérification dans CampingProgressionService
```lua
local function isCampfireActive()
    local campfire = game.Workspace:FindFirstChild("Campfire")
    if not campfire then return false end
    
    local fireLevel = campfire:FindFirstChild("FireLevel")
    if not fireLevel then return false end
    
    return fireLevel.Value > 10 -- Seuil critique
end
```

### Boucle d'Income
```lua
task.spawn(function()
    while true do
        task.wait(5) -- Toutes les 5 secondes
        
        local fireActive = isCampfireActive()
        
        for _, player in ipairs(Players:GetPlayers()) do
            local income = PlayerProgressService.GetTotalIncomePerTick(player)
            if income > 0 and fireActive then
                EconomyService.AddCash(player, income)
            end
        end
    end
end)
```

## 🏗️ Placement Visuel

### Structure des Parcelles
```
Plot.Container
└── CampsiteObjects/ (créé par CampsiteDefaultsService)
    ├── Trailer (Model avec attributs)
    ├── BBQ (Model avec attributs)
    ├── PicnicTable (Model avec attributs)
    └── etc.
```

### Attributs des Objets
```lua
model:SetAttribute("CampsiteObjectId", category)
model:SetAttribute("ItemId", itemData.Id)
model:SetAttribute("ItemLevel", itemData.Level)
model:SetAttribute("IsDefaultCampsiteObject", true)
model:SetAttribute("IsLocked", true)
model:SetAttribute("OwnerUserId", player.UserId)
```

### Slots par Catégorie (CampingItemsConfig)
```lua
Categories = {
    Trailer = { SlotName = "TrailerSlot", DefaultOffset = CFrame.new(0, 0, -8) },
    BBQ = { SlotName = "BBQSlot", DefaultOffset = CFrame.new(-6, 0, 2) },
    PicnicTable = { SlotName = "PicnicTableSlot", DefaultOffset = CFrame.new(6, 0, 2) },
    Campfire = { SlotName = "CampfireSlot", DefaultOffset = CFrame.new(0, 0, 5) },
    -- etc.
}
```

## 📊 Progression Typique

### Phase 1 : Démarrage
1. Joueur join → parcelle auto-attribuée
2. Trailer_1 gratuit (objet de départ)
3. Revenu : +5$/tick (si feu actif)

### Phase 2 : Premiers Achievements
1. Jouer à la pêche → Attraper 1 poisson rare → `CaughtRareFish` ✅
2. Acheter Trailer_2 (500$, requires CaughtRareFish) → +15$/tick

### Phase 3 : Accumulation
1. Jouer au labyrinthe → `CompletedMaze` ✅
2. Pêcher légendaire → `CaughtLegendaryFish` ✅
3. Acheter Trailer_3 (2000$, requires les 2 achievements) → +40$/tick

### Phase 4 : Optimisation
1. Acheter tous les objets de base (BBQ_1, PicnicTable_1, etc.)
2. Total income : ~20$/tick = 240$/minute
3. Couper 50 bûches → `WoodMaster` ✅
4. 10 tours balançoire → `CompletedSwingLoops` ✅

### Phase 5 : Endgame
1. Tous les achievements débloqués
2. Acheter Trailer_4 (5000$) → +100$/tick
3. Income maximal : ~200$/tick = 2400$/minute

## 🧪 Tests

### Tester le Système Complet

1. **Test Achievements** :
```lua
-- Dans la console serveur
local player = game.Players:GetChildren()[1]
local PlayerProgressService = shared.PlayerProgressService

PlayerProgressService.IncrementStat(player, "RareFishCaught", 1)
-- Devrait débloquer CaughtRareFish automatiquement

PlayerProgressService.HasAchievement(player, "CaughtRareFish")
-- Devrait retourner true
```

2. **Test Achat** :
```lua
-- Via RemoteEvent côté client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage.Remotes.CampingProgressionRemote

remote:FireServer("PurchaseItem", "Trailer_2")
```

3. **Test FireLevel** :
```lua
-- Dans la console serveur
local campfire = workspace.Campfire
local fireLevel = campfire.FireLevel

fireLevel.Value = 5 -- Mettre sous le seuil
-- Attendre 5s → Aucun revenu distribué

fireLevel.Value = 50 -- Remettre au-dessus
-- Attendre 5s → Revenus distribués normalement
```

4. **Test Income** :
```lua
-- Vérifier le revenu total d'un joueur
local player = game.Players:GetChildren()[1]
local income = PlayerProgressService.GetTotalIncomePerTick(player)
print("Income:", income, "$/tick")
```

## 📁 Fichiers Créés/Modifiés

### ✅ Fichiers Existants (Déjà Créés)
- ✅ `PlayerProgressService.lua` - Gestion achievements et stats
- ✅ `CampingItemsConfig.lua` - Configuration des 24 objets
- ✅ `CampingProgressionService.lua` - Achats et income automatique
- ✅ `CampfireService.server.lua` - Système de feu
- ✅ `PlotService.server.lua` - Parcelles avec planquettes

### ✅ Fichiers Modifiés (Hooks Ajoutés)
- ✅ `FishingSystem.server.lua` - Hook CaughtRareFish/LegendaryFish
- ✅ `MazeRewardService.server.lua` - Hook CompletedMaze
- ✅ `WoodcuttingFeedback.server.lua` - Hook LogsCut
- ✅ `SwingLoops.server.lua` - Hook SwingLoops

### ✅ Modifications Finales
- ✅ `CampingProgressionService.lua` - Ajout vérification feu pour income
- ✅ Tutoriel mis à jour dans `BuildScreenGui.lua`
- ✅ UI client `CampingProgressionUI.lua` créée

## 🎯 Résumé du Flux

```
Joueur join
    ↓
Parcelle auto-attribuée (PlotService)
    ↓
Planquette "Parcelle de [Nom]" apparaît
    ↓
Trailer_1 gratuit placé (CampsiteDefaultsService)
    ↓
Revenu passif démarre (+5$/tick si feu actif)
    ↓
Joueur joue mini-jeux → Gagne argent + achievements
    ↓
Ouvre UI Camping → Achète/améliore objets
    ↓
Objets placés visuellement + income augmente
    ↓
Boucle : Mini-jeux → Argent → Achievements → Objets → Plus d'income
    ↓
Entretien du feu (coupe de bois) → Maintient l'income actif
```

## ⚠️ Points Importants

1. **Feu Critique** : Si personne ne nourrit le feu → income = 0 pour TOUS
2. **Progression Obligatoire** : Impossible d'acheter Trailer_3 sans Trailer_2
3. **Achievements Auto** : Se débloquent automatiquement via IncrementStat()
4. **Sauvegarde** : Pour l'instant en mémoire, DataStore à implémenter plus tard
5. **Modèles** : Si modèle introuvable → placeholder automatique créé

## 🚀 Prochaines Étapes (Futures)

1. **DataStore** : Sauvegarder progression entre sessions
2. **UI Améliorée** : Interface plus jolie pour achats
3. **Modèles 3D** : Remplacer les placeholders par vrais modèles
4. **Notifications** : Alertes visuelles quand feu faible
5. **Leaderboard** : Classement par income total
6. **Achievements Avancés** : Plus de tiers (10, 50, 100 loops, etc.)

---

**Développé pour Paradise - Système de progression camping inspiré de BrainRock** 🏕️
