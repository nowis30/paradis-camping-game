-- AxeUpgradeClient.client.lua
-- Interface minimale (temporaire) pour demander une upgrade de hache.
-- Appelle RemoteFunction RequestAxeUpgrade et affiche le résultat dans l'Output + petite notification.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local requestFunc = remotesFolder:WaitForChild("RequestAxeUpgrade")
local upgradeEvent = remotesFolder:WaitForChild("AxeUpgradeSucceeded")
local requestLegendaryFunc = remotesFolder:WaitForChild("RequestLegendaryUpgrade")
local legendaryFailEvent = remotesFolder:WaitForChild("LegendaryPurchaseFailed")
local MarketplaceService = game:GetService("MarketplaceService")
local axeConfig = require(ReplicatedStorage.Config.AxeUpgradeConfig)

-- Crée un ScreenGui léger si absent
local gui = Instance.new("ScreenGui")
gui.Name = "AxeUpgradeGui"
gui.ResetOnSpawn = false
pcall(function() gui.DisplayOrder = 100 end)

gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.42, 0, 0, 155)
frame.Position = UDim2.new(0, 10, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(30,30,35)
frame.BorderSizePixel = 0
frame.Parent = gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0,6)
uiCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 22)
title.Position = UDim2.new(0, 5, 0, 4)
title.BackgroundTransparency = 1
title.Text = "Amélioration Hache"
title.TextColor3 = Color3.fromRGB(255,220,160)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Parent = frame

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -10, 0, 68)
info.Position = UDim2.new(0, 5, 0, 28)
info.BackgroundTransparency = 1
info.TextWrapped = true
info.TextColor3 = Color3.new(1,1,1)
info.Font = Enum.Font.Gotham
info.TextScaled = true
info.Text = "Puissance actuelle: ?\nProchain coût: ?"
info.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 32)
button.Position = UDim2.new(0, 10, 0, 105)
button.BackgroundColor3 = Color3.fromRGB(70,50,40)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.Text = "Acheter upgrade"
button.AutoButtonColor = true
button.Parent = frame
local cornerBtn = Instance.new("UICorner")
cornerBtn.CornerRadius = UDim.new(0,6)
cornerBtn.Parent = button

local function findTier(power)
	for _, tier in ipairs(axeConfig.Tiers) do
		if tier.Power == power then return tier end
	end
	return nil
end

local function nextTier(power)
	local idx
	for i, tier in ipairs(axeConfig.Tiers) do
		if tier.Power == power then idx = i break end
	end
	if not idx then return nil end
	return axeConfig.Tiers[idx+1]
end

local function getFireLevel()
	local campfire = workspace:FindFirstChild("Campfire")
	if not campfire then return 0 end
	local fireLevel = campfire:FindFirstChild("FireLevel")
	if fireLevel and fireLevel:IsA("NumberValue") then return fireLevel.Value end
	return 0
end

local function refresh()
	local power = player:GetAttribute("AxePower") or 1
	local nTier = nextTier(power)
	local fireLevel = getFireLevel()
	if nTier then
		if nTier.CostRobux then
			info.Text = string.format("Puissance: %d\nLégendaire: %s\nFeu requis: %d (Actuel %d)\nRobux uniquement", power, nTier.Name, nTier.FireRequirement or 0, fireLevel)
			button.Text = "Acheter Robux" -- Bouton déclenche purchase
			button.Active = fireLevel >= (nTier.FireRequirement or 0)
			button.AutoButtonColor = button.Active
		else
			info.Text = string.format("Puissance: %d\nSuivant: %s (Cost %d)\nFeu requis: %d (Actuel %d)", power, nTier.Name, nTier.Cost, nTier.FireRequirement or 0, fireLevel)
			button.Text = "Acheter upgrade"
			button.Active = fireLevel >= (nTier.FireRequirement or 0)
			button.AutoButtonColor = button.Active
		end
	else
		info.Text = string.format("Puissance: %d\nDernier palier atteint", power)
		button.Text = "Max atteint"
		button.Active = false
		button.AutoButtonColor = false
	end
end

button.MouseButton1Click:Connect(function()
	local power = player:GetAttribute("AxePower") or 1
	local nTier = nextTier(power)
	if not nTier then return end
	if nTier.CostRobux then
		local ok, msg, productId = requestLegendaryFunc:InvokeServer()
		print("Demande légendaire:", ok, msg, productId)
		if ok and productId then
			MarketplaceService:PromptProductPurchase(player, productId)
		else
			button.BackgroundColor3 = Color3.fromRGB(140,40,40)
			task.delay(0.25, function()
				button.BackgroundColor3 = Color3.fromRGB(70,50,40)
			end)
		end
	else
		local success, msg = requestFunc:InvokeServer()
		print("Upgrade hache:", success, msg)
		if success then
			refresh()
		else
			button.BackgroundColor3 = Color3.fromRGB(140,40,40)
			task.delay(0.25, function()
				button.BackgroundColor3 = Color3.fromRGB(70,50,40)
			end)
		end
	end
end)

upgradeEvent.OnClientEvent:Connect(function(p, newPower, name)
	if p == player then
		print("Nouvelle hache:", name, "Puissance", newPower)
	end
end)

player:GetAttributeChangedSignal("AxePower"):Connect(refresh)
-- Mise à jour régulière du feu
task.spawn(function()
	while true do
		refresh()
		wait(2)
	end
end)
refresh()

-- Billboard sur hache pour coût suivant
local function updateAxeBillboard(tool)
	if not tool then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local bb = handle:FindFirstChild("UpgradeBillboard")
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = "UpgradeBillboard"
		bb.Size = UDim2.fromOffset(120,50)
		bb.StudsOffset = Vector3.new(0, handle.Size.Y/2 + 0.5,0)
		bb.AlwaysOnTop = true
		bb.Parent = handle
		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.fromScale(1,1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBold
		tl.TextScaled = true
		tl.TextColor3 = Color3.fromRGB(255,240,200)
		tl.Parent = bb
	end
	local textLabel = bb:FindFirstChild("Text")
	if textLabel then
		local power = player:GetAttribute("AxePower") or 1
		local nTier = nextTier(power)
		if nTier then
			if nTier.CostRobux then
				textLabel.Text = "Légendaire\nRobux"
			else
				textLabel.Text = "Next: " .. nTier.Cost
			end
		else
			textLabel.Text = "Max"
		end
	end
end

local function hookTool(tool)
	if tool:IsA("Tool") then
		updateAxeBillboard(tool)
		tool.AncestryChanged:Connect(function()
			if tool.Parent == player.Character then
				updateAxeBillboard(tool)
			end
		end)
	end
end

player.CharacterAdded:Connect(function(char)
	for _, child in ipairs(char:GetChildren()) do
		hookTool(child)
	end
	char.ChildAdded:Connect(hookTool)
end)

if player.Character then
	for _, child in ipairs(player.Character:GetChildren()) do
		hookTool(child)
	end
	player.Character.ChildAdded:Connect(hookTool)
end