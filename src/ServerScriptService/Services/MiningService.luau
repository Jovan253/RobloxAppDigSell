-- Builds all zones procedurally (so the game is playable the moment you hit
-- Play, before any hand-built map exists) and handles click-to-mine on ore
-- nodes. Standard zones (Zone1-3) are an enclosed room shell with ore
-- scattered across the floor by weighted rarity; Dark Mines (Zone4) gets a
-- hand-laid-out entrance/lava/parkour/treasure sequence instead. Swap any of
-- this for hand-built Studio geometry later -- just keep OreNode's Model
-- shape (a "Rock" BasePart child with the ClickDetector, optional "Vein"
-- accent) and attributes (CashValue/RespawnTime/ZoneName) so this service
-- still recognizes it.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)
local MarketplaceService = require(script.Parent.MarketplaceService)

local ORE_TAG = "OreNode"

-- Dark Mines layout, in studs along Z from the room's entrance edge. Keep
-- these in sync with Zone4's RoomSize.Z in Config.luau (40 + 70 + 50 = 160).
local DARK_MINES_ENTRANCE_DEPTH = 40
local DARK_MINES_LAVA_DEPTH = 70
local DARK_MINES_TREASURE_DEPTH = 50
local DARK_MINES_PLATFORM_COUNT = 7
local DARK_MINES_PLATFORM_X_OFFSET = 4 -- studs, left/right zigzag
local DARK_MINES_PLATFORM_SIZE = Vector3.new(6, 1, 5)

local MiningService = {}

local lastCheckpoint = {} -- [player] = { CFrame, Order }
local teleportCooldown = {} -- [player] = true while cooling down after a lava hit

-- Each "pool" is a fixed set of possible ore spawn slots within a zone (or
-- part of one, e.g. Dark Mines' entrance vs its treasure platform). Mining a
-- node destroys it outright and, after RespawnTime, a new one spawns at a
-- random slot from its pool -- not necessarily the same spot -- so ore
-- positions drift around instead of the same rock just reappearing in place.
local orePools = {} -- [poolId] = { folder, zoneName, respawnTime, positions, spawnPick }

-- === Ore node creation (shared by standard-zone scatter and Dark Mines) ===

local function pickOreType(oreTypes)
	local totalWeight = 0
	for _, oreType in oreTypes do
		totalWeight += oreType.Weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, oreType in oreTypes do
		cumulative += oreType.Weight
		if roll <= cumulative then
			return oreType
		end
	end
	return oreTypes[#oreTypes]
end

local function createOreNode(oreType, cashValue, zoneName, respawnTime, position, poolId)
	local model = Instance.new("Model")
	model.Name = "OreNode"

	local rockSize = 2.6 + math.random() * 1.4 -- 2.6 - 4.0 studs
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Shape = Enum.PartType.Block
	rock.Size = Vector3.new(rockSize, rockSize * 0.85, rockSize)
	rock.Anchored = true
	rock.Material = oreType.Material
	rock.Color = oreType.Color
	rock.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
	rock.Parent = model

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 15
	click.Parent = rock

	if oreType.Glow then
		local vein = Instance.new("Part")
		vein.Name = "Vein"
		vein.Shape = Enum.PartType.Ball
		vein.Size = Vector3.new(rockSize * 0.4, rockSize * 0.4, rockSize * 0.4)
		vein.Anchored = true
		vein.CanCollide = false
		vein.Material = Enum.Material.Neon
		vein.Color = oreType.Color
		vein.CFrame = rock.CFrame * CFrame.new(0, rockSize * 0.35, 0)
		vein.Parent = model

		local light = Instance.new("PointLight")
		light.Color = oreType.Color
		light.Range = 10
		light.Brightness = 2
		light.Parent = vein
	end

	model:SetAttribute("CashValue", cashValue)
	model:SetAttribute("RespawnTime", respawnTime)
	model:SetAttribute("ZoneName", zoneName)
	model:SetAttribute("OreTypeName", oreType.Name)
	model:SetAttribute("PoolId", poolId)

	CollectionService:AddTag(model, ORE_TAG)

	return model
end

local function spawnOreAt(poolId, position)
	local pool = orePools[poolId]
	if not pool then
		return
	end

	local oreType, cashValue = pool.spawnPick()
	local node = createOreNode(oreType, cashValue, pool.zoneName, pool.respawnTime, position, poolId)
	node.Parent = pool.folder
end

local function registerOrePool(zoneFolder, zoneName, respawnTime, positions, poolId, spawnPick)
	orePools[poolId] = {
		folder = zoneFolder,
		zoneName = zoneName,
		respawnTime = respawnTime,
		positions = positions,
		spawnPick = spawnPick,
	}

	for _, position in positions do
		spawnOreAt(poolId, position)
	end
end

-- Jittered-grid slots: divides the usable floor area into a roughly
-- OreCount-sized grid and returns one slot position per cell with random
-- jitter, so coverage is even without needing true collision-based
-- placement.
local function computeGridSlots(zoneConfig, areaOrigin, areaDepth)
	local size = zoneConfig.RoomSize
	local margin = 8
	local usableX = size.X - margin * 2
	local usableZ = areaDepth - margin * 2
	local positions = {}
	if usableX <= 0 or usableZ <= 0 then
		return positions
	end

	local cols = math.max(1, math.floor(math.sqrt(zoneConfig.OreCount * usableX / usableZ)))
	local rows = math.max(1, math.ceil(zoneConfig.OreCount / cols))
	local cellX = usableX / cols
	local cellZ = usableZ / rows

	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			if #positions >= zoneConfig.OreCount then
				break
			end

			local baseX = areaOrigin.X - size.X / 2 + margin + cellX * (col + 0.5)
			local baseZ = areaOrigin.Z + margin + cellZ * (row + 0.5)
			local jitterX = (math.random() - 0.5) * cellX * 0.6
			local jitterZ = (math.random() - 0.5) * cellZ * 0.6
			table.insert(positions, Vector3.new(baseX + jitterX, areaOrigin.Y, baseZ + jitterZ))
		end
	end

	return positions
end

local function buildWeightedOrePool(zoneConfig, zoneFolder, areaOrigin, areaDepth, poolId)
	local positions = computeGridSlots(zoneConfig, areaOrigin, areaDepth)
	registerOrePool(zoneFolder, zoneConfig.Name, zoneConfig.RespawnTime, positions, poolId, function()
		local oreType = pickOreType(zoneConfig.OreTypes)
		return oreType, zoneConfig.OreValue * oreType.Multiplier
	end)
end

-- === Room shell (floor segments + walls/ceiling for enclosed zones) ===
--
-- Floor is built separately from walls/ceiling (rather than one solid slab)
-- so Dark Mines can leave a real gap under its lava -- a single floor
-- spanning the whole room would sit as an invisible solid slab UNDER the
-- lava part, making the "pit" unreachable and the lava never touchable.

local function addFloorSegment(zoneConfig, zoneFolder, startZ, depth)
	local size = zoneConfig.RoomSize
	local origin = zoneConfig.Origin

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(size.X, 2, depth)
	floor.CFrame = CFrame.new(origin.X, origin.Y - 1, startZ + depth / 2)
	floor.Material = zoneConfig.GroundMaterial
	floor.Color = zoneConfig.GroundColor
	floor.Parent = zoneFolder
end

local function buildWallsAndCeiling(zoneConfig, zoneFolder)
	if not zoneConfig.Enclosed then
		return
	end

	local size = zoneConfig.RoomSize
	local origin = zoneConfig.Origin

	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Anchored = true
	ceiling.Size = Vector3.new(size.X, 2, size.Z)
	ceiling.CFrame = CFrame.new(origin.X, origin.Y + size.Y, origin.Z + size.Z / 2)
	ceiling.Material = zoneConfig.WallMaterial
	ceiling.Color = zoneConfig.WallColor
	ceiling.Parent = zoneFolder

	local function addWall(cframe, wallSize)
		local wall = Instance.new("Part")
		wall.Name = "Wall"
		wall.Anchored = true
		wall.Size = wallSize
		wall.CFrame = cframe
		wall.Material = zoneConfig.WallMaterial
		wall.Color = zoneConfig.WallColor
		wall.Parent = zoneFolder
	end

	-- Left/right walls run the full depth; a back wall closes the far end.
	-- The near end (facing the previous zone) is left open as the entrance.
	addWall(CFrame.new(origin.X - size.X / 2, origin.Y + size.Y / 2, origin.Z + size.Z / 2), Vector3.new(2, size.Y, size.Z))
	addWall(CFrame.new(origin.X + size.X / 2, origin.Y + size.Y / 2, origin.Z + size.Z / 2), Vector3.new(2, size.Y, size.Z))
	addWall(CFrame.new(origin.X, origin.Y + size.Y / 2, origin.Z + size.Z), Vector3.new(size.X, size.Y, 2))
end

local function buildStandardZone(zoneConfig, zonesFolder)
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = zoneConfig.Name
	zoneFolder.Parent = zonesFolder

	addFloorSegment(zoneConfig, zoneFolder, zoneConfig.Origin.Z, zoneConfig.RoomSize.Z)
	buildWallsAndCeiling(zoneConfig, zoneFolder)
	buildWeightedOrePool(zoneConfig, zoneFolder, zoneConfig.Origin, zoneConfig.RoomSize.Z, zoneConfig.Name)
end

-- === Dark Mines: entrance (safe ore) -> lava + jump platforms -> treasure ===

local function getCharacterPlayer(part)
	local character = part.Parent
	if not character or not character:FindFirstChildOfClass("Humanoid") then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function addCheckpoint(zoneFolder, cframe, size, order)
	local checkpoint = Instance.new("Part")
	checkpoint.Name = "Checkpoint"
	checkpoint.Anchored = true
	checkpoint.CanCollide = false
	checkpoint.Transparency = 1
	checkpoint.Size = size
	checkpoint.CFrame = cframe
	checkpoint.Parent = zoneFolder
	checkpoint:SetAttribute("CheckpointOrder", order)
end

local function setupCheckpoints(zoneFolder)
	for _, part in zoneFolder:GetChildren() do
		if part.Name == "Checkpoint" then
			part.Touched:Connect(function(hit)
				local player = getCharacterPlayer(hit)
				if not player then
					return
				end
				local order = part:GetAttribute("CheckpointOrder") or 0
				local current = lastCheckpoint[player]
				if not current or order >= current.Order then
					lastCheckpoint[player] = { CFrame = part.CFrame, Order = order }
				end
			end)
		end
	end
end

local function setupLavaKillZone(lava, defaultCFrame)
	lava.Touched:Connect(function(hit)
		local player = getCharacterPlayer(hit)
		if not player or teleportCooldown[player] then
			return
		end

		teleportCooldown[player] = true

		local character = player.Character
		if character then
			local checkpoint = lastCheckpoint[player]
			local targetCFrame = checkpoint and checkpoint.CFrame or defaultCFrame
			character:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
		end

		Remotes.ZoneNotice:FireClient(player, "You fell into the lava! Back to your last checkpoint.")

		task.delay(1, function()
			teleportCooldown[player] = nil
		end)
	end)
end

local function buildDarkMines(zoneConfig, zonesFolder)
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = zoneConfig.Name
	zoneFolder.Parent = zonesFolder

	buildWallsAndCeiling(zoneConfig, zoneFolder)

	local size = zoneConfig.RoomSize
	local origin = zoneConfig.Origin

	-- Entrance floor only -- no floor under the lava gap (see
	-- addFloorSegment's comment), and the treasure platform built below
	-- doubles as the floor for the far end.
	addFloorSegment(zoneConfig, zoneFolder, origin.Z, DARK_MINES_ENTRANCE_DEPTH)

	-- Safe entrance ore
	buildWeightedOrePool(zoneConfig, zoneFolder, origin, DARK_MINES_ENTRANCE_DEPTH, zoneConfig.Name .. "_Entrance")

	local entranceCheckpointCFrame = CFrame.new(origin.X, origin.Y + 2, origin.Z + DARK_MINES_ENTRANCE_DEPTH - 4)
	addCheckpoint(zoneFolder, entranceCheckpointCFrame, Vector3.new(size.X - 4, 1, 4), 1)

	-- Lava pit -- fills the Z gap between the entrance floor and the
	-- treasure platform, well below floor level so falling through actually
	-- reads as falling into a pit rather than clipping through a thin gap.
	local lavaZ = origin.Z + DARK_MINES_ENTRANCE_DEPTH + DARK_MINES_LAVA_DEPTH / 2
	local lava = Instance.new("Part")
	lava.Name = "Lava"
	lava.Anchored = true
	lava.Size = Vector3.new(size.X - 4, 1, DARK_MINES_LAVA_DEPTH)
	lava.CFrame = CFrame.new(origin.X, origin.Y - 15, lavaZ)
	lava.Material = Enum.Material.Neon
	lava.Color = zoneConfig.LavaColor
	lava.Parent = zoneFolder

	local lavaLight = Instance.new("PointLight")
	lavaLight.Color = zoneConfig.LavaColor
	lavaLight.Range = 24
	lavaLight.Brightness = 2
	lavaLight.Parent = lava

	setupLavaKillZone(lava, entranceCheckpointCFrame)

	-- Jump platforms across the lava, zigzagging left/right
	local zStep = DARK_MINES_LAVA_DEPTH / (DARK_MINES_PLATFORM_COUNT + 1)
	local midIndex = math.floor(DARK_MINES_PLATFORM_COUNT / 2) + 1

	for i = 1, DARK_MINES_PLATFORM_COUNT do
		local px = origin.X + (i % 2 == 0 and 1 or -1) * DARK_MINES_PLATFORM_X_OFFSET
		local pz = origin.Z + DARK_MINES_ENTRANCE_DEPTH + zStep * i
		local platformCFrame = CFrame.new(px, origin.Y, pz)

		local platform = Instance.new("Part")
		platform.Name = "Platform" .. i
		platform.Anchored = true
		platform.Size = DARK_MINES_PLATFORM_SIZE
		platform.CFrame = platformCFrame
		platform.Material = zoneConfig.WallMaterial
		platform.Color = zoneConfig.WallColor
		platform.Parent = zoneFolder

		if i == midIndex then
			addCheckpoint(zoneFolder, platformCFrame + Vector3.new(0, 2.5, 0), Vector3.new(DARK_MINES_PLATFORM_SIZE.X, 3, DARK_MINES_PLATFORM_SIZE.Z), 2)
		end
	end

	-- Treasure platform (rare ore), past the lava
	local treasureZ = origin.Z + DARK_MINES_ENTRANCE_DEPTH + DARK_MINES_LAVA_DEPTH + DARK_MINES_TREASURE_DEPTH / 2
	local treasurePlatform = Instance.new("Part")
	treasurePlatform.Name = "TreasurePlatform"
	treasurePlatform.Anchored = true
	treasurePlatform.Size = Vector3.new(size.X - 10, 2, DARK_MINES_TREASURE_DEPTH - 4)
	treasurePlatform.CFrame = CFrame.new(origin.X, origin.Y - 1, treasureZ)
	treasurePlatform.Material = zoneConfig.GroundMaterial
	treasurePlatform.Color = zoneConfig.GroundColor
	treasurePlatform.Parent = zoneFolder

	local treasureCheckpointCFrame = CFrame.new(origin.X, origin.Y + 2, treasureZ - DARK_MINES_TREASURE_DEPTH / 2 + 3)
	addCheckpoint(zoneFolder, treasureCheckpointCFrame, Vector3.new(size.X - 10, 3, 4), 3)

	local treasurePositions = {}
	for _ = 1, zoneConfig.RareOreCount do
		local px = origin.X + (math.random() - 0.5) * (size.X - 16)
		local pz = treasureZ + (math.random() - 0.5) * (DARK_MINES_TREASURE_DEPTH - 8)
		table.insert(treasurePositions, Vector3.new(px, origin.Y, pz))
	end
	registerOrePool(zoneFolder, zoneConfig.Name, zoneConfig.RespawnTime, treasurePositions, zoneConfig.Name .. "_Treasure", function()
		return zoneConfig.RareOreType, zoneConfig.OreValue * zoneConfig.RareOreType.Multiplier
	end)

	setupCheckpoints(zoneFolder)
end

-- === Zone bootstrap ===

local function ensureZonesExist()
	if Workspace:FindFirstChild("MiningZones") then
		return
	end

	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "MiningZones"
	zonesFolder.Parent = Workspace

	for _, zoneConfig in Config.Zones do
		if zoneConfig.IsDarkMines then
			buildDarkMines(zoneConfig, zonesFolder)
		else
			buildStandardZone(zoneConfig, zonesFolder)
		end
	end
end

-- === Mining interaction ===

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
		-- Debounce: without this, two MouseClick firings that both start
		-- before the first one's Destroy() below takes effect could grant
		-- the reward twice.
		return
	end
	node:SetAttribute("Mining", true)

	local zoneName = node:GetAttribute("ZoneName")
	if not isZoneUnlocked(player, zoneName) then
		node:SetAttribute("Mining", false)
		return
	end

	local baseValue = node:GetAttribute("CashValue") or 1
	local reward = baseValue
		* pickaxeMultiplier(player)
		* rebirthMultiplier(player)
		* MarketplaceService.GetCashMultiplier(player)
	DataService.AddCash(player, reward)

	local poolId = node:GetAttribute("PoolId")
	local respawnTime = node:GetAttribute("RespawnTime") or 3
	node:Destroy()

	task.delay(respawnTime, function()
		local pool = orePools[poolId]
		if not pool or #pool.positions == 0 then
			return
		end
		spawnOreAt(poolId, pool.positions[math.random(1, #pool.positions)])
	end)
end

local function hookNode(node)
	local rock = node:FindFirstChild("Rock")
	local click = rock and rock:FindFirstChildOfClass("ClickDetector")
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

	Players.PlayerRemoving:Connect(function(player)
		lastCheckpoint[player] = nil
		teleportCooldown[player] = nil
	end)
end

return MiningService
