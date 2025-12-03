# Configuration de la Canne Master (Achat Robux)

La canne Master est désormais achetable uniquement avec des Robux via un **Developer Product**.

## Étapes de configuration (dans Roblox Studio/Creator Dashboard)

### 1. Créer un Developer Product
1. Allez sur [Roblox Creator Dashboard](https://create.roblox.com/)
2. Sélectionnez votre expérience "Paradis des Parcelles"
3. Dans le menu latéral, cliquez sur **Monetization** → **Developer Products**
4. Cliquez sur **Create a Developer Product**
5. Remplissez:
   - **Name**: `Master Fishing Rod` (ou "Canne à pêche Master")
   - **Description**: `La meilleure canne à pêche avec effets brillants et +12% de poisson légendaire`
   - **Price in Robux**: `199` (ou le prix souhaité)
6. Cliquez sur **Create**
7. **IMPORTANT**: Notez l'**Asset ID** (Product ID) généré (ex: `1234567890`)

### 2. Ajouter l'ID dans le code

Dans `FishingGearConfig.lua`, remplacez la ligne `RobuxPrice = 199` par:
```lua
RobuxPrice = 199,
ProductId = 1234567890, -- REMPLACER par votre vrai Product ID
```

### 3. Implémenter le callback ProcessReceipt

Créez un nouveau fichier `MonetizationService.server.lua` dans `ServerScriptService/ParadisServer/`:

```lua
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local FishingShopService = waitForShared("ParadisFishingShopService")
local ConfigFolder = game:GetService("ReplicatedStorage"):WaitForChild("Config")
local FishingGearConfig = require(ConfigFolder:WaitForChild("FishingGearConfig"))

local MASTER_ROD_PRODUCT_ID = FishingGearConfig.Rods.Master.ProductId

-- Callback appelé après chaque achat Developer Product
local function processReceipt(receiptInfo)
    local userId = receiptInfo.PlayerId
    local productId = receiptInfo.ProductId
    
    -- Vérifier si c'est la canne Master
    if productId == MASTER_ROD_PRODUCT_ID then
        local success = FishingShopService.GrantMasterRod(userId)
        if success then
            print("[Monetization] Canne Master accordée via Robux pour:", userId)
            return Enum.ProductPurchaseDecision.PurchaseGranted
        else
            warn("[Monetization] Échec accord canne Master pour:", userId)
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = processReceipt
print("[Paradis][Monetization] Service initialisé")
```

### 4. Activer le prompt d'achat côté client

Dans `FishingShopClient.client.lua`, remplacez le TODO par:

```lua
if rodDef.RobuxPrice and rodDef.ProductId then
    local MarketplaceService = game:GetService("MarketplaceService")
    MarketplaceService:PromptProductPurchase(LocalPlayer, rodDef.ProductId)
else
    warn("[FishingShopClient] ProductId manquant pour achat Robux")
end
```

### 5. Tester

1. **En Studio**: Les achats Developer Product ne fonctionnent pas en mode test local (retournent erreur). Vous devez publier et tester sur un serveur réel.
2. **Publication**: Publiez votre jeu
3. **Test réel**: Rejoignez via le site Roblox
4. **Vérification**:
   - Ouvrez le Pro Shop
   - La canne Master doit afficher `🔶 199 R$` (bleu cyan)
   - Cliquez: prompt d'achat Robux Roblox s'affiche
   - Achetez (ou testez avec compte test)
   - La canne doit apparaître dans votre inventaire immédiatement

## Notes importantes

- **Remboursements**: ProcessReceipt doit retourner `PurchaseGranted` pour valider l'achat. Si vous retournez `NotProcessedYet`, Roblox réessaiera plus tard.
- **Sécurité**: Le callback `ProcessReceipt` s'exécute côté serveur, impossible de tricher.
- **Persistence**: L'achat est sauvegardé dans `DataStore` (OwnedRods.Master = true).
- **Prix**: Modifiable à tout moment dans Creator Dashboard (pas besoin de republier le jeu).

## Alternative: GamePass

Si vous préférez un **GamePass** (achat permanent unique):
1. Créez un GamePass au lieu d'un Developer Product
2. Remplacez `PromptProductPurchase` par `PromptGamePassPurchase`
3. Utilisez `UserOwnsGamePassAsync` au chargement du joueur pour accorder automatiquement la canne

Le Developer Product est recommandé ici car il permet des achats répétés (si jamais vous voulez offrir des packs ou consommables Robux).
