-- Leaderboard panel: reads ReplicatedStorage.LeaderboardData (a JSON list of
-- {Name, Cash} published periodically by LeaderboardService) and displays
-- it. Toggle with the corner button or the "L" key.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local entriesValue = require(ReplicatedStorage:WaitForChild("LeaderboardData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LeaderboardUi"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(1, 0)
toggleButton.Position = UDim2.new(1, -16, 0, 68)
toggleButton.Size = UDim2.new(0, 100, 0, 44)
toggleButton.BackgroundColor3 = Color3.fromRGB(90, 90, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.Text = "Ranks"
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 120)
panel.Size = UDim2.new(0, 260, 0, 360)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.new(0, 12, 0, 8)
title.Size = UDim2.new(1, -24, 0, 28)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Top Miners"
title.Parent = panel

local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "List"
listFrame.Position = UDim2.new(0, 12, 0, 44)
listFrame.Size = UDim2.new(1, -24, 1, -56)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.ScrollBarThickness = 6
listFrame.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

local rowPool = {}

local function getRow(index)
	local row = rowPool[index]
	if row then
		return row
	end

	row = Instance.new("TextLabel")
	row.Name = "Row" .. index
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundTransparency = 1
	row.TextColor3 = Color3.fromRGB(230, 230, 230)
	row.Font = Enum.Font.Gotham
	row.TextSize = 15
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.LayoutOrder = index
	row.Parent = listFrame

	rowPool[index] = row
	return row
end

local function refresh()
	local ok, entries = pcall(HttpService.JSONDecode, HttpService, entriesValue.Value)
	if not ok or typeof(entries) ~= "table" then
		entries = {}
	end

	if #entries == 0 then
		local row = getRow(1)
		row.Text = "No scores yet -- go mine!"
		row.Visible = true
		for index = 2, #rowPool do
			rowPool[index].Visible = false
		end
		return
	end

	for index, entry in entries do
		local row = getRow(index)
		row.Text = ("%d. %s -- %d"):format(index, entry.Name, entry.Cash)
		row.Visible = true
	end

	for index = #entries + 1, #rowPool do
		rowPool[index].Visible = false
	end
end

entriesValue:GetPropertyChangedSignal("Value"):Connect(refresh)
refresh()

local function setOpen(open)
	panel.Visible = open
end

toggleButton.MouseButton1Click:Connect(function()
	setOpen(not panel.Visible)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.L then
		setOpen(not panel.Visible)
	end
end)
