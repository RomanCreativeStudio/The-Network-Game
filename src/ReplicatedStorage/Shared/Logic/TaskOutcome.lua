--[[
	TaskOutcome - pure task-outcome resolution logic
	(docs/technical-architecture-v0.1.md §10, §18).

	Pure logic module: no Roblox service calls, no `require`, no client
	input of any kind - the server is the sole computer of outcome
	rewards, always derived from a task/choice DEFINITION plus a
	server-generated roll, never from anything a client sends
	(docs/mvp-definition-v0.1.md's security requirements: the client must
	never determine reward, performance, reputation, or quality values).

	Phase 2: resolves a CHOICE (one of a task definition's Choices) into
	its realized outcome. Where a choice has a single Weight=100 outcome
	(the "careful"/"quick" choices), this is fully deterministic - the
	roll is irrelevant. Where a choice has multiple weighted outcomes
	(the "cut_corners" choice), the roll (an integer in [1,100], always
	supplied by the caller - see TaskService) selects which one occurred,
	via WeightedOutcome.Pick's bounded, explainable bucketing.
]]

local TaskOutcome = {}

--[[
	Resolves `choice` (a TaskDefinitions choice entry, with an Outcomes
	list) into its realized outcome, using `roll` (an integer, expected
	to be in [1, WeightedOutcome.TotalWeight(choice.Outcomes)] - by
	convention in this codebase, weights sum to 100 and roll comes from
	math.random(1, 100)) to select among multiple possible outcomes.

	`weightedOutcome` is the WeightedOutcome logic module, passed in
	explicitly so this module has zero internal `require` calls (see
	technical-architecture-v0.1.md §18) - callers always pass the real
	Shared/Logic/WeightedOutcome.lua module.

	Returns:
	{
		ChoiceId = string,
		ResultLabel = string,   -- narrates what happened, shown to the player
		QualityScore = number,  -- Phase 2's TaskQualityScore-equivalent metric
		MoneyGain = number,
		PerformanceGain = number,
		ReputationGain = number,
	}
]]
function TaskOutcome.Resolve(choice, roll, weightedOutcome)
	assert(type(choice) == "table", "choice must be a table")
	assert(type(choice.ChoiceId) == "string" and #choice.ChoiceId > 0, "choice.ChoiceId must be a non-empty string")
	assert(type(choice.Outcomes) == "table" and #choice.Outcomes > 0, "choice.Outcomes must be a non-empty array")
	assert(type(roll) == "number", "roll must be a number")
	assert(type(weightedOutcome) == "table" and type(weightedOutcome.Pick) == "function", "weightedOutcome module required")

	local outcome = weightedOutcome.Pick(choice.Outcomes, roll)

	assert(type(outcome.MoneyGain) == "number", "outcome.MoneyGain must be a number")
	assert(type(outcome.PerformanceGain) == "number", "outcome.PerformanceGain must be a number")
	assert(type(outcome.ReputationGain) == "number", "outcome.ReputationGain must be a number")
	assert(type(outcome.QualityScore) == "number", "outcome.QualityScore must be a number")

	return {
		ChoiceId = choice.ChoiceId,
		ResultLabel = outcome.Label,
		QualityScore = outcome.QualityScore,
		MoneyGain = outcome.MoneyGain,
		PerformanceGain = outcome.PerformanceGain,
		ReputationGain = outcome.ReputationGain,
	}
end

return TaskOutcome
