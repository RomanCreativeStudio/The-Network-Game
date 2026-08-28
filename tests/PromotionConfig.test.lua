local testkit = _G.testkit or dofile("tests/testkit.lua")
local PromotionConfig = dofile("src/ReplicatedStorage/Shared/Data/PromotionConfig.lua")

testkit.suite("PromotionConfig")

testkit.test("ASSOCIATE_TO_MANAGER defines numeric, positive thresholds", function()
	local config = PromotionConfig.ASSOCIATE_TO_MANAGER
	testkit.assertTrue(type(config.PerformanceThreshold) == "number" and config.PerformanceThreshold > 0)
	testkit.assertTrue(type(config.ReputationThreshold) == "number" and config.ReputationThreshold > 0)
end)

testkit.test("ASSOCIATE_TO_MANAGER has no MoneyThreshold field at all (locked: Money never gates promotion)", function()
	testkit.assertNil(PromotionConfig.ASSOCIATE_TO_MANAGER.MoneyThreshold)
end)

testkit.test("ASSOCIATE_TO_MANAGER falls within the Phase 3A calibration report's proposed ranges", function()
	-- PLAYTEST CALIBRATION cross-check, not a locked requirement: the
	-- Phase 3A report proposed Performance 8-14 and Reputation 4-7 as a
	-- starting range to playtest against.
	local config = PromotionConfig.ASSOCIATE_TO_MANAGER
	testkit.assertTrue(config.PerformanceThreshold >= 8 and config.PerformanceThreshold <= 14)
	testkit.assertTrue(config.ReputationThreshold >= 4 and config.ReputationThreshold <= 7)
end)
