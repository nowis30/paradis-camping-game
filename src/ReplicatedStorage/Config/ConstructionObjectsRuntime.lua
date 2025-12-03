--[[
    ConstructionObjectsRuntime
    Lecture dynamique des modèles placés dans ReplicatedStorage["Construction Objet"].
    Chaque model enfant devient automatiquement un bloc plaçable côté client/serveur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureConstructionFolder()
    local folder = ReplicatedStorage:FindFirstChild("Construction Objet")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Construction Objet"
        folder.Parent = ReplicatedStorage
        warn("[Paradis][Construction] Dossier 'Construction Objet' introuvable, dossier vide créé par défaut.")
    end
    return folder
end

local ConstructionFolder = ensureConstructionFolder()

local DEBUG = false -- passe à true pour inspecter les scan runtime

local runtime = {}
local cachedDefs = {}
local dirty = true
local listeners = {}

local function debugPrint(...)
    if DEBUG then
        print("[ConstructionRuntime]", ...)
    end
end

local function isConstructionInstance(instance)
    return instance:IsA("Model") or instance:IsA("BasePart")
end

local function buildDefinition(instance)
    local previewSize = Vector3.new(6, 4, 6)
    local ok, size = pcall(function()
        return instance:GetExtentsSize()
    end)
    if ok and size then
        previewSize = size
    end
    return {
        Id = instance.Name,
        DisplayName = instance:GetAttribute("DisplayName") or instance.Name,
        ModelName = instance.Name,
        Category = instance:GetAttribute("Category") or "Construction",
        PreviewSize = previewSize,
        DisplayOrder = instance:GetAttribute("DisplayOrder"),
    }
end

local function rebuild()
    cachedDefs = {}
    for _, child in ipairs(ConstructionFolder:GetChildren()) do
        if isConstructionInstance(child) then
            table.insert(cachedDefs, buildDefinition(child))
            debugPrint("Model détecté", child.Name)
        end
    end
    table.sort(cachedDefs, function(a, b)
        local orderA = tonumber(a.DisplayOrder) or math.huge
        local orderB = tonumber(b.DisplayOrder) or math.huge
        if orderA == orderB then
            local labelA = a.DisplayName or a.Id
            local labelB = b.DisplayName or b.Id
            return labelA < labelB
        end
        return orderA < orderB
    end)
    dirty = false
    for _, callback in ipairs(listeners) do
        task.spawn(callback, runtime.GetDefinitions())
    end
end

local function flagDirty()
    dirty = true
    task.defer(rebuild)
end

ConstructionFolder.ChildAdded:Connect(flagDirty)
ConstructionFolder.ChildRemoved:Connect(flagDirty)
ConstructionFolder.DescendantRemoving:Connect(flagDirty)
ConstructionFolder.DescendantAdded:Connect(flagDirty)

function runtime.GetDefinitions()
    if dirty then
        rebuild()
    end
    local copy = {}
    for _, def in ipairs(cachedDefs) do
        copy[#copy + 1] = table.clone(def)
    end
    return copy
end

function runtime.GetDefinitionById(objectId)
    if dirty then
        rebuild()
    end
    for _, def in ipairs(cachedDefs) do
        if def.Id == objectId then
            return table.clone(def)
        end
    end
    return nil
end

function runtime.GetConstructionFolder()
    return ConstructionFolder
end

function runtime.GetTemplate(objectId)
    return ConstructionFolder:FindFirstChild(objectId)
end

function runtime.OnDefinitionsChanged(callback)
    table.insert(listeners, callback)
end

return runtime
