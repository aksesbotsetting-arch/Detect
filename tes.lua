-- Roblox Teleport & Anti-Hit System
-- Creator: NazamOfficial

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Variables
local SavedPosition = nil
local AntiHitEnabled = false
local OriginalVelocity = nil
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
MainFrame.Size = UDim2.new(0, 280, 0, 220)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -110)
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
Header.Size = UDim2.new(1, 0, 0, 40)
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
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "NazamOfficial"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.BorderSizePixel = 0
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Creator Label
local CreatorLabel = Instance.new("TextLabel")
CreatorLabel.Name = "CreatorLabel"
CreatorLabel.Size = UDim2.new(1, -20, 0, 20)
CreatorLabel.Position = UDim2.new(0, 10, 0, 45)
CreatorLabel.BackgroundTransparency = 1
CreatorLabel.Text = "Creator: NazamOfficial"
CreatorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CreatorLabel.TextSize = 12
CreatorLabel.Font = Enum.Font.Gotham
CreatorLabel.TextXAlignment = Enum.TextXAlignment.Left
CreatorLabel.Parent = MainFrame

-- Notification Label
local NotificationLabel = Instance.new("TextLabel")
NotificationLabel.Name = "NotificationLabel"
NotificationLabel.Size = UDim2.new(1, -20, 0, 20)
NotificationLabel.Position = UDim2.new(0, 10, 0, 70)
NotificationLabel.BackgroundTransparency = 1
NotificationLabel.Text = ""
NotificationLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
NotificationLabel.TextSize = 13
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
    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.GothamSemibold
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
    end)
    
    return button
end

-- Create Buttons
local SetPosButton = CreateButton("SetPosButton", "Set Position", UDim2.new(0, 10, 0, 100), MainFrame)
local TeleportButton = CreateButton("TeleportButton", "Teleport to Position", UDim2.new(0, 10, 0, 145), MainFrame)
local AntiHitButton = CreateButton("AntiHitButton", "Anti-Hit: OFF", UDim2.new(0, 10, 0, 190), MainFrame)

-- Mini Icon Frame (collapsed state)
local MiniIcon = Instance.new("Frame")
MiniIcon.Name = "MiniIcon"
MiniIcon.Size = UDim2.new(0, 60, 0, 60)
MiniIcon.Position = UDim2.new(0, 20, 0, 20)
MiniIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MiniIcon.BorderSizePixel = 0
MiniIcon.Visible = false
MiniIcon.Active = true
MiniIcon.Draggable = true
MiniIcon.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 10)
MiniCorner.Parent = MiniIcon

local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(1, 0, 1, 0)
MiniButton.BackgroundTransparency = 1
MiniButton.Text = "⚙️"
MiniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniButton.TextSize = 28
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

-- Teleport Button
TeleportButton.MouseButton1Click:Connect(function()
    if SavedPosition then
        if Character and HumanoidRootPart then
            HumanoidRootPart.CFrame = SavedPosition
            ShowNotification("✓ Teleported Successfully!", 2)
        else
            ShowNotification("✗ Error: Character not found!", 2)
        end
    else
        ShowNotification("✗ No saved position!", 2)
    end
end)

-- Anti-Hit System
local function EnableAntiHit()
    if not Character or not HumanoidRootPart then return end
    
    -- Prevent velocity changes
    if Connections.VelocityReset then
        Connections.VelocityReset:Disconnect()
    end
    
    Connections.VelocityReset = RunService.Heartbeat:Connect(function()
        if Character and HumanoidRootPart and AntiHitEnabled then
            -- Reset velocity to prevent knockback
            if HumanoidRootPart.AssemblyLinearVelocity.Magnitude > 50 then
                HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
    
    -- Make character more stable
    if HumanoidRootPart then
        OriginalVelocity = HumanoidRootPart.AssemblyLinearVelocity
    end
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
