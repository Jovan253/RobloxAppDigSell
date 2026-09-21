-- Minimal always-on Cash readout. Shop/Rebirth menus are the next milestone
-- and are best built visually in Studio's UI editor rather than by hand here.
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Position = UDim2.new(0, 16, 0, 16)
cashLabel.Size = UDim2.new(0, 220, 0, 44)
cashLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
cashLabel.BackgroundTransparency = 0.25
cashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextSize = 22
cashLabel.Text = "Cash: 0"
cashLabel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = cashLabel

local function formatCash(amount)
	return ("Cash: %d"):format(amount)
end

local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")

cashLabel.Text = formatCash(cashValue.Value)
cashValue:GetPropertyChangedSignal("Value"):Connect(function()
	cashLabel.Text = formatCash(cashValue.Value)
end)
