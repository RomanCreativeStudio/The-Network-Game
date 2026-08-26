local testkit = _G.testkit or dofile("tests/testkit.lua")
local ActionRateLimiter = dofile("src/ReplicatedStorage/Shared/Logic/ActionRateLimiter.lua")

testkit.suite("ActionRateLimiter")

testkit.test("allows a first action with no prior timestamp", function()
	testkit.assertTrue(ActionRateLimiter.ShouldAllow(nil, 1000))
end)

testkit.test("allows an action once the interval has elapsed", function()
	local allowed = ActionRateLimiter.ShouldAllow(1000, 1000 + ActionRateLimiter.MIN_INTERVAL_SECONDS, nil)
	testkit.assertTrue(allowed)
end)

testkit.test("refuses an action within the interval", function()
	local allowed = ActionRateLimiter.ShouldAllow(1000, 1000.1, nil)
	testkit.assertFalse(allowed)
end)

testkit.test("respects a custom interval", function()
	testkit.assertFalse(ActionRateLimiter.ShouldAllow(1000, 1004, 5))
	testkit.assertTrue(ActionRateLimiter.ShouldAllow(1000, 1005, 5))
end)
