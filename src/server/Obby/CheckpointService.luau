--!strict
-- Checkpoint and finish detection.
--
-- A checkpoint only counts when it is the *next* one in sequence
-- (current checkpoint index + 1). Touching a checkpoint out of order
-- or one the player already passed does nothing. On a valid touch:
--   * the player's checkpoint index advances,
--   * leaderstats Stage is set to the checkpoint number,
--   * Player.RespawnLocation is set to the checkpoint pad, so the
--     next death respawns exactly there.
--
-- The finish pad only counts once the player has reached the last
-- checkpoint (index == Config.STAGE_COUNT). It then notifies the
-- client through the PlayerFinished RemoteEvent, and the client
-- shows the congratulation GUI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ObbyShared")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
type CheckpointData = Types.CheckpointData
type LevelData = Types.LevelData
type Remotes = Types.Remotes

local ObbyFolder = script.Parent :: Folder
local PlayerService = require(ObbyFolder:WaitForChild("PlayerService"))

local FINISH_DEBOUNCE_SECONDS = 2

local finishDebounceByPlayer: { [Player]: boolean } = {}

local CheckpointService = {}

local function getPlayerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if character == nil then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function onCheckpointTouched(checkpoint: CheckpointData, hit: BasePart): ()
	local player = getPlayerFromHit(hit)
	if player == nil then
		return
	end

	local currentIndex = PlayerService.GetCheckpointIndex(player)
	if checkpoint.Stage ~= currentIndex + 1 then
		return
	end

	PlayerService.SetCheckpointIndex(player, checkpoint.Stage)
	PlayerService.SetStage(player, checkpoint.Stage)
	player.RespawnLocation = checkpoint.Pad
end

local function onFinishTouched(remotes: Remotes, hit: BasePart): ()
	local player = getPlayerFromHit(hit)
	if player == nil then
		return
	end

	if PlayerService.GetCheckpointIndex(player) ~= Config.STAGE_COUNT then
		return
	end

	if finishDebounceByPlayer[player] then
		return
	end
	finishDebounceByPlayer[player] = true

	remotes.PlayerFinished:FireClient(player)

	task.delay(FINISH_DEBOUNCE_SECONDS, function()
		finishDebounceByPlayer[player] = false
	end)
end

function CheckpointService.Init(data: LevelData, remotes: Remotes): ()
	for _, checkpoint in data.Checkpoints do
		local capturedCheckpoint = checkpoint
		checkpoint.Pad.Touched:Connect(function(hit: BasePart)
			onCheckpointTouched(capturedCheckpoint, hit)
		end)
	end

	data.FinishPad.Touched:Connect(function(hit: BasePart)
		onFinishTouched(remotes, hit)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		finishDebounceByPlayer[player] = nil
	end)
end

return CheckpointService
