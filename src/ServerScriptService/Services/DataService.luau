-- Owns per-player progress: load on join, save on leave/autosave/shutdown,
-- and exposes the mutation API other services use (AddCash, SetCash, ...).
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

function DataService.Save(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local ok, err = pcall(function()
		playerStore:SetAsync(storeKey(player), profile)
	end)
	if not ok then
		warn(("DataService: failed to save data for %s: %s"):format(player.Name, tostring(err)))
	end
end

local function loadProfile(player)
	local ok, result = pcall(function()
		return playerStore:GetAsync(storeKey(player))
	end)

	local profile
	if ok and result then
		profile = result
	else
		if not ok then
			warn(("DataService: failed to load data for %s: %s"):format(player.Name, tostring(result)))
		end
		profile = defaultProfile()
	end

	profiles[player] = profile
	setupLeaderstats(player, profile)
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
