--[[
	OrganizationService - loads (and, for seeded orgs, creates-if-missing)
	an organization's persistent record (docs/technical-architecture-v0.1.md
	§1, §7, §9).

	Phase 0 scope: this service only loads/creates OrganizationData records
	for KNOWN SEEDED organizations (Data/SeedOrganizations.lua). It does
	NOT implement organization gameplay (Departments, Branches, Capital,
	hiring, etc.) - those fields exist in the schema as reserved headroom
	only (Types/OrganizationData.lua).

	Dependency-injected (schema, seedOrganizations, wrapper, store are all
	passed in via config) so this module has zero internal `require` calls
	and can be exercised by the standalone test suite against a fake
	DataStore - see technical-architecture-v0.1.md §18.
]]

local OrganizationService = {}
OrganizationService.__index = OrganizationService

--[[
	config:
		wrapper (required) - a DataStoreWrapper instance
		store (required) - a DataStore-like object (real or fake) for organization records
		schema (required) - the OrganizationData schema module (CreateDefault, Validate)
		seedOrganizations (required) - the SeedOrganizations data module (FindById)
]]
function OrganizationService.new(config)
	config = config or {}
	assert(config.wrapper, "OrganizationService requires config.wrapper")
	assert(config.store, "OrganizationService requires config.store")
	assert(config.schema, "OrganizationService requires config.schema")
	assert(config.seedOrganizations, "OrganizationService requires config.seedOrganizations")

	local self = setmetatable({}, OrganizationService)
	self._wrapper = config.wrapper
	self._store = config.store
	self._schema = config.schema
	self._seedOrganizations = config.seedOrganizations

	-- Per-server in-memory cache (technical architecture §14: organization
	-- records are loaded per-server on first need, not session-locked the
	-- way player profiles are, since Phase 0 performs no write to this
	-- data beyond first-time seeding).
	self._cache = {}

	return self
end

--[[
	Loads the organization identified by orgId, creating it from a known
	seed definition if it does not exist yet. Returns (true, record) on
	success, or (false, errorMessage) on failure - including the case
	where orgId is neither an existing record nor a known seed (Phase 0
	does not create arbitrary/unseeded organizations; that is the Founder
	system, explicitly out of scope).
]]
function OrganizationService:GetOrCreateOrganization(orgId)
	if type(orgId) ~= "string" or #orgId == 0 then
		return false, "invalid orgId"
	end

	if self._cache[orgId] ~= nil then
		return true, self._cache[orgId]
	end

	local getOk, getResult = self._wrapper:Get(self._store, orgId)
	if not getOk then
		return false, "datastore error: " .. tostring(getResult)
	end

	if getResult ~= nil then
		local valid, reason = self._schema.Validate(getResult)
		if not valid then
			return false, "corrupt organization record: " .. tostring(reason)
		end
		self._cache[orgId] = getResult
		return true, getResult
	end

	local seedDef = self._seedOrganizations.FindById(orgId)
	if not seedDef then
		return false, "organization not found and not seedable: " .. tostring(orgId)
	end

	local schema = self._schema

	-- Race-safe creation: two servers may both discover the org is
	-- missing at nearly the same time. UpdateAsync's read-modify-write
	-- means whichever call actually runs the transform last still checks
	-- `old` and, if another server already created it in the meantime,
	-- keeps that value instead of overwriting it.
	local updOk, updResult = self._wrapper:Update(self._store, orgId, function(old)
		if old ~= nil then
			return old
		end
		return schema.CreateDefault(seedDef)
	end)

	if not updOk then
		return false, "datastore error: " .. tostring(updResult)
	end
	if updResult == nil then
		return false, "organization creation returned no data"
	end

	self._cache[orgId] = updResult
	return true, updResult
end

return OrganizationService
