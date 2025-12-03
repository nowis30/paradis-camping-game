-- DiagnosticCampfire.server.lua
-- Script pour diagnostiquer la structure du Campfire

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- N'exécute ce script que dans Studio (pas en production)
if not RunService:IsStudio() then
	return
end

print("=== [DIAGNOSTIC CAMPFIRE] Démarrage ===")

task.wait(2)

local campfire = Workspace:FindFirstChild("Campfire")
if campfire then
	print("[DIAGNOSTIC] ✓ Campfire trouvé:", campfire:GetFullName())
	print("[DIAGNOSTIC] Enfants de Campfire:")
	
	for _, child in ipairs(campfire:GetChildren()) do
		print(string.format("  - %s (%s)", child.Name, child.ClassName))
		
		-- Chercher ProximityPrompt
		if child:IsA("BasePart") or child:IsA("Model") then
			for _, desc in ipairs(child:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					print(string.format("    ✓ ProximityPrompt trouvé: %s", desc:GetFullName()))
					print(string.format("      ActionText: %s", desc.ActionText))
					print(string.format("      MaxDistance: %d", desc.MaxActivationDistance))
				end
			end
		end
	end
	
	-- Chercher FireBase spécifiquement
	local fireBase = campfire:FindFirstChild("FireBase")
	if fireBase then
		print("[DIAGNOSTIC] ✓ FireBase trouvé:", fireBase:GetFullName())
		print(string.format("  Type: %s, Position: %s", fireBase.ClassName, tostring(fireBase.Position)))
	else
		warn("[DIAGNOSTIC] ✗ FireBase INTROUVABLE - Le ProximityPrompt ne peut pas être créé!")
		print("[DIAGNOSTIC] SOLUTION: Renommez une part du Campfire en 'FireBase' ou ajoutez-en une")
	end
	
	-- Chercher Fire et PointLight
	local fireEffect = campfire:FindFirstChildOfClass("Fire", true)
	local pointLight = campfire:FindFirstChildOfClass("PointLight", true)
	
	if fireEffect then
		print("[DIAGNOSTIC] ✓ Fire effect trouvé:", fireEffect:GetFullName())
	else
		warn("[DIAGNOSTIC] ✗ Fire effect introuvable")
	end
	
	if pointLight then
		print("[DIAGNOSTIC] ✓ PointLight trouvé:", pointLight:GetFullName())
	else
		warn("[DIAGNOSTIC] ✗ PointLight introuvable")
	end
	
else
	warn("[DIAGNOSTIC] ✗ Campfire INTROUVABLE dans Workspace!")
end

print("=== [DIAGNOSTIC CAMPFIRE] Terminé ===")
