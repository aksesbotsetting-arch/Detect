

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- State variables
local states = {
    pvpMode = false,
    speedBoost = false,
    jumpBoost = false,
    lockPlayer = false,
    shiftLock = false,
    floor3d = false
}

local originalWalkSpeed = 16
local originalJumpPower = 50
local originalFOV = 70
local lockedTarget = nil
local floor3dConnection = nil
local shiftLockConnection = nil
local lockPlayerConnection = nil

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SabScriptGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Protection
pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if ScreenGui.Parent ~= game:GetService("CoreGui") then
    ScreenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 350)
MainFrame.Position = UDim2.new(0.5, -100, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Corner
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SabScript"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Buttons Container
local ButtonsContainer = Instance.new("Frame")
ButtonsContainer.Name = "ButtonsContainer"
ButtonsContainer.Size = UDim2.new(1, -20, 1, -50)
ButtonsContainer.Position = UDim2.new(0, 10, 0, 45)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ButtonsContainer

-- Function to create buttons
local function createButton(name, layoutOrder)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 45)
    button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 16
    button.Font = Enum.Font.GothamSemibold
    button.LayoutOrder = layoutOrder
    button.Parent = ButtonsContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    return button
end

-- Create all buttons
local PvPModeBtn = createButton("PvP Mode", 1)
local SpeedBoostBtn = createButton("Speed Boost", 2)
local JumpBoostBtn = createButton("Jump Boost", 3)
local LockPlayerBtn = createButton("Lock Player", 4)
local ShiftLockBtn = createButton("Shift Lock", 5)
local Floor3DBtn = createButton("3D Floor", 6)

-- Toggle function
local function toggleButton(button, state)
    if state then
        button.BackgroundColor3 = Color3.fromRGB(0, 139, 0)
    else
        button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    end
end

-- PvP Mode Function
local function togglePvPMode()
    states.pvpMode = not states.pvpMode
    toggleButton(PvPModeBtn, states.pvpMode)
    
    local camera = workspace.CurrentCamera
    if states.pvpMode then
        camera.FieldOfView = 90
    else
        camera.FieldOfView = originalFOV
    end
end

-- Speed Boost Function
local function toggleSpeedBoost()
    states.speedBoost = not states.speedBoost
    toggleButton(SpeedBoostBtn, states.speedBoost)
    
    if states.speedBoost then
        humanoid.WalkSpeed = 18
    else
        humanoid.WalkSpeed = originalWalkSpeed
    end
end

-- Jump Boost Function
local function toggleJumpBoost()
    states.jumpBoost = not states.jumpBoost
    toggleButton(JumpBoostBtn, states.jumpBoost)
    
    if states.jumpBoost then
        if humanoid.UseJumpPower then
            humanoid.JumpPower = originalJumpPower + 10
        else
            humanoid.JumpHeight = 7.2 + 1
        end
    else
        if humanoid.UseJumpPower then
            humanoid.JumpPower = originalJumpPower
        else
            humanoid.JumpHeight = 7.2
        end
    end
end

-- Lock Player Function
local function findNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = 30
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local otherHumanoid = otherPlayer.Character:FindFirstChild("Humanoid")
            
            if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
                local distance = (rootPart.Position - otherRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = otherPlayer
                end
            end
        end
    end
    
    return nearestPlayer
end

local function toggleLockPlayer()
    states.lockPlayer = not states.lockPlayer
    toggleButton(LockPlayerBtn, states.lockPlayer)
    
    if states.lockPlayer then
        lockPlayerConnection = RunService.Heartbeat:Connect(function()
            local target = findNearestPlayer()
            if target and target.Character then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    lockedTarget = targetRoot
                    local lookVector = (targetRoot.Position - rootPart.Position).Unit
                    rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
                end
            end
        end)
    else
        if lockPlayerConnection then
            lockPlayerConnection:Disconnect()
            lockPlayerConnection = nil
        end
        lockedTarget = nil
    end
end

-- Shift Lock Function
local function toggleShiftLock()
    states.shiftLock = not states.shiftLock
    toggleButton(ShiftLockBtn, states.shiftLock)
    
    if states.shiftLock then
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        wait(0.1)
        player.CameraMode = Enum.CameraMode.Classic
        
        shiftLockConnection = RunService.RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z))
            end
        end)
    else
        if shiftLockConnection then
            shiftLockConnection:Disconnect()
            shiftLockConnection = nil
        end
    end
end

-- 3D Floor Function
local activeParts = {}

local function toggle3DFloor()
    states.floor3d = not states.floor3d
    toggleButton(Floor3DBtn, states.floor3d)
    
    if states.floor3d then
        floor3dConnection = RunService.Heartbeat:Connect(function()
            -- Remove old parts
            for _, part in pairs(activeParts) do
                if part and part.Parent then
                    part:Destroy()
                end
            end
            activeParts = {}
            
            -- Create new part
            local floorPart = Instance.new("Part")
            floorPart.Size = Vector3.new(4, 0.5, 4)
            floorPart.Position = rootPart.Position - Vector3.new(0, 3, 0)
            floorPart.Anchored = true
            floorPart.CanCollide = false
            floorPart.Transparency = 0.5
            floorPart.Material = Enum.Material.Neon
            floorPart.BrickColor = BrickColor.new("Lime green")
            floorPart.Parent = workspace
            
            table.insert(activeParts, floorPart)
            
            -- Auto remove after 0.5 seconds
            game:GetService("Debris"):AddItem(floorPart, 0.5)
        end)
    else
        if floor3dConnection then
            floor3dConnection:Disconnect()
            floor3dConnection = nil
        end
        
        for _, part in pairs(activeParts) do
            if part and part.Parent then
                part:Destroy()
            end
        end
        activeParts = {}
    end
end

-- Button Connections
PvPModeBtn.MouseButton1Click:Connect(togglePvPMode)
SpeedBoostBtn.MouseButton1Click:Connect(toggleSpeedBoost)
JumpBoostBtn.MouseButton1Click:Connect(toggleJumpBoost)
LockPlayerBtn.MouseButton1Click:Connect(toggleLockPlayer)
ShiftLockBtn.MouseButton1Click:Connect(toggleShiftLock)
Floor3DBtn.MouseButton1Click:Connect(toggle3DFloor)

-- Character Reset Handler
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    -- Reset all states
    for key, _ in pairs(states) do
        states[key] = false
    end
    
    -- Update button colors
    toggleButton(PvPModeBtn, false)
    toggleButton(SpeedBoostBtn, false)
    toggleButton(JumpBoostBtn, false)
    toggleButton(LockPlayerBtn, false)
    toggleButton(ShiftLockBtn, false)
    toggleButton(Floor3DBtn, false)
    
    -- Disconnect connections
    if lockPlayerConnection then lockPlayerConnection:Disconnect() end
    if shiftLockConnection then shiftLockConnection:Disconnect() end
    if floor3dConnection then floor3dConnection:Disconnect() end
end)

print("SabScript loaded successfully!")
