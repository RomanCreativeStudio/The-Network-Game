--[[
	SessionLock - pure session-ownership decision logic.

	Implements the in-band (no MemoryStoreService dependency) session-lock
	pattern recommended in docs/technical-architecture-v0.1.md §5, §14:
	a player's PlayerData record carries an `ActiveSession` field that
	records which server currently "owns" it, so a second server cannot
	load and later save stale/conflicting data over a session that is
	still active elsewhere (technical architecture §16, and the Phase 0
	success criterion "saves do not overwrite newer state incorrectly").

	Pure logic module: no Roblox service calls, no `require`, no internal
	clock/randomness - `now` and the token are always passed in, so this
	is fully unit-testable and fully deterministic.
]]

local SessionLock = {}

-- A lock older than this is presumed abandoned (e.g. the owning server
-- crashed without releasing it) and may be reclaimed by a new session.
SessionLock.STALE_AFTER_SECONDS = 5 * 60

--[[
	Builds an opaque session token. Callers should pass a real Roblox
	game.JobId, the player's UserId, the current time, and a nonce (e.g. a
	random number) to make collisions between two servers claiming the
	same record at nearly the same instant vanishingly unlikely.
]]
function SessionLock.NewToken(jobId, userId, now, nonce)
	jobId = jobId or "unknown-job"
	assert(type(userId) == "number", "userId must be a number")
	assert(type(now) == "number", "now must be a number")
	nonce = nonce or 0
	return string.format("%s:%d:%d:%d", tostring(jobId), userId, now, nonce)
end

--[[
	Decides whether `myToken` may claim the lock, given the record's
	current ActiveSession field (which may be nil, a well-formed session
	table, or - defensively - something unrecognized).

	Returns (canClaim: boolean, reason: string).
]]
function SessionLock.EvaluateClaim(activeSession, myToken, now)
	assert(type(myToken) == "string" and #myToken > 0, "myToken must be a non-empty string")
	assert(type(now) == "number", "now must be a number")

	if activeSession == nil then
		return true, "no existing session"
	end

	if
		type(activeSession) ~= "table"
		or type(activeSession.Token) ~= "string"
		or type(activeSession.ClaimedAt) ~= "number"
	then
		-- Corrupt/unrecognized lock shape: never blindly claim over unknown
		-- state - safer to refuse than to risk clobbering something we
		-- don't understand.
		return false, "unrecognized active session shape"
	end

	if activeSession.Token == myToken then
		return true, "already owned by this session"
	end

	if (now - activeSession.ClaimedAt) > SessionLock.STALE_AFTER_SECONDS then
		return true, "existing session is stale"
	end

	return false, "session actively owned by another server"
end

--[[
	Returns the ActiveSession value to write when claiming the lock.
]]
function SessionLock.Claim(myToken, now)
	assert(type(myToken) == "string" and #myToken > 0, "myToken must be a non-empty string")
	assert(type(now) == "number", "now must be a number")
	return { Token = myToken, ClaimedAt = now }
end

--[[
	Returns the ActiveSession value to write when releasing the lock: nil
	(released) if `myToken` currently owns it, or the existing value
	unchanged if it does not (never release a lock that isn't ours).
]]
function SessionLock.Release(activeSession, myToken)
	if activeSession ~= nil and type(activeSession) == "table" and activeSession.Token == myToken then
		return nil
	end
	return activeSession
end

return SessionLock
