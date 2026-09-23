local Config = {}

-- Each zone is a room MiningService builds procedurally (see its comments
-- for the room-shell/scatter algorithm). `Origin` is the point on the
-- zone's edge closest to the hub (its "door"); the room extends away from
-- the hub by RoomSize.Z ("depth") and is RoomSize.X wide ("width"),
-- centered on Origin. `Orientation` ("North"/"South"/"East"/"West", see
-- ZoneGeometry) says which compass side of the hub the zone is on and thus
-- which world axis is actually "depth" -- e.g. an East zone's RoomSize.Z
-- extends along world +X, not +Z. Parts stay world-axis-aligned regardless
-- (ZoneGeometry swaps X/Z rather than rotating anything).
--
-- Layout is hub-and-spoke: Zone1 is a wide-open square central hub (no
-- walls). Zone2/3/4 are one per side (West/East/North) so each is a
-- separate direction from the hub rather than lined up next to each other;
-- South is left open as the entrance/spawn side.
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
		RoomSize = Vector3.new(120, 1, 120),
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
		Origin = Vector3.new(-60, 1, 60), -- hub's west edge, vertically centered
		Orientation = "West",
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
		Origin = Vector3.new(60, 1, 60), -- hub's east edge, vertically centered
		Orientation = "East",
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
		Origin = Vector3.new(0, 1, 120), -- hub's north edge
		Orientation = "North",
		-- Z = ENTRANCE_DEPTH + LAVA_DEPTH + TREASURE_DEPTH from
		-- MiningService's Dark Mines layout constants (40 + 70 + 50 = 160).
		-- Keep these in sync if either changes. Dark Mines' internal lava/
		-- platform/treasure geometry is hardcoded North-only (unlike the
		-- generic room shell/ore scatter, which is orientation-aware via
		-- ZoneGeometry) -- don't change this zone's Orientation without
		-- also reworking that geometry.
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

-- Dark Mines "Jumpscare Prank" developer product.
Config.JumpscareProductId = 3714340075
Config.JumpscarePrankRadius = 60 -- studs; players within this range of the buyer get jumpscared

-- Roblox UserIds that get everything unlocked/maxed for free: all zones,
-- max pickaxe tier, and the 2x Cash multiplier -- applied on join by
-- DataService/MarketplaceService (see Config.IsAdmin). Doesn't cover
-- Robux-based purchases (Cash Packs, Jumpscare Prank) -- those are real
-- transactions Roblox itself gates, not something to fake server-side.
Config.AdminUserIds = {
	-- TODO: add your Roblox numeric UserId here, e.g. 123456789
}

function Config.IsAdmin(userId)
	for _, id in Config.AdminUserIds do
		if id == userId then
			return true
		end
	end
	return false
end

return Config
