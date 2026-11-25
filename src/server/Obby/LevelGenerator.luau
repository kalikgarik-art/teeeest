--!strict
-- Procedural level generator.
--
-- Builds the whole course at server startup with Instance.new only:
-- no external models and no paid assets. The result is:
--   * a start pad (SpawnLocation),
--   * Config.STAGE_COUNT checkpoint pads (SpawnLocations, so Roblox
--     respawns the player there automatically after a death),
--   * a finish pad (Part),
--   * one red killbrick below every gap between two pads,
--   * a large baseplate far below the course.
--
-- Checkpoint pads are SpawnLocations on purpose: CheckpointService
-- assigns the touched pad to Player.RespawnLocation, and then both
-- a killbrick death and any other death respawn the player exactly
-- on their current checkpoint.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("ObbyShared")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
type LevelData = Types.LevelData
type CheckpointData = Types.CheckpointData

local FOLDER_NAME = "ObbyLevel"

local function addLabel(pad: BasePart, text: string): ()
	local surfaceGui = Instance.new("SurfaceGui") :: SurfaceGui
	surfaceGui.Name = "Label"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.LightInfluence = 0
	surfaceGui.Parent = pad

	local label = Instance.new("TextLabel") :: TextLabel
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Parent = surfaceGui
end

local function createSpawnPad(
	folder: Folder,
	name: string,
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	labelText: string
): SpawnLocation
	local pad = Instance.new("SpawnLocation") :: SpawnLocation
	pad.Name = name
	pad.CFrame = cframe
	pad.Size = size
	pad.Color = color
	pad.Material = Enum.Material.SmoothPlastic
	pad.Anchored = true
	pad.CanCollide = true
	pad.Neutral = true
	pad.AllowTeamChangeOnTouch = false
	pad.Enabled = true
	pad.Duration = 0
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.Parent = folder

	addLabel(pad, labelText)
	return pad
end

local function createPart(
	folder: Folder,
	name: string,
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part") :: Part
	part.Name = name
	part.CFrame = cframe
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function checkpointPosition(stage: number): Vector3
	return Vector3.new(
		stage * Config.CHECKPOINT_SPACING_X,
		Config.START_POSITION.Y + stage * Config.CHECKPOINT_RISE_Y,
		math.sin(stage * 0.7) * Config.CHECKPOINT_CURVE_AMPLITUDE
	)
end

local function finishPosition(): Vector3
	return checkpointPosition(Config.STAGE_COUNT + 1)
end

local LevelGenerator = {}

function LevelGenerator.Generate(): LevelData
	-- Reuse the folder if the server script is re-run (e.g. in Studio
	-- with "Run" instead of "Play"), otherwise create it.
	local existingFolder = Workspace:FindFirstChild(FOLDER_NAME)
	local folder: Folder
	if existingFolder ~= nil and existingFolder:IsA("Folder") then
		folder = existingFolder
	else
		folder = Instance.new("Folder") :: Folder
		folder.Name = FOLDER_NAME
		folder.Parent = Workspace
	end
	for _, child in folder:GetChildren() do
		child:Destroy()
	end

	local rng = Random.new(Config.SEED)

	-- Baseplate far below the course. The fall check (Config.FALL_Y)
	-- teleports the player long before they could land on it.
	local baseplate = createPart(
		folder,
		"Baseplate",
		CFrame.new(0, -60, 0),
		Vector3.new(400, 1, 400),
		Color3.fromRGB(50, 50, 50),
		Enum.Material.SmoothPlastic
	)
	baseplate.CanCollide = true

	-- Start pad. Players spawn here because PlayerService assigns it
	-- to Player.RespawnLocation on join.
	local startPad = createSpawnPad(
		folder,
		"StartPad",
		CFrame.new(Config.START_POSITION),
		Config.START_SIZE,
		Config.START_COLOR,
		"START"
	)

	-- Checkpoint pads, stages 1..STAGE_COUNT.
	local checkpoints: { CheckpointData } = {}
	for stage = 1, Config.STAGE_COUNT do
		local side = rng:NextNumber(Config.CHECKPOINT_MIN_SIZE, Config.CHECKPOINT_MAX_SIZE)
		local size = Vector3.new(side, Config.CHECKPOINT_HEIGHT, side)
		local color = Config.PALETTE[stage]
		local pad = createSpawnPad(
			folder,
			string.format("Checkpoint_%02d", stage),
			CFrame.new(checkpointPosition(stage)),
			size,
			color,
			tostring(stage)
		)
		table.insert(checkpoints, {
			Stage = stage,
			Pad = pad,
			CFrame = pad.CFrame,
		})
	end

	-- Finish pad. It is a plain Part, not a SpawnLocation, so touching
	-- it never becomes a respawn point.
	local finishPad = createPart(
		folder,
		"FinishPad",
		CFrame.new(finishPosition()),
		Config.FINISH_SIZE,
		Config.FINISH_COLOR,
		Enum.Material.SmoothPlastic
	)
	addLabel(finishPad, "FINISH")

	-- One killbrick below every gap: start -> 1 -> 2 -> ... -> finish.
	local padPositions: { Vector3 } = { Config.START_POSITION }
	for _, checkpoint in checkpoints do
		table.insert(padPositions, checkpoint.CFrame.Position)
	end
	table.insert(padPositions, finishPosition())

	local killbricks: { Part } = {}
	for index = 1, #padPositions - 1 do
		local from = padPositions[index]
		local to = padPositions[index + 1]
		local midpoint = (from + to) / 2
		local killbrickCFrame = CFrame.new(
			midpoint.X,
			math.min(from.Y, to.Y) - Config.KILLBRICK_DROP_Y,
			midpoint.Z
		)
		local killbrick = createPart(
			folder,
			string.format("Killbrick_%02d", index),
			killbrickCFrame,
			Config.KILLBRICK_SIZE,
			Config.KILLBRICK_COLOR,
			Enum.Material.Neon
		)
		table.insert(killbricks, killbrick)
	end

	return {
		Folder = folder,
		StartPad = startPad,
		StartCFrame = startPad.CFrame,
		Checkpoints = checkpoints,
		FinishPad = finishPad,
		FinishCFrame = finishPad.CFrame,
		Killbricks = killbricks,
	}
end

return LevelGenerator
