# Paradis des Parcelles

Mini-experience Roblox tournée vers l'aménagement libre d'une parcelle de camping. Tout est synchronisé via Rojo et peut être testé localement en quelques étapes.

## Démarrage rapide
1. Ouvre un terminal dans `paradis/` et lance `rojo serve`.
2. Dans Roblox Studio, ouvre `ParadisDesParcelles.rbxlx` (ou une baseplate) et connecte-toi au serveur Rojo.
3. Clique sur Play. Les panneaux de réservation te permettent de réclamer une parcelle.

> Astuce : le jeu repose sur `default.project.json`. Assure-toi que Rojo utilise bien cette configuration.

## Tester le mode "Aménager ma parcelle"
1. Approche-toi d'un panneau "Parcelle libre" et maintiens **E** pour la réserver.
2. Un bouton **Aménager ma parcelle** apparaît en bas de l'écran.
3. Clique dessus pour ouvrir la barre d'outils : les six blocs Lego-like sont désormais gratuits.
4. Sélectionne un bloc (plaque d'herbe, gravier, arbre bloc, roche bloc, clôture, lampadaire).
5. Vise la parcelle : un fantôme bleu montre l'emplacement **snappé sur la grille** (2 studs).
6. Appuie sur **R** pour pivoter par pas de 45° si besoin, puis clique pour placer.
7. Pour supprimer, active le bouton **Supprimer** puis clique sur un objet existant.

### Points importants
- Tous les objets sont gratuits : aucune monnaie ou budget à gérer.
- La palette est ordonnée pour rappeler une petite boîte Lego.
- Le serveur resnape systématiquement les placements, ce qui garantit un alignement propre même si un client lag.
- La liste d'objets placés (frame gauche) se met à jour en direct et propose un bouton de suppression rapide.

## Magasin "Construction Objet"
- Le dossier `ReplicatedStorage/Construction Objet` est **la source unique** des blocs de cabane.
- Chaque `Model` enfant devient automatiquement un bouton supplémentaire dans l'onglet **Aménager ma parcelle**.
- Aucun code à mettre à jour : ajoute le modèle dans Roblox Studio, synchronise via Rojo, et il apparaît côté client.
- Le client récupère la liste à chaud, affiche les boutons et envoie `Catalog = "Construction"` + `ConstructionId = <NomDuModel>` quand tu places un bloc.
- Le serveur clone le modèle demandé, applique la rotation/position snappée et l'ancre dans la parcelle du joueur.

### Ajouter/Test un nouveau bloc
1. Dans Studio, insère ton `Model` (mur, poutre, etc.) dans `ReplicatedStorage > Construction Objet`.
2. Facultatif : ajoute les attributs `DisplayName` (texte du bouton) et `DisplayOrder` (tri dans la palette).
3. Lance `rojo serve` + Play : le bouton apparaît automatiquement sous les blocs Lego.
4. Clique dessus, vise la parcelle : le fantôme bleu utilise la bounding box du modèle pour prévisualiser la taille.
5. Clique pour placer : le serveur clone exactement ton modèle, sans coût.

- Les blocs restent gratuits et respectent la même grille (2 studs) que les objets classiques.
- Supprimer un bloc de `Construction Objet` le retire aussi de la palette (la sélection est nettoyée si nécessaire).

## Construire la roulotte modulaire
- Clique sur **Construire la roulotte** pour basculer vers les pièces Foundation/Wall/Roof.
- Le fantôme orange suit la grille de 4 studs propre au mode roulotte.
- R pour tourner, clic pour poser, bouton "Quitter" pour revenir au mode parcelle.

## Mini-jeux (aire commune)
- **Balançoire 360°** : trouve le rig métallique près de l'aire commune, assieds-toi sur le siège, puis alterne `W`/`S` ou flèches haut/bas pour pousser. Chaque looping complet valide (360° autour du pivot) crédite automatiquement 5 $ via l'EconomyService/leaderstats.
- **Pêche** : cinq pontons (`FishingSpot1..5`) longent le lac. Approche-toi d'un spot et active le ProximityPrompt "Pêcher" pour tirer un poisson aléatoire (Petit → Rare) et recevoir sa récompense en Cash. Un cooldown de 5 s empêche le spam.

## Raccourcis utiles
- `R` : rotation de l'objet sélectionné.
- `Esc` : fermer le mode actif.
- `Supprimer` (bouton) : active le mode suppression.

## Débogage rapide
- Si rien n'apparaît, vérifie que `BuildRemotes` est bien accessible depuis ReplicatedStorage.
- S'assure que les services partagés (`shared.Paradis*`) sont initialisés : PlotService appelle `shared.ParadisPlotService` au chargement.
- Pour réinitialiser une parcelle, quitte et reviens en jeu ; la parcelle se vide quand le joueur se déconnecte.

## Personnalisation
- Les objets plaçables sont déclarés dans `src/ReplicatedStorage/Config/ObjectsConfig.lua`.
- Les blocs "Construction Objet" sont découverts à la volée via `src/ReplicatedStorage/Config/ConstructionObjectsRuntime.lua`.
- Le pas de la grille est contrôlé par `CampConfig.BUILD_GRID_SIZE` (défaut 2).
- Les builders côté serveur se trouvent dans `PlacementService.server.lua`.
- L'UI est générée via `StarterGui/ParadisGui/BuildScreenGui.lua`.

Bon aménagement !
