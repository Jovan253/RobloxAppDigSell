-- Validates and applies pickaxe-tier and zone-unlock purchases requested by
-- the client. There is no shop UI yet (see StarterGui/MainUi) -- these
-- remotes can be exercised from the command bar for now:
--   game.ReplicatedStorage.Remotes.PurchaseUpgrade:FireServer(2)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)

local ShopService = {}

local function purchasePickaxe(player, tierIndex)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local tier = Config.PickaxeTiers[tierIndex]
	if not tier then
		return
	end

	-- Tiers must be bought in order so Cost/Multiplier stay meaningful.
	if tierIndex ~= profile.PickaxeTier + 1 then
		return
	end

	if profile.Cash < tier.Cost then
		return
	end

	DataService.SetCash(player, profile.Cash - tier.Cost)
	DataService.SetPickaxeTier(player, tierIndex)
end

local function purchaseZone(player, zoneName)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local zoneConfig
	for _, zone in Config.Zones do
		if zone.Name == zoneName then
			zoneConfig = zone
			break
		end
	end
	if not zoneConfig then
		return
	end

	for _, unlocked in profile.UnlockedZones do
		if unlocked == zoneName then
			return
		end
	end

	if profile.Cash < zoneConfig.UnlockCost then
		return
	end

	DataService.SetCash(player, profile.Cash - zoneConfig.UnlockCost)
	local zones = profile.UnlockedZones
	table.insert(zones, zoneName)
	DataService.SetUnlockedZones(player, zones)
end

function ShopService.Init()
	Remotes.PurchaseUpgrade.OnServerEvent:Connect(function(player, tierIndex)
		if typeof(tierIndex) ~= "number" then
			return
		end
		purchasePickaxe(player, tierIndex)
	end)

	Remotes.PurchaseZone.OnServerEvent:Connect(function(player, zoneName)
		if typeof(zoneName) ~= "string" then
			return
		end
		purchaseZone(player, zoneName)
	end)
end

return ShopService
