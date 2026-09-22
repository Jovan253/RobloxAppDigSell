-- Shop panel for pickaxe/zone purchases. Toggle with the corner button or
-- the "B" key. Prices/tiers come from ReplicatedStorage.Config; current
-- progress comes from the player's PlayerData value objects (see
-- DataService) and leaderstats.Cash, all of which just replicate -- no
-- RemoteFunction round-trip needed to render the panel.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local playerData = player:WaitForChild("PlayerData")
local pickaxeTierValue = playerData:WaitForChild("PickaxeTier")
local unlockedZonesValue = playerData:WaitForChild("UnlockedZones")

local OWNED_COLOR = Color3.fromRGB(60, 60, 60)
local AFFORDABLE_COLOR = Color3.fromRGB(35, 120, 60)
local UNAFFORDABLE_COLOR = Color3.fromRGB(120, 60, 35)

local function getUnlockedZones()
	local zones = {}
	for zoneName in unlockedZonesValue.Value:gmatch("[^,]+") do
		zones[zoneName] = true
	end
	return zones
end

-- === GUI scaffold ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUi"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(1, 0)
toggleButton.Position = UDim2.new(1, -16, 0, 16)
toggleButton.Size = UDim2.new(0, 100, 0, 44)
toggleButton.BackgroundColor3 = AFFORDABLE_COLOR
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.Text = "Shop"
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.Size = UDim2.new(0, 420, 0, 480)
shopFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopFrame

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -8, 0, 8)
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.BackgroundColor3 = OWNED_COLOR
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.Text = "X"
closeButton.Parent = shopFrame

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
title.Text = "Shop"
title.Parent = shopFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "Scroll"
scrollFrame.Position = UDim2.new(0, 16, 0, 56)
scrollFrame.Size = UDim2.new(1, -32, 1, -72)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = shopFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local function addSectionHeader(text, order)
	local header = Instance.new("TextLabel")
	header.Name = "Header_" .. text
	header.Size = UDim2.new(1, 0, 0, 28)
	header.BackgroundTransparency = 1
	header.TextColor3 = Color3.fromRGB(200, 200, 200)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 18
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = text
	header.LayoutOrder = order
	header.Parent = scrollFrame
end

local function addRow(order)
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	row.LayoutOrder = order
	row.Parent = scrollFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Size = UDim2.new(1, -132, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = ""
	label.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "BuyButton"
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -12, 0.5, 0)
	button.Size = UDim2.new(0, 100, 0, 36)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	return label, button
end

addSectionHeader("Pickaxe", 1)

local pickaxeRows = {}
for index, tier in Config.PickaxeTiers do
	local label, button = addRow(1 + index)
	button.MouseButton1Click:Connect(function()
		Remotes.PurchaseUpgrade:FireServer(index)
	end)
	pickaxeRows[index] = { label = label, button = button, tier = tier }
end

addSectionHeader("Zones", 100)

local zoneRows = {}
for i, zoneConfig in Config.Zones do
	local label, button = addRow(100 + i)
	button.MouseButton1Click:Connect(function()
		Remotes.PurchaseZone:FireServer(zoneConfig.Name)
	end)
	zoneRows[zoneConfig.Name] = { label = label, button = button, config = zoneConfig }
end

local function refresh()
	local cash = cashValue.Value
	local currentTier = pickaxeTierValue.Value
	local unlocked = getUnlockedZones()

	for index, entry in pickaxeRows do
		local tier, label, button = entry.tier, entry.label, entry.button
		if index <= currentTier then
			label.Text = ("%s (owned)"):format(tier.Name)
			button.Text = "Owned"
			button.Active = false
			button.BackgroundColor3 = OWNED_COLOR
		elseif index == currentTier + 1 then
			label.Text = ("%s -- x%d cash/hit"):format(tier.Name, tier.Multiplier)
			button.Text = tostring(tier.Cost)
			button.Active = true
			button.BackgroundColor3 = cash >= tier.Cost and AFFORDABLE_COLOR or UNAFFORDABLE_COLOR
		else
			label.Text = ("%s -- locked"):format(tier.Name)
			button.Text = "Locked"
			button.Active = false
			button.BackgroundColor3 = OWNED_COLOR
		end
	end

	for zoneName, entry in zoneRows do
		local config, label, button = entry.config, entry.label, entry.button
		if unlocked[zoneName] then
			label.Text = ("%s (unlocked)"):format(config.DisplayName)
			button.Text = "Unlocked"
			button.Active = false
			button.BackgroundColor3 = OWNED_COLOR
		else
			label.Text = ("%s -- ore worth %d"):format(config.DisplayName, config.OreValue)
			button.Text = tostring(config.UnlockCost)
			button.Active = true
			button.BackgroundColor3 = cash >= config.UnlockCost and AFFORDABLE_COLOR or UNAFFORDABLE_COLOR
		end
	end
end

cashValue:GetPropertyChangedSignal("Value"):Connect(refresh)
pickaxeTierValue:GetPropertyChangedSignal("Value"):Connect(refresh)
unlockedZonesValue:GetPropertyChangedSignal("Value"):Connect(refresh)
refresh()

local function setOpen(open)
	shopFrame.Visible = open
end

toggleButton.MouseButton1Click:Connect(function()
	setOpen(not shopFrame.Visible)
end)

closeButton.MouseButton1Click:Connect(function()
	setOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		setOpen(not shopFrame.Visible)
	end
end)
