local testkit = _G.testkit or dofile("tests/testkit.lua")
local PlayerDataSchema = dofile("src/ReplicatedStorage/Shared/Types/PlayerData.lua")

testkit.suite("PlayerData schema")

testkit.test("CreateDefault produces a valid record", function()
	local record = PlayerDataSchema.CreateDefault(12345, "org-1")
	local valid, reason = PlayerDataSchema.Validate(record)
	testkit.assertTrue(valid, "expected valid default record, got: " .. tostring(reason))
end)

testkit.test("RANK defines both Associate and Manager (Phase 3)", function()
	testkit.assertEqual(PlayerDataSchema.RANK.ASSOCIATE, "Associate")
	testkit.assertEqual(PlayerDataSchema.RANK.MANAGER, "Manager")
end)

testkit.test("Validate accepts a record with Rank = Manager", function()
	local record = PlayerDataSchema.CreateDefault(1, "org-1")
	record.Rank = PlayerDataSchema.RANK.MANAGER
	local valid, reason = PlayerDataSchema.Validate(record)
	testkit.assertTrue(valid, tostring(reason))
end)

testkit.test("CreateDefault sets safe defaults", function()
	local record = PlayerDataSchema.CreateDefault(12345, "org-1")
	testkit.assertEqual(record.UserId, 12345)
	testkit.assertEqual(record.OrgId, "org-1")
	testkit.assertEqual(record.Rank, PlayerDataSchema.RANK.ASSOCIATE)
	testkit.assertEqual(record.PersonalMoney, 0)
	testkit.assertEqual(record.PerformanceRating, 0)
	testkit.assertEqual(record.Reputation, 0)
	testkit.assertEqual(record.Influence, 0)
	testkit.assertEqual(#record.PerformanceHistory, 0)
	testkit.assertEqual(#record.TaskHistory, 0)
	testkit.assertEqual(record.SchemaVersion, PlayerDataSchema.SCHEMA_VERSION)
	testkit.assertNil(record.ActiveSession)
end)

testkit.test("CreateDefault rejects an invalid userId", function()
	local ok = pcall(PlayerDataSchema.CreateDefault, -1, "org-1")
	testkit.assertFalse(ok, "expected CreateDefault to reject a negative userId")
end)

testkit.test("CreateDefault rejects an empty orgId", function()
	local ok = pcall(PlayerDataSchema.CreateDefault, 1, "")
	testkit.assertFalse(ok, "expected CreateDefault to reject an empty orgId")
end)

testkit.test("Validate rejects a non-table", function()
	local valid = PlayerDataSchema.Validate("not a table")
	testkit.assertFalse(valid)
end)

testkit.test("Validate rejects missing required fields", function()
	local valid, reason = PlayerDataSchema.Validate({ UserId = 1 })
	testkit.assertFalse(valid)
	testkit.assertNotNil(reason)
end)

testkit.test("Validate rejects negative PersonalMoney", function()
	local record = PlayerDataSchema.CreateDefault(1, "org-1")
	record.PersonalMoney = -50
	local valid = PlayerDataSchema.Validate(record)
	testkit.assertFalse(valid)
end)

testkit.test("Validate rejects PerformanceHistory exceeding the bound", function()
	local record = PlayerDataSchema.CreateDefault(1, "org-1")
	for i = 1, PlayerDataSchema.MAX_HISTORY_LENGTH + 1 do
		table.insert(record.PerformanceHistory, i)
	end
	local valid = PlayerDataSchema.Validate(record)
	testkit.assertFalse(valid)
end)

testkit.test("Validate accepts a well-formed ActiveSession", function()
	local record = PlayerDataSchema.CreateDefault(1, "org-1")
	record.ActiveSession = { Token = "abc", ClaimedAt = 100 }
	local valid, reason = PlayerDataSchema.Validate(record)
	testkit.assertTrue(valid, tostring(reason))
end)

testkit.test("Validate rejects a malformed ActiveSession", function()
	local record = PlayerDataSchema.CreateDefault(1, "org-1")
	record.ActiveSession = { Token = 123 }
	local valid = PlayerDataSchema.Validate(record)
	testkit.assertFalse(valid)
end)

testkit.test("AppendBounded caps the list length and does not mutate the input", function()
	local list = {}
	for i = 1, PlayerDataSchema.MAX_HISTORY_LENGTH do
		list[i] = i
	end
	local appended = PlayerDataSchema.AppendBounded(list, "new-item", PlayerDataSchema.MAX_HISTORY_LENGTH)
	testkit.assertEqual(#appended, PlayerDataSchema.MAX_HISTORY_LENGTH)
	testkit.assertEqual(appended[#appended], "new-item")
	testkit.assertEqual(appended[1], 2) -- oldest entry (1) dropped
	testkit.assertEqual(#list, PlayerDataSchema.MAX_HISTORY_LENGTH) -- original untouched
end)
