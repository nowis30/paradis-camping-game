local ServerScriptService = game:GetService("ServerScriptService")
local paradisFolder = ServerScriptService:FindFirstChild("ParadisServer") or script.Parent
local CampingWorldGenerator = require(paradisFolder:WaitForChild("CampingWorldGenerator"))

local function generateWorld()
	if typeof(CampingWorldGenerator) ~= "table" or typeof(CampingWorldGenerator.Generate) ~= "function" then
		warn("[Paradis][WorldDebug] CampingWorldGenerator.Generate indisponible, génération annulée.")
		return
	end

	print("[Paradis][WorldDebug] Lancement du CampingWorldGenerator...")
	CampingWorldGenerator.Generate()
	print("[Paradis][WorldDebug] Monde généré via CampingWorldGenerator.")
end

generateWorld()
