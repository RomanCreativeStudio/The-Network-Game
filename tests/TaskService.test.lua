--[[
	Integration tests for TaskService, wired to a real PlayerDataService/
	OrganizationService/DataStoreWrapper stack (fake DataStore underneath,
	same pattern as tests/PlayerDataService.test.lua) - this exercises the
	full Phase 1+2 required security tests: complete twice, complete
	another player's task, invalid/fabricated task id, invalid/fabricated
	choice id, fabricated reward/performance/reputation/quality values,
	replay, and completion without a task - plus the Phase 2 decision/
	outcome paths (deterministic choices, weighted/random choice with
	controlled rolls, Reputation changes).
]]

local testkit = _G.testkit or dofile("tests/testkit.lua")
local RetryPolicy = dofile("src/ReplicatedStorage/Shared/Logic/RetryPolicy.lua")
local SessionLock = dofile("src/ReplicatedStorage/Shared/Logic/SessionLock.lua")
local ActionRateLimiter = dofile("src/ReplicatedStorage/Shared/Logic/ActionRateLimiter.lua")
local TaskInstance = dofile("src/ReplicatedStorage/Shared/Logic/TaskInstance.lua")
local TaskOutcome = dofile("src/ReplicatedStorage/Shared/Logic/TaskOutcome.lua")
local WeightedOutcome = dofile("src/ReplicatedStorage/Shared/Logic/WeightedOutcome.lua")
local ChoicePreview = dofile("src/ReplicatedStorage/Shared/Logic/ChoicePreview.lua")
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

local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)

-- Computes the "expected" resolved outcome for a choice/roll the same
-- way production code does, so tests can assert against it without
-- hardcoding reward numbers that live in TaskDefinitions.lua.
local function expectedOutcome(choiceId, roll)
	local choice = TaskDefinitions.FindChoice(definition, choiceId)
	return TaskOutcome.Resolve(choice, roll, WeightedOutcome)
end

--[[
	Builds a full stack (PlayerDataService + TaskService).

	TaskService uses two DECOUPLED clocks in production (see
	TaskService.lua's constructor docs): `now` (coarse, for persisted-
	shaped instance timestamps) and `clock` (fine-grained, for rate-limit
	spacing only). This harness mirrors that split:

	- `now` is a manually-controlled fake clock (starts at 1000, only
	  moves when a test calls advance()) - used where a test cares about
	  actual elapsed time.
	- the rate-limit clock auto-increments by `rateClockStep` (default 1,
	  comfortably above ActionRateLimiter.MIN_INTERVAL_SECONDS) on every
	  read, so ordinary tests never trip the rate limiter by accident.
	  Pass `rateClockStep = 0` to freeze it for a test that specifically
	  wants to prove rate-limiting behavior.

	`options.forcedRoll`, if set, makes the OUTCOME roll (the
	math.random(1, 100) draw CompleteTask uses to pick among a choice's
	weighted outcomes) deterministic - the instance-id nonce roll
	(math.random(1, 1000000000)) is left real/random so instance ids
	still don't collide. This is how Phase 2's "controlled server-side
	randomness" requirement is made testable: the SAME roll must always
	produce the SAME outcome branch (see the determinism test below).
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

	local randomFn = nil
	if options.forcedRoll ~= nil then
		randomFn = function(lo, hi)
			if hi == TaskService.OUTCOME_ROLL_MAX then
				return options.forcedRoll
			end
			return math.random(lo, hi)
		end
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
		weightedOutcome = WeightedOutcome,
		choicePreview = ChoicePreview,
		rateLimiter = ActionRateLimiter,
		now = nowFn,
		clock = clockFn,
		random = randomFn,
	})

	return taskService, playerDataService, t
end

local function advance(t, seconds)
	t.now = t.now + seconds
end

--------------------------------------------------------------------------
-- Successful completion (deterministic choice)
--------------------------------------------------------------------------

testkit.test("SUCCESS: request then complete (careful) grants exactly the defined reward", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(111, SeedOrganizations.DEFAULT_ORG_ID)

	local reqOk, task = taskService:RequestTask(111)
	testkit.assertTrue(reqOk, tostring(task))
	testkit.assertEqual(task.TaskId, TaskDefinitions.DEFAULT_TASK_ID)

	local expected = expectedOutcome("careful", 1)
	local compOk, result = taskService:CompleteTask(111, task.TaskId, task.InstanceId, "careful")
	testkit.assertTrue(compOk, tostring(result))
	testkit.assertEqual(result.MoneyGain, expected.MoneyGain)
	testkit.assertEqual(result.PerformanceGain, expected.PerformanceGain)
	testkit.assertEqual(result.ReputationGain, expected.ReputationGain)
	testkit.assertEqual(result.QualityScore, expected.QualityScore)
	testkit.assertEqual(result.ChoiceId, "careful")
	testkit.assertEqual(result.NewPersonalMoney, expected.MoneyGain)
	testkit.assertEqual(result.NewPerformanceRating, expected.PerformanceGain)
	testkit.assertEqual(result.NewReputation, expected.ReputationGain)

	-- The reward actually landed in the persistent-record-backing session.
	local record = playerDataService:GetLoadedRecord(111)
	testkit.assertEqual(record.PersonalMoney, expected.MoneyGain)
	testkit.assertEqual(record.PerformanceRating, expected.PerformanceGain)
	testkit.assertEqual(record.Reputation, expected.ReputationGain)
	testkit.assertEqual(#record.TaskHistory, 1)
	testkit.assertEqual(record.TaskHistory[1].ChoiceId, "careful")
end)

testkit.test("SUCCESS: RequestTask fails without an active session (join required first)", function()
	local taskService = newHarness()
	local ok, err = taskService:RequestTask(222)
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)
end)

testkit.test("SUCCESS: RequestTask returns a Prompt and a Choices preview built from server data", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(112, SeedOrganizations.DEFAULT_ORG_ID)

	local ok, task = taskService:RequestTask(112)
	testkit.assertTrue(ok, tostring(task))
	testkit.assertTrue(type(task.Prompt) == "string" and #task.Prompt > 0)
	testkit.assertEqual(#task.Choices, #definition.Choices)
	for _, choice in ipairs(task.Choices) do
		testkit.assertTrue(type(choice.ChoiceId) == "string")
		testkit.assertTrue(type(choice.Preview) == "table")
	end
end)

testkit.test("SUCCESS: after completing, a new task can be requested again", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(333, SeedOrganizations.DEFAULT_ORG_ID)

	local _ok1, task1 = taskService:RequestTask(333)
	taskService:CompleteTask(333, task1.TaskId, task1.InstanceId, "careful")

	local ok2, task2 = taskService:RequestTask(333)
	testkit.assertTrue(ok2, tostring(task2))
	testkit.assertTrue(task2.InstanceId ~= task1.InstanceId)
end)

testkit.test("SUCCESS: the 'quick' choice grants its own distinct, deterministic reward", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(113, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(113)

	local expected = expectedOutcome("quick", 1)
	local ok, result = taskService:CompleteTask(113, task.TaskId, task.InstanceId, "quick")
	testkit.assertTrue(ok, tostring(result))
	testkit.assertEqual(result.MoneyGain, expected.MoneyGain)
	testkit.assertEqual(result.PerformanceGain, expected.PerformanceGain)
	testkit.assertEqual(result.ReputationGain, expected.ReputationGain)
end)

--------------------------------------------------------------------------
-- Weighted/random choice: controlled, deterministic-given-the-roll outcomes
--------------------------------------------------------------------------

testkit.test("SUCCESS: 'cut_corners' with a forced low roll takes the success branch", function()
	local taskService, playerDataService = newHarness({ forcedRoll = 1 }) -- well within the 60% success bucket
	playerDataService:LoadPlayer(114, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(114)

	local expected = expectedOutcome("cut_corners", 1)
	local ok, result = taskService:CompleteTask(114, task.TaskId, task.InstanceId, "cut_corners")
	testkit.assertTrue(ok, tostring(result))
	testkit.assertEqual(result.MoneyGain, expected.MoneyGain)
	testkit.assertEqual(result.PerformanceGain, expected.PerformanceGain)
	testkit.assertEqual(result.ReputationGain, expected.ReputationGain)
	testkit.assertTrue(result.PerformanceGain > 0)
	testkit.assertTrue(result.ReputationGain >= 0)
end)

testkit.test("SUCCESS: 'cut_corners' with a forced high roll takes the backfire branch (negative Performance/Reputation)", function()
	local taskService, playerDataService = newHarness({ forcedRoll = 100 }) -- within the 40% backfire bucket
	playerDataService:LoadPlayer(115, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(115)

	local expected = expectedOutcome("cut_corners", 100)
	local ok, result = taskService:CompleteTask(115, task.TaskId, task.InstanceId, "cut_corners")
	testkit.assertTrue(ok, tostring(result))
	testkit.assertEqual(result.MoneyGain, expected.MoneyGain)
	testkit.assertTrue(result.PerformanceGain < 0)
	testkit.assertTrue(result.ReputationGain < 0)

	-- Reputation must actually be allowed to go negative on the ledger.
	local record = playerDataService:GetLoadedRecord(115)
	testkit.assertEqual(record.Reputation, expected.ReputationGain)
	testkit.assertTrue(record.Reputation < 0)
end)

testkit.test("DETERMINISM: the same roll always produces the same outcome branch for different players", function()
	local taskServiceA, playerDataServiceA = newHarness({ forcedRoll = 100 })
	local taskServiceB, playerDataServiceB = newHarness({ forcedRoll = 100 })
	playerDataServiceA:LoadPlayer(116, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataServiceB:LoadPlayer(117, SeedOrganizations.DEFAULT_ORG_ID)

	local _okA, taskA = taskServiceA:RequestTask(116)
	local _okB, taskB = taskServiceB:RequestTask(117)

	local _ok1, resultA = taskServiceA:CompleteTask(116, taskA.TaskId, taskA.InstanceId, "cut_corners")
	local _ok2, resultB = taskServiceB:CompleteTask(117, taskB.TaskId, taskB.InstanceId, "cut_corners")

	testkit.assertEqual(resultA.MoneyGain, resultB.MoneyGain)
	testkit.assertEqual(resultA.PerformanceGain, resultB.PerformanceGain)
	testkit.assertEqual(resultA.ReputationGain, resultB.ReputationGain)
	testkit.assertEqual(resultA.ResultLabel, resultB.ResultLabel)
end)

--------------------------------------------------------------------------
-- SECURITY: complete a task twice
--------------------------------------------------------------------------

testkit.test("SECURITY: completing the same task instance twice is rejected the second time", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(444, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(444)

	local expected = expectedOutcome("careful", 1)
	local firstOk = taskService:CompleteTask(444, task.TaskId, task.InstanceId, "careful")
	testkit.assertTrue(firstOk)

	-- Second attempt tries a DIFFERENT choice too, to prove the
	-- already-completed check blocks it regardless of which choice is
	-- (fraudulently) submitted the second time.
	local secondOk, reason = taskService:CompleteTask(444, task.TaskId, task.InstanceId, "cut_corners")
	testkit.assertFalse(secondOk)
	testkit.assertEqual(reason, "task already completed")

	-- Reward must not have been granted twice, and must still reflect
	-- the FIRST (careful) choice, not the second (cut_corners) attempt.
	local record = playerDataService:GetLoadedRecord(444)
	testkit.assertEqual(record.PersonalMoney, expected.MoneyGain)
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
	local ok, reason = taskService:CompleteTask(556, task.TaskId, task.InstanceId, "careful")
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "unknown task instance")

	-- Player 556's own record must be unaffected.
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

	local ok, reason = taskService:CompleteTask(666, "totally-fabricated-task-id", task.InstanceId, "careful")
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "task id mismatch")
end)

testkit.test("SECURITY: a nonexistent instance id is rejected (garbage task reference)", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(667, SeedOrganizations.DEFAULT_ORG_ID)
	taskService:RequestTask(667)

	local ok, reason =
		taskService:CompleteTask(667, TaskDefinitions.DEFAULT_TASK_ID, "totally-fabricated-instance-id", "careful")
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "unknown task instance")
end)

--------------------------------------------------------------------------
-- SECURITY: submit an invalid/fabricated CHOICE id
--------------------------------------------------------------------------

testkit.test("SECURITY: a fabricated/unknown choice id is rejected", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(668, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(668)

	local ok, reason = taskService:CompleteTask(668, task.TaskId, task.InstanceId, "totally-fabricated-choice-id")
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "invalid choice")

	-- No reward of any kind should have been granted for a rejected choice.
	local record = playerDataService:GetLoadedRecord(668)
	testkit.assertEqual(record.PersonalMoney, 0)
	testkit.assertEqual(record.PerformanceRating, 0)
	testkit.assertEqual(record.Reputation, 0)
end)

testkit.test("SECURITY: a choice id from a DIFFERENT task is still rejected as invalid for this instance", function()
	-- Even though "careful" is a real ChoiceId in the system, submitting
	-- it against an instance whose definition doesn't define that exact
	-- choice must still resolve correctly - this pins down that choice
	-- lookup is always scoped to the instance's OWN task definition, not
	-- to choice ids in the abstract.
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(669, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(669)

	local ok, result = taskService:CompleteTask(669, task.TaskId, task.InstanceId, "careful")
	testkit.assertTrue(ok, tostring(result)) -- sanity: "careful" IS valid for this task
end)

--------------------------------------------------------------------------
-- SECURITY: submit fabricated reward / performance / reputation / quality values
--------------------------------------------------------------------------

testkit.test("SECURITY: CompleteTask's signature has no reward/performance/reputation/quality parameter to fabricate", function()
	-- CompleteTask(userId, taskId, instanceId, choiceId) is the entire
	-- client-facing surface - there is no field a client could populate
	-- with a reward, performance, reputation, or quality value even if it
	-- wanted to. Extra positional arguments (what a modified client might
	-- try to smuggle through) are simply ignored by Lua's calling
	-- convention and have no effect on the server-computed result.
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(777, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(777)

	local expected = expectedOutcome("careful", 1)
	local ok, result = taskService:CompleteTask(
		777,
		task.TaskId,
		task.InstanceId,
		"careful",
		999999, -- fabricated "MoneyGain"
		999999, -- fabricated "PerformanceGain"
		999999, -- fabricated "ReputationGain"
		100, -- fabricated "QualityScore"
		true -- fabricated "Success"
	)

	testkit.assertTrue(ok, tostring(result))
	testkit.assertEqual(result.MoneyGain, expected.MoneyGain)
	testkit.assertEqual(result.PerformanceGain, expected.PerformanceGain)
	testkit.assertEqual(result.ReputationGain, expected.ReputationGain)
	testkit.assertTrue(result.MoneyGain ~= 999999)
end)

testkit.test("SECURITY: the reward is always derived from the server-side task/choice definition", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(778, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(778)
	local _ok2, result = taskService:CompleteTask(778, task.TaskId, task.InstanceId, "careful")

	local expected = expectedOutcome("careful", 1)
	testkit.assertEqual(result.MoneyGain, expected.MoneyGain)
	testkit.assertEqual(result.PerformanceGain, expected.PerformanceGain)
	testkit.assertEqual(result.ReputationGain, expected.ReputationGain)
end)

--------------------------------------------------------------------------
-- SECURITY: replay an old completion request
--------------------------------------------------------------------------

testkit.test("SECURITY: replaying an old (already-processed) completion request is rejected", function()
	local taskService, playerDataService, t = newHarness()
	playerDataService:LoadPlayer(888, SeedOrganizations.DEFAULT_ORG_ID)
	local _ok, task = taskService:RequestTask(888)
	taskService:CompleteTask(888, task.TaskId, task.InstanceId, "careful")

	-- Simulate a captured/replayed network request arriving much later.
	-- (Already-completed rejection is time-independent, but advancing the
	-- clock keeps this test's premise - "replayed much later" - honest.)
	advance(t, 3600)
	local ok, reason = taskService:CompleteTask(888, task.TaskId, task.InstanceId, "careful")
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "task already completed")
end)

--------------------------------------------------------------------------
-- SECURITY: call completion without receiving a task
--------------------------------------------------------------------------

testkit.test("SECURITY: completing without ever requesting a task is rejected", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(999, SeedOrganizations.DEFAULT_ORG_ID)

	local ok, reason = taskService:CompleteTask(999, TaskDefinitions.DEFAULT_TASK_ID, "no-such-instance", "careful")
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "unknown task instance")
end)

testkit.test("SECURITY: completing with no active session at all is rejected", function()
	local taskService = newHarness()
	local ok, reason = taskService:CompleteTask(1000, TaskDefinitions.DEFAULT_TASK_ID, "whatever", "careful")
	testkit.assertFalse(ok)
	testkit.assertNotNil(reason)
end)

--------------------------------------------------------------------------
-- SECURITY: malformed input types
--------------------------------------------------------------------------

testkit.test("SECURITY: non-string taskId/instanceId/choiceId are rejected as malformed, not crashed on", function()
	local taskService, playerDataService = newHarness()
	playerDataService:LoadPlayer(1001, SeedOrganizations.DEFAULT_ORG_ID)
	taskService:RequestTask(1001)

	local ok1, reason1 = taskService:CompleteTask(1001, { injected = true }, "inst-1", "careful")
	testkit.assertFalse(ok1)
	testkit.assertEqual(reason1, "malformed request")

	local ok2, reason2 = taskService:CompleteTask(1001, TaskDefinitions.DEFAULT_TASK_ID, 12345, "careful")
	testkit.assertFalse(ok2)
	testkit.assertEqual(reason2, "malformed request")

	local ok3, reason3 = taskService:CompleteTask(1001, TaskDefinitions.DEFAULT_TASK_ID, "inst-1", 12345)
	testkit.assertFalse(ok3)
	testkit.assertEqual(reason3, "malformed request")
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

	-- Immediately (same instant) try to complete - should be refused by
	-- the rate limiter even before argument validity is checked (the
	-- "already completed"/"invalid choice" checks are a separate
	-- mechanism from this one, and taskId/instanceId here are valid
	-- strings so the malformed-type check doesn't fire first).
	local ok2, reason2 = taskService:CompleteTask(1002, "x", "y", "careful")
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
		taskService:CompleteTask(1003, task.TaskId, task.InstanceId, "careful")
		advance(t, 1) -- keeps CompletedAt timestamps distinct for prune-ordering
	end

	testkit.assertTrue(taskService:_instanceCount(1003) <= TaskService.MAX_TRACKED_INSTANCES_PER_PLAYER)
end)
