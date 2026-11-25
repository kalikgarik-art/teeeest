--!strict
-- Player lifecycle service.
--
-- Responsibilities:
--   * create leaderstats with Stage = 1 for every joining player,
--   * keep Player.RespawnLocation pointing at the player's current
--     checkpoint pad (start pad until the first checkpoint is touched),
--   * teleport the player back to their current checkpoint when they
--     fall below Config.FALL_Y (deaths respawn automatically through
--     RespawnLocation, because checkpoint pads are SpawnLocations),
--   * handle "restart" requests from the client: Stage back to 1 and
--     teleport to the start pad.
--
-- Stage numbering: the start pad and checkpoint 1 both show Stage 1
-- in the leaderboard (Stage is capped to 1..Config.STAGE_COUNT, so
-- checkpoint i shows Stage i). The exact position is tracked
-- separately as a checkpoint index: 0 = start pad, 1..STAGE_COUNT =
-- checkpoint pads. That is what respawning uses, so touching
-- checkpoint 1 still moves the respawn point even though the
-- displayed Stage stays at 1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ObbyShared")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
type LevelData = Types.LevelData

local FALL_CHECK_INTERVAL = 0.1

local levelData: LevelData? = nil
local checkpointIndexByPlayer: { [Player]: number } = {}
local fallDebounceByPlayer: { [Player]: boolean } = {}

local PlayerService = {}

function PlayerService.GetStage(player: Player): number
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats ~= nil then
		local stage = leaderstats:FindFirstChild("Stage")
		if stage ~= nil and stage:IsA("IntValue") then
			return stage.Value
		end
	end
	return 1
end

function PlayerService.SetStage(player: Player, stageValue: number): ()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats ~= nil then
		local stage = leaderstats:FindFirstChild("Stage")
		if stage ~= nil and stage:IsA("IntValue") then
			stage.Value = stageValue
		end
	end
end

function PlayerService.GetCheckpointIndex(player: Player): number
	return checkpointIndexByPlayer[player] or 0
end

function PlayerService.SetCheckpointIndex(player: Player, index: number): ()
	checkpointIndexByPlayer[player] = index
end

function PlayerService.TeleportToCheckpoint(player: Player, index: number): ()
	if levelData == nil then
		return
	end

	local character = player.Character
	if character == nil then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart == nil then
		return
	end

	local targetCFrame: CFrame
	if index <= 0 then
		targetCFrame = levelData.StartCFrame
	else
		local checkpoint = levelData.Checkpoints[index]
		if checkpoint ~= nil then
			targetCFrame = checkpoint.CFrame
		else
			targetCFrame = levelData.StartCFrame
		end
	end

	local spawnCFrame = targetCFrame * CFrame.new(0, Config.RESPAWN_OFFSET_Y, 0)
	character:PivotTo(spawnCFrame)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

function PlayerService.HandleRestart(player: Player): ()
	PlayerService.SetCheckpointIndex(player, 0)
	PlayerService.SetStage(player, 1)
	if levelData ~= nil then
		player.RespawnLocation = levelData.StartPad
	end
	PlayerService.TeleportToCheckpoint(player, 0)
end

local function onPlayerAdded(player: Player): ()
	checkpointIndexByPlayer[player] = 0

	local leaderstats = Instance.new("Folder") :: Folder
	leaderstats.Name = "leaderstats"

	local stage = Instance.new("IntValue") :: IntValue
	stage.Name = "Stage"
	stage.Value = 1
	stage.Parent = leaderstats

	leaderstats.Parent = player

	if levelData ~= nil then
		player.RespawnLocation = levelData.StartPad
	end
end

local function onPlayerRemoving(player: Player): ()
	checkpointIndexByPlayer[player] = nil
	fallDebounceByPlayer[player] = nil
end

local function startFallCheckLoop(): ()
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local character = player.Character
				if character ~= nil then
					local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if rootPart ~= nil and rootPart.Position.Y < Config.FALL_Y then
						if not fallDebounceByPlayer[player] then
							fallDebounceByPlayer[player] = true
							local capturedPlayer = player
							PlayerService.TeleportToCheckpoint(
								capturedPlayer,
								PlayerService.GetCheckpointIndex(capturedPlayer)
							)
							task.delay(0.5, function()
								fallDebounceByPlayer[capturedPlayer] = false
							end)
						end
					end
				end
			end
			task.wait(FALL_CHECK_INTERVAL)
		end
	end)
end

function PlayerService.Init(data: LevelData): ()
	levelData = data

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Players who joined before Init ran (not possible in a normal
	-- server start, but keeps the service correct in Studio tests).
	for _, player in Players:GetPlayers() do
		if player:FindFirstChild("leaderstats") == nil then
			onPlayerAdded(player)
		end
	end

	startFallCheckLoop()
end

return PlayerService
