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

	Phase 3 scope only. Deliberately does NOT implement: Director/VP/
	Chief/Executive/CEO/Founder, Departments, Branches, hiring/firing,
	Contracts, Governance, Board, M&A, Courts, political systems, mega-
	corporation systems, or Monetization. See docs/mvp-definition-v0.1.md
	and docs/technical-architecture-v0.1.md.

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
local PromotionConfig = require(Shared.Data.PromotionConfig)
local RetryPolicy = require(Shared.Logic.RetryPolicy)
local SessionLock = require(Shared.Logic.SessionLock)
local TaskInstance = require(Shared.Logic.TaskInstance)
local TaskOutcome = require(Shared.Logic.TaskOutcome)
local WeightedOutcome = require(Shared.Logic.WeightedOutcome)
local ChoicePreview = require(Shared.Logic.ChoicePreview)
local ActionRateLimiter = require(Shared.Logic.ActionRateLimiter)
local PromotionRules = require(Shared.Logic.PromotionRules)

local DataStoreWrapper = require(script.Parent.DataStoreWrapper)
local OrganizationService = require(script.Parent.OrganizationService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PromotionService = require(script.Parent.PromotionService)
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

-- PLAYTEST CALIBRATION values (Phase 3A) - see
-- Shared/Data/PromotionConfig.lua for the full rationale and the
-- explicit "not locked" caveat.
local promotionService = PromotionService.new({
	playerDataService = playerDataService,
	promotionRules = PromotionRules,
	promotionConfig = PromotionConfig.ASSOCIATE_TO_MANAGER,
	schema = PlayerDataSchema,
	log = function(msg)
		warn("[PromotionService] " .. msg)
	end,
})

local taskService = TaskService.new({
	playerDataService = playerDataService,
	taskDefinitions = TaskDefinitions,
	taskInstance = TaskInstance,
	taskOutcome = TaskOutcome,
	weightedOutcome = WeightedOutcome,
	choicePreview = ChoicePreview,
	rateLimiter = ActionRateLimiter,
	schema = PlayerDataSchema,
	promotionService = promotionService,
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
-- Task pipeline Remotes
--------------------------------------------------------------------------

local Remotes = Shared:WaitForChild("Remotes")
local RequestTaskRemote = Remotes:WaitForChild("RequestTask")
local TaskAssignedRemote = Remotes:WaitForChild("TaskAssigned")
local CompleteTaskRemote = Remotes:WaitForChild("CompleteTask")
local TaskResultRemote = Remotes:WaitForChild("TaskResult")
local AssignTaskRemote = Remotes:WaitForChild("AssignTask")
local AssignTaskResultRemote = Remotes:WaitForChild("AssignTaskResult")
local PromotionNoticeRemote = Remotes:WaitForChild("PromotionNotice")

-- `player` is the Roblox-engine-verified sender; RequestTask takes no
-- other arguments, so there is nothing here for a client to fabricate.
-- The Choices array sent back is a READ-ONLY preview (built by
-- ChoicePreview purely from server data) so the player can see what
-- their options are and roughly what each is likely to cost/earn before
-- deciding - the server never reads these numbers back from the client.
RequestTaskRemote.OnServerEvent:Connect(function(player)
	local ok, taskOrErr = taskService:RequestTask(player.UserId)
	if ok then
		TaskAssignedRemote:FireClient(player, {
			Success = true,
			InstanceId = taskOrErr.InstanceId,
			TaskId = taskOrErr.TaskId,
			Name = taskOrErr.Name,
			Prompt = taskOrErr.Prompt,
			Choices = taskOrErr.Choices,
		})
	else
		TaskAssignedRemote:FireClient(player, { Success = false, Reason = tostring(taskOrErr) })
	end
end)

-- taskId/instanceId/choiceId are the ONLY client-controllable inputs,
-- and all three are opaque references validated entirely server-side by
-- TaskService - see its module-level SECURITY MODEL comment. No reward,
-- performance, reputation, quality, rank, or promotion-eligibility value
-- is ever accepted here. Malformed argument types are dropped here
-- before ever reaching TaskService.
CompleteTaskRemote.OnServerEvent:Connect(function(player, taskId, instanceId, choiceId)
	if type(taskId) ~= "string" or type(instanceId) ~= "string" or type(choiceId) ~= "string" then
		TaskResultRemote:FireClient(player, { Success = false, Reason = "malformed request" })
		return
	end

	local ok, resultOrErr = taskService:CompleteTask(player.UserId, taskId, instanceId, choiceId)
	if ok then
		TaskResultRemote:FireClient(player, {
			Success = true,
			ChoiceId = resultOrErr.ChoiceId,
			ResultLabel = resultOrErr.ResultLabel,
			QualityScore = resultOrErr.QualityScore,
			MoneyGain = resultOrErr.MoneyGain,
			PerformanceGain = resultOrErr.PerformanceGain,
			ReputationGain = resultOrErr.ReputationGain,
			NewPersonalMoney = resultOrErr.NewPersonalMoney,
			NewPerformanceRating = resultOrErr.NewPerformanceRating,
			NewReputation = resultOrErr.NewReputation,
			-- Phase 3 "clear player-facing explanation": always present,
			-- regardless of whether a promotion happened this call.
			Rank = resultOrErr.Rank,
			PerformanceThreshold = resultOrErr.PerformanceThreshold,
			ReputationThreshold = resultOrErr.ReputationThreshold,
			PromotionEligible = resultOrErr.PromotionEligible,
		})

		-- Fired only when CheckAndPromote (inside CompleteTask) actually
		-- just granted a promotion - a distinct celebratory event from
		-- the ongoing status fields above. Never triggered by, or in
		-- response to, anything the client sent.
		if resultOrErr.Promotion then
			PromotionNoticeRemote:FireClient(player, {
				PreviousRank = resultOrErr.Promotion.PreviousRank,
				NewRank = resultOrErr.Promotion.NewRank,
				PerformanceRating = resultOrErr.Promotion.PerformanceRating,
				Reputation = resultOrErr.Promotion.Reputation,
				PerformanceThreshold = resultOrErr.Promotion.PerformanceThreshold,
				ReputationThreshold = resultOrErr.Promotion.ReputationThreshold,
				Unlocked = resultOrErr.Promotion.Unlocked,
			})
		end
	else
		TaskResultRemote:FireClient(player, { Success = false, Reason = tostring(resultOrErr) })
	end
end)

--------------------------------------------------------------------------
-- Manager responsibility: assigning the existing task to another player
-- (Phase 3). Extends the same TaskService/instance machinery above -
-- see TaskService.lua's AssignTask for the full authorization chain
-- (never trusts the client's claim about its own rank or the target's
-- eligibility; both are re-read from PlayerDataService on every call).
--------------------------------------------------------------------------

-- targetUserId is the only client-controllable input; `player` (the
-- assigning Manager) is, as always, the engine-verified Remote sender.
AssignTaskRemote.OnServerEvent:Connect(function(player, targetUserId)
	if type(targetUserId) ~= "number" then
		AssignTaskResultRemote:FireClient(player, { Success = false, Reason = "malformed request" })
		return
	end

	local ok, resultOrErr = taskService:AssignTask(player.UserId, targetUserId)
	if not ok then
		AssignTaskResultRemote:FireClient(player, { Success = false, Reason = tostring(resultOrErr) })
		return
	end

	-- Manager feedback: confirms the assignment succeeded.
	AssignTaskResultRemote:FireClient(player, {
		Success = true,
		TargetUserId = resultOrErr.TargetUserId,
		TaskName = resultOrErr.Name,
	})

	-- Recipient notification: reuses the same TaskAssigned event a
	-- self-request would fire, with AssignedBy fields added so the
	-- client can distinguish "I asked for this" from "I was assigned
	-- this." If the target disconnected between AssignTask succeeding
	-- and here (should not happen in practice - AssignTask itself
	-- requires an active session), this is a no-op rather than an error.
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		TaskAssignedRemote:FireClient(targetPlayer, {
			Success = true,
			InstanceId = resultOrErr.InstanceId,
			TaskId = resultOrErr.TaskId,
			Name = resultOrErr.Name,
			Prompt = resultOrErr.Prompt,
			Choices = resultOrErr.Choices,
			AssignedByUserId = resultOrErr.AssignedBy,
			AssignedByName = player.Name,
		})
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
