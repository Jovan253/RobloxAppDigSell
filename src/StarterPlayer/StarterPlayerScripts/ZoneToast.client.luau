-- Brief on-screen message for zone events (currently just Dark Mines lava
-- falls -- see MiningService's setupLavaKillZone).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZoneToast"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 80)
toast.Size = UDim2.new(0, 360, 0, 40)
toast.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
toast.BackgroundTransparency = 0.1
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 16
toast.Text = ""
toast.Visible = false
toast.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toast

local hideTask = nil

Remotes.ZoneNotice.OnClientEvent:Connect(function(message)
	toast.Text = message
	toast.Visible = true

	if hideTask then
		task.cancel(hideTask)
	end
	hideTask = task.delay(2.5, function()
		toast.Visible = false
	end)
end)
