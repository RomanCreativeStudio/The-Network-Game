--[[
	PromotionService - server-authoritative rank promotion (Phase 3).

	SECURITY MODEL: there is NO client-facing entry point that requests a
	promotion. Promotion is checked as a SIDE EFFECT of TaskService
	completing a task (see TaskService.lua's CompleteTask), which is
	itself only ever reachable through the engine-verified
	`player.UserId` in Bootstrap.server.lua's Remote handlers. The client
	can never invoke CheckAndPromote directly, never supplies a "desired
	rank," and never supplies Performance/Reputation values - both are
	read from the server-held PlayerData record via PlayerDataService.
	This is the concrete, minimal implementation of Technical
	Architecture §11: "Promotion checking runs server-side, triggered
	after each Task completion (event-driven, not polled)."

	Threshold VALUES are PLAYTEST CALIBRATION (see
	Shared/Data/PromotionConfig.lua); the AND-gate SHAPE they're checked
	against is locked (see Shared/Logic/PromotionRules.lua). This module
	never reads or writes Money - promotion eligibility has no path to
	Money at all (Phase 3A finding #8).

	Dependency-injected (playerDataService, promotionRules,
	promotionConfig, schema all passed via config) so this module has
	zero internal `require` calls and can be exercised by the standalone
	test suite against a fake PlayerDataService - see
	technical-architecture-v0.1.md §18.
]]

local PromotionService = {}
PromotionService.__index = PromotionService

--[[
	config:
		playerDataService (required) - a Phase 0 PlayerDataService instance
		promotionRules (required) - the PromotionRules logic module
		promotionConfig (required) - a PromotionConfig threshold table,
			e.g. PromotionConfig.ASSOCIATE_TO_MANAGER (PLAYTEST CALIBRATION)
		schema (required) - the PlayerData schema module (for RANK constants)
		log (optional) - function(message), defaults to a no-op
]]
function PromotionService.new(config)
	config = config or {}
	assert(config.playerDataService, "PromotionService requires config.playerDataService")
	assert(config.promotionRules, "PromotionService requires config.promotionRules")
	assert(config.promotionConfig, "PromotionService requires config.promotionConfig")
	assert(config.schema, "PromotionService requires config.schema")

	local self = setmetatable({}, PromotionService)
	self._playerDataService = config.playerDataService
	self._promotionRules = config.promotionRules
	self._promotionConfig = config.promotionConfig
	self._schema = config.schema
	self._log = config.log or function() end

	return self
end

--[[
	Returns (true, status) describing `userId`'s current progression
	state - this is the data behind the Phase 3 "clear player-facing
	explanation" requirement: current rank, current Performance/
	Reputation, the thresholds required for the next promotion, and
	whether they are currently eligible. Read-only; never mutates
	anything. Returns (false, errorMessage) if the player has no active
	session.
]]
function PromotionService:GetStatus(userId)
	local record = self._playerDataService:GetLoadedRecord(userId)
	if not record then
		return false, "no active session for user"
	end

	local eligible = false
	if record.Rank == self._schema.RANK.ASSOCIATE then
		eligible = self._promotionRules.MeetsThresholds(record.PerformanceRating, record.Reputation, self._promotionConfig)
	end

	return true, {
		Rank = record.Rank,
		PerformanceRating = record.PerformanceRating,
		Reputation = record.Reputation,
		PerformanceThreshold = self._promotionConfig.PerformanceThreshold,
		ReputationThreshold = self._promotionConfig.ReputationThreshold,
		EligibleForPromotion = eligible,
	}
end

--[[
	Checks `userId`'s eligibility and, if met, applies the Associate ->
	Manager promotion. Returns (true, promotionInfo) only when a
	promotion actually just happened; returns (false, reason) both when
	the player is not yet eligible AND when they are not on the
	Associate rank at all (already Manager, or any future rank) - this
	single check is what prevents duplicate promotion: a second call
	against an already-Manager record always returns false, never
	re-applies anything.

	promotionInfo: { PreviousRank, NewRank, PerformanceRating, Reputation,
	  PerformanceThreshold, ReputationThreshold, Unlocked }
]]
function PromotionService:CheckAndPromote(userId)
	local record = self._playerDataService:GetLoadedRecord(userId)
	if not record then
		return false, "no active session for user"
	end

	if record.Rank ~= self._schema.RANK.ASSOCIATE then
		-- Covers "already Manager" (duplicate-promotion prevention) and
		-- any future rank this service doesn't yet know how to advance.
		return false, "not eligible for promotion from current rank"
	end

	local eligible, reason =
		self._promotionRules.MeetsThresholds(record.PerformanceRating, record.Reputation, self._promotionConfig)
	if not eligible then
		return false, reason
	end

	local applyOk, updatedRecordOrErr = self._playerDataService:ApplyPromotion(userId, self._schema.RANK.MANAGER)
	if not applyOk then
		return false, "failed to apply promotion: " .. tostring(updatedRecordOrErr)
	end

	return true, {
		PreviousRank = self._schema.RANK.ASSOCIATE,
		NewRank = self._schema.RANK.MANAGER,
		PerformanceRating = updatedRecordOrErr.PerformanceRating,
		Reputation = updatedRecordOrErr.Reputation,
		PerformanceThreshold = self._promotionConfig.PerformanceThreshold,
		ReputationThreshold = self._promotionConfig.ReputationThreshold,
		Unlocked = "You can now assign this task to another Associate in your organization.",
	}
end

return PromotionService
