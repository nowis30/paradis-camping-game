--[[
    CampingDetailsRemotes.lua
    Remotes pour communiquer les détails du camping entre serveur et client
]]

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

local CampingDetailsRemotes = {
    GetCampingDetails = getOrCreateRemote("RemoteFunction", "GetCampingDetails"),
    RequestPurchaseItem = getOrCreateRemote("RemoteEvent", "RequestPurchaseItem"),
    CampingDetailsUpdated = getOrCreateRemote("RemoteEvent", "CampingDetailsUpdated"),
}

return CampingDetailsRemotes
