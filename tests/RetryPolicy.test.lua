local testkit = _G.testkit or dofile("tests/testkit.lua")
local RetryPolicy = dofile("src/ReplicatedStorage/Shared/Logic/RetryPolicy.lua")

testkit.suite("RetryPolicy")

testkit.test("ShouldRetry allows retries below the max", function()
	testkit.assertTrue(RetryPolicy.ShouldRetry(1, 5))
	testkit.assertTrue(RetryPolicy.ShouldRetry(4, 5))
end)

testkit.test("ShouldRetry stops at the max", function()
	testkit.assertFalse(RetryPolicy.ShouldRetry(5, 5))
	testkit.assertFalse(RetryPolicy.ShouldRetry(6, 5))
end)

testkit.test("ShouldRetry uses DEFAULT_MAX_ATTEMPTS when maxAttempts is omitted", function()
	testkit.assertTrue(RetryPolicy.ShouldRetry(1))
	testkit.assertFalse(RetryPolicy.ShouldRetry(RetryPolicy.DEFAULT_MAX_ATTEMPTS))
end)

testkit.test("BackoffSeconds grows exponentially", function()
	testkit.assertEqual(RetryPolicy.BackoffSeconds(1, 1, 100), 1)
	testkit.assertEqual(RetryPolicy.BackoffSeconds(2, 1, 100), 2)
	testkit.assertEqual(RetryPolicy.BackoffSeconds(3, 1, 100), 4)
	testkit.assertEqual(RetryPolicy.BackoffSeconds(4, 1, 100), 8)
end)

testkit.test("BackoffSeconds is capped at maxDelay", function()
	testkit.assertEqual(RetryPolicy.BackoffSeconds(10, 1, 16), 16)
end)

testkit.test("BackoffSeconds uses defaults when base/max are omitted", function()
	local delay = RetryPolicy.BackoffSeconds(1)
	testkit.assertEqual(delay, RetryPolicy.BASE_DELAY_SECONDS)
end)
