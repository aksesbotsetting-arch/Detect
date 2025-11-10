-- STEALTH TELEPORT v4.0
-- NoClip OFF after teleport - Bypass anti-NoClip detection!

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Hapus GUI lama
if LocalPlayer.PlayerGui:FindFirstChild("CustomGUI") then
    LocalPlayer.PlayerGui:FindFirstChild("CustomGUI"):Destroy()
end

-- Load character
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
local Humanoid = Character:WaitForChild("Humanoid", 10)

if not HumanoidRootPart or not Humanoid then
    warn("Failed to load character")
    return
end

-- Variables
local SavedPosition = nil
local IsTeleporting = false
local NoClipConnection = nil
local PositionLockConnection = nil

-- ==================== STEALTH BYPASS METHODS ====================

-- NOCLIP TEMPORARY (Hanya saat teleport!)
local function EnableNoClip()
    if NoClipConnection then return end
    
    NoClipConnection = RunService.Stepped:Connect(function()
        pcall(function()
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

local function DisableNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
    
    -- Restore collision
    pcall(function()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
        HumanoidRootPart.CanCollide = false -- HRP tetap false
    end)
end

-- NETWORK OWNERSHIP
local function ClaimNetworkOwnership()
    pcall(function()
        for i = 1, 5 do
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") and part:CanSetNetworkOwnership() then
                    part:SetNetworkOwner(LocalPlayer)
                end
            end
            wait(0.05)
        end
    end)
end

-- DESTROY CONSTRAINTS
local function DestroyConstraints()
    pcall(function()
        for _, obj in pairs(HumanoidRootPart:GetChildren()) do
            if obj:IsA("BodyMover") or obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") 
               or obj:IsA("BodyPosition") or obj:IsA("BodyForce") or obj:IsA("Constraint") then
                obj:Destroy()
            end
        end
    end)
end

-- POSITION LOCK (SMART - Detect player movement)
local PlayerIsMoving = false

local function SmartPositionLock(targetPos, duration)
    if PositionLockConnection then
        PositionLockConnection:Disconnect()
    end
    
    local startTime = tick()
    local lockActive = true
    
    PositionLockConnection = RunService.Heartbeat:Connect(function()
        if not HumanoidRootPart or not HumanoidRootPart.Parent then
            if PositionLockConnection then
                PositionLockConnection:Disconnect()
                PositionLockConnection = nil
            end
            return
        end
        
        -- Check if duration expired
        if tick() - startTime > duration then
            lockActive = false
            if PositionLockConnection then
                PositionLockConnection:Disconnect()
                PositionLockConnection = nil
            end
            return
        end
        
        -- Detect player movement input
        if Humanoid then
            local moveVector = Humanoid.MoveVector
            if moveVector.Magnitude > 0.1 then
                PlayerIsMoving = true
                lockActive = false
                if PositionLockConnection then
                    PositionLockConnection:Disconnect()
                    PositionLockConnection = nil
                end
                return
            end
        end
        
        -- Lock position if not moving
        if lockActive and not PlayerIsMoving then
            local currentPos = HumanoidRootPart.Position
            local distance = (currentPos - targetPos).Magnitude
            
            if distance > 3 then
                pcall(function()
                    HumanoidRootPart.CFrame = CFrame.new(targetPos)
                    HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
                    HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
            end
        end
    end)
end

local function UnlockPosition()
    if PositionLockConnection then
        PositionLockConnection:Disconnect()
        PositionLockConnection = nil
    end
end

-- ANCHOR METHOD (Short duration)
local function AnchorTeleport(targetPos, holdTime)
    pcall(function()
        -- Multiple teleport attempts
        for i = 1, 3 do
            HumanoidRootPart.CFrame = CFrame.new(targetPos)
            wait(0.03)
        end
        
        -- Anchor to hold position
        HumanoidRootPart.Anchored = true
        HumanoidRootPart.CFrame = CFrame.new(targetPos)
        
        wait(holdTime)
        
        -- Unanchor
        HumanoidRootPart.Anchored = false
        
        -- Clear velocity
        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end)
end

-- HUMANOID STATE TRICK
local function HumanoidStateTrick(targetPos)
    pcall(function()
        if not Humanoid then return end
        
        -- Save original state
        local originalState = Humanoid:GetState()
        
        -- Change to physics
        Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        wait(0.1)
        
        -- Teleport
        HumanoidRootPart.CFrame = CFrame.new(targetPos)
        wait(0.2)
        
        -- Restore state
        Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    end)
end

-- ==================== ULTIMATE STEALTH TELEPORT ====================

local function STEALTH_TELEPORT(targetPos)
    if IsTeleporting then
        return false, "Already teleporting"
    end
    
    IsTeleporting = true
    PlayerIsMoving = false
    
    -- STEP 1: Enable NoClip for travel
    EnableNoClip()
    ShowNotification("🔓 NoClip: ON (Traveling...)", Color3.fromRGB(100, 150, 255))
    
    -- STEP 2: Preparation
    ClaimNetworkOwnership()
    DestroyConstraints()
    
    wait(0.1)
    
    -- STEP 3: Calculate distance and choose method
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    
    if distance < 100 then
        -- SHORT DISTANCE: Direct teleport + anchor
        for i = 1, 3 do
            pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end)
            wait(0.05)
        end
        
        AnchorTeleport(targetPos, 0.8)
        
    elseif distance < 500 then
        -- MEDIUM DISTANCE: Step teleport
        local steps = math.ceil(distance / 50)
        local direction = (targetPos - HumanoidRootPart.Position).Unit
        
        for i = 1, steps do
            if not HumanoidRootPart or not HumanoidRootPart.Parent then break end
            
            local stepDist = math.min(50, distance - (i-1) * 50)
            local newPos = HumanoidRootPart.Position + (direction * stepDist)
            
            pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(newPos)
            end)
            wait(0.04)
        end
        
        -- Final position + anchor
        AnchorTeleport(targetPos, 1.0)
        
    else
        -- LONG DISTANCE: Humanoid state trick + anchor
        HumanoidStateTrick(targetPos)
        AnchorTeleport(targetPos, 1.2)
    end
    
    wait(0.2)
    
    -- STEP 4: DISABLE NoClip (IMPORTANT!)
    DisableNoClip()
    ShowNotification("🔒 NoClip: OFF (Arrived!)", Color3.fromRGB(255, 140, 0))
    
    wait(0.3)
    
    -- STEP 5: Position lock (with movement detection)
    SmartPositionLock(targetPos, 5.0) -- Lock 5 seconds or until movement
    ShowNotification("🔐 Position Locked 5s", Color3.fromRGB(255, 200, 0))
    
    -- STEP 6: Continuous position check (backup)
    spawn(function()
        for i = 1, 50 do -- 5 seconds (50 x 0.1s)
            wait(0.1)
            
            if PlayerIsMoving then
                ShowNotification("✓ Unlocked - Move freely!", Color3.fromRGB(0, 255, 0))
                break
            end
            
            -- Check if far from target
            if HumanoidRootPart then
                local dist = (HumanoidRootPart.Position - targetPos).Magnitude
                if dist > 5 then
                    -- Force back if rolled back
                    pcall(function()
                        HumanoidRootPart.CFrame = CFrame.new(targetPos)
                        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    end)
                end
            end
        end
        
        -- After 5 seconds, fully unlock
        if not PlayerIsMoving then
            UnlockPosition()
            ShowNotification("✓ Auto-Unlock Complete!", Color3.fromRGB(0, 255, 0))
        end
    end)
    
    wait(0.5)
    IsTeleporting = false
    
    return true, "Success"
end

-- ==================== GUI CREATION ====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 400)
MainFrame.Position = UDim2.new(0.5, -110, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "🥷 STEALTH TP v4.0"
Title.TextColor3 = Color3.fromRGB(100, 200, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -55)
Container.Position = UDim2.new(0, 10, 0, 45)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

-- Button Creator
local function CreateButton(name, text, position, color, callback)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 45)
    Button.Position = position
    Button.BackgroundColor3 = color
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamSemibold
    Button.AutoButtonColor = false
    Button.Parent = Container
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button
    
    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Size = UDim2.new(0, 60, 1, 0)
    Status.Position = UDim2.new(1, -65, 0, 0)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(255, 255, 255)
    Status.TextSize = 10
    Status.Font = Enum.Font.GothamBold
    Status.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        callback(Button, Status)
    end)
    
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.new(
            math.min(color.R * 1.3, 1),
            math.min(color.G * 1.3, 1),
            math.min(color.B * 1.3, 1)
        )
    end)
    
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = color
    end)
    
    return Button, Status
end

-- SET POSITION Button
CreateButton("SetPos", "SET POSITION", UDim2.new(0, 0, 0, 0),
    Color3.fromRGB(139, 0, 0),
    function(btn, status)
        if not HumanoidRootPart then return end
        
        SavedPosition = HumanoidRootPart.Position
        btn.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
        status.Text = "✓ SAVED"
        
        ShowNotification("📍 Position Saved!", Color3.fromRGB(0, 255, 0))
        
        wait(1.5)
        btn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        status.Text = ""
    end
)

-- TELEPORT Button
CreateButton("TpPos", "TELEPORT (STEALTH)", UDim2.new(0, 0, 0, 55),
    Color3.fromRGB(100, 150, 255),
    function(btn, status)
        if not SavedPosition then
            ShowNotification("❌ No position saved!", Color3.fromRGB(255, 50, 50))
            return
        end
        
        if IsTeleporting then
            ShowNotification("⏳ Please wait...", Color3.fromRGB(255, 100, 0))
            return
        end
        
        status.Text = "TP..."
        ShowNotification("🥷 Stealth TP Starting...", Color3.fromRGB(100, 150, 255))
        
        spawn(function()
            local success, msg = STEALTH_TELEPORT(SavedPosition)
            
            if success then
                status.Text = "✓ DONE"
            else
                ShowNotification("❌ Failed: " .. msg, Color3.fromRGB(255, 50, 50))
                status.Text = "✗ FAIL"
            end
            
            wait(2)
            status.Text = ""
        end)
    end
)

-- Info Panel
local InfoBox = Instance.new("Frame")
InfoBox.Size = UDim2.new(1, 0, 0, 130)
InfoBox.Position = UDim2.new(0, 0, 0, 110)
InfoBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InfoBox.BackgroundTransparency = 0.5
InfoBox.BorderSizePixel = 0
InfoBox.Parent = Container

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoBox

local InfoTitle = Instance.new("TextLabel")
InfoTitle.Size = UDim2.new(1, -10, 0, 20)
InfoTitle.Position = UDim2.new(0, 5, 0, 5)
InfoTitle.BackgroundTransparency = 1
InfoTitle.Text = "📍 SAVED POSITION:"
InfoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoTitle.TextSize = 11
InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
InfoTitle.Parent = InfoBox

local PosText = Instance.new("TextLabel")
PosText.Size = UDim2.new(1, -10, 0, 75)
PosText.Position = UDim2.new(0, 5, 0, 25)
PosText.BackgroundTransparency = 1
PosText.Text = "None"
PosText.TextColor3 = Color3.fromRGB(200, 200, 200)
PosText.TextSize = 10
PosText.Font = Enum.Font.Gotham
PosText.TextXAlignment = Enum.TextXAlignment.Left
PosText.TextYAlignment = Enum.TextYAlignment.Top
PosText.Parent = InfoBox

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 25)
StatusLabel.Position = UDim2.new(0, 5, 0, 100)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = InfoBox

-- NoClip Status Indicator
local NoClipStatus = Instance.new("Frame")
NoClipStatus.Size = UDim2.new(1, 0, 0, 35)
NoClipStatus.Position = UDim2.new(0, 0, 0, 250)
NoClipStatus.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
NoClipStatus.BackgroundTransparency = 0.5
NoClipStatus.BorderSizePixel = 0
NoClipStatus.Parent = Container

local NoClipCorner = Instance.new("UICorner")
NoClipCorner.CornerRadius = UDim.new(0, 8)
NoClipCorner.Parent = NoClipStatus

local NoClipText = Instance.new("TextLabel")
NoClipText.Size = UDim2.new(1, -10, 1, -10)
NoClipText.Position = UDim2.new(0, 5, 0, 5)
NoClipText.BackgroundTransparency = 1
NoClipText.Text = "🔒 NoClip: OFF"
NoClipText.TextColor3 = Color3.fromRGB(255, 255, 255)
NoClipText.TextSize = 11
NoClipText.Font = Enum.Font.GothamBold
NoClipText.Parent = NoClipStatus

-- Stealth Info Box
local StealthBox = Instance.new("Frame")
StealthBox.Size = UDim2.new(1, 0, 0, 70)
StealthBox.Position = UDim2.new(0, 0, 0, 295)
StealthBox.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
StealthBox.BackgroundTransparency = 0.3
StealthBox.BorderSizePixel = 0
StealthBox.Parent = Container

local StealthCorner = Instance.new("UICorner")
StealthCorner.CornerRadius = UDim.new(0, 8)
StealthCorner.Parent = StealthBox

local StealthText = Instance.new("TextLabel")
StealthText.Size = UDim2.new(1, -10, 1, -10)
StealthText.Position = UDim2.new(0, 5, 0, 5)
StealthText.BackgroundTransparency = 1
StealthText.Text = "🥷 STEALTH MODE 🥷\n\n✓ NoClip OFF after TP\n✓ Anti-Detection System\n✓ Move after 5s or earlier"
StealthText.TextColor3 = Color3.fromRGB(255, 255, 255)
StealthText.TextSize = 9
StealthText.Font = Enum.Font.GothamBold
StealthText.TextWrapped = true
StealthText.Parent = StealthBox

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    UnlockPosition()
    DisableNoClip()
    ScreenGui:Destroy()
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
end)

-- Notification
function ShowNotification(text, color)
    color = color or Color3.fromRGB(0, 155, 0)
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 280, 0, 55)
    NotifFrame.Position = UDim2.new(0.5, -140, 0, -70)
    NotifFrame.BackgroundColor3 = color
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 10)
    NotifCorner.Parent = NotifFrame
    
    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, -10, 1, -10)
    NotifText.Position = UDim2.new(0, 5, 0, 5)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = text
    NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifText.TextSize = 12
    NotifText.Font = Enum.Font.GothamBold
    NotifText.TextWrapped = true
    NotifText.Parent = NotifFrame
    
    NotifFrame:TweenPosition(UDim2.new(0.5, -140, 0, 10), "Out", "Quad", 0.3, true)
    
    spawn(function()
        wait(2.5)
        NotifFrame:TweenPosition(UDim2.new(0.5, -140, 0, -70), "In", "Quad", 0.3, true)
        wait(0.3)
        NotifFrame:Destroy()
    end)
end

-- Update display
spawn(function()
    while wait(0.3) do
        if SavedPosition and HumanoidRootPart then
            local dist = (SavedPosition - HumanoidRootPart.Position).Magnitude
            PosText.Text = string.format("X: %.1f  Y: %.1f  Z: %.1f\n\nDistance: %.1f studs", 
                SavedPosition.X, SavedPosition.Y, SavedPosition.Z, dist)
        end
        
        -- Update NoClip indicator
        if NoClipConnection then
            NoClipStatus.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
            NoClipText.Text = "🔓 NoClip: ON"
        else
            NoClipStatus.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
            NoClipText.Text = "🔒 NoClip: OFF"
        end
        
        -- Update status
        if IsTeleporting then
            StatusLabel.Text = "⚡ Status: Teleporting..."
            StatusLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
        elseif PositionLockConnection then
            StatusLabel.Text = "🔐 Status: Locked (5s)"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        elseif PlayerIsMoving then
            StatusLabel.Text = "🏃 Status: Moving (Unlocked)"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            StatusLabel.Text = "✓ Status: Ready"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        end
    end
end)

-- Character respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 10)
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    UnlockPosition()
    DisableNoClip()
    IsTeleporting = false
    PlayerIsMoving = false
end)

-- Load notification
spawn(function()
    wait(0.5)
    ShowNotification("🥷 STEALTH TP v4.0 LOADED!\nNoClip OFF after arrival!", Color3.fromRGB(100, 150, 255))
end)

print("🥷 STEALTH TELEPORT v4.0 LOADED - Anti-NoClip Detection!")
