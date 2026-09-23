-- Handles case-opening: spend Gems, roll a weighted-random pickaxe skin,
-- grant it (or refund partial Gems if it's a duplicate), and let the player
-- equip any skin they own. The reveal spin animation is purely client-side
-- (CaseUi.client.luau) -- this just decides the outcome and tells the
-- client what it was; the client's spinning reel is decorative and always
-- lands on the server's actual result, so there's nothing to fake here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)

local CaseService = {}

-- Same cumulative-roll weighted pick as MiningService.pickOreType.
local function pickSkin()
	local totalWeight = 0
	for _, skin in Config.PickaxeSkins do
		totalWeight += skin.Weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, skin in Config.PickaxeSkins do
		cumulative += skin.Weight
		if roll <= cumulative then
			return skin
		end
	end
	return Config.PickaxeSkins[#Config.PickaxeSkins]
end

local function onOpenCase(player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	if profile.Gems < Config.CaseCost then
		return
	end

	DataService.SetGems(player, profile.Gems - Config.CaseCost)

	local skin = pickSkin()
	local isNew = DataService.AddOwnedSkin(player, skin.Name)

	if not isNew then
		DataService.AddGems(player, Config.CaseDuplicateRefund)
	end

	Remotes.CaseResult:FireClient(player, skin.Name, isNew, isNew and 0 or Config.CaseDuplicateRefund)
end

local function onEquipSkin(player, skinName)
	if typeof(skinName) ~= "string" then
		return
	end
	if not DataService.HasOwnedSkin(player, skinName) then
		return
	end
	DataService.SetEquippedSkin(player, skinName)
end

function CaseService.Init()
	Remotes.OpenCase.OnServerEvent:Connect(onOpenCase)
	Remotes.EquipSkin.OnServerEvent:Connect(onEquipSkin)
end

return CaseService
