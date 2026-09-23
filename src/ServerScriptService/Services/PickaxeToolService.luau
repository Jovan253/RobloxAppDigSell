-- Gives each player an equippable Tool matching their current pickaxe
-- tier, cloned from a free Toolbox asset (ServerStorage.PickaxeAsset)
-- rather than built procedurally -- one color for every tier for now, see
-- Config.PickaxeTiers for where a per-tier look could be added later.
-- Reacts to PlayerData.PickaxeTier's replicated value directly, so it
-- stays correct through shop purchases, rebirth resets, and the admin
-- override alike without needing to be called from each of those sites
-- individually. The swing itself is cosmetic (see PickaxeSwing.client.luau)
-- -- mining is proximity-based via Remotes.MineHit (see MiningService), not
-- tied to the tool's geometry at all -- but MiningService requires this
-- Tool to actually be equipped (in Character, not just Backpack) before a
-- swing counts as a hit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataService = require(script.Parent.DataService)

local PickaxeToolService = {}

local sourceAsset = ServerStorage:WaitForChild("PickaxeAsset")

local toolTemplates = {}

-- PickaxeAsset turned out to be a Model, not a ready-to-equip Tool (free
-- Toolbox "pickaxe" results aren't always packaged as actual Tools). Builds
-- a real Tool around it: picks a part to serve as the required "Handle"
-- (PrimaryPart if set, an existing part literally named Handle, or just the
-- first BasePart found) and welds every other part to it so the whole
-- model moves together.
local function buildToolTemplate(tierIndex)
	local tier = Config.PickaxeTiers[tierIndex]
	local sourceClone = sourceAsset:Clone()

	local tool = Instance.new("Tool")
	tool.Name = tier and tier.Name or "Pickaxe"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsPickaxe", true)

	if sourceClone:IsA("Tool") then
		-- Already a proper Tool (e.g. a different asset later) -- just move
		-- its contents into ours so the rest of this function (script
		-- stripping, CanQuery) still applies uniformly.
		for _, child in sourceClone:GetChildren() do
			child.Parent = tool
		end
		sourceClone:Destroy()
	else
		local handle = sourceClone.PrimaryPart or sourceClone:FindFirstChild("Handle", true)
		if not handle then
			for _, descendant in sourceClone:GetDescendants() do
				if descendant:IsA("BasePart") then
					handle = descendant
					break
				end
			end
		end

		if not handle then
			warn("PickaxeToolService: PickaxeAsset has no BasePart to use as a Handle")
			sourceClone:Destroy()
			return tool
		end

		handle.Name = "Handle"

		local parts = {}
		for _, descendant in sourceClone:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end

		for _, child in sourceClone:GetChildren() do
			child.Parent = tool
		end
		sourceClone:Destroy()

		for _, part in parts do
			if part ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = part
				weld.Parent = handle
			end
		end
	end

	-- Roll 90 degrees around the axis pointing away from the hand, so the
	-- head's sharp edge leads instead of its flat side -- a guess at which
	-- axis/direction is right since this can't be previewed; say the word
	-- if it needs to go the other way or around a different axis.
	tool.Grip = CFrame.Angles(0, 0, math.rad(90))

	-- Strip any scripts the asset came with -- a Toolbox "pickaxe" could be
	-- a full scripted kit assuming its own hit-detection, which we don't
	-- want fighting with MiningService. CanQuery off so the held tool can't
	-- block the player's own click-targeting for anything else either.
	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.CanQuery = false
		end
	end

	return tool
end

local function getToolTemplate(tierIndex)
	if not toolTemplates[tierIndex] then
		toolTemplates[tierIndex] = buildToolTemplate(tierIndex)
	end
	return toolTemplates[tierIndex]
end

local function equipCurrentTier(player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	for _, container in { backpack, player.Character } do
		if container then
			for _, item in container:GetChildren() do
				if item:IsA("Tool") and item:GetAttribute("IsPickaxe") then
					item:Destroy()
				end
			end
		end
	end

	local tool = getToolTemplate(profile.PickaxeTier):Clone()
	tool.Parent = backpack
end

local function hookPlayer(player)
	local playerData = player:WaitForChild("PlayerData")
	local pickaxeTierValue = playerData:WaitForChild("PickaxeTier")

	pickaxeTierValue:GetPropertyChangedSignal("Value"):Connect(function()
		equipCurrentTier(player)
	end)

	player.CharacterAdded:Connect(function()
		equipCurrentTier(player)
	end)

	equipCurrentTier(player)
end

function PickaxeToolService.Init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(hookPlayer, player)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(hookPlayer, player)
	end
end

return PickaxeToolService
