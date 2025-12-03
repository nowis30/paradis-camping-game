--[[
    EconomyFeedback
    Affiche des popups et joue un son léger pour les gains/pertes passifs.
]]

local TweenService = game:GetService("TweenService")

local EconomyFeedback = {}
EconomyFeedback.__index = EconomyFeedback

function EconomyFeedback.new(parent)
    local self = setmetatable({}, EconomyFeedback)
    self.Parent = parent

    local container = Instance.new("Folder")
    container.Name = "EconomyFeedback"
    container.Parent = parent
    self.Container = container

    local sound = Instance.new("Sound")
    sound.Name = "PassiveGainSound"
    sound.SoundId = "rbxassetid://3398620867" -- Son de pièce valide
    sound.Volume = 0.4
    sound.PlayOnRemove = false
    sound.Parent = container
    self.Sound = sound

    return self
end

local function formatAmount(amount)
    local prefix = amount >= 0 and "+" or "-"
    return string.format("%s%.2f $", prefix, math.abs(amount))
end

function EconomyFeedback:Show(amount, reason, multiplier)
    amount = tonumber(amount) or 0
    reason = reason or (amount >= 0 and "Revenu passif" or "Taxe")

    local label = Instance.new("TextLabel")
    label.Name = "EconomyPopup"
    label.Size = UDim2.new(0, 200, 0, 40)
    label.Position = UDim2.new(0, 20, 0, 140)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.TextStrokeTransparency = 0.6
    label.Parent = self.Parent

    if amount == 0 then
        label.Text = reason
        label.TextColor3 = Color3.fromRGB(230, 230, 255)
    else
        local text = formatAmount(amount)
        if multiplier and multiplier > 1.01 then
            text = string.format("%s (x%.2f)", text, multiplier)
        end
        label.Text = string.format("%s\n%s", text, reason)
        if amount >= 0 then
            label.TextColor3 = Color3.fromRGB(150, 255, 170)
            self.Sound:Stop()
            self.Sound.TimePosition = 0
            self.Sound:Play()
        else
            label.TextColor3 = Color3.fromRGB(255, 130, 130)
        end
    end

    local goal = { Position = label.Position + UDim2.new(0, 0, 0, -40), TextTransparency = 1 }
    local tween = TweenService:Create(label, TweenInfo.new(1.2), goal)
    tween:Play()
    tween.Completed:Connect(function()
        label:Destroy()
    end)
end

return EconomyFeedback
