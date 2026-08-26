--[[
	TaskInstance - pure task-instance state machine.

	A TaskInstance is the server-issued, opaque handle a player receives
	when they request a task (see TaskService). Completion is validated
	against the instance, never against anything else the client claims -
	this is the core mechanism behind Phase 1's security requirements:

	- "call completion without receiving a task" -> instance is nil
	- "submit an invalid task ID"                -> TaskId mismatch
	- "complete a task twice" / "replay an old
	   completion request"                        -> already Completed
	- "complete another player's task"           -> instances are stored
	  per-player by TaskService, so another player's instance table
	  simply does not contain this instanceId (see TaskService.lua)

	Pure logic module: no Roblox service calls, no `require`, no internal
	clock - `now`/`issuedAt`/`completedAt` are always passed in, so this
	is fully deterministic and unit-testable (see tests/).
]]

local TaskInstance = {}

--[[
	Creates a new, pending (not completed) task instance.
]]
function TaskInstance.New(taskId, instanceId, issuedAt)
	assert(type(taskId) == "string" and #taskId > 0, "taskId must be a non-empty string")
	assert(type(instanceId) == "string" and #instanceId > 0, "instanceId must be a non-empty string")
	assert(type(issuedAt) == "number", "issuedAt must be a number")

	return {
		TaskId = taskId,
		InstanceId = instanceId,
		IssuedAt = issuedAt,
		Completed = false,
		CompletedAt = nil,
	}
end

--[[
	Decides whether a completion request may proceed against `instance`
	(which may be nil, meaning "no such instance was found" - see
	TaskService's per-player lookup).

	`submittedTaskId` is whatever TaskId the client claims to be
	completing; it must match the TaskId the server actually issued for
	this instance.

	Returns (ok: boolean, reason: string).
]]
function TaskInstance.ValidateCompletion(instance, submittedTaskId)
	if instance == nil then
		return false, "unknown task instance"
	end
	if type(instance) ~= "table" or type(instance.TaskId) ~= "string" or type(instance.Completed) ~= "boolean" then
		-- Corrupt/unrecognized instance shape - never trust it.
		return false, "unrecognized task instance shape"
	end
	if instance.TaskId ~= submittedTaskId then
		return false, "task id mismatch"
	end
	if instance.Completed then
		return false, "task already completed"
	end
	return true
end

--[[
	Returns a NEW instance table (does not mutate `instance`) marked
	completed at `completedAt`.
]]
function TaskInstance.MarkCompleted(instance, completedAt)
	assert(type(instance) == "table", "instance must be a table")
	assert(type(completedAt) == "number", "completedAt must be a number")

	local updated = {}
	for k, v in pairs(instance) do
		updated[k] = v
	end
	updated.Completed = true
	updated.CompletedAt = completedAt
	return updated
end

return TaskInstance
