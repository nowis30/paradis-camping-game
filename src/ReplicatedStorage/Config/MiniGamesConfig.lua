local MiniGamesConfig = {}

MiniGamesConfig.SwingGame = {
    PivotPosition = Vector3.new(-120, 8, 60),
    SeatOffset = Vector3.new(0, -6, 0),
    RewardPerFullLoop = 5,
    MinRadius = 3,
    PushAngularImpulse = 4,
    ForwardKeys = { Enum.KeyCode.W, Enum.KeyCode.Up },
    BackwardKeys = { Enum.KeyCode.S, Enum.KeyCode.Down },
    ModelName = "Swing",
    PivotName = "SwingPivot",
    SeatName = "Seat",
    AutoCreateModel = false,
    Swings = {
        {
            ModelName = "Swing",
            PivotName = "SwingPivot",
            SeatName = "Seat",
        },
        {
            ModelName = "Swing2",
            PivotName = "SwingPivot",
            SeatName = "Seat",
        },
    },
    ComboWindowSeconds = 3,
    ComboBonusPerLoop = 2,
}

MiniGamesConfig.FishingGame = {
    Spots = {
        { Name = "FishingSpot1", Position = Vector3.new(-60, 1, -150) },
        { Name = "FishingSpot2", Position = Vector3.new(-20, 1, -170) },
        { Name = "FishingSpot3", Position = Vector3.new(20, 1, -180) },
        { Name = "FishingSpot4", Position = Vector3.new(60, 1, -170) },
        { Name = "FishingSpot5", Position = Vector3.new(100, 1, -160) },
    },

    FishRewards = {
        Small = { Label = "Petit poisson", MinReward = 3, MaxReward = 7 },
        Medium = { Label = "Poisson moyen", MinReward = 8, MaxReward = 15 },
        Large = { Label = "Gros poisson", MinReward = 16, MaxReward = 30 },
        Rare = { Label = "Poisson rare", MinReward = 31, MaxReward = 60 },
    },

    FishProbabilities = {
        Small = 0.45,
        Medium = 0.30,
        Large = 0.20,
        Rare = 0.05,
    },

    CooldownSeconds = 5,
}

return MiniGamesConfig
