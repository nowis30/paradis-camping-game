--[[
    ShopService
    Gère l'achat et le placement d'objets décoratifs sur la parcelle du joueur.
    Les modèles référencés doivent se trouver dans ReplicatedStorage.ShopObjects.
    DÉSACTIVÉ: fonctionnalité retirée.
]]

do return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local ShopObjects = ReplicatedStorage:FindFirstChild("ShopObjects")
if not ShopObjects then
    ShopObjects = Instance.new("Folder")
    ShopObjects.Name = "ShopObjects"
    ShopObjects.Parent = ReplicatedStorage
    warn("[Paradis][Shop] Dossier 'ShopObjects' manquant, créé vide par défaut.")
end

local ConfigFolder = ReplicatedStorage:WaitForChild("Config")
local ShopConfig = require(ConfigFolder:WaitForChild("ShopConfig"))
local BuildRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuildRemotes"))

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
    RemotesFolder = Instance.new("Folder")
    RemotesFolder.Name = "Remotes"
    RemotesFolder.Parent = ReplicatedStorage
end

local ShopRemotes = RemotesFolder:FindFirstChild("ShopRemotes")
if not ShopRemotes then
    ShopRemotes = Instance.new("Folder")
    ShopRemotes.Name = "ShopRemotes"
    ShopRemotes.Parent = RemotesFolder
end

local PlaceShopItem = ShopRemotes:FindFirstChild("PlaceShopItem")
if not PlaceShopItem then
    PlaceShopItem = Instance.new("RemoteEvent")
    PlaceShopItem.Name = "PlaceShopItem"
    PlaceShopItem.Parent = ShopRemotes
end

local PlotService = waitForShared("ParadisPlotService")
local EconomyService = shared.ParadisEconomyService

local function getCashValue(player)
    local stats = player:FindFirstChild("leaderstats")
    return stats and stats:FindFirstChild("Cash")
end

local function getItemDefinition(itemId)
    local def = ShopConfig.Items[itemId]
    if def then
        return def
    end
    warn("[Paradis][Shop] Item inconnu demandé:", itemId)
    return nil
end

local function ensurePlotOwnership(player)
    if not PlotService or not PlotService.GetPlotForPlayer then
        return nil
    end
    return PlotService.GetPlotForPlayer(player)
end

local function isInsidePlot(plot, position)
    if PlotService and PlotService.IsPositionInsidePlot then
        return PlotService.IsPositionInsidePlot(plot, position)
    end
    return false
end

local function chargePlayer(player, cost)
    cost = math.max(0, cost or 0)
    if cost == 0 then
        return true
    end

    if EconomyService and EconomyService.HasEnoughCash and EconomyService.AddCash then
        if not EconomyService.HasEnoughCash(player, cost) then
            return false
        end
        EconomyService.AddCash(player, -cost)
        return true
    end

    local cashValue = getCashValue(player)
    if not cashValue or cashValue.Value < cost then
        return false
    end
    cashValue.Value -= cost
    return true
end

local function recordPlacement(plot, itemDef, targetCFrame)
    plot.PlacedObjects = plot.PlacedObjects or {}
    table.insert(plot.PlacedObjects, {
        Type = "ShopItem",
        ItemId = itemDef.Id,
        Category = itemDef.Category,
        Position = targetCFrame.Position,
        YRotation = select(2, targetCFrame:ToEulerAnglesYXZ()),
        Cost = itemDef.Cost,
        Timestamp = os.time(),
    })
end

local function placeModelInPlot(plot, modelTemplate, targetCFrame)
    local clone = modelTemplate:Clone()
    if clone.PrimaryPart then
        clone:PivotTo(targetCFrame)
    else
        local primary = clone:FindFirstChildWhichIsA("BasePart", true)
        if primary then
            local offset = primary.CFrame:ToObjectSpace(clone:GetPivot())
            clone:PivotTo(targetCFrame * offset)
        else
            clone:PivotTo(targetCFrame)
        end
    end

    local container = plot.Container
    if not container then
        container = Instance.new("Folder")
        container.Name = "PlotContainer_" .. tostring(plot.Id)
        container.Parent = plot.BasePart or workspace
        plot.Container = container
    end

    clone.Parent = container
    return clone
end

local function sanitizeCFrame(cf)
    if typeof(cf) ~= "CFrame" then
        return nil
    end
    local position = cf.Position
    local _, yaw = cf:ToEulerAnglesYXZ()
    return CFrame.new(position) * CFrame.Angles(0, yaw, 0)
end

PlaceShopItem.OnServerEvent:Connect(function(player, itemId, requestedCFrame)
    if typeof(itemId) ~= "string" then
        return
    end

    local itemDef = getItemDefinition(itemId)
    if not itemDef then
        return
    end

    local modelTemplate = ShopObjects:FindFirstChild(itemDef.ModelName)
    if not modelTemplate then
        warn("[Paradis][Shop] Model introuvable pour l'item:", itemId, itemDef.ModelName)
        return
    end

    local targetCFrame = sanitizeCFrame(requestedCFrame)
    if not targetCFrame then
        warn("[Paradis][Shop] CFrame invalide pour", player.Name)
        return
    end

    local plot = ensurePlotOwnership(player)
    if not plot then
        warn("[Paradis][Shop] Le joueur n'a pas de parcelle:", player.Name)
        return
    end

    if not isInsidePlot(plot, targetCFrame.Position) then
        warn("[Paradis][Shop] Placement refusé hors parcelle pour", player.Name)
        return
    end

    local cost = itemDef.Cost or (ShopConfig.Defaults and ShopConfig.Defaults.Cost) or 0
    if not chargePlayer(player, cost) then
        warn("[Paradis][Shop] Pas assez d'argent pour", player.Name, "item", itemId)
        return
    end

    placeModelInPlot(plot, modelTemplate, targetCFrame)
    recordPlacement(plot, itemDef, targetCFrame)
    BuildRemotes.PlacedObjectsUpdated:FireClient(player, plot.PlacedObjects)

    if shared.ParadisEconomyService and shared.ParadisEconomyService.RecalculateIncome then
        shared.ParadisEconomyService.RecalculateIncome(player, plot.PlacedObjects)
    end

    print("[Paradis][Shop] Objet placé:", itemId, "par", player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Rien de spécifique pour l'instant, la persistance sera gérée via PlotService/DataService.
end)
