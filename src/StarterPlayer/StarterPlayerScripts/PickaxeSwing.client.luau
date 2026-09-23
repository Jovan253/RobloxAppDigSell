-- Cosmetic swing for the player's equipped pickaxe (a Tool tagged
-- IsPickaxe, given by PickaxeToolService). Tweens the Tool's Grip briefly
-- on Activated (fires on click while equipped) rather than using an
-- uploaded Animation asset. Purely visual -- actual mining validation and
-- reward stay server-side via each ore's ClickDetector, unaffected by this.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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

		local swingOut = TweenService:Create(tool, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			Grip = baseGrip * CFrame.Angles(math.rad(-60), 0, 0),
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
