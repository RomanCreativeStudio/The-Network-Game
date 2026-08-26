--[[
	TaskOutcome - pure task-outcome resolution logic
	(docs/technical-architecture-v0.1.md §10, §18).

	Pure logic module: no Roblox service calls, no `require`, no client
	input of any kind - the server is the sole computer of outcome
	rewards, always derived from a task DEFINITION, never from anything a
	client sends (docs/mvp-definition-v0.1.md's Phase 1 security
	requirements: the client must never determine reward or performance
	amounts).

	Phase 1's single task has no decision point, so Resolve() is a fixed
	echo of the definition's reward fields today. This module exists as
	its own tested seam specifically because Phase 2 will replace its
	insides (decision-quality scoring, Economy Spec §5.1's real formula)
	without needing to touch TaskService's orchestration logic around it.
]]

local TaskOutcome = {}

--[[
	Resolves the reward for completing `definition` (a TaskDefinitions
	entry). Returns { MoneyGain = number, PerformanceGain = number }.

	Phase 1 takes no other arguments (no decision/choice input exists
	yet) - Resolve is still written to take the definition rather than a
	raw taskId so it stays a pure function of known-server-side data only.
]]
function TaskOutcome.Resolve(definition)
	assert(type(definition) == "table", "definition must be a table")
	assert(type(definition.MoneyGain) == "number", "definition.MoneyGain must be a number")
	assert(type(definition.PerformanceGain) == "number", "definition.PerformanceGain must be a number")

	return {
		MoneyGain = definition.MoneyGain,
		PerformanceGain = definition.PerformanceGain,
	}
end

return TaskOutcome
