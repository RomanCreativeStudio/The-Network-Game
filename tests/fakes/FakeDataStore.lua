--[[
	FakeDataStore - an in-memory stand-in for a Roblox GlobalDataStore,
	used only by the test suite.

	Mimics the subset of the real DataStore API DataStoreWrapper calls:
	GetAsync(key), SetAsync(key, value), UpdateAsync(key, transformFn).

	Supports injectable transient failures (via `failuresRemaining`) so
	DataStoreWrapper's retry behavior can be exercised deterministically,
	without real network calls or real waiting.
]]

local FakeDataStore = {}
FakeDataStore.__index = FakeDataStore

function FakeDataStore.new(config)
	config = config or {}
	local self = setmetatable({}, FakeDataStore)
	self._data = {}
	-- Public (tests may mutate this directly to inject failures mid-test).
	self._failuresRemaining = config.failuresRemaining or 0
	self._failureMessage = config.failureMessage or "simulated datastore failure"
	self._callLog = {}
	return self
end

function FakeDataStore:_maybeFail(methodName)
	table.insert(self._callLog, methodName)
	if self._failuresRemaining > 0 then
		self._failuresRemaining = self._failuresRemaining - 1
		error(self._failureMessage)
	end
end

function FakeDataStore:GetAsync(key)
	self:_maybeFail("GetAsync")
	return self._data[key]
end

function FakeDataStore:SetAsync(key, value)
	self:_maybeFail("SetAsync")
	self._data[key] = value
	return true
end

-- Mirrors real UpdateAsync semantics: transformFn receives the current
-- value (or nil) and returns the new value to commit, or nil to abort
-- the write (the stored value is left unchanged).
function FakeDataStore:UpdateAsync(key, transformFn)
	self:_maybeFail("UpdateAsync")
	local old = self._data[key]
	local new = transformFn(old)
	if new ~= nil then
		self._data[key] = new
	end
	return new
end

-- Test-only helpers (not part of the real DataStore API):
function FakeDataStore:RawGet(key)
	return self._data[key]
end

function FakeDataStore:RawSet(key, value)
	self._data[key] = value
end

function FakeDataStore:CallCount()
	return #self._callLog
end

return FakeDataStore
