-- DiagnosticLogs.server.lua
-- Script de diagnostic pour identifier pourquoi les bûches ne sont pas reçues

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- N'exécute ce script que dans Studio (pas en production)
if not RunService:IsStudio() then
	return
end

print("=== [DIAGNOSTIC WOODCUTTING] Démarrage ===")

-- Vérifier la structure Workspace
task.wait(2)

local woodNodes = Workspace:FindFirstChild("WoodcuttingNodes")
if woodNodes then
	print("[DIAGNOSTIC] ✓ WoodcuttingNodes trouvé avec", #woodNodes:GetChildren(), "enfants")
	for i, node in ipairs(woodNodes:GetChildren()) do
		if i <= 3 then
			print(string.format("  - %s (IsActive=%s, HitsRemaining=%s)", 
				node.Name,
				tostring(node:GetAttribute("IsActive")),
				tostring(node:GetAttribute("HitsRemaining"))
			))
			
			-- Vérifier ProximityPrompt
			local hasPrompt = false
			for _, desc in ipairs(node:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					hasPrompt = true
					print(string.format("    ✓ ProximityPrompt trouvé: %s", desc:GetFullName()))
				end
			end
			if not hasPrompt then
				warn(string.format("    ✗ AUCUN ProximityPrompt dans %s!", node.Name))
			end
		end
	end
else
	warn("[DIAGNOSTIC] ✗ WoodcuttingNodes INTROUVABLE dans Workspace!")
end

-- Vérifier les attributs des joueurs
Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	print(string.format("[DIAGNOSTIC] Joueur %s connecté:", player.Name))
	print(string.format("  - AxePower = %s", tostring(player:GetAttribute("AxePower"))))
	print(string.format("  - Logs = %s", tostring(player:GetAttribute("Logs"))))
	print(string.format("  - Money = %s", tostring(player:GetAttribute("Money"))))
	
	-- Surveiller les changements d'attributs
	player.AttributeChanged:Connect(function(attr)
		if attr == "Logs" then
			local newValue = player:GetAttribute("Logs")
			print(string.format("[DIAGNOSTIC] 🪵 %s -> Logs changé à %d", player.Name, newValue))
		end
	end)
end)

-- Pour les joueurs déjà présents
for _, player in ipairs(Players:GetPlayers()) do
	print(string.format("[DIAGNOSTIC] Joueur existant %s:", player.Name))
	print(string.format("  - AxePower = %s", tostring(player:GetAttribute("AxePower"))))
	print(string.format("  - Logs = %s", tostring(player:GetAttribute("Logs"))))
	print(string.format("  - Money = %s", tostring(player:GetAttribute("Money"))))
	
	player.AttributeChanged:Connect(function(attr)
		if attr == "Logs" then
			local newValue = player:GetAttribute("Logs")
			print(string.format("[DIAGNOSTIC] 🪵 %s -> Logs changé à %d", player.Name, newValue))
		end
	end)
end

print("=== [DIAGNOSTIC WOODCUTTING] Surveillance active ===")
