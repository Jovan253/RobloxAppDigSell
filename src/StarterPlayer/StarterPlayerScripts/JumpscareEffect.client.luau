-- Plays when this client is the target of a Dark Mines "Jumpscare Prank"
-- purchase (see MarketplaceService.triggerJumpscarePrank). SoundId is left
-- blank -- swap it for a real jumpscare sound's asset ID once you have one
-- uploaded (needs to be an ID you own or a public rbxassetid://).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
flash.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
flash.BackgroundTransparency = 1
flash.Visible = false
flash.Parent = screenGui

local sound = Instance.new("Sound")
sound.Name = "JumpscareSound"
sound.SoundId = "" -- TODO: set to a real jumpscare sound asset ID
sound.Volume = 1
sound.Parent = screenGui

Remotes.JumpscareEffect.OnClientEvent:Connect(function()
	flash.BackgroundTransparency = 0
	flash.Visible = true
	if sound.SoundId ~= "" then
		sound:Play()
	end

	local fadeOut = TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		flash.Visible = false
	end)
end)
