local Config = {}

-- Each zone is a room MiningService builds procedurally (see its comments
-- for the room-shell/scatter algorithm). `Origin` is (center X, floor Y,
-- near-Z edge) -- the room extends from Origin.Z to Origin.Z + RoomSize.Z,
-- and from Origin.X - RoomSize.X/2 to Origin.X + RoomSize.X/2.
--
-- Layout is hub-and-spoke: Zone1 is a wide-open central hub (no walls), and
-- Zone2/3/4 sit side by side along its north edge (Origin.Z = 80 for all
-- three), each its own lane on the X axis with gaps so their walls don't
-- intersect. All three are reachable directly from the hub -- you don't
-- walk through one zone to reach another.
--
-- `OreTypes` entries are picked per ore node by weighted random (Weight is
-- relative, doesn't need to sum to 100). `Multiplier` scales the zone's base
-- `OreValue`. `Glow` gives the ore a small glowing accent + light -- use it
-- to make rare ore types visually pop.
Config.Zones = {
	{
		Name = "Zone1",
		DisplayName = "Sunny Quarry",
		UnlockCost = 0, -- starter zone / hub, free and always open
		OreValue = 1,
		RespawnTime = 3,
		Origin = Vector3.new(0, 1, 0),
		RoomSize = Vector3.new(160, 1, 80),
		Enclosed = false, -- open-air hub, no walls/ceiling
		GroundMaterial = Enum.Material.Grass,
		GroundColor = Color3.fromRGB(94, 155, 76),
		WallMaterial = Enum.Material.Rock,
		WallColor = Color3.fromRGB(150, 140, 120),
		OreCount = 30,
		OreTypes = {
			{ Name = "Sandstone", Material = Enum.Material.Sandstone, Color = Color3.fromRGB(214, 187, 129), Multiplier = 1, Weight = 85, Glow = false },
			{ Name = "Quartz", Material = Enum.Material.Glass, Color = Color3.fromRGB(240, 240, 250), Multiplier = 5, Weight = 15, Glow = true },
		},
	},
	{
		Name = "Zone2",
		DisplayName = "Deep Caverns",
		UnlockCost = 500,
		OreValue = 5,
		RespawnTime = 4,
		Origin = Vector3.new(-130, 1, 80),
		RoomSize = Vector3.new(100, 36, 100),
		Enclosed = true,
		GroundMaterial = Enum.Material.Slate,
		GroundColor = Color3.fromRGB(70, 70, 78),
		WallMaterial = Enum.Material.Basalt,
		WallColor = Color3.fromRGB(45, 45, 52),
		OreCount = 28,
		OreTypes = {
			{ Name = "Iron Ore", Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 150, 155), Multiplier = 1, Weight = 80, Glow = false },
			{ Name = "Emerald", Material = Enum.Material.Glass, Color = Color3.fromRGB(60, 220, 120), Multiplier = 6, Weight = 20, Glow = true },
		},
	},
	{
		Name = "Zone3",
		DisplayName = "Crystal Depths",
		UnlockCost = 5000,
		OreValue = 25,
		RespawnTime = 5,
		Origin = Vector3.new(0, 1, 80),
		RoomSize = Vector3.new(110, 40, 110),
		Enclosed = true,
		GroundMaterial = Enum.Material.Basalt,
		GroundColor = Color3.fromRGB(45, 35, 60),
		WallMaterial = Enum.Material.Slate,
		WallColor = Color3.fromRGB(60, 45, 80),
		OreCount = 30,
		OreTypes = {
			{ Name = "Amethyst", Material = Enum.Material.Glass, Color = Color3.fromRGB(150, 90, 220), Multiplier = 1, Weight = 80, Glow = true },
			{ Name = "Diamond", Material = Enum.Material.Ice, Color = Color3.fromRGB(190, 240, 250), Multiplier = 6, Weight = 20, Glow = true },
		},
	},
	{
		Name = "Zone4",
		DisplayName = "Dark Mines",
		UnlockCost = 25000,
		OreValue = 80,
		RespawnTime = 6,
		Origin = Vector3.new(140, 1, 80),
		-- Z = ENTRANCE_DEPTH + LAVA_DEPTH + TREASURE_DEPTH from
		-- MiningService's Dark Mines layout constants (40 + 70 + 50 = 160).
		-- Keep these in sync if either changes.
		RoomSize = Vector3.new(90, 40, 160),
		Enclosed = true,
		IsDarkMines = true,
		GroundMaterial = Enum.Material.Basalt,
		GroundColor = Color3.fromRGB(20, 18, 20),
		WallMaterial = Enum.Material.Basalt,
		WallColor = Color3.fromRGB(15, 13, 15),
		OreCount = 10, -- safe ore in the entrance area only
		OreTypes = {
			{ Name = "Obsidian Shard", Material = Enum.Material.Basalt, Color = Color3.fromRGB(40, 35, 45), Multiplier = 1, Weight = 100, Glow = false },
		},
		-- Rare ore is hand-placed on the treasure platform past the lava,
		-- not part of the weighted OreTypes scatter.
		RareOreType = { Name = "Cursed Ruby", Material = Enum.Material.Neon, Color = Color3.fromRGB(200, 20, 20), Multiplier = 8, Glow = true },
		RareOreCount = 6,
		LavaColor = Color3.fromRGB(230, 90, 20),
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

-- Dark Mines "Jumpscare Prank" developer product: create it in the Creator
-- Dashboard (Monetization > Developer Products) and paste its ID here.
-- Left nil until then -- MarketplaceService/ShopUi both skip it while nil,
-- so nothing breaks in the meantime.
Config.JumpscareProductId = nil
Config.JumpscarePrankRadius = 60 -- studs; players within this range of the buyer get jumpscared

return Config
