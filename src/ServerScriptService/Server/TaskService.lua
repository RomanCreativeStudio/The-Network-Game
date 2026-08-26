--[[
	TaskService - the Phase 1 server-authoritative task pipeline:
	assignment (RequestTask) and completion (CompleteTask).

	Phase 1 scope: exactly one task, no decision point, no promotion, no
	economy gameplay beyond a single fixed reward. See
	docs/mvp-definition-v0.1.md's Phase 1 brief and
	docs/technical-architecture-v0.1.md §10-§13.

	SECURITY MODEL (this is the whole point of Phase 1):
	The client can only ever send two opaque values to CompleteTask: a
	taskId and an instanceId. Neither is trusted as authoritative - both
	are looked up against server-held state (the per-player instance
	table below) and the server-only task definitions in
	Shared/Data/TaskDefinitions.lua. The client NEVER sends, and this
	module NEVER reads from the client, a reward amount, a performance
	amount, a completion flag, or anything about organization state.
	`userId` is likewise never taken from client input - see
	Bootstrap.server.lua, which passes only the Roblox-engine-verified
	`player.UserId` from a RemoteEvent's server-populated first argument.

	Dependency-injected (playerDataService, taskDefinitions, taskInstance,
	taskOutcome, rateLimiter all passed via config) so this module has
	zero internal `require` calls and can be exercised by the standalone
	test suite against a fake PlayerDataService - see
	technical-architecture-v0.1.md §18.
]]

local TaskService = {}
TaskService.__index = TaskService

-- Bounds how many instances (pending + completed) are retained per
-- player, so a long session's in-memory instance table doesn't grow
-- unboundedly. Pruning only ever removes COMPLETED instances, oldest
-- first, and never a still-pending one. This is a memory-hygiene bound,
-- not a persisted value - task instances are never written to
-- DataStore (see Phase 1 report §11, "persist only the minimum
-- required state").
TaskService.MAX_TRACKED_INSTANCES_PER_PLAYER = 50

--[[
	config:
		playerDataService (required) - a Phase 0 PlayerDataService instance
		taskDefinitions (required) - the TaskDefinitions data module
		taskInstance (required) - the TaskInstance logic module
		taskOutcome (required) - the TaskOutcome logic module
		rateLimiter (required) - the ActionRateLimiter logic module
		defaultTaskId (optional) - defaults to taskDefinitions.DEFAULT_TASK_ID
		now (optional) - function() -> number, defaults to os.time. Used
			for persisted-shaped timestamps (instance IssuedAt/CompletedAt,
			mirroring the 1-second-resolution convention the rest of the
			codebase uses for stored timestamps - see PlayerData/
			OrganizationData CreatedAt/LastLogin, SessionLock.ClaimedAt).
		clock (optional) - function() -> number, defaults to os.clock.
			Used ONLY for rate-limit spacing (self._lastActionAt), which
			needs sub-second resolution: two legitimate actions (e.g.
			RequestTask immediately followed by a click on "Complete")
			can easily land within the same os.time() second, so the rate
			limiter must not share that clock's granularity. In real
			Roblox, os.clock() is a monotonic wall-clock-seconds timer
			(the modern replacement for the deprecated tick()), which is
			exactly what a sub-second cooldown needs.
		random (optional) - function(lo, hi) -> number, defaults to math.random
		log (optional) - function(message), defaults to a no-op
]]
function TaskService.new(config)
	config = config or {}
	assert(config.playerDataService, "TaskService requires config.playerDataService")
	assert(config.taskDefinitions, "TaskService requires config.taskDefinitions")
	assert(config.taskInstance, "TaskService requires config.taskInstance")
	assert(config.taskOutcome, "TaskService requires config.taskOutcome")
	assert(config.rateLimiter, "TaskService requires config.rateLimiter")

	local self = setmetatable({}, TaskService)
	self._playerDataService = config.playerDataService
	self._taskDefinitions = config.taskDefinitions
	self._taskInstance = config.taskInstance
	self._taskOutcome = config.taskOutcome
	self._rateLimiter = config.rateLimiter
	self._defaultTaskId = config.defaultTaskId or config.taskDefinitions.DEFAULT_TASK_ID
	self._now = config.now or os.time
	self._clock = config.clock or os.clock
	self._random = config.random or math.random
	self._log = config.log or function() end

	-- userId -> { [instanceId] = TaskInstance }
	self._instances = {}
	-- userId -> timestamp of the last allowed RequestTask/CompleteTask call
	self._lastActionAt = {}

	return self
end

-- Internal: checks AND (on success) records this action's timestamp
-- against the per-player rate limiter, using self._clock (not self._now -
-- see the constructor docs above for why the two are deliberately
-- different clocks).
function TaskService:_checkRateLimit(userId)
	local now = self._clock()
	if not self._rateLimiter.ShouldAllow(self._lastActionAt[userId], now) then
		return false
	end
	self._lastActionAt[userId] = now
	return true
end

function TaskService:_newInstanceId(userId)
	return string.format("ti:%d:%d:%d", userId, self._now(), self._random(1, 1000000000))
end

-- Internal: drops the oldest COMPLETED instances for userId once the
-- tracked count exceeds MAX_TRACKED_INSTANCES_PER_PLAYER. Never prunes a
-- pending (not yet completed) instance.
function TaskService:_pruneInstances(userId)
	local instances = self._instances[userId]
	if not instances then
		return
	end

	local count = 0
	for _ in pairs(instances) do
		count = count + 1
	end
	if count <= TaskService.MAX_TRACKED_INSTANCES_PER_PLAYER then
		return
	end

	-- Collect completed instances, oldest first, and drop from the front
	-- until back under the cap.
	local completed = {}
	for instanceId, instance in pairs(instances) do
		if instance.Completed then
			table.insert(completed, { instanceId = instanceId, completedAt = instance.CompletedAt or 0 })
		end
	end
	table.sort(completed, function(a, b)
		return a.completedAt < b.completedAt
	end)

	local toRemove = count - TaskService.MAX_TRACKED_INSTANCES_PER_PLAYER
	for i = 1, math.min(toRemove, #completed) do
		instances[completed[i].instanceId] = nil
	end
end

--[[
	Assigns Phase 1's single task to `userId`. Requires the player to
	already have an active PlayerDataService session (i.e. to have
	joined - see Bootstrap.server.lua's PlayerAdded handler), and refuses
	to assign a second task while one is still pending, which doubles as
	both a sensible Phase 1 rule ("one task at a time") and a cheap abuse
	guard against instance-table growth.

	Returns (true, { InstanceId, TaskId, Name }) on success, or
	(false, errorMessage) on failure. Deliberately does NOT return
	MoneyGain/PerformanceGain - Phase 1 exposes reward amounts only as
	the RESULT of completion (TaskResult), never at assignment time, so
	there is nothing reward-shaped for a client to try to spoof back at
	the server later.
]]
function TaskService:RequestTask(userId)
	assert(type(userId) == "number", "userId must be a number")

	if not self:_checkRateLimit(userId) then
		return false, "rate limited"
	end

	if not self._playerDataService:GetLoadedRecord(userId) then
		return false, "no active session for user"
	end

	local instances = self._instances[userId]
	if instances then
		for _, instance in pairs(instances) do
			if not instance.Completed then
				return false, "a task is already in progress"
			end
		end
	else
		instances = {}
		self._instances[userId] = instances
	end

	local definition = self._taskDefinitions.FindById(self._defaultTaskId)
	if not definition then
		-- Defensive: should be unreachable given a correctly configured
		-- TaskDefinitions module, but never assign an instance for an
		-- unknown definition.
		return false, "no task available"
	end

	local now = self._now()
	local instanceId = self:_newInstanceId(userId)
	local instance = self._taskInstance.New(definition.TaskId, instanceId, now)
	instances[instanceId] = instance

	self:_pruneInstances(userId)

	return true, {
		InstanceId = instance.InstanceId,
		TaskId = instance.TaskId,
		Name = definition.Name,
	}
end

--[[
	Completes a previously-assigned task instance for `userId`.

	taskId, instanceId: the ONLY client-controllable inputs. Both are
	opaque references validated against server-held state - see the
	module-level SECURITY MODEL comment above.

	Returns (true, resultTable) on success, where resultTable is
	{ MoneyGain, PerformanceGain, NewPersonalMoney, NewPerformanceRating },
	or (false, errorMessage) on failure (unknown instance, task id
	mismatch, already completed, rate limited, no active session).
]]
function TaskService:CompleteTask(userId, taskId, instanceId)
	assert(type(userId) == "number", "userId must be a number")

	if type(taskId) ~= "string" or type(instanceId) ~= "string" then
		return false, "malformed request"
	end

	if not self:_checkRateLimit(userId) then
		return false, "rate limited"
	end

	if not self._playerDataService:GetLoadedRecord(userId) then
		return false, "no active session for user"
	end

	local instances = self._instances[userId]
	local instance = instances and instances[instanceId] or nil

	local canComplete, reason = self._taskInstance.ValidateCompletion(instance, taskId)
	if not canComplete then
		return false, reason
	end

	local now = self._now()

	local definition = self._taskDefinitions.FindById(instance.TaskId)
	if not definition then
		-- Defensive: the instance referenced a task definition that no
		-- longer exists. Should be unreachable in Phase 1 (one static
		-- definition, never removed at runtime), but never fabricate a
		-- reward for an unknown definition.
		return false, "task definition no longer exists"
	end

	local reward = self._taskOutcome.Resolve(definition)

	instances[instanceId] = self._taskInstance.MarkCompleted(instance, now)

	local applyOk, recordOrErr = self._playerDataService:ApplyTaskCompletion(userId, {
		MoneyGain = reward.MoneyGain,
		PerformanceGain = reward.PerformanceGain,
		HistoryEntry = {
			TaskId = definition.TaskId,
			InstanceId = instanceId,
			CompletedAt = now,
			MoneyGain = reward.MoneyGain,
			PerformanceGain = reward.PerformanceGain,
		},
	})

	if not applyOk then
		-- The reward was resolved but could not be applied (e.g. the
		-- player's session ended between the checks above and here).
		-- Roll the instance back to pending so a legitimate retry (once
		-- the player has an active session again) is not blocked by a
		-- false "already completed".
		instances[instanceId] = instance
		return false, "failed to apply reward: " .. tostring(recordOrErr)
	end

	self:_pruneInstances(userId)

	return true, {
		MoneyGain = reward.MoneyGain,
		PerformanceGain = reward.PerformanceGain,
		NewPersonalMoney = recordOrErr.PersonalMoney,
		NewPerformanceRating = recordOrErr.PerformanceRating,
	}
end

-- Test/diagnostic helper: returns how many instances (pending + completed)
-- are currently tracked for userId.
function TaskService:_instanceCount(userId)
	local instances = self._instances[userId]
	if not instances then
		return 0
	end
	local count = 0
	for _ in pairs(instances) do
		count = count + 1
	end
	return count
end

return TaskService
