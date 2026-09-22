-- Creates (server) or looks up (client) the StringValue LeaderboardService
-- publishes the current top-N leaderboard into (JSON-encoded array of
-- {Name, Cash}). Parented under this ModuleScript itself, not
-- ReplicatedStorage directly, so its name can't collide with the
-- "LeaderboardData" ModuleScript instance (see Remotes.luau for the same
-- issue this avoids).
local RunService = game:GetService("RunService")

local entriesValue

if RunService:IsServer() then
	entriesValue = Instance.new("StringValue")
	entriesValue.Name = "Entries"
	entriesValue.Value = "[]"
	entriesValue.Parent = script
else
	entriesValue = script:WaitForChild("Entries")
end

return entriesValue
