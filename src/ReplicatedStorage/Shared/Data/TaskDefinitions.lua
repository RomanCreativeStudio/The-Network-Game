--[[
	TaskDefinitions - static, server-authoritative Task content
	(docs/technical-architecture-v0.1.md §10; docs/mvp-definition-v0.1.md §4).

	Pure static data module: no Roblox service calls, no `require`.

	Phase 1 scope: exactly ONE task, with NO player decision - its purpose
	is to validate the client -> server -> validation -> execution ->
	result -> persistence pipeline, not to finalize gameplay content (see
	the Phase 1 task brief). Real decision points, multiple task types,
	and the actual Economy Spec §5.1 Performance formula are explicitly
	Post-Phase-1.

	Reward values here (MoneyGain/PerformanceGain) are illustrative
	placeholders, not tuned numbers - consistent with the Economy and
	Progression Specifications leaving exact formulas/thresholds open.
]]

local TaskDefinitions = {}

TaskDefinitions.DEFAULT_TASK_ID = "task_file_the_report_001"

TaskDefinitions.List = {
	{
		TaskId = "task_file_the_report_001",
		Name = "File the Report",
		-- Phase 1 has no decision, so there is exactly one fixed outcome
		-- for this task - see Shared/Logic/TaskOutcome.lua, which is the
		-- seam Phase 2's real decision-point/quality-scoring logic will
		-- extend.
		MoneyGain = 10,
		PerformanceGain = 1,
	},
}

--[[
	Looks up a task definition by TaskId. Returns the definition table, or
	nil if taskId does not correspond to a known task.
]]
function TaskDefinitions.FindById(taskId)
	for _, definition in ipairs(TaskDefinitions.List) do
		if definition.TaskId == taskId then
			return definition
		end
	end
	return nil
end

return TaskDefinitions
