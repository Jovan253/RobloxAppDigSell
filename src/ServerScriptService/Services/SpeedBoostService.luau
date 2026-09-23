-- Applies the player's current Speed tier to Humanoid.WalkSpeed. Reacts to
-- PlayerData.SpeedTier's replicated value directly (same pattern as
-- PickaxeToolService reacting to PickaxeTier), so it stays correct through
-- shop purchases, character respawns, and the admin override alike without
-- needing to be called from each of those sites individually.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataService = require(script.Parent.DataService)

local SpeedBoostService = {}

local function applyCurrentTier(player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local tier = Config.SpeedTiers[profile.SpeedTier] or Config.SpeedTiers[1]
	humanoid.WalkSpeed = tier.WalkSpeed
end

local function hookPlayer(player)
	local playerData = player:WaitForChild("PlayerData")
	local speedTierValue = playerData:WaitForChild("SpeedTier")

	speedTierValue:GetPropertyChangedSignal("Value"):Connect(function()
		applyCurrentTier(player)
	end)

	player.CharacterAdded:Connect(function()
		applyCurrentTier(player)
	end)

	applyCurrentTier(player)
end

function SpeedBoostService.Init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(hookPlayer, player)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(hookPlayer, player)
	end
end

return SpeedBoostService
