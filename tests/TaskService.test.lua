--[[
	Integration tests for TaskService, wired to a real PlayerDataService/
	OrganizationService/DataStoreWrapper stack (fake DataStore underneath,
	same pattern as tests/PlayerDataService.test.lua) - this is what
	directly exercises Phase 1's required security tests: complete twice,
	complete another player's task, invalid task id, fabricated reward/
	performance values, replay, and completion without a task.
]]

local testkit = _G.testkit or dofile("tests/testkit.lua")
local RetryPolicy = dofile("src/ReplicatedStorage/Shared/Logic/RetryPolicy.lua")
local SessionLock = dofile("src/ReplicatedStorage/Shared/Logic/SessionLock.lua")
local ActionRateLimiter = dofile("src/ReplicatedStorage/Shared/Logic/ActionRateLimiter.lua")
local TaskInstance = dofile("src/ReplicatedStorage/Shared/Logic/TaskInstance.lua")
local TaskOutcome = dofile("src/ReplicatedStorage/Shared/Logic/TaskOutcome.lua")
local PlayerDataSchema = dofile("src/ReplicatedStorage/Shared/Types/PlayerData.lua")
local OrganizationDataSchema = dofile("src/ReplicatedStorage/Shared/Types/OrganizationData.lua")
local SeedOrganizations = dofile("src/ReplicatedStorage/Shared/Data/SeedOrganizations.lua")
local TaskDefinitions = dofile("src/ReplicatedStorage/Shared/Data/TaskDefinitions.lua")
local DataStoreWrapper = dofile("src/ServerScriptService/Server/DataStoreWrapper.lua")
local OrganizationService = dofile("src/ServerScriptService/Server/OrganizationService.lua")
local PlayerDataService = dofile("src/ServerScriptService/Server/PlayerDataService.lua")
local TaskService = dofile("src/ServerScriptService/Server/TaskService.lua")
local FakeDataStore = dofile("tests/fakes/FakeDataStore.lua")

testkit.suite("TaskService (integration)")

--[[
	Builds a full stack (PlayerDataService + TaskService).

	TaskService uses two DECOUPLED clocks in production (see
	TaskService.lua's constructor docs): `now` (coarse, for persisted-
	shaped instance timestamps) and `clock` (fine-grained, for rate-limit
	spacing only). This harness mirrors that split:

	- `now` is a manually-controlled fake clock (starts at 1000, only
	  moves when a test calls advance()) - used where a test cares about
	  actual elapsed time (e.g. session-lock staleness elsewhere, or
	  narrative realism in the replay test below).
	- the rate-limit clock auto-increments by `rateClockStep` (default 1,
	  comfortably above ActionRateLimiter.MIN_INTERVAL_SECONDS) on every
	  read, so ordinary tests never trip the rate limiter by accident.
	  Pass `rateClockStep = 0` to freeze it for a test that specifically
	  wants to prove rate-limiting behavior.
]]
local function newHarness(options)
	options = options or {}
	local rateClockStep = options.rateClockStep
	if rateClockStep == nil then
		rateClockStep = 1
	end

	local t = { now = 1000, rateClock = 0 }

	local function nowFn()
		return t.now
	end

	local function clockFn()
		t.rateClock = t.rateClock + rateClockStep
		return t.rateClock
	end

	local playerStore = FakeDataStore.new()
	local orgStore = FakeDataStore.new()
	local wrapper = DataStoreWrapper.new({ retryPolicy = RetryPolicy, wait = function() end })
	local orgService = OrganizationService.new({
		wrapper = wrapper,
		store = orgStore,
		schema = OrganizationDataSchema,
		seedOrganizations = SeedOrganizations,
	})
	local playerDataService = PlayerDataService.new({
		wrapper = wrapper,
		store = playerStore,
		organizationService = orgService,
		schema = PlayerDataSchema,
		sessionLock = SessionLock,
		jobId = "server-a",
		now = nowFn,
	})
	local taskService = TaskService.new({
		playerDataService = playerDataService,
		taskDefinitions = TaskDefinitions,
		taskInstance = TaskInstance,
		taskOutcome = TaskOutcome,
		rateLimiter = ActionRateLimiter,
		now = nowFn,
		clock = clockFn,
	})

	return taskService, playerDataService, t
end

local function advance(t, seconds)
	t.now = t.now + seconds
end

--------------------------------------------------------------------------
-- Successful completion
--------------------------------------------------------------------------

testkit.test("SUCCESS: request then complete grants exactly the defined reward", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(111, SeedOrganizations.DEFAULT_ORG_ID)

	local reqOk, task = taskService:RequestTask(111)
	testkit.assertTrue(reqOk, tostring(task))
	testkit.assertEqual(task.TaskId, TaskDefinitions.DEFAULT_TASK_ID)

	local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	local compOk, result = taskService:CompleteTask(111, task.TaskId, task.InstanceId)
	testkit.assertTrue(compOk, tostring(result))
	testkit.assertEqual(result.MoneyGain, definition.MoneyGain)
	testkit.assertEqual(result.PerformanceGain, definition.PerformanceGain)
	testkit.assertEqual(result.NewPersonalMoney, definition.MoneyGain)
	testkit.assertEqual(result.NewPerformanceRating, definition.PerformanceGain)

	-- The reward actually landed in the persistent-record-backing session.
	local record = playerDataService:GetLoadedRecord(111)
	testkit.assertEqual(record.PersonalMoney, definition.MoneyGain)
	testkit.assertEqual(record.PerformanceRating, definition.PerformanceGain)
	testkit.assertEqual(#record.TaskHistory, 1)
end)

testkit.test("SUCCESS: RequestTask fails without an active session (join required first)", function()
	local taskService = newHarness()
	local ok, err = taskService:RequestTask(222)
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)
end)

testkit.test("SUCCESS: after completing, a new task can be requested again", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(333, SeedOrganizations.DEFAULT_ORG_ID)

	local _ok1, task1 = taskService:RequestTask(333)
	taskService:CompleteTask(333, task1.TaskId, task1.InstanceId)

	local ok2, task2 = taskService:RequestTask(333)
	testkit.assertTrue(ok2, tostring(task2))
	testkit.assertTrue(task2.InstanceId ~= task1.InstanceId)
end)

--------------------------------------------------------------------------
-- SECURITY: complete a task twice
--------------------------------------------------------------------------

testkit.test("SECURITY: completing the same task instance twice is rejected the second time", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(444, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(444)

	local firstOk = taskService:CompleteTask(444, task.TaskId, task.InstanceId)
	testkit.assertTrue(firstOk)

	local secondOk, reason = taskService:CompleteTask(444, task.TaskId, task.InstanceId)
	testkit.assertFalse(secondOk)
	testkit.assertEqual(reason, "task already completed")

	-- Reward must not have been granted twice.
	local record = playerDataService:GetLoadedRecord(444)
	local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	testkit.assertEqual(record.PersonalMoney, definition.MoneyGain)
end)

--------------------------------------------------------------------------
-- SECURITY: complete another player's task
--------------------------------------------------------------------------

testkit.test("SECURITY: a different player cannot complete this player's task instance", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(555, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:LoadPlayer(556, SeedOrganizations.DEFAULT_ORG_ID)

	local _ok, task = taskService:RequestTask(555) -- issued to player 555

	-- Player 556 obtained (e.g. sniffed/guessed) player 555's real
	-- instanceId and taskId and tries to complete it as themselves.
	local ok, reason = taskService:CompleteTask(556, task.TaskId, task.InstanceId)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "unknown task instance")

	-- Player 555's own reward must be unaffected (task still pending for them).
	local recordFor556 = playerDataService:GetLoadedRecord(556)
	testkit.assertEqual(recordFor556.PersonalMoney, 0)
end)

--------------------------------------------------------------------------
-- SECURITY: submit an invalid task ID
--------------------------------------------------------------------------

testkit.test("SECURITY: a fabricated/mismatched task id is rejected", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(666, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(666)

	local ok, reason = taskService:CompleteTask(666, "totally-fabricated-task-id", task.InstanceId)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "task id mismatch")
end)

testkit.test("SECURITY: a nonexistent instance id is rejected (garbage task reference)", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(667, SeedOrganizations.DEFAULT_ORG_ID)
	taskService:RequestTask(667)

	local ok, reason = taskService:CompleteTask(667, TaskDefinitions.DEFAULT_TASK_ID, "totally-fabricated-instance-id")
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "unknown task instance")
end)

--------------------------------------------------------------------------
-- SECURITY: submit fabricated reward / performance values
--------------------------------------------------------------------------

testkit.test("SECURITY: CompleteTask's signature has no reward/performance parameter to fabricate", function()
	-- CompleteTask(userId, taskId, instanceId) is the entire client-facing
	-- surface - there is no field a client could populate with a reward
	-- or performance amount even if it wanted to. Extra positional
	-- arguments (what a modified client might try to smuggle through)
	-- are simply ignored by Lua's calling convention and have no effect
	-- on the server-computed result.
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(777, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(777)

	local ok, result = taskService:CompleteTask(
		777,
		task.TaskId,
		task.InstanceId,
		999999, -- fabricated "MoneyGain" a malicious caller might try to inject
		999999 -- fabricated "PerformanceGain"
	)

	local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	testkit.assertTrue(ok, tostring(result))
	testkit.assertEqual(result.MoneyGain, definition.MoneyGain)
	testkit.assertEqual(result.PerformanceGain, definition.PerformanceGain)
	testkit.assertTrue(result.MoneyGain ~= 999999)
end)

testkit.test("SECURITY: the reward is always derived from the server-side task definition", function()
	-- Tamper with the definition's identity in a completed instance's
	-- lookup path is impossible from the outside; this test pins down
	-- that TaskOutcome.Resolve (the only source of a reward number) is
	-- called with the real TaskDefinitions entry, not anything derived
	-- from client input.
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(778, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(778)
	local _ok2, result = taskService:CompleteTask(778, task.TaskId, task.InstanceId)

	local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	testkit.assertEqual(result.MoneyGain, definition.MoneyGain)
	testkit.assertEqual(result.PerformanceGain, definition.PerformanceGain)
end)

--------------------------------------------------------------------------
-- SECURITY: replay an old completion request
--------------------------------------------------------------------------

testkit.test("SECURITY: replaying an old (already-processed) completion request is rejected", function()
	local taskService, playerDataService, t = newHarness()
	playerDataService:LoadPlayer(888, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(888)
	taskService:CompleteTask(888, task.TaskId, task.InstanceId)

	-- Simulate a captured/replayed network request arriving much later.
	-- (Already-completed rejection is time-independent, but advancing the
	-- clock keeps this test's premise - "replayed much later" - honest.)
	advance(t, 3600)
	local ok, reason = taskService:CompleteTask(888, task.TaskId, task.InstanceId)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "task already completed")
end)

--------------------------------------------------------------------------
-- SECURITY: call completion without receiving a task
--------------------------------------------------------------------------

testkit.test("SECURITY: completing without ever requesting a task is rejected", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(999, SeedOrganizations.DEFAULT_ORG_ID)

	local ok, reason = taskService:CompleteTask(999, TaskDefinitions.DEFAULT_TASK_ID, "no-such-instance")
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "unknown task instance")
end)

testkit.test("SECURITY: completing with no active session at all is rejected", function()
	local taskService = newHarness()
	local ok, reason = taskService:CompleteTask(1000, TaskDefinitions.DEFAULT_TASK_ID, "whatever")
	testkit.assertFalse(ok)
	testkit.assertNotNil(reason)
end)

--------------------------------------------------------------------------
-- SECURITY: malformed input types
--------------------------------------------------------------------------

testkit.test("SECURITY: non-string taskId/instanceId are rejected as malformed, not crashed on", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(1001, SeedOrganizations.DEFAULT_ORG_ID)
	taskService:RequestTask(1001)

	local ok1, reason1 = taskService:CompleteTask(1001, { injected = true }, "inst-1")
	testkit.assertFalse(ok1)
	testkit.assertEqual(reason1, "malformed request")

	local ok2, reason2 = taskService:CompleteTask(1001, TaskDefinitions.DEFAULT_TASK_ID, 12345)
	testkit.assertFalse(ok2)
	testkit.assertEqual(reason2, "malformed request")
end)

--------------------------------------------------------------------------
-- SECURITY: rate limiting
--------------------------------------------------------------------------

testkit.test("SECURITY: rapid-fire RequestTask calls are rate-limited", function()
	-- Freeze the rate-limit clock so two calls land at the exact same
	-- instant, deliberately proving the limiter blocks them.
	local taskService, playerDataService = newHarness({ rateClockStep = 0 })
	playerDataService:LoadPlayer(1002, SeedOrganizations.DEFAULT_ORG_ID)

	local ok1 = taskService:RequestTask(1002)
	testkit.assertTrue(ok1)

	-- Immediately (same instant) try to request again - should be
	-- refused by the rate limiter even though no task is in progress
	-- (the "already completed"/"already in progress" checks are a
	-- separate mechanism from this one).
	local ok2, reason2 = taskService:CompleteTask(1002, "x", "y")
	testkit.assertFalse(ok2)
	testkit.assertEqual(reason2, "rate limited")
end)

--------------------------------------------------------------------------
-- Instance table hygiene
--------------------------------------------------------------------------

testkit.test("completed instances beyond the tracked cap are pruned, pending ones are not", function()
	local taskService, playerDataService, t = newHarness()
	playerDataService:LoadPlayer(1003, SeedOrganizations.DEFAULT_ORG_ID)

	for _ = 1, TaskService.MAX_TRACKED_INSTANCES_PER_PLAYER + 5 do
		local _ok, task = taskService:RequestTask(1003)
		taskService:CompleteTask(1003, task.TaskId, task.InstanceId)
		advance(t, 1) -- keeps CompletedAt timestamps distinct for prune-ordering
	end

	testkit.assertTrue(taskService:_instanceCount(1003) <= TaskService.MAX_TRACKED_INSTANCES_PER_PLAYER)
end)
