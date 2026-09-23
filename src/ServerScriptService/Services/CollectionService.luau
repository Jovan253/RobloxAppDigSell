-- Handles Collection Journal reward claims. Mining an ore type for the
-- first time marks it "discovered" (MiningService calls
-- DataService.MarkOreTypeCollected), which reveals it in the Journal -- but
-- the Gems for that discovery aren't granted automatically. The player has
-- to open the Journal and click Claim, which fires Remotes.ClaimOreReward
-- here. Kept as its own service rather than folded into MiningService
-- (already the largest file) since this is a Journal/UI-driven concern, not
-- a mining-interaction one.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)

local CollectionService = {}

-- Built once from Config.Zones, same pattern as MiningService's
-- GEMS_BY_ORE_TYPE_NAME but for the one-time claim reward.
local CLAIM_GEMS_BY_ORE_TYPE_NAME = {}
for _, zoneConfig in Config.Zones do
	for _, oreType in zoneConfig.OreTypes do
		CLAIM_GEMS_BY_ORE_TYPE_NAME[oreType.Name] = oreType.ClaimGems or 0
	end
	if zoneConfig.RareOreType then
		CLAIM_GEMS_BY_ORE_TYPE_NAME[zoneConfig.RareOreType.Name] = zoneConfig.RareOreType.ClaimGems or 0
	end
end

local function onClaimOreReward(player, oreTypeName)
	if typeof(oreTypeName) ~= "string" then
		return
	end

	-- MarkOreTypeClaimed itself already checks "discovered and not yet
	-- claimed" and returns false otherwise -- this is the real
	-- server-side guard against double-claiming or claiming something
	-- never mined, regardless of what the client thinks its state is.
	if not DataService.MarkOreTypeClaimed(player, oreTypeName) then
		return
	end

	local reward = CLAIM_GEMS_BY_ORE_TYPE_NAME[oreTypeName] or 0
	if reward > 0 then
		DataService.AddGems(player, reward)
	end
end

function CollectionService.Init()
	Remotes.ClaimOreReward.OnServerEvent:Connect(onClaimOreReward)
end

return CollectionService
