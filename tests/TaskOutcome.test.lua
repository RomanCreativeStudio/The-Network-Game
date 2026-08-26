local testkit = _G.testkit or dofile("tests/testkit.lua")
local TaskOutcome = dofile("src/ReplicatedStorage/Shared/Logic/TaskOutcome.lua")
local WeightedOutcome = dofile("src/ReplicatedStorage/Shared/Logic/WeightedOutcome.lua")
local TaskDefinitions = dofile("src/ReplicatedStorage/Shared/Data/TaskDefinitions.lua")

testkit.suite("TaskOutcome")

local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)

testkit.test("Resolve a deterministic (Weight=100) choice ignores the roll", function()
	local choice = TaskDefinitions.FindChoice(definition, "careful")
	local a = TaskOutcome.Resolve(choice, 1, WeightedOutcome)
	local b = TaskOutcome.Resolve(choice, 100, WeightedOutcome)
	testkit.assertEqual(a.MoneyGain, b.MoneyGain)
	testkit.assertEqual(a.PerformanceGain, b.PerformanceGain)
	testkit.assertEqual(a.ReputationGain, b.ReputationGain)
	testkit.assertEqual(a.QualityScore, b.QualityScore)
end)

testkit.test("Resolve returns the ChoiceId it was given", function()
	local choice = TaskDefinitions.FindChoice(definition, "quick")
	local result = TaskOutcome.Resolve(choice, 1, WeightedOutcome)
	testkit.assertEqual(result.ChoiceId, "quick")
end)

testkit.test("Resolve a weighted choice picks the success branch on a low roll", function()
	local choice = TaskDefinitions.FindChoice(definition, "cut_corners")
	local result = TaskOutcome.Resolve(choice, 1, WeightedOutcome) -- within the 60% success bucket
	testkit.assertTrue(result.MoneyGain > 0)
	testkit.assertTrue(result.PerformanceGain > 0)
	testkit.assertTrue(result.ReputationGain >= 0)
end)

testkit.test("Resolve a weighted choice picks the backfire branch on a high roll", function()
	local choice = TaskDefinitions.FindChoice(definition, "cut_corners")
	local result = TaskOutcome.Resolve(choice, 100, WeightedOutcome) -- within the 40% backfire bucket
	testkit.assertTrue(result.PerformanceGain < 0)
	testkit.assertTrue(result.ReputationGain < 0)
end)

testkit.test("Resolve includes a human-readable ResultLabel and a QualityScore", function()
	local choice = TaskDefinitions.FindChoice(definition, "careful")
	local result = TaskOutcome.Resolve(choice, 1, WeightedOutcome)
	testkit.assertTrue(type(result.ResultLabel) == "string" and #result.ResultLabel > 0)
	testkit.assertTrue(type(result.QualityScore) == "number")
end)

testkit.test("Resolve rejects a choice with no Outcomes", function()
	local ok = pcall(TaskOutcome.Resolve, { ChoiceId = "x", Outcomes = {} }, 1, WeightedOutcome)
	testkit.assertFalse(ok)
end)

testkit.test("Resolve rejects a malformed outcome (missing reward fields)", function()
	local badChoice = { ChoiceId = "x", Outcomes = { { Weight = 100, Label = "bad" } } }
	local ok = pcall(TaskOutcome.Resolve, badChoice, 1, WeightedOutcome)
	testkit.assertFalse(ok)
end)
