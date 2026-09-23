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

local function formatNumber(n)
	local formatted = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local barriers = {} -- [zoneName] = { part = Part, gui = SurfaceGui }

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

		-- Face = Front means the label renders on the -Z side of the part,
		-- which (since none of this is rotated) is the side facing the hub
		-- -- i.e. readable as you walk up to the entrance.
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Label"
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0
		gui.Parent = barrier

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0.2
		label.TextScaled = true
		label.Text = ("%s\n%s Cash to Unlock"):format(zoneConfig.DisplayName, formatNumber(zoneConfig.UnlockCost))
		label.Parent = gui

		barriers[zoneConfig.Name] = { part = barrier, gui = gui }
	end
end

local function refresh()
	for zoneName, barrier in barriers do
		local unlocked = isUnlocked(zoneName)
		barrier.part.CanCollide = not unlocked
		barrier.part.Transparency = unlocked and 1 or 0.6
		barrier.gui.Enabled = not unlocked
	end
end

unlockedZonesValue:GetPropertyChangedSignal("Value"):Connect(refresh)
refresh()
