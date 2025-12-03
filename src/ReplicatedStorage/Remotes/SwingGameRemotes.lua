local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if folder then
        return folder
    end
    if RunService:IsServer() then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    else
        folder = parent:WaitForChild(name)
    end
    return folder
end

local remotesFolder = ensureFolder(ReplicatedStorage, "Remotes")
local swingFolder = ensureFolder(remotesFolder, "SwingGame")

local function getOrCreateRemote(name)
    local remote = swingFolder:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    if RunService:IsServer() then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = swingFolder
        return remote
    end
    return swingFolder:WaitForChild(name)
end

local SwingGameRemotes = {
    Folder = swingFolder,
    PushSwing = getOrCreateRemote("PushSwing"),
}

return SwingGameRemotes
