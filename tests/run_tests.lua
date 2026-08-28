--[[
	Standalone Lua 5.1 test runner for Phase 0's persistence modules.

	Run from the repo root:
		lua5.1 tests/run_tests.lua

	Why Lua 5.1 and not a Roblox/Luau test harness: this environment has
	no Roblox Studio/Luau runtime available. Every module under src/ was
	deliberately written with zero dependency on Roblox-only syntax or
	globals (no type annotations, no `game`/`Instance`/`DataStoreService`
	calls inside the modules themselves - see Bootstrap.server.lua, the
	one file that is Roblox-only by necessity and is not covered by this
	suite) specifically so this suite can exercise the real production
	source files directly, unmodified, under a plain Lua 5.1 interpreter.
	See docs/technical-architecture-v0.1.md §18 for the design rationale.
]]

_G.testkit = dofile("tests/testkit.lua")

local testFiles = {
	-- Phase 0
	"tests/PlayerData.test.lua",
	"tests/OrganizationData.test.lua",
	"tests/RetryPolicy.test.lua",
	"tests/SessionLock.test.lua",
	"tests/SeedOrganizations.test.lua",
	"tests/DataStoreWrapper.test.lua",
	"tests/OrganizationService.test.lua",
	"tests/PlayerDataService.test.lua", -- also covers Phase 1/2's ApplyTaskCompletion additions
	-- Phase 1
	"tests/TaskInstance.test.lua",
	"tests/ActionRateLimiter.test.lua",
	-- Phase 2 (TaskDefinitions/TaskOutcome cover Phase 2's Choices/decision shape)
	"tests/WeightedOutcome.test.lua",
	"tests/ChoicePreview.test.lua",
	"tests/TaskDefinitions.test.lua",
	"tests/TaskOutcome.test.lua",
	-- Phase 3
	"tests/PromotionConfig.test.lua",
	"tests/PromotionRules.test.lua",
	"tests/PromotionService.test.lua",
	"tests/TaskService.test.lua",
}

for _, file in ipairs(testFiles) do
	print("== " .. file .. " ==")
	dofile(file)
end

local success = _G.testkit.summary()
os.exit(success and 0 or 1)
