--[[
	TaskClient.client.lua - minimal UI to trigger and display Phase 1's
	single test task.

	Deliberately basic, per the Phase 1 brief ("basic client UI needed to
	trigger and display the test task" - not the polished onboarding/UI
	pass that MVP Definition §11 and §23 Phase 5 reserve for later): one
	status label, one button that requests/completes the task depending
	on state, one result label.

	SECURITY NOTE: this script displays whatever the server tells it and
	sends only two opaque, server-issued values (TaskId/InstanceId) back
	on completion. It never computes, stores as authoritative, or
	displays a value it invented itself - every number shown (MoneyGain,
	PerformanceGain, NewPersonalMoney, NewPerformanceRating) comes
	directly from a TaskResult the server pushed. A modified client could
	display anything it wants to ITSELF, but cannot make the server
	believe it - see TaskService.lua's SECURITY MODEL comment and
	Bootstrap.server.lua's Remote handlers, which are the actual
	enforcement point.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local RequestTaskRemote = Remotes:WaitForChild("RequestTask")
local TaskAssignedRemote = Remotes:WaitForChild("TaskAssigned")
local CompleteTaskRemote = Remotes:WaitForChild("CompleteTask")
local TaskResultRemote = Remotes:WaitForChild("TaskResult")

--------------------------------------------------------------------------
-- UI construction
--------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Phase1TaskUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "TaskPanel"
frame.Size = UDim2.new(0, 260, 0, 130)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 16
statusLabel.Text = "No task yet."
statusLabel.Parent = frame

local actionButton = Instance.new("TextButton")
actionButton.Name = "ActionButton"
actionButton.Size = UDim2.new(1, -20, 0, 32)
actionButton.Position = UDim2.new(0, 10, 0, 55)
actionButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
actionButton.Font = Enum.Font.SourceSansBold
actionButton.TextSize = 16
actionButton.Text = "Request Task"
actionButton.Parent = frame

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(1, -20, 0, 30)
resultLabel.Position = UDim2.new(0, 10, 0, 95)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
resultLabel.TextWrapped = true
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.Font = Enum.Font.SourceSans
resultLabel.TextSize = 14
resultLabel.Text = ""
resultLabel.Parent = frame

--------------------------------------------------------------------------
-- State machine: Idle -> Requesting -> HasTask -> Completing -> Idle
--------------------------------------------------------------------------

local State = {
	IDLE = "Idle",
	REQUESTING = "Requesting",
	HAS_TASK = "HasTask",
	COMPLETING = "Completing",
}

local state = State.IDLE
local heldTask = nil -- { TaskId, InstanceId, Name }

local function render()
	if state == State.IDLE then
		statusLabel.Text = "No task yet."
		actionButton.Text = "Request Task"
		actionButton.Active = true
	elseif state == State.REQUESTING then
		statusLabel.Text = "Requesting a task..."
		actionButton.Active = false
	elseif state == State.HAS_TASK then
		statusLabel.Text = "Task: " .. heldTask.Name
		actionButton.Text = "Complete Task"
		actionButton.Active = true
	elseif state == State.COMPLETING then
		statusLabel.Text = "Task: " .. heldTask.Name
		actionButton.Text = "Completing..."
		actionButton.Active = false
	end
end

render()

actionButton.MouseButton1Click:Connect(function()
	if state == State.IDLE then
		state = State.REQUESTING
		render()
		RequestTaskRemote:FireServer()
	elseif state == State.HAS_TASK then
		state = State.COMPLETING
		render()
		CompleteTaskRemote:FireServer(heldTask.TaskId, heldTask.InstanceId)
	end
	-- REQUESTING/COMPLETING: button is inactive, click is a no-op.
end)

TaskAssignedRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	if payload.Success then
		heldTask = {
			TaskId = payload.TaskId,
			InstanceId = payload.InstanceId,
			Name = payload.Name,
		}
		state = State.HAS_TASK
		resultLabel.Text = ""
	else
		heldTask = nil
		state = State.IDLE
		resultLabel.Text = "Couldn't get a task: " .. tostring(payload.Reason)
	end
	render()
end)

TaskResultRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	if payload.Success then
		resultLabel.Text = string.format(
			"Done! +%s money, +%s performance (total: %s money, %s performance)",
			tostring(payload.MoneyGain),
			tostring(payload.PerformanceGain),
			tostring(payload.NewPersonalMoney),
			tostring(payload.NewPerformanceRating)
		)
	else
		resultLabel.Text = "Completion failed: " .. tostring(payload.Reason)
	end

	heldTask = nil
	state = State.IDLE
	render()
end)
