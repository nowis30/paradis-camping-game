--[[
    FishingShopRemotes
    Remotes pour le Pro Shop de pêche
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local FishingShopFolder = RemotesFolder:FindFirstChild("FishingShop")
if not FishingShopFolder then
    FishingShopFolder = Instance.new("Folder")
    FishingShopFolder.Name = "FishingShop"
    FishingShopFolder.Parent = RemotesFolder
end

local function getOrCreate(name, className)
    local existing = FishingShopFolder:FindFirstChild(name)
    if existing then
        return existing
    end
    local obj = Instance.new(className)
    obj.Name = name
    obj.Parent = FishingShopFolder
    return obj
end

local FishingShopRemotes = {
    BuyRod = getOrCreate("BuyRod", "RemoteEvent"),
    BuyBait = getOrCreate("BuyBait", "RemoteEvent"),
    SetCurrentRod = getOrCreate("SetCurrentRod", "RemoteEvent"),
    GetGear = getOrCreate("GetGear", "RemoteFunction"),
    UseFishAsBait = getOrCreate("UseFishAsBait", "RemoteEvent"),
    -- Vente poissonnerie
    SellAllFish = getOrCreate("SellAllFish", "RemoteEvent"),
    SellFish = getOrCreate("SellFish", "RemoteEvent"),
    -- Codex
    GetCodex = getOrCreate("GetCodex", "RemoteFunction"),
}

return FishingShopRemotes
