-- FishingMiniGameClient.client.lua
-- Gère le mini-jeu de pêche côté client : UI, input E, et animation du bras levé

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local startMiniGameEvent = remotesFolder:WaitForChild("StartFishingMiniGame")
local resultEvent = remotesFolder:WaitForChild("FishingMiniGameResult")

-- Animation de lever le bras (ID d'animation de pêche Roblox ou custom)
local REEL_ARM_ANIMATION_ID = "rbxassetid://0" -- Remplace par une vraie animation si disponible
local reelArmTrack

-- Charge l'animation de lever le bras
local function loadReelAnimation()
	if REEL_ARM_ANIMATION_ID == "rbxassetid://0" then
		return nil -- Pas d'animation disponible
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = REEL_ARM_ANIMATION_ID
	return humanoid:LoadAnimation(anim)
end

-- Démarre le mini-jeu quand le serveur l'ordonne
startMiniGameEvent.OnClientEvent:Connect(function(fishRarity)
	print("[FishingMiniGameClient] Démarrage mini-jeu pour rareté:", fishRarity)
	
	-- Charge le module du mini-jeu
	local TensionMiniGame = require(ReplicatedStorage:WaitForChild("FishingTensionMiniGame"))
	
	-- Charge l'animation du bras
	reelArmTrack = loadReelAnimation()
	
	-- Hook le mini-jeu pour jouer l'animation quand le joueur tire
	local originalRun = TensionMiniGame.Run
	TensionMiniGame.Run = function(plr, rarity)
		-- Lance le mini-jeu original avec animation du bras
		local gui -- référence à l'UI créée
		local isPulling = false
		
		-- Patch le comportement d'input pour ajouter l'animation
		local UserInputService = game:GetService("UserInputService")
		local inputConnection
		
		inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
			if input.KeyCode == Enum.KeyCode.E then
				isPulling = true
				-- Joue l'animation du bras levé
				if reelArmTrack then
					reelArmTrack:Play(0.1, 1, 1.2) -- Joue en boucle plus rapide
				end
			end
		end)
		
		local inputEndConnection
		inputEndConnection = UserInputService.InputEnded:Connect(function(input, processed)
			if input.KeyCode == Enum.KeyCode.E then
				isPulling = false
				-- Arrête l'animation du bras
				if reelArmTrack then
					reelArmTrack:Stop(0.2)
				end
			end
		end)
		
		-- Lance le mini-jeu
		local success = originalRun(plr, rarity)
		
		-- Nettoie les connections
		if inputConnection then inputConnection:Disconnect() end
		if inputEndConnection then inputEndConnection:Disconnect() end
		if reelArmTrack then reelArmTrack:Stop(0.1) end
		
		return success
	end
	
	-- Exécute le mini-jeu
	local success = TensionMiniGame.Run(player, fishRarity)
	
	-- Envoie le résultat au serveur
	resultEvent:FireServer(success)
	print("[FishingMiniGameClient] Résultat envoyé:", success)
end)

-- Recharge l'animation si le personnage respawn
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	reelArmTrack = loadReelAnimation()
end)
