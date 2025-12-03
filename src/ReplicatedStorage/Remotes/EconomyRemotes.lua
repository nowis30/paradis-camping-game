--[[
    EconomyRemotes
    Remotes dédiés à la synchronisation de l'argent côté client.
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

local EconomyRemotes = {
    CashUpdated = getOrCreateRemote("RemoteEvent", "EconomyCashUpdated"),
    IncomeUpdated = getOrCreateRemote("RemoteEvent", "EconomyIncomeUpdated"),
    RequestSnapshot = getOrCreateRemote("RemoteFunction", "EconomyRequestSnapshot"),
    BoostUpdated = getOrCreateRemote("RemoteEvent", "EconomyBoostUpdated"),
    PassiveTick = getOrCreateRemote("RemoteEvent", "EconomyPassiveTick"),
    RequestManualSave = getOrCreateRemote("RemoteFunction", "EconomyRequestManualSave"),
}

return EconomyRemotes
