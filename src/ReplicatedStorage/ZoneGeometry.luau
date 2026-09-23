-- Shared zone-local-to-world coordinate helpers. A zone's Origin is the
-- point on its edge closest to the hub; Orientation ("North"/"South"/
-- "East"/"West", default "North") says which compass side of the hub it's
-- on, and therefore which world axis its "depth" (away from the hub) runs
-- along. Parts stay world-axis-aligned (no CFrame rotation) -- an East/West
-- zone just swaps which RoomSize component maps to which world axis.
--
-- Used by both MiningService (building the zones) and client scripts
-- (ZoneBarriers) that need to independently agree on where a zone's
-- entrance is and which way it faces.
local ZoneGeometry = {}

local ORIENTATIONS = {
	North = { depthAxis = "Z", depthSign = 1 },
	South = { depthAxis = "Z", depthSign = -1 },
	East = { depthAxis = "X", depthSign = 1 },
	West = { depthAxis = "X", depthSign = -1 },
}

-- The SurfaceGui NormalId that faces back toward the hub for each
-- orientation (i.e. the face visible as you approach from the hub).
ZoneGeometry.FaceTowardHub = {
	North = Enum.NormalId.Front,
	South = Enum.NormalId.Back,
	East = Enum.NormalId.Left,
	West = Enum.NormalId.Right,
}

-- widthOffset: distance from the zone's centerline, perpendicular to depth.
-- depthOffset: distance from Origin along the depth direction (0 = hub edge).
-- yOffset: added directly to Origin.Y.
function ZoneGeometry.point(zoneConfig, widthOffset, depthOffset, yOffset)
	local orient = ORIENTATIONS[zoneConfig.Orientation or "North"]
	local origin = zoneConfig.Origin
	local x, z

	if orient.depthAxis == "Z" then
		x = origin.X + widthOffset
		z = origin.Z + orient.depthSign * depthOffset
	else
		x = origin.X + orient.depthSign * depthOffset
		z = origin.Z + widthOffset
	end

	return Vector3.new(x, origin.Y + (yOffset or 0), z)
end

-- Converts local (width, depth, height) part dimensions into a world Size.
function ZoneGeometry.size(zoneConfig, width, depth, height)
	local orient = ORIENTATIONS[zoneConfig.Orientation or "North"]
	if orient.depthAxis == "Z" then
		return Vector3.new(width, height, depth)
	end
	return Vector3.new(depth, height, width)
end

-- World-space bounding rectangle of the zone's full RoomSize footprint.
function ZoneGeometry.bounds(zoneConfig)
	local corner1 = ZoneGeometry.point(zoneConfig, -zoneConfig.RoomSize.X / 2, 0, 0)
	local corner2 = ZoneGeometry.point(zoneConfig, zoneConfig.RoomSize.X / 2, zoneConfig.RoomSize.Z, 0)
	return {
		minX = math.min(corner1.X, corner2.X),
		maxX = math.max(corner1.X, corner2.X),
		minZ = math.min(corner1.Z, corner2.Z),
		maxZ = math.max(corner1.Z, corner2.Z),
	}
end

return ZoneGeometry
