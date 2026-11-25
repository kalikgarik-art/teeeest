--!strict
-- Minimal stage HUD: a small label at the top of the screen that
-- always shows the current leaderstats Stage ("Этап: X / 10").
-- Built in code and parented to PlayerGui, like FinishGui.

local Players = game:GetService("Players")

local StageHud = {}

function StageHud.Init(stageValue: IntValue, stageCount: number): ()
	local player = Players.LocalPlayer :: Player
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local screenGui = Instance.new("ScreenGui") :: ScreenGui
	screenGui.Name = "StageHud"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 1
	screenGui.Parent = playerGui

	local label = Instance.new("TextLabel") :: TextLabel
	label.Name = "StageLabel"
	label.Size = UDim2.new(0, 220, 0, 36)
	label.Position = UDim2.new(0.5, 0, 0, 12)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Parent = screenGui

	local corner = Instance.new("UICorner") :: UICorner
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local function refresh(_newValue: number?): ()
		label.Text = string.format("Этап: %d / %d", stageValue.Value, stageCount)
	end

	refresh()
	stageValue.Changed:Connect(function(newValue: number)
		refresh(newValue)
	end)
end

return StageHud
