local testkit = _G.testkit or dofile("tests/testkit.lua")
local TaskOutcome = dofile("src/ReplicatedStorage/Shared/Logic/TaskOutcome.lua")

testkit.suite("TaskOutcome")

testkit.test("Resolve echoes the definition's reward fields", function()
	local result = TaskOutcome.Resolve({ MoneyGain = 10, PerformanceGain = 1 })
	testkit.assertEqual(result.MoneyGain, 10)
	testkit.assertEqual(result.PerformanceGain, 1)
end)

testkit.test("Resolve rejects a malformed definition", function()
	local ok = pcall(TaskOutcome.Resolve, { MoneyGain = "not a number", PerformanceGain = 1 })
	testkit.assertFalse(ok)
end)

testkit.test("Resolve never reads fields beyond MoneyGain/PerformanceGain", function()
	-- Documents the security invariant: even if a definition-shaped table
	-- somehow carried extra attacker-influenced fields, Resolve only ever
	-- reads the two reward fields it's contracted to.
	local result = TaskOutcome.Resolve({ MoneyGain = 5, PerformanceGain = 2, Extra = "ignored" })
	testkit.assertEqual(result.MoneyGain, 5)
	testkit.assertEqual(result.PerformanceGain, 2)
	testkit.assertNil(result.Extra)
end)
