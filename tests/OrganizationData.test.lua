local testkit = _G.testkit or dofile("tests/testkit.lua")
local OrganizationDataSchema = dofile("src/ReplicatedStorage/Shared/Types/OrganizationData.lua")

testkit.suite("OrganizationData schema")

testkit.test("CreateDefault produces a valid record", function()
	local record = OrganizationDataSchema.CreateDefault({ OrgId = "org-1", Name = "Test Org" })
	local valid, reason = OrganizationDataSchema.Validate(record)
	testkit.assertTrue(valid, tostring(reason))
end)

testkit.test("CreateDefault sets safe defaults", function()
	local record = OrganizationDataSchema.CreateDefault({ OrgId = "org-1", Name = "Test Org" })
	testkit.assertEqual(record.OrgId, "org-1")
	testkit.assertEqual(record.Name, "Test Org")
	testkit.assertEqual(record.Seeded, true)
	testkit.assertEqual(record.Stage, OrganizationDataSchema.STAGE.STARTUP)
	testkit.assertEqual(record.MemberCount, 0)
	testkit.assertNil(record.Capital)
	testkit.assertNil(record.Departments)
	testkit.assertNil(record.Branches)
	testkit.assertEqual(record.SchemaVersion, OrganizationDataSchema.SCHEMA_VERSION)
end)

testkit.test("CreateDefault rejects a missing OrgId", function()
	local ok = pcall(OrganizationDataSchema.CreateDefault, { Name = "Test Org" })
	testkit.assertFalse(ok)
end)

testkit.test("CreateDefault rejects a missing Name", function()
	local ok = pcall(OrganizationDataSchema.CreateDefault, { OrgId = "org-1" })
	testkit.assertFalse(ok)
end)

testkit.test("Validate rejects a non-table", function()
	testkit.assertFalse(OrganizationDataSchema.Validate(42))
end)

testkit.test("Validate rejects a negative MemberCount", function()
	local record = OrganizationDataSchema.CreateDefault({ OrgId = "org-1", Name = "Test Org" })
	record.MemberCount = -1
	testkit.assertFalse(OrganizationDataSchema.Validate(record))
end)

testkit.test("Validate rejects a missing Stage", function()
	local record = OrganizationDataSchema.CreateDefault({ OrgId = "org-1", Name = "Test Org" })
	record.Stage = nil
	testkit.assertFalse(OrganizationDataSchema.Validate(record))
end)
