-- ULTIMATE Position Teleporter with ADVANCED Anti-Cheat Bypass
-- Multiple bypass methods for maximum compatibility

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Cek apakah GUI sudah ada, hapus jika iya
if LocalPlayer.PlayerGui:FindFirstChild("CustomGUI") then
    LocalPlayer.PlayerGui:FindFirstChild("CustomGUI"):Destroy()
end

-- Tunggu character load dengan proper error handling
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
local Humanoid = Character:WaitForChild("Humanoid", 10)

if not HumanoidRootPart or not Humanoid then
    warn("Failed to load character components")
    return
end

-- Variabel global
local SavedPosition = nil
local IsTeleporting = false
local BypassMode = "Smart" -- Default mode
local AntiCheatDetected = false

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

-- Frame Utama
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 380)
MainFrame.Position = UDim2.new(0.5, -100, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Header
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "ULTIMATE TP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Container
local FeatureContainer = Instance.new("Frame")
FeatureContainer.Size = UDim2.new(1, -20, 1, -55)
FeatureContainer.Position = UDim2.new(0, 10, 0, 45)
FeatureContainer.BackgroundTransparency = 1
FeatureContainer.Parent = MainFrame

-- ==================== ADVANCED BYPASS FUNCTIONS ====================

-- NOCLIP Function - Tembus Tembok/Pagar/Obstacle
local NoClipEnabled = false
local NoClipConnection = nil

local function EnableNoClip()
    if NoClipConnection then return end
    
    NoClipEnabled = true
    NoClipConnection = RunService.Stepped:Connect(function()
        if not NoClipEnabled or not Character then return end
        
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
    NoClipEnabled = false
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
    end)
end

-- Method 1: Instant Teleport (Fastest, Most Risky)
local function InstantTeleport(targetPos)
    -- Enable NoClip untuk tembus obstacle
    EnableNoClip()
    
    pcall(function()
        HumanoidRootPart.CFrame = CFrame.new(targetPos)
    end)
    
    wait(0.2)
    DisableNoClip()
end

-- Method 2: Smooth Step Teleport (Balanced)
local function SmoothStepTeleport(targetPos)
    -- Enable NoClip untuk tembus obstacle
    EnableNoClip()
    
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    local steps = math.ceil(distance / 35)
    local direction = (targetPos - HumanoidRootPart.Position).Unit
    
    for i = 1, steps do
        if not HumanoidRootPart or not HumanoidRootPart.Parent then break end
        
        local stepDistance = math.min(35, distance - (i-1) * 35)
        local newPos = HumanoidRootPart.Position + (direction * stepDistance)
        
        pcall(function()
            HumanoidRootPart.CFrame = CFrame.new(newPos)
        end)
        
        wait(0.02 + math.random() * 0.01)
    end
    
    pcall(function()
        HumanoidRootPart.CFrame = CFrame.new(targetPos)
    end)
    
    wait(0.2)
    DisableNoClip()
end

-- Method 3: Velocity Simulation (Safest, Slowest)
local function VelocityTeleport(targetPos)
    -- Enable NoClip untuk tembus obstacle
    EnableNoClip()
    
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    local direction = (targetPos - HumanoidRootPart.Position).Unit
    local speed = 250
    
    -- Create BodyVelocity for smooth movement
    local BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BV.Velocity = direction * speed
    BV.Parent = HumanoidRootPart
    
    -- Wait until close to target
    local startTime = tick()
    repeat
        wait(0.03)
        local currentDistance = (targetPos - HumanoidRootPart.Position).Magnitude
        if currentDistance < 10 or (tick() - startTime) > 5 then
            break
        end
    until false
    
    BV:Destroy()
    
    -- Final precise teleport
    pcall(function()
        HumanoidRootPart.CFrame = CFrame.new(targetPos)
    end)
    
    wait(0.2)
    DisableNoClip()
end

-- Method 4: Tween Teleport (Very Smooth)
local function TweenTeleport(targetPos)
    -- Enable NoClip untuk tembus obstacle
    EnableNoClip()
    
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    local time = math.clamp(distance / 100, 0.5, 3)
    
    local tween = TweenService:Create(
        HumanoidRootPart,
        TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
        {CFrame = CFrame.new(targetPos)}
    )
    
    tween:Play()
    tween.Completed:Wait()
    
    wait(0.2)
    DisableNoClip()
end

-- Method 5: Hybrid Method (Combines multiple techniques)
local function HybridTeleport(targetPos)
    -- Enable NoClip untuk tembus obstacle
    EnableNoClip()
    
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    
    if distance < 100 then
        -- Short distance: Use instant
        pcall(function()
            HumanoidRootPart.CFrame = CFrame.new(targetPos)
        end)
    elseif distance < 500 then
        -- Medium distance: Use smooth step without re-enabling noclip
        local steps = math.ceil(distance / 35)
        local direction = (targetPos - HumanoidRootPart.Position).Unit
        
        for i = 1, steps do
            if not HumanoidRootPart or not HumanoidRootPart.Parent then break end
            
            local stepDistance = math.min(35, distance - (i-1) * 35)
            local newPos = HumanoidRootPart.Position + (direction * stepDistance)
            
            pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(newPos)
            end)
            
            wait(0.02 + math.random() * 0.01)
        end
        
        pcall(function()
            HumanoidRootPart.CFrame = CFrame.new(targetPos)
        end)
    else
        -- Long distance: Use velocity simulation without re-enabling noclip
        local direction = (targetPos - HumanoidRootPart.Position).Unit
        local speed = 250
        
        local BV = Instance.new("BodyVelocity")
        BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BV.Velocity = direction * speed
        BV.Parent = HumanoidRootPart
        
        local startTime = tick()
        repeat
            wait(0.03)
            local currentDistance = (targetPos - HumanoidRootPart.Position).Magnitude
            if currentDistance < 10 or (tick() - startTime) > 5 then
                break
            end
        until false
        
        BV:Destroy()
        
        pcall(function()
            HumanoidRootPart.CFrame = CFrame.new(targetPos)
        end)
    end
    
    wait(0.2)
    DisableNoClip()
end

-- ==================== ANTI-CHEAT BYPASS TECHNIQUES ====================

-- Remove velocity constraints
local function RemoveVelocityLimits()
    pcall(function()
        for _, v in pairs(HumanoidRootPart:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyPosition") then
                v:Destroy()
            end
        end
    end)
end

-- Prevent position rollback
local function PreventRollback()
    pcall(function()
        HumanoidRootPart.Anchored = true
        wait(0.03)
        HumanoidRootPart.Anchored = false
    end)
    
    RemoveVelocityLimits()
    
    -- Reset humanoid state
    pcall(function()
        if Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end)
end

-- Network ownership manipulation
local function ClaimNetworkOwnership()
    pcall(function()
        if HumanoidRootPart:CanSetNetworkOwnership() then
            HumanoidRootPart:SetNetworkOwner(LocalPlayer)
        end
    end)
end

-- Disable movement detection temporarily
local function DisableMovementDetection()
    pcall(function()
        -- Disable platform stand
        if Humanoid then
            Humanoid.PlatformStand = false
            Humanoid.Sit = false
        end
        
        -- Set walkspeed to normal to avoid detection
        if Humanoid and Humanoid.WalkSpeed ~= 16 then
            Humanoid.WalkSpeed = 16
        end
    end)
end

-- Smart teleport with auto anti-cheat detection
local function SmartTeleport(targetPos)
    if IsTeleporting then return end
    IsTeleporting = true
    
    -- ALWAYS Enable NoClip sebelum teleport (PENTING!)
    EnableNoClip()
    
    -- Pre-teleport setup
    ClaimNetworkOwnership()
    DisableMovementDetection()
    RemoveVelocityLimits()
    
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    local success = false
    
    -- Try different methods based on distance and detected anti-cheat
    if AntiCheatDetected then
        -- Strict anti-cheat: Use safest method
        success = pcall(function()
            local direction = (targetPos - HumanoidRootPart.Position).Unit
            local speed = 250
            
            local BV = Instance.new("BodyVelocity")
            BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            BV.Velocity = direction * speed
            BV.Parent = HumanoidRootPart
            
            local startTime = tick()
            repeat
                wait(0.03)
                local currentDistance = (targetPos - HumanoidRootPart.Position).Magnitude
                if currentDistance < 10 or (tick() - startTime) > 5 then
                    break
                end
            until false
            
            BV:Destroy()
            HumanoidRootPart.CFrame = CFrame.new(targetPos)
        end)
        
        if not success then
            success = pcall(function()
                local time = math.clamp(distance / 100, 0.5, 3)
                local tween = TweenService:Create(
                    HumanoidRootPart,
                    TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
                    {CFrame = CFrame.new(targetPos)}
                )
                tween:Play()
                tween.Completed:Wait()
            end)
        end
    else
        -- No anti-cheat detected: Try faster methods
        if distance < 150 then
            success = pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end)
        elseif distance < 600 then
            success = pcall(function()
                local steps = math.ceil(distance / 35)
                local direction = (targetPos - HumanoidRootPart.Position).Unit
                
                for i = 1, steps do
                    if not HumanoidRootPart or not HumanoidRootPart.Parent then break end
                    
                    local stepDistance = math.min(35, distance - (i-1) * 35)
                    local newPos = HumanoidRootPart.Position + (direction * stepDistance)
                    HumanoidRootPart.CFrame = CFrame.new(newPos)
                    wait(0.02 + math.random() * 0.01)
                end
                
                HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end)
        else
            success = pcall(HybridTeleport, targetPos)
        end
    end
    
    -- Post-teleport cleanup
    wait(0.2)
    DisableNoClip()
    PreventRollback()
    DisableMovementDetection()
    
    wait(0.15)
    IsTeleporting = false
    
    return success
end

-- Detect if anti-cheat is present
local function DetectAntiCheat()
    spawn(function()
        wait(2)
        local startPos = HumanoidRootPart.Position
        
        -- Test small teleport
        pcall(function()
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
        end)
        
        wait(0.5)
        
        -- Check if position was rolled back
        local endPos = HumanoidRootPart.Position
        local moved = (endPos - startPos).Magnitude
        
        if moved < 3 then
            AntiCheatDetected = true
            ShowNotification("Anti-Cheat Detected!", Color3.fromRGB(255, 100, 0))
        end
    end)
end

-- ==================== GUI FUNCTIONS ====================

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
    Button.Parent = FeatureContainer
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button
    
    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Size = UDim2.new(0, 50, 1, 0)
    Status.Position = UDim2.new(1, -55, 0, 0)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(255, 255, 255)
    Status.TextSize = 11
    Status.Font = Enum.Font.GothamBold
    Status.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        callback(Button, Status)
    end)
    
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.new(color.R * 1.3, color.G * 1.3, color.B * 1.3)
    end)
    
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = color
    end)
    
    return Button, Status
end

-- Button 1: Set Position
CreateButton("SetPos", "SET POSITION", UDim2.new(0, 0, 0, 0), 
    Color3.fromRGB(139, 0, 0), 
    function(btn, status)
        if not HumanoidRootPart then return end
        
        SavedPosition = HumanoidRootPart.Position
        btn.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
        status.Text = "SAVED"
        
        ShowNotification("Position Saved!", Color3.fromRGB(0, 155, 0))
        
        wait(1.5)
        btn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        status.Text = ""
    end
)

-- Button 2: Teleport to Position
CreateButton("TpPos", "TELEPORT TO POS", UDim2.new(0, 0, 0, 55), 
    Color3.fromRGB(255, 140, 0), 
    function(btn, status)
        if not SavedPosition then
            ShowNotification("No position saved!", Color3.fromRGB(255, 50, 50))
            return
        end
        
        if IsTeleporting then
            ShowNotification("Already teleporting!", Color3.fromRGB(255, 100, 0))
            return
        end
        
        status.Text = "TP..."
        ShowNotification("Teleporting...", Color3.fromRGB(255, 140, 0))
        
        spawn(function()
            local success = SmartTeleport(SavedPosition)
            
            if success then
                ShowNotification("Teleport Success!", Color3.fromRGB(0, 255, 0))
                status.Text = "DONE"
            else
                ShowNotification("Teleport Failed!", Color3.fromRGB(255, 50, 50))
                status.Text = "FAIL"
            end
            
            wait(1.5)
            status.Text = ""
        end)
    end
)

-- Info Panel
local InfoBox = Instance.new("Frame")
InfoBox.Size = UDim2.new(1, 0, 0, 110)
InfoBox.Position = UDim2.new(0, 0, 0, 110)
InfoBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InfoBox.BackgroundTransparency = 0.5
InfoBox.BorderSizePixel = 0
InfoBox.Parent = FeatureContainer

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoBox

local InfoTitle = Instance.new("TextLabel")
InfoTitle.Size = UDim2.new(1, -10, 0, 20)
InfoTitle.Position = UDim2.new(0, 5, 0, 5)
InfoTitle.BackgroundTransparency = 1
InfoTitle.Text = "SAVED POSITION:"
InfoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoTitle.TextSize = 11
InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
InfoTitle.Parent = InfoBox

local PosText = Instance.new("TextLabel")
PosText.Size = UDim2.new(1, -10, 0, 60)
PosText.Position = UDim2.new(0, 5, 0, 25)
PosText.BackgroundTransparency = 1
PosText.Text = "None"
PosText.TextColor3 = Color3.fromRGB(200, 200, 200)
PosText.TextSize = 10
PosText.Font = Enum.Font.Gotham
PosText.TextXAlignment = Enum.TextXAlignment.Left
PosText.TextYAlignment = Enum.TextYAlignment.Top
PosText.Parent = InfoBox

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 0, 20)
StatusText.Position = UDim2.new(0, 5, 0, 85)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Status: Ready"
StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusText.TextSize = 10
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = InfoBox

-- Mode Selector
local ModeBox = Instance.new("Frame")
ModeBox.Size = UDim2.new(1, 0, 0, 90)
ModeBox.Position = UDim2.new(0, 0, 0, 230)
ModeBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ModeBox.BackgroundTransparency = 0.5
ModeBox.BorderSizePixel = 0
ModeBox.Parent = FeatureContainer

local ModeCorner = Instance.new("UICorner")
ModeCorner.CornerRadius = UDim.new(0, 8)
ModeCorner.Parent = ModeBox

local ModeTitle = Instance.new("TextLabel")
ModeTitle.Size = UDim2.new(1, -10, 0, 20)
ModeTitle.Position = UDim2.new(0, 5, 0, 5)
ModeTitle.BackgroundTransparency = 1
ModeTitle.Text = "TELEPORT MODE:"
ModeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeTitle.TextSize = 11
ModeTitle.Font = Enum.Font.GothamBold
ModeTitle.TextXAlignment = Enum.TextXAlignment.Left
ModeTitle.Parent = ModeBox

local modes = {"Smart", "Instant", "Smooth", "Safe", "Tween"}
local currentModeIndex = 1

local ModeDisplay = Instance.new("TextLabel")
ModeDisplay.Size = UDim2.new(1, -10, 0, 25)
ModeDisplay.Position = UDim2.new(0, 5, 0, 30)
ModeDisplay.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ModeDisplay.BorderSizePixel = 0
ModeDisplay.Text = "Smart (Auto)"
ModeDisplay.TextColor3 = Color3.fromRGB(0, 255, 0)
ModeDisplay.TextSize = 12
ModeDisplay.Font = Enum.Font.GothamBold
ModeDisplay.Parent = ModeBox

local ModeCorner2 = Instance.new("UICorner")
ModeCorner2.CornerRadius = UDim.new(0, 6)
ModeCorner2.Parent = ModeDisplay

local ChangeModeBtn = Instance.new("TextButton")
ChangeModeBtn.Size = UDim2.new(1, -10, 0, 25)
ChangeModeBtn.Position = UDim2.new(0, 5, 0, 60)
ChangeModeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
ChangeModeBtn.BorderSizePixel = 0
ChangeModeBtn.Text = "CHANGE MODE"
ChangeModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ChangeModeBtn.TextSize = 11
ChangeModeBtn.Font = Enum.Font.GothamBold
ChangeModeBtn.Parent = ModeBox

local ChangeModeCorner = Instance.new("UICorner")
ChangeModeCorner.CornerRadius = UDim.new(0, 6)
ChangeModeCorner.Parent = ChangeModeBtn

ChangeModeBtn.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex + 1
    if currentModeIndex > #modes then currentModeIndex = 1 end
    
    BypassMode = modes[currentModeIndex]
    
    local modeTexts = {
        Smart = "Smart (Auto)",
        Instant = "Instant (Fast)",
        Smooth = "Smooth (Balance)",
        Safe = "Safe (Slow)",
        Tween = "Tween (Visual)"
    }
    
    ModeDisplay.Text = modeTexts[BypassMode]
    ShowNotification("Mode: " .. BypassMode, Color3.fromRGB(100, 150, 255))
end)

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
    DisableNoClip() -- Disable noclip sebelum close
    ScreenGui:Destroy()
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
end)

-- Notification Function
function ShowNotification(text, color)
    color = color or Color3.fromRGB(0, 155, 0)
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 250, 0, 50)
    NotifFrame.Position = UDim2.new(0.5, -125, 0, -60)
    NotifFrame.BackgroundColor3 = color
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 10)
    NotifCorner.Parent = NotifFrame
    
    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, 0, 1, 0)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = text
    NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifText.TextSize = 13
    NotifText.Font = Enum.Font.GothamBold
    NotifText.Parent = NotifFrame
    
    NotifFrame:TweenPosition(UDim2.new(0.5, -125, 0, 10), "Out", "Quad", 0.3, true)
    
    spawn(function()
        wait(2.5)
        NotifFrame:TweenPosition(UDim2.new(0.5, -125, 0, -60), "In", "Quad", 0.3, true)
        wait(0.3)
        NotifFrame:Destroy()
    end)
end

-- Update position display
spawn(function()
    while wait(0.5) do
        if SavedPosition then
            PosText.Text = string.format("X: %.1f\nY: %.1f\nZ: %.1f\n\nDistance: %.1f", 
                SavedPosition.X, SavedPosition.Y, SavedPosition.Z,
                HumanoidRootPart and (SavedPosition - HumanoidRootPart.Position).Magnitude or 0)
        end
        
        if IsTeleporting then
            StatusText.Text = "Status: Teleporting..."
            StatusText.TextColor3 = Color3.fromRGB(255, 140, 0)
        else
            StatusText.Text = "Status: Ready"
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
        end
    end
end)

-- Auto-detect anti-cheat on load
DetectAntiCheat()

-- Initial notification
spawn(function()
    wait(0.5)
    ShowNotification("Ultimate TP Loaded!", Color3.fromRGB(0, 255, 0))
    wait(2)
    ShowNotification("NoClip: Active!", Color3.fromRGB(100, 150, 255))
end)

-- Cleanup on character death
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 10)
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    DisableNoClip()
    IsTeleporting = false
end)

print("🚀 Ultimate TP Script Loaded - NoClip Enabled!")
