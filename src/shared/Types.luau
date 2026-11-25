--!strict
-- Shared type definitions for the Obby game.
-- This module intentionally has no runtime values: it exists only
-- so other modules can share Luau types under `--!strict`.

export type CheckpointData = {
	-- Stage number of this checkpoint, 1..Config.STAGE_COUNT.
	Stage: number,
	-- The SpawnLocation pad itself. It is also used as the player's
	-- RespawnLocation once the checkpoint is reached.
	Pad: SpawnLocation,
	-- CFrame of the pad center at generation time.
	CFrame: CFrame,
}

export type LevelData = {
	Folder: Folder,
	StartPad: SpawnLocation,
	StartCFrame: CFrame,
	Checkpoints: { CheckpointData },
	FinishPad: Part,
	FinishCFrame: CFrame,
	Killbricks: { Part },
}

export type Remotes = {
	PlayerFinished: RemoteEvent,
	RestartRequested: RemoteEvent,
}

return {}
