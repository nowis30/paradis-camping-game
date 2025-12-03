--[[
    EconomyClient
    Affiche l'argent et le revenu passif du joueur via un petit HUD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local EconomyRemotes = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EconomyRemotes"))
local HudEconomy = require(playerGui:WaitForChild("ParadisGui"):WaitForChild("HudEconomy"))
local EconomyFeedback = require(playerGui:WaitForChild("ParadisGui"):WaitForChild("EconomyFeedback"))

local hud = HudEconomy.create(playerGui)
local feedback = EconomyFeedback.new(hud.ScreenGui)
local currentBoostMultiplier = 1
local latestIncomeValue = 0

local function formatNumber(value)
    value = tonumber(value) or 0
    return math.floor(value * 100 + 0.5) / 100
end

local function formatText(value)
    return string.format("%.2f", formatNumber(value))
end

local function updateCash(value)
    hud.CashLabel.Text = string.format("Argent : %s $", formatText(value))
end

local function updateIncome(value)
    latestIncomeValue = tonumber(value) or 0
    local baseText = string.format("+%s $ / sec", formatText(latestIncomeValue))
    if currentBoostMultiplier and currentBoostMultiplier > 1.01 then
        baseText = string.format("%s (x%.2f)", baseText, currentBoostMultiplier)
    end
    hud.IncomeLabel.Text = baseText
end

local function updateBoost(payload)
    payload = payload or {}
    currentBoostMultiplier = payload.Multiplier or 1
    if payload.Active then
        local label = payload.Name or "Boost actif"
        local timeLeft = payload.TimeLeft or 0
        hud.BoostLabel.Text = string.format("Boost : %s (%.0fs)", label, math.max(0, math.floor(timeLeft)))
    else
        hud.BoostLabel.Text = "Boost : Aucun"
    end
    updateIncome(latestIncomeValue)
end

local success, snapshot = pcall(function()
    return EconomyRemotes.RequestSnapshot:InvokeServer()
end)
if success and snapshot then
    updateCash(snapshot.Cash)
    updateIncome(snapshot.IncomePerSecond)
    updateBoost(snapshot.Boost)
else
    updateCash(0)
    updateIncome(0)
end

EconomyRemotes.CashUpdated.OnClientEvent:Connect(updateCash)
EconomyRemotes.IncomeUpdated.OnClientEvent:Connect(updateIncome)
EconomyRemotes.BoostUpdated.OnClientEvent:Connect(updateBoost)
EconomyRemotes.PassiveTick.OnClientEvent:Connect(function(amount, reason, multiplier)
    feedback:Show(amount, reason, multiplier)
end)

if hud.SaveButton then
    local saving = false
    hud.SaveButton.MouseButton1Click:Connect(function()
        if saving then
            return
        end
        saving = true
        hud.SaveButton.Text = "Sauvegarde..."
        local ok, result = pcall(function()
            return EconomyRemotes.RequestManualSave:InvokeServer()
        end)
        if ok and result and result.Success then
            feedback:Show(0, "Sauvegarde réussie")
        else
            feedback:Show(0, "Erreur de sauvegarde")
        end
        task.delay(2, function()
            hud.SaveButton.Text = "Sauvegarder"
            saving = false
        end)
    end)
end

local function bindLeaderstat(statName, callback)
    local function attach(stat)
        callback(stat.Value)
        stat:GetPropertyChangedSignal("Value"):Connect(function()
            callback(stat.Value)
        end)
    end

    local function inspect(folder)
        local stat = folder:FindFirstChild(statName)
        if stat then
            attach(stat)
        end
        folder.ChildAdded:Connect(function(child)
            if child.Name == statName then
                attach(child)
            end
        end)
    end

    local existing = LocalPlayer:FindFirstChild("leaderstats")
    if existing then
        inspect(existing)
    end

    LocalPlayer.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            inspect(child)
        end
    end)
end

bindLeaderstat("Cash", updateCash)
bindLeaderstat("IncomePerSecond", updateIncome)

-- Afficher le nombre de bûches transportées
local function updateLogs()
    local logs = LocalPlayer:GetAttribute("Logs") or 0
    if hud.LogsLabel then
        hud.LogsLabel.Text = string.format("🪵 Bûches : %d", logs)
    end
end

-- Mise à jour initiale
updateLogs()

-- Écouter les changements d'attribut Logs
LocalPlayer:GetAttributeChangedSignal("Logs"):Connect(updateLogs)

-- NOUVEAU: Écouter l'événement GrantIncome pour afficher feedback visuel
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local grantIncomeEvent = remotesFolder:WaitForChild("GrantIncome")

grantIncomeEvent.OnClientEvent:Connect(function(amount)
    print("[EconomyClient] 💰 Revenu TIC reçu:", amount, "$")
    -- Afficher feedback visuel
    if amount > 0 then
        feedback:Show(amount, "Revenu camping", 1)
    end
end)

print("[EconomyClient] ✅ Client d'économie initialisé avec listener GrantIncome")
