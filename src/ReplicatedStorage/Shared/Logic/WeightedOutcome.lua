--[[
	WeightedOutcome - pure weighted-selection logic for a decision's
	possible outcomes (docs task brief Phase 2: "If randomness exists, it
	must be bounded, explainable, and server-controlled").

	Convention used throughout Shared/Data/TaskDefinitions.lua: each
	choice's Outcomes list carries integer Weights that sum to exactly
	100 (percentage points), and the caller rolls an integer in [1, 100]
	(e.g. via math.random(1, 100)) - so `Weight` doubles directly as a
	human-readable "N% chance" with no division or rounding needed
	anywhere, keeping the whole system "explainable" per the brief.

	Pure logic module: no Roblox service calls, no `require`, no internal
	randomness - the roll is always passed in, so outcome selection is a
	deterministic, fully unit-testable function of (outcomes, roll).
]]

local WeightedOutcome = {}

-- Sums the Weight fields of an outcomes list.
function WeightedOutcome.TotalWeight(outcomes)
	assert(type(outcomes) == "table" and #outcomes > 0, "outcomes must be a non-empty array")
	local total = 0
	for _, outcome in ipairs(outcomes) do
		assert(type(outcome.Weight) == "number" and outcome.Weight > 0, "each outcome needs a positive Weight")
		total = total + outcome.Weight
	end
	return total
end

--[[
	Picks the outcome corresponding to `roll` (expected to be an integer
	in [1, TotalWeight(outcomes)], e.g. from math.random(1, 100) when
	weights sum to 100) via cumulative-bucket selection: outcomes are
	tried in list order, and `roll` selects the first outcome whose
	cumulative weight-so-far is >= roll.

	Example: outcomes = [{Weight=60,...}, {Weight=40,...}]
	  roll 1..60   -> outcome 1 (60% of the range)
	  roll 61..100 -> outcome 2 (40% of the range)

	Defensively falls back to the last outcome if `roll` exceeds the
	total weight (should not happen with a correctly bounded roll, but
	never errors or returns nil for an out-of-range input).
]]
function WeightedOutcome.Pick(outcomes, roll)
	assert(type(outcomes) == "table" and #outcomes > 0, "outcomes must be a non-empty array")
	assert(type(roll) == "number", "roll must be a number")

	local cumulative = 0
	for _, outcome in ipairs(outcomes) do
		cumulative = cumulative + outcome.Weight
		if roll <= cumulative then
			return outcome
		end
	end

	return outcomes[#outcomes]
end

return WeightedOutcome
