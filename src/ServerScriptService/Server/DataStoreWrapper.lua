--[[
	DataStoreWrapper - the single shared DataStore access point
	(docs/technical-architecture-v0.1.md §5), providing retry/backoff
	(§15) around GetAsync/SetAsync/UpdateAsync.

	This module takes its DataStore-like `store` objects and its
	RetryPolicy as arguments/config rather than calling
	game:GetService("DataStoreService") or `require`-ing RetryPolicy
	itself. That dependency injection is what makes it possible to run
	the exact same code, unmodified, against a fake in-memory DataStore in
	the standalone test suite (tests/) - see technical-architecture-v0.1.md
	§18. Only Bootstrap.server.lua wires this to the real
	DataStoreService.
]]

local unpack = table.unpack or unpack -- luacheck: ignore unpack (Lua 5.1 global fallback)

local DataStoreWrapper = {}
DataStoreWrapper.__index = DataStoreWrapper

--[[
	config:
		retryPolicy (required) - a RetryPolicy-shaped module (ShouldRetry, BackoffSeconds)
		wait (optional) - function(seconds) used between retries; defaults to a no-op
		maxAttempts (optional) - defaults to retryPolicy.DEFAULT_MAX_ATTEMPTS
		log (optional) - function(message) for diagnostic logging; defaults to a no-op
]]
function DataStoreWrapper.new(config)
	config = config or {}
	assert(config.retryPolicy, "DataStoreWrapper requires config.retryPolicy")

	local self = setmetatable({}, DataStoreWrapper)
	self._retryPolicy = config.retryPolicy
	self._wait = config.wait or function() end
	self._maxAttempts = config.maxAttempts or self._retryPolicy.DEFAULT_MAX_ATTEMPTS
	self._log = config.log or function() end
	return self
end

-- Internal: runs store[methodName](store, ...) with bounded retry/backoff.
-- Returns (true, result) on success, or (false, lastError) if every
-- attempt failed.
function DataStoreWrapper:_run(store, methodName, ...)
	assert(store ~= nil, "store must not be nil")
	assert(type(store[methodName]) == "function", "store has no method " .. tostring(methodName))

	local args = { ... }
	local attempt = 0
	local lastErr = nil

	while true do
		attempt = attempt + 1
		local ok, result = pcall(function()
			return store[methodName](store, unpack(args))
		end)

		if ok then
			return true, result
		end

		lastErr = result
		self._log(string.format("DataStore %s failed (attempt %d): %s", tostring(methodName), attempt, tostring(result)))

		if not self._retryPolicy.ShouldRetry(attempt, self._maxAttempts) then
			return false, lastErr
		end

		self._wait(self._retryPolicy.BackoffSeconds(attempt))
	end
end

function DataStoreWrapper:Get(store, key)
	return self:_run(store, "GetAsync", key)
end

function DataStoreWrapper:Set(store, key, value)
	return self:_run(store, "SetAsync", key, value)
end

--[[
	Update performs a read-modify-write via the store's UpdateAsync-style
	method: transformFn(oldValue) -> newValue (or nil to abort the write,
	e.g. because validation failed or a session lock could not be
	claimed - see PlayerDataService/OrganizationService).
]]
function DataStoreWrapper:Update(store, key, transformFn)
	assert(type(transformFn) == "function", "transformFn must be a function")
	return self:_run(store, "UpdateAsync", key, transformFn)
end

return DataStoreWrapper
