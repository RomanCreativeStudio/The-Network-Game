--[[
	ActionRateLimiter - pure per-player action cooldown decision logic
	(docs/technical-architecture-v0.1.md §13: "Rate-limit/debounce every
	action Remote per-player").

	Defense-in-depth against a modified client hammering a Task Remote
	far faster than any legitimate UI would - the primary correctness
	guard against duplicate/replay is TaskInstance's Completed flag, not
	this; this exists to blunt wasted server work from spam, not to be
	the safety mechanism itself.

	Pure logic module: no Roblox service calls, no `require`, no internal
	clock - fully deterministic and unit-testable.
]]

local ActionRateLimiter = {}

ActionRateLimiter.MIN_INTERVAL_SECONDS = 0.25

--[[
	Returns true if an action may proceed given the timestamp of the
	player's last allowed action (`lastActionAt`, or nil if they have
	never acted before) and the current time `now`.
]]
function ActionRateLimiter.ShouldAllow(lastActionAt, now, minInterval)
	minInterval = minInterval or ActionRateLimiter.MIN_INTERVAL_SECONDS
	assert(type(now) == "number", "now must be a number")

	if lastActionAt == nil then
		return true
	end
	assert(type(lastActionAt) == "number", "lastActionAt must be a number or nil")

	return (now - lastActionAt) >= minInterval
end

return ActionRateLimiter
