--[[
	OrganizationData schema module.

	Pure data/schema module: no Roblox service calls, no `require` of any
	other module (see docs/technical-architecture-v0.1.md §7, §18).

	Phase 0 scope: this module defines the schema, safe defaults, and
	validation for an organization's persistent record. Capital,
	Departments, and Branches are reserved fields for the Economy and
	Organization Systems specs - present in the schema, unused by any
	Phase 0 code path. This is deliberate "data model headroom" (see
	docs/mvp-definition-v0.1.md §17 and technical-architecture-v0.1.md §7)
	so those systems are additive later, not a migration.
]]

local OrganizationDataSchema = {}

OrganizationDataSchema.SCHEMA_VERSION = 1

OrganizationDataSchema.STAGE = {
	STARTUP = "Startup",
}

--[[
	Creates a fresh, valid default OrganizationData record from a seed
	definition (see Data/SeedOrganizations.lua).

	seedDefinition: { OrgId = string, Name = string }
]]
function OrganizationDataSchema.CreateDefault(seedDefinition)
	assert(type(seedDefinition) == "table", "seedDefinition must be a table")
	assert(
		type(seedDefinition.OrgId) == "string" and #seedDefinition.OrgId > 0,
		"seedDefinition.OrgId must be a non-empty string"
	)
	assert(
		type(seedDefinition.Name) == "string" and #seedDefinition.Name > 0,
		"seedDefinition.Name must be a non-empty string"
	)

	return {
		OrgId = seedDefinition.OrgId,
		SchemaVersion = OrganizationDataSchema.SCHEMA_VERSION,
		Name = seedDefinition.Name,
		Seeded = true,
		Stage = OrganizationDataSchema.STAGE.STARTUP,
		MemberCount = 0,

		-- Reserved for the Economy Specification / Organization Systems
		-- Specification. Not written to by any Phase 0 code path.
		Capital = nil,
		Departments = nil,
		Branches = nil,

		CreatedAt = os.time(),
	}
end

--[[
	Validates that `record` is a well-formed OrganizationData record.
	Returns true on success, or false + a reason string on failure.
]]
function OrganizationDataSchema.Validate(record)
	if type(record) ~= "table" then
		return false, "record is not a table"
	end
	if type(record.OrgId) ~= "string" or #record.OrgId == 0 then
		return false, "invalid OrgId"
	end
	if type(record.SchemaVersion) ~= "number" then
		return false, "invalid SchemaVersion"
	end
	if type(record.Name) ~= "string" or #record.Name == 0 then
		return false, "invalid Name"
	end
	if type(record.Seeded) ~= "boolean" then
		return false, "invalid Seeded flag"
	end
	if type(record.Stage) ~= "string" or #record.Stage == 0 then
		return false, "invalid Stage"
	end
	if type(record.MemberCount) ~= "number" or record.MemberCount < 0 then
		return false, "invalid MemberCount"
	end
	if type(record.CreatedAt) ~= "number" then
		return false, "invalid CreatedAt"
	end

	return true
end

return OrganizationDataSchema
