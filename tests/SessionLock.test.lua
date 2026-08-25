local testkit = _G.testkit or dofile("tests/testkit.lua")
local SessionLock = dofile("src/ReplicatedStorage/Shared/Logic/SessionLock.lua")

testkit.suite("SessionLock")

testkit.test("EvaluateClaim allows claiming an unlocked record", function()
	local canClaim = SessionLock.EvaluateClaim(nil, "token-a", 1000)
	testkit.assertTrue(canClaim)
end)

testkit.test("EvaluateClaim allows the same token to reclaim its own lock", function()
	local session = SessionLock.Claim("token-a", 1000)
	local canClaim = SessionLock.EvaluateClaim(session, "token-a", 1005)
	testkit.assertTrue(canClaim)
end)

testkit.test("EvaluateClaim refuses a different token while the lock is fresh", function()
	local session = SessionLock.Claim("token-a", 1000)
	local canClaim = SessionLock.EvaluateClaim(session, "token-b", 1001)
	testkit.assertFalse(canClaim)
end)

testkit.test("EvaluateClaim allows a different token once the lock is stale", function()
	local session = SessionLock.Claim("token-a", 1000)
	local now = 1000 + SessionLock.STALE_AFTER_SECONDS + 1
	local canClaim = SessionLock.EvaluateClaim(session, "token-b", now)
	testkit.assertTrue(canClaim)
end)

testkit.test("EvaluateClaim treats the staleness boundary as still locked", function()
	local session = SessionLock.Claim("token-a", 1000)
	local now = 1000 + SessionLock.STALE_AFTER_SECONDS -- exactly at the boundary, not past it
	local canClaim = SessionLock.EvaluateClaim(session, "token-b", now)
	testkit.assertFalse(canClaim)
end)

testkit.test("EvaluateClaim refuses an unrecognized session shape", function()
	local canClaim = SessionLock.EvaluateClaim({ garbage = true }, "token-a", 1000)
	testkit.assertFalse(canClaim)
end)

testkit.test("Release clears a lock owned by the given token", function()
	local session = SessionLock.Claim("token-a", 1000)
	local released = SessionLock.Release(session, "token-a")
	testkit.assertNil(released)
end)

testkit.test("Release leaves a lock owned by another token untouched", function()
	local session = SessionLock.Claim("token-a", 1000)
	local released = SessionLock.Release(session, "token-b")
	testkit.assertNotNil(released)
	testkit.assertEqual(released.Token, "token-a")
end)

testkit.test("Release on an already-nil session is a safe no-op", function()
	local released = SessionLock.Release(nil, "token-a")
	testkit.assertNil(released)
end)

testkit.test("NewToken produces distinct tokens for distinct nonces", function()
	local t1 = SessionLock.NewToken("job-1", 1, 1000, 1)
	local t2 = SessionLock.NewToken("job-1", 1, 1000, 2)
	testkit.assertTrue(t1 ~= t2)
end)

testkit.test("NewToken produces distinct tokens for distinct jobIds", function()
	local t1 = SessionLock.NewToken("job-1", 1, 1000, 1)
	local t2 = SessionLock.NewToken("job-2", 1, 1000, 1)
	testkit.assertTrue(t1 ~= t2)
end)
