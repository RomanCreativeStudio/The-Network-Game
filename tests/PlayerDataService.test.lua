--[[
	Integration tests for PlayerDataService, wired to a real
	OrganizationService and DataStoreWrapper but a fake DataStore - this
	is what directly exercises Phase 0's success criteria:
	join / default data / seeded org / leave / save / rejoin / recover,
	plus the "must not silently misbehave" checks (duplicate/invalid data,
	retry, no stale overwrite).
]]

local testkit = _G.testkit or dofile("tests/testkit.lua")
local RetryPolicy = dofile("src/ReplicatedStorage/Shared/Logic/RetryPolicy.lua")
local SessionLock = dofile("src/ReplicatedStorage/Shared/Logic/SessionLock.lua")
local PlayerDataSchema = dofile("src/ReplicatedStorage/Shared/Types/PlayerData.lua")
local OrganizationDataSchema = dofile("src/ReplicatedStorage/Shared/Types/OrganizationData.lua")
local SeedOrganizations = dofile("src/ReplicatedStorage/Shared/Data/SeedOrganizations.lua")
local DataStoreWrapper = dofile("src/ServerScriptService/Server/DataStoreWrapper.lua")
local OrganizationService = dofile("src/ServerScriptService/Server/OrganizationService.lua")
local PlayerDataService = dofile("src/ServerScriptService/Server/PlayerDataService.lua")
local FakeDataStore = dofile("tests/fakes/FakeDataStore.lua")

testkit.suite("PlayerDataService (integration)")

local function newHarness(playerStore, orgStore, jobId, nowFn)
	playerStore = playerStore or FakeDataStore.new()
	orgStore = orgStore or FakeDataStore.new()
	local wrapper = DataStoreWrapper.new({ retryPolicy = RetryPolicy, wait = function() end })
	local orgService = OrganizationService.new({
		wrapper = wrapper,
		store = orgStore,
		schema = OrganizationDataSchema,
		seedOrganizations = SeedOrganizations,
	})
	local service = PlayerDataService.new({
		wrapper = wrapper,
		store = playerStore,
		organizationService = orgService,
		schema = PlayerDataSchema,
		sessionLock = SessionLock,
		jobId = jobId or "server-a",
		now = nowFn,
	})
	return service, playerStore, orgStore
end

testkit.test("join: a brand-new player receives valid default data and a real seeded org", function()
	local service = newHarness()
	local ok, session = service:LoadPlayer(111, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok, tostring(session))
	testkit.assertEqual(session.record.UserId, 111)
	testkit.assertEqual(session.record.OrgId, SeedOrganizations.DEFAULT_ORG_ID)
	local valid = PlayerDataSchema.Validate(session.record)
	testkit.assertTrue(valid)
	testkit.assertEqual(session.orgRecord.OrgId, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertEqual(session.orgRecord.Seeded, true)
end)

testkit.test("join -> leave -> rejoin recovers the same persistent state", function()
	local playerStore = FakeDataStore.new()
	local orgStore = FakeDataStore.new()
	local service = newHarness(playerStore, orgStore)

	local ok1 = service:LoadPlayer(222, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok1)

	-- Phase 0 itself never mutates PersonalMoney (no gameplay is
	-- implemented yet); we set it directly here purely to prove the
	-- round-trip actually persists whatever is in memory at save time.
	local record = service:GetLoadedRecord(222)
	record.PersonalMoney = 42

	local saveOk = service:SavePlayer(222, { release = true })
	testkit.assertTrue(saveOk)
	testkit.assertNil(service:GetLoadedRecord(222), "record should be cleared from memory after release")

	-- Rejoin: a brand-new service instance simulates a fresh server
	-- reading back from the same underlying stores.
	local secondService = newHarness(playerStore, orgStore)
	local ok2, session2 = secondService:LoadPlayer(222, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok2, tostring(session2))
	testkit.assertEqual(session2.record.PersonalMoney, 42)
	testkit.assertEqual(session2.record.UserId, 222)
end)

testkit.test("a second concurrent session cannot load the same player while the lock is held", function()
	local playerStore = FakeDataStore.new()
	local orgStore = FakeDataStore.new()
	local serverA = newHarness(playerStore, orgStore, "server-a")
	local serverB = newHarness(playerStore, orgStore, "server-b")

	local okA = serverA:LoadPlayer(333, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(okA)

	local okB, errB = serverB:LoadPlayer(333, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertFalse(okB)
	testkit.assertNotNil(errB)
end)

testkit.test("a stale abandoned lock can be reclaimed, and the old owner's late save is rejected", function()
	local playerStore = FakeDataStore.new()
	local orgStore = FakeDataStore.new()
	local clock = { t = 1000 }
	local function nowFn()
		return clock.t
	end

	local serverA = newHarness(playerStore, orgStore, "server-a", nowFn)
	local okA = serverA:LoadPlayer(444, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(okA)
	-- Server A "crashes" here: it never calls SavePlayer/releases the lock.

	clock.t = clock.t + SessionLock.STALE_AFTER_SECONDS + 10

	local serverB = newHarness(playerStore, orgStore, "server-b", nowFn)
	local okB = serverB:LoadPlayer(444, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(okB, "server B should be able to reclaim the stale lock")

	serverB:GetLoadedRecord(444).PersonalMoney = 999
	local saveBOk = serverB:SavePlayer(444, { release = false })
	testkit.assertTrue(saveBOk)

	-- Server A finally "wakes up" and tries to save its old in-memory
	-- copy. Its lock token no longer matches what's stored, so the save
	-- must be rejected, not silently allowed to clobber server B's data.
	local staleOk, staleErr = serverA:SavePlayer(444, { release = true })
	testkit.assertFalse(staleOk)
	testkit.assertNotNil(staleErr)

	-- The persisted record must still reflect server B's write.
	local finalRecord = playerStore:RawGet("Player_444")
	testkit.assertEqual(finalRecord.PersonalMoney, 999)
end)

testkit.test("corrupt existing player data is rejected, not silently repaired", function()
	local playerStore = FakeDataStore.new()
	playerStore:RawSet("Player_555", { garbage = true })
	local orgStore = FakeDataStore.new()
	local service = newHarness(playerStore, orgStore)

	local ok, err = service:LoadPlayer(555, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)
end)

testkit.test("a load that fails to load its organization releases its session lock", function()
	local playerStore = FakeDataStore.new()
	-- The org store fails every call (exhausts DataStoreWrapper's
	-- retries), simulating a transient organization-load failure rather
	-- than an unseeded/invalid orgId - the player's own OrgId stays
	-- valid throughout, which is what makes a same-orgId retry the right
	-- test of "did the lock get released" in isolation.
	local orgStore = FakeDataStore.new({ failuresRemaining = 100 })
	local service = newHarness(playerStore, orgStore)

	local ok, err = service:LoadPlayer(666, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)

	-- Simulate the DataStore recovering, then retry with the same valid
	-- seeded org. The lock must have been released on the failed attempt,
	-- so this succeeds instead of reporting itself locked out by its own
	-- abandoned first claim.
	orgStore._failuresRemaining = 0
	local ok2 = service:LoadPlayer(666, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok2)
end)

testkit.test("saves survive transient DataStore failures via retry", function()
	local playerStore = FakeDataStore.new()
	local orgStore = FakeDataStore.new()
	local service = newHarness(playerStore, orgStore)
	service:LoadPlayer(777, SeedOrganizations.DEFAULT_ORG_ID)

	-- Inject transient failures right before saving.
	playerStore._failuresRemaining = 2

	local ok = service:SavePlayer(777, { release = true })
	testkit.assertTrue(ok)
end)

testkit.test("loads survive transient DataStore failures via retry", function()
	local playerStore = FakeDataStore.new({ failuresRemaining = 2 })
	local orgStore = FakeDataStore.new()
	local service = newHarness(playerStore, orgStore)

	local ok = service:LoadPlayer(888, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok)
end)

testkit.test("SavePlayer on a user with no active session fails safely", function()
	local service = newHarness()
	local ok, err = service:SavePlayer(999, { release = true })
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)
end)

testkit.test("clients cannot mutate persistent state: no client-facing entry point exists", function()
	-- Phase 0 intentionally exposes no RemoteEvent/RemoteFunction (see
	-- Bootstrap.server.lua), and PlayerDataService's public surface only
	-- ever takes a Roblox UserId plus server-known parameters - never an
	-- arbitrary client-supplied state/reward payload. This test documents
	-- that contract at the API-surface level.
	local service = newHarness()
	testkit.assertEqual(type(service.LoadPlayer), "function")
	testkit.assertEqual(type(service.SavePlayer), "function")
	testkit.assertNil(service.SetPlayerData)
	testkit.assertNil(service.ApplyClientState)
end)
