-- Paradis Template Service
-- Ensures ReplicatedStorage.Paradis.{Templates,Remotes} exist and exposes Remote API
-- RemoteFunction: GetParadisTemplates -> returns { {name, category, price}, ... }
-- RemoteEvent: RequestPlaceTemplate(player, templateName) -> clones model a few studs ahead of player

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Create/get Paradis root in ReplicatedStorage
local paradisFolder = ReplicatedStorage:FindFirstChild("Paradis")
if not paradisFolder then
	paradisFolder = Instance.new("Folder")
	paradisFolder.Name = "Paradis"
	paradisFolder.Parent = ReplicatedStorage
end

-- Create/get Templates folder (models to drop in Studio)
local templatesFolder = paradisFolder:FindFirstChild("Templates")
if not templatesFolder then
	templatesFolder = Instance.new("Folder")
	templatesFolder.Name = "Templates"
	templatesFolder.Parent = paradisFolder
end

-- Create/get Remotes folder
local remotesFolder = paradisFolder:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = paradisFolder
end

-- RemoteFunction: GetParadisTemplates
local getTemplatesFn = remotesFolder:FindFirstChild("GetParadisTemplates")
if not getTemplatesFn then
	getTemplatesFn = Instance.new("RemoteFunction")
	getTemplatesFn.Name = "GetParadisTemplates"
	getTemplatesFn.Parent = remotesFolder
end

-- RemoteEvent: RequestPlaceTemplate
local requestPlaceEvt = remotesFolder:FindFirstChild("RequestPlaceTemplate")
if not requestPlaceEvt then
	requestPlaceEvt = Instance.new("RemoteEvent")
	requestPlaceEvt.Name = "RequestPlaceTemplate"
	requestPlaceEvt.Parent = remotesFolder
end

-- Optional future feedback channel
local feedbackEvt = remotesFolder:FindFirstChild("TemplateFeedback")
if not feedbackEvt then
	feedbackEvt = Instance.new("RemoteEvent")
	feedbackEvt.Name = "TemplateFeedback"
	feedbackEvt.Parent = remotesFolder
end

-- Load registry (shared) lazily to ensure folders are ready
local TemplateRegistry
local function getRegistry()
	if not TemplateRegistry then
		TemplateRegistry = require(paradisFolder:WaitForChild("TemplateRegistry"))
	end
	return TemplateRegistry
end

-- Anti-spam per player (simple cooldown)
local lastPlaceAt: { [number]: number } = {}
local PLACE_COOLDOWN = 0.75 -- seconds

-- Utility: find ground position by raycasting down
local function getGroundPositionNear(pos: Vector3, ignoreInstances: { Instance }?)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreInstances or {}
	rayParams.IgnoreWater = false
	local origin = pos + Vector3.new(0, 50, 0)
	local dir = Vector3.new(0, -500, 0)
	local result = Workspace:Raycast(origin, dir, rayParams)
	if result then
		return result.Position
	end
	return pos
end

-- Return simplified list to clients
getTemplatesFn.OnServerInvoke = function(player)
	local reg = getRegistry()
	local out = {}
	for _, info in reg.getAll() do
		out[#out+1] = {
			name = info.name,
			category = info.category,
			price = info.price,
		}
	end
	return out
end

-- Handle placement requests
requestPlaceEvt.OnServerEvent:Connect(function(player, templateName)
	if typeof(templateName) ~= "string" then return end
	if #templateName == 0 or #templateName > 100 then return end
	local now = os.clock()
	local last = lastPlaceAt[player.UserId]
	if last and (now - last) < PLACE_COOLDOWN then
		return -- ignore spam
	end
	lastPlaceAt[player.UserId] = now

	local reg = getRegistry()
	local info = reg.getByName(templateName)
	if not info or typeof(info.model) ~= "Instance" then
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Place a few studs ahead of the player, projected to ground.
	local ahead = hrp.CFrame.Position + hrp.CFrame.LookVector * 8
	local groundPos = getGroundPositionNear(ahead, { character })

	local clone: Model = info.model:Clone()
	clone.Name = info.name
	clone.Parent = Workspace

	-- If model has a PrimaryPart, pivot to the ground position; otherwise try best-effort
	if clone.PrimaryPart then
		clone:PivotTo(CFrame.new(groundPos))
	else
		-- Try to find a BasePart to position
		local firstPart: BasePart? = clone:FindFirstChildWhichIsA("BasePart", true)
		if firstPart then
			local offset = groundPos - firstPart.Position
			for _, part in clone:GetDescendants() do
				if part:IsA("BasePart") then
					part.Position += offset
				end
			end
		end
	end

	-- TODO: Later, replace world placement with logic to place inside player's owned parcel
	-- You can also enforce parcel boundaries here when the parcel system is ready.
end)
