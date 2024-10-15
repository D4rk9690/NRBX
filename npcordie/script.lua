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
    Title = "[🍂] Be NPC or DIE! 💢 ",
    SubTitle = "by NRBX",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    Acrylic = true,
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "grid" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Statistics = Window:AddTab({ Title = "Statistics", Icon = "bar-chart-2" }), -- Statistics tab
    Credit = Window:AddTab({ Title = "Credit", Icon = "award" })
}

-- OPTIONS
local espEnabled = false
local npcEspEnabled = false
local autoTaskEnabled = false
local instantInteractionEnabled = false
local selectedPlayer
local autoFarmEnabled = false
local autoInteractEnabled = false







-- 
-- --
-- DEBUG ANTI NPC PART
-- --
-- 


local function debugMap()
    local mapFolders = {
        "PirateOutpost",
        "ShoppingMall",
        "Hotel",
        "LighthouseCove",
        "Town",
        "RailYard",
        "Office",
        "Prison"
    }

    for _, folderName in ipairs(mapFolders) do
        local mapFolder = workspace:FindFirstChild(folderName)
        if mapFolder then
            local pathModifications = mapFolder:FindFirstChild("PathfindingModifications")
            if pathModifications then
                for _, part in ipairs(pathModifications:GetChildren()) do
                    if part:IsA("BasePart") and part.Name == "AntiNPCPart" then
                        part.Transparency = 0 -- Set opacity to 0 (fully transparent)
                        part.CanCollide = true -- Enable collision
                    end
                end
                Fluent:Notify({
                    Title = "Debug Complete",
                    Content = "Pathfinding modifications applied for " .. folderName,
                    Duration = 5
                })
                return
            end
        end
    end

    Fluent:Notify({
        Title = "Debug Info",
        Content = "No relevant map found or no PathfindingModifications folder detected.",
        Duration = 5
    })
end




-- 
-- --
-- AUTO INTERACT
-- --
-- 

local function autoInteract()
    while autoInteractEnabled do
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                -- Check if the parent has a PrimaryPart or a specific part to get the position
                local parentModel = prompt.Parent
                local interactPart = parentModel:IsA("Model") and parentModel.PrimaryPart or parentModel:FindFirstChildWhichIsA("BasePart")

                if interactPart then
                    local distance = (players.LocalPlayer.Character.HumanoidRootPart.Position - interactPart.Position).Magnitude
                    if distance <= prompt.MaxActivationDistance then
                        prompt:InputHoldBegin()
                        wait(0.1)  -- Simulate hold
                        prompt:InputHoldEnd()
                    end
                end
            end
        end
        wait(0.5) -- Check every 0.5 seconds for new prompts
    end
end

local function toggleAutoInteract(state)
    autoInteractEnabled = state
    if autoInteractEnabled then
        Fluent:Notify({ Title = "Auto Interact", Content = "Auto Interact enabled.", Duration = 3 })
        autoInteract()
    else
        Fluent:Notify({ Title = "Auto Interact", Content = "Auto Interact disabled.", Duration = 3 })
    end
end



-- 
-- --
-- AutoFarm TP
-- --
-- 


local function autoFarmTasks()
    while autoFarmEnabled do
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
                        local highlightedTask = nil

                        -- Iterate through all tasks to find one with TargetTaskHighlight
                        for _, task in ipairs(tasksFolder:GetChildren()) do
                            if task:IsA("Model") and task:FindFirstChild("TargetTaskHighlight") then
                                highlightedTask = task
                                break -- Prioritize the task with TargetTaskHighlight
                            end
                        end

                        -- If a highlighted task is found, teleport to it
                        if highlightedTask then
                            local taskPosition = highlightedTask:FindFirstChild("Hitbox")
                            if taskPosition and taskPosition.Position then
                                humanoidRootPart.CFrame = CFrame.new(taskPosition.Position)
                                wait(1) -- Wait 1 second to simulate task completion
                            end
                        else
                            -- No highlighted task found, teleport to ObbyEndPart
                            local obbyEndPart = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Obby") and workspace.Lobby.Obby:FindFirstChild("ObbyEndPart")
                            if obbyEndPart then
                                humanoidRootPart.CFrame = obbyEndPart.CFrame
                            end
                        end
                    end
                end
            end
        end
        wait(2) -- Check for new tasks after 2 seconds
    end
end


-- Function to toggle AutoFarm
local function toggleAutoFarm(state)
    autoFarmEnabled = state
    if autoFarmEnabled then
        Fluent:Notify({
            Title = "AutoFarm",
            Content = "AutoFarm enabled.",
            Duration = 3
        })
        task.spawn(autoFarmTasks)
    else
        Fluent:Notify({
            Title = "AutoFarm",
            Content = "AutoFarm disabled.",
            Duration = 3
        })
    end
end




-- 
-- --
-- INTANT INTERACT
-- --
-- 


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




-- 
-- --
-- UPDATE PLAYER LIST
-- --
-- 

local function getPlayerNames()
    local playerNames = {}
    for _, player in ipairs(players:GetPlayers()) do
        table.insert(playerNames, player.Name)
    end
    return playerNames
end




-- 
-- --
-- LEGIT AUTO COMPLETE TASK
-- --
-- 


-- Store connections in a separate table
local connectionStore = {}

-- Function to gradually move the player to a target position with obstacle avoidance
local function walkToPosition(targetPosition)
    local character = players.LocalPlayer.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if humanoidRootPart and humanoid then
            -- Disconnect any previous path connections if they exist
            if connectionStore.reachedConnection then
                connectionStore.reachedConnection:Disconnect()
                connectionStore.reachedConnection = nil
            end
            if connectionStore.blockedConnection then
                connectionStore.blockedConnection:Disconnect()
                connectionStore.blockedConnection = nil
            end

            -- Calculate the path
            local path = pathfindingService:CreatePath({
                AgentRadius = 1.5,  -- Adjust to match the character's width
                AgentHeight = 5,    -- Adjust to match the character's height
                AgentCanJump = true,
                AgentCanClimb = true,
                AgentJumpHeight = 7,
                AgentMaxSlope = 45,
            })

            -- Compute the path and check if it is successful
            local success, message = pcall(function()
                path:ComputeAsync(humanoidRootPart.Position, targetPosition)
            end)

            if success and path.Status == Enum.PathStatus.Success then
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
                    game:GetService("Debris"):AddItem(part, 1)
                end

                -- Function to move to each waypoint and handle obstacles
                local function moveToWaypoint(index)
                    if index > #waypoints then
                        print("Path completed.")
                        return
                    end

                    local waypoint = waypoints[index]
                    
                    -- Jump if the waypoint requires it
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        humanoid.Jump = true
                    end

                    -- Move to the waypoint
                    humanoid:MoveTo(waypoint.Position)

                    -- Wait for the character to reach the waypoint or get blocked
                    connectionStore.reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
                        -- Disconnect connections to prevent conflicts
                        if connectionStore.reachedConnection then
                            connectionStore.reachedConnection:Disconnect()
                            connectionStore.reachedConnection = nil
                        end
                        if connectionStore.blockedConnection then
                            connectionStore.blockedConnection:Disconnect()
                            connectionStore.blockedConnection = nil
                        end
                        
                        if reached then
                            moveToWaypoint(index + 1) -- Proceed to the next waypoint
                        else
                            print("Failed to reach waypoint. Recalculating path...")
                            walkToPosition(targetPosition) -- Recalculate path if blocked
                        end
                    end)
                end

                -- Event listener for when the path gets blocked
                connectionStore.blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
                    print("Path blocked at waypoint: ", blockedWaypointIndex)
                    if connectionStore.reachedConnection then
                        connectionStore.reachedConnection:Disconnect()
                        connectionStore.reachedConnection = nil
                    end
                    if connectionStore.blockedConnection then
                        connectionStore.blockedConnection:Disconnect()
                        connectionStore.blockedConnection = nil
                    end
                    walkToPosition(targetPosition) -- Recalculate path if blocked
                end)

                -- Start moving to the first waypoint
                moveToWaypoint(1)
            else
                warn("Path not found or incomplete. Status: ", path.Status or message)
                -- Handle NoPath status gracefully
                Fluent:Notify({
                    Title = "Pathfinding Error",
                    Content = "Unable to find a path to the target position. Make sure the target is reachable.",
                    Duration = 3
                })
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
                        local importantTaskModel = nil
                        local randomTaskModel = nil

                        -- Iterate through all tasks to find one with TargetTaskHighlight or pick a random one
                        for _, taskModel in ipairs(tasksFolder:GetChildren()) do
                            if taskModel:IsA("Model") then
                                if taskModel:FindFirstChild("TargetTaskHighlight") then
                                    importantTaskModel = taskModel
                                    break -- Prioritize the important task
                                elseif not randomTaskModel then
                                    randomTaskModel = taskModel -- Select a random task as a fallback
                                end
                            end
                        end

                        -- If an important task is available, prioritize it
                        if importantTaskModel then
                            local taskPosition = importantTaskModel:FindFirstChild("Hitbox")
                            if taskPosition and taskPosition.Position then
                                -- Calculate the distance to the important task position
                                local distance = (humanoidRootPart.Position - taskPosition.Position).Magnitude

                                -- Set a proximity threshold (distance in studs)
                                local proximityThreshold = 5

                                -- If the player is far enough, move to the important task position
                                if distance > proximityThreshold then
                                    walkToPosition(taskPosition.Position)
                                    wait(1) -- Small wait time before checking again
                                else
                                    print("Close enough to the important task, stopping movement.")
                                end
                            end
                        -- If no important task is available, move to a random task
                        elseif randomTaskModel then
                            local taskPosition = randomTaskModel:FindFirstChild("Hitbox")
                            if taskPosition and taskPosition.Position then
                                -- Calculate the distance to the random task position
                                local distance = (humanoidRootPart.Position - taskPosition.Position).Magnitude

                                -- Set a proximity threshold (distance in studs)
                                local proximityThreshold = 5

                                -- If the player is far enough, move to the random task position
                                if distance > proximityThreshold then
                                    walkToPosition(taskPosition.Position)
                                    wait(1) -- Small wait time before checking again
                                else
                                    print("Close enough to the random task, stopping movement.")
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




-- 
-- --
-- REMOVE DUPLICATE NPC
-- --
-- 

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




















-- 
-- --
-- FEATURES 
-- --
-- 

Tabs.Main:AddParagraph({
    Title = "Features",
    Content = "Enjoy the easy gameplay."
})





-- Remove duplicate NPC
Tabs.Main:AddButton({
    Title = "Remove NPC",
    Description = "Remove duplicate NPC models based on player usernames.",
    Callback = function()
        removeDuplicateNPCs()
    end
})


-- Instant interaction
Tabs.Main:AddToggle("InstantInteraction", {Title = "Instant Interaction", Default = false}):OnChanged(function(state)
    toggleInstantInteraction(state)
end)





-- Debug Anti NPC
Tabs.Main:AddButton({
    Title = "Check and Debug Map",
    Description = "Check the current map and modify pathfinding parts.",
    Callback = function()
        debugMap()
    end
})


-- Auto interact
Tabs.Main:AddToggle("AutoInteract", { Title = "Auto Interact", Default = false }):OnChanged(toggleAutoInteract)


Tabs.Main:AddParagraph({
    Title = "Autofarms",
    Content = "Get rich while being AFK."
})



-- Auto farm tp
Tabs.Main:AddToggle("AutoFarm", {Title = "AutoFarm", Default = false}):OnChanged(function(state)
    toggleAutoFarm(state)
end)


-- Legit auto complete task
Tabs.Main:AddToggle("LegitAutoTask", {Title = "Legit Auto Task Completion", Default = false}):OnChanged(function(state)
    toggleLegitAutoTask(state)
end)





local esp = false -- You can set this to true or false to turn the ESP on or off
local checkInterval = 5 -- Interval (in seconds) to recheck for tasks
local Name = false -- Toggle to display the player's name
local Distance = false -- Toggle to display the distance to the player
local Line = false -- Toggle to display the ESP line (tracer)
local HealthBar = false -- Toggle to display the player's health bar

local mapFolders = {
    "PirateOutpost",
    "ShoppingMall",
    "Hotel",
    "LighthouseCove",
    "Town",
    "RailYard",
    "Office",
    "Prison"
}

local camera = game.Workspace.CurrentCamera
local runService = game:GetService("RunService")

-- Function to create ESP for a specific player part
local function createESP(target, hasTask, humanoid, playerName)
    if not esp then return end -- If ESP is disabled, don't create any ESP

    local color = hasTask and Color3.new(0, 1, 0) or Color3.new(1, 0, 0) -- Green if task exists, Red otherwise

    -- Box for ESP
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 2
    box.Transparency = 1
    box.Color = color

    -- Text label for player name
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Center = true
    nameTag.Outline = false
    nameTag.Size = 18
    nameTag.Font = Drawing.Fonts.Monospace -- Monospace font for code-like appearance
    nameTag.Color = color
    nameTag.Text = playerName

    -- Text label for distance
    local distanceTag = Drawing.new("Text")
    distanceTag.Visible = false
    distanceTag.Center = true
    distanceTag.Outline = false
    distanceTag.Size = 16
    distanceTag.Font = Drawing.Fonts.Monospace
    distanceTag.Color = color

    -- ESP Line (Tracer)
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = color
    line.Thickness = 1

    -- Health Bar
    local healthBarBackground = Drawing.new("Square")
    local healthBar = Drawing.new("Square")
    healthBarBackground.Visible = false
    healthBar.Visible = false
    healthBarBackground.Color = Color3.new(0, 0, 0) -- Black background for the health bar
    healthBar.Color = Color3.new(0, 1, 0) -- Green for health

    -- Update ESP position and visibility every frame
    local connection
    connection = runService.RenderStepped:Connect(function()
        if target and target.Parent then
            local screenPosition, onScreen = camera:WorldToViewportPoint(target.Position)

            if onScreen then
                local targetSize = target.Size * 0.5
                local distance = (camera.CFrame.Position - target.Position).Magnitude

                -- Set box size and position based on distance
                box.Size = Vector2.new(1000 / distance, 1000 / distance)
                box.Position = Vector2.new(screenPosition.X - box.Size.X / 2, screenPosition.Y - box.Size.Y / 2)
                box.Visible = true

                -- Update player name position and visibility
                if Name then
                    nameTag.Position = Vector2.new(screenPosition.X, screenPosition.Y - box.Size.Y / 2 - 15) -- Slightly above the box
                    nameTag.Visible = true
                end

                -- Update distance position and visibility
                if Distance then
                    distanceTag.Text = string.format("Distance: %d", math.floor(distance))
                    distanceTag.Position = Vector2.new(screenPosition.X, screenPosition.Y + box.Size.Y / 2 + 5) -- Slightly below the box
                    distanceTag.Visible = true
                end

                -- Update ESP line (tracer)
                if Line then
                    line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y) -- From bottom center of the screen
                    line.To = Vector2.new(screenPosition.X, screenPosition.Y) -- To the target
                    line.Visible = true
                end

                -- Update health bar
                if HealthBar then
                    healthBarBackground.Visible = true
                    healthBar.Visible = true

                    healthBarBackground.Size = Vector2.new(5, 50) -- Fixed size for background
                    healthBarBackground.Position = Vector2.new(screenPosition.X - 50, screenPosition.Y - 25)

                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    healthBar.Size = Vector2.new(5, 50 * healthPercent) -- Health bar size based on health percentage
                    healthBar.Position = healthBarBackground.Position
                end

            else
                box.Visible = false
                nameTag.Visible = false
                distanceTag.Visible = false
                line.Visible = false
                healthBar.Visible = false
                healthBarBackground.Visible = false
            end
        else
            -- Remove ESP elements when the target is no longer valid
            box.Visible = false
            nameTag.Visible = false
            distanceTag.Visible = false
            line.Visible = false
            healthBar.Visible = false
            healthBarBackground.Visible = false
            connection:Disconnect() -- Stop updating the ESP once target is invalid
            box:Remove()
            nameTag:Remove()
            distanceTag:Remove()
            line:Remove()
            healthBar:Remove()
            healthBarBackground:Remove()
        end
    end)

    return box, nameTag, distanceTag, line, healthBar, healthBarBackground
end

-- Function to check if the object is a map folder
local function isMapFolder(obj)
    return table.find(mapFolders, obj.Name) ~= nil
end


local players = game:GetService("Players") -- Service to get player information
local localPlayer = players.LocalPlayer -- Reference to the local player


-- Function to apply ESP to all players up until a map folder is encountered
local function applyESPToPlayers()
    if not esp then return end -- If ESP is disabled, don't apply ESP

    for _, child in ipairs(game.Workspace:GetChildren()) do
        if isMapFolder(child) then
            print("Encountered map folder: " .. child.Name .. ", stopping ESP application.")
            break
        end

        -- Check if the object is a player model and exclude the local player
        if child:IsA("Model") and child:FindFirstChild("Humanoid") and players:GetPlayerFromCharacter(child) ~= localPlayer then
            local humanoid = child:FindFirstChild("Humanoid")

            -- Check if the Task object exists in the player's model
            local hasTask = child:FindFirstChild("Task") ~= nil

            -- Attempt to find the primary part for ESP (HumanoidRootPart)
            local primaryPart = child:FindFirstChild("HumanoidRootPart")

            if primaryPart then
                print("Found HumanoidRootPart for player: " .. child.Name)
                local espBox, nameTag, distanceTag, line, healthBar, healthBarBackground = createESP(primaryPart, hasTask, humanoid, child.Name)

                -- Remove ESP if the player dies
                humanoid.Died:Connect(function()
                    print("Player " .. child.Name .. " has died, removing ESP")
                    espBox:Remove()
                    nameTag:Remove()
                    distanceTag:Remove()
                    line:Remove()
                    healthBar:Remove()
                    healthBarBackground:Remove()
                end)

                -- Check every 5 seconds if the task status has changed
                task.spawn(function()
                    while humanoid and humanoid.Health > 0 do
                        wait(checkInterval)

                        local currentHasTask = child:FindFirstChild("Task") ~= nil
                        if espBox then
                            -- Update the color of the ESP box and text based on the presence of a task
                            espBox.Color = currentHasTask and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                            nameTag.Color = espBox.Color
                            distanceTag.Color = espBox.Color
                            line.Color = espBox.Color
                            healthBar.Color = espBox.Color
                        end
                    end
                end)
            else
                warn("No HumanoidRootPart found for player: " .. child.Name)
            end
        else
            -- Skip the local player or non-player objects
            if players:GetPlayerFromCharacter(child) == localPlayer then
                print("Skipping local player: " .. child.Name)
            else
                warn("Non-player object found: " .. child.Name)
            end
        end
    end
end

-- Call this function whenever a new map folder is added to workspace
local function onNewMapFolderAdded()
    print("A new map folder has been added to Workspace.")
    applyESPToPlayers()
end

-- Listen for changes in the workspace, reapply ESP when a map folder is added
game.Workspace.ChildAdded:Connect(function(child)
    if isMapFolder(child) then
        onNewMapFolderAdded()
    end
end)

-- Initial ESP application
if esp then
    applyESPToPlayers() -- Apply ESP when the game starts
end





Tabs.Visual:AddParagraph({
    Title = "Players",
    Content = "Player ESP check NPC or seaker."
})




-- Esp Box
Tabs.Visual:AddToggle("BoxESP", {Title = "ESP Box", Default = false}):OnChanged(function(state)
    esp = state
end)


-- Esp Name
Tabs.Visual:AddToggle("NameESP", {Title = "ESP Name", Default = false}):OnChanged(function(state)
    Name = state
end)



-- Esp Distance
Tabs.Visual:AddToggle("DistanceESP", {Title = "ESP Distance", Default = false}):OnChanged(function(state)
    Distance = state
end)


-- Esp Line
Tabs.Visual:AddToggle("LineESP", {Title = "ESP Line", Default = false}):OnChanged(function(state)
    Line = state
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

-- Input field to display the cash value
local NpcKillInput = Tabs.Statistics:AddInput("NpcKillInput", {
    Title = "NPC kills Value",
    Default = "Select a player to view how much NPC were killed.",
    Placeholder = "Will be displayed here",
    Numeric = true, -- Only allows numbers
    ReadOnly = true -- Prevent user from editing manually
})

-- Input field to display the cash value
local XPInput = Tabs.Statistics:AddInput("XPInput", {
    Title = "NPC kills Value",
    Default = "Select a player to view how much NPC were killed.",
    Placeholder = "Will be displayed here",
    Numeric = true, -- Only allows numbers
    ReadOnly = true -- Prevent user from editing manually
})

-- Input field to display the cash value
local winAsHiderInput = Tabs.Statistics:AddInput("winAsHiderInput", {
    Title = "Win as hider Value",
    Default = "Select a player to view how many win as Hider.",
    Placeholder = "Will be displayed here",
    Numeric = true, -- Only allows numbers
    ReadOnly = true -- Prevent user from editing manually
})


-- Input field to display the cash value
local TasksCompletedInput = Tabs.Statistics:AddInput("TasksCompletedInput", {
    Title = "Tasks Completed Value",
    Default = "Select a player to view how many tasks completed.",
    Placeholder = "Will be displayed here",
    Numeric = true, -- Only allows numbers
    ReadOnly = true -- Prevent user from editing manually
})

PlayerDropdown:OnChanged(function(selected)
    local selectedPlayer = selected
    local player = players:FindFirstChild(selectedPlayer)
    if player and player:FindFirstChild("Data") and player.Data:FindFirstChild("Cash") then
        local cashValue = player.Data.Cash.Value
        local xpValue = player.Data.XP.Value
        local npckillValue = player.Data.Statistics.NPCsShot.Value
        local winAsHider = player.Data.Statistics.WinsAsHider.Value
        local TasksCompleted = player.Data.Statistics.TasksCompleted.Value


        -- Update the input field with the player's cash value
        CashInput:SetValue(tostring(cashValue))
        XPInput:SetValue(tostring(xpValue))
        winAsHiderInput:SetValue(tostring(winAsHider))
        NpcKillInput:SetValue(tostring(npckillValue))
        TasksCompletedInput:SetValue(tostring(TasksCompleted))
    else
        -- Display an error message if the player's cash value can't be found
        CashInput:SetValue("Error: Cash not found")
        XPInput:SetValue("Error: XP not found")
        winAsHider:SetValue("Error: Win not found")
        NpcKillInput:SetValue("Error: NPC kills not found")
        TasksCompletedInput:SetValue("Error: Tasks Completed not found")
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
