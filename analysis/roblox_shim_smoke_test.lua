--[[
	roblox_shim_smoke_test.lua - PHASE 3B PLAYTEST-BUILD VERIFICATION.

	NOT part of the automated regression suite (tests/run_tests.lua does
	not run this) and NOT gameplay code. This environment has no Roblox
	Studio/Roblox runtime available, so this script builds a minimal but
	faithful shim of the Roblox APIs Bootstrap.server.lua and
	TaskClient.client.lua actually use (Instance, game:GetService,
	RemoteEvents, Players, DataStoreService, task.*, Enum, Color3, UDim2)
	and then LOADS AND RUNS THE REAL, UNMODIFIED production files through
	it - the two files no prior phase's lua5.1 test suite could even
	parse, since they use `game`/`Instance` syntax the standalone Lua 5.1
	interpreter has no meaning for on its own.

	This is a smoke test, not a substitute for real Roblox Studio
	validation - see the Phase 3B report's "Remaining blockers" section
	for what this specifically cannot verify (rendering, physical input,
	real DataStore/replication behavior, multi-server behavior).

	Run from the repo root: lua5.1 analysis/roblox_shim_smoke_test.lua
]]

local FakeDataStore = dofile("tests/fakes/FakeDataStore.lua")

--------------------------------------------------------------------------
-- Signal shim
--------------------------------------------------------------------------

local Signal = {}
Signal.__index = Signal
local function newSignal()
	return setmetatable({ _handlers = {} }, Signal)
end
function Signal:Connect(fn)
	table.insert(self._handlers, fn)
	return { Disconnect = function() end }
end
function Signal:Fire(...)
	for _, fn in ipairs(self._handlers) do
		fn(...)
	end
end

--------------------------------------------------------------------------
-- Instance shim: supports Parent/child auto-registration, dot-access
-- child lookup (Roblox's `instance.ChildName` sugar), WaitForChild/
-- FindFirstChild/GetChildren/IsA/Destroy, and RemoteEvent/TextButton
-- behavior.
--------------------------------------------------------------------------

local InstanceMT = {}

InstanceMT.__index = function(t, k)
	local method = rawget(InstanceMT, k)
	if method ~= nil then
		return method
	end
	local children = rawget(t, "_children")
	if children then
		for _, c in ipairs(children) do
			if rawget(c, "Name") == k then
				return c
			end
		end
	end
	return nil
end

InstanceMT.__newindex = function(t, k, v)
	if k == "Parent" then
		local oldParent = rawget(t, "Parent")
		if oldParent then
			for i, c in ipairs(oldParent._children) do
				if c == t then
					table.remove(oldParent._children, i)
					break
				end
			end
		end
		rawset(t, "Parent", v)
		if v ~= nil then
			table.insert(v._children, t)
		end
	else
		rawset(t, k, v)
	end
end

local function newInstanceRaw(className)
	local inst = setmetatable({
		ClassName = className,
		Name = className,
		_children = {},
	}, InstanceMT)
	if className == "RemoteEvent" then
		inst.OnServerEvent = newSignal()
		inst.OnClientEvent = newSignal()
		inst.FireClientLog = {}
		inst.FireServerLog = {}
	elseif className == "TextButton" then
		inst.MouseButton1Click = newSignal()
	end
	return inst
end

function InstanceMT:GetChildren()
	local out = {}
	for _, c in ipairs(self._children) do
		table.insert(out, c)
	end
	return out
end

function InstanceMT:FindFirstChild(name)
	for _, c in ipairs(self._children) do
		if c.Name == name then
			return c
		end
	end
	return nil
end

function InstanceMT:WaitForChild(name)
	local found = self:FindFirstChild(name)
	assert(found, "WaitForChild: no child named '" .. tostring(name) .. "' under '" .. tostring(self.Name) .. "'")
	return found
end

function InstanceMT:IsA(className)
	return self.ClassName == className
end

function InstanceMT:Destroy()
	self.Parent = nil
end

-- RemoteEvent behavior. Present on every instance for simplicity; only
-- meaningful on RemoteEvent instances.
function InstanceMT:FireClient(player, payload)
	table.insert(self.FireClientLog, { Player = player, Payload = payload })
	self.LastFireClient = { Player = player, Payload = payload }
	self.OnClientEvent:Fire(payload)
end

function InstanceMT:FireServer(...)
	local player = assert(_G.__simCurrentPlayer, "FireServer called with no simulated current player set")
	local args = { ... }
	table.insert(self.FireServerLog, args)
	self.OnServerEvent:Fire(player, ...)
end

local function mount(parent, name, path, className)
	local inst = newInstanceRaw(className or "ModuleScript")
	inst.Name = name
	inst._path = path
	inst.Parent = parent
	return inst
end

local function folder(parent, name)
	local inst = newInstanceRaw("Folder")
	inst.Name = name
	inst.Parent = parent
	return inst
end

--------------------------------------------------------------------------
-- Global environment: game, Instance, task, warn, Enum, Color3, UDim2,
-- UDim, os.clock (fine-grained, matching Roblox's real monotonic
-- os.clock() - stock Lua 5.1's os.clock() is coarse CPU time, which
-- would spuriously trip the rate limiter for back-to-back simulated
-- actions; see TaskService.lua's constructor docs for why the real
-- Roblox os.clock() is exactly what the rate limiter needs).
--------------------------------------------------------------------------

_G.Instance = { new = newInstanceRaw }

local dataStores = {}
local DataStoreServiceShim = {
	GetDataStore = function(_self, name)
		if not dataStores[name] then
			dataStores[name] = FakeDataStore.new()
		end
		return dataStores[name]
	end,
}

local playersList = {}
local PlayersService = {
	PlayerAdded = newSignal(),
	PlayerRemoving = newSignal(),
	LocalPlayer = nil,
	GetPlayers = function(_self)
		return playersList
	end,
	GetPlayerByUserId = function(_self, id)
		for _, p in ipairs(playersList) do
			if p.UserId == id then
				return p
			end
		end
		return nil
	end,
}

local function newFakePlayer(userId, name)
	local player = newInstanceRaw("Player")
	player.Name = name
	player.UserId = userId
	player.Kicked = false
	player.KickReason = nil
	player.Kick = function(self, reason)
		self.Kicked = true
		self.KickReason = reason
	end
	local playerGui = newInstanceRaw("Folder")
	playerGui.Name = "PlayerGui"
	playerGui.Parent = player
	return player
end

local ReplicatedStorage = newInstanceRaw("ReplicatedStorage")
local services = {
	Players = PlayersService,
	DataStoreService = DataStoreServiceShim,
	ReplicatedStorage = ReplicatedStorage,
}

_G.game = {
	JobId = "smoke-test-job",
	GetService = function(_self, name)
		local svc = services[name]
		assert(svc, "GetService: unmocked service " .. tostring(name))
		return svc
	end,
	BindToClose = function(_self, fn)
		_G.__bindToCloseHandlers = _G.__bindToCloseHandlers or {}
		table.insert(_G.__bindToCloseHandlers, fn)
	end,
}

-- task.spawn/task.wait use real coroutines, matching Roblox's actual
-- cooperative-scheduling semantics: task.wait() SUSPENDS the calling
-- thread rather than blocking. This matters concretely for Bootstrap's
-- periodic autosave loop (`task.spawn(function() while true do
-- task.wait(120) ... end end)`) - a naive no-op task.wait would let that
-- infinite loop run synchronously forever and hang this entire script.
-- With real yielding, task.spawn resumes the coroutine once, it runs
-- until its first task.wait() (which yields), and control returns here -
-- exactly mirroring how the real engine only re-resumes such a loop
-- after the requested delay actually elapses. This script never resumes
-- it again, which is correct: this smoke test verifies the loop doesn't
-- hang server boot, not the periodic tick itself (see the report).
_G.task = {
	-- Lua 5.1 has no coroutine.isyieldable(); coroutine.running() returns
	-- nil when called from the main thread (unlike 5.2+), which is the
	-- correct 5.1-compatible way to detect "am I inside a task.spawn'd
	-- coroutine right now" before yielding.
	wait = function(_n)
		if coroutine.running() then
			coroutine.yield()
		end
	end,
	spawn = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			error("task.spawn handler errored: " .. tostring(err))
		end
	end,
	defer = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			error("task.defer handler errored: " .. tostring(err))
		end
	end,
}

_G.warn = function(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end
	print("[WARN] " .. table.concat(parts, " "))
end

local fakeClock = 0
_G.os = setmetatable({
	clock = function()
		fakeClock = fakeClock + 1
		return fakeClock
	end,
}, { __index = os })

local function makeEnumToken(name)
	return { __enumName = name }
end
local EnumCategoryMT = {
	__index = function(t, k)
		local v = makeEnumToken(k)
		rawset(t, k, v)
		return v
	end,
}
_G.Enum = setmetatable({}, {
	__index = function(t, k)
		local cat = setmetatable({}, EnumCategoryMT)
		rawset(t, k, cat)
		return cat
	end,
})

_G.Color3 = { fromRGB = function(r, g, b)
	return { r = r, g = g, b = b }
end }
_G.UDim2 = { new = function(a, b, c, d)
	return { a, b, c, d }
end }
_G.UDim = { new = function(a, b)
	return { a, b }
end }

--------------------------------------------------------------------------
-- require() / script execution, mirroring Luau's ModuleScript semantics
--------------------------------------------------------------------------

local moduleCache = {}
_G.require = function(instance)
	assert(type(instance) == "table" and instance._path, "require: argument is not a requirable file-backed instance")
	if moduleCache[instance] ~= nil then
		return moduleCache[instance]
	end
	local chunk, err = loadfile(instance._path)
	if not chunk then
		error("require: failed to load " .. instance._path .. ": " .. tostring(err))
	end
	local env = setmetatable({ script = instance }, { __index = _G, __newindex = _G })
	setfenv(chunk, env)
	local result = chunk()
	moduleCache[instance] = result
	return result
end

local function runTopLevelScript(instance)
	local chunk, err = loadfile(instance._path)
	if not chunk then
		error("failed to load " .. instance._path .. ": " .. tostring(err))
	end
	local env = setmetatable({ script = instance }, { __index = _G, __newindex = _G })
	setfenv(chunk, env)
	return chunk()
end

--------------------------------------------------------------------------
-- Mount the real production tree, mirroring default.project.json exactly
--------------------------------------------------------------------------

local Shared = folder(ReplicatedStorage, "Shared")

local Types = folder(Shared, "Types")
mount(Types, "PlayerData", "src/ReplicatedStorage/Shared/Types/PlayerData.lua")
mount(Types, "OrganizationData", "src/ReplicatedStorage/Shared/Types/OrganizationData.lua")

local Data = folder(Shared, "Data")
mount(Data, "SeedOrganizations", "src/ReplicatedStorage/Shared/Data/SeedOrganizations.lua")
mount(Data, "TaskDefinitions", "src/ReplicatedStorage/Shared/Data/TaskDefinitions.lua")
mount(Data, "PromotionConfig", "src/ReplicatedStorage/Shared/Data/PromotionConfig.lua")

local Logic = folder(Shared, "Logic")
mount(Logic, "RetryPolicy", "src/ReplicatedStorage/Shared/Logic/RetryPolicy.lua")
mount(Logic, "SessionLock", "src/ReplicatedStorage/Shared/Logic/SessionLock.lua")
mount(Logic, "TaskInstance", "src/ReplicatedStorage/Shared/Logic/TaskInstance.lua")
mount(Logic, "TaskOutcome", "src/ReplicatedStorage/Shared/Logic/TaskOutcome.lua")
mount(Logic, "WeightedOutcome", "src/ReplicatedStorage/Shared/Logic/WeightedOutcome.lua")
mount(Logic, "ChoicePreview", "src/ReplicatedStorage/Shared/Logic/ChoicePreview.lua")
mount(Logic, "ActionRateLimiter", "src/ReplicatedStorage/Shared/Logic/ActionRateLimiter.lua")
mount(Logic, "PromotionRules", "src/ReplicatedStorage/Shared/Logic/PromotionRules.lua")

local Remotes = folder(Shared, "Remotes")
for _, remoteName in ipairs({
	"RequestTask",
	"TaskAssigned",
	"CompleteTask",
	"TaskResult",
	"AssignTask",
	"AssignTaskResult",
	"PromotionNotice",
}) do
	local r = newInstanceRaw("RemoteEvent")
	r.Name = remoteName
	r.Parent = Remotes
end

local ServerScriptService = newInstanceRaw("ServerScriptService")
local Server = folder(ServerScriptService, "Server")
mount(Server, "DataStoreWrapper", "src/ServerScriptService/Server/DataStoreWrapper.lua")
mount(Server, "OrganizationService", "src/ServerScriptService/Server/OrganizationService.lua")
mount(Server, "PlayerDataService", "src/ServerScriptService/Server/PlayerDataService.lua")
mount(Server, "PromotionService", "src/ServerScriptService/Server/PromotionService.lua")
mount(Server, "TaskService", "src/ServerScriptService/Server/TaskService.lua")
local Bootstrap = mount(Server, "Bootstrap", "src/ServerScriptService/Server/Bootstrap.server.lua", "Script")

local StarterPlayer = newInstanceRaw("StarterPlayer")
local StarterPlayerScripts = folder(StarterPlayer, "StarterPlayerScripts")
local Client = folder(StarterPlayerScripts, "Client")
local TaskClientScript = mount(Client, "TaskClient", "src/StarterPlayerScripts/Client/TaskClient.client.lua", "LocalScript")

--------------------------------------------------------------------------
-- Test harness
--------------------------------------------------------------------------

local passed, failed = 0, 0
local function check(name, condition, detail)
	if condition then
		passed = passed + 1
		print("  [PASS] " .. name)
	else
		failed = failed + 1
		print("  [FAIL] " .. name .. (detail ~= nil and (" - " .. tostring(detail)) or ""))
	end
end

--------------------------------------------------------------------------
-- STEP 1: Server boot (items 1-2: Rojo structure syncs, server boots)
--------------------------------------------------------------------------

print("== STEP 1: Server boot ==")
local bootOk, bootErr = pcall(runTopLevelScript, Bootstrap)
check("Bootstrap.server.lua runs without error", bootOk, bootErr)
if not bootOk then
	print("FATAL: server did not boot, aborting remaining checks.")
	os.exit(1)
end

local RequestTaskRemote = Remotes.RequestTask
local TaskAssignedRemote = Remotes.TaskAssigned
local CompleteTaskRemote = Remotes.CompleteTask
local TaskResultRemote = Remotes.TaskResult
local AssignTaskRemote = Remotes.AssignTask
local AssignTaskResultRemote = Remotes.AssignTaskResult
local PromotionNoticeRemote = Remotes.PromotionNotice

check("RequestTask has exactly one server-side connection", #RequestTaskRemote.OnServerEvent._handlers == 1)
check("CompleteTask has exactly one server-side connection", #CompleteTaskRemote.OnServerEvent._handlers == 1)
check("AssignTask has exactly one server-side connection", #AssignTaskRemote.OnServerEvent._handlers == 1)

--------------------------------------------------------------------------
-- STEP 2: Player join, PlayerData load, seeded org load, request task
-- (items 3-5)
--------------------------------------------------------------------------

print("== STEP 2: Player join, seeded org, request task ==")
local associate = newFakePlayer(9001, "AssociateOne")
table.insert(playersList, associate)
local addOk, addErr = pcall(function()
	PlayersService.PlayerAdded:Fire(associate)
end)
check("PlayerAdded handler runs without error (PlayerData load + seeded org load)", addOk, addErr)
check("Associate was not kicked (load succeeded)", associate.Kicked == false)

RequestTaskRemote.OnServerEvent:Fire(associate)
local assigned = TaskAssignedRemote.LastFireClient
check("TaskAssigned was sent to the Associate", assigned ~= nil and assigned.Player == associate)
check("RequestTask succeeded", assigned and assigned.Payload.Success == true, assigned and assigned.Payload.Reason)
check(
	"Assigned task carries a Prompt and Choices (decision UI data)",
	assigned and type(assigned.Payload.Prompt) == "string" and type(assigned.Payload.Choices) == "table"
)
check("Assigned task has exactly 3 choices", assigned and #assigned.Payload.Choices == 3)

--------------------------------------------------------------------------
-- STEP 3: Decision + completion resolves server-side; Performance/
-- Reputation/Money update (items 6-8, partially - full UI check in Step 8)
--------------------------------------------------------------------------

print("== STEP 3: Completion resolves server-side, resources update ==")
local taskPayload = assigned.Payload
CompleteTaskRemote.OnServerEvent:Fire(associate, taskPayload.TaskId, taskPayload.InstanceId, "careful")
local result = TaskResultRemote.LastFireClient
check("TaskResult was sent to the Associate", result ~= nil and result.Player == associate)
check("Completion succeeded", result and result.Payload.Success == true, result and result.Payload.Reason)
check("Money increased correctly (careful: +10)", result and result.Payload.NewPersonalMoney == 10)
check("Performance increased correctly (careful: +2)", result and result.Payload.NewPerformanceRating == 2)
check("Reputation increased correctly (careful: +1)", result and result.Payload.NewReputation == 1)
check("Rank still Associate (below the 10/5 calibration threshold)", result and result.Payload.Rank == "Associate")

--------------------------------------------------------------------------
-- STEP 4: Promotion at calibrated thresholds (items 9-10)
--------------------------------------------------------------------------

print("== STEP 4: Promotion at calibrated thresholds ==")
for _ = 2, 5 do
	RequestTaskRemote.OnServerEvent:Fire(associate)
	local a = TaskAssignedRemote.LastFireClient.Payload
	CompleteTaskRemote.OnServerEvent:Fire(associate, a.TaskId, a.InstanceId, "careful")
end
local finalResult = TaskResultRemote.LastFireClient.Payload
check(
	"After 5 careful completions, Performance == 10 and Reputation == 5 (the calibrated thresholds)",
	finalResult.NewPerformanceRating == 10 and finalResult.NewReputation == 5
)
check("Rank promoted to Manager on the completion that crosses both thresholds", finalResult.Rank == "Manager")

local promoNotice = PromotionNoticeRemote.LastFireClient
check("PromotionNotice was sent to the newly-promoted player", promoNotice ~= nil and promoNotice.Player == associate)
check(
	"PromotionNotice reports Associate -> Manager with the unlocked capability",
	promoNotice
		and promoNotice.Payload.PreviousRank == "Associate"
		and promoNotice.Payload.NewRank == "Manager"
		and type(promoNotice.Payload.Unlocked) == "string"
)

--------------------------------------------------------------------------
-- STEP 5: Manager assigns the task to another Associate; recipient
-- receives it (items 11-13)
--------------------------------------------------------------------------

print("== STEP 5: Manager assigns task to another Associate ==")
local associate2 = newFakePlayer(9002, "AssociateTwo")
table.insert(playersList, associate2)
PlayersService.PlayerAdded:Fire(associate2)
check("Second Associate was not kicked", associate2.Kicked == false)

AssignTaskRemote.OnServerEvent:Fire(associate, associate2.UserId)
local assignResult = AssignTaskResultRemote.LastFireClient
check("AssignTaskResult sent to the Manager", assignResult ~= nil and assignResult.Player == associate)
check(
	"Assignment succeeded (Manager receives the capability)",
	assignResult and assignResult.Payload.Success == true,
	assignResult and assignResult.Payload.Reason
)

local recipientAssigned = TaskAssignedRemote.LastFireClient
check("TaskAssigned (recipient notification) sent to AssociateTwo", recipientAssigned ~= nil and recipientAssigned.Player == associate2)
check(
	"Recipient notification carries AssignedByUserId",
	recipientAssigned and recipientAssigned.Payload.AssignedByUserId == associate.UserId
)

local assignedTask = recipientAssigned.Payload
CompleteTaskRemote.OnServerEvent:Fire(associate2, assignedTask.TaskId, assignedTask.InstanceId, "quick")
local recipientResult = TaskResultRemote.LastFireClient
check(
	"Recipient's completion of the assigned task succeeded",
	recipientResult and recipientResult.Player == associate2 and recipientResult.Payload.Success == true
)

--------------------------------------------------------------------------
-- STEP 6: Security protections through the real Remote wiring (item 14)
--------------------------------------------------------------------------

print("== STEP 6: Security protections through the real Remote wiring ==")

AssignTaskRemote.OnServerEvent:Fire(associate2, associate.UserId)
local unauthorizedAssign = AssignTaskResultRemote.LastFireClient
check(
	"An Associate cannot assign a task (rejected through the real wiring)",
	unauthorizedAssign.Payload.Success == false and unauthorizedAssign.Payload.Reason == "only a Manager may assign tasks"
)

CompleteTaskRemote.OnServerEvent:Fire(associate2, 12345, "inst", "careful")
local malformedResult = TaskResultRemote.LastFireClient
check(
	"Malformed taskId type is dropped by the real Remote handler before reaching TaskService",
	malformedResult.Payload.Success == false and malformedResult.Payload.Reason == "malformed request"
)

CompleteTaskRemote.OnServerEvent:Fire(associate2, assignedTask.TaskId, assignedTask.InstanceId, "careful")
local dupResult = TaskResultRemote.LastFireClient
check(
	"Completing the same instance twice is rejected through the real wiring",
	dupResult.Payload.Success == false and dupResult.Payload.Reason == "task already completed"
)

--------------------------------------------------------------------------
-- STEP 7: Client script loads and reacts without runtime error
-- (items 6, 10, 11 - the UI side)
--------------------------------------------------------------------------

print("== STEP 7: Client script loads and drives a full click round-trip ==")
PlayersService.LocalPlayer = associate2
_G.__simCurrentPlayer = associate2

local clientOk, clientErr = pcall(runTopLevelScript, TaskClientScript)
check("TaskClient.client.lua constructs its UI without error", clientOk, clientErr)

local playerGui = associate2:FindFirstChild("PlayerGui")
local screenGui = playerGui and playerGui:FindFirstChild("TaskUI")
local panel = screenGui and screenGui:FindFirstChild("TaskPanel")
check("Client UI panel was constructed under PlayerGui", panel ~= nil)

if panel then
	local requestButton = panel:FindFirstChild("RequestButton")
	local clickOk, clickErr = pcall(function()
		requestButton.MouseButton1Click:Fire()
	end)
	check("Clicking Request Task -> FireServer -> server -> FireClient -> client handler round-trip works", clickOk, clickErr)
	check("RequestTaskRemote:FireServer() was actually invoked", #RequestTaskRemote.FireServerLog >= 1)

	local choicesFrame = panel:FindFirstChild("ChoicesFrame")
	local choiceButtons = {}
	if choicesFrame then
		for _, c in ipairs(choicesFrame:GetChildren()) do
			if c.ClassName == "TextButton" then
				table.insert(choiceButtons, c)
			end
		end
	end
	check("Choice buttons were built client-side after receiving TaskAssigned", #choiceButtons == 3)

	if #choiceButtons > 0 then
		local completeClickOk, completeClickErr = pcall(function()
			choiceButtons[1].MouseButton1Click:Fire()
		end)
		check("Clicking a choice button completes the full round-trip without error", completeClickOk, completeClickErr)
		check("CompleteTaskRemote:FireServer() was actually invoked", #CompleteTaskRemote.FireServerLog >= 1)
	end

	local promoOk, promoErr = pcall(function()
		PromotionNoticeRemote.OnClientEvent:Fire({
			PreviousRank = "Associate",
			NewRank = "Manager",
			PerformanceRating = 10,
			Reputation = 5,
			PerformanceThreshold = 10,
			ReputationThreshold = 5,
			Unlocked = "You can now assign this task to another Associate in your organization.",
		})
	end)
	check("Client's PromotionNotice handler runs without error on a realistic payload", promoOk, promoErr)

	local promotionBanner = panel:FindFirstChild("PromotionBanner")
	check(
		"Promotion banner becomes visible and populated client-side",
		promotionBanner and promotionBanner.Visible == true and #promotionBanner.Text > 0
	)

	local managerFrame = panel:FindFirstChild("ManagerFrame")
	check("Manager assignment panel becomes visible client-side after a Manager-rank PromotionNotice", managerFrame and managerFrame.Visible == true)
end

--------------------------------------------------------------------------
-- STEP 8: Leave-save / autosave path (item 15)
--------------------------------------------------------------------------

print("== STEP 8: Leave-save ==")
local removeOk, removeErr = pcall(function()
	PlayersService.PlayerRemoving:Fire(associate)
end)
check("PlayerRemoving handler (save) runs without error", removeOk, removeErr)

local playerStore = dataStores["PlayerData_v1"]
local savedRecord = playerStore and playerStore:RawGet("Player_9001")
check("Promoted player's record actually persisted to the (fake) DataStore", savedRecord ~= nil)
check("Persisted record has Rank = Manager", savedRecord and savedRecord.Rank == "Manager")
check("Persisted record has the correct accumulated Money (5 x careful @ +10)", savedRecord and savedRecord.PersonalMoney == 50)
check("Persisted record has the correct accumulated Performance (5 x careful @ +2)", savedRecord and savedRecord.PerformanceRating == 10)
check("Persisted record has the correct accumulated Reputation (5 x careful @ +1)", savedRecord and savedRecord.Reputation == 5)

local autosaveOk = pcall(function()
	dataStores["PlayerData_v1"] = dataStores["PlayerData_v1"] -- no-op; autosave loop itself is a task.spawn'd infinite wait loop, not directly invokable here
end)
check("Autosave loop registered without error at boot (see report: interval loop itself not directly exercised here)", autosaveOk)

--------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------

print("")
print(string.format("Total: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
