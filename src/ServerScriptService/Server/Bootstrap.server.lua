--[[
	Bootstrap.server.lua - Phase 0 entry point.

	Wires the persistence skeleton (DataStoreWrapper, OrganizationService,
	PlayerDataService) to live Roblox services: Players.PlayerAdded/
	PlayerRemoving and game:BindToClose.

	This is deliberately the ONLY file in Phase 0 that touches
	game:GetService(...) / Players / DataStoreService directly - every
	other module is dependency-injected and Roblox-independent so it can
	be unit/integration tested outside Roblox (see tests/ and
	docs/technical-architecture-v0.1.md §18-§19). Keep this file thin;
	real logic belongs in the modules it wires together, not here.

	Phase 0 scope only. Deliberately does NOT implement:
	Tasks, Proposals, Promotions, Economy gameplay, Influence mechanics,
	Organization gameplay, hiring/firing, Departments, Branches,
	Contracts, Founder system, M&A, Courts, Governance, Monetization, or
	any client-facing UI/Remote. See docs/mvp-definition-v0.1.md Phase 0
	and docs/technical-architecture-v0.1.md.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerDataSchema = require(Shared.Types.PlayerData)
local OrganizationDataSchema = require(Shared.Types.OrganizationData)
local SeedOrganizations = require(Shared.Data.SeedOrganizations)
local RetryPolicy = require(Shared.Logic.RetryPolicy)
local SessionLock = require(Shared.Logic.SessionLock)

local DataStoreWrapper = require(script.Parent.DataStoreWrapper)
local OrganizationService = require(script.Parent.OrganizationService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local wrapper = DataStoreWrapper.new({
	retryPolicy = RetryPolicy,
	wait = task.wait,
	log = function(msg)
		warn("[DataStoreWrapper] " .. msg)
	end,
})

-- Versioned DataStore names (technical architecture §6-§7): bump the
-- suffix if a future breaking schema change requires a clean split
-- rather than an in-place migration.
local playerStore = DataStoreService:GetDataStore("PlayerData_v1")
local orgStore = DataStoreService:GetDataStore("OrganizationData_v1")

local organizationService = OrganizationService.new({
	wrapper = wrapper,
	store = orgStore,
	schema = OrganizationDataSchema,
	seedOrganizations = SeedOrganizations,
})

local playerDataService = PlayerDataService.new({
	wrapper = wrapper,
	store = playerStore,
	organizationService = organizationService,
	schema = PlayerDataSchema,
	sessionLock = SessionLock,
	jobId = game.JobId,
	log = function(msg)
		warn("[PlayerDataService] " .. msg)
	end,
})

local DEFAULT_ORG_ID = SeedOrganizations.DEFAULT_ORG_ID

local function onPlayerAdded(player)
	local ok, resultOrErr = playerDataService:LoadPlayer(player.UserId, DEFAULT_ORG_ID)
	if not ok then
		warn(
			string.format(
				"[Bootstrap] Failed to load data for %s (%d): %s",
				player.Name,
				player.UserId,
				tostring(resultOrErr)
			)
		)
		player:Kick("We couldn't load your data right now. Please rejoin in a moment.")
	end
end

local function onPlayerRemoving(player)
	local ok, err = playerDataService:SavePlayer(player.UserId, { release = true })
	if not ok then
		warn(
			string.format(
				"[Bootstrap] Failed to save data for %s (%d): %s",
				player.Name,
				player.UserId,
				tostring(err)
			)
		)
	end
end

-- Handle any players already present when this script starts (e.g. a
-- script restart mid-session in Studio).
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	playerDataService:SaveAll({ release = true })
end)
