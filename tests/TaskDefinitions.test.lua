local testkit = _G.testkit or dofile("tests/testkit.lua")
local TaskDefinitions = dofile("src/ReplicatedStorage/Shared/Data/TaskDefinitions.lua")

testkit.suite("TaskDefinitions")

testkit.test("exactly one task is defined in Phase 1", function()
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

testkit.test("every task definition has valid reward fields", function()
	for _, def in ipairs(TaskDefinitions.List) do
		testkit.assertTrue(type(def.TaskId) == "string" and #def.TaskId > 0)
		testkit.assertTrue(type(def.Name) == "string" and #def.Name > 0)
		testkit.assertTrue(type(def.MoneyGain) == "number" and def.MoneyGain >= 0)
		testkit.assertTrue(type(def.PerformanceGain) == "number" and def.PerformanceGain >= 0)
	end
end)
