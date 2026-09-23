-- Creates (server) or looks up (client) the shared RemoteEvents used by the
-- shop/rebirth flows, plus a couple of server->client-only ones (Dark Mines
-- lava/jumpscare feedback). Cash itself is not pushed over a remote: clients
-- read it from the player's leaderstats.Cash value, which is simpler and
-- avoids keeping two sources of truth in sync.
local RunService = game:GetService("RunService")

local REMOTE_NAMES = { "PurchaseUpgrade", "PurchaseZone", "Rebirth", "ZoneNotice", "JumpscareEffect", "MineHit", "ClaimOreReward" }

local remotesFolder

if RunService:IsServer() then
	-- Parented under this ModuleScript (not ReplicatedStorage) so the folder
	-- name can't collide with the "Remotes" ModuleScript instance itself.
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "RemoteEvents"
	remotesFolder.Parent = script

	for _, name in REMOTE_NAMES do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotesFolder
	end
else
	remotesFolder = script:WaitForChild("RemoteEvents")
end

local Remotes = {}
for _, name in REMOTE_NAMES do
	Remotes[name] = remotesFolder:WaitForChild(name)
end

return Remotes
