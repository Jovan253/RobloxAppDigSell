-- Collection Journal: shows every ore type across all 5 zones, grouped by
-- zone, with collected/uncollected state. Undiscovered types show "???"
-- instead of their name -- an incentive to go find them, not just a
-- checklist. Toggle with the corner button or the "J" key. Read-only (no
-- purchases here, unlike the Shop panel it's styled after).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerData = player:WaitForChild("PlayerData")
local collectedOreTypesValue = playerData:WaitForChild("CollectedOreTypes")

local function getCollectedSet()
	local set = {}
	for name in collectedOreTypesValue.Value:gmatch("[^,]+") do
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
panel.Size = UDim2.new(0, 420, 0, 520)
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

local entries = {} -- { label, oreType }

local function addOreRow(oreType, order)
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.new(1, 0, 0, 40)
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
	label.Size = UDim2.new(1, -54, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Gotham
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.Parent = row

	table.insert(entries, { label = label, swatch = swatch, oreType = oreType })
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
	local collected = getCollectedSet()

	for _, entry in entries do
		local oreType = entry.oreType
		if collected[oreType.Name] then
			entry.label.Text = ("%s -- %d Gem%s"):format(oreType.Name, oreType.Gems or 0, (oreType.Gems == 1) and "" or "s")
			entry.label.TextColor3 = Color3.fromRGB(255, 255, 255)
			entry.swatch.BackgroundColor3 = oreType.Color
			entry.swatch.BackgroundTransparency = 0
		else
			entry.label.Text = "???"
			entry.label.TextColor3 = Color3.fromRGB(130, 130, 130)
			entry.swatch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			entry.swatch.BackgroundTransparency = 0.4
		end
	end
end

collectedOreTypesValue:GetPropertyChangedSignal("Value"):Connect(refresh)
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
