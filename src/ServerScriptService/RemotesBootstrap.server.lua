-- RemotesBootstrap.server.lua
-- Assure que tous les RemoteEvents/RemoteFunctions critiques existent tôt pour éviter les Infinite Yield.
-- Centralise la création au lieu de compter sur des ModuleScripts non requis.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local remotesFolder = ensureFolder()

local function ensureRemoteEvent(name)
	local r = remotesFolder:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then return r end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = remotesFolder
	return ev
end

local function ensureRemoteFunction(name)
	local r = remotesFolder:FindFirstChild(name)
	if r and r:IsA("RemoteFunction") then return r end
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = remotesFolder
	return rf
end

-- Liste des remotes requises par anciens et nouveaux scripts
local EVENT_NAMES = {
	"WoodcutHit",
	"WoodcutBreak",
	"CampfireFed",
	"LogsUpdated",
	"CollectLog",
	"FuelCampfire",
	"GrantIncome",
	"AxeUpgradeSucceeded",
	"LegendaryPurchaseFailed",
	"StartFishingMiniGame",
	"FishingMiniGameResult",
	"ProShopPurchaseResult",
	"ProShopRefresh",
	"MagicLogExpired",
}

local FUNCTION_NAMES = {
	"RequestAxeUpgrade",
	"RequestLegendaryUpgrade",
	"RequestProShopPurchase",
	"GetProShopData",
}

for _, n in ipairs(EVENT_NAMES) do
	ensureRemoteEvent(n)
end
for _, n in ipairs(FUNCTION_NAMES) do
	ensureRemoteFunction(n)
end

print("[RemotesBootstrap] Remotes initialisés:", #EVENT_NAMES, "events,", #FUNCTION_NAMES, "functions")

-- Assurer la présence des dossiers de remotes spécifiques (clients attendent ces dossiers)
local function ensurePlainFolder(name)
	local f = ReplicatedStorage:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = ReplicatedStorage
	end
	return f
end

local parkourFolder = ensurePlainFolder("ParkourRemotes")
local kartFolder = ensurePlainFolder("GolfKartRemotes")

-- Créer les RemoteEvents spécifiques pour éviter les Infinite Yield
local function ensureRemoteInFolder(folder, name, className)
    local r = folder:FindFirstChild(name)
    if r and r.ClassName == className then return r end
    local remote = Instance.new(className)
    remote.Name = name
    remote.Parent = folder
    return remote
end

-- Parkour remotes
ensureRemoteInFolder(parkourFolder, "StartParkour", "RemoteEvent")
ensureRemoteInFolder(parkourFolder, "EndParkour", "RemoteEvent")
ensureRemoteInFolder(parkourFolder, "FinishParkour", "RemoteEvent")
ensureRemoteInFolder(parkourFolder, "CheckpointReached", "RemoteEvent")

-- Golf Kart remotes
ensureRemoteInFolder(kartFolder, "ShiftGear", "RemoteEvent")
ensureRemoteInFolder(kartFolder, "SetThrottle", "RemoteEvent")
ensureRemoteInFolder(kartFolder, "SetBrake", "RemoteEvent")
ensureRemoteInFolder(kartFolder, "SetSteering", "RemoteEvent")
ensureRemoteInFolder(kartFolder, "RequestKartPurchase", "RemoteEvent")
ensureRemoteInFolder(kartFolder, "RequestKartSpawn", "RemoteEvent")
ensureRemoteInFolder(kartFolder, "RequestKartDespawn", "RemoteEvent")
ensureRemoteInFolder(kartFolder, "RequestKartUpgrade", "RemoteEvent")
ensureRemoteInFolder(kartFolder, "NotifyKartStatus", "RemoteEvent")
