local testkit = _G.testkit or dofile("tests/testkit.lua")
local ChoicePreview = dofile("src/ReplicatedStorage/Shared/Logic/ChoicePreview.lua")
local TaskDefinitions = dofile("src/ReplicatedStorage/Shared/Data/TaskDefinitions.lua")

testkit.suite("ChoicePreview")

testkit.test("Build produces one preview entry per choice", function()
	local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	local preview = ChoicePreview.Build(definition)
	testkit.assertEqual(#preview, #definition.Choices)
end)

testkit.test("Build includes ChoiceId/Label/Description for each choice", function()
	local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	local preview = ChoicePreview.Build(definition)
	for i, entry in ipairs(preview) do
		testkit.assertEqual(entry.ChoiceId, definition.Choices[i].ChoiceId)
		testkit.assertEqual(entry.Label, definition.Choices[i].Label)
		testkit.assertEqual(entry.Description, definition.Choices[i].Description)
	end
end)

testkit.test("Build's per-outcome preview exposes Chance and the reward fields", function()
	local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	local preview = ChoicePreview.Build(definition)

	local cutCorners = nil
	for _, entry in ipairs(preview) do
		if entry.ChoiceId == "cut_corners" then
			cutCorners = entry
		end
	end
	testkit.assertNotNil(cutCorners)
	testkit.assertEqual(#cutCorners.Preview, 2)

	local totalChance = 0
	for _, outcome in ipairs(cutCorners.Preview) do
		totalChance = totalChance + outcome.Chance
		testkit.assertTrue(type(outcome.Label) == "string")
		testkit.assertTrue(type(outcome.MoneyGain) == "number")
		testkit.assertTrue(type(outcome.PerformanceGain) == "number")
		testkit.assertTrue(type(outcome.ReputationGain) == "number")
	end
	testkit.assertEqual(totalChance, 100)
end)

testkit.test("Build rejects a definition with no Choices", function()
	local ok = pcall(ChoicePreview.Build, { Choices = {} })
	testkit.assertFalse(ok)
end)
