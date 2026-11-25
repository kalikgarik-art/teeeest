--!strict
-- Obby server entry point (ServerScriptService/ObbyServer).
--
-- Startup order:
--   1. resolve the shared RemoteEvents,
--   2. procedurally generate the level,
--   3. initialise the gameplay services with the generated level,
--   4. wire the "restart" RemoteEvent to PlayerService.
--
-- All geometry is created at runtime by LevelGenerator, so the
-- place file itself contains no level instances.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ObbyShared")
local RemotesModule = require(Shared:WaitForChild("Remotes"))

local ObbyFolder = script:WaitForChild("Obby")
local LevelGenerator = require(ObbyFolder:WaitForChild("LevelGenerator"))
local PlayerService = require(ObbyFolder:WaitForChild("PlayerService"))
local CheckpointService = require(ObbyFolder:WaitForChild("CheckpointService"))
local KillbrickService = require(ObbyFolder:WaitForChild("KillbrickService"))

local remotes = RemotesModule.Get()

local levelData = LevelGenerator.Generate()

PlayerService.Init(levelData)
CheckpointService.Init(levelData, remotes)
KillbrickService.Init(levelData)

remotes.RestartRequested.OnServerEvent:Connect(function(player: Player)
	PlayerService.HandleRestart(player)
end)

print(string.format("[Obby] Server started: %d checkpoints, %d killbricks", #levelData.Checkpoints, #levelData.Killbricks))
