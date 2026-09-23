-- Gives each player an equippable Tool matching their current pickaxe
-- tier -- built procedurally (handle + head, no mesh assets needed),
-- colored per tier so upgrading is visually obvious. Reacts to
-- PlayerData.PickaxeTier's replicated value directly, so it stays correct
-- through shop purchases, rebirth resets, and the admin override alike
-- without needing to be called from each of those sites individually.
-- Purely cosmetic: mining itself still validates through each ore's
-- ClickDetector (see MiningService), unaffected by whether a tool is
-- equipped.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataService = require(script.Parent.DataService)

local PickaxeToolService = {}

local TIER_LOOKS = {
	[1] = { Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 85, 55) },
	[2] = { Material = Enum.Material.Slate, Color = Color3.fromRGB(140, 140, 140) },
	[3] = { Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 150, 155) },
	[4] = { Material = Enum.Material.Metal, Color = Color3.fromRGB(230, 190, 60) },
	[5] = { Material = Enum.Material.Glass, Color = Color3.fromRGB(180, 230, 240) },
}

local toolTemplates = {}

local function buildToolTemplate(tierIndex)
	local tier = Config.PickaxeTiers[tierIndex]
	local look = TIER_LOOKS[tierIndex] or TIER_LOOKS[1]

	local tool = Instance.new("Tool")
	tool.Name = tier and tier.Name or "Pickaxe"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsPickaxe", true)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 2.4, 0.4)
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromRGB(92, 64, 40)
	handle.CanCollide = false
	handle.Parent = tool

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.6, 0.4, 0.4)
	head.Material = look.Material
	head.Color = look.Color
	head.CanCollide = false
	head.CFrame = handle.CFrame * CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	head.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = head
	weld.Parent = handle

	tool.Grip = CFrame.new(0, -0.9, 0) * CFrame.Angles(math.rad(-90), 0, 0)

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
