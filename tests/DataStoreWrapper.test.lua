local testkit = _G.testkit or dofile("tests/testkit.lua")
local RetryPolicy = dofile("src/ReplicatedStorage/Shared/Logic/RetryPolicy.lua")
local DataStoreWrapper = dofile("src/ServerScriptService/Server/DataStoreWrapper.lua")
local FakeDataStore = dofile("tests/fakes/FakeDataStore.lua")

testkit.suite("DataStoreWrapper")

testkit.test("Get succeeds immediately when the store is healthy", function()
	local store = FakeDataStore.new()
	local wrapper = DataStoreWrapper.new({ retryPolicy = RetryPolicy, wait = function() end })
	local ok, result = wrapper:Get(store, "missing-key")
	testkit.assertTrue(ok)
	testkit.assertNil(result)
end)

testkit.test("Set then Get roundtrips a value", function()
	local store = FakeDataStore.new()
	local wrapper = DataStoreWrapper.new({ retryPolicy = RetryPolicy, wait = function() end })
	local setOk = wrapper:Set(store, "key-1", { hello = "world" })
	testkit.assertTrue(setOk)
	local getOk, value = wrapper:Get(store, "key-1")
	testkit.assertTrue(getOk)
	testkit.assertEqual(value.hello, "world")
end)

testkit.test("retries a transient failure and eventually succeeds", function()
	local store = FakeDataStore.new({ failuresRemaining = 2 })
	local waitCalls = 0
	local wrapper = DataStoreWrapper.new({
		retryPolicy = RetryPolicy,
		wait = function()
			waitCalls = waitCalls + 1
		end,
		maxAttempts = 5,
	})
	local ok = wrapper:Get(store, "key-1")
	testkit.assertTrue(ok)
	testkit.assertEqual(waitCalls, 2)
end)

testkit.test("gives up after maxAttempts and returns failure", function()
	local store = FakeDataStore.new({ failuresRemaining = 10 })
	local wrapper = DataStoreWrapper.new({
		retryPolicy = RetryPolicy,
		wait = function() end,
		maxAttempts = 3,
	})
	local ok, err = wrapper:Get(store, "key-1")
	testkit.assertFalse(ok)
	testkit.assertNotNil(err)
	testkit.assertEqual(store:CallCount(), 3)
end)

testkit.test("Update performs a read-modify-write", function()
	local store = FakeDataStore.new()
	local wrapper = DataStoreWrapper.new({ retryPolicy = RetryPolicy, wait = function() end })
	wrapper:Set(store, "counter", 1)
	local ok, result = wrapper:Update(store, "counter", function(old)
		return (old or 0) + 1
	end)
	testkit.assertTrue(ok)
	testkit.assertEqual(result, 2)
end)

testkit.test("Update aborts the write when the transform returns nil", function()
	local store = FakeDataStore.new()
	local wrapper = DataStoreWrapper.new({ retryPolicy = RetryPolicy, wait = function() end })
	wrapper:Set(store, "counter", 5)
	wrapper:Update(store, "counter", function(_old)
		return nil -- abort
	end)
	testkit.assertEqual(store:RawGet("counter"), 5) -- unchanged
end)

testkit.test("does not retry a call that succeeds on the first attempt", function()
	local store = FakeDataStore.new()
	local wrapper = DataStoreWrapper.new({ retryPolicy = RetryPolicy, wait = function() end })
	wrapper:Get(store, "key-1")
	testkit.assertEqual(store:CallCount(), 1)
end)
