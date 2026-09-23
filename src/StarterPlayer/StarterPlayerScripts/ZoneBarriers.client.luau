-- Red translucent barrier across the entrance of any zone this player
-- hasn't unlocked yet. Created purely on the client (never replicated) so
-- it blocks THIS player without affecting anyone else who has already
-- unlocked the zone -- a server-side Part's CanCollide can't differ per
-- player, but a client-only Part still physically blocks the local
-- character (client-side collision is simulated locally same as any other
-- part in the local Workspace). This is a UX convenience only: the actual
-- security boundary is server-side (MiningService checks UnlockedZones
-- before granting any reward regardless of where the player is standing).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer
local playerData = player:WaitForChild("PlayerData")
local unlockedZonesValue = playerData:WaitForChild("UnlockedZones")

local function isUnlocked(zoneName)
	for name in unlockedZonesValue.Value:gmatch("[^,]+") do
		if name == zoneName then
			return true
		end
	end
	return false
end

local barriers = {} -- [zoneName] = Part

for _, zoneConfig in Config.Zones do
	if zoneConfig.UnlockCost > 0 then
		local size = zoneConfig.RoomSize
		local origin = zoneConfig.Origin
		local height = zoneConfig.Enclosed and size.Y or 10

		local barrier = Instance.new("Part")
		barrier.Name = "ZoneBarrier_" .. zoneConfig.Name
		barrier.Anchored = true
		barrier.CanCollide = true
		barrier.Material = Enum.Material.ForceField
		barrier.Color = Color3.fromRGB(200, 30, 30)
		barrier.Transparency = 0.6
		barrier.Size = Vector3.new(size.X, height, 1)
		barrier.CFrame = CFrame.new(origin.X, origin.Y + height / 2, origin.Z)
		barrier.Parent = Workspace

		barriers[zoneConfig.Name] = barrier
	end
end

local function refresh()
	for zoneName, barrier in barriers do
		local unlocked = isUnlocked(zoneName)
		barrier.CanCollide = not unlocked
		barrier.Transparency = unlocked and 1 or 0.6
	end
end

unlockedZonesValue:GetPropertyChangedSignal("Value"):Connect(refresh)
refresh()
