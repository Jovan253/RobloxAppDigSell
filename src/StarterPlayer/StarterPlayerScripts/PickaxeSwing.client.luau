-- Swing for the player's equipped pickaxe (a Tool tagged IsPickaxe, given
-- by PickaxeToolService). Tweens the Tool's Grip briefly on Activated
-- rather than using an uploaded Animation asset, and fires Remotes.MineHit
-- so the server applies a hit to the nearest ore in range -- mining no
-- longer goes through a ClickDetector at all (see MiningService for why:
-- ClickDetector hover/clicks don't fire while any Tool is equipped).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local function hookTool(tool)
	if not tool:IsA("Tool") or not tool:GetAttribute("IsPickaxe") then
		return
	end

	local baseGrip = tool.Grip
	local swinging = false

	tool.Activated:Connect(function()
		if swinging then
			return
		end
		swinging = true

		Remotes.MineHit:FireServer()

		-- Flipped from the previous version, which swung downward -- this
		-- direction/magnitude is still a guess (can't preview it), tell me
		-- which way it should actually go if this isn't it.
		local swingOut = TweenService:Create(tool, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			Grip = baseGrip * CFrame.Angles(math.rad(40), 0, 0),
		})
		swingOut:Play()
		swingOut.Completed:Connect(function()
			local swingBack = TweenService:Create(tool, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Grip = baseGrip })
			swingBack:Play()
			swingBack.Completed:Connect(function()
				swinging = false
			end)
		end)
	end)
end

local function hookContainer(container)
	for _, child in container:GetChildren() do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

hookContainer(player:WaitForChild("Backpack"))

player.CharacterAdded:Connect(hookContainer)
if player.Character then
	hookContainer(player.Character)
end
