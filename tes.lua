-- ULTIMATE Anti-Rollback Teleporter v2.0
-- Advanced bypass untuk anti-cheat yang paksa balik ke posisi awal

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
local AntiRollbackConnection = nil
local PositionLockConnection = nil

-- ==================== ADVANCED ANTI-ROLLBACK SYSTEM ====================

-- NOCLIP System
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
    
    pcall(function()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end)
end

-- POSITION LOCK - Kunci posisi supaya gak balik (PALING PENTING!)
local function LockPosition(targetPos)
    -- Disconnect old lock
    if PositionLockConnection then
        PositionLockConnection:Disconnect()
        PositionLockConnection = nil
    end
    
    -- Lock position dengan RunService (update setiap frame!)
    PositionLockConnection = RunService.Heartbeat:Connect(function()
        if not HumanoidRootPart or not HumanoidRootPart.Parent then
            if PositionLockConnection then
                PositionLockConnection:Disconnect()
                PositionLockConnection = nil
            end
            return
        end
        
        -- Cek jarak dari target, kalau kejauhan berarti kena rollback
        local currentDist = (HumanoidRootPart.Position - targetPos).Magnitude
        
        if currentDist > 5 then
            -- Paksa balik ke posisi target (melawan rollback!)
            pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(targetPos)
                HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end)
end

local function UnlockPosition()
    if PositionLockConnection then
        PositionLockConnection:Disconnect()
        PositionLockConnection = nil
    end
end

-- ANTI-ROLLBACK: Anchor Method (Metode paling kuat!)
local function AntiRollbackAnchor(targetPos, duration)
    duration = duration or 2.0
    
    pcall(function()
        -- Step 1: Teleport ke posisi
        HumanoidRootPart.CFrame = CFrame.new(targetPos)
        
        -- Step 2: ANCHOR character (freeze posisi!)
        HumanoidRootPart.Anchored = true
        
        -- Step 3: Set humanoid state
        if Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
        
        -- Step 4: Tunggu beberapa saat dengan anchor
        wait(duration)
        
        -- Step 5: Unanchor perlahan
        HumanoidRootPart.Anchored = false
        
        -- Step 6: Reset state
        if Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
        
        -- Step 7: Clear velocity
        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end)
end

-- NETWORK OWNERSHIP: Claim ownership
local function ForceNetworkOwnership()
    pcall(function()
        if HumanoidRootPart:CanSetNetworkOwnership() then
            HumanoidRootPart:SetNetworkOwner(LocalPlayer)
        end
        
        -- Claim ownership untuk semua body parts
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part:CanSetNetworkOwnership() then
                part:SetNetworkOwner(LocalPlayer)
            end
        end
    end)
end

-- ULTIMATE TELEPORT: Kombinasi semua teknik!
local function UltimateTeleport(targetPos)
    if IsTeleporting then 
        return false, "Already teleporting"
    end
    
    IsTeleporting = true
    
    -- Step 1: Enable NoClip
    EnableNoClip()
    
    -- Step 2: Claim network ownership
    ForceNetworkOwnership()
    
    -- Step 3: Remove body movers
    pcall(function()
        for _, v in pairs(HumanoidRootPart:GetChildren()) do
            if v:IsA("BodyMover") then
                v:Destroy()
            end
        end
    end)
    
    -- Step 4: Multiple teleport attempts dengan delay
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    
    if distance < 200 then
        -- Jarak dekat: Instant + Anchor
        for i = 1, 3 do
            pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end)
            wait(0.05)
        end
        
        -- Anchor untuk prevent rollback
        AntiRollbackAnchor(targetPos, 1.5)
        
    else
        -- Jarak jauh: Step teleport + Position lock
        local steps = math.ceil(distance / 50)
        local direction = (targetPos - HumanoidRootPart.Position).Unit
        
        for i = 1, steps do
            if not HumanoidRootPart or not HumanoidRootPart.Parent then break end
            
            local stepDist = math.min(50, distance - (i-1) * 50)
            local newPos = HumanoidRootPart.Position + (direction * stepDist)
            
            -- Triple teleport untuk setiap step
            for j = 1, 2 do
                pcall(function()
                    HumanoidRootPart.CFrame = CFrame.new(newPos)
                end)
                wait(0.03)
            end
            
            wait(0.05)
        end
        
        -- Final teleport + Anchor
        for i = 1, 3 do
            pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end)
            wait(0.05)
        end
        
        AntiRollbackAnchor(targetPos, 2.0)
    end
    
    -- Step 5: Position Lock (KUNCI POSISI!)
    LockPosition(targetPos)
    
    -- Step 6: Hold position dengan continuous teleport
    spawn(function()
        for i = 1, 20 do
            wait(0.1)
            local currentDist = (HumanoidRootPart.Position - targetPos).Magnitude
            if currentDist > 3 then
                pcall(function()
                    HumanoidRootPart.CFrame = CFrame.new(targetPos)
                    HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                end)
            end
        end
        
        -- Unlock after 2 seconds
        wait(0.5)
        UnlockPosition()
        DisableNoClip()
    end)
    
    wait(0.3)
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
MainFrame.Size = UDim2.new(0, 200, 0, 350)
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

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "ANTI-ROLLBACK TP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    Status.Size = UDim2.new(0, 55, 1, 0)
    Status.Position = UDim2.new(1, -60, 0, 0)
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
        status.Text = "SAVED"
        
        ShowNotification("Position Saved!", Color3.fromRGB(0, 255, 0))
        
        wait(1.5)
        btn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        status.Text = ""
    end
)

-- TELEPORT Button  
CreateButton("TpPos", "TELEPORT TO POS", UDim2.new(0, 0, 0, 55),
    Color3.fromRGB(255, 140, 0),
    function(btn, status)
        if not SavedPosition then
            ShowNotification("No position saved!", Color3.fromRGB(255, 50, 50))
            return
        end
        
        if IsTeleporting then
            ShowNotification("Wait...", Color3.fromRGB(255, 100, 0))
            return
        end
        
        status.Text = "TP..."
        ShowNotification("Teleporting...", Color3.fromRGB(255, 140, 0))
        
        spawn(function()
            local success, msg = UltimateTeleport(SavedPosition)
            
            if success then
                ShowNotification("TP Success! Locked 2s", Color3.fromRGB(0, 255, 0))
                status.Text = "DONE"
            else
                ShowNotification("TP Failed: " .. msg, Color3.fromRGB(255, 50, 50))
                status.Text = "FAIL"
            end
            
            wait(2)
            status.Text = ""
        end)
    end
)

-- Info Panel
local InfoBox = Instance.new("Frame")
InfoBox.Size = UDim2.new(1, 0, 0, 120)
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
InfoTitle.Text = "SAVED POSITION:"
InfoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoTitle.TextSize = 11
InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
InfoTitle.Parent = InfoBox

local PosText = Instance.new("TextLabel")
PosText.Size = UDim2.new(1, -10, 0, 70)
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
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 5, 0, 95)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = InfoBox

-- Tips Box
local TipsBox = Instance.new("Frame")
TipsBox.Size = UDim2.new(1, 0, 0, 50)
TipsBox.Position = UDim2.new(0, 0, 0, 240)
TipsBox.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
TipsBox.BackgroundTransparency = 0.3
TipsBox.BorderSizePixel = 0
TipsBox.Parent = Container

local TipsCorner = Instance.new("UICorner")
TipsCorner.CornerRadius = UDim.new(0, 8)
TipsCorner.Parent = TipsBox

local TipsText = Instance.new("TextLabel")
TipsText.Size = UDim2.new(1, -10, 1, -10)
TipsText.Position = UDim2.new(0, 5, 0, 5)
TipsText.BackgroundTransparency = 1
TipsText.Text = "💡 Position locked 2 sec\nafter teleport to prevent\nrollback!"
TipsText.TextColor3 = Color3.fromRGB(255, 255, 255)
TipsText.TextSize = 9
TipsText.Font = Enum.Font.Gotham
TipsText.TextWrapped = true
TipsText.TextYAlignment = Enum.TextYAlignment.Top
TipsText.TextXAlignment = Enum.TextXAlignment.Left
TipsText.Parent = TipsBox

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

-- Notification System
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

-- Update display
spawn(function()
    while wait(0.5) do
        if SavedPosition and HumanoidRootPart then
            local dist = (SavedPosition - HumanoidRootPart.Position).Magnitude
            PosText.Text = string.format("X: %.1f\nY: %.1f\nZ: %.1f\n\nDistance: %.1f studs", 
                SavedPosition.X, SavedPosition.Y, SavedPosition.Z, dist)
        end
        
        if IsTeleporting then
            StatusLabel.Text = "Status: Teleporting..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
        elseif PositionLockConnection then
            StatusLabel.Text = "Status: Position Locked"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            StatusLabel.Text = "Status: Ready"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        end
    end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 10)
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    UnlockPosition()
    DisableNoClip()
    IsTeleporting = false
end)

-- Initial load notification
spawn(function()
    wait(0.5)
    ShowNotification("Anti-Rollback TP Loaded!", Color3.fromRGB(0, 255, 0))
end)

print("🚀 Anti-Rollback Teleporter v2.0 Loaded!")
