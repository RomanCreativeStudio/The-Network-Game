local testkit = _G.testkit or dofile("tests/testkit.lua")
local WeightedOutcome = dofile("src/ReplicatedStorage/Shared/Logic/WeightedOutcome.lua")

testkit.suite("WeightedOutcome")

testkit.test("TotalWeight sums a single-outcome list", function()
	testkit.assertEqual(WeightedOutcome.TotalWeight({ { Weight = 100 } }), 100)
end)

testkit.test("TotalWeight sums a multi-outcome list", function()
	testkit.assertEqual(WeightedOutcome.TotalWeight({ { Weight = 60 }, { Weight = 40 } }), 100)
end)

testkit.test("Pick returns the only outcome for a single-outcome (Weight=100) list regardless of roll", function()
	local outcomes = { { Weight = 100, Label = "only" } }
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 1).Label, "only")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 100).Label, "only")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 50).Label, "only")
end)

testkit.test("Pick selects the first bucket at its lower and upper boundary", function()
	local outcomes = { { Weight = 60, Label = "first" }, { Weight = 40, Label = "second" } }
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 1).Label, "first")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 60).Label, "first")
end)

testkit.test("Pick selects the second bucket immediately past the first boundary and at the top", function()
	local outcomes = { { Weight = 60, Label = "first" }, { Weight = 40, Label = "second" } }
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 61).Label, "second")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 100).Label, "second")
end)

testkit.test("Pick falls back to the last outcome for an out-of-range roll", function()
	local outcomes = { { Weight = 60, Label = "first" }, { Weight = 40, Label = "second" } }
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 9999).Label, "second")
end)

testkit.test("Pick works with three unevenly weighted outcomes", function()
	local outcomes = { { Weight = 10, Label = "a" }, { Weight = 30, Label = "b" }, { Weight = 60, Label = "c" } }
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 5).Label, "a")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 10).Label, "a")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 11).Label, "b")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 40).Label, "b")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 41).Label, "c")
	testkit.assertEqual(WeightedOutcome.Pick(outcomes, 100).Label, "c")
end)

testkit.test("TotalWeight rejects a non-positive weight", function()
	local ok = pcall(WeightedOutcome.TotalWeight, { { Weight = 0 } })
	testkit.assertFalse(ok)
end)
