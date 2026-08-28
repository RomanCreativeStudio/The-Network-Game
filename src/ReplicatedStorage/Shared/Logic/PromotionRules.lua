--[[
	PromotionRules - pure AND-gate promotion-eligibility logic.

	LOCKED shape (docs/progression-specification-v0.1.md §3.2, itself
	inherited from the locked "Performance > Time" principle in
	docs/source-of-truth.md §4): eligibility requires Performance AND
	Reputation to both clear their threshold - never either alone. Money
	is never a parameter here at all, by construction, not by an omission
	someone could quietly "fix" later - see Phase 3A finding #8 (Money
	must never gate promotion).

	The actual threshold VALUES this module is called with are PLAYTEST
	CALIBRATION, not locked - see Shared/Data/PromotionConfig.lua. This
	module only owns the shape of the comparison, never the numbers.

	Pure logic module: no Roblox service calls, no `require`.
]]

local PromotionRules = {}

--[[
	Returns (true) if `performance` and `reputation` both meet or exceed
	their threshold in `config` - "exactly at threshold" counts as
	eligible (>=, not strictly >), matching the Phase 3A calibration
	report's exactly-at-threshold expectation. Returns (false, reason) on
	the first failing requirement (performance checked first, matching
	Progression Spec's Performance-primacy framing) if not eligible.

	config: { PerformanceThreshold = number, ReputationThreshold = number }
	(see PromotionConfig.lua - these values are calibration, this
	function's logic is not).
]]
function PromotionRules.MeetsThresholds(performance, reputation, config)
	assert(type(performance) == "number", "performance must be a number")
	assert(type(reputation) == "number", "reputation must be a number")
	assert(
		type(config) == "table"
			and type(config.PerformanceThreshold) == "number"
			and type(config.ReputationThreshold) == "number",
		"config must have numeric PerformanceThreshold and ReputationThreshold"
	)

	if performance < config.PerformanceThreshold then
		return false, "performance below threshold"
	end
	if reputation < config.ReputationThreshold then
		return false, "reputation below threshold"
	end
	return true
end

return PromotionRules
