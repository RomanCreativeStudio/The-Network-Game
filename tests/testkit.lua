--[[
	testkit.lua - a minimal, dependency-free test runner/assertion library
	for exercising the Lua-5.1-compatible pure modules under a plain Lua
	interpreter (no Roblox/Luau runtime available in this environment -
	see the "Tests added/run" section of the Phase 0 report for why this
	is Phase 0's practical testing approach; technical-architecture-v0.1.md
	§18 recommends exactly this separation).

	Loaded once by tests/run_tests.lua and shared (via _G.testkit) across
	all *.test.lua files so pass/fail counts accumulate into one summary.
]]

local testkit = {}

testkit.passed = 0
testkit.failed = 0
testkit.failures = {}

local currentSuite = "unknown"

function testkit.suite(name)
	currentSuite = name
end

function testkit.test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		testkit.passed = testkit.passed + 1
		print(string.format("  [PASS] %s - %s", currentSuite, name))
	else
		testkit.failed = testkit.failed + 1
		table.insert(testkit.failures, string.format("%s - %s: %s", currentSuite, name, tostring(err)))
		print(string.format("  [FAIL] %s - %s: %s", currentSuite, name, tostring(err)))
	end
end

function testkit.assertEqual(actual, expected, message)
	if actual ~= expected then
		error(
			string.format(
				"%s (expected %s, got %s)",
				message or "assertEqual failed",
				tostring(expected),
				tostring(actual)
			),
			2
		)
	end
end

function testkit.assertTrue(value, message)
	if value ~= true then
		error(message or ("assertTrue failed (got " .. tostring(value) .. ")"), 2)
	end
end

function testkit.assertFalse(value, message)
	if value ~= false then
		error(message or ("assertFalse failed (got " .. tostring(value) .. ")"), 2)
	end
end

function testkit.assertNil(value, message)
	if value ~= nil then
		error(message or ("assertNil failed (got " .. tostring(value) .. ")"), 2)
	end
end

function testkit.assertNotNil(value, message)
	if value == nil then
		error(message or "assertNotNil failed (got nil)", 2)
	end
end

function testkit.summary()
	print("")
	print(string.format("Total: %d passed, %d failed", testkit.passed, testkit.failed))
	if testkit.failed > 0 then
		print("Failures:")
		for _, f in ipairs(testkit.failures) do
			print("  - " .. f)
		end
	end
	return testkit.failed == 0
end

return testkit
