-- Periodically pushes each online player's Cash into an OrderedDataStore
-- (an all-time high-score board across sessions/servers) and publishes the
-- current top N into ReplicatedStorage.LeaderboardData for the client UI to
-- read -- no RemoteFunction round-trip needed.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local entriesValue = require(ReplicatedStorage:WaitForChild("LeaderboardData"))
local DataService = require(script.Parent.DataService)

local orderedStore = DataStoreService:GetOrderedDataStore(Config.LeaderboardStoreName)

local LeaderboardService = {}

local function pushScore(player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	local ok, err = pcall(function()
		orderedStore:SetAsync(tostring(player.UserId), math.floor(profile.Cash))
	end)
	if not ok then
		warn(("LeaderboardService: failed to update score for %s: %s"):format(player.Name, tostring(err)))
	end
end

local function resolveName(userId)
	local onlinePlayer = Players:GetPlayerByUserId(userId)
	if onlinePlayer then
		return onlinePlayer.Name
	end

	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok then
		return name
	end

	return "Player " .. userId
end

local function refreshDisplay()
	local ok, pages = pcall(function()
		return orderedStore:GetSortedAsync(false, Config.LeaderboardDisplayCount)
	end)
	if not ok then
		warn("LeaderboardService: failed to fetch leaderboard: " .. tostring(pages))
		return
	end

	local entries = {}
	for _, entry in pages:GetCurrentPage() do
		local userId = tonumber(entry.key)
		table.insert(entries, { Name = userId and resolveName(userId) or entry.key, Cash = entry.value })
	end

	entriesValue.Value = HttpService:JSONEncode(entries)
end

function LeaderboardService.Init()
	Players.PlayerRemoving:Connect(pushScore)

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				pushScore(player)
			end
			refreshDisplay()
			task.wait(Config.LeaderboardUpdateInterval)
		end
	end)
end

return LeaderboardService
