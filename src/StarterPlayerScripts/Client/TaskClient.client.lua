--[[
	TaskClient.client.lua - minimal UI to trigger a task, present its
	decision, and display the result.

	Deliberately basic, per the Phase 1/2 briefs ("basic client UI" - not
	the polished onboarding/UI pass MVP Definition §11/§23 Phase 5
	reserves for later): a status label, a "Request Task" button, one
	button per choice (built from the server's Choices preview) once a
	task is assigned, and a result label.

	Design principle this UI exists to serve (Phase 2 brief): the player
	must be able to answer, in order:
	  "What am I being asked to do?"        -> Prompt
	  "What choices do I have?"              -> one button per choice
	  "What are the likely consequences?"    -> each choice's Description
	                                             plus its Preview breakdown
	  "What happened because of my decision?"-> the TaskResult display

	SECURITY NOTE: this script displays whatever the server tells it and
	sends only opaque, server-issued values back (TaskId/InstanceId/
	ChoiceId - the ChoiceId a button carries is the exact string the
	server itself sent in the Choices preview, never invented
	client-side). It never computes, stores as authoritative, or displays
	a value it invented itself - every number shown (MoneyGain,
	PerformanceGain, ReputationGain, QualityScore, NewPersonalMoney,
	NewPerformanceRating, NewReputation) comes directly from a TaskResult
	the server pushed. A modified client could display anything it wants
	to ITSELF, but cannot make the server believe it - see
	TaskService.lua's SECURITY MODEL comment and Bootstrap.server.lua's
	Remote handlers, which are the actual enforcement point.
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
screenGui.Name = "TaskUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "TaskPanel"
frame.Size = UDim2.new(0, 420, 0, 420)
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
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 16
statusLabel.Text = "No task yet."
statusLabel.Parent = frame

local requestButton = Instance.new("TextButton")
requestButton.Name = "RequestButton"
requestButton.Size = UDim2.new(1, -20, 0, 32)
requestButton.Position = UDim2.new(0, 10, 0, 55)
requestButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
requestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
requestButton.Font = Enum.Font.SourceSansBold
requestButton.TextSize = 16
requestButton.Text = "Request Task"
requestButton.Parent = frame

-- Container for one button per choice, built/rebuilt each time a task is
-- assigned. Choice buttons live here instead of being pre-created since
-- the number of choices is server-driven, not fixed client-side.
local choicesFrame = Instance.new("Frame")
choicesFrame.Name = "ChoicesFrame"
choicesFrame.Size = UDim2.new(1, -20, 0, 260)
choicesFrame.Position = UDim2.new(0, 10, 0, 55)
choicesFrame.BackgroundTransparency = 1
choicesFrame.Visible = false
choicesFrame.Parent = frame

local choicesLayout = Instance.new("UIListLayout")
choicesLayout.Padding = UDim.new(0, 6)
choicesLayout.Parent = choicesFrame

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(1, -20, 0, 90)
resultLabel.Position = UDim2.new(0, 10, 1, -100)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
resultLabel.TextWrapped = true
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.TextYAlignment = Enum.TextYAlignment.Top
resultLabel.Font = Enum.Font.SourceSans
resultLabel.TextSize = 14
resultLabel.Text = ""
resultLabel.Parent = frame

--------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------

local State = {
	IDLE = "Idle",
	REQUESTING = "Requesting",
	CHOOSING = "Choosing",
	COMPLETING = "Completing",
}

local state = State.IDLE
local heldTask = nil -- { TaskId, InstanceId, Name, Prompt, Choices }

local function formatPreview(preview)
	-- preview: array of { Chance, Label, MoneyGain, PerformanceGain, ReputationGain }
	local lines = {}
	for _, outcome in ipairs(preview) do
		table.insert(
			lines,
			string.format(
				"  %d%%: %s (money %+d, perf %+d, rep %+d)",
				outcome.Chance,
				outcome.Label,
				outcome.MoneyGain,
				outcome.PerformanceGain,
				outcome.ReputationGain
			)
		)
	end
	return table.concat(lines, "\n")
end

local function clearChoiceButtons()
	for _, child in ipairs(choicesFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function onChoiceClicked(choiceId)
	if state ~= State.CHOOSING or not heldTask then
		return
	end
	state = State.COMPLETING
	statusLabel.Text = "Task: " .. heldTask.Name .. " - submitting your decision..."
	choicesFrame.Visible = false
	requestButton.Visible = false
	CompleteTaskRemote:FireServer(heldTask.TaskId, heldTask.InstanceId, choiceId)
end

local function buildChoiceButtons()
	clearChoiceButtons()

	for index, choice in ipairs(heldTask.Choices) do
		local button = Instance.new("TextButton")
		button.Name = "Choice_" .. choice.ChoiceId
		button.Size = UDim2.new(1, 0, 0, 70)
		button.LayoutOrder = index
		button.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 13
		button.TextWrapped = true
		-- Label + prose Description, then the exact per-outcome numeric
		-- breakdown from formatPreview - both the "why" and the "exact
		-- numbers" for "what are the likely consequences?".
		button.Text = choice.Label .. "\n" .. choice.Description .. "\n" .. formatPreview(choice.Preview)
		button.Parent = choicesFrame

		-- The ChoiceId this button sends is exactly the server-issued
		-- string from the Choices preview - never a client-invented value.
		button.MouseButton1Click:Connect(function()
			onChoiceClicked(choice.ChoiceId)
		end)
	end
end

local function render()
	if state == State.IDLE then
		statusLabel.Text = "No task yet."
		requestButton.Visible = true
		requestButton.Active = true
		requestButton.Text = "Request Task"
		choicesFrame.Visible = false
	elseif state == State.REQUESTING then
		statusLabel.Text = "Requesting a task..."
		requestButton.Active = false
		choicesFrame.Visible = false
	elseif state == State.CHOOSING then
		statusLabel.Text = heldTask.Name .. ": " .. heldTask.Prompt
		requestButton.Visible = false
		choicesFrame.Visible = true
	elseif state == State.COMPLETING then
		statusLabel.Text = "Task: " .. heldTask.Name .. " - submitting..."
		requestButton.Visible = false
		choicesFrame.Visible = false
	end
end

render()

requestButton.MouseButton1Click:Connect(function()
	if state ~= State.IDLE then
		return
	end
	state = State.REQUESTING
	render()
	RequestTaskRemote:FireServer()
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
			Prompt = payload.Prompt,
			Choices = payload.Choices,
		}
		buildChoiceButtons()
		state = State.CHOOSING
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
			"%s\nMoney %+d, Performance %+d, Reputation %+d (quality %d/100)\nTotals: %s money, %s performance, %s reputation",
			tostring(payload.ResultLabel),
			payload.MoneyGain,
			payload.PerformanceGain,
			payload.ReputationGain,
			payload.QualityScore,
			tostring(payload.NewPersonalMoney),
			tostring(payload.NewPerformanceRating),
			tostring(payload.NewReputation)
		)
	else
		resultLabel.Text = "Completion failed: " .. tostring(payload.Reason)
	end

	heldTask = nil
	clearChoiceButtons()
	state = State.IDLE
	render()
end)
