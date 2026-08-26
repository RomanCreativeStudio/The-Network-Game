--[[
	TaskDefinitions - static, server-authoritative Task content
	(docs/technical-architecture-v0.1.md §10; docs/mvp-definition-v0.1.md §4).

	Pure static data module: no Roblox service calls, no `require`.

	Phase 2 scope: still exactly ONE task, but it now carries a real
	decision - 2-3 choices, each with a clearly described consequence.
	Per the Phase 2 design principle, the point is to TEACH the loop
	(Task -> Decision -> Outcome -> Performance/Money/Reputation), not to
	overwhelm - so two of the three choices are fully deterministic (no
	randomness at all), and the one risky choice uses a small, explicit,
	labeled probability rather than a hidden roll.

	Every choice's Outcomes list carries integer Weights that sum to
	exactly 100 (percentage points) - see Shared/Logic/WeightedOutcome.lua
	for how a choice is resolved and Shared/Logic/ChoicePreview.lua for
	how this is safely shown to the player before they decide.

	Reward values (MoneyGain/PerformanceGain/ReputationGain/QualityScore)
	are illustrative placeholders, not tuned numbers - consistent with
	the Economy and Progression Specifications leaving exact formulas/
	thresholds open. QualityScore is Phase 2's "TaskQualityScore or
	equivalent outcome metric": a labeled 0-100 read on how well the task
	went, distinct from (and simpler than) the Economy Specification's
	full rolling-average Performance formula (§5.1), which remains a
	Post-Phase-2 numeric-tuning decision.
]]

local TaskDefinitions = {}

TaskDefinitions.DEFAULT_TASK_ID = "task_file_the_report_001"

TaskDefinitions.List = {
	{
		TaskId = "task_file_the_report_001",
		Name = "File the Report",
		Prompt = "A client report is due. How do you want to handle it?",
		Choices = {
			{
				ChoiceId = "careful",
				Label = "File it thoroughly",
				Description = "Take your time and get every detail right. Slower, but reliable - guaranteed solid results.",
				Outcomes = {
					{
						Weight = 100,
						Label = "You took your time and it shows. Solid, dependable work.",
						QualityScore = 100,
						MoneyGain = 10,
						PerformanceGain = 2,
						ReputationGain = 1,
					},
				},
			},
			{
				ChoiceId = "quick",
				Label = "File it quickly",
				Description = "Get it done fast and move on. Smaller reward, but no real downside.",
				Outcomes = {
					{
						Weight = 100,
						Label = "Filed on time. Nothing special, but it's done.",
						QualityScore = 70,
						MoneyGain = 6,
						PerformanceGain = 1,
						ReputationGain = 0,
					},
				},
			},
			{
				ChoiceId = "cut_corners",
				Label = "Cut corners to impress the boss",
				Description = "Skip the parts nobody checks and oversell the results. High risk, high reward: "
					.. "about a 60% chance it pays off big, 40% chance it backfires and costs you reputation.",
				Outcomes = {
					{
						Weight = 60,
						Label = "It worked - the boss is impressed and nobody noticed the shortcuts.",
						QualityScore = 90,
						MoneyGain = 18,
						PerformanceGain = 3,
						ReputationGain = 1,
					},
					{
						Weight = 40,
						Label = "It backfired - people noticed the corners you cut.",
						QualityScore = 20,
						MoneyGain = 2,
						PerformanceGain = -1,
						ReputationGain = -2,
					},
				},
			},
		},
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

--[[
	Looks up a choice within a given task definition by ChoiceId. Returns
	the choice table, or nil if choiceId is not one of `definition`'s
	known choices (including if `definition` has no Choices at all).
]]
function TaskDefinitions.FindChoice(definition, choiceId)
	if type(definition) ~= "table" or type(definition.Choices) ~= "table" then
		return nil
	end
	for _, choice in ipairs(definition.Choices) do
		if choice.ChoiceId == choiceId then
			return choice
		end
	end
	return nil
end

return TaskDefinitions
