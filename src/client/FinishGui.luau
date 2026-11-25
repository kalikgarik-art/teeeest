--!strict
-- Finish congratulation GUI.
--
-- The ScreenGui is built entirely in code and parented to PlayerGui
-- (the per-player copy of StarterGui), so no GUI instances have to
-- be stored in the place file. It starts hidden, is shown when the
-- server fires the PlayerFinished RemoteEvent, and its
-- "Начать заново" button asks the server to restart the player
-- through the RestartRequested RemoteEvent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage:WaitForChild("ObbyShared"):WaitForChild("Types"))
type Remotes = Types.Remotes

local FinishGui = {}

function FinishGui.Init(remotes: Remotes, stageValue: IntValue, stageCount: number): ()
	local player = Players.LocalPlayer :: Player
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local screenGui = Instance.new("ScreenGui") :: ScreenGui
	screenGui.Name = "FinishGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame") :: Frame
	frame.Name = "Panel"
	frame.Size = UDim2.new(0, 400, 0, 220)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local frameCorner = Instance.new("UICorner") :: UICorner
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = frame

	local frameStroke = Instance.new("UIStroke") :: UIStroke
	frameStroke.Color = Color3.fromRGB(255, 215, 0)
	frameStroke.Thickness = 2
	frameStroke.Parent = frame

	local title = Instance.new("TextLabel") :: TextLabel
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "Поздравляем!"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 28
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.Parent = frame

	local message = Instance.new("TextLabel") :: TextLabel
	message.Name = "Message"
	message.Size = UDim2.new(1, -20, 0, 80)
	message.Position = UDim2.new(0, 10, 0, 60)
	message.BackgroundTransparency = 1
	message.Text = string.format("Вы прошли все %d этапов!\nОтличная работа!", stageCount)
	message.Font = Enum.Font.Gotham
	message.TextSize = 18
	message.TextColor3 = Color3.fromRGB(255, 255, 255)
	message.TextWrapped = true
	message.Parent = frame

	local button = Instance.new("TextButton") :: TextButton
	button.Name = "RestartButton"
	button.Size = UDim2.new(1, -20, 0, 44)
	button.Position = UDim2.new(0, 10, 0, 156)
	button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	button.Text = "Начать заново"
	button.Font = Enum.Font.GothamBold
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = true
	button.Parent = frame

	local buttonCorner = Instance.new("UICorner") :: UICorner
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local function show(): ()
		screenGui.Enabled = true
	end

	local function hide(): ()
		screenGui.Enabled = false
	end

	remotes.PlayerFinished.OnClientEvent:Connect(show)

	button.Activated:Connect(function()
		remotes.RestartRequested:FireServer()
		hide()
	end)

	-- If the server resets the stage (restart), make sure the
	-- congratulation panel does not stay on screen.
	stageValue.Changed:Connect(function(newValue: number)
		if newValue < stageCount then
			hide()
		end
	end)
end

return FinishGui
