-- TestWoodcuttingPrompts.server.lua
-- PRODUCTION READY: Diagnostics complets du système de woodcutting

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

task.wait(3) -- Attendre que tout soit chargé

print("=== DIAGNOSTIC WOODCUTTING SYSTEM ===")

-- 1. Vérifier WoodcuttingNodes
local folder = Workspace:FindFirstChild("WoodcuttingNodes")
if not folder then
	warn("❌ WoodcuttingNodes folder introuvable dans Workspace")
	return
end

print("✅ WoodcuttingNodes trouvé avec", #folder:GetChildren(), "enfants")

-- 2. Vérifier chaque LogNode
for _, node in ipairs(folder:GetChildren()) do
	if node:IsA("Model") then
		print("\n📦 LogNode:", node.Name)
		
		-- Chercher les ProximityPrompts
		local prompts = {}
		for _, desc in ipairs(node:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				table.insert(prompts, desc)
			end
		end
		
		if #prompts == 0 then
			warn("  ⚠️ Aucun ProximityPrompt trouvé")
		else
			print("  ✅", #prompts, "ProximityPrompt(s) trouvé(s)")
			
			for i, prompt in ipairs(prompts) do
				print(string.format("    [%d] %s:", i, prompt:GetFullName()))
				print("        ActionText:", prompt.ActionText)
				print("        MaxActivationDistance:", prompt.MaxActivationDistance)
				print("        RequiresLineOfSight:", prompt.RequiresLineOfSight)
				print("        HoldDuration:", prompt.HoldDuration)
				print("        KeyboardKeyCode:", prompt.KeyboardKeyCode)
				print("        Enabled:", prompt.Enabled)
				print("        __BoundWoodcut:", prompt:GetAttribute("__BoundWoodcut"))
			end
		end
		
		-- Vérifier les attributs du node
		print("  📊 Attributs du node:")
		print("      IsActive:", node:GetAttribute("IsActive"))
		print("      HitsRemaining:", node:GetAttribute("HitsRemaining"))
		print("      LogsObtained:", node:GetAttribute("LogsObtained"))
	end
end

-- 3. Vérifier les RemoteEvents
print("\n🔌 Vérification des RemoteEvents:")
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if remotesFolder then
	local woodcutEvents = {"WoodcutHit", "WoodcutBreak", "LogsUpdated", "CollectLog", "FuelCampfire"}
	for _, eventName in ipairs(woodcutEvents) do
		local remote = remotesFolder:FindFirstChild(eventName)
		if remote then
			print("  ✅", eventName, "existe")
		else
			warn("  ❌", eventName, "MANQUANT")
		end
	end
else
	warn("❌ Dossier Remotes introuvable")
end

-- 4. Vérifier les axes dans Workspace
print("\n🪓 Vérification des axes dans Workspace:")
local axes = {"Axe", "Axe1", "Axe2"}
for _, axeName in ipairs(axes) do
	local axe = Workspace:FindFirstChild(axeName)
	if axe then
		print("  ✅", axeName, "existe dans Workspace")
	else
		local axeInRS = ReplicatedStorage:FindFirstChild(axeName)
		if axeInRS then
			print("  ✅", axeName, "existe dans ReplicatedStorage")
		else
			warn("  ⚠️", axeName, "introuvable")
		end
	end
end

-- 5. Vérifier les joueurs
print("\n👤 Joueurs présents:")
for _, player in ipairs(Players:GetPlayers()) do
	print(string.format("  - %s (AxePower: %s, Logs: %s)", 
		player.Name, 
		tostring(player:GetAttribute("AxePower")), 
		tostring(player:GetAttribute("Logs"))
	))
end

print("\n=== FIN DIAGNOSTIC ===")
