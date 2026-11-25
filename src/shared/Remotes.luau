--!strict
-- Accessors for the RemoteEvents of the Obby game.
--
-- The events are declared declaratively in default.project.json
-- under ReplicatedStorage/ObbyRemotes:
--   * PlayerFinished    (server -> client) the player touched the finish pad
--   * RestartRequested  (client -> server) the player pressed "Начать заново"
--
-- If the place was not synced through Rojo, the server creates the
-- folder and the events on demand, so the game still works standalone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedFolder = script.Parent :: Folder
local Types = require(sharedFolder:WaitForChild("Types"))
type RemotesData = Types.Remotes

local FOLDER_NAME = "ObbyRemotes"
local PLAYER_FINISHED_NAME = "PlayerFinished"
local RESTART_REQUESTED_NAME = "RestartRequested"

local function getOrCreateFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing ~= nil and existing:IsA("Folder") then
		return existing
	end

	if RunService:IsServer() then
		local folder = Instance.new("Folder") :: Folder
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end

	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function getOrCreateEvent(folder: Folder, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing ~= nil and existing:IsA("RemoteEvent") then
		return existing
	end

	if RunService:IsServer() then
		local event = Instance.new("RemoteEvent") :: RemoteEvent
		event.Name = name
		event.Parent = folder
		return event
	end

	return folder:WaitForChild(name) :: RemoteEvent
end

local Remotes = {}

function Remotes.Get(): RemotesData
	local folder = getOrCreateFolder()
	return {
		PlayerFinished = getOrCreateEvent(folder, PLAYER_FINISHED_NAME),
		RestartRequested = getOrCreateEvent(folder, RESTART_REQUESTED_NAME),
	}
end

function Remotes.GetPlayerFinished(): RemoteEvent
	return Remotes.Get().PlayerFinished
end

function Remotes.GetRestartRequested(): RemoteEvent
	return Remotes.Get().RestartRequested
end

return Remotes
