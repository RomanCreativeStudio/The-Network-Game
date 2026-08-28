--[[
	RetryPolicy - pure retry/backoff decision logic for DataStore
	operations (docs/technical-architecture-v0.1.md §5, §15).

	Pure logic module: no Roblox service calls, no `require`, no internal
	randomness/timing - every function is a deterministic pure function of
	its arguments, so it can be fully unit tested (see tests/).

	This module does NOT perform any I/O or waiting itself; DataStoreWrapper
	is responsible for calling `self._wait(BackoffSeconds(...))` between
	attempts.
]]

local RetryPolicy = {}

RetryPolicy.DEFAULT_MAX_ATTEMPTS = 5
RetryPolicy.BASE_DELAY_SECONDS = 1
RetryPolicy.MAX_DELAY_SECONDS = 16

--[[
	Returns true if another attempt should be made after `attemptNumber`
	has already failed (attemptNumber is 1-indexed: the first attempt is
	attemptNumber == 1).
]]
function RetryPolicy.ShouldRetry(attemptNumber, maxAttempts)
	maxAttempts = maxAttempts or RetryPolicy.DEFAULT_MAX_ATTEMPTS
	assert(type(attemptNumber) == "number" and attemptNumber >= 1, "attemptNumber must be >= 1")
	assert(type(maxAttempts) == "number" and maxAttempts >= 1, "maxAttempts must be >= 1")
	return attemptNumber < maxAttempts
end

--[[
	Returns the number of seconds to wait before the next attempt, using
	exponential backoff capped at maxDelay. Deterministic (no jitter) so
	it stays exactly testable; a jitter component can be layered on top
	by the caller if needed later without changing this function's
	contract.
]]
function RetryPolicy.BackoffSeconds(attemptNumber, baseDelay, maxDelay)
	baseDelay = baseDelay or RetryPolicy.BASE_DELAY_SECONDS
	maxDelay = maxDelay or RetryPolicy.MAX_DELAY_SECONDS
	assert(type(attemptNumber) == "number" and attemptNumber >= 1, "attemptNumber must be >= 1")

	local delay = baseDelay * (2 ^ (attemptNumber - 1))
	if delay > maxDelay then
		delay = maxDelay
	end
	return delay
end

return RetryPolicy
