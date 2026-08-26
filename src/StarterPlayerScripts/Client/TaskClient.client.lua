--[[
	TaskClient.client.lua - minimal UI to trigger a task, present its
	decision, display the result, show progression status, and (once
	promoted) let a Manager assign the task to another player.

	Deliberately basic, per the Phase 1-3 briefs ("basic client UI" - not
	the polished onboarding/UI pass MVP Definition §11/§23 Phase 5
	reserves for later).

	Design principle this UI exists to serve (Phase 2/3 briefs): the
	player must be able to answer, in order:
	  "What am I being asked to do?"          -> Prompt
	  "What choices do I have?"                -> one button per choice
	  "What are the likely consequences?"      -> each choice's Description
	                                               plus its Preview breakdown
	  "What happened because of my decision?"  -> the TaskResult display
	  "Where do I stand, and what's next?"     -> the always-visible rank/
	                                               threshold status line
	  "What did I just unlock?"                -> the PromotionNotice banner

	SECURITY NOTE: this script displays whatever the server tells it and
	sends only opaque, server-issued values back (TaskId/InstanceId/
	ChoiceId, or another player's UserId for AssignTask - never a rank, a
	reward, a performance/reputation value, or a threshold). It never
	computes, stores as authoritative, or displays a value it invented
	itself. `currentRank` below is a purely client-side DISPLAY
	convenience (which panel to show) - it is never trusted by the
	server, which re-checks the real rank from PlayerDataService on every
	AssignTask call regardless of what this script shows. See
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
local AssignTaskRemote = Remotes:WaitForChild("AssignTask")
local AssignTaskResultRemote = Remotes:WaitForChild("AssignTaskResult")
local PromotionNoticeRemote = Remotes:WaitForChild("PromotionNotice")

--------------------------------------------------------------------------
-- UI construction
--------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TaskUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "TaskPanel"
frame.Size = UDim2.new(0, 440, 0, 560)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 36)
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

-- Always-visible progression explanation: current rank, current
-- Performance/Reputation, and the thresholds required for the next
-- promotion (Phase 3 "clear player-facing explanation" requirement).
-- Populated from TaskResult's Rank/PerformanceThreshold/
-- ReputationThreshold/PromotionEligible fields after every completion.
local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "RankLabel"
rankLabel.Size = UDim2.new(1, -20, 0, 36)
rankLabel.Position = UDim2.new(0, 10, 0, 46)
rankLabel.BackgroundTransparency = 1
rankLabel.TextColor3 = Color3.fromRGB(170, 200, 255)
rankLabel.TextWrapped = true
rankLabel.TextXAlignment = Enum.TextXAlignment.Left
rankLabel.TextYAlignment = Enum.TextYAlignment.Top
rankLabel.Font = Enum.Font.SourceSans
rankLabel.TextSize = 13
rankLabel.Text = "Rank: Associate"
rankLabel.Parent = frame

-- Distinct celebratory banner, shown only when a PromotionNotice arrives.
local promotionBanner = Instance.new("TextLabel")
promotionBanner.Name = "PromotionBanner"
promotionBanner.Size = UDim2.new(1, -20, 0, 40)
promotionBanner.Position = UDim2.new(0, 10, 0, 84)
promotionBanner.BackgroundColor3 = Color3.fromRGB(50, 110, 50)
promotionBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
promotionBanner.TextWrapped = true
promotionBanner.Font = Enum.Font.SourceSansBold
promotionBanner.TextSize = 14
promotionBanner.Text = ""
promotionBanner.Visible = false
promotionBanner.Parent = frame

local requestButton = Instance.new("TextButton")
requestButton.Name = "RequestButton"
requestButton.Size = UDim2.new(1, -20, 0, 32)
requestButton.Position = UDim2.new(0, 10, 0, 132)
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
choicesFrame.Position = UDim2.new(0, 10, 0, 132)
choicesFrame.BackgroundTransparency = 1
choicesFrame.Visible = false
choicesFrame.Parent = frame

local choicesLayout = Instance.new("UIListLayout")
choicesLayout.Padding = UDim.new(0, 6)
choicesLayout.Parent = choicesFrame

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(1, -20, 0, 80)
resultLabel.Position = UDim2.new(0, 10, 0, 400)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
resultLabel.TextWrapped = true
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.TextYAlignment = Enum.TextYAlignment.Top
resultLabel.Font = Enum.Font.SourceSans
resultLabel.TextSize = 14
resultLabel.Text = ""
resultLabel.Parent = frame

-- Manager responsibility panel: only shown once currentRank == "Manager"
-- (display-only gating; the server independently re-checks rank on every
-- AssignTask call regardless of whether this panel is visible).
local managerFrame = Instance.new("Frame")
managerFrame.Name = "ManagerFrame"
managerFrame.Size = UDim2.new(1, -20, 0, 130)
managerFrame.Position = UDim2.new(0, 10, 1, -140)
managerFrame.BackgroundTransparency = 1
managerFrame.Visible = false
managerFrame.Parent = frame

local managerTitle = Instance.new("TextLabel")
managerTitle.Name = "ManagerTitle"
managerTitle.Size = UDim2.new(1, 0, 0, 20)
managerTitle.BackgroundTransparency = 1
managerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
managerTitle.TextXAlignment = Enum.TextXAlignment.Left
managerTitle.Font = Enum.Font.SourceSansBold
managerTitle.TextSize = 14
managerTitle.Text = "Assign the task to another Associate:"
managerTitle.Parent = managerFrame

local managerListFrame = Instance.new("Frame")
managerListFrame.Name = "ManagerListFrame"
managerListFrame.Size = UDim2.new(1, 0, 0, 100)
managerListFrame.Position = UDim2.new(0, 0, 0, 24)
managerListFrame.BackgroundTransparency = 1
managerListFrame.Parent = managerFrame

local managerListLayout = Instance.new("UIListLayout")
managerListLayout.Padding = UDim.new(0, 4)
managerListLayout.Parent = managerListFrame

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
local currentRank = "Associate" -- display-only; see SECURITY NOTE above

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

--------------------------------------------------------------------------
-- Manager panel: list other players currently in the server; the server
-- independently re-validates rank/eligibility/org on every AssignTask
-- call, so this list is a convenience, not a security boundary.
--------------------------------------------------------------------------

local function rebuildManagerList()
	for _, child in ipairs(managerListFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= localPlayer then
			local row = Instance.new("Frame")
			row.Name = "Row_" .. otherPlayer.UserId
			row.Size = UDim2.new(1, 0, 0, 26)
			row.BackgroundTransparency = 1
			row.Parent = managerListFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Font = Enum.Font.SourceSans
			nameLabel.TextSize = 13
			nameLabel.Text = otherPlayer.Name
			nameLabel.Parent = row

			local assignButton = Instance.new("TextButton")
			assignButton.Size = UDim2.new(0.4, 0, 1, 0)
			assignButton.Position = UDim2.new(0.6, 0, 0, 0)
			assignButton.BackgroundColor3 = Color3.fromRGB(60, 150, 90)
			assignButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			assignButton.Font = Enum.Font.SourceSansBold
			assignButton.TextSize = 13
			assignButton.Text = "Assign"
			assignButton.Parent = row

			-- Sends only the target's UserId - an opaque reference the
			-- server independently validates (rank, org, availability,
			-- duplicate-in-progress) before doing anything with it.
			assignButton.MouseButton1Click:Connect(function()
				AssignTaskRemote:FireServer(otherPlayer.UserId)
			end)
		end
	end
end

Players.PlayerAdded:Connect(function()
	if currentRank == "Manager" then
		rebuildManagerList()
	end
end)
Players.PlayerRemoving:Connect(function()
	if currentRank == "Manager" then
		task.defer(rebuildManagerList)
	end
end)

--------------------------------------------------------------------------
-- Render
--------------------------------------------------------------------------

local function render()
	managerFrame.Visible = (currentRank == "Manager")

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
		if payload.AssignedByUserId then
			-- A Manager assigned this task - distinct from having
			-- requested it yourself.
			statusLabel.Text =
				string.format("%s assigned you a task: %s", tostring(payload.AssignedByName), heldTask.Name)
		end
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

		-- Always-visible progression explanation (Phase 3 requirement):
		-- current rank, current Performance/Reputation, and what's
		-- required for the next promotion.
		currentRank = payload.Rank or currentRank
		if currentRank == "Manager" then
			rankLabel.Text = "Rank: Manager"
			rebuildManagerList()
		else
			rankLabel.Text = string.format(
				"Rank: %s | Performance %s/%s | Reputation %s/%s%s",
				tostring(payload.Rank),
				tostring(payload.NewPerformanceRating),
				tostring(payload.PerformanceThreshold),
				tostring(payload.NewReputation),
				tostring(payload.ReputationThreshold),
				payload.PromotionEligible and " - eligible for promotion!" or ""
			)
		end
	else
		resultLabel.Text = "Completion failed: " .. tostring(payload.Reason)
	end

	heldTask = nil
	clearChoiceButtons()
	state = State.IDLE
	render()
end)

PromotionNoticeRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	currentRank = payload.NewRank or currentRank
	promotionBanner.Text = string.format(
		"Promoted: %s -> %s!\n%s",
		tostring(payload.PreviousRank),
		tostring(payload.NewRank),
		tostring(payload.Unlocked)
	)
	promotionBanner.Visible = true

	render()
end)

--------------------------------------------------------------------------
-- Manager feedback: confirms an AssignTask attempt succeeded or failed.
--------------------------------------------------------------------------

AssignTaskResultRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	if payload.Success then
		resultLabel.Text = string.format("Assigned '%s' to the selected player.", tostring(payload.TaskName))
	else
		resultLabel.Text = "Couldn't assign task: " .. tostring(payload.Reason)
	end
end)
