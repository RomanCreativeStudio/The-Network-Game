local testkit = _G.testkit or dofile("tests/testkit.lua")
local SeedOrganizations = dofile("src/ReplicatedStorage/Shared/Data/SeedOrganizations.lua")

testkit.suite("SeedOrganizations")

testkit.test("at least one seeded organization exists", function()
	testkit.assertTrue(#SeedOrganizations.List >= 1)
end)

testkit.test("DEFAULT_ORG_ID resolves to a known seed", function()
	local def = SeedOrganizations.FindById(SeedOrganizations.DEFAULT_ORG_ID)
	testkit.assertNotNil(def)
	testkit.assertEqual(def.OrgId, SeedOrganizations.DEFAULT_ORG_ID)
end)

testkit.test("FindById returns nil for an unknown id", function()
	local def = SeedOrganizations.FindById("does-not-exist")
	testkit.assertNil(def)
end)

testkit.test("every seed definition has a non-empty OrgId and Name", function()
	for _, def in ipairs(SeedOrganizations.List) do
		testkit.assertTrue(type(def.OrgId) == "string" and #def.OrgId > 0)
		testkit.assertTrue(type(def.Name) == "string" and #def.Name > 0)
	end
end)

testkit.test("OrgIds are unique", function()
	local seen = {}
	for _, def in ipairs(SeedOrganizations.List) do
		testkit.assertNil(seen[def.OrgId], "duplicate OrgId: " .. tostring(def.OrgId))
		seen[def.OrgId] = true
	end
end)
