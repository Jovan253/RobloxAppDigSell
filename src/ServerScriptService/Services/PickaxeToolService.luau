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

local SKIN_BY_NAME = {}
for _, skin in Config.PickaxeSkins do
	SKIN_BY_NAME[skin.Name] = skin
end

-- Recolors every part of an equipped tool to the given skin (won from a
-- case -- see CaseService) and, for the rarer tiers, adds a Sparkles
-- instance to the Handle. Sparkles needs no Texture asset to render (unlike
-- ParticleEmitter, which bit us earlier with an invisible mining-hit
-- effect), so it's the simplest reliable way to give a skin a "not just a
-- recolor" particle effect.
local function applySkin(tool, skinName)
	local skin = SKIN_BY_NAME[skinName]
	if not skin then
		return
	end

	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = skin.Color
		end
	end

	if skin.Sparkle then
		local handle = tool:FindFirstChild("Handle")
		if handle then
			local sparkles = Instance.new("Sparkles")
			sparkles.SparkleColor = skin.Color
			sparkles.Parent = handle
		end
	end
end

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

	-- Live-tuned by the user via the Command Bar (Y-axis rotation was the
	-- one that mattered -- the earlier Z/X guesses were both the wrong axis).
	tool.Grip = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))

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
	if profile.EquippedSkin ~= "" then
		applySkin(tool, profile.EquippedSkin)
	end
	tool.Parent = backpack
end

local function hookPlayer(player)
	local playerData = player:WaitForChild("PlayerData")
	local pickaxeTierValue = playerData:WaitForChild("PickaxeTier")
	local equippedSkinValue = playerData:WaitForChild("EquippedSkin")

	pickaxeTierValue:GetPropertyChangedSignal("Value"):Connect(function()
		equipCurrentTier(player)
	end)

	equippedSkinValue:GetPropertyChangedSignal("Value"):Connect(function()
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
