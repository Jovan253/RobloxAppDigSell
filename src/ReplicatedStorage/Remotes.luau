-- Creates (server) or looks up (client) the shared RemoteEvents used by the
-- shop/rebirth flows. Cash itself is not pushed over a remote: clients read
-- it from the player's leaderstats.Cash value, which is simpler and avoids
-- keeping two sources of truth in sync.
local RunService = game:GetService("RunService")

local REMOTE_NAMES = { "PurchaseUpgrade", "PurchaseZone", "Rebirth" }

local remotesFolder

if RunService:IsServer() then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = script.Parent

	for _, name in REMOTE_NAMES do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotesFolder
	end
else
	remotesFolder = script.Parent:WaitForChild("Remotes")
end

local Remotes = {}
for _, name in REMOTE_NAMES do
	Remotes[name] = remotesFolder:WaitForChild(name)
end

return Remotes
