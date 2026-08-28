--[[
	PromotionConfig - PLAYTEST CALIBRATION VALUES for rank promotion
	thresholds.

	=====================================================================
	THESE ARE PLAYTEST CALIBRATION VALUES, NOT LOCKED DESIGN DECISIONS.
	=====================================================================

	docs/progression-specification-v0.1.md explicitly leaves exact rank
	requirements open ("Numeric thresholds are explicitly not proposed
	here" - its §3.3, and open decision #2 in its summary), and
	docs/source-of-truth.md §18 marks "exact rank requirements" as NOT
	YET LOCKED. Nothing in this file should be treated as final.

	These specific numbers come from the Phase 3A calibration analysis
	(analysis/progression_calibration_sim.lua), which simulated the real
	Phase 2 task/choice rewards against MVP Definition §20's target of a
	skillful player reaching first promotion within roughly 20-30 minutes
	(translated, via the calibration report's stated per-task time
	assumption, to a ~5-10 task target under consistently good decisions).
	P=10 falls in that report's proposed PerformanceThreshold range
	(8-14) and R=5 in its ReputationThreshold range (4-7), chosen as the
	pair that aligns with the "careful" choice's fixed 2:1 Performance:
	Reputation ratio (see the calibration report) - not because 10 and 5
	are correct, only because they are a reasonable, documented starting
	point to playtest against and adjust.

	LOCKED (not calibration - see docs/progression-specification-v0.1.md
	§3.2, itself inherited from the locked "Performance > Time" principle
	in docs/source-of-truth.md §4): promotion eligibility must require
	BOTH Performance AND Reputation to clear their threshold - never
	either alone. Money is never part of this gate at all: there is no
	MoneyThreshold field here, deliberately, per Phase 3A finding #8.
	Do not add one without an explicit Source-of-Truth-level decision.
]]

local PromotionConfig = {}

-- PLAYTEST CALIBRATION - see module doc comment above. Expect to tune
-- these against real play sessions; do not treat as final.
PromotionConfig.ASSOCIATE_TO_MANAGER = {
	PerformanceThreshold = 10, -- PLAYTEST CALIBRATION
	ReputationThreshold = 5, -- PLAYTEST CALIBRATION
}

return PromotionConfig
