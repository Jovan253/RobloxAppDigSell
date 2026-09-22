local Config = {}

Config.Zones = {
	{
		Name = "Zone1",
		DisplayName = "Sunny Quarry",
		UnlockCost = 0, -- starter zone, free
		OreValue = 1,
		RespawnTime = 3,
		GridSize = Vector2.new(6, 6),
		CellSize = 6,
		Origin = Vector3.new(0, 1, 0),
	},
	{
		Name = "Zone2",
		DisplayName = "Deep Caverns",
		UnlockCost = 500,
		OreValue = 5,
		RespawnTime = 4,
		GridSize = Vector2.new(6, 6),
		CellSize = 6,
		Origin = Vector3.new(0, 1, 60),
	},
	{
		Name = "Zone3",
		DisplayName = "Crystal Depths",
		UnlockCost = 5000,
		OreValue = 25,
		RespawnTime = 5,
		GridSize = Vector2.new(6, 6),
		CellSize = 6,
		Origin = Vector3.new(0, 1, 120),
	},
}

Config.PickaxeTiers = {
	{ Name = "Wooden Pickaxe", Cost = 0, Multiplier = 1 },
	{ Name = "Stone Pickaxe", Cost = 100, Multiplier = 2 },
	{ Name = "Iron Pickaxe", Cost = 750, Multiplier = 4 },
	{ Name = "Gold Pickaxe", Cost = 4000, Multiplier = 8 },
	{ Name = "Diamond Pickaxe", Cost = 20000, Multiplier = 16 },
}

Config.Rebirth = {
	CashRequired = 50000,
	MultiplierPerRebirth = 0.5, -- +50% cash per rebirth, stacking
}

Config.DataStoreName = "DigAndSellPlayerData_v1"
Config.AutosaveInterval = 120 -- seconds

Config.LeaderboardStoreName = "DigAndSellLeaderboard_v1"
Config.LeaderboardUpdateInterval = 30 -- seconds
Config.LeaderboardDisplayCount = 10

-- Real IDs from the Creator Dashboard (Monetization > Passes / Developer
-- Products). Shared here so server (ownership checks / ProcessReceipt) and
-- client (purchase-prompt buttons) can't drift out of sync on IDs.
Config.GamePasses = {
	DoubleCash = 1988462502,
}

Config.CashProducts = {
	{ ProductId = 3714204369, Name = "Small Pack", Cash = 5000 },
	{ ProductId = 3714204408, Name = "Huge Pack", Cash = 50000 },
}

return Config
