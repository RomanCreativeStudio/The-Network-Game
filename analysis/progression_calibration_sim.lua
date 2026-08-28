--[[
	progression_calibration_sim.lua - PHASE 3A CALIBRATION ANALYSIS TOOL.

	NOT part of the automated test suite (tests/run_tests.lua does not
	run this) and NOT gameplay code - a read-only analysis script that
	exercises the real, unmodified production modules
	(Shared/Data/TaskDefinitions.lua, Shared/Logic/TaskOutcome.lua,
	Shared/Logic/WeightedOutcome.lua) to produce empirical numbers for
	the Phase 3A progression-calibration report, instead of hand-waving
	expected values for the probabilistic "cut_corners" choice.

	Run from the repo root: lua5.1 analysis/progression_calibration_sim.lua

	Simulates four archetypal play strategies against a small set of
	ILLUSTRATIVE (Performance, Reputation) threshold pairs - none of
	these threshold pairs are proposed as final numbers; they exist only
	to make "how many tasks would this take" concrete and comparable.
	Promotion in every case requires BOTH Performance AND Reputation to
	clear their threshold simultaneously, matching the locked requirement
	shape in docs/progression-specification-v0.1.md §3.2 (never Performance
	alone).
]]

math.randomseed(42) -- fixed seed: reproducible report numbers on re-run

local TaskDefinitions = dofile("src/ReplicatedStorage/Shared/Data/TaskDefinitions.lua")
local WeightedOutcome = dofile("src/ReplicatedStorage/Shared/Logic/WeightedOutcome.lua")
local TaskOutcome = dofile("src/ReplicatedStorage/Shared/Logic/TaskOutcome.lua")

local definition = TaskDefinitions.FindById(TaskDefinitions.DEFAULT_TASK_ID)

local function resolveChoice(choiceId)
	local choice = TaskDefinitions.FindChoice(definition, choiceId)
	local roll = math.random(1, 100)
	return TaskOutcome.Resolve(choice, roll, WeightedOutcome)
end

--------------------------------------------------------------------------
-- Strategies (archetypal play patterns)
--------------------------------------------------------------------------

local strategies = {
	{
		name = "careful_only (consistently strong)",
		fn = function(_state)
			return "careful"
		end,
	},
	{
		name = "quick_only (average/low-effort)",
		fn = function(_state)
			return "quick"
		end,
	},
	{
		name = "cut_corners_only (always risky)",
		fn = function(_state)
			return "cut_corners"
		end,
	},
	{
		name = "mixed_2to1 (2 careful : 1 cut_corners, fixed cycle)",
		fn = function(state)
			state.cycle = (state.cycle or 0) + 1
			if state.cycle % 3 == 0 then
				return "cut_corners"
			end
			return "careful"
		end,
	},
	{
		name = "opportunistic (careful; gamble only once reputation has a +3 buffer)",
		fn = function(state)
			if state.reputation >= (state.repThreshold + 3) then
				return "cut_corners"
			end
			return "careful"
		end,
	},
}

--------------------------------------------------------------------------
-- Simulation
--------------------------------------------------------------------------

local MAX_TASKS = 200 -- generous cap; exceeding this is reported as DNF (did not finish)
local TRIALS = 3000

local function simulateOnce(strategyFn, perfThreshold, repThreshold)
	local performance, reputation = 0, 0
	local state = { reputation = 0, repThreshold = repThreshold }
	for taskCount = 1, MAX_TASKS do
		local choiceId = strategyFn(state)
		local outcome = resolveChoice(choiceId)
		performance = performance + outcome.PerformanceGain
		reputation = reputation + outcome.ReputationGain
		state.reputation = reputation
		if performance >= perfThreshold and reputation >= repThreshold then
			return taskCount, performance, reputation
		end
	end
	return nil, performance, reputation
end

local function runTrials(strategyFn, perfThreshold, repThreshold)
	local results = {}
	local dnf = 0
	local finalRepSumOnDnf = 0
	for _ = 1, TRIALS do
		local taskCount, _perf, finalRep = simulateOnce(strategyFn, perfThreshold, repThreshold)
		if taskCount then
			table.insert(results, taskCount)
		else
			dnf = dnf + 1
			finalRepSumOnDnf = finalRepSumOnDnf + finalRep
		end
	end
	table.sort(results)

	local function pct(p)
		if #results == 0 then
			return nil
		end
		local idx = math.max(1, math.ceil(p * #results))
		return results[idx]
	end

	local sum = 0
	for _, v in ipairs(results) do
		sum = sum + v
	end

	return {
		completed = #results,
		dnf = dnf,
		mean = (#results > 0) and (sum / #results) or nil,
		median = pct(0.5),
		p90 = pct(0.9),
		min = results[1],
		max = results[#results],
		avgFinalRepOnDnf = (dnf > 0) and (finalRepSumOnDnf / dnf) or nil,
	}
end

--------------------------------------------------------------------------
-- Report
--------------------------------------------------------------------------

-- Illustrative threshold pairs only - see module doc comment above.
local thresholdPairs = {
	{ perf = 10, rep = 5, label = "P=10, R=5 (matches careful's 2:1 Perf:Rep ratio)" },
	{ perf = 10, rep = 3, label = "P=10, R=3 (Reputation looser than careful's ratio)" },
	{ perf = 20, rep = 10, label = "P=20, R=10 (same 2:1 ratio, larger scale)" },
	{ perf = 8, rep = 7, label = "P=8, R=7 (Reputation tighter than careful's ratio - Rep becomes binding)" },
}

print(string.format("Simulation: %d trials per (strategy, threshold pair), cap %d tasks, fixed seed 42.\n", TRIALS, MAX_TASKS))

for _, tp in ipairs(thresholdPairs) do
	print(string.format("=== Threshold pair: %s ===", tp.label))
	print(string.format("%-55s %8s %8s %8s %8s %8s %10s", "strategy", "mean", "median", "p90", "min", "max", "DNF%"))
	for _, strat in ipairs(strategies) do
		local r = runTrials(strat.fn, tp.perf, tp.rep)
		local dnfPct = 100 * r.dnf / TRIALS
		print(
			string.format(
				"%-55s %8s %8s %8s %8s %8s %9.1f%%",
				strat.name,
				r.mean and string.format("%.2f", r.mean) or "-",
				r.median and tostring(r.median) or "-",
				r.p90 and tostring(r.p90) or "-",
				r.min and tostring(r.min) or "-",
				r.max and tostring(r.max) or "-",
				dnfPct
			)
		)
		if r.dnf > 0 and r.avgFinalRepOnDnf then
			print(string.format("    -> on DNF trials, average final Reputation after %d tasks: %.2f", MAX_TASKS, r.avgFinalRepOnDnf))
		end
	end
	print("")
end

--------------------------------------------------------------------------
-- Per-task expected value table (closed-form, cross-checks the simulation)
--------------------------------------------------------------------------

print("=== Per-task expected value (closed-form) ===")
print(string.format("%-14s %10s %10s %10s", "choice", "E[Money]", "E[Perf]", "E[Rep]"))
local choiceEV = {
	careful = { money = 10, perf = 2, rep = 1 },
	quick = { money = 6, perf = 1, rep = 0 },
	cut_corners = { money = 0.6 * 18 + 0.4 * 2, perf = 0.6 * 3 + 0.4 * (-1), rep = 0.6 * 1 + 0.4 * (-2) },
}
for _, choiceId in ipairs({ "careful", "quick", "cut_corners" }) do
	local ev = choiceEV[choiceId]
	print(string.format("%-14s %10.2f %10.2f %10.2f", choiceId, ev.money, ev.perf, ev.rep))
end
