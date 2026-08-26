local testkit = _G.testkit or dofile("tests/testkit.lua")
local TaskDefinitions = dofile("src/ReplicatedStorage/Shared/Data/TaskDefinitions.lua")

testkit.suite("TaskDefinitions")

testkit.test("exactly one task is defined in Phase 2", function()
	testkit.assertEqual(#TaskDefinitions.List, 1)
end)

testkit.test("DEFAULT_TASK_ID resolves to a known definition", function()
	local def = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	testkit.assertNotNil(def)
	testkit.assertEqual(def.TaskId, TaskDefinitions.DEFAULT_TASK_ID)
end)

testkit.test("FindById returns nil for an unknown id", function()
	testkit.assertNil(TaskDefinitions.FindById("not-a-real-task"))
end)

testkit.test("the default task has a Prompt and 2-3 choices", function()
	local def = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	testkit.assertTrue(type(def.Prompt) == "string" and #def.Prompt > 0)
	testkit.assertTrue(#def.Choices >= 2 and #def.Choices <= 3)
end)

testkit.test("every choice has a unique ChoiceId, Label, and Description", function()
	local def = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	local seen = {}
	for _, choice in ipairs(def.Choices) do
		testkit.assertTrue(type(choice.ChoiceId) == "string" and #choice.ChoiceId > 0)
		testkit.assertTrue(type(choice.Label) == "string" and #choice.Label > 0)
		testkit.assertTrue(type(choice.Description) == "string" and #choice.Description > 0)
		testkit.assertNil(seen[choice.ChoiceId], "duplicate ChoiceId: " .. tostring(choice.ChoiceId))
		seen[choice.ChoiceId] = true
	end
end)

testkit.test("every choice's outcome weights sum to exactly 100", function()
	local def = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	for _, choice in ipairs(def.Choices) do
		local total = 0
		for _, outcome in ipairs(choice.Outcomes) do
			total = total + outcome.Weight
		end
		testkit.assertEqual(total, 100, "choice " .. choice.ChoiceId .. " weights do not sum to 100")
	end
end)

testkit.test("every outcome has valid reward fields and a QualityScore", function()
	local def = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	for _, choice in ipairs(def.Choices) do
		for _, outcome in ipairs(choice.Outcomes) do
			testkit.assertTrue(type(outcome.Label) == "string" and #outcome.Label > 0)
			testkit.assertTrue(type(outcome.MoneyGain) == "number")
			testkit.assertTrue(type(outcome.PerformanceGain) == "number")
			testkit.assertTrue(type(outcome.ReputationGain) == "number")
			testkit.assertTrue(type(outcome.QualityScore) == "number")
			testkit.assertTrue(outcome.QualityScore >= 0 and outcome.QualityScore <= 100)
		end
	end
end)

testkit.test("at least one choice is fully deterministic (a single Weight=100 outcome)", function()
	local def = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	local hasDeterministic = false
	for _, choice in ipairs(def.Choices) do
		if #choice.Outcomes == 1 and choice.Outcomes[1].Weight == 100 then
			hasDeterministic = true
		end
	end
	testkit.assertTrue(hasDeterministic, "expected at least one deterministic choice per the Phase 2 design principle")
end)

testkit.test("FindChoice resolves a known choice on the default task", function()
	local def = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	local choice = TaskDefinitions.FindChoice(def, "careful")
	testkit.assertNotNil(choice)
	testkit.assertEqual(choice.ChoiceId, "careful")
end)

testkit.test("FindChoice returns nil for an unknown choice id", function()
	local def = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)
	testkit.assertNil(TaskDefinitions.FindChoice(def, "not-a-real-choice"))
end)

testkit.test("FindChoice returns nil for a nil/malformed definition", function()
	testkit.assertNil(TaskDefinitions.FindChoice(nil, "careful"))
	testkit.assertNil(TaskDefinitions.FindChoice({}, "careful"))
end)
