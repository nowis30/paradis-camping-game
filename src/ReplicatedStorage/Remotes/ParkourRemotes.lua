local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = script.Parent

local function getOrCreateRemote(className, name)
    local remote = folder:FindFirstChild(name)
    if remote and remote:IsA(className) then
        return remote
    end
    if remote then
        remote:Destroy()
    end
    remote = Instance.new(className)
    remote.Name = name
    remote.Parent = folder
    return remote
end

local ParkourRemotes = {
    StartParkour = getOrCreateRemote("RemoteFunction", "StartParkour"),
    FinishParkour = getOrCreateRemote("RemoteFunction", "FinishParkour"),
    CancelParkour = getOrCreateRemote("RemoteFunction", "CancelParkour"),
    UpdateTimer = getOrCreateRemote("RemoteEvent", "UpdateTimer"),
    ParkourResult = getOrCreateRemote("RemoteEvent", "ParkourResult"),
}

return ParkourRemotes
