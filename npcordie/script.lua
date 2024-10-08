local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local teams = game:GetService("Teams")
local pathfindingService = game:GetService("PathfindingService")

-- Load the Fluent library and other dependencies
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create a new window with a very dark theme and no transparency
local Window = Fluent:CreateWindow({
    Title = "[🍂] Be NPC or DIE!💢 ",
    SubTitle = "by No_rbex",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "" }),
    Statistics = Window:AddTab({ Title = "Statistics", Icon = "bar-chart-2" }), -- New Statistics tab
    Credit = Window:AddTab({ Title = "Credit", Icon = "" })
}

local espEnabled = false
local npcEspEnabled = false
local autoTaskEnabled = false
local instantInteractionEnabled = false
local selectedPlayer




-- Function to make interactions instant
local function makeInteractionInstant()
    -- Loop through all ProximityPrompts in the workspace
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            -- Set the hold duration to zero
            prompt.HoldDuration = 0

            -- Automatically trigger the prompt when the player is in range
            prompt.Triggered:Connect(function(player)
                if player == players.LocalPlayer and instantInteractionEnabled then
                    prompt:InputHoldBegin()
                    wait(0.1)  -- Small delay to simulate holding, you can reduce further if needed
                    prompt:InputHoldEnd()
                end
            end)
        end
    end
end

-- Monitor for new ProximityPrompts being added dynamically
workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then
        makeInteractionInstant()
    end
end)

-- Function to toggle instant interaction
local function toggleInstantInteraction(state)
    instantInteractionEnabled = state
    if instantInteractionEnabled then
        makeInteractionInstant() -- Call the function to apply the modifications
        Fluent:Notify({
            Title = "Instant Interaction",
            Content = "Instant Interaction enabled.",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Instant Interaction",
            Content = "Instant Interaction disabled.",
            Duration = 3
        })
    end
end

-- Adding a toggle for Instant Interaction to the Main Tab
Tabs.Main:AddToggle("InstantInteraction", {Title = "Instant Interaction", Default = false}):OnChanged(function(state)
    toggleInstantInteraction(state)
end)

-- Other existing code...

-- Call the function to update all existing ProximityPrompts
makeInteractionInstant()

-- Function to refresh player list in the dropdown
local function getPlayerNames()
    local playerNames = {}
    for _, player in ipairs(players:GetPlayers()) do
        table.insert(playerNames, player.Name)
    end
    return playerNames
end

-- Function to get the team color for a player
local function getTeamColor(player)
    if player.Team then
        if player.Team.Name == "Criminal" then
            return Color3.fromRGB(255, 0, 0) -- Red color for criminals
        else
            return player.Team.TeamColor.Color
        end
    else
        return Color3.fromRGB(255, 255, 255) -- White for players without a team
    end
end

-- Function to create a BillboardGui with the username and distance
local function addUsernameLabel(model, player)
    if not model.PrimaryPart then
        model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart") or model:FindFirstChildWhichIsA("Part")
    end
    
    if model.PrimaryPart then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.Adornee = model.PrimaryPart
        billboard.Name = "UsernameLabel"
        billboard.Parent = model

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = getTeamColor(player)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextScaled = true
        textLabel.Parent = billboard

        local function updateLabel()
            local distance = (model.PrimaryPart.Position - players.LocalPlayer.Character.PrimaryPart.Position).Magnitude
            textLabel.Text = string.format("%s | %.0f studs", player.Name, distance)
        end

        updateLabel()
        game:GetService("RunService").Heartbeat:Connect(updateLabel)
    end
end

-- Function to create a BillboardGui with the NPC name and distance
local function addNPCEsp(model)
    if not model.PrimaryPart then
        model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart") or model:FindFirstChildWhichIsA("Part")
    end
    
    if model.PrimaryPart then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.Adornee = model.PrimaryPart
        billboard.Name = "NPCLabel"
        billboard.Parent = model

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 0, 0) -- Red color for NPCs
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextScaled = true
        textLabel.Parent = billboard

        local function updateLabel()
            local distance = (model.PrimaryPart.Position - players.LocalPlayer.Character.PrimaryPart.Position).Magnitude
            textLabel.Text = string.format("NPC | %.0f studs", distance)
        end

        updateLabel()
        game:GetService("RunService").Heartbeat:Connect(updateLabel)
    end
end

-- Function to update player ESP
local function updatePlayerESP()
    for _, model in ipairs(workspace:GetChildren()) do
        for _, player in ipairs(players:GetPlayers()) do
            if model:IsA("Model") and model.Name == player.Name and not model:FindFirstChild("Animations") then
                local existingLabel = model:FindFirstChild("UsernameLabel")
                local existingHighlight = model:FindFirstChild("PlayerGlow")

                if espEnabled then
                    if not existingLabel then
                        addUsernameLabel(model, player)
                    end
                    
                    if not existingHighlight then
                        local highlight = Instance.new("Highlight")
                        highlight.Adornee = model
                        highlight.Name = "PlayerGlow"
                        highlight.Parent = model
                        highlight.FillColor = getTeamColor(player)
                        highlight.OutlineColor = Color3.new(0, 0, 0) -- Black outline
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    else
                        existingHighlight.FillColor = getTeamColor(player)
                    end
                else
                    if existingLabel then
                        existingLabel:Destroy()
                    end
                    if existingHighlight then
                        existingHighlight:Destroy()
                    end
                end
            end
        end
    end
end

-- Function to update NPC ESP
local function updateNPCESP()
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("Animations") then
            local existingLabel = model:FindFirstChild("NPCLabel")
            local existingHighlight = model:FindFirstChild("NPCGlow")

            if npcEspEnabled then
                if not existingLabel then
                    addNPCEsp(model)
                end
                
                if not existingHighlight then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = model
                    highlight.Name = "NPCGlow"
                    highlight.Parent = model
                    highlight.FillColor = Color3.new(1, 0, 0) -- Red color for NPCs
                    highlight.OutlineColor = Color3.new(0, 0, 0) -- Black outline
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
            else
                if existingLabel then
                    existingLabel:Destroy()
                end
                if existingHighlight then
                    existingHighlight:Destroy()
                end
            end
        end
    end
end

-- Function to gradually move the player to a target position
local function walkToPosition(targetPosition)
    local character = players.LocalPlayer.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoidRootPart and humanoid then
            -- Calculate the path
            local path = pathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentCanClimb = true,
                AgentJumpHeight = 7,
                AgentMaxSlope = 45,
            })

            -- Compute the path and check if it is successful
            path:ComputeAsync(humanoidRootPart.Position, targetPosition)
            if path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()

                -- Visualize the waypoints for debugging (optional)
                for _, waypoint in ipairs(waypoints) do
                    local part = Instance.new("Part")
                    part.Shape = Enum.PartType.Ball
                    part.Material = Enum.Material.Neon
                    part.Size = Vector3.new(0.5, 0.5, 0.5)
                    part.Position = waypoint.Position
                    part.Anchored = true
                    part.CanCollide = false
                    part.Color = Color3.new(0, 1, 0)
                    part.Parent = workspace

                    -- Auto-destroy the debug part after 5 seconds
                    game:GetService("Debris"):AddItem(part, 10)
                end

                for _, waypoint in ipairs(waypoints) do
                    -- Move to each waypoint in the path
                    humanoid:MoveTo(waypoint.Position)

                    -- Wait until the character reaches the waypoint
                    local success = humanoid.MoveToFinished:Wait()
                    if not success then
                        warn("Failed to reach waypoint. Retrying...")
                        humanoid:MoveTo(waypoint.Position) -- Retry moving to the waypoint
                    end
                end

                print("Path completed.")
            else
                warn("Path not found or incomplete. Status: ", path.Status)
            end
        else
            warn("HumanoidRootPart or Humanoid not found.")
        end
    else
        warn("Character not found.")
    end
end


-- Function to auto-complete tasks (Legit version)
local function legitAutoCompleteTasks()
    while autoTaskEnabled do
        local character = players.LocalPlayer.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local mainFolder = nil
                for _, folder in ipairs(workspace:GetChildren()) do
                    if folder:IsA("Folder") and folder.Name ~= "Plots" and folder.Name ~= "Lobby" and folder.Name ~= "Ragdolls" then
                        mainFolder = folder
                        break
                    end
                end

                if mainFolder then
                    local tasksFolder = mainFolder:FindFirstChild("Tasks")
                    if tasksFolder then
                        for _, taskModel in ipairs(tasksFolder:GetChildren()) do
                            if taskModel:IsA("Model") then

                                local targetTaskHighlight = taskModel:FindFirstChild("TargetTaskHighlight")
                            if targetTaskHighlight then
                                local teleportPosition = taskModel:FindFirstChild("Hitbox")
                                if teleportPosition then
                                    walkToPosition(teleportPosition.Position)
                                    wait(1)
                                    break
                                end
                            end
                            end
                        end
                    end
                end
            end
        end
        wait(2)
    end
end

-- Function to toggle legit auto task completion
local function toggleLegitAutoTask(state)
    autoTaskEnabled = state
    if autoTaskEnabled then
        Fluent:Notify({
            Title = "Legit Auto Task",
            Content = "Legit auto task completion enabled.",
            Duration = 3
        })
        task.spawn(legitAutoCompleteTasks)
    else
        Fluent:Notify({
            Title = "Legit Auto Task",
            Content = "Legit auto task completion disabled.",
            Duration = 3
        })
    end
end

-- Adding a toggle for Legit Auto Task to the Main Tab
Tabs.Main:AddToggle("LegitAutoTask", {Title = "Legit Auto Task Completion", Default = false}):OnChanged(function(state)
    toggleLegitAutoTask(state)
end)

-- Function to remove duplicate NPC models
local function removeDuplicateNPCs()
    local userModels = {}

    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("Animations") then
            for _, player in ipairs(players:GetPlayers()) do
                if model.Name == player.Name then
                    if userModels[player.Name] then
                        model:Destroy()
                        print("Removed duplicate NPC model for user: " .. player.Name)
                    else
                        userModels[player.Name] = model
                    end
                end
            end
        end
    end

    Fluent:Notify({
        Title = "Remove NPC",
        Content = "Duplicate NPCs check and cleanup complete.",
        Duration = 5
    })
end

-- Adding buttons and toggles to the Main Tab
Tabs.Main:AddButton({
    Title = "Remove NPC",
    Description = "Remove duplicate NPC models based on player usernames.",
    Callback = function()
        removeDuplicateNPCs()
    end
})

-- Adding toggles to the Visual Tab
Tabs.Visual:AddToggle("PlayerESP", {Title = "Player ESP (with Distance & Teams)", Default = false}):OnChanged(function(state)
    espEnabled = state
    updatePlayerESP()
    Fluent:Notify({
        Title = "Player ESP",
        Content = espEnabled and "Player ESP enabled." or "Player ESP disabled.",
        Duration = 3
    })
end)

Tabs.Visual:AddToggle("NPCESP", {Title = "NPC ESP", Default = false}):OnChanged(function(state)
    npcEspEnabled = state
    updateNPCESP()
    Fluent:Notify({
        Title = "NPC ESP",
        Content = npcEspEnabled and "NPC ESP enabled." or "NPC ESP disabled.",
        Duration = 3
    })
end)



-- Dropdown for player selection
local PlayerDropdown = Tabs.Statistics:AddDropdown("PlayerDropdown", {
    Title = "Select a Player",
    Values = getPlayerNames(),
    Multi = false,
    Default = nil,
})

-- Input field to display the cash value
local CashInput = Tabs.Statistics:AddInput("CashInput", {
    Title = "Cash Value",
    Default = "Select a player to view cash",
    Placeholder = "Cash will be displayed here",
    Numeric = true, -- Only allows numbers
    ReadOnly = true -- Prevent user from editing manually
})

PlayerDropdown:OnChanged(function(selected)
    local selectedPlayer = selected
    local player = players:FindFirstChild(selectedPlayer)
    if player and player:FindFirstChild("Data") and player.Data:FindFirstChild("Cash") then
        local cashValue = player.Data.Cash.Value
        -- Update the input field with the player's cash value
        CashInput:SetValue(tostring(cashValue))
    else
        -- Display an error message if the player's cash value can't be found
        CashInput:SetValue("Error: Cash not found")
    end
end)

-- Function to update the dropdown when players join or leave
local function updateDropdown()
    PlayerDropdown:SetValues(getPlayerNames())
end

-- Connect to player added and removed events to keep the dropdown updated
players.PlayerAdded:Connect(updateDropdown)
players.PlayerRemoving:Connect(updateDropdown)


-- Add a label to the Credit tab
Tabs.Credit:AddParagraph({
    Title = "Credits",
    Content = "Script by No_rbex\nBE NPC OR DIE " .. Fluent.Version
})

-- Set up SaveManager and InterfaceManager
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

-- Initial setup complete
Window:SelectTab(1)

Fluent:Notify({
    Title = "NRBX",
    Content = "The script has been loaded.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
