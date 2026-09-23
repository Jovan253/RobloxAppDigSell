-- Collection Journal: shows every ore type across all 5 zones, grouped by
-- zone, with collected/uncollected state. Undiscovered types show "???"
-- instead of their name -- an incentive to go find them, not just a
-- checklist. Discovering a type (mining it for the first time) is
-- automatic, but the Gem reward for it isn't -- click Claim to take it,
-- which fires Remotes.ClaimOreReward (server re-validates everything; this
-- UI is just a reflection of PlayerData). Toggle with the corner button or
-- the "J" key.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerData = player:WaitForChild("PlayerData")
local collectedOreTypesValue = playerData:WaitForChild("CollectedOreTypes")
local claimedOreTypesValue = playerData:WaitForChild("ClaimedOreTypes")

local OWNED_COLOR = Color3.fromRGB(60, 60, 60)
local AFFORDABLE_COLOR = Color3.fromRGB(35, 120, 60)

local function getNameSet(value)
	local set = {}
	for name in value.Value:gmatch("[^,]+") do
		set[name] = true
	end
	return set
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JournalUi"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(1, 0)
toggleButton.Position = UDim2.new(1, -16, 0, 120)
toggleButton.Size = UDim2.new(0, 100, 0, 44)
toggleButton.BackgroundColor3 = Color3.fromRGB(90, 60, 130)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.Text = "Journal"
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 440, 0, 520)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -8, 0, 8)
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.Text = "X"
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.new(0, 16, 0, 12)
title.Size = UDim2.new(1, -60, 0, 32)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Collection Journal"
title.Parent = panel

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "Scroll"
scrollFrame.Position = UDim2.new(0, 16, 0, 56)
scrollFrame.Size = UDim2.new(1, -32, 1, -72)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local function addSectionHeader(text, order)
	local header = Instance.new("TextLabel")
	header.Name = "Header_" .. text
	header.Size = UDim2.new(1, 0, 0, 26)
	header.BackgroundTransparency = 1
	header.TextColor3 = Color3.fromRGB(200, 200, 200)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 16
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = text
	header.LayoutOrder = order
	header.Parent = scrollFrame
end

local entries = {} -- { label, swatch, button, oreType }

local function addOreRow(oreType, order)
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	row.LayoutOrder = order
	row.Parent = scrollFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.AnchorPoint = Vector2.new(0, 0.5)
	swatch.Position = UDim2.new(0, 8, 0.5, 0)
	swatch.Size = UDim2.new(0, 24, 0, 24)
	swatch.BackgroundColor3 = oreType.Color
	swatch.Parent = row

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(0, 6)
	swatchCorner.Parent = swatch

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Position = UDim2.new(0, 44, 0, 0)
	label.Size = UDim2.new(1, -152, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = ""
	label.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "ClaimButton"
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -8, 0.5, 0)
	button.Size = UDim2.new(0, 96, 0, 32)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	button.MouseButton1Click:Connect(function()
		Remotes.ClaimOreReward:FireServer(oreType.Name)
	end)

	table.insert(entries, { label = label, swatch = swatch, button = button, oreType = oreType })
end

for zoneOrder, zoneConfig in Config.Zones do
	addSectionHeader(zoneConfig.DisplayName, zoneOrder * 100)

	for oreOrder, oreType in zoneConfig.OreTypes do
		addOreRow(oreType, zoneOrder * 100 + oreOrder)
	end

	if zoneConfig.RareOreType then
		addOreRow(zoneConfig.RareOreType, zoneOrder * 100 + #zoneConfig.OreTypes + 1)
	end
end

local function refresh()
	local collected = getNameSet(collectedOreTypesValue)
	local claimed = getNameSet(claimedOreTypesValue)

	for _, entry in entries do
		local oreType = entry.oreType
		local label, swatch, button = entry.label, entry.swatch, entry.button

		if not collected[oreType.Name] then
			label.Text = "???"
			label.TextColor3 = Color3.fromRGB(130, 130, 130)
			swatch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			swatch.BackgroundTransparency = 0.4
			button.Text = "???"
			button.Active = false
			button.BackgroundColor3 = OWNED_COLOR
		else
			swatch.BackgroundColor3 = oreType.Color
			swatch.BackgroundTransparency = 0
			label.TextColor3 = Color3.fromRGB(255, 255, 255)

			local claimGems = oreType.ClaimGems or 0
			if claimed[oreType.Name] then
				label.Text = oreType.Name
				button.Text = "Claimed"
				button.Active = false
				button.BackgroundColor3 = OWNED_COLOR
			elseif claimGems > 0 then
				label.Text = ("%s -- +%d Gems/mine"):format(oreType.Name, oreType.Gems or 0)
				button.Text = ("Claim +%d"):format(claimGems)
				button.Active = true
				button.BackgroundColor3 = AFFORDABLE_COLOR
			else
				-- Discovered, nothing to claim (e.g. Common tier).
				label.Text = ("%s -- +%d Gems/mine"):format(oreType.Name, oreType.Gems or 0)
				button.Text = "--"
				button.Active = false
				button.BackgroundColor3 = OWNED_COLOR
			end
		end
	end
end

collectedOreTypesValue:GetPropertyChangedSignal("Value"):Connect(refresh)
claimedOreTypesValue:GetPropertyChangedSignal("Value"):Connect(refresh)
refresh()

local function setOpen(open)
	panel.Visible = open
end

toggleButton.MouseButton1Click:Connect(function()
	setOpen(not panel.Visible)
end)

closeButton.MouseButton1Click:Connect(function()
	setOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.J then
		setOpen(not panel.Visible)
	end
end)
