-- Resets Cash/pickaxe/zones in exchange for a permanent, stacking cash
-- multiplier once the player crosses Config.Rebirth.CashRequired.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)

local RebirthService = {}

local function tryRebirth(player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	if profile.Cash < Config.Rebirth.CashRequired then
		return
	end

	profile.Rebirths += 1
	profile.RebirthMultiplier = 1 + (profile.Rebirths * Config.Rebirth.MultiplierPerRebirth)
	profile.PickaxeTier = 1
	profile.UnlockedZones = { "Zone1" }
	DataService.SetCash(player, 0)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Rebirths.Value = profile.Rebirths
	end
end

function RebirthService.Init()
	Remotes.Rebirth.OnServerEvent:Connect(function(player)
		tryRebirth(player)
	end)
end

return RebirthService
