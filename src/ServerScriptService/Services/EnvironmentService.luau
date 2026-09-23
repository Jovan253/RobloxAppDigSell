-- Removes Studio's default "Baseplate" (the flat grey sandbox floor that
-- otherwise extends infinitely past the built zones) and replaces it with a
-- themed, finite ground fill covering the gaps between zones -- computed
-- from Config.Zones geometry (via ZoneGeometry, so it's orientation-aware)
-- so it stays correct if zones move or change sides.
--
-- Deliberately builds this via rectangle-grid decomposition (collect every
-- zone's X/Z edges, sort them into a grid, fill any cell whose center isn't
-- inside a zone's footprint) rather than one big slab under everything: a
-- single slab would sit right under Dark Mines' lava pit (which has no
-- floor there on purpose, see MiningService) and silently "catch" players
-- who fall in, breaking that feature. This approach is correct for any
-- axis-aligned zone arrangement, not just the current hub-and-spoke one.
--
-- Also adds light distance fog so the ground fill's own edges (finite, ~80
-- studs past the outermost zone) fade into haze instead of ending abruptly.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local ZoneGeometry = require(ReplicatedStorage:WaitForChild("ZoneGeometry"))

local MARGIN = 80
local GROUND_MATERIAL = Enum.Material.Ground
local GROUND_COLOR = Color3.fromRGB(84, 66, 48)

local EnvironmentService = {}

local function removeDefaultBaseplate()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate:Destroy()
	end
end

local function addGroundStrip(zonesFolder, x1, x2, z1, z2)
	if x2 <= x1 or z2 <= z1 then
		return
	end

	local strip = Instance.new("Part")
	strip.Name = "GroundFill"
	strip.Anchored = true
	strip.Size = Vector3.new(x2 - x1, 2, z2 - z1)
	strip.CFrame = CFrame.new((x1 + x2) / 2, 0, (z1 + z2) / 2) -- top surface at Y=1, matching zone floors
	strip.Material = GROUND_MATERIAL
	strip.Color = GROUND_COLOR
	strip.Parent = zonesFolder
end

local function buildGroundFill()
	local groundFolder = Instance.new("Folder")
	groundFolder.Name = "GroundFill"
	groundFolder.Parent = Workspace

	local rects = {}
	local overallMinX, overallMaxX = math.huge, -math.huge
	local overallMinZ, overallMaxZ = math.huge, -math.huge

	for _, zoneConfig in Config.Zones do
		local bounds = ZoneGeometry.bounds(zoneConfig)
		table.insert(rects, bounds)
		overallMinX = math.min(overallMinX, bounds.minX)
		overallMaxX = math.max(overallMaxX, bounds.maxX)
		overallMinZ = math.min(overallMinZ, bounds.minZ)
		overallMaxZ = math.max(overallMaxZ, bounds.maxZ)
	end

	-- Every distinct X/Z edge across all zone rectangles, plus the outer
	-- margin, sorted -- these divide the plane into a grid of cells that
	-- each either lie fully inside one zone's rectangle or fully outside
	-- all of them (never straddling an edge).
	local xEdges, zEdges = { overallMinX - MARGIN, overallMaxX + MARGIN }, { overallMinZ - MARGIN, overallMaxZ + MARGIN }
	for _, rect in rects do
		table.insert(xEdges, rect.minX)
		table.insert(xEdges, rect.maxX)
		table.insert(zEdges, rect.minZ)
		table.insert(zEdges, rect.maxZ)
	end
	table.sort(xEdges)
	table.sort(zEdges)

	local function isInsideAnyZone(x, z)
		for _, rect in rects do
			if x > rect.minX and x < rect.maxX and z > rect.minZ and z < rect.maxZ then
				return true
			end
		end
		return false
	end

	for i = 1, #xEdges - 1 do
		local x1, x2 = xEdges[i], xEdges[i + 1]
		if x2 > x1 then
			for j = 1, #zEdges - 1 do
				local z1, z2 = zEdges[j], zEdges[j + 1]
				if z2 > z1 and not isInsideAnyZone((x1 + x2) / 2, (z1 + z2) / 2) then
					addGroundStrip(groundFolder, x1, x2, z1, z2)
				end
			end
		end
	end
end

local function setupAtmosphere()
	Lighting.FogColor = Color3.fromRGB(150, 140, 130)
	Lighting.FogStart = 150
	Lighting.FogEnd = 500
end

-- Spawn moved to the hub's center now that all 4 sides have a zone (none
-- left open as a natural "entrance" edge). Replaces any existing
-- SpawnLocation(s) so there's exactly one, regardless of what was manually
-- placed in Studio before this.
local function setupSpawn()
	local hubConfig = Config.Zones[1]
	local bounds = ZoneGeometry.bounds(hubConfig)
	local center = Vector3.new((bounds.minX + bounds.maxX) / 2, hubConfig.Origin.Y, (bounds.minZ + bounds.maxZ) / 2)

	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant:Destroy()
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0))
	spawn.Parent = Workspace
end

function EnvironmentService.Init()
	removeDefaultBaseplate()
	buildGroundFill()
	setupAtmosphere()
	setupSpawn()
end

return EnvironmentService
