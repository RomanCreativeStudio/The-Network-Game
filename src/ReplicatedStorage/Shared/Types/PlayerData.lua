--[[
	PlayerData schema module.

	Pure data/schema module: no Roblox service calls, no `require` of any
	other module. This is deliberate (see docs/technical-architecture-v0.1.md
	§6, §18) so it can be exercised by the standalone test suite (tests/)
	as well as inside Roblox.

	Phase 0 scope: this module defines the schema, safe defaults, and
	validation for a player's persistent record. It does NOT implement any
	gameplay logic that mutates these fields (Tasks, Promotions, Economy
	gameplay are out of scope for Phase 0 per docs/mvp-definition-v0.1.md).

	Several fields (Influence, PerformanceHistory, TaskHistory, higher Ranks)
	exist here only as schema headroom for systems specified in the Economy,
	Progression, and Organization Systems specs but not implemented yet -
	this is the "data model headroom, not feature stubs" principle from
	docs/mvp-definition-v0.1.md §17.
]]

local PlayerDataSchema = {}

-- Bump this whenever the shape of a PlayerData record changes, and add a
-- migration step in Validate/CreateDefault as needed. See technical
-- architecture §6 and the schema-drift risk in §24.
PlayerDataSchema.SCHEMA_VERSION = 1

-- Bounded history length (technical architecture §6, §22): PerformanceHistory
-- and TaskHistory must never grow unbounded, both to respect DataStore's
-- per-key payload size limit and because the rolling Performance average
-- (Economy Spec §5.1) only needs a recent window, not full history.
PlayerDataSchema.MAX_HISTORY_LENGTH = 20

-- Only "Associate" is reachable in Phase 0 - no code path in Phase 0 ever
-- assigns Specialist/Manager/etc. The rest of the Progression Spec's
-- ladder is intentionally not enumerated here yet; adding it later is a
-- field/enum extension, not a schema migration.
PlayerDataSchema.RANK = {
	ASSOCIATE = "Associate",
}

--[[
	Creates a fresh, valid default PlayerData record for a brand-new player.

	userId: positive number (Roblox UserId)
	orgId: non-empty string - the seeded organization this player starts in
]]
function PlayerDataSchema.CreateDefault(userId, orgId)
	assert(type(userId) == "number" and userId > 0, "userId must be a positive number")
	assert(type(orgId) == "string" and #orgId > 0, "orgId must be a non-empty string")

	local now = os.time()

	return {
		UserId = userId,
		SchemaVersion = PlayerDataSchema.SCHEMA_VERSION,
		OrgId = orgId,
		Rank = PlayerDataSchema.RANK.ASSOCIATE,

		-- Economy Spec §3.1, §3.5, §3.4; Progression Spec - all inert in Phase 0.
		PersonalMoney = 0,
		PerformanceRating = 0,
		PerformanceHistory = {},
		Reputation = 0,
		Influence = 0,

		-- Bounded action/outcome log (technical architecture §6, §17).
		TaskHistory = {},

		CreatedAt = now,
		LastLogin = now,

		-- ActiveSession is intentionally absent from a freshly-created record;
		-- it is populated by the session-lock claim process (Logic/SessionLock),
		-- not by schema defaults. See Validate() below for its optional shape.
	}
end

--[[
	Validates that `record` is a well-formed PlayerData record.
	Returns true on success, or false + a reason string on failure.

	This performs structural/type validation only - it does not implement
	game-rule validation (e.g. "is this a legal promotion"), since no
	gameplay system that would produce such rules exists in Phase 0.
]]
function PlayerDataSchema.Validate(record)
	if type(record) ~= "table" then
		return false, "record is not a table"
	end
	if type(record.UserId) ~= "number" or record.UserId <= 0 then
		return false, "invalid UserId"
	end
	if type(record.SchemaVersion) ~= "number" then
		return false, "invalid SchemaVersion"
	end
	if type(record.OrgId) ~= "string" or #record.OrgId == 0 then
		return false, "invalid OrgId"
	end
	if type(record.Rank) ~= "string" or #record.Rank == 0 then
		return false, "invalid Rank"
	end
	if type(record.PersonalMoney) ~= "number" or record.PersonalMoney < 0 then
		return false, "invalid PersonalMoney"
	end
	if type(record.PerformanceRating) ~= "number" then
		return false, "invalid PerformanceRating"
	end
	if type(record.PerformanceHistory) ~= "table" then
		return false, "invalid PerformanceHistory"
	end
	if #record.PerformanceHistory > PlayerDataSchema.MAX_HISTORY_LENGTH then
		return false, "PerformanceHistory exceeds bound"
	end
	if type(record.Reputation) ~= "number" then
		return false, "invalid Reputation"
	end
	if type(record.Influence) ~= "number" then
		return false, "invalid Influence"
	end
	if type(record.TaskHistory) ~= "table" then
		return false, "invalid TaskHistory"
	end
	if #record.TaskHistory > PlayerDataSchema.MAX_HISTORY_LENGTH then
		return false, "TaskHistory exceeds bound"
	end
	if type(record.CreatedAt) ~= "number" then
		return false, "invalid CreatedAt"
	end
	if type(record.LastLogin) ~= "number" then
		return false, "invalid LastLogin"
	end

	if record.ActiveSession ~= nil then
		if type(record.ActiveSession) ~= "table" then
			return false, "invalid ActiveSession shape"
		end
		if type(record.ActiveSession.Token) ~= "string" or #record.ActiveSession.Token == 0 then
			return false, "invalid ActiveSession.Token"
		end
		if type(record.ActiveSession.ClaimedAt) ~= "number" then
			return false, "invalid ActiveSession.ClaimedAt"
		end
	end

	return true
end

--[[
	Returns a NEW list with `item` appended and the oldest entries dropped
	so the result never exceeds maxLen. Does not mutate `list`.

	Not called by any Phase 0 code path yet (there is no Task system to
	produce history entries) - included now as tested infrastructure so
	Phase 1's Task system has a correct, already-verified primitive to
	build on, per technical architecture §6's bounded-history requirement.
]]
function PlayerDataSchema.AppendBounded(list, item, maxLen)
	assert(type(list) == "table", "list must be a table")
	maxLen = maxLen or PlayerDataSchema.MAX_HISTORY_LENGTH

	local result = {}
	for i = 1, #list do
		result[i] = list[i]
	end
	table.insert(result, item)

	while #result > maxLen do
		table.remove(result, 1)
	end

	return result
end

return PlayerDataSchema
