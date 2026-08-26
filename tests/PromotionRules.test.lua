local testkit = _G.testkit or dofile("tests/testkit.lua")
local PromotionRules = dofile("src/ReplicatedStorage/Shared/Logic/PromotionRules.lua")

testkit.suite("PromotionRules")

local config = { PerformanceThreshold = 10, ReputationThreshold = 5 }

testkit.test("MeetsThresholds passes when both requirements are exceeded", function()
	testkit.assertTrue(PromotionRules.MeetsThresholds(20, 10, config))
end)

testkit.test("MeetsThresholds passes when both requirements are EXACTLY at threshold", function()
	testkit.assertTrue(PromotionRules.MeetsThresholds(10, 5, config))
end)

testkit.test("MeetsThresholds fails when performance is below threshold (even if Reputation is fine)", function()
	local ok, reason = PromotionRules.MeetsThresholds(9, 100, config)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "performance below threshold")
end)

testkit.test("MeetsThresholds fails when reputation is below threshold (even if Performance is fine)", function()
	local ok, reason = PromotionRules.MeetsThresholds(100, 4, config)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "reputation below threshold")
end)

testkit.test("MeetsThresholds fails when both are below threshold", function()
	local ok = PromotionRules.MeetsThresholds(0, 0, config)
	testkit.assertFalse(ok)
end)

testkit.test("MeetsThresholds fails one below by a fraction of a point (boundary just under)", function()
	local ok = PromotionRules.MeetsThresholds(9.99, 5, config)
	testkit.assertFalse(ok)
end)

testkit.test("MeetsThresholds treats negative Reputation as below any positive threshold", function()
	local ok, reason = PromotionRules.MeetsThresholds(50, -3, config)
	testkit.assertFalse(ok)
	testkit.assertEqual(reason, "reputation below threshold")
end)

testkit.test("MeetsThresholds rejects a malformed config", function()
	local ok1 = pcall(PromotionRules.MeetsThresholds, 10, 5, {})
	testkit.assertFalse(ok1)
	local ok2 = pcall(PromotionRules.MeetsThresholds, 10, 5, nil)
	testkit.assertFalse(ok2)
end)

testkit.test("MeetsThresholds rejects non-numeric performance/reputation", function()
	local ok1 = pcall(PromotionRules.MeetsThresholds, "10", 5, config)
	testkit.assertFalse(ok1)
	local ok2 = pcall(PromotionRules.MeetsThresholds, 10, "5", config)
	testkit.assertFalse(ok2)
end)
