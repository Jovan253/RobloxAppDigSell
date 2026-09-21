-- Builds the demo ore grids (so the game is playable the moment you hit Play,
-- before any hand-built map exists) and handles click-to-mine on ore nodes.
-- Replace ensureZonesExist's procedural grid with hand-built Studio geometry
-- whenever you want real art -- just keep the OreNode name/attributes/tag
-- and ClickDetector on each rock so this service still recognizes them.
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataService = require(script.Parent.DataService)

local ORE_TAG = "OreNode"

local MiningService = {}

local function buildZone(zoneConfig, zonesFolder)
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = zoneConfig.Name
	zoneFolder.Parent = zonesFolder

	local grid = zoneConfig.GridSize
	local cell = zoneConfig.CellSize
	local origin = zoneConfig.Origin

	for x = 1, grid.X do
		for z = 1, grid.Y do
			local node = Instance.new("Part")
			node.Name = "OreNode"
			node.Shape = Enum.PartType.Block
			node.Size = Vector3.new(cell * 0.8, 4, cell * 0.8)
			node.Anchored = true
			node.Material = Enum.Material.Rock
			node.BrickColor = BrickColor.new("Dark stone grey")
			node.Position = origin + Vector3.new((x - 1) * cell, 0, (z - 1) * cell)
			node:SetAttribute("CashValue", zoneConfig.OreValue)
			node:SetAttribute("RespawnTime", zoneConfig.RespawnTime)
			node:SetAttribute("ZoneName", zoneConfig.Name)
			node.Parent = zoneFolder

			local click = Instance.new("ClickDetector")
			click.MaxActivationDistance = 15
			click.Parent = node

			CollectionService:AddTag(node, ORE_TAG)
		end
	end
end

local function ensureZonesExist()
	if Workspace:FindFirstChild("MiningZones") then
		return
	end

	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "MiningZones"
	zonesFolder.Parent = Workspace

	for _, zoneConfig in Config.Zones do
		buildZone(zoneConfig, zonesFolder)
	end
end

local function isZoneUnlocked(player, zoneName)
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	for _, unlocked in profile.UnlockedZones do
		if unlocked == zoneName then
			return true
		end
	end
	return false
end

local function pickaxeMultiplier(player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return 1
	end
	local tier = Config.PickaxeTiers[profile.PickaxeTier]
	return tier and tier.Multiplier or 1
end

local function rebirthMultiplier(player)
	local profile = DataService.GetProfile(player)
	return profile and profile.RebirthMultiplier or 1
end

local function onNodeClicked(node, player)
	if node:GetAttribute("Mining") then
		return
	end

	local zoneName = node:GetAttribute("ZoneName")
	if not isZoneUnlocked(player, zoneName) then
		return
	end

	node:SetAttribute("Mining", true)

	local baseValue = node:GetAttribute("CashValue") or 1
	local reward = baseValue * pickaxeMultiplier(player) * rebirthMultiplier(player)
	DataService.AddCash(player, reward)

	local click = node:FindFirstChildOfClass("ClickDetector")
	node.Transparency = 0.85
	node.CanCollide = false
	if click then
		click.MaxActivationDistance = 0
	end

	task.delay(node:GetAttribute("RespawnTime") or 3, function()
		if not node.Parent then
			return
		end
		node.Transparency = 0
		node.CanCollide = true
		if click then
			click.MaxActivationDistance = 15
		end
		node:SetAttribute("Mining", false)
	end)
end

local function hookNode(node)
	local click = node:FindFirstChildOfClass("ClickDetector")
	if not click then
		return
	end
	click.MouseClick:Connect(function(player)
		onNodeClicked(node, player)
	end)
end

function MiningService.Init()
	ensureZonesExist()

	for _, node in CollectionService:GetTagged(ORE_TAG) do
		hookNode(node)
	end

	CollectionService:GetInstanceAddedSignal(ORE_TAG):Connect(hookNode)
end

return MiningService
