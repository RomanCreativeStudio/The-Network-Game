--[[
	PlayerDataService - the player join/leave persistence lifecycle
	(docs/technical-architecture-v0.1.md §14), including default-record
	creation (§10), session-lock claim/release (§5, §16), and safe,
	non-clobbering saves (§15, §16).

	Phase 0 scope: this service loads and saves PlayerData records and
	loads the player's associated OrganizationData record. It does NOT
	implement any gameplay mutation of that data (no Task/Promotion/Economy
	logic writes through this service in Phase 0).

	Dependency-injected (schema, sessionLock, wrapper, store,
	organizationService all passed via config) so this module has zero
	internal `require` calls and can be exercised by the standalone test
	suite against a fake DataStore and a fake OrganizationService - see
	technical-architecture-v0.1.md §18.
]]

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

--[[
	config:
		wrapper (required) - a DataStoreWrapper instance
		store (required) - a DataStore-like object (real or fake) for player records
		organizationService (required) - an OrganizationService instance
		schema (required) - the PlayerData schema module (CreateDefault, Validate)
		sessionLock (required) - the SessionLock logic module
		jobId (optional) - this server's identifier for session tokens; defaults to "unknown-job"
		now (optional) - function() -> number, defaults to os.time
		random (optional) - function(lo, hi) -> number, defaults to math.random
		log (optional) - function(message), defaults to a no-op
]]
function PlayerDataService.new(config)
	config = config or {}
	assert(config.wrapper, "PlayerDataService requires config.wrapper")
	assert(config.store, "PlayerDataService requires config.store")
	assert(config.organizationService, "PlayerDataService requires config.organizationService")
	assert(config.schema, "PlayerDataService requires config.schema")
	assert(config.sessionLock, "PlayerDataService requires config.sessionLock")

	local self = setmetatable({}, PlayerDataService)
	self._wrapper = config.wrapper
	self._store = config.store
	self._orgService = config.organizationService
	self._schema = config.schema
	self._sessionLock = config.sessionLock
	self._jobId = config.jobId or "unknown-job"
	self._now = config.now or os.time
	self._random = config.random or math.random
	self._log = config.log or function() end

	-- userId -> { record = PlayerData, orgRecord = OrganizationData, token = string }
	self._sessions = {}

	return self
end

function PlayerDataService:_key(userId)
	return "Player_" .. tostring(userId)
end

--[[
	Loads (creating a default record if this is the player's first join)
	the PlayerData for `userId`, claims the session lock for this server,
	and loads the player's associated OrganizationData.

	`defaultOrgId` is used only when creating a brand-new record.

	Returns (true, sessionInfo) on success, where sessionInfo is
	{ record, orgRecord, token }, or (false, errorMessage) on failure -
	including: a corrupt existing record, the record being actively
	locked by another server, or the associated organization failing to
	load.
]]
function PlayerDataService:LoadPlayer(userId, defaultOrgId)
	assert(type(userId) == "number", "userId must be a number")
	assert(type(defaultOrgId) == "string" and #defaultOrgId > 0, "defaultOrgId must be a non-empty string")

	local key = self:_key(userId)
	local now = self._now()
	local myToken = self._sessionLock.NewToken(self._jobId, userId, now, self._random(1, 1000000000))

	local claimedRecord = nil
	local claimError = nil
	local schema = self._schema
	local sessionLock = self._sessionLock

	local ok, result = self._wrapper:Update(self._store, key, function(old)
		if old == nil then
			local fresh = schema.CreateDefault(userId, defaultOrgId)
			fresh.ActiveSession = sessionLock.Claim(myToken, now)
			claimedRecord = fresh
			return fresh
		end

		local valid, reason = schema.Validate(old)
		if not valid then
			-- Never silently repair/coerce a corrupt record - abort the
			-- write and surface the failure (Phase 0 success criterion:
			-- "duplicate/invalid data is rejected safely").
			claimError = "corrupt record: " .. tostring(reason)
			return nil
		end

		local canClaim, why = sessionLock.EvaluateClaim(old.ActiveSession, myToken, now)
		if not canClaim then
			claimError = "locked: " .. tostring(why)
			return nil
		end

		local updated = {}
		for k, v in pairs(old) do
			updated[k] = v
		end
		updated.ActiveSession = sessionLock.Claim(myToken, now)
		updated.LastLogin = now
		claimedRecord = updated
		return updated
	end)

	if not ok then
		return false, "datastore error: " .. tostring(result)
	end
	if claimError then
		return false, claimError
	end
	if claimedRecord == nil then
		return false, "unknown load failure"
	end

	local orgOk, orgRecordOrErr = self._orgService:GetOrCreateOrganization(claimedRecord.OrgId)
	if not orgOk then
		-- Don't leave a lock held with nothing successfully loaded.
		self:_releaseLock(userId, myToken)
		return false, "organization load failed: " .. tostring(orgRecordOrErr)
	end

	self._sessions[userId] = {
		record = claimedRecord,
		orgRecord = orgRecordOrErr,
		token = myToken,
	}
	return true, self._sessions[userId]
end

-- Internal: best-effort release of a lock this server claimed but is
-- abandoning (e.g. because the associated organization failed to load).
function PlayerDataService:_releaseLock(userId, token)
	local key = self:_key(userId)
	local sessionLock = self._sessionLock

	self._wrapper:Update(self._store, key, function(old)
		if old == nil then
			return nil
		end
		local released = {}
		for k, v in pairs(old) do
			released[k] = v
		end
		released.ActiveSession = sessionLock.Release(old.ActiveSession, token)
		return released
	end)
end

--[[
	Saves the currently-loaded record for `userId`. Refuses to overwrite
	the stored record if another session has claimed the lock since this
	server loaded it (Phase 0 success criterion: "saves do not overwrite
	newer state incorrectly").

	opts.release (boolean, default false): if true, clears the session
	lock (used on player leave); if false, re-claims it (used for a
	future periodic-autosave checkpoint that keeps the session alive).

	Returns (true) on success, or (false, errorMessage) on failure.
]]
function PlayerDataService:SavePlayer(userId, opts)
	opts = opts or {}
	local session = self._sessions[userId]
	if not session then
		return false, "no active session for user"
	end

	local key = self:_key(userId)
	local now = self._now()
	local schema = self._schema
	local sessionLock = self._sessionLock
	local saveError = nil

	local ok, result = self._wrapper:Update(self._store, key, function(old)
		if old ~= nil then
			local valid = schema.Validate(old)
			if
				valid
				and old.ActiveSession ~= nil
				and type(old.ActiveSession) == "table"
				and old.ActiveSession.Token ~= session.token
			then
				-- Another session claimed this record after ours did.
				-- Never blindly overwrite a session we no longer own -
				-- and, critically, record WHY we aborted so the caller
				-- gets an honest failure instead of a false "success"
				-- (the DataStore call itself still completes without
				-- error, so `ok` alone can't distinguish "wrote" from
				-- "intentionally declined to write").
				saveError = "stale session: another server now owns this record"
				return nil
			end
		end

		local toSave = {}
		for k, v in pairs(session.record) do
			toSave[k] = v
		end
		toSave.LastLogin = now

		if opts.release then
			toSave.ActiveSession = nil
		else
			toSave.ActiveSession = sessionLock.Claim(session.token, now)
		end

		return toSave
	end)

	if not ok then
		return false, "datastore error: " .. tostring(result)
	end
	if saveError then
		return false, saveError
	end

	if opts.release then
		self._sessions[userId] = nil
	end

	return true
end

--[[
	Applies a task-completion reward to the currently-loaded record for
	`userId`. This is the ONLY code path that mutates PersonalMoney/
	PerformanceRating/PerformanceHistory/Reputation/TaskHistory -
	TaskService computes the reward (from server-side task/choice
	definitions plus, where a choice has multiple weighted outcomes, a
	server-generated roll - never from client input) and hands it here so
	PlayerDataService stays the single owner of PlayerData's field-level
	invariants (bounded history lists, non-negative money), the same role
	it already plays for schema validation elsewhere in this file.

	reward: {
		MoneyGain = number,
		PerformanceGain = number,
		ReputationGain = number (optional, defaults to 0 - added in Phase 2;
			omitting it preserves Phase 1 callers' exact prior behavior),
		HistoryEntry = table,  -- appended to the bounded TaskHistory log
	}

	Returns (true, updatedRecord) on success, or (false, errorMessage) if
	the player has no active session. Does not persist to DataStore by
	itself - the caller (or the periodic autosave loop) is responsible
	for calling SavePlayer/SaveAll afterward.
]]
function PlayerDataService:ApplyTaskCompletion(userId, reward)
	assert(type(reward) == "table", "reward must be a table")
	assert(type(reward.MoneyGain) == "number", "reward.MoneyGain must be a number")
	assert(type(reward.PerformanceGain) == "number", "reward.PerformanceGain must be a number")
	assert(
		reward.ReputationGain == nil or type(reward.ReputationGain) == "number",
		"reward.ReputationGain must be a number when provided"
	)

	local session = self._sessions[userId]
	if not session then
		return false, "no active session for user"
	end

	local record = session.record
	local schema = self._schema
	local reputationGain = reward.ReputationGain or 0

	record.PersonalMoney = record.PersonalMoney + reward.MoneyGain
	record.PerformanceRating = record.PerformanceRating + reward.PerformanceGain
	record.PerformanceHistory = schema.AppendBounded(record.PerformanceHistory, reward.PerformanceGain)
	record.Reputation = record.Reputation + reputationGain

	if reward.HistoryEntry ~= nil then
		record.TaskHistory = schema.AppendBounded(record.TaskHistory, reward.HistoryEntry)
	end

	return true, record
end

-- Returns the in-memory PlayerData record for a currently-loaded session,
-- or nil if the player has no active session on this server.
function PlayerDataService:GetLoadedRecord(userId)
	local session = self._sessions[userId]
	if not session then
		return nil
	end
	return session.record
end

-- Returns the in-memory OrganizationData record associated with a
-- currently-loaded session, or nil if the player has no active session.
function PlayerDataService:GetLoadedOrganization(userId)
	local session = self._sessions[userId]
	if not session then
		return nil
	end
	return session.orgRecord
end

-- Saves every currently-loaded session (used by game:BindToClose).
function PlayerDataService:SaveAll(opts)
	for userId in pairs(self._sessions) do
		self:SavePlayer(userId, opts)
	end
end

return PlayerDataService
