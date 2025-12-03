-- TestWoodcuttingPrompts.server.lua
-- Script de test pour vérifier les ProximityPrompts des LogNodes

local Workspace = game:GetService("Workspace")

task.wait(3) -- Attendre que tout soit chargé

print("=== TEST WOODCUTTING PROMPTS ===")

local folder = Workspace:FindFirstChild("WoodcuttingNodes")
if not folder then
	warn("❌ WoodcuttingNodes folder introuvable dans Workspace")
	return
end

print("✅ WoodcuttingNodes trouvé avec", #folder:GetChildren(), "enfants")

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
	end
end

print("\n=== FIN TEST ===")
