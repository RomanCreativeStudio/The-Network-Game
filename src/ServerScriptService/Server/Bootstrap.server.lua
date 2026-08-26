--[[
	Bootstrap.server.lua - server entry point.

	Wires the persistence skeleton (DataStoreWrapper, OrganizationService,
	PlayerDataService - Phase 0) and the task pipeline (TaskService -
	Phase 1) to live Roblox services: Players.PlayerAdded/PlayerRemoving,
	the Shared/Remotes RemoteEvents, a periodic autosave loop, and
	game:BindToClose.

	This is deliberately the ONLY file that touches game:GetService(...) /
	Players / DataStoreService / RemoteEvents directly - every other
	module is dependency-injected and Roblox-independent so it can be
	unit/integration tested outside Roblox (see tests/ and
	docs/technical-architecture-v0.1.md §18-§19). Keep this file thin;
	real logic belongs in the modules it wires together, not here.

	Phase 1 scope only. Deliberately does NOT implement: real proposal
	mechanics, multiple task types, complex decisions, Influence spending,
	Promotion, hiring/firing, Departments, Branches, Contracts, Founder
	system, M&A, Courts, Governance, or Monetization. See
	docs/mvp-definition-v0.1.md and docs/technical-architecture-v0.1.md.

	SECURITY: every RemoteEvent handler below uses ONLY the `player`
	argument Roblox itself supplies (the true, engine-verified sender of
	the event) for `player.UserId` - never a client-sent field - and
	treats every other argument as untrusted, opaque, type-checked input.
	See TaskService.lua's module-level SECURITY MODEL comment for the
	full invariant this depends on.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerDataSchema = require(Shared.Types.PlayerData)
local OrganizationDataSchema = require(Shared.Types.OrganizationData)
local SeedOrganizations = require(Shared.Data.SeedOrganizations)
local TaskDefinitions = require(Shared.Data.TaskDefinitions)
local RetryPolicy = require(Shared.Logic.RetryPolicy)
local SessionLock = require(Shared.Logic.SessionLock)
local TaskInstance = require(Shared.Logic.TaskInstance)
local TaskOutcome = require(Shared.Logic.TaskOutcome)
local ActionRateLimiter = require(Shared.Logic.ActionRateLimiter)

local DataStoreWrapper = require(script.Parent.DataStoreWrapper)
local OrganizationService = require(script.Parent.OrganizationService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local TaskService = require(script.Parent.TaskService)

local wrapper = DataStoreWrapper.new({
	retryPolicy = RetryPolicy,
	wait = task.wait,
	log = function(msg)
		warn("[DataStoreWrapper] " .. msg)
	end,
})

-- Versioned DataStore names (technical architecture §6-§7): bump the
-- suffix if a future breaking schema change requires a clean split
-- rather than an in-place migration.
local playerStore = DataStoreService:GetDataStore("PlayerData_v1")
local orgStore = DataStoreService:GetDataStore("OrganizationData_v1")

local organizationService = OrganizationService.new({
	wrapper = wrapper,
	store = orgStore,
	schema = OrganizationDataSchema,
	seedOrganizations = SeedOrganizations,
})

local playerDataService = PlayerDataService.new({
	wrapper = wrapper,
	store = playerStore,
	organizationService = organizationService,
	schema = PlayerDataSchema,
	sessionLock = SessionLock,
	jobId = game.JobId,
	log = function(msg)
		warn("[PlayerDataService] " .. msg)
	end,
})

local taskService = TaskService.new({
	playerDataService = playerDataService,
	taskDefinitions = TaskDefinitions,
	taskInstance = TaskInstance,
	taskOutcome = TaskOutcome,
	rateLimiter = ActionRateLimiter,
	log = function(msg)
		warn("[TaskService] " .. msg)
	end,
})

local DEFAULT_ORG_ID = SeedOrganizations.DEFAULT_ORG_ID

local function onPlayerAdded(player)
	local ok, resultOrErr = playerDataService:LoadPlayer(player.UserId, DEFAULT_ORG_ID)
	if not ok then
		warn(
			string.format(
				"[Bootstrap] Failed to load data for %s (%d): %s",
				player.Name,
				player.UserId,
				tostring(resultOrErr)
			)
		)
		player:Kick("We couldn't load your data right now. Please rejoin in a moment.")
	end
end

local function onPlayerRemoving(player)
	local ok, err = playerDataService:SavePlayer(player.UserId, { release = true })
	if not ok then
		warn(
			string.format(
				"[Bootstrap] Failed to save data for %s (%d): %s",
				player.Name,
				player.UserId,
				tostring(err)
			)
		)
	end
end

-- Handle any players already present when this script starts (e.g. a
-- script restart mid-session in Studio).
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

--------------------------------------------------------------------------
-- Task pipeline Remotes (Phase 1)
--------------------------------------------------------------------------

local Remotes = Shared:WaitForChild("Remotes")
local RequestTaskRemote = Remotes:WaitForChild("RequestTask")
local TaskAssignedRemote = Remotes:WaitForChild("TaskAssigned")
local CompleteTaskRemote = Remotes:WaitForChild("CompleteTask")
local TaskResultRemote = Remotes:WaitForChild("TaskResult")

-- `player` is the Roblox-engine-verified sender; RequestTask takes no
-- other arguments, so there is nothing here for a client to fabricate.
RequestTaskRemote.OnServerEvent:Connect(function(player)
	local ok, taskOrErr = taskService:RequestTask(player.UserId)
	if ok then
		TaskAssignedRemote:FireClient(player, {
			Success = true,
			InstanceId = taskOrErr.InstanceId,
			TaskId = taskOrErr.TaskId,
			Name = taskOrErr.Name,
		})
	else
		TaskAssignedRemote:FireClient(player, { Success = false, Reason = tostring(taskOrErr) })
	end
end)

-- taskId/instanceId are the only client-controllable inputs, and both
-- are opaque references validated entirely server-side by TaskService -
-- see its module-level SECURITY MODEL comment. Malformed argument types
-- are dropped here before ever reaching TaskService.
CompleteTaskRemote.OnServerEvent:Connect(function(player, taskId, instanceId)
	if type(taskId) ~= "string" or type(instanceId) ~= "string" then
		TaskResultRemote:FireClient(player, { Success = false, Reason = "malformed request" })
		return
	end

	local ok, resultOrErr = taskService:CompleteTask(player.UserId, taskId, instanceId)
	if ok then
		TaskResultRemote:FireClient(player, {
			Success = true,
			MoneyGain = resultOrErr.MoneyGain,
			PerformanceGain = resultOrErr.PerformanceGain,
			NewPersonalMoney = resultOrErr.NewPersonalMoney,
			NewPerformanceRating = resultOrErr.NewPerformanceRating,
		})
	else
		TaskResultRemote:FireClient(player, { Success = false, Reason = tostring(resultOrErr) })
	end
end)

--------------------------------------------------------------------------
-- Periodic autosave (Phase 1 introduces in-session mutation via
-- ApplyTaskCompletion; Phase 0 only ever saved on leave/shutdown, which
-- is no longer sufficient to bound data loss from a mid-session crash).
--
-- Kept intentionally minimal, per the Phase 1 brief: reuses SaveAll
-- exactly as Phase 0 built it (release = false, so the session lock is
-- re-claimed rather than released - a session stays "owned" by this
-- server across the autosave), on a plain interval loop. No new
-- persistence/session-lock design - see technical-architecture-v0.1.md
-- §5's autosave recommendation.
--------------------------------------------------------------------------

local AUTOSAVE_INTERVAL_SECONDS = 120

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL_SECONDS)
		playerDataService:SaveAll({ release = false })
	end
end)

game:BindToClose(function()
	playerDataService:SaveAll({ release = true })
end)
