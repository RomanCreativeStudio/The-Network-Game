--[[
	SeedOrganizations - the fixed, stable set of pre-seeded organizations
	MVP players join (Organization Systems Spec §21; MVP Definition §7).

	Pure static data module: no Roblox service calls, no `require`.

	Per docs/technical-architecture-v0.1.md §1, an OrgId here is a STABLE,
	PERMANENT identifier - it is used as the DataStore key for that
	organization's persistent record forever. Do not change an existing
	entry's OrgId once real player data may reference it; add a new entry
	instead.

	These are NOT player-founded organizations (Founder system is
	explicitly out of scope, per SoT §7 and MVP Definition §3/§7).
]]

local SeedOrganizations = {}

-- The single seeded organization Phase 0 / MVP players are associated
-- with. MVP Definition §7 recommends 2-3 seeded orgs as a "Recommended"
-- (not Required) enhancement; Phase 0 implements only the Required
-- minimum of one, real, persistent org, per the Phase 0 task scope.
SeedOrganizations.DEFAULT_ORG_ID = "seed_org_associate_holdings_001"

SeedOrganizations.List = {
	{
		OrgId = "seed_org_associate_holdings_001",
		Name = "Associate Holdings",
	},
}

--[[
	Looks up a seed definition by OrgId. Returns the definition table, or
	nil if orgId does not correspond to a known seeded organization.
]]
function SeedOrganizations.FindById(orgId)
	for _, definition in ipairs(SeedOrganizations.List) do
		if definition.OrgId == orgId then
			return definition
		end
	end
	return nil
end

return SeedOrganizations
