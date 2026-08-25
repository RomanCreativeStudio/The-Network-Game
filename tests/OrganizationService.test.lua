local testkit = _G.testkit or dofile("tests/testkit.lua")
local RetryPolicy = dofile("src/ReplicatedStorage/Shared/Logic/RetryPolicy.lua")
local DataStoreWrapper = dofile("src/ServerScriptService/Server/DataStoreWrapper.lua")
local OrganizationDataSchema = dofile("src/ReplicatedStorage/Shared/Types/OrganizationData.lua")
local SeedOrganizations = dofile("src/ReplicatedStorage/Shared/Data/SeedOrganizations.lua")
local OrganizationService = dofile("src/ServerScriptService/Server/OrganizationService.lua")
local FakeDataStore = dofile("tests/fakes/FakeDataStore.lua")

testkit.suite("OrganizationService")

local function newService(store)
	local wrapper = DataStoreWrapper.new({ retryPolicy = RetryPolicy, wait = function() end })
	return OrganizationService.new({
		wrapper = wrapper,
		store = store or FakeDataStore.new(),
		schema = OrganizationDataSchema,
		seedOrganizations = SeedOrganizations,
	})
end

testkit.test("creates a seeded organization on first load", function()
	local store = FakeDataStore.new()
	local service = newService(store)
	local ok, record = service:GetOrCreateOrganization(SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok, tostring(record))
	testkit.assertEqual(record.OrgId, SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertEqual(record.Seeded, true)
	-- persisted for real, not just cached in memory
	testkit.assertNotNil(store:RawGet(SeedOrganizations.DEFAULT_ORG_ID))
end)

testkit.test("loads an existing organization record without recreating it", function()
	local store = FakeDataStore.new()
	local service = newService(store)
	local _ok, first = service:GetOrCreateOrganization(SeedOrganizations.DEFAULT_ORG_ID)
	first.MemberCount = 7
	store:RawSet(SeedOrganizations.DEFAULT_ORG_ID, first)

	local freshService = newService(store) -- new instance, empty in-memory cache
	local ok, record = freshService:GetOrCreateOrganization(SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok)
	testkit.assertEqual(record.MemberCount, 7)
end)

testkit.test("rejects an unknown, unseeded orgId", function()
	local service = newService()
	local ok, err = service:GetOrCreateOrganization("not-a-real-org")
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)
end)

testkit.test("rejects an empty orgId", function()
	local service = newService()
	local ok, err = service:GetOrCreateOrganization("")
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)
end)

testkit.test("rejects a corrupt existing organization record", function()
	local store = FakeDataStore.new()
	store:RawSet(SeedOrganizations.DEFAULT_ORG_ID, { garbage = true })
	local service = newService(store)
	local ok, err = service:GetOrCreateOrganization(SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)
end)

testkit.test("caches the loaded record and does not re-hit the store", function()
	local store = FakeDataStore.new()
	local service = newService(store)
	service:GetOrCreateOrganization(SeedOrganizations.DEFAULT_ORG_ID)
	local callsAfterFirst = store:CallCount()
	service:GetOrCreateOrganization(SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertEqual(store:CallCount(), callsAfterFirst)
end)

testkit.test("survives a transient failure while creating a seeded org", function()
	local store = FakeDataStore.new({ failuresRemaining = 1 })
	local service = newService(store)
	local ok, record = service:GetOrCreateOrganization(SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertTrue(ok, tostring(record))
	testkit.assertEqual(record.OrgId, SeedOrganizations.DEFAULT_ORG_ID)
end)
