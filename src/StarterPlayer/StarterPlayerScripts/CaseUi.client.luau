-- Pickaxe skin cases: spend Gems on Remotes.OpenCase, watch a horizontal
-- spinning reel land on the result Remotes.CaseResult reports, then equip
-- any owned skin from the list below. The reel is purely a client-side
-- animation -- CaseService has already committed the outcome server-side
-- before this ever starts spinning, so there's nothing to fake or exploit
-- by watching it. Toggle with the corner button or the "C" key.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerData = player:WaitForChild("PlayerData")
local gemsValue = playerData:WaitForChild("Gems")
local ownedSkinsValue = playerData:WaitForChild("OwnedSkins")
local equippedSkinValue = playerData:WaitForChild("EquippedSkin")

local OWNED_COLOR = Color3.fromRGB(60, 60, 60)
local AFFORDABLE_COLOR = Color3.fromRGB(35, 120, 60)
local UNAFFORDABLE_COLOR = Color3.fromRGB(120, 60, 35)
local EQUIPPED_COLOR = Color3.fromRGB(60, 100, 140)
local GOLD_COLOR = Color3.fromRGB(200, 165, 60)

local RARITY_COLOR = {
	Common = Color3.fromRGB(190, 190, 190),
	Uncommon = Color3.fromRGB(110, 210, 120),
	Rare = Color3.fromRGB(90, 150, 240),
	Legendary = Color3.fromRGB(255, 195, 60),
}

local SKIN_BY_NAME = {}
for _, skin in Config.PickaxeSkins do
	SKIN_BY_NAME[skin.Name] = skin
end

local function getOwnedSkins()
	local owned = {}
	for name in ownedSkinsValue.Value:gmatch("[^,]+") do
		owned[name] = true
	end
	return owned
end

-- === GUI scaffold ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CaseUi"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(1, 0)
toggleButton.Position = UDim2.new(1, -16, 0, 224)
toggleButton.Size = UDim2.new(0, 100, 0, 44)
toggleButton.BackgroundColor3 = GOLD_COLOR
toggleButton.TextColor3 = Color3.fromRGB(20, 20, 20)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.Text = "Cases"
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 440, 0, 560)
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
closeButton.BackgroundColor3 = OWNED_COLOR
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
title.TextColor3 = GOLD_COLOR
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Pickaxe Cases"
title.Parent = panel

-- Reel viewport: a fixed-width clipped window with a center marker line.
-- Opening a case slides a long strip of skin items through it, landing the
-- actual result under the marker.
local REEL_ITEM_WIDTH = 92
local REEL_VISIBLE_WIDTH = 380
local REEL_ITEM_COUNT = 50
-- The result lands short of the strip's end, not exactly on it, so a few
-- more (decorative) items are still visible sliding past after it settles
-- -- otherwise the strip would just dead-stop right at the last item, which
-- doesn't read as a wheel that could keep going.
local REEL_TRAILING_ITEMS = 8
local REEL_LANDING_INDEX = REEL_ITEM_COUNT - REEL_TRAILING_ITEMS

local reelViewport = Instance.new("Frame")
reelViewport.Name = "ReelViewport"
reelViewport.Position = UDim2.new(0, 16, 0, 56)
reelViewport.Size = UDim2.new(0, REEL_VISIBLE_WIDTH, 0, 84)
reelViewport.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
reelViewport.ClipsDescendants = true
reelViewport.Parent = panel

local reelViewportCorner = Instance.new("UICorner")
reelViewportCorner.CornerRadius = UDim.new(0, 8)
reelViewportCorner.Parent = reelViewport

local marker = Instance.new("Frame")
marker.Name = "Marker"
marker.AnchorPoint = Vector2.new(0.5, 0)
marker.Position = UDim2.new(0.5, 0, 0, 0)
marker.Size = UDim2.new(0, 3, 1, 0)
marker.BackgroundColor3 = GOLD_COLOR
marker.ZIndex = 5
marker.Parent = reelViewport

local reelStrip = Instance.new("Frame")
reelStrip.Name = "ReelStrip"
reelStrip.Position = UDim2.new(0, 0, 0, 0)
reelStrip.Size = UDim2.new(0, REEL_ITEM_WIDTH * REEL_ITEM_COUNT, 1, 0)
reelStrip.BackgroundTransparency = 1
reelStrip.Parent = reelViewport

local reelListLayout = Instance.new("UIListLayout")
reelListLayout.FillDirection = Enum.FillDirection.Horizontal
reelListLayout.SortOrder = Enum.SortOrder.LayoutOrder
reelListLayout.Parent = reelStrip

local function addReelItem(skin, order)
	local item = Instance.new("Frame")
	item.Name = "Item"
	item.Size = UDim2.new(0, REEL_ITEM_WIDTH, 1, 0)
	item.BackgroundTransparency = 1
	item.LayoutOrder = order
	item.Parent = reelStrip

	local swatch = Instance.new("Frame")
	swatch.AnchorPoint = Vector2.new(0.5, 0)
	swatch.Position = UDim2.new(0.5, 0, 0, 10)
	swatch.Size = UDim2.new(0, 56, 0, 40)
	swatch.BackgroundColor3 = skin.Color
	swatch.Parent = item

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(0, 6)
	swatchCorner.Parent = swatch

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 54)
	label.Size = UDim2.new(0, 86, 0, 26)
	label.BackgroundTransparency = 1
	label.TextColor3 = RARITY_COLOR[skin.Rarity] or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextWrapped = true
	label.Text = skin.Name
	label.Parent = item
end

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Position = UDim2.new(0, 16, 0, 148)
resultLabel.Size = UDim2.new(1, -32, 0, 28)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextSize = 16
resultLabel.Text = ("Open a case for %d Gems -- weighted random skin"):format(Config.CaseCost)
resultLabel.Parent = panel

local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Position = UDim2.new(0, 16, 0, 182)
openButton.Size = UDim2.new(1, -32, 0, 44)
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 20
openButton.Text = ("Open Case -- %d Gems"):format(Config.CaseCost)
openButton.Parent = panel

local openButtonCorner = Instance.new("UICorner")
openButtonCorner.CornerRadius = UDim.new(0, 8)
openButtonCorner.Parent = openButton

local inventoryHeader = Instance.new("TextLabel")
inventoryHeader.Position = UDim2.new(0, 16, 0, 238)
inventoryHeader.Size = UDim2.new(1, -32, 0, 26)
inventoryHeader.BackgroundTransparency = 1
inventoryHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
inventoryHeader.Font = Enum.Font.GothamBold
inventoryHeader.TextSize = 18
inventoryHeader.TextXAlignment = Enum.TextXAlignment.Left
inventoryHeader.Text = "My Skins"
inventoryHeader.Parent = panel

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "Scroll"
scrollFrame.Position = UDim2.new(0, 16, 0, 268)
scrollFrame.Size = UDim2.new(1, -32, 1, -284)
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

local function addSkinRow(order)
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
	swatch.AnchorPoint = Vector2.new(0, 0.5)
	swatch.Position = UDim2.new(0, 8, 0.5, 0)
	swatch.Size = UDim2.new(0, 24, 0, 24)
	swatch.Parent = row

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(0, 6)
	swatchCorner.Parent = swatch

	local label = Instance.new("TextLabel")
	label.Position = UDim2.new(0, 44, 0, 0)
	label.Size = UDim2.new(1, -152, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local button = Instance.new("TextButton")
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

	return swatch, label, button
end

local skinRows = {}

-- Set while a case's reel is spinning so the "My Skins" refresh below
-- doesn't reveal the won skin the instant the server grants it (which
-- replicates well before the reel finishes) -- spoils the reveal otherwise.
local spinning = false

do
	local swatch, label, button = addSkinRow(0)
	swatch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	swatch.BackgroundTransparency = 0.7
	label.Text = "None (natural look)"
	button.MouseButton1Click:Connect(function()
		Remotes.EquipSkin:FireServer("")
	end)
	skinRows[""] = { label = label, button = button }
end

for order, skin in Config.PickaxeSkins do
	local swatch, label, button = addSkinRow(order)
	button.MouseButton1Click:Connect(function()
		Remotes.EquipSkin:FireServer(skin.Name)
	end)
	skinRows[skin.Name] = { label = label, swatch = swatch, button = button, skin = skin }
end

local function refreshInventory()
	local owned = getOwnedSkins()
	local equipped = equippedSkinValue.Value

	local noneEntry = skinRows[""]
	if equipped == "" then
		noneEntry.button.Text = "Equipped"
		noneEntry.button.Active = false
		noneEntry.button.BackgroundColor3 = EQUIPPED_COLOR
	else
		noneEntry.button.Text = "Equip"
		noneEntry.button.Active = true
		noneEntry.button.BackgroundColor3 = OWNED_COLOR
	end

	for _, skin in Config.PickaxeSkins do
		local entry = skinRows[skin.Name]
		if owned[skin.Name] then
			entry.swatch.BackgroundColor3 = skin.Color
			entry.swatch.BackgroundTransparency = 0
			entry.label.TextColor3 = Color3.fromRGB(255, 255, 255)
			entry.label.Text = ("%s (%s)"):format(skin.Name, skin.Rarity)
			if equipped == skin.Name then
				entry.button.Text = "Equipped"
				entry.button.Active = false
				entry.button.BackgroundColor3 = EQUIPPED_COLOR
			else
				entry.button.Text = "Equip"
				entry.button.Active = true
				entry.button.BackgroundColor3 = AFFORDABLE_COLOR
			end
		else
			entry.swatch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			entry.swatch.BackgroundTransparency = 0.4
			entry.label.TextColor3 = Color3.fromRGB(130, 130, 130)
			entry.label.Text = ("??? (%s)"):format(skin.Rarity)
			entry.button.Text = "Locked"
			entry.button.Active = false
			entry.button.BackgroundColor3 = OWNED_COLOR
		end
	end
end

local function refreshOpenButton()
	local gems = gemsValue.Value
	if gems >= Config.CaseCost then
		openButton.Active = true
		openButton.BackgroundColor3 = AFFORDABLE_COLOR
	else
		openButton.Active = false
		openButton.BackgroundColor3 = UNAFFORDABLE_COLOR
	end
end

ownedSkinsValue:GetPropertyChangedSignal("Value"):Connect(function()
	if not spinning then
		refreshInventory()
	end
end)
equippedSkinValue:GetPropertyChangedSignal("Value"):Connect(function()
	if not spinning then
		refreshInventory()
	end
end)
gemsValue:GetPropertyChangedSignal("Value"):Connect(refreshOpenButton)
refreshInventory()
refreshOpenButton()

-- === Case opening / reel spin ===

local function buildReel(resultSkinName)
	-- Not ClearAllChildren -- that would also destroy reelListLayout, which
	-- is parented under reelStrip too, leaving every future reel with no
	-- horizontal layout (items would all stack on top of each other at 0,0).
	for _, child in reelStrip:GetChildren() do
		if child.Name == "Item" then
			child:Destroy()
		end
	end
	reelStrip.Position = UDim2.new(0, 0, 0, 0)

	local resultSkin = SKIN_BY_NAME[resultSkinName]
	for order = 1, REEL_ITEM_COUNT do
		if order == REEL_LANDING_INDEX then
			addReelItem(resultSkin, order)
		else
			addReelItem(Config.PickaxeSkins[math.random(1, #Config.PickaxeSkins)], order)
		end
	end
end

local function spinToResult(resultSkinName, isNew, refund)
	buildReel(resultSkinName)

	-- Land the center of the landing item under the marker (viewport
	-- center) -- trailing items past it stay visible once it settles.
	local landedCenterX = REEL_ITEM_WIDTH * (REEL_LANDING_INDEX - 1) + REEL_ITEM_WIDTH / 2
	local targetX = -(landedCenterX - REEL_VISIBLE_WIDTH / 2)

	local tween = TweenService:Create(
		reelStrip,
		TweenInfo.new(7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, targetX, 0, 0) }
	)

	resultLabel.Text = "Spinning..."
	tween:Play()
	tween.Completed:Connect(function()
		local resultSkin = SKIN_BY_NAME[resultSkinName]
		if isNew then
			resultLabel.Text = ("New! %s (%s)"):format(resultSkin.Name, resultSkin.Rarity)
		else
			resultLabel.Text = ("Duplicate %s -- +%d Gems"):format(resultSkin.Name, refund)
		end
		spinning = false
		refreshInventory()
		refreshOpenButton()
	end)
end

openButton.MouseButton1Click:Connect(function()
	if spinning or gemsValue.Value < Config.CaseCost then
		return
	end
	spinning = true
	openButton.Active = false
	openButton.BackgroundColor3 = OWNED_COLOR
	Remotes.OpenCase:FireServer()
end)

Remotes.CaseResult.OnClientEvent:Connect(function(skinName, isNew, refund)
	spinToResult(skinName, isNew, refund)
end)

-- === Panel toggle ===

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
	if input.KeyCode == Enum.KeyCode.C then
		setOpen(not panel.Visible)
	end
end)
