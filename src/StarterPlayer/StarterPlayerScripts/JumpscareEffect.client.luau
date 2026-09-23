-- Plays when this client is the target of a Dark Mines "Jumpscare Prank"
-- purchase (see MarketplaceService.triggerJumpscarePrank).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JumpscareEffect"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000
screenGui.Parent = playerGui

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.new(1, 0, 1, 0)
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1
flash.Visible = false
flash.Parent = screenGui

local sound = Instance.new("Sound")
sound.Name = "JumpscareSound"
sound.SoundId = "rbxassetid://139162107746216"
sound.Volume = 1
sound.Parent = screenGui

-- Preload so sound.TimeLength is actually populated by the time the effect
-- fires -- it reads as 0 until the asset has loaded at least once.
task.spawn(function()
	ContentProvider:PreloadAsync({ sound })
end)

local FALLBACK_DURATION = 1.5 -- used only if TimeLength isn't available yet
local activeFade = nil

Remotes.JumpscareEffect.OnClientEvent:Connect(function()
	if activeFade then
		activeFade:Cancel()
	end

	flash.BackgroundTransparency = 0
	flash.Visible = true
	sound:Play()

	local duration = sound.TimeLength > 0 and sound.TimeLength or FALLBACK_DURATION

	activeFade = TweenService:Create(flash, TweenInfo.new(duration, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
	activeFade:Play()
	activeFade.Completed:Connect(function()
		flash.Visible = false
	end)
end)
