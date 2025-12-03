local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

-- Crée le dossier racine FishModels + sous-dossiers si manquants
local root = ensureFolder(ReplicatedStorage, "FishModels")
ensureFolder(root, "Common")
ensureFolder(root, "Rare")
ensureFolder(root, "Legendaire")

print("[Paradis][FishModelsBootstrap] Dossier ReplicatedStorage/FishModels prêt (Common/Rare/Legendaire)")
