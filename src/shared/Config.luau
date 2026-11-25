--!strict
-- Shared configuration for the Obby game.
-- All gameplay constants live here so the server and the client
-- stay in sync. This module is replicated via ReplicatedStorage/ObbyShared.

export type Config = {
	STAGE_COUNT: number,
	FALL_Y: number,
	SEED: number,
	START_POSITION: Vector3,
	START_SIZE: Vector3,
	START_COLOR: Color3,
	CHECKPOINT_SPACING_X: number,
	CHECKPOINT_RISE_Y: number,
	CHECKPOINT_CURVE_AMPLITUDE: number,
	CHECKPOINT_MIN_SIZE: number,
	CHECKPOINT_MAX_SIZE: number,
	CHECKPOINT_HEIGHT: number,
	FINISH_SIZE: Vector3,
	FINISH_COLOR: Color3,
	KILLBRICK_SIZE: Vector3,
	KILLBRICK_COLOR: Color3,
	KILLBRICK_DROP_Y: number,
	RESPAWN_OFFSET_Y: number,
	PALETTE: { Color3 },
}

local Config: Config = {
	-- Number of checkpoint platforms. Stages are numbered 1..STAGE_COUNT.
	STAGE_COUNT = 10,

	-- Falling below this Y coordinate teleports the player back
	-- to their current checkpoint.
	FALL_Y = -50,

	-- Fixed seed for the procedural level generator, so every server
	-- start produces exactly the same level.
	SEED = 20241125,

	-- Center of the start pad.
	START_POSITION = Vector3.new(0, 3, 0),
	START_SIZE = Vector3.new(14, 1, 14),
	START_COLOR = Color3.fromRGB(163, 162, 165),

	-- Checkpoint layout: platforms advance along +X, rise gradually
	-- and follow a gentle sine curve in Z so the course is not a
	-- perfectly straight line. Gaps stay jumpable with default
	-- WalkSpeed (16) and JumpPower (50).
	CHECKPOINT_SPACING_X = 15,
	CHECKPOINT_RISE_Y = 1.2,
	CHECKPOINT_CURVE_AMPLITUDE = 6,
	CHECKPOINT_MIN_SIZE = 5.5,
	CHECKPOINT_MAX_SIZE = 8,
	CHECKPOINT_HEIGHT = 1,

	FINISH_SIZE = Vector3.new(12, 1, 12),
	FINISH_COLOR = Color3.fromRGB(255, 215, 0),

	-- Killbricks sit below the jump path between two pads, so they
	-- punish a fall without blocking a clean jump.
	KILLBRICK_SIZE = Vector3.new(4, 1, 4),
	KILLBRICK_COLOR = Color3.fromRGB(255, 0, 0),
	KILLBRICK_DROP_Y = 5,

	-- How far above a pad center the character is placed on respawn.
	-- Pad height is 1 (top at +0.5), the character needs roughly
	-- 3 studs of clearance above the top surface.
	RESPAWN_OFFSET_Y = 4,

	-- One distinct bright color per checkpoint, in stage order.
	PALETTE = {
		Color3.fromRGB(255, 85, 85), -- 1  Bright red
		Color3.fromRGB(255, 170, 0), -- 2  Bright orange
		Color3.fromRGB(255, 255, 85), -- 3  Bright yellow
		Color3.fromRGB(85, 255, 85), -- 4  Bright green
		Color3.fromRGB(85, 255, 255), -- 5  Bright cyan
		Color3.fromRGB(85, 170, 255), -- 6  Bright blue
		Color3.fromRGB(170, 85, 255), -- 7  Bright violet
		Color3.fromRGB(255, 85, 255), -- 8  Bright magenta
		Color3.fromRGB(255, 85, 170), -- 9  Bright reddish violet
		Color3.fromRGB(85, 255, 170), -- 10 Bright bluish green
	},
}

return Config
