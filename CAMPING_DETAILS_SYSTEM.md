# Système de Détails du Camping

## 📋 Vue d'ensemble

Le nouveau système d'interaction avec les campings remplace l'ancienne interface de construction (`BuildScreenGui` et `BuildClient`). Maintenant, **chaque pancarte devant une parcelle** devient le point central d'interaction pour le joueur.

## 🎯 Fonctionnalités

### 1. Pancartes Interactives
- Chaque parcelle possédée affiche "**Camping de [NomJoueur]**" sur sa pancarte
- Un **ProximityPrompt** apparaît quand le joueur approche (uniquement pour les parcelles possédées)
- Appuyer sur **E** ouvre l'interface détaillée du camping

### 2. Interface des Détails du Camping
L'interface (`CampingDetailsGui`) affiche :
- **Titre** : Nom du camping et du propriétaire
- **Revenue** : Montant d'argent généré par tick (ex: "+45 $ / tick")
- **Argent disponible** : Cash actuel du joueur
- **Objets possédés** : Liste de tous les objets de camping avec leur niveau et income individuel
- **Améliorations disponibles** : Liste des prochains upgrades possibles pour chaque catégorie

### 3. Système d'Amélioration
Pour chaque amélioration disponible, l'interface montre :
- **Nom et niveau** de l'objet
- **Income** qu'il va générer
- **Coût** en argent
- **Achievements requis** avec indicateur ✅/❌
- **Bouton "Améliorer"** :
  - Vert et actif si toutes les conditions sont remplies
  - Gris et désactivé avec indication du blocage (🔒 Succès ou 🔒 Argent)

## 📁 Architecture des Fichiers

### Fichiers créés/modifiés

#### ✨ Nouveau système

**1. Remotes (Communication client-serveur)**
```
src/ReplicatedStorage/Remotes/CampingDetailsRemotes.lua
```
- `GetCampingDetails` (RemoteFunction) : Récupérer les détails du camping
- `RequestPurchaseItem` (RemoteEvent) : Demander l'achat d'un item
- `CampingDetailsUpdated` (RemoteEvent) : Notifier le client d'une mise à jour

**2. Service Serveur**
```
src/ServerScriptService/ParadisServer/CampingDetailsService.server.lua
```
- Gère les requêtes de détails du camping
- Agrège les données de plusieurs services (PlayerProgress, Economy, CampingProgression)
- Traite les demandes d'achat et notifie les clients

**3. Interface Client**
```
src/StarterGui/ParadisGui/CampingDetailsGui.lua
```
- Création de l'interface graphique
- Frame principal avec titre, income, cash, listes scrollables
- Design moderne avec coins arrondis et couleurs cohérentes

**4. Script Client**
```
src/StarterPlayer/StarterPlayerScripts/CampingDetailsClient.client.lua
```
- Connecte les ProximityPrompts aux interactions joueur
- Ouvre/ferme l'interface
- Remplit l'interface avec les données du serveur
- Gère les clics sur les boutons d'amélioration
- Rafraîchit automatiquement après un achat

#### ♻️ Fichiers modifiés

**5. PlotService (Modification)**
```
src/ServerScriptService/ParadisServer/PlotService.server.lua
```
- Ajout de la création du ProximityPrompt dans `ensureOwnerSign()`
- Modification de `updateSignDisplay()` pour gérer l'activation du prompt et changer le texte en "Camping de [Nom]"
- Ajout des attributs `PlotId` et `OwnerUserId` au prompt

#### ⛔ Ancien système (désactivé)

**6. BuildClient (Désactivé)**
```
src/StarterPlayer/StarterPlayerScripts/BuildClient.client.lua
```
- Ajout d'un `return` au début pour désactiver le script
- Commentaire indiquant le remplacement par CampingDetailsClient

**7. BuildScreenGui (Désactivé)**
```
src/StarterGui/ParadisGui/BuildScreenGui.lua
```
- Ajout d'un `return` au début du module
- Commentaire indiquant le remplacement par CampingDetailsGui

## 🔄 Flux de Données

### Ouverture de l'interface

```
1. Joueur approche de sa parcelle
   ↓
2. ProximityPrompt apparaît ("Voir les détails")
   ↓
3. Joueur appuie sur E
   ↓
4. CampingDetailsClient détecte Triggered
   ↓
5. Appel GetCampingDetails:InvokeServer()
   ↓
6. CampingDetailsService collecte les données:
   - Plot du joueur (PlotService)
   - Objets possédés (PlayerProgressService)
   - Cash disponible (EconomyService)
   - Income total (calculé à partir des objets)
   - Upgrades disponibles (CampingItemsConfig + vérification des prérequis)
   ↓
7. Données retournées au client
   ↓
8. CampingDetailsClient remplit la GUI
   ↓
9. Interface s'affiche avec toutes les informations
```

### Achat d'un upgrade

```
1. Joueur clique sur bouton "Améliorer"
   ↓
2. CampingDetailsClient appelle RequestPurchaseItem:FireServer(itemId)
   ↓
3. CampingDetailsService reçoit la demande
   ↓
4. Appel à CampingProgressionService.PurchaseItem(player, itemId)
   ↓
5. Vérifications:
   - Prérequis (achievements, niveau précédent)
   - Cash suffisant
   ↓
6. Si OK:
   - Retrait du cash (EconomyService)
   - Enregistrement de l'objet possédé (PlayerProgressService)
   - Placement visuel sur la parcelle (updateItemOnPlot)
   ↓
7. CampingDetailsUpdated:FireClient(player)
   ↓
8. Client rafraîchit automatiquement l'interface
   ↓
9. Nouvelle liste d'objets/upgrades affichée
```

## 🎨 Structure de la GUI

```
CampingDetailsGui (ScreenGui)
└── MainFrame (Frame - 500x600px, centré)
    ├── CloseButton (TextButton - "✕" rouge en haut à droite)
    ├── TitleLabel (TextLabel - "Camping de [Nom]")
    ├── IncomeLabel (TextLabel - "💰 Revenue : +XX $/tick")
    ├── CashLabel (TextLabel - "💵 Argent disponible : XX $")
    ├── Separator1 (Frame - ligne de séparation)
    ├── OwnedTitleLabel (TextLabel - "📦 Objets possédés")
    ├── OwnedItemsFrame (ScrollingFrame - 120px hauteur)
    │   └── [OwnedItemElements générés dynamiquement]
    ├── Separator2 (Frame - ligne de séparation)
    ├── UpgradesTitleLabel (TextLabel - "⬆️ Améliorations disponibles")
    ├── UpgradesFrame (ScrollingFrame - 220px hauteur)
    │   └── [UpgradeElements générés dynamiquement]
    └── StatusLabel (TextLabel - messages d'erreur/succès)
```

### Élément d'objet possédé (généré dynamiquement)
```
Frame (1x30px)
└── TextLabel: "✅ Roulotte familiale (Niv. 2) - +15$/tick"
```

### Élément d'upgrade (généré dynamiquement)
```
Frame (1x90px)
├── TitleLabel: "Roulotte familiale (Niv. 2)"
├── IncomeLabel: "💰 +15$/tick"
├── AchievementsLabel: "✅ Pêcher un poisson rare"
├── CostLabel: "💵 Coût : 500 $"
└── BuyButton: "Améliorer" (vert si OK, gris si bloqué)
```

## 🔧 Services Utilisés

### Services serveur

- **PlotService** : Gestion des parcelles et pancartes
- **PlayerProgressService** : Stockage des objets possédés et achievements
- **EconomyService** : Gestion du cash
- **CampingProgressionService** : Logique d'achat et vérification des prérequis
- **CampingDetailsService** (nouveau) : Agrégation des données pour l'interface

### Configuration

- **CampingItemsConfig** : Définition des 24 objets de camping avec :
  - Catégories : Trailer, BBQ, PicnicTable, TreesGroup, DecorRock, Campfire
  - Niveaux, coûts, income
  - Prérequis (achievements, argent minimum)

## 📊 Données Retournées

### GetCampingDetails renvoie :
```lua
{
    PlayerName = "Joueur123",
    PlotId = "Plot_1",
    Cash = 1500,
    TotalIncome = 45,
    OwnedItems = {
        {
            Category = "Trailer",
            ItemId = "Trailer_2",
            Level = 2,
            DisplayName = "Roulotte familiale",
            Income = 15
        },
        -- ...
    },
    AvailableUpgrades = {
        {
            ItemId = "Trailer_3",
            Category = "Trailer",
            Level = 3,
            DisplayName = "Roulotte de luxe",
            Cost = 2000,
            Income = 30,
            CanAfford = false,
            HasMinCash = false,
            HasAllAchievements = true,
            Achievements = {
                {
                    Id = "CaughtRareFish",
                    Name = "Pêcher un poisson rare",
                    Completed = true
                }
            }
        },
        -- ...
    }
}
```

## 🎮 Utilisation Joueur

1. **Obtenir une parcelle** (système existant)
2. **Approcher de la pancarte** de votre parcelle
3. **Appuyer sur E** pour voir les détails
4. **Consulter** votre revenue actuel et vos objets
5. **Choisir une amélioration** dans la liste
6. **Vérifier** que vous avez l'argent et les achievements requis
7. **Cliquer sur "Améliorer"** pour acheter
8. **L'objet apparaît** automatiquement sur votre parcelle
9. **L'income augmente** automatiquement

## ⚠️ Notes Importantes

- L'ancien système de build manuel est **complètement désactivé**
- Les objets sont maintenant **automatiquement placés** selon leur catégorie
- Les positions sont **fixes** (définies dans CampingItemsConfig.Categories)
- Impossible de **déplacer ou supprimer** les objets manuellement
- Progression **linéaire** : vous devez avoir le niveau N pour acheter le niveau N+1
- Les **achievements** sont obligatoires pour débloquer certains objets

## 🚀 Prochaines Étapes Potentielles

- Ajouter des animations lors de l'achat
- Ajouter des sons
- Afficher un message de succès/erreur plus détaillé
- Permettre de voir les détails du camping d'autres joueurs (en lecture seule)
- Ajouter des statistiques (nombre total d'objets, rang, etc.)
- Ajouter des filtres ou tri dans la liste d'upgrades
