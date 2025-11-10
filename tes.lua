

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
    floor3d = false
}

local originalWalkSpeed = 16
local originalJumpPower = 50
local originalFOV = 70
local lockedTarget = nil
local floor3dConnection = nil
local lockPlayerConnection = nil
local pvpBlurEffect = nil
local pvpVignetteEffect = nil

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
MainFrame.Size = UDim2.new(0, 200, 0, 300)
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
local Floor3DBtn = createButton("3D Floor", 5)

-- Toggle function
local function toggleButton(button, state)
    if state then
        button.BackgroundColor3 = Color3.fromRGB(0, 139, 0)
    else
        button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    end
end

-- PvP Mode Function with Zoom Effect
local function togglePvPMode()
    states.pvpMode = not states.pvpMode
    toggleButton(PvPModeBtn, states.pvpMode)
    
    local camera = workspace.CurrentCamera
    
    if states.pvpMode then
        -- Change FOV untuk zoom effect
        camera.FieldOfView = 90
        
        -- Create Vignette Effect (efek gelap di pinggir)
        if not pvpVignetteEffect then
            pvpVignetteEffect = Instance.new("ScreenGui")
            pvpVignetteEffect.Name = "PvPVignette"
            pvpVignetteEffect.IgnoreGuiInset = true
            pvpVignetteEffect.ResetOnSpawn = false
            
            local vignetteFrame = Instance.new("ImageLabel")
            vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
            vignetteFrame.Position = UDim2.new(0, 0, 0, 0)
            vignetteFrame.BackgroundTransparency = 1
            vignetteFrame.Image = "rbxasset://textures/ui/VignetteOverlay.png"
            vignetteFrame.ImageColor3 = Color3.fromRGB(0, 0, 0)
            vignetteFrame.ImageTransparency = 0.3
            vignetteFrame.ScaleType = Enum.ScaleType.Slice
            vignetteFrame.SliceCenter = Rect.new(0, 0, 0, 0)
            vignetteFrame.Parent = pvpVignetteEffect
            
            pcall(function()
                pvpVignetteEffect.Parent = game:GetService("CoreGui")
            end)
            if pvpVignetteEffect.Parent ~= game:GetService("CoreGui") then
                pvpVignetteEffect.Parent = player:WaitForChild("PlayerGui")
            end
        end
        
        -- Create Motion Blur Effect
        if not camera:FindFirstChild("PvPBlur") then
            local blur = Instance.new("BlurEffect")
            blur.Name = "PvPBlur"
            blur.Size = 3
            blur.Parent = camera
        end
        
    else
        -- Remove effects
        camera.FieldOfView = originalFOV
        
        if pvpVignetteEffect then
            pvpVignetteEffect:Destroy()
            pvpVignetteEffect = nil
        end
        
        local blur = camera:FindFirstChild("PvPBlur")
        if blur then
            blur:Destroy()
        end
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

-- 3D Floor Function (Platform yang bikin terbang)
local floorPart = nil

local function toggle3DFloor()
    states.floor3d = not states.floor3d
    toggleButton(Floor3DBtn, states.floor3d)
    
    if states.floor3d then
        -- Create persistent platform
        floorPart = Instance.new("Part")
        floorPart.Name = "FloatingPlatform"
        floorPart.Size = Vector3.new(6, 0.5, 6)
        floorPart.Anchored = true
        floorPart.CanCollide = true
        floorPart.Transparency = 0.3
        floorPart.Material = Enum.Material.Neon
        floorPart.BrickColor = BrickColor.new("Lime green")
        floorPart.TopSurface = Enum.SurfaceType.Smooth
        floorPart.BottomSurface = Enum.SurfaceType.Smooth
        floorPart.Parent = workspace
        
        -- Trail parts for visual effect
        local trailParts = {}
        
        floor3dConnection = RunService.Heartbeat:Connect(function()
            if floorPart and rootPart then
                -- Update platform position (di bawah player)
                local targetPos = rootPart.Position - Vector3.new(0, 3.5, 0)
                floorPart.Position = targetPos
                
                -- Create trail effect
                local trailPart = Instance.new("Part")
                trailPart.Size = Vector3.new(6, 0.5, 6)
                trailPart.Position = targetPos
                trailPart.Anchored = true
                trailPart.CanCollide = false
                trailPart.Transparency = 0.5
                trailPart.Material = Enum.Material.Neon
                trailPart.BrickColor = BrickColor.new("Lime green")
                trailPart.Parent = workspace
                
                table.insert(trailParts, trailPart)
                
                -- Fade out trail
                spawn(function()
                    wait(0.1)
                    for i = 1, 10 do
                        if trailPart and trailPart.Parent then
                            trailPart.Transparency = trailPart.Transparency + 0.05
                            wait(0.05)
                        end
                    end
                    if trailPart and trailPart.Parent then
                        trailPart:Destroy()
                    end
                end)
                
                -- Clean up old trails
                if #trailParts > 20 then
                    local oldPart = table.remove(trailParts, 1)
                    if oldPart and oldPart.Parent then
                        oldPart:Destroy()
                    end
                end
            end
        end)
    else
        if floor3dConnection then
            floor3dConnection:Disconnect()
            floor3dConnection = nil
        end
        
        if floorPart then
            floorPart:Destroy()
            floorPart = nil
        end
        
        -- Clean up all trail parts
        for _, part in pairs(workspace:GetChildren()) do
            if part:IsA("Part") and part.BrickColor == BrickColor.new("Lime green") and part.Material == Enum.Material.Neon then
                part:Destroy()
            end
        end
    end
end

-- Button Connections
PvPModeBtn.MouseButton1Click:Connect(togglePvPMode)
SpeedBoostBtn.MouseButton1Click:Connect(toggleSpeedBoost)
JumpBoostBtn.MouseButton1Click:Connect(toggleJumpBoost)
LockPlayerBtn.MouseButton1Click:Connect(toggleLockPlayer)
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
    toggleButton(Floor3DBtn, false)
    
    -- Disconnect connections
    if lockPlayerConnection then lockPlayerConnection:Disconnect() end
    if floor3dConnection then floor3dConnection:Disconnect() end
    
    -- Remove PvP effects
    if pvpVignetteEffect then
        pvpVignetteEffect:Destroy()
        pvpVignetteEffect = nil
    end
    
    local camera = workspace.CurrentCamera
    local blur = camera:FindFirstChild("PvPBlur")
    if blur then blur:Destroy() end
end)

print("SabScript loaded successfully!")
