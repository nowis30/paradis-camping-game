-- BackgroundMusic.server.lua
-- Joue une musique d'ambiance dans tout le jeu

local SoundService = game:GetService("SoundService")

-- ====================================
-- CONFIGURATION MUSIQUE
-- ====================================
local MUSIC_PLAYLIST = {
	"rbxassetid://115222151625604", -- Je spawn encore dans mon petit coin de paradis
	"rbxassetid://115905909512113", -- La vie est belle
	"rbxassetid://117790257108974"  -- Chanson roblox
}
local MUSIC_VOLUME = 0.5 -- Volume (0 à 1)
local MUSIC_FADE_TIME = 2 -- Temps de fondu en secondes

-- ====================================
-- CRÉATION DE LA MUSIQUE
-- ====================================

-- Créer le SoundGroup pour la musique (optionnel, pour contrôler le volume global)
local musicGroup = SoundService:FindFirstChild("MusicGroup")
if not musicGroup then
	musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "MusicGroup"
	musicGroup.Volume = 1
	musicGroup.Parent = SoundService
end

-- Créer le son de fond
local backgroundMusic = Instance.new("Sound")
backgroundMusic.Name = "BackgroundMusic"
backgroundMusic.Volume = 0 -- Commence à 0 pour le fondu
backgroundMusic.SoundGroup = musicGroup
backgroundMusic.Parent = SoundService

local currentTrackIndex = 1

-- Fonction pour jouer une chanson avec fondu
local function playTrackWithFade(trackIndex)
	local assetId = MUSIC_PLAYLIST[trackIndex]
	if not assetId then
		trackIndex = 1
		assetId = MUSIC_PLAYLIST[1]
	end
	
	currentTrackIndex = trackIndex
	backgroundMusic.SoundId = assetId
	backgroundMusic:Play()
	
	-- Fondu d'entrée
	local targetVolume = MUSIC_VOLUME
	local steps = 20
	local stepTime = MUSIC_FADE_TIME / steps
	local volumeIncrement = targetVolume / steps
	
	for i = 1, steps do
		task.wait(stepTime)
		backgroundMusic.Volume = math.min(backgroundMusic.Volume + volumeIncrement, targetVolume)
	end
	
	print(string.format("[BackgroundMusic] Musique démarrée (Piste %d/%d, ID: %s, Volume: %.2f)", 
		currentTrackIndex, #MUSIC_PLAYLIST, assetId, MUSIC_VOLUME))
end

-- Démarrer la première piste
playTrackWithFade(1)

-- Passer à la piste suivante quand une chanson se termine
backgroundMusic.Ended:Connect(function()
	local nextIndex = currentTrackIndex + 1
	if nextIndex > #MUSIC_PLAYLIST then
		nextIndex = 1
	end
	playTrackWithFade(nextIndex)
end)

-- ====================================
-- CONTRÔLE OPTIONNEL (Commandes)
-- ====================================

-- Fonction pour ajuster le volume
local function setMusicVolume(volume)
	backgroundMusic.Volume = math.clamp(volume, 0, 1)
	print(string.format("[BackgroundMusic] Volume ajusté: %.2f", volume))
end

-- Fonction pour mettre en pause/reprendre
local function toggleMusic()
	if backgroundMusic.IsPlaying then
		backgroundMusic:Pause()
		print("[BackgroundMusic] Musique en pause")
	else
		backgroundMusic:Resume()
		print("[BackgroundMusic] Musique reprise")
	end
end

-- Exposer les fonctions globalement (optionnel, pour debug)
_G.SetMusicVolume = setMusicVolume
_G.ToggleMusic = toggleMusic

print("[BackgroundMusic] Service initialisé - Commandes disponibles: _G.SetMusicVolume(0.5), _G.ToggleMusic()")
