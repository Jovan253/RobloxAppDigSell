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

	local isAdmin = Config.IsAdmin(player.UserId)
	if not isAdmin and profile.Cash < Config.Rebirth.CashRequired then
		return
	end

	profile.Rebirths += 1
	profile.RebirthMultiplier = 1 + (profile.Rebirths * Config.Rebirth.MultiplierPerRebirth)
	DataService.SetCash(player, 0)

	if isAdmin then
		-- Admins keep everything unlocked/maxed even through rebirth,
		-- rather than actually resetting like a normal player would.
		local allZoneNames = {}
		for _, zoneConfig in Config.Zones do
			table.insert(allZoneNames, zoneConfig.Name)
		end
		DataService.SetPickaxeTier(player, #Config.PickaxeTiers)
		DataService.SetUnlockedZones(player, allZoneNames)
	else
		DataService.SetPickaxeTier(player, 1)
		DataService.SetUnlockedZones(player, { "Zone1" })
	end

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
