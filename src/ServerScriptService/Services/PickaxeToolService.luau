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

local function buildToolTemplate(tierIndex)
	local tier = Config.PickaxeTiers[tierIndex]

	local tool = sourceAsset:Clone()
	tool.Name = tier and tier.Name or "Pickaxe"
	tool.CanBeDropped = false
	tool:SetAttribute("IsPickaxe", true)

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
