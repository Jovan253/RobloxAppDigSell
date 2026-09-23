-- Removes Studio's default "Baseplate" (the flat grey sandbox floor that
-- otherwise extends infinitely past the built zones) and replaces it with a
-- themed, finite ground fill covering the gaps between zones -- computed
-- from Config.Zones geometry so it stays correct if zones move.
--
-- Deliberately builds this as several rectangular strips around the known
-- zone footprints, rather than one big slab under everything: a single slab
-- would sit right under Dark Mines' lava pit (which has no floor there on
-- purpose, see MiningService) and silently "catch" players who fall in,
-- breaking that feature.
--
-- Also adds light distance fog so the ground fill's own edges (finite, ~80
-- studs past the outermost zone) fade into haze instead of ending abruptly.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

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

	local hubConfig = Config.Zones[1]
	local hubLeft = hubConfig.Origin.X - hubConfig.RoomSize.X / 2
	local hubRight = hubConfig.Origin.X + hubConfig.RoomSize.X / 2
	local hubFrontZ = hubConfig.Origin.Z
	local hubBackZ = hubConfig.Origin.Z + hubConfig.RoomSize.Z

	local spokeEdges = {}
	local overallLeft, overallRight = hubLeft, hubRight
	local maxSpokeZ = hubBackZ

	for i = 2, #Config.Zones do
		local zoneConfig = Config.Zones[i]
		local left = zoneConfig.Origin.X - zoneConfig.RoomSize.X / 2
		local right = zoneConfig.Origin.X + zoneConfig.RoomSize.X / 2
		table.insert(spokeEdges, { left = left, right = right })
		overallLeft = math.min(overallLeft, left)
		overallRight = math.max(overallRight, right)
		maxSpokeZ = math.max(maxSpokeZ, zoneConfig.Origin.Z + zoneConfig.RoomSize.Z)
	end
	table.sort(spokeEdges, function(a, b)
		return a.left < b.left
	end)

	-- Around the hub: south margin (spawn side), west margin, east margin.
	-- Never touches the hub's own X range, so it can't overlap its floor.
	addGroundStrip(groundFolder, overallLeft - MARGIN, overallRight + MARGIN, hubFrontZ - MARGIN, hubFrontZ)
	addGroundStrip(groundFolder, overallLeft - MARGIN, hubLeft, hubFrontZ, hubBackZ)
	addGroundStrip(groundFolder, hubRight, overallRight + MARGIN, hubFrontZ, hubBackZ)

	-- Between/around the spoke zones, sorted left to right. Each strip sits
	-- strictly between two zones' edges (or a zone's edge and the margin),
	-- so it never overlaps any zone's own footprint -- including Dark
	-- Mines', which is what keeps its lava pit un-floored.
	if #spokeEdges > 0 then
		addGroundStrip(groundFolder, overallLeft - MARGIN, spokeEdges[1].left, hubBackZ, maxSpokeZ + MARGIN)
		for i = 1, #spokeEdges - 1 do
			addGroundStrip(groundFolder, spokeEdges[i].right, spokeEdges[i + 1].left, hubBackZ, maxSpokeZ + MARGIN)
		end
		addGroundStrip(groundFolder, spokeEdges[#spokeEdges].right, overallRight + MARGIN, hubBackZ, maxSpokeZ + MARGIN)
	end

	-- Far margin beyond the deepest zone.
	addGroundStrip(groundFolder, overallLeft - MARGIN, overallRight + MARGIN, maxSpokeZ, maxSpokeZ + MARGIN)
end

local function setupAtmosphere()
	Lighting.FogColor = Color3.fromRGB(150, 140, 130)
	Lighting.FogStart = 150
	Lighting.FogEnd = 500
end

function EnvironmentService.Init()
	removeDefaultBaseplate()
	buildGroundFill()
	setupAtmosphere()
end

return EnvironmentService
