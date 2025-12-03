--[[
    PlacementService
    Vérifie et applique les placements d'objets demandés par les joueurs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local ObjectsConfig = require(configFolder:WaitForChild("ObjectsConfig"))
local CampConfig = require(configFolder:WaitForChild("CampConfig"))
local ConstructionRuntime = require(configFolder:WaitForChild("ConstructionObjectsRuntime"))
local BuildRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuildRemotes"))
local BUILD_GRID_SIZE = CampConfig.BUILD_GRID_SIZE or 0

local constructionFolder

local function getConstructionFolder()
    if constructionFolder and constructionFolder.Parent then
        return constructionFolder
    end
    local folder = ReplicatedStorage:FindFirstChild("ConstructionObjet")
        or ReplicatedStorage:FindFirstChild("Construction Objet")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ConstructionObjet"
        folder.Parent = ReplicatedStorage
        warn("[Paradis][Construction] Dossier 'ConstructionObjet' introuvable, dossier vide créé par défaut.")
    end
    constructionFolder = folder
    return constructionFolder
end

local function getModelFolder(name)
    if not name then
        return nil
    end
    if name == "ConstructionObjet" or name == "Construction Objet" then
        return getConstructionFolder()
    end
    return ReplicatedStorage:FindFirstChild(name)
end

local function waitForShared(key)
    while not shared[key] do
        RunService.Heartbeat:Wait()
    end
    return shared[key]
end

local PlotApi = waitForShared("ParadisPlotService")
local DataApi = waitForShared("ParadisDataService")
local EconomyService = waitForShared("ParadisEconomyService")

-- ✅ NOUVEAU : Service pour gérer les objets de camping par défaut
-- Accès au service de kit camping via 'shared' (évite require d'un Script)
local CampsiteDefaultsService = waitForShared("ParadisCampsiteDefaultsService")

local builders = {}

local function setAnchored(model, value)
    if model:IsA("BasePart") then
        model.Anchored = value
        model.CanCollide = true
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = value
            descendant.CanCollide = true
        end
    end
end

local function applyObjectId(model, objectId)
    if not objectId then
        return
    end
    model:SetAttribute("PlotObjectId", objectId)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant:SetAttribute("PlotObjectId", objectId)
        end
    end
end

local function pivotModelToCFrame(model, targetCFrame)
    if model:IsA("BasePart") then
        model.CFrame = targetCFrame
    else
        model:PivotTo(targetCFrame)
    end
end

local function getPlotBaseHeight(plot)
    if plot then
        if plot.BasePart then
            local base = plot.BasePart
            return base.Position.Y + (base.Size.Y / 2)
        end
        if plot.Center then
            return plot.Center.Y
        end
    end
    return 0
end

local function snapPositionToPlotGrid(plot, position)
    if not plot or BUILD_GRID_SIZE <= 0 then
        return position
    end
    local plotSize = plot.Size
    if not plotSize then
        return position
    end
    local halfX = (plotSize.X / 2) - (BUILD_GRID_SIZE / 2)
    local halfZ = (plotSize.Y / 2) - (BUILD_GRID_SIZE / 2)
    if halfX <= 0 or halfZ <= 0 then
        return Vector3.new(plot.Center.X, plot.Center.Y + 1, plot.Center.Z)
    end
    local relativeX = math.clamp(position.X - plot.Center.X, -halfX, halfX)
    local relativeZ = math.clamp(position.Z - plot.Center.Z, -halfZ, halfZ)
    local snappedX = math.round(relativeX / BUILD_GRID_SIZE) * BUILD_GRID_SIZE
    local snappedZ = math.round(relativeZ / BUILD_GRID_SIZE) * BUILD_GRID_SIZE
    snappedX = math.clamp(snappedX, -halfX, halfX)
    snappedZ = math.clamp(snappedZ, -halfZ, halfZ)
    local baseY = getPlotBaseHeight(plot)
    local rawY = position and position.Y or (baseY + (BUILD_GRID_SIZE / 2))
    local y = math.clamp(rawY, baseY, baseY + 100)
    return Vector3.new(plot.Center.X + snappedX, y, plot.Center.Z + snappedZ)
end

local function putOnGround(part)
    part.CFrame = CFrame.new(0, part.Size.Y / 2, 0)
end

local function createPlate(def, material)
    local model = Instance.new("Model")
    model.Name = def.Label or "Plaque"
    local plate = Instance.new("Part")
    plate.Name = "Plate"
    plate.Size = def.Size or Vector3.new(8, 1, 8)
    plate.Color = def.PrimaryColor or Color3.fromRGB(100, 180, 100)
    plate.Material = material or Enum.Material.Plastic
    plate.TopSurface = Enum.SurfaceType.Smooth
    plate.BottomSurface = Enum.SurfaceType.Smooth
    putOnGround(plate)
    plate.Parent = model
    model.PrimaryPart = plate
    return model
end

local function cloneConfiguredModel(def)
    local folder = getModelFolder(def.ModelFolder)
    if not folder then
        warn("[Paradis][Placement] Dossier de modèle introuvable:", tostring(def.ModelFolder))
        return nil, "Dossier de modèle introuvable"
    end
    local template = folder:FindFirstChild(def.ModelName)
    if not template then
        warn("[Paradis][Placement] Modèle introuvable:", tostring(def.ModelName), "dans", folder:GetFullName())
        return nil, "Modèle introuvable"
    end
    return template:Clone()
end

function builders.GrassTile(def)
    return createPlate(def, Enum.Material.Grass)
end

function builders.GravelTile(def)
    return createPlate(def, Enum.Material.Pebble)
end

function builders.TreeBlock(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "TreeBlock"

    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Size = Vector3.new(1.75, 6, 1.75)
    trunk.Color = def.SecondaryColor or Color3.fromRGB(120, 70, 35)
    trunk.Material = Enum.Material.Wood
    putOnGround(trunk)
    trunk.Parent = model

    local leaves = Instance.new("Part")
    leaves.Name = "Leaves"
    leaves.Size = Vector3.new(4, 4, 4)
    leaves.Color = def.PrimaryColor or Color3.fromRGB(70, 160, 90)
    leaves.Material = Enum.Material.Grass
    leaves.CFrame = CFrame.new(0, trunk.Size.Y + (leaves.Size.Y / 2), 0)
    leaves.Parent = model

    model.PrimaryPart = trunk
    return model
end

function builders.RockBlock(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "RockBlock"

    local rock = Instance.new("Part")
    rock.Name = "Rock"
    rock.Size = Vector3.new(5, 3, 4)
    rock.Color = def.PrimaryColor or Color3.fromRGB(110, 110, 120)
    rock.Material = Enum.Material.Slate
    putOnGround(rock)
    rock.Parent = model

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(1.3, 0.8, 1.1)
    mesh.Parent = rock

    model.PrimaryPart = rock
    return model
end

function builders.FenceSegment(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "FenceSegment"
    local size = def.Size or Vector3.new(10, 3, 1)

    local rail = Instance.new("Part")
    rail.Name = "Rail"
    rail.Size = Vector3.new(size.X, 0.4, size.Z)
    rail.Color = def.SecondaryColor or Color3.fromRGB(180, 150, 110)
    rail.Material = Enum.Material.WoodPlanks
    rail.CFrame = CFrame.new(0, size.Y - 0.6, 0)
    rail.Parent = model

    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(size.X, 0.4, size.Z)
    base.Color = def.SecondaryColor or Color3.fromRGB(180, 150, 110)
    base.Material = Enum.Material.WoodPlanks
    putOnGround(base)
    base.Parent = model

    for _, offset in ipairs({ -size.X / 2 + 0.4, size.X / 2 - 0.4 }) do
        local post = Instance.new("Part")
        post.Name = "Post"
        post.Size = Vector3.new(0.6, size.Y, 0.6)
        post.Color = def.PrimaryColor or Color3.fromRGB(210, 190, 150)
        post.Material = Enum.Material.Wood
        post.CFrame = CFrame.new(offset, size.Y / 2, 0)
        post.Parent = model
    end

    model.PrimaryPart = base
    return model
end

function builders.LightPost(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "LightPost"

    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.8, 10, 0.8)
    pole.Color = def.SecondaryColor or Color3.fromRGB(60, 60, 70)
    pole.Material = Enum.Material.Metal
    putOnGround(pole)
    pole.Parent = model

    local lamp = Instance.new("Part")
    lamp.Name = "Lamp"
    lamp.Size = Vector3.new(2, 1.5, 2)
    lamp.Color = def.PrimaryColor or Color3.fromRGB(230, 230, 230)
    lamp.Material = Enum.Material.Neon
    lamp.CFrame = CFrame.new(0, pole.Size.Y + (lamp.Size.Y / 2), 0)
    lamp.Parent = model

    local light = Instance.new("PointLight")
    light.Range = 18
    light.Brightness = 2
    light.Color = lamp.Color
    light.Parent = lamp

    model.PrimaryPart = pole
    return model
end

-- Décorations simples (fallback visuel minimal)
local function setBase(part, color, material)
    part.Color = color
    part.Material = material or Enum.Material.Wood
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
end

function builders.Bench(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "Bench"
    local seat = Instance.new("Part")
    seat.Name = "Seat"
    seat.Size = Vector3.new(5, 0.4, 2)
    putOnGround(seat)
    setBase(seat, Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
    seat.Parent = model
    for _, x in ipairs({-2.2, 2.2}) do
        local leg = Instance.new("Part")
        leg.Name = "Leg"
        leg.Size = Vector3.new(0.4, 1.4, 0.4)
        leg.CFrame = CFrame.new(x, 0.7, -0.6)
        setBase(leg, Color3.fromRGB(120, 80, 50), Enum.Material.Wood)
        leg.Parent = model
    end
    model.PrimaryPart = seat
    return model
end

function builders.TablePicnic(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "TablePicnic"
    local top = Instance.new("Part")
    top.Name = "Top"
    top.Size = Vector3.new(6, 0.5, 4)
    top.CFrame = CFrame.new(0, 1.5, 0)
    setBase(top, Color3.fromRGB(160, 120, 80), Enum.Material.WoodPlanks)
    top.Parent = model
    for _, x in ipairs({-2.5, 2.5}) do
        local leg = Instance.new("Part")
        leg.Name = "Leg"
        leg.Size = Vector3.new(0.5, 1.5, 0.5)
        leg.CFrame = CFrame.new(x, 0.75, -1.5)
        setBase(leg, Color3.fromRGB(120, 90, 60), Enum.Material.Wood)
        leg.Parent = model
        local leg2 = leg:Clone()
        leg2.CFrame = CFrame.new(x, 0.75, 1.5)
        leg2.Parent = model
    end
    model.PrimaryPart = top
    return model
end

function builders.BBQGrill(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "BBQGrill"
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(2.2, 0.4, 1.6)
    putOnGround(base)
    setBase(base, Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
    base.Parent = model
    local bowl = Instance.new("Part")
    bowl.Name = "Grill"
    bowl.Shape = Enum.PartType.Cylinder
    bowl.Size = Vector3.new(1.6, 0.6, 1.6)
    bowl.CFrame = CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90))
    setBase(bowl, Color3.fromRGB(30, 30, 35), Enum.Material.Metal)
    bowl.Parent = model
    model.PrimaryPart = base
    return model
end

function builders.Lantern(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "Lantern"
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.3, 2, 0.3)
    putOnGround(pole)
    setBase(pole, Color3.fromRGB(70, 70, 80), Enum.Material.Metal)
    pole.Parent = model
    local lamp = Instance.new("Part")
    lamp.Name = "Lamp"
    lamp.Size = Vector3.new(0.8, 1, 0.8)
    lamp.CFrame = CFrame.new(0, 2.3, 0)
    setBase(lamp, Color3.fromRGB(250, 240, 170), Enum.Material.Neon)
    lamp.Parent = model
    local light = Instance.new("PointLight")
    light.Range = 12
    light.Brightness = 2
    light.Color = lamp.Color
    light.Parent = lamp
    model.PrimaryPart = pole
    return model
end

function builders.TentSmall(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "TentSmall"
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(6, 0.4, 4)
    putOnGround(base)
    setBase(base, Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
    base.Parent = model
    local cover = Instance.new("Part")
    cover.Name = "Cover"
    cover.Size = Vector3.new(6, 3, 4)
    cover.Color = Color3.fromRGB(120, 170, 210)
    cover.Material = Enum.Material.Fabric
    cover.Transparency = 0.15
    cover.CFrame = CFrame.new(0, 1.7, 0)
    cover.Parent = model
    model.PrimaryPart = base
    return model
end

function builders.TentLarge(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "TentLarge"
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(8, 0.4, 6)
    putOnGround(base)
    setBase(base, Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
    base.Parent = model
    local cover = Instance.new("Part")
    cover.Name = "Cover"
    cover.Size = Vector3.new(8, 4, 6)
    cover.Color = Color3.fromRGB(180, 140, 90)
    cover.Material = Enum.Material.Fabric
    cover.Transparency = 0.12
    cover.CFrame = CFrame.new(0, 2.2, 0)
    cover.Parent = model
    model.PrimaryPart = base
    return model
end

function builders.FlowerPot(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "FlowerPot"
    local pot = Instance.new("Part")
    pot.Name = "Pot"
    pot.Size = Vector3.new(1.6, 1.2, 1.6)
    putOnGround(pot)
    setBase(pot, Color3.fromRGB(140, 90, 55), Enum.Material.Sandstone)
    pot.Parent = model
    local flower = Instance.new("Part")
    flower.Name = "Flower"
    flower.Size = Vector3.new(1.2, 1.2, 1.2)
    flower.Shape = Enum.PartType.Ball
    flower.Color = Color3.fromRGB(255, 120, 160)
    flower.Material = Enum.Material.Neon
    flower.CFrame = CFrame.new(0, 1.4, 0)
    flower.Parent = model
    model.PrimaryPart = pot
    return model
end

function builders.Bush(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "Bush"
    local base = Instance.new("Part")
    base.Name = "Shrub"
    base.Size = Vector3.new(3, 2, 3)
    putOnGround(base)
    setBase(base, Color3.fromRGB(70, 150, 80), Enum.Material.Grass)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(1.4, 1, 1.2)
    mesh.Parent = base
    base.Parent = model
    model.PrimaryPart = base
    return model
end

function builders.SignWood(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "SignWood"
    local post = Instance.new("Part")
    post.Name = "Post"
    post.Size = Vector3.new(0.5, 3, 0.5)
    putOnGround(post)
    setBase(post, Color3.fromRGB(170, 120, 70), Enum.Material.Wood)
    post.Parent = model
    local board = Instance.new("Part")
    board.Name = "Board"
    board.Size = Vector3.new(3, 1.6, 0.3)
    board.CFrame = CFrame.new(0, 2.4, -0.15)
    setBase(board, Color3.fromRGB(120, 80, 40), Enum.Material.WoodPlanks)
    board.Parent = model
    model.PrimaryPart = post
    return model
end

function builders.Campfire(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "Campfire"
    local ring = Instance.new("Part")
    ring.Name = "Ring"
    ring.Size = Vector3.new(3, 0.6, 3)
    putOnGround(ring)
    setBase(ring, Color3.fromRGB(90, 80, 70), Enum.Material.Rock)
    ring.Parent = model
    local flame = Instance.new("Part")
    flame.Name = "Flame"
    flame.Shape = Enum.PartType.Ball
    flame.Size = Vector3.new(1.4, 1.4, 1.4)
    flame.Color = Color3.fromRGB(255, 140, 40)
    flame.Material = Enum.Material.Neon
    flame.CFrame = CFrame.new(0, 1.1, 0)
    flame.Parent = model
    local light = Instance.new("PointLight")
    light.Brightness = 3
    light.Range = 14
    light.Color = flame.Color
    light.Parent = flame
    model.PrimaryPart = ring
    return model
end

-- Caravane simplifiée
function builders.TravelTrailer1961(def)
    local model = Instance.new("Model")
    model.Name = def.Label or "TravelTrailer1961"
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(14, 1, 6)
    putOnGround(base)
    setBase(base, Color3.fromRGB(180, 180, 185), Enum.Material.Metal)
    base.Parent = model
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(14, 6, 6)
    body.Color = Color3.fromRGB(210, 210, 215)
    body.Material = Enum.Material.SmoothPlastic
    body.CFrame = CFrame.new(0, 3.5, 0)
    body.Parent = model
    local stripe = Instance.new("Part")
    stripe.Name = "Stripe"
    stripe.Size = Vector3.new(14.1, 1, 6.05)
    stripe.Color = Color3.fromRGB(120, 160, 220)
    stripe.Material = Enum.Material.SmoothPlastic
    stripe.CFrame = CFrame.new(0, 2.5, 0)
    stripe.Parent = model
    model.PrimaryPart = base
    return model
end

-- Arbres stylisés
local function buildTree(label, trunkColor, leafColor)
    local model = Instance.new("Model")
    model.Name = label
    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Size = Vector3.new(1.8, 8, 1.8)
    putOnGround(trunk)
    trunk.Color = trunkColor
    trunk.Material = Enum.Material.Wood
    trunk.Parent = model
    local crown = Instance.new("Part")
    crown.Name = "Leaves"
    crown.Size = Vector3.new(8, 6, 8)
    crown.Color = leafColor
    crown.Material = Enum.Material.Grass
    crown.CFrame = CFrame.new(0, trunk.Size.Y + 3, 0)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(1, 0.8, 1)
    mesh.Parent = crown
    crown.Parent = model
    model.PrimaryPart = trunk
    return model
end

function builders.ArbreVert(def)
    return buildTree(def.Label or "ArbreVert", Color3.fromRGB(120, 70, 35), Color3.fromRGB(70, 160, 90))
end

function builders.ArbreRose(def)
    return buildTree(def.Label or "ArbreRose", Color3.fromRGB(120, 70, 35), Color3.fromRGB(240, 170, 220))
end

function builders.ArbreGros(def)
    local model = buildTree(def.Label or "ArbreGros", Color3.fromRGB(110, 65, 30), Color3.fromRGB(60, 140, 70))
    -- Agrandir le feuillage
    local leaves = model:FindFirstChild("Leaves")
    if leaves then
        leaves.Size = Vector3.new(10, 8, 10)
        leaves.CFrame = model.PrimaryPart.CFrame * CFrame.new(0, 9, 0)
    end
    return model
end

function builders.ArbrePetit(def)
    local model = buildTree(def.Label or "ArbrePetit", Color3.fromRGB(120, 70, 35), Color3.fromRGB(80, 170, 100))
    local trunk = model:FindFirstChild("Trunk")
    local leaves = model:FindFirstChild("Leaves")
    if trunk then
        trunk.Size = Vector3.new(1.4, 6, 1.4)
    end
    if leaves and trunk then
        leaves.Size = Vector3.new(5, 4, 5)
        leaves.CFrame = trunk.CFrame * CFrame.new(0, 6, 0)
    end
    return model
end

-- Modèles de poissons décoratifs (sans mesh externe)
local function buildFishModel(def, sizeScale, bodyColor)
    local model = Instance.new("Model")
    model.Name = def.Label or "Fish"

    -- Corps
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(1.6 * sizeScale, 0.8 * sizeScale, 0.9 * sizeScale)
    body.Material = Enum.Material.SmoothPlastic
    body.Color = bodyColor
    putOnGround(body)
    body.Parent = model

    -- Queue (wedge)
    local tail = Instance.new("WedgePart")
    tail.Name = "Tail"
    tail.Size = Vector3.new(0.8 * sizeScale, 0.6 * sizeScale, 0.2 * sizeScale)
    tail.Material = Enum.Material.SmoothPlastic
    tail.Color = bodyColor:Lerp(Color3.fromRGB(250, 250, 250), 0.2)
    tail.CFrame = CFrame.new(body.Position) * CFrame.new(0.9 * sizeScale, 0, 0)
    tail.Parent = model

    local weldTail = Instance.new("WeldConstraint")
    weldTail.Part0 = body
    weldTail.Part1 = tail
    weldTail.Parent = tail

    -- Nageoire dorsale
    local finTop = Instance.new("WedgePart")
    finTop.Name = "TopFin"
    finTop.Size = Vector3.new(0.5 * sizeScale, 0.3 * sizeScale, 0.2 * sizeScale)
    finTop.Material = Enum.Material.SmoothPlastic
    finTop.Color = bodyColor:Lerp(Color3.fromRGB(255, 255, 255), 0.3)
    finTop.CFrame = CFrame.new(body.Position) * CFrame.new(0, 0.4 * sizeScale, 0)
    finTop.Parent = model

    local weldTop = Instance.new("WeldConstraint")
    weldTop.Part0 = body
    weldTop.Part1 = finTop
    weldTop.Parent = finTop

    -- Nageoire ventrale
    local finBottom = Instance.new("WedgePart")
    finBottom.Name = "BottomFin"
    finBottom.Size = Vector3.new(0.5 * sizeScale, 0.3 * sizeScale, 0.2 * sizeScale)
    finBottom.Material = Enum.Material.SmoothPlastic
    finBottom.Color = bodyColor:Lerp(Color3.fromRGB(255, 255, 255), 0.3)
    finBottom.CFrame = CFrame.new(body.Position) * CFrame.new(0, -0.35 * sizeScale, 0)
    finBottom.Parent = model

    local weldBottom = Instance.new("WeldConstraint")
    weldBottom.Part0 = body
    weldBottom.Part1 = finBottom
    weldBottom.Parent = finBottom

    model.PrimaryPart = body
    return model
end

function builders.Common(def)
    return buildFishModel(def, 1.0, Color3.fromRGB(180, 200, 220))
end

function builders.rare(def)
    return buildFishModel(def, 1.4, Color3.fromRGB(255, 165, 80))
end

function builders.legendaire(def)
    return buildFishModel(def, 2.2, Color3.fromRGB(255, 215, 0))
end

local function createModel(objectType)
    local def = ObjectsConfig[objectType]
    if not def then
        return nil, "Objet inconnu"
    end
    if def.ModelFolder and def.ModelName then
        local model, err = cloneConfiguredModel(def)
        if not model then
            return nil, err or "Modèle introuvable"
        end
        model.Name = objectType
        return model, nil
    end
    local builder = builders[def.ModelType]
    if not builder then
        return nil, "ModelType non géré"
    end
    local model = builder(def)
    model.Name = objectType
    return model, nil
end

local function ensurePlotState(plot)
    plot.PlayerData = plot.PlayerData or {
        Objects = plot.PlacedObjects or {},
    }
    plot.PlayerData.Objects = plot.PlayerData.Objects or {}
    plot.PlacedObjects = plot.PlayerData.Objects
end

local function countObjectsOfType(plot, objectType)
    ensurePlotState(plot)
    local count = 0
    for _, entry in ipairs(plot.PlacedObjects) do
        if entry.Type == objectType then
            count += 1
        end
    end
    return count
end

local function resolveEconomyValues(catalog, objectType, constructionId)
    if not EconomyService then
        return { Cost = 0, IncomePerSecond = 0, UnlockAtIncome = 0 }
    end
    local id = objectType
    if catalog == "Construction" then
        id = constructionId or objectType
    end
    local values = EconomyService.GetEconomyForObject(catalog, id) or {}
    return {
        Cost = tonumber(values.Cost) or 0,
        IncomePerSecond = tonumber(values.IncomePerSecond) or 0,
        UnlockAtIncome = tonumber(values.UnlockAtIncome) or 0,
    }
end

local function applyEconomyOnRecord(player, record, cost, income)
    record.Cost = cost
    record.IncomePerSecond = income
    if cost > 0 then
        EconomyService.AddCash(player, -cost)
    end
    if income > 0 then
        EconomyService.AddIncomeSource(player, income)
    end
end

local function serializeVector(v)
    return { x = v.X, y = v.Y, z = v.Z }
end

local function deserializeVector(tbl)
    return Vector3.new(tbl.x, tbl.y, tbl.z)
end

local function toVector(value)
    if typeof(value) == "Vector3" then
        return value
    elseif typeof(value) == "table" and value.x and value.y and value.z then
        return deserializeVector(value)
    end
    return nil
end

local function spawnModelInPlot(plot, record)
    if record.Type == "Construction" or record.Catalog == "Construction" then
        local templateId = record.ConstructionId or record.ObjectId or record.Type
        local template = templateId and ConstructionRuntime.GetTemplate(templateId)
        if not template then
            warn("[Paradis] Modèle de construction introuvable", templateId)
            return
        end
        local position = toVector(record.Position)
        if not position then
            return
        end
        local cframe = CFrame.new(position)
        if record.Rotation then
            cframe *= CFrame.Angles(0, math.rad(record.Rotation), 0)
        end
        local clone = template:Clone()
        setAnchored(clone, false)
        pivotModelToCFrame(clone, cframe)
        setAnchored(clone, true)
        applyObjectId(clone, record.Id)
        clone.Parent = plot.Container
        return
    end

    local model, err = createModel(record.Type)
    if not model then
        warn("[Paradis] Impossible de créer l'objet", record.Type, err)
        return
    end
    local position = toVector(record.Position)
    if not position then
        return
    end
    local cframe = CFrame.new(position)
    if record.Rotation then
        cframe *= CFrame.Angles(0, math.rad(record.Rotation), 0)
    end
    setAnchored(model, false)
    pivotModelToCFrame(model, cframe)
    setAnchored(model, true)
    applyObjectId(model, record.Id)
    model.Parent = plot.Container
end

local function savePlotData(plot)
    if not plot.OwnerUserId then
        return
    end
    ensurePlotState(plot)
    if DataApi and DataApi.SavePlayerData then
        plot.PlayerData.Objects = plot.PlacedObjects
        DataApi.SavePlayerData(plot.OwnerUserId, plot.PlayerData)
    end
end

local function handlePlacement(player, payload)
    -- ✅ Placement activé pour TerrainDecor et Objects (décor de parcelle)
    -- Seuls les objets du kit de camping par défaut restent verrouillés
    local allowedCatalogs = {
        ["TerrainDecor"] = true,
        ["Objects"] = true,
    }
    
    if payload and allowedCatalogs[payload.Catalog] then
        local plot = PlotApi.GetPlotForPlayer(player)
        if not plot then
            return false, "Aucune parcelle réservée"
        end
        ensurePlotState(plot)

        local objectType = payload.ObjectType
        local position = payload.Position
        local rotation = payload.Rotation or 0

        if typeof(position) ~= "Vector3" then
            return false, "Position invalide"
        end

        local snappedPosition = snapPositionToPlotGrid(plot, position)
        if not snappedPosition then
            return false, "Position invalide"
        end

        if not PlotApi.IsPositionInsidePlot(plot, snappedPosition) then
            return false, "Position hors parcelle"
        end

        if CampConfig.MAX_OBJECTS_PER_PLOT and #plot.PlacedObjects >= CampConfig.MAX_OBJECTS_PER_PLOT then
            return false, "Trop d'objets sur la parcelle"
        end

        -- Utiliser ObjectsConfig pour les décorations de terrain
        local def = ObjectsConfig[objectType]
        if not def then
            return false, "Objet de terrain inconnu"
        end

        if def.MaxPerPlot and countObjectsOfType(plot, objectType) >= def.MaxPerPlot then
            return false, "Limite atteinte pour " .. objectType
        end

        local model, err = createModel(objectType)
        if not model then
            return false, err or "Erreur de modèle"
        end

        local cframe = CFrame.new(snappedPosition) * CFrame.Angles(0, math.rad(rotation), 0)
        setAnchored(model, false)
        pivotModelToCFrame(model, cframe)
        setAnchored(model, true)
        model.Parent = plot.Container

        -- Calcul du coût évolutif pour LogNode (1000 pour le premier, puis x10 par arbre déjà planté)
        local effectiveCost = 0
        local incomePerSecond = 0
        if objectType == "LogNode" then
            local existing = countObjectsOfType(plot, "LogNode")
            effectiveCost = 1000 * (10 ^ existing)
            local econ = EconomyConfig.Objects.LogNode or EconomyConfig.Defaults
            incomePerSecond = econ.IncomePerSecond or 0
            if effectiveCost > 0 and not EconomyService.HasEnoughCash(player, effectiveCost) then
                return false, "Pas assez d'argent (coût: " .. tostring(effectiveCost) .. ")"
            end
        end

        -- Gestion économique pour LogNode ou objets normaux
        if objectType == "LogNode" then
            -- Calcul déjà fait ci-dessus
            if effectiveCost > 0 then
                EconomyService.AddCash(player, -effectiveCost)
            end
            if (incomePerSecond or 0) > 0 then
                EconomyService.AddIncomeSource(player, incomePerSecond)
            end
        else
            -- Objets normaux: utiliser EconomyConfig
            local economyValues = resolveEconomyValues(payload.Catalog, objectType, nil)
            effectiveCost = economyValues.Cost
            incomePerSecond = economyValues.IncomePerSecond
            
            if effectiveCost > 0 and not EconomyService.HasEnoughCash(player, effectiveCost) then
                return false, "Pas assez d'argent"
            end
            
            if effectiveCost > 0 then
                EconomyService.AddCash(player, -effectiveCost)
            end
            if incomePerSecond > 0 then
                EconomyService.AddIncomeSource(player, incomePerSecond)
            end
        end

        local record = {
            Id = HttpService:GenerateGUID(false),
            Type = objectType,
            Catalog = payload.Catalog,
            Position = serializeVector(snappedPosition),
            Rotation = rotation,
            Cost = effectiveCost,
            IncomePerSecond = incomePerSecond,
        }
        
        applyObjectId(model, record.Id)
        table.insert(plot.PlacedObjects, record)
        BuildRemotes.PlacedObjectsUpdated:FireClient(player, plot.PlacedObjects)
        savePlotData(plot)

        return true
    end

    -- Les objets de camping sont générés automatiquement et fixes
    return false, "Le placement libre est désactivé. Les objets sont automatiques."
end


local function handleMove(player, payload)
    -- payload: { ObjectId = number, CFrame = CFrame or {x,y,z}, Rotation = number }
    print("[PlacementService] handleMove appelé pour", player.Name, "payload:", payload)
    local plot = PlotApi and PlotApi.GetPlotForPlayer and PlotApi.GetPlotForPlayer(player)
    if not plot then
        warn("[PlacementService] Parcelle introuvable pour", player.Name)
        return false, "Parcelle introuvable"
    end
    local objectId = payload and payload.ObjectId
    print("[PlacementService] ObjectId demandé:", objectId)
    if not objectId then
        warn("[PlacementService] Objet introuvable (objectId nil)")
        return false, "Objet introuvable"
    end
    local record, index
    for i, rec in ipairs(plot.PlacedObjects or {}) do
        if rec.Id == objectId then
            record, index = rec, i
            break
        end
    end
    if not record then
        warn("[PlacementService] Objet introuvable dans PlacedObjects. ObjectId:", objectId)
        return false, "Objet introuvable sur la parcelle"
    end
    print("[PlacementService] Record trouvé:", record.Type, "index:", index)
    
    -- ✅ NOUVEAU : Vérifier si c'est un objet de camping par défaut (verrouillé)
    if record.Instance and CampsiteDefaultsService then
        if CampsiteDefaultsService.IsDefaultCampsiteObject(record.Instance) then
            return false, "Cet objet est fixe et ne peut pas être déplacé"
        end
    end

    -- Compute target position from payload (X,Z only, preserve original Y)
    local targetPos
    if typeof(payload.CFrame) == "CFrame" then
        targetPos = payload.CFrame.Position
    elseif type(payload.CFrame) == "table" and payload.CFrame.x and payload.CFrame.z then
        targetPos = Vector3.new(payload.CFrame.x, payload.CFrame.y or 0, payload.CFrame.z)
    else
        return false, "Position invalide"
    end
    
    -- Snap X and Z to grid, use plot base height for Y
    local grid = 2
    local snappedX = math.floor(targetPos.X / grid + 0.5) * grid
    local snappedZ = math.floor(targetPos.Z / grid + 0.5) * grid
    
    -- Use plot base height (same as initial placement)
    local baseY = getPlotBaseHeight(plot)
    local snappedPos = Vector3.new(snappedX, baseY, snappedZ)
    print("[PlacementService] Position avec baseY:", snappedPos)

    -- Validate inside plot
    if PlotApi and PlotApi.IsPositionInsidePlot then
        if not PlotApi.IsPositionInsidePlot(plot, snappedPos) then
            return false, "Déplacement hors de la parcelle"
        end
    end

    local rotation = tonumber(payload.Rotation or 0) or 0
    local targetCFrame = CFrame.new(snappedPos) * CFrame.Angles(0, math.rad(rotation), 0)

    -- Locate instance by PlotObjectId attribute
    local instance = record.Instance
    print("[PlacementService] Instance depuis record:", instance)
    if not instance or not instance.Parent then
        local worldFolder = plot.Container
        print("[PlacementService] Recherche instance dans plot.Container:", worldFolder)
        if worldFolder then
            for _, m in ipairs(worldFolder:GetChildren()) do
                if m:GetAttribute("PlotObjectId") == objectId then
                    print("[PlacementService] Instance trouvée via PlotObjectId:", m.Name)
                    instance = m
                    break
                end
            end
        end
    end
    
    if not instance or not instance.Parent then
        warn("[PlacementService] Instance de l'objet introuvable pour objectId:", objectId)
        return false, "Instance de l'objet introuvable"
    end

    print("[PlacementService] Déplacement de l'instance:", instance.Name, "vers", targetCFrame.Position)
    -- Move the instance
    if instance:IsA("Model") then
        instance:PivotTo(targetCFrame)
    elseif instance:IsA("BasePart") then
        instance.CFrame = targetCFrame
    end

    -- Update record with CFrame as table for consistency
    record.CFrame = {
        X = targetCFrame.Position.X,
        Y = targetCFrame.Position.Y,
        Z = targetCFrame.Position.Z
    }
    record.Rotation = rotation
    record.Instance = instance
    
    -- Notify data save
    if DataApi and DataApi.SavePlotData then
        task.defer(function()
            DataApi.SavePlotData(player)
        end)
    end

    print("[PlacementService] Déplacement réussi pour objectId:", objectId)
    return true, "Objet déplacé"
end

BuildRemotes.RequestPlacement.OnServerInvoke = function(player, payload)
    return handlePlacement(player, payload or {})
end

local function findObjectRecord(plot, objectId)
    ensurePlotState(plot)
    for index, entry in ipairs(plot.PlacedObjects) do
        if entry.Id == objectId then
            return entry, index
        end
    end
    return nil
end

local function handleRemoval(player, objectId)
    local plot = PlotApi.GetPlotForPlayer(player)
    if not plot then
        return false, "Aucune parcelle"
    end
    ensurePlotState(plot)
    if typeof(objectId) ~= "string" or objectId == "" then
        return false, "Id invalide"
    end

    local record, index = findObjectRecord(plot, objectId)
    if not record then
        return false, "Objet introuvable"
    end
    
    -- ✅ NOUVEAU : Vérifier si c'est un objet de camping par défaut (verrouillé)
        local CampsiteDefaultsService = shared.ParadisCampsiteDefaultsService
        if record.Instance and CampsiteDefaultsService and CampsiteDefaultsService.IsDefaultCampsiteObject then
            if CampsiteDefaultsService.IsDefaultCampsiteObject(record.Instance) then
            return false, "Les objets du kit de camping ne peuvent pas être supprimés"
        end
    end

    if plot.Container then
        local destroyedModels = {}
        for _, descendant in ipairs(plot.Container:GetDescendants()) do
            if descendant:GetAttribute("PlotObjectId") == objectId then
                local model = descendant:IsA("BasePart") and descendant.Parent or descendant
                if model and model:IsA("Model") and not destroyedModels[model] then
                    destroyedModels[model] = true
                    model:Destroy()
                elseif not model then
                    descendant:Destroy()
                elseif not model:IsA("Model") then
                    descendant:Destroy()
                end
            end
        end
    end

    EconomyService.RemoveIncomeSource(player, record.IncomePerSecond or 0)
    table.remove(plot.PlacedObjects, index)
    BuildRemotes.PlacedObjectsUpdated:FireClient(player, plot.PlacedObjects)
    savePlotData(plot)
    return true
end

BuildRemotes.RequestRemove.OnServerInvoke = function(player, objectId)
    return handleRemoval(player, objectId)
end

BuildRemotes.RequestMove.OnServerInvoke = function(player, payload)
    return handleMove(player, payload or {})
end

local PlacementAPI = {}

function PlacementAPI.OnPlotClaimed(player, plot, savedData)
    plot.Container:ClearAllChildren()
    plot.PlayerData = savedData or plot.PlayerData or {
        Objects = {},
    }
    ensurePlotState(plot)
    for _, entry in ipairs(plot.PlacedObjects) do
        entry.Id = entry.Id or HttpService:GenerateGUID(false)
        spawnModelInPlot(plot, entry)
    end
    if player then
        EconomyService.RecalculateIncome(player, plot.PlacedObjects)
    end
    savePlotData(plot)
end

shared.ParadisPlacementService = PlacementAPI
