# 🧪 Guide de Test - Système de Progression Paradise

## 🚀 Démarrage Rapide

### Test 1 : Attribution Automatique de Parcelle
1. Ouvrir le jeu dans Roblox Studio
2. Cliquer sur "Play" (F5)
3. **Vérification** :
   - Une parcelle devrait être attribuée automatiquement après 2 secondes
   - Une planquette devrait apparaître avec "Parcelle de [VotreNom]"
   - Un Trailer_1 devrait être visible sur la parcelle

### Test 2 : Système de Feu
1. Chercher l'objet "Campfire" dans Workspace
2. Ouvrir ses propriétés → Trouver "FireLevel" (NumberValue)
3. **Test seuil critique** :
   - Mettre FireLevel.Value = 50 → Feu actif (revenu normal)
   - Attendre 5 secondes → Vérifier que de l'argent est ajouté
   - Mettre FireLevel.Value = 5 → Feu presque éteint
   - Attendre 5 secondes → Vérifier que AUCUN argent n'est ajouté

### Test 3 : Achievements via Mini-Jeux

#### Pêche
1. Aller à la zone de pêche
2. Utiliser ProximityPrompt pour pêcher
3. Attraper un poisson rare ou légendaire
4. **Console serveur** :
```lua
local player = game.Players:GetChildren()[1]
local ps = shared.PlayerProgressService
print("Rare fish:", ps.GetStat(player, "RareFishCaught"))
print("Has achievement:", ps.HasAchievement(player, "CaughtRareFish"))
```

#### Labyrinthe
1. Trouver l'entrée du labyrinthe
2. Compléter le labyrinthe
3. **Console serveur** :
```lua
local player = game.Players:GetChildren()[1]
print("Mazes:", ps.GetStat(player, "MazesCompleted"))
print("Has achievement:", ps.HasAchievement(player, "CompletedMaze"))
```

#### Balançoire
1. S'asseoir sur la balançoire
2. Faire 10 tours complets (360°)
3. **Console serveur** :
```lua
local player = game.Players:GetChildren()[1]
print("Loops:", ps.GetStat(player, "SwingLoops"))
print("Has achievement:", ps.HasAchievement(player, "CompletedSwingLoops"))
```

#### Coupe de Bois
1. Trouver un arbre (LogNode)
2. Couper 50 bûches au total
3. **Console serveur** :
```lua
local player = game.Players:GetChildren()[1]
print("Logs cut:", ps.GetStat(player, "LogsCut"))
print("Has achievement:", ps.HasAchievement(player, "WoodMaster"))
```

### Test 4 : Achat d'Objets

#### Via Console Serveur (Rapide)
```lua
local player = game.Players:GetChildren()[1]
local ps = shared.PlayerProgressService
local cs = shared.CampingProgressionService
local es = shared.ParadisEconomyService

-- Donner de l'argent
es.AddCash(player, 10000)

-- Débloquer un achievement manuellement
ps.UnlockAchievement(player, "CaughtRareFish")

-- Acheter Trailer_2
local success, msg = cs.PurchaseItem(player, "Trailer_2")
print("Achat:", success, msg)

-- Vérifier l'income
print("Income total:", ps.GetTotalIncomePerTick(player), "$/tick")
```

#### Via UI Client
1. Cliquer sur le bouton "🏕️ Camping" (côté droit de l'écran)
2. Parcourir les objets disponibles
3. Cliquer "ACHETER" sur un objet
4. **Vérifications** :
   - L'argent devrait être déduit
   - L'objet devrait apparaître visuellement sur la parcelle
   - Le revenu par tick devrait augmenter

### Test 5 : Income Automatique

#### Configuration du Test
```lua
-- Console serveur
local player = game.Players:GetChildren()[1]
local ps = shared.PlayerProgressService
local es = shared.ParadisEconomyService

-- Setup: donner argent et achievements
es.AddCash(player, 10000)
ps.UnlockAchievement(player, "CaughtRareFish")
ps.UnlockAchievement(player, "CaughtLegendaryFish")
ps.UnlockAchievement(player, "CompletedMaze")

-- Acheter plusieurs objets
local cs = shared.CampingProgressionService
cs.PurchaseItem(player, "Trailer_2") -- +15$/tick
cs.PurchaseItem(player, "BBQ_1")     -- +2$/tick
cs.PurchaseItem(player, "PicnicTable_1") -- +1$/tick

-- Income total attendu: 18$/tick
print("Income:", ps.GetTotalIncomePerTick(player))
```

#### Vérification
1. Noter le cash actuel du joueur
2. Attendre 5 secondes (1 tick)
3. Vérifier que le cash a augmenté de ~18$
4. Répéter plusieurs fois

#### Test avec Feu Éteint
```lua
-- Console serveur
local campfire = workspace.Campfire
campfire.FireLevel.Value = 5 -- Sous le seuil

-- Attendre 5 secondes
-- Le cash NE DEVRAIT PAS augmenter

-- Rallumer
campfire.FireLevel.Value = 50

-- Attendre 5 secondes
-- Le cash DEVRAIT augmenter normalement
```

### Test 6 : Progression Complète

#### Scénario de Progression Typique
```lua
-- Console serveur - Simulation d'une session complète
local player = game.Players:GetChildren()[1]
local ps = shared.PlayerProgressService
local cs = shared.CampingProgressionService
local es = shared.ParadisEconomyService

-- 1. Démarrage (Trailer_1 gratuit)
print("=== DÉMARRAGE ===")
print("Income:", ps.GetTotalIncomePerTick(player), "$/tick") -- 5

-- 2. Jouer aux mini-jeux
print("\n=== MINI-JEUX ===")
ps.IncrementStat(player, "RareFishCaught", 1) -- Auto-unlock CaughtRareFish
es.AddCash(player, 500)

-- 3. Premier upgrade
print("\n=== PREMIER UPGRADE ===")
cs.PurchaseItem(player, "Trailer_2")
print("Income:", ps.GetTotalIncomePerTick(player), "$/tick") -- 15

-- 4. Plus de mini-jeux
print("\n=== PLUS DE MINI-JEUX ===")
ps.IncrementStat(player, "LegendaryFishCaught", 1)
ps.IncrementStat(player, "MazesCompleted", 1)
es.AddCash(player, 2000)

-- 5. Upgrade niveau 3
print("\n=== UPGRADE NIVEAU 3 ===")
cs.PurchaseItem(player, "Trailer_3")
print("Income:", ps.GetTotalIncomePerTick(player), "$/tick") -- 40

-- 6. Acheter autres objets
print("\n=== DIVERSIFICATION ===")
es.AddCash(player, 5000)
cs.PurchaseItem(player, "BBQ_1")
cs.PurchaseItem(player, "PicnicTable_1")
cs.PurchaseItem(player, "TreesDecor_1")
print("Income final:", ps.GetTotalIncomePerTick(player), "$/tick") -- ~44

-- 7. Vérifier les objets sur la parcelle
print("\n=== OBJETS POSSÉDÉS ===")
local owned = ps.GetAllOwnedItems(player)
for cat, itemId in pairs(owned) do
    print(cat, "→", itemId)
end
```

### Test 7 : Prérequis et Blocages

#### Test Blocage sans Achievement
```lua
local player = game.Players:GetChildren()[1]
local cs = shared.CampingProgressionService
local es = shared.ParadisEconomyService

-- Donner beaucoup d'argent
es.AddCash(player, 100000)

-- Essayer d'acheter Trailer_2 SANS l'achievement
local success, msg = cs.PurchaseItem(player, "Trailer_2")
print("Sans achievement:", success, msg) -- false, "Achievement manquant"

-- Débloquer l'achievement
ps.UnlockAchievement(player, "CaughtRareFish")

-- Réessayer
success, msg = cs.PurchaseItem(player, "Trailer_2")
print("Avec achievement:", success, msg) -- true, "Acheté: Roulotte familiale"
```

#### Test Progression Non Linéaire
```lua
-- Essayer d'acheter Trailer_3 sans avoir Trailer_2
local success, msg = cs.PurchaseItem(player, "Trailer_3")
print("Saut de niveau:", success, msg) -- false, "Vous devez d'abord avoir le niveau 2"
```

## 🎯 Checklist de Validation

### ✅ Fonctionnalités de Base
- [ ] Parcelle attribuée automatiquement au join
- [ ] Planquette affiche le nom du joueur
- [ ] Trailer_1 présent sur la parcelle
- [ ] Income de base fonctionne (+5$/tick)

### ✅ Système de Feu
- [ ] FireLevel diminue avec le temps
- [ ] Déposer des bûches augmente FireLevel
- [ ] FireLevel ≤ 10 → Pas de revenu
- [ ] FireLevel > 10 → Revenu normal

### ✅ Achievements
- [ ] Pêche rare → CaughtRareFish ✅
- [ ] Pêche légendaire → CaughtLegendaryFish ✅
- [ ] Labyrinthe → CompletedMaze ✅
- [ ] 10 loops balançoire → CompletedSwingLoops ✅
- [ ] 50 bûches → WoodMaster ✅

### ✅ Achats
- [ ] Achat bloqué sans argent
- [ ] Achat bloqué sans achievement
- [ ] Achat bloqué si niveau précédent manquant
- [ ] Achat réussi déduit l'argent
- [ ] Achat place l'objet visuellement
- [ ] Income augmente après achat

### ✅ Income Automatique
- [ ] Tick toutes les 5 secondes
- [ ] Argent ajouté selon les objets possédés
- [ ] Income = 0 si feu éteint
- [ ] Income reprend si feu rallumé

## 🐛 Débogage

### Problème : Pas de parcelle attribuée
**Solution** :
```lua
-- Console serveur
local player = game.Players:GetChildren()[1]
local plotService = shared.ParadisPlotService
local plots = plotService.GetAllPlots()

-- Forcer l'attribution
for _, plot in ipairs(plots) do
    if not plot.OwnerUserId then
        plotService.ClaimPlot(player, plot.Id)
        break
    end
end
```

### Problème : Pas d'income
**Vérifications** :
1. Vérifier FireLevel : `workspace.Campfire.FireLevel.Value`
2. Vérifier objets possédés : `ps.GetAllOwnedItems(player)`
3. Vérifier income calculé : `ps.GetTotalIncomePerTick(player)`
4. Vérifier EconomyService : `shared.ParadisEconomyService`

### Problème : Achievement ne se débloque pas
```lua
-- Console serveur
local player = game.Players:GetChildren()[1]
local ps = shared.PlayerProgressService

-- Voir toutes les stats
print("Stats:", ps.GetStat(player, "RareFishCaught"))
print("Stats:", ps.GetStat(player, "LegendaryFishCaught"))
print("Stats:", ps.GetStat(player, "MazesCompleted"))
print("Stats:", ps.GetStat(player, "SwingLoops"))
print("Stats:", ps.GetStat(player, "LogsCut"))

-- Forcer le débloquage
ps.UnlockAchievement(player, "CaughtRareFish")
```

### Problème : Objet ne s'affiche pas
**Vérifications** :
1. Le modèle existe dans `ReplicatedStorage.ConstructionObjet` ?
2. Si non, un placeholder devrait être créé automatiquement
3. Vérifier dans la parcelle : `Plot.Container.CampsiteObjects`

## 📊 Métriques de Performance

### Objets à Surveiller
- Temps d'attribution de parcelle : <2s
- Temps de tick income : ~5s ±0.5s
- Temps de placement d'objet : <1s
- Mémoire par joueur : ~10-50 KB (en mémoire)

### Commandes de Monitoring
```lua
-- Console serveur
local RunService = game:GetService("RunService")

-- Compter le nombre de ticks d'income
local tickCount = 0
local startTime = os.clock()

RunService.Heartbeat:Connect(function()
    -- Observer les prints de CampingProgressionService
end)

task.wait(60) -- Attendre 1 minute
print("Ticks en 60s:", tickCount, "attendu:", 60/5) -- Devrait être ~12
```

---

**Bon test ! 🧪**
