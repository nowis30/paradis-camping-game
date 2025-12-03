--[[
    BuildRemotes
    Centralise la création/récupération des RemoteEvents & RemoteFunctions
    utilisés par Paradis des Parcelles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = script.Parent

local function getOrCreateRemote(className, name)
    local remote = folder:FindFirstChild(name)
    if remote and remote:IsA(className) then
        return remote
    end

    remote = Instance.new(className)
    remote.Name = name
    remote.Parent = folder
    return remote
end

local BuildRemotes = {
    RequestClaim = getOrCreateRemote("RemoteFunction", "RequestClaim"),
    RequestPlacement = getOrCreateRemote("RemoteFunction", "RequestPlacement"),
    RequestRemove = getOrCreateRemote("RemoteFunction", "RequestRemove"),
        RequestMove = getOrCreateRemote("RemoteFunction", "RequestMove"),
    TrailerRequestPlacement = getOrCreateRemote("RemoteFunction", "TrailerRequestPlacement"),
    TrailerRequestRemove = getOrCreateRemote("RemoteFunction", "TrailerRequestRemove"),
    PlotAssigned = getOrCreateRemote("RemoteEvent", "PlotAssigned"),
    ToggleBuildMode = getOrCreateRemote("RemoteEvent", "ToggleBuildMode"),
    PlacedObjectsUpdated = getOrCreateRemote("RemoteEvent", "PlacedObjectsUpdated"),
    TrailerStateUpdated = getOrCreateRemote("RemoteEvent", "TrailerStateUpdated"),
}

return BuildRemotes
