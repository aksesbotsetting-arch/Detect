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
local SavedPositions = {} -- NEW: Array untuk menyimpan multiple positions
local MAX_SAVES = 20 -- Maksimal 20 save slots
local IsTeleporting = false
local NoClipConnection = nil
local PositionLockConnection = nil

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
        HumanoidRootPart.CanCollide = false
    end)
end

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
        
        if tick() - startTime > duration then
            lockActive = false
            if PositionLockConnection then
                PositionLockConnection:Disconnect()
                PositionLockConnection = nil
            end
            return
        end
        
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

local function AnchorTeleport(targetPos, holdTime)
    pcall(function()
        for i = 1, 3 do
            HumanoidRootPart.CFrame = CFrame.new(targetPos)
            wait(0.03)
        end
        
        HumanoidRootPart.Anchored = true
        HumanoidRootPart.CFrame = CFrame.new(targetPos)
        
        wait(holdTime)
        
        HumanoidRootPart.Anchored = false
        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end)
end

local function HumanoidStateTrick(targetPos)
    pcall(function()
        if not Humanoid then return end
        
        local originalState = Humanoid:GetState()
        Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        wait(0.1)
        HumanoidRootPart.CFrame = CFrame.new(targetPos)
        wait(0.2)
        Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    end)
end

local function STEALTH_TELEPORT(targetPos)
    if IsTeleporting then
        return false, "Already teleporting"
    end
    
    IsTeleporting = true
    PlayerIsMoving = false
    
    EnableNoClip()
    ShowNotification("🔓 NoClip: ON (Traveling...)", Color3.fromRGB(100, 150, 255))
    
    ClaimNetworkOwnership()
    DestroyConstraints()
    wait(0.1)
    
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    
    if distance < 100 then
        for i = 1, 3 do
            pcall(function()
                HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end)
            wait(0.05)
        end
        AnchorTeleport(targetPos, 0.8)
        
    elseif distance < 500 then
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
        AnchorTeleport(targetPos, 1.0)
    else
        HumanoidStateTrick(targetPos)
        AnchorTeleport(targetPos, 1.2)
    end
    
    wait(0.2)
    
    DisableNoClip()
    ShowNotification("🔒 NoClip: OFF (Arrived!)", Color3.fromRGB(255, 140, 0))
    
    wait(0.3)
    
    SmartPositionLock(targetPos, 5.0)
    ShowNotification("🔐 Position Locked 5s", Color3.fromRGB(255, 200, 0))
    
    spawn(function()
        for i = 1, 50 do
            wait(0.1)
            
            if PlayerIsMoving then
                ShowNotification("✓ Unlocked - Move freely!", Color3.fromRGB(0, 255, 0))
                break
            end
            
            if HumanoidRootPart then
                local dist = (HumanoidRootPart.Position - targetPos).Magnitude
                if dist > 5 then
                    pcall(function()
                        HumanoidRootPart.CFrame = CFrame.new(targetPos)
                        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    end)
                end
            end
        end
        
        if not PlayerIsMoving then
            UnlockPosition()
            ShowNotification("✓ Auto-Unlock Complete!", Color3.fromRGB(0, 255, 0))
        end
    end)
    
    wait(0.5)
    IsTeleporting = false
    
    return true, "Success"
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 500)
MainFrame.Position = UDim2.new(0.5, -120, 0.05, 0)
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
Title.Text = "🥷 STEALTH TP v5.0"
Title.TextColor3 = Color3.fromRGB(100, 200, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local MinimizeIcon = Instance.new("ImageButton")
MinimizeIcon.Name = "MinimizeIcon"
MinimizeIcon.Size = UDim2.new(0, 50, 0, 50)
MinimizeIcon.Position = UDim2.new(0, 10, 0, 10)
MinimizeIcon.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
MinimizeIcon.BorderSizePixel = 0
MinimizeIcon.Active = true
MinimizeIcon.Draggable = true
MinimizeIcon.Visible = false
MinimizeIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 10)
IconCorner.Parent = MinimizeIcon

local IconText = Instance.new("TextLabel")
IconText.Size = UDim2.new(1, 0, 1, 0)
IconText.BackgroundTransparency = 1
IconText.Text = "🥷"
IconText.TextColor3 = Color3.fromRGB(255, 255, 255)
IconText.TextSize = 24
IconText.Font = Enum.Font.GothamBold
IconText.Parent = MinimizeIcon

MinimizeIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizeIcon.Visible = false
end)

MinimizeIcon.MouseEnter:Connect(function()
    MinimizeIcon.BackgroundColor3 = Color3.fromRGB(130, 180, 255)
    MinimizeIcon.Size = UDim2.new(0, 55, 0, 55)
end)

MinimizeIcon.MouseLeave:Connect(function()
    MinimizeIcon.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    MinimizeIcon.Size = UDim2.new(0, 50, 0, 50)
end)

local SetPosButton = Instance.new("TextButton")
SetPosButton.Name = "SetPos"
SetPosButton.Size = UDim2.new(1, -20, 0, 45)
SetPosButton.Position = UDim2.new(0, 10, 0, 45)
SetPosButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
SetPosButton.BorderSizePixel = 0
SetPosButton.Text = "📍 SET POSITION"
SetPosButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SetPosButton.TextSize = 14
SetPosButton.Font = Enum.Font.GothamBold
SetPosButton.Parent = MainFrame

local SetPosCorner = Instance.new("UICorner")
SetPosCorner.CornerRadius = UDim.new(0, 8)
SetPosCorner.Parent = SetPosButton

local SaveCounter = Instance.new("TextLabel")
SaveCounter.Size = UDim2.new(0, 70, 1, 0)
SaveCounter.Position = UDim2.new(1, -75, 0, 0)
SaveCounter.BackgroundTransparency = 1
SaveCounter.Text = "0/" .. MAX_SAVES
SaveCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveCounter.TextSize = 11
SaveCounter.Font = Enum.Font.GothamBold
SaveCounter.Parent = SetPosButton

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "TeleportList"
ScrollFrame.Size = UDim2.new(1, -20, 1, -180)
ScrollFrame.Position = UDim2.new(0, 10, 0, 100)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ScrollFrame.BackgroundTransparency = 0.5
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = ScrollFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 5)
ListLayout.Parent = ScrollFrame

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end)

local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.Name = "EmptyLabel"
EmptyLabel.Size = UDim2.new(1, -20, 1, -20)
EmptyLabel.Position = UDim2.new(0, 10, 0, 10)
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "No saved positions yet\n\nClick SET POSITION to start!"
EmptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
EmptyLabel.TextSize = 12
EmptyLabel.Font = Enum.Font.GothamBold
EmptyLabel.TextWrapped = true
EmptyLabel.Parent = ScrollFrame

local function CreateTeleportButton(index, position)
    local Button = Instance.new("TextButton")
    Button.Name = "TPSave" .. index
    Button.Size = UDim2.new(1, -10, 0, 50)
    Button.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Parent = ScrollFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Button
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -50, 0, 20)
    TitleLabel.Position = UDim2.new(0, 5, 0, 5)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "📌 TP SAVE " .. index
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 12
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Button
    
    local PosLabel = Instance.new("TextLabel")
    PosLabel.Size = UDim2.new(1, -50, 0, 25)
    PosLabel.Position = UDim2.new(0, 5, 0, 25)
    PosLabel.BackgroundTransparency = 1
    PosLabel.Text = string.format("X:%.0f Y:%.0f Z:%.0f", position.X, position.Y, position.Z)
    PosLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    PosLabel.TextSize = 9
    PosLabel.Font = Enum.Font.Gotham
    PosLabel.TextXAlignment = Enum.TextXAlignment.Left
    PosLabel.Parent = Button
    
    local DeleteBtn = Instance.new("TextButton")
    DeleteBtn.Size = UDim2.new(0, 35, 0, 35)
    DeleteBtn.Position = UDim2.new(1, -40, 0, 7.5)
    DeleteBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    DeleteBtn.BorderSizePixel = 0
    DeleteBtn.Text = "🗑️"
    DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DeleteBtn.TextSize = 16
    DeleteBtn.Font = Enum.Font.GothamBold
    DeleteBtn.Parent = Button
    
    local DelCorner = Instance.new("UICorner")
    DelCorner.CornerRadius = UDim.new(0, 8)
    DelCorner.Parent = DeleteBtn
    
    Button.MouseButton1Click:Connect(function()
        if IsTeleporting then
            ShowNotification("⏳ Please wait...", Color3.fromRGB(255, 100, 0))
            return
        end
        
        ShowNotification("🥷 Teleporting to Save " .. index .. "...", Color3.fromRGB(100, 150, 255))
        
        spawn(function()
            local success, msg = STEALTH_TELEPORT(position)
            
            if success then
                ShowNotification("✓ Arrived at Save " .. index .. "!", Color3.fromRGB(0, 255, 0))
            else
                ShowNotification("❌ Failed: " .. msg, Color3.fromRGB(255, 50, 50))
            end
        end)
    end)
    
    DeleteBtn.MouseButton1Click:Connect(function()
        table.remove(SavedPositions, index)
        RefreshTeleportList()
        ShowNotification("🗑️ Save " .. index .. " deleted!", Color3.fromRGB(255, 100, 0))
    end)
    
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    end)
    
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    end)
    
    DeleteBtn.MouseEnter:Connect(function()
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    end)
    
    DeleteBtn.MouseLeave:Connect(function()
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    end)
    
    return Button
end

function RefreshTeleportList()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    SaveCounter.Text = #SavedPositions .. "/" .. MAX_SAVES
    
    if #SavedPositions == 0 then
        EmptyLabel.Visible = true
    else
        EmptyLabel.Visible = false
        
        for i, pos in ipairs(SavedPositions) do
            CreateTeleportButton(i, pos)
        end
    end
end

SetPosButton.MouseButton1Click:Connect(function()
    if not HumanoidRootPart then return end
    
    if #SavedPositions >= MAX_SAVES then
        ShowNotification("❌ Maximum " .. MAX_SAVES .. " saves reached!", Color3.fromRGB(255, 50, 50))
        return
    end
    
    local currentPos = HumanoidRootPart.Position
    table.insert(SavedPositions, currentPos)
    
    RefreshTeleportList()
    
    SetPosButton.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
    ShowNotification("📍 Position " .. #SavedPositions .. " saved!", Color3.fromRGB(0, 255, 0))
    
    wait(1)
    SetPosButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
end)

SetPosButton.MouseEnter:Connect(function()
    if #SavedPositions < MAX_SAVES then
        SetPosButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    end
end)

SetPosButton.MouseLeave:Connect(function()
    SetPosButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
end)


local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(1, -20, 0, 70)
InfoPanel.Position = UDim2.new(0, 10, 1, -80)
InfoPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InfoPanel.BackgroundTransparency = 0.5
InfoPanel.BorderSizePixel = 0
InfoPanel.Parent = MainFrame

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoPanel

local NoClipText = Instance.new("TextLabel")
NoClipText.Size = UDim2.new(1, -10, 0, 20)
NoClipText.Position = UDim2.new(0, 5, 0, 5)
NoClipText.BackgroundTransparency = 1
NoClipText.Text = "🔒 NoClip: OFF"
NoClipText.TextColor3 = Color3.fromRGB(255, 255, 255)
NoClipText.TextSize = 11
NoClipText.Font = Enum.Font.GothamBold
NoClipText.TextXAlignment = Enum.TextXAlignment.Left
NoClipText.Parent = InfoPanel

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 0, 20)
StatusText.Position = UDim2.new(0, 5, 0, 25)
StatusText.BackgroundTransparency = 1
StatusText.Text = "✓ Status: Ready"
StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusText.TextSize = 10
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = InfoPanel

local VersionText = Instance.new("TextLabel")
VersionText.Size = UDim2.new(1, -10, 0, 15)
VersionText.Position = UDim2.new(0, 5, 0, 50)
VersionText.BackgroundTransparency = 1
VersionText.Text = "🥷 Multi-Save System | v5.0"
VersionText.TextColor3 = Color3.fromRGB(100, 150, 255)
VersionText.TextSize = 8
VersionText.Font = Enum.Font.GothamBold
VersionText.TextXAlignment = Enum.TextXAlignment.Left
VersionText.Parent = InfoPanel

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
    MainFrame.Visible = false
    MinimizeIcon.Visible = true
    ShowNotification("🥷 Menu minimized - Active features running!", Color3.fromRGB(100, 150, 255))
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
end)

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

spawn(function()
    while wait(0.3) do
        if NoClipConnection then
            NoClipText.Text = "🔓 NoClip: ON"
            NoClipText.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            NoClipText.Text = "🔒 NoClip: OFF"
            NoClipText.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        
        if IsTeleporting then
            StatusText.Text = "⚡ Status: Teleporting..."
            StatusText.TextColor3 = Color3.fromRGB(100, 150, 255)
        elseif PositionLockConnection then
            StatusText.Text = "🔐 Status: Locked (5s)"
            StatusText.TextColor3 = Color3.fromRGB(255, 200, 0)
        elseif PlayerIsMoving then
            StatusText.Text = "🏃 Status: Moving (Unlocked)"
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            StatusText.Text = "✓ Status: Ready"
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 10)
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    UnlockPosition()
    DisableNoClip()
    IsTeleporting = false
    PlayerIsMoving = false
end)

spawn(function()
    wait(0.5)
    ShowNotification("🥷 STEALTH TP v5.0 LOADED!\n📍 Multi-Save System Active!", Color3.fromRGB(100, 150, 255))
end)

print("🥷 STEALTH TELEPORT v5.0 - MULTI SAVE SYSTEM LOADED!")
print("✓ Save up to 20 positions")
print("✓ Scrollable teleport list")
print("✓ Click any save to teleport!")
