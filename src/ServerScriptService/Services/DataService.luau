-- Owns per-player progress: load on join, save on leave/autosave/shutdown,
-- and exposes the mutation API other services use (AddCash, SetCash, ...).
-- Cash/Rebirths mirror into `leaderstats` (shows in Roblox's player list);
-- PickaxeTier/UnlockedZones mirror into a `PlayerData` folder instead, so
-- client UI (the shop) can read current progress via plain replication
-- instead of a RemoteFunction round-trip.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local playerStore = DataStoreService:GetDataStore(Config.DataStoreName)

local DataService = {}

local profiles = {} -- [player] = { Cash, PickaxeTier, UnlockedZones, Rebirths, RebirthMultiplier }

local function defaultProfile()
	return {
		Cash = 0,
		PickaxeTier = 1,
		UnlockedZones = { "Zone1" },
		Rebirths = 0,
		RebirthMultiplier = 1,
	}
end

local function storeKey(player)
	return "Player_" .. player.UserId
end

-- Retries a DataStore call a few times with backoff before giving up.
-- Roblox DataStore calls can fail transiently (throttling, brief outages);
-- without this, a single hiccup on load would look identical to "no saved
-- data" and silently hand the player a fresh profile, which then gets
-- saved over their real progress.
local function retryAsync(fn, attempts)
	local lastError
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < attempts then
			task.wait(attempt) -- 1s, 2s, ...
		end
	end
	return false, lastError
end

local function setupLeaderstats(player, profile)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Value = profile.Cash
	cash.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = profile.Rebirths
	rebirths.Parent = leaderstats
end

local function setupPlayerData(player, profile)
	local playerData = Instance.new("Folder")
	playerData.Name = "PlayerData"
	playerData.Parent = player

	local pickaxeTier = Instance.new("IntValue")
	pickaxeTier.Name = "PickaxeTier"
	pickaxeTier.Value = profile.PickaxeTier
	pickaxeTier.Parent = playerData

	local unlockedZones = Instance.new("StringValue")
	unlockedZones.Name = "UnlockedZones"
	unlockedZones.Value = table.concat(profile.UnlockedZones, ",")
	unlockedZones.Parent = playerData

	-- Not part of `profile`/DataStore -- gamepass ownership is authoritative
	-- on Roblox's side and re-checked by MarketplaceService each session.
	-- This just mirrors that check for the client's shop UI to read.
	local ownsDoubleCash = Instance.new("BoolValue")
	ownsDoubleCash.Name = "OwnsDoubleCash"
	ownsDoubleCash.Value = false
	ownsDoubleCash.Parent = playerData
end

function DataService.GetProfile(player)
	return profiles[player]
end

function DataService.SetCash(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Cash = amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Cash.Value = profile.Cash
	end
end

function DataService.AddCash(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	DataService.SetCash(player, profile.Cash + amount)
end

function DataService.SetPickaxeTier(player, tier)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.PickaxeTier = tier
	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		playerData.PickaxeTier.Value = tier
	end
end

function DataService.SetUnlockedZones(player, zones)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.UnlockedZones = zones
	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		playerData.UnlockedZones.Value = table.concat(zones, ",")
	end
end

function DataService.SetOwnsDoubleCash(player, owns)
	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		playerData.OwnsDoubleCash.Value = owns
	end
end

function DataService.Save(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local ok, err = retryAsync(function()
		playerStore:SetAsync(storeKey(player), profile)
	end, 3)
	if not ok then
		warn(("DataService: failed to save data for %s after retries: %s"):format(player.Name, tostring(err)))
	end
end

local function loadProfile(player)
	local ok, result = retryAsync(function()
		return playerStore:GetAsync(storeKey(player))
	end, 3)

	if not ok then
		-- Don't hand out a fresh profile on a load failure -- that would
		-- get saved over the player's real progress. Kick instead so they
		-- can rejoin and try again rather than silently losing progress.
		warn(("DataService: failed to load data for %s after retries: %s"):format(player.Name, tostring(result)))
		player:Kick("Couldn't load your save data. Please rejoin in a moment -- sorry about that!")
		return
	end

	local profile = result or defaultProfile()

	if Config.IsAdmin(player.UserId) then
		profile.PickaxeTier = #Config.PickaxeTiers
		profile.UnlockedZones = {}
		for _, zoneConfig in Config.Zones do
			table.insert(profile.UnlockedZones, zoneConfig.Name)
		end
	end

	profiles[player] = profile
	setupLeaderstats(player, profile)
	setupPlayerData(player, profile)
end

function DataService.Init()
	Players.PlayerAdded:Connect(loadProfile)

	Players.PlayerRemoving:Connect(function(player)
		DataService.Save(player)
		profiles[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end

	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for _, player in Players:GetPlayers() do
				DataService.Save(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			DataService.Save(player)
		end
	end)
end

return DataService
