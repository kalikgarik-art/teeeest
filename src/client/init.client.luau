--!strict
-- Obby client entry point (StarterPlayer/StarterPlayerScripts/ObbyClient).
--
-- Waits for the replicated leaderstats and RemoteEvents, then
-- initialises the two client modules:
--   * StageHud  — shows the current stage,
--   * FinishGui — shows the congratulation panel on finish.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ObbyShared")
local Config = require(Shared:WaitForChild("Config"))
local RemotesModule = require(Shared:WaitForChild("Remotes"))

local FinishGui = require(script:WaitForChild("FinishGui"))
local StageHud = require(script:WaitForChild("StageHud"))

local player = Players.LocalPlayer :: Player
local leaderstats = player:WaitForChild("leaderstats")
local stageValue = leaderstats:WaitForChild("Stage") :: IntValue

local remotes = RemotesModule.Get()

StageHud.Init(stageValue, Config.STAGE_COUNT)
FinishGui.Init(remotes, stageValue, Config.STAGE_COUNT)

print("[Obby] Client started")
