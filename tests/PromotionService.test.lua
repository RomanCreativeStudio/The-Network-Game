--[[
	Integration tests for PromotionService, wired to a real
	PlayerDataService/OrganizationService/DataStoreWrapper stack (fake
	DataStore underneath, same pattern as tests/PlayerDataService.test.lua).

	Directly exercises the Phase 3 promotion requirements: eligibility,
	below-threshold, exactly-at-threshold, duplicate-promotion prevention,
	Money cannot cause promotion, and persistence of the promoted rank
	across leave/rejoin.
]]

local testkit = _G.testkit or dofile("tests/testkit.lua")
local RetryPolicy = dofile("src/ReplicatedStorage/Shared/Logic/RetryPolicy.lua")
local SessionLock = dofile("src/ReplicatedStorage/Shared/Logic/SessionLock.lua")
local PromotionRules = dofile("src/ReplicatedStorage/Shared/Logic/PromotionRules.lua")
local PromotionConfig = dofile("src/ReplicatedStorage/Shared/Data/PromotionConfig.lua")
local PlayerDataSchema = dofile("src/ReplicatedStorage/Shared/Types/PlayerData.lua")
local OrganizationDataSchema = dofile("src/ReplicatedStorage/Shared/Types/OrganizationData.lua")
local SeedOrganizations = dofile("src/ReplicatedStorage/Shared/Data/SeedOrganizations.lua")
local DataStoreWrapper = dofile("src/ServerScriptService/Server/DataStoreWrapper.lua")
local OrganizationService = dofile("src/ServerScriptService/Server/OrganizationService.lua")
local PlayerDataService = dofile("src/ServerScriptService/Server/PlayerDataService.lua")
local PromotionService = dofile("src/ServerScriptService/Server/PromotionService.lua")
local FakeDataStore = dofile("tests/fakes/FakeDataStore.lua")

testkit.suite("PromotionService (integration)")

local CONFIG = PromotionConfig.ASSOCIATE_TO_MANAGER -- PLAYTEST CALIBRATION (10 perf, 5 rep)

local function newHarness(playerStore, orgStore)
	playerStore = playerStore or FakeDataStore.new()
	orgStore = orgStore or FakeDataStore.new()
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
	})
	local promotionService = PromotionService.new({
		playerDataService = playerDataService,
		promotionRules = PromotionRules,
		promotionConfig = CONFIG,
		schema = PlayerDataSchema,
	})
	return promotionService, playerDataService
end

--------------------------------------------------------------------------
-- Eligibility
--------------------------------------------------------------------------

testkit.test("ELIGIBILITY: an Associate meeting both thresholds is promoted", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(101, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(101, {
		MoneyGain = 0,
		PerformanceGain = CONFIG.PerformanceThreshold + 5,
		ReputationGain = CONFIG.ReputationThreshold + 5,
	})

	local ok, result = promotionService:CheckAndPromote(101)
	testkit.assertTrue(ok, tostring(result))
	testkit.assertEqual(result.PreviousRank, PlayerDataSchema.RANK.ASSOCIATE)
	testkit.assertEqual(result.NewRank, PlayerDataSchema.RANK.MANAGER)
	testkit.assertTrue(type(result.Unlocked) == "string" and #result.Unlocked > 0)

	local record = playerDataService:GetLoadedRecord(101)
	testkit.assertEqual(record.Rank, PlayerDataSchema.RANK.MANAGER)
end)

testkit.test("ELIGIBILITY: GetStatus reports EligibleForPromotion before CheckAndPromote is called", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(102, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(102, {
		MoneyGain = 0,
		PerformanceGain = CONFIG.PerformanceThreshold,
		ReputationGain = CONFIG.ReputationThreshold,
	})

	local ok, status = promotionService:GetStatus(102)
	testkit.assertTrue(ok)
	testkit.assertTrue(status.EligibleForPromotion)
	testkit.assertEqual(status.Rank, PlayerDataSchema.RANK.ASSOCIATE) -- not yet applied
end)

--------------------------------------------------------------------------
-- Below-threshold cases
--------------------------------------------------------------------------

testkit.test("BELOW-THRESHOLD: performance short of the requirement is not promoted", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(103, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(103, {
		MoneyGain = 0,
		PerformanceGain = CONFIG.PerformanceThreshold - 1,
		ReputationGain = CONFIG.ReputationThreshold + 10,
	})

	local ok, reason = promotionService:CheckAndPromote(103)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "performance below threshold")
	testkit.assertEqual(playerDataService:GetLoadedRecord(103).Rank, PlayerDataSchema.RANK.ASSOCIATE)
end)

testkit.test("BELOW-THRESHOLD: reputation short of the requirement is not promoted", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(104, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(104, {
		MoneyGain = 0,
		PerformanceGain = CONFIG.PerformanceThreshold + 10,
		ReputationGain = CONFIG.ReputationThreshold - 1,
	})

	local ok, reason = promotionService:CheckAndPromote(104)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "reputation below threshold")
	testkit.assertEqual(playerDataService:GetLoadedRecord(104).Rank, PlayerDataSchema.RANK.ASSOCIATE)
end)

testkit.test("BELOW-THRESHOLD: a brand-new Associate (0/0) is not promoted", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(105, SeedOrganizations.DEFAULT_ORG_ID)

	local ok = promotionService:CheckAndPromote(105)
	testkit.assertFalse(ok)
end)

--------------------------------------------------------------------------
-- Exactly-at-threshold
--------------------------------------------------------------------------

testkit.test("EXACTLY-AT-THRESHOLD: performance and reputation exactly equal to the requirement promotes", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(106, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(106, {
		MoneyGain = 0,
		PerformanceGain = CONFIG.PerformanceThreshold,
		ReputationGain = CONFIG.ReputationThreshold,
	})

	local ok, result = promotionService:CheckAndPromote(106)
	testkit.assertTrue(ok, tostring(result))
	testkit.assertEqual(result.PerformanceRating, CONFIG.PerformanceThreshold)
	testkit.assertEqual(result.Reputation, CONFIG.ReputationThreshold)
end)

testkit.test("EXACTLY-AT-THRESHOLD: one point under either threshold is NOT eligible", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(107, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(107, {
		MoneyGain = 0,
		PerformanceGain = CONFIG.PerformanceThreshold - 1,
		ReputationGain = CONFIG.ReputationThreshold,
	})

	local ok = promotionService:CheckAndPromote(107)
	testkit.assertFalse(ok)
end)

--------------------------------------------------------------------------
-- Duplicate promotion prevention
--------------------------------------------------------------------------

testkit.test("DUPLICATE PROMOTION: a second CheckAndPromote call on an already-Manager record fails cleanly", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(108, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(108, {
		MoneyGain = 0,
		PerformanceGain = CONFIG.PerformanceThreshold + 20,
		ReputationGain = CONFIG.ReputationThreshold + 20,
	})

	local firstOk = promotionService:CheckAndPromote(108)
	testkit.assertTrue(firstOk)

	local secondOk, reason = promotionService:CheckAndPromote(108)
	testkit.assertFalse(secondOk)
	testkit.assertEqual(reason, "not eligible for promotion from current rank")
	testkit.assertEqual(playerDataService:GetLoadedRecord(108).Rank, PlayerDataSchema.RANK.MANAGER)
end)

--------------------------------------------------------------------------
-- Money cannot cause promotion
--------------------------------------------------------------------------

testkit.test("MONEY CANNOT PROMOTE: enormous Money with Performance/Reputation at zero does not promote", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(109, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(109, {
		MoneyGain = 999999,
		PerformanceGain = 0,
		ReputationGain = 0,
	})

	local ok = promotionService:CheckAndPromote(109)
	testkit.assertFalse(ok)
	testkit.assertEqual(playerDataService:GetLoadedRecord(109).Rank, PlayerDataSchema.RANK.ASSOCIATE)
end)

testkit.test("MONEY CANNOT PROMOTE: enormous Money with Performance met but Reputation short still fails", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(110, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(110, {
		MoneyGain = 999999,
		PerformanceGain = CONFIG.PerformanceThreshold + 50,
		ReputationGain = CONFIG.ReputationThreshold - 1,
	})

	local ok, reason = promotionService:CheckAndPromote(110)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "reputation below threshold")
end)

--------------------------------------------------------------------------
-- Client cannot force promotion (no client-facing entry point)
--------------------------------------------------------------------------

testkit.test("CLIENT CANNOT FORCE PROMOTION: CheckAndPromote takes only a userId, nothing else", function()
	-- PromotionService's public surface never accepts a target rank, a
	-- performance/reputation value, or a threshold override from a
	-- caller - CheckAndPromote/GetStatus take only a userId, which is
	-- itself always the engine-verified player.UserId (see
	-- Bootstrap.server.lua and TaskService.lua's SECURITY MODEL comment).
	-- There is no method here shaped like "SetRank" or "ApplyPromotion"
	-- exposed on PromotionService itself.
	local promotionService = newHarness()
	testkit.assertEqual(type(promotionService.CheckAndPromote), "function")
	testkit.assertEqual(type(promotionService.GetStatus), "function")
	testkit.assertNil(promotionService.SetRank)
	testkit.assertNil(promotionService.ApplyPromotion)
	testkit.assertNil(promotionService.ForcePromotion)
end)

testkit.test("CLIENT CANNOT FORCE PROMOTION: fabricated extra arguments to CheckAndPromote have no effect", function()
	local promotionService, playerDataService = newHarness()
	playerDataService:LoadPlayer(111, SeedOrganizations.DEFAULT_ORG_ID)
	-- No Performance/Reputation earned at all.
	local ok = promotionService:CheckAndPromote(111, PlayerDataSchema.RANK.MANAGER, 999999, 999999)
	testkit.assertFalse(ok)
	testkit.assertEqual(playerDataService:GetLoadedRecord(111).Rank, PlayerDataSchema.RANK.ASSOCIATE)
end)

--------------------------------------------------------------------------
-- Persistence: promoted rank survives leave -> rejoin
--------------------------------------------------------------------------

testkit.test("PERSISTENCE: Associate -> Manager survives leave -> rejoin", function()
	local playerStore = FakeDataStore.new()
	local orgStore = FakeDataStore.new()
	local promotionService, playerDataService = newHarness(playerStore, orgStore)

	playerDataService:LoadPlayer(112, SeedOrganizations.DEFAULT_ORG_ID)
	playerDataService:ApplyTaskCompletion(112, {
		MoneyGain = 0,
		PerformanceGain = CONFIG.PerformanceThreshold,
		ReputationGain = CONFIG.ReputationThreshold,
	})
	local promOk = promotionService:CheckAndPromote(112)
	testkit.assertTrue(promOk)

	playerDataService:SavePlayer(112, { release = true })

	local secondPlayerDataService = select(2, newHarness(playerStore, orgStore))
	local ok, session = secondPlayerDataService:LoadPlayer(112, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok, tostring(session))
	testkit.assertEqual(session.record.Rank, PlayerDataSchema.RANK.MANAGER)
end)

testkit.test("no active session: both GetStatus and CheckAndPromote fail safely", function()
	local promotionService = newHarness()
	local ok1, err1 = promotionService:GetStatus(999)
	testkit.assertFalse(ok1)
	testkit.assertNotNil(err1)

	local ok2, err2 = promotionService:CheckAndPromote(999)
	testkit.assertFalse(ok2)
	testkit.assertNotNil(err2)
end)
