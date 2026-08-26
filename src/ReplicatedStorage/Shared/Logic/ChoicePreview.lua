--[[
	ChoicePreview - pure builder for the client-facing "what are my
	choices and their consequences" payload (Phase 2 design principle:
	the player must be able to answer "What choices do I have?" and
	"What are the likely consequences?" BEFORE deciding).

	This is a read-only PREVIEW, not player input: it is sent to the
	client inside TaskAssigned, built entirely from server-held
	TaskDefinitions data. Showing a possible reward range to the player
	is not the same as trusting the player to report one back - the
	server never reads these numbers back from the client (see
	TaskService.lua's SECURITY MODEL comment).

	Pure logic module: no Roblox service calls, no `require`.
]]

local ChoicePreview = {}

--[[
	Builds a client-safe preview array from a task definition's Choices.

	Returns:
	{
		{
			ChoiceId = string,
			Label = string,
			Description = string,
			Preview = {
				{ Chance = number (0-100), Label = string,
				  MoneyGain = number, PerformanceGain = number, ReputationGain = number },
				...
			},
		},
		...
	}
]]
function ChoicePreview.Build(definition)
	assert(type(definition) == "table", "definition must be a table")
	assert(type(definition.Choices) == "table" and #definition.Choices > 0, "definition.Choices must be a non-empty array")

	local choices = {}
	for _, choice in ipairs(definition.Choices) do
		local preview = {}
		for _, outcome in ipairs(choice.Outcomes) do
			table.insert(preview, {
				Chance = outcome.Weight,
				Label = outcome.Label,
				MoneyGain = outcome.MoneyGain,
				PerformanceGain = outcome.PerformanceGain,
				ReputationGain = outcome.ReputationGain,
			})
		end

		table.insert(choices, {
			ChoiceId = choice.ChoiceId,
			Label = choice.Label,
			Description = choice.Description,
			Preview = preview,
		})
	end

	return choices
end

return ChoicePreview
