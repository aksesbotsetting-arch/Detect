-- Roblox Teleport & Anti-Hit System
-- Creator: NazamOfficial

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Variables
local SavedPosition = nil
local AntiHitEnabled = false
local TeleportInProgress = false
local Connections = {}

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportAntiHitGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Create Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 240)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Create Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "NazamOfficial"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 35, 0, 35)
CloseButton.Position = UDim2.new(1, -40, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.BorderSizePixel = 0
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

-- Creator Label
local CreatorLabel = Instance.new("TextLabel")
CreatorLabel.Name = "CreatorLabel"
CreatorLabel.Size = UDim2.new(1, -30, 0, 25)
CreatorLabel.Position = UDim2.new(0, 15, 0, 50)
CreatorLabel.BackgroundTransparency = 1
CreatorLabel.Text = "Creator: NazamOfficial"
CreatorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CreatorLabel.TextSize = 13
CreatorLabel.Font = Enum.Font.Gotham
CreatorLabel.TextXAlignment = Enum.TextXAlignment.Left
CreatorLabel.Parent = MainFrame

-- Notification Label
local NotificationLabel = Instance.new("TextLabel")
NotificationLabel.Name = "NotificationLabel"
NotificationLabel.Size = UDim2.new(1, -30, 0, 25)
NotificationLabel.Position = UDim2.new(0, 15, 0, 80)
NotificationLabel.BackgroundTransparency = 1
NotificationLabel.Text = ""
NotificationLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
NotificationLabel.TextSize = 14
NotificationLabel.Font = Enum.Font.GothamSemibold
NotificationLabel.TextXAlignment = Enum.TextXAlignment.Center
NotificationLabel.Parent = MainFrame

-- Function to show notification
local function ShowNotification(text, duration)
    NotificationLabel.Text = text
    NotificationLabel.TextTransparency = 0
    task.wait(duration or 2)
    local tween = TweenService:Create(NotificationLabel, TweenInfo.new(0.5), {TextTransparency = 1})
    tween:Play()
end

-- Button Creator Function
local function CreateButton(name, text, position, parent)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -30, 0, 40)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 15
    button.Font = Enum.Font.GothamSemibold
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        local baseColor = Color3.fromRGB(45, 45, 45)
        if button.Name == "AntiHitButton" and AntiHitEnabled then
            baseColor = Color3.fromRGB(60, 150, 60)
        end
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = baseColor}):Play()
    end)
    
    return button
end

-- Create Buttons
local SetPosButton = CreateButton("SetPosButton", "Set Position", UDim2.new(0, 15, 0, 110), MainFrame)
local TeleportButton = CreateButton("TeleportButton", "Teleport to Position", UDim2.new(0, 15, 0, 160), MainFrame)
local AntiHitButton = CreateButton("AntiHitButton", "Anti-Hit: OFF", UDim2.new(0, 15, 0, 210), MainFrame)

-- Mini Icon Frame (collapsed state)
local MiniIcon = Instance.new("Frame")
MiniIcon.Name = "MiniIcon"
MiniIcon.Size = UDim2.new(0, 65, 0, 65)
MiniIcon.Position = UDim2.new(0, 20, 0, 20)
MiniIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MiniIcon.BorderSizePixel = 0
MiniIcon.Visible = false
MiniIcon.Active = true
MiniIcon.Draggable = true
MiniIcon.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 12)
MiniCorner.Parent = MiniIcon

local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(1, 0, 1, 0)
MiniButton.BackgroundTransparency = 1
MiniButton.Text = "⚙️"
MiniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniButton.TextSize = 32
MiniButton.Font = Enum.Font.GothamBold
MiniButton.Parent = MiniIcon

-- Toggle GUI function
local function ToggleGUI()
    if MainFrame.Visible then
        MainFrame.Visible = false
        MiniIcon.Visible = true
    else
        MainFrame.Visible = true
        MiniIcon.Visible = false
    end
end

CloseButton.MouseButton1Click:Connect(ToggleGUI)
MiniButton.MouseButton1Click:Connect(ToggleGUI)

-- Set Position Button
SetPosButton.MouseButton1Click:Connect(function()
    if Character and HumanoidRootPart then
        SavedPosition = HumanoidRootPart.CFrame
        ShowNotification("✓ Position Saved Successfully!", 2)
    else
        ShowNotification("✗ Error: Character not found!", 2)
    end
end)

-- Improved Teleport Function
local function TeleportToPosition()
    if not SavedPosition then
        ShowNotification("✗ No saved position!", 2)
        return
    end
    
    if not Character or not HumanoidRootPart or not Humanoid then
        ShowNotification("✗ Error: Character not found!", 2)
        return
    end
    
    if TeleportInProgress then
        return
    end
    
    TeleportInProgress = true
    
    -- Disable anti-hit temporarily during teleport
    local wasAntiHitEnabled = AntiHitEnabled
    if AntiHitEnabled then
        AntiHitEnabled = false
    end
    
    -- Save the target position
    local targetCFrame = SavedPosition
    
    -- Method 1: Direct teleport with PivotTo
    if Character.PrimaryPart then
        Character:PivotTo(targetCFrame)
    end
    
    -- Method 2: Direct CFrame set
    HumanoidRootPart.CFrame = targetCFrame
    
    -- Method 3: Reset velocity and anchoring
    HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    
    -- Anchor briefly to prevent snapback
    local originalAnchored = HumanoidRootPart.Anchored
    HumanoidRootPart.Anchored = true
    
    task.wait(0.1)
    
    -- Final position set
    HumanoidRootPart.CFrame = targetCFrame
    HumanoidRootPart.Anchored = originalAnchored
    
    -- Re-enable anti-hit if it was enabled
    if wasAntiHitEnabled then
        task.wait(0.1)
        AntiHitEnabled = true
    end
    
    ShowNotification("✓ Teleported Successfully!", 2)
    
    task.wait(0.2)
    TeleportInProgress = false
end

-- Teleport Button
TeleportButton.MouseButton1Click:Connect(TeleportToPosition)

-- Anti-Hit System
local function EnableAntiHit()
    if not Character or not HumanoidRootPart then return end
    
    -- Prevent velocity changes
    if Connections.VelocityReset then
        Connections.VelocityReset:Disconnect()
    end
    
    Connections.VelocityReset = RunService.Heartbeat:Connect(function()
        if Character and HumanoidRootPart and AntiHitEnabled and not TeleportInProgress then
            -- Reset velocity to prevent knockback
            local velocity = HumanoidRootPart.AssemblyLinearVelocity
            if velocity.Magnitude > 60 or math.abs(velocity.Y) > 50 then
                HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                    math.clamp(velocity.X, -20, 20),
                    math.clamp(velocity.Y, -20, 20),
                    math.clamp(velocity.Z, -20, 20)
                )
            end
        end
    end)
end

local function DisableAntiHit()
    if Connections.VelocityReset then
        Connections.VelocityReset:Disconnect()
        Connections.VelocityReset = nil
    end
end

-- Anti-Hit Button
AntiHitButton.MouseButton1Click:Connect(function()
    AntiHitEnabled = not AntiHitEnabled
    
    if AntiHitEnabled then
        AntiHitButton.Text = "Anti-Hit: ON"
        AntiHitButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
        EnableAntiHit()
        ShowNotification("✓ Anti-Hit Enabled!", 2)
    else
        AntiHitButton.Text = "Anti-Hit: OFF"
        AntiHitButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        DisableAntiHit()
        ShowNotification("✗ Anti-Hit Disabled!", 2)
    end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")
    
    -- Reset teleport flag
    TeleportInProgress = false
    
    if AntiHitEnabled then
        task.wait(1)
        EnableAntiHit()
    end
end)

-- Cleanup on script removal
ScreenGui.AncestryChanged:Connect(function(_, parent)
    if not parent then
        DisableAntiHit()
        for _, connection in pairs(Connections) do
            if connection then
                connection:Disconnect()
            end
        end
    end
end)

-- Initial notification
ShowNotification("Script Loaded Successfully!", 3)
