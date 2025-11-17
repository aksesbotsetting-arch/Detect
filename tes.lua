local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

if LocalPlayer.PlayerGui:FindFirstChild("CustomGUI") then
    LocalPlayer.PlayerGui:FindFirstChild("CustomGUI"):Destroy()
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
local Humanoid = Character:WaitForChild("Humanoid", 10)

if not HumanoidRootPart or not Humanoid then
    warn("Failed to load character")
    return
end

-- Variables
local SavedPositions = {}
local MAX_SAVES = 20
local IsTeleporting = false
local NoClipConnection = nil
local PositionLockConnection = nil
local PlayerIsMoving = false
local SAVE_FILE_NAME = "StealthTP_Saves_v6"

-- Forward declarations
local ShowNotification
local RefreshTeleportList
local SaveToFile
local LoadFromFile

local function EnableNoClip()
    if NoClipConnection then return end
    NoClipConnection = RunService.Stepped:Connect(function()
        pcall(function()
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end)
end

local function DisableNoClip()
    if NoClipConnection then NoClipConnection:Disconnect() NoClipConnection = nil end
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

local function SmartPositionLock(targetPos, duration)
    if PositionLockConnection then PositionLockConnection:Disconnect() end
    
    local startTime = tick()
    local lockActive = true
    
    PositionLockConnection = RunService.Heartbeat:Connect(function()
        if not HumanoidRootPart or not HumanoidRootPart.Parent then
            if PositionLockConnection then PositionLockConnection:Disconnect() PositionLockConnection = nil end
            return
        end
        
        if tick() - startTime > duration then
            lockActive = false
            if PositionLockConnection then PositionLockConnection:Disconnect() PositionLockConnection = nil end
            return
        end
        
        if Humanoid then
            local moveVector = Humanoid.MoveVector
            if moveVector.Magnitude > 0.1 then
                PlayerIsMoving = true
                lockActive = false
                if PositionLockConnection then PositionLockConnection:Disconnect() PositionLockConnection = nil end
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
    if PositionLockConnection then PositionLockConnection:Disconnect() PositionLockConnection = nil end
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
    if IsTeleporting then return false, "Already teleporting" end
    
    IsTeleporting = true
    PlayerIsMoving = false
    
    EnableNoClip()
    ShowNotification("🔓 NoClip: ON", Color3.fromRGB(100, 150, 255))
    
    ClaimNetworkOwnership()
    DestroyConstraints()
    wait(0.1)
    
    local distance = (targetPos - HumanoidRootPart.Position).Magnitude
    
    if distance < 100 then
        for i = 1, 3 do
            pcall(function() HumanoidRootPart.CFrame = CFrame.new(targetPos) end)
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
            pcall(function() HumanoidRootPart.CFrame = CFrame.new(newPos) end)
            wait(0.04)
        end
        AnchorTeleport(targetPos, 1.0)
    else
        HumanoidStateTrick(targetPos)
        AnchorTeleport(targetPos, 1.2)
    end
    
    wait(0.2)
    DisableNoClip()
    ShowNotification("🔒 NoClip: OFF", Color3.fromRGB(255, 140, 0))
    wait(0.3)
    SmartPositionLock(targetPos, 5.0)
    
    spawn(function()
        for i = 1, 50 do
            wait(0.1)
            if PlayerIsMoving then break end
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
        if not PlayerIsMoving then UnlockPosition() end
    end)
    
    wait(0.5)
    IsTeleporting = false
    return true, "Success"
end

function SaveToFile()
    local success, result = pcall(function()
        local data = {}
        for i, pos in ipairs(SavedPositions) do
            table.insert(data, {X = pos.X, Y = pos.Y, Z = pos.Z})
        end
        local encoded = HttpService:JSONEncode(data)
        writefile(SAVE_FILE_NAME .. ".json", encoded)
        return true
    end)
    
    if success and result then
        ShowNotification("💾 Saved " .. #SavedPositions .. " positions!", Color3.fromRGB(0, 255, 0))
        return true
    else
        ShowNotification("❌ Save failed!", Color3.fromRGB(255, 50, 50))
        return false
    end
end

function LoadFromFile()
    local success, result = pcall(function()
        if not isfile(SAVE_FILE_NAME .. ".json") then
            return nil
        end
        local content = readfile(SAVE_FILE_NAME .. ".json")
        local data = HttpService:JSONDecode(content)
        return data
    end)
    
    if success and result then
        SavedPositions = {}
        for i, pos in ipairs(result) do
            table.insert(SavedPositions, Vector3.new(pos.X, pos.Y, pos.Z))
        end
        RefreshTeleportList()
        ShowNotification("📂 Loaded " .. #SavedPositions .. " positions!", Color3.fromRGB(0, 255, 0))
        return true
    elseif not success then
        ShowNotification("❌ Load failed!", Color3.fromRGB(255, 50, 50))
        return false
    else
        ShowNotification("📂 No save file found", Color3.fromRGB(255, 200, 0))
        return false
    end
end

local function ParseCoordinates(input)
    input = input:gsub("%s+", "")
    
    local x, y, z
    
    if input:find(",") then
        x, y, z = input:match("^([%-]?%d+%.?%d*),([%-]?%d+%.?%d*),([%-]?%d+%.?%d*)$")
    elseif input:find(";") then
        x, y, z = input:match("^([%-]?%d+%.?%d*);([%-]?%d+%.?%d*);([%-]?%d+%.?%d*)$")
    elseif input:find(":") then
        x, y, z = input:match("^([%-]?%d+%.?%d*):([%-]?%d+%.?%d*):([%-]?%d+%.?%d*)$")
    elseif input:find("%s") then
        x, y, z = input:match("^([%-]?%d+%.?%d*)%s+([%-]?%d+%.?%d*)%s+([%-]?%d+%.?%d*)$")
    end
    
    if x and y and z then
        x, y, z = tonumber(x), tonumber(y), tonumber(z)
        if x and y and z then
            return Vector3.new(x, y, z)
        end
    end
    
    return nil
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

-- Main Frame (Lebih kompak)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 420)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🥷 STEALTH TP v6.0"
Title.TextColor3 = Color3.fromRGB(100, 200, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Minimize Icon
local MinimizeIcon = Instance.new("TextButton")
MinimizeIcon.Name = "MinimizeIcon"
MinimizeIcon.Size = UDim2.new(0, 55, 0, 55)
MinimizeIcon.Position = UDim2.new(0, 10, 0.5, -27)
MinimizeIcon.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
MinimizeIcon.BorderSizePixel = 0
MinimizeIcon.Active = true
MinimizeIcon.Draggable = true
MinimizeIcon.Visible = false
MinimizeIcon.Text = "🥷"
MinimizeIcon.TextSize = 28
MinimizeIcon.Font = Enum.Font.GothamBold
MinimizeIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 12)
IconCorner.Parent = MinimizeIcon

MinimizeIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizeIcon.Visible = false
end)

MinimizeIcon.MouseEnter:Connect(function()
    MinimizeIcon.BackgroundColor3 = Color3.fromRGB(130, 180, 255)
    MinimizeIcon.Size = UDim2.new(0, 60, 0, 60)
end)

MinimizeIcon.MouseLeave:Connect(function()
    MinimizeIcon.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    MinimizeIcon.Size = UDim2.new(0, 55, 0, 55)
end)

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -33, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "—"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinimizeIcon.Visible = true
    ShowNotification("🥷 Minimized - Features active!", Color3.fromRGB(100, 150, 255))
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
end)

local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, -20, 0, 90)
ButtonContainer.Position = UDim2.new(0, 10, 0, 35)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

-- Set Position Button
local SetPosButton = Instance.new("TextButton")
SetPosButton.Size = UDim2.new(0.48, 0, 0, 38)
SetPosButton.Position = UDim2.new(0, 0, 0, 0)
SetPosButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
SetPosButton.BorderSizePixel = 0
SetPosButton.Text = "📍 SET POS"
SetPosButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SetPosButton.TextSize = 12
SetPosButton.Font = Enum.Font.GothamBold
SetPosButton.Parent = ButtonContainer

local SetPosCorner = Instance.new("UICorner")
SetPosCorner.CornerRadius = UDim.new(0, 8)
SetPosCorner.Parent = SetPosButton

-- Save Button
local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0.48, 0, 0, 38)
SaveButton.Position = UDim2.new(0.52, 0, 0, 0)
SaveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
SaveButton.BorderSizePixel = 0
SaveButton.Text = "💾 SAVE"
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.TextSize = 12
SaveButton.Font = Enum.Font.GothamBold
SaveButton.Parent = ButtonContainer

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 8)
SaveCorner.Parent = SaveButton

-- Load Button
local LoadButton = Instance.new("TextButton")
LoadButton.Size = UDim2.new(0.48, 0, 0, 38)
LoadButton.Position = UDim2.new(0, 0, 0, 47)
LoadButton.BackgroundColor3 = Color3.fromRGB(0, 100, 139)
LoadButton.BorderSizePixel = 0
LoadButton.Text = "📂 LOAD"
LoadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadButton.TextSize = 12
LoadButton.Font = Enum.Font.GothamBold
LoadButton.Parent = ButtonContainer

local LoadCorner = Instance.new("UICorner")
LoadCorner.CornerRadius = UDim.new(0, 8)
LoadCorner.Parent = LoadButton

-- Counter Label
local SaveCounter = Instance.new("TextLabel")
SaveCounter.Size = UDim2.new(0.48, 0, 0, 38)
SaveCounter.Position = UDim2.new(0.52, 0, 0, 47)
SaveCounter.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SaveCounter.BackgroundTransparency = 0.3
SaveCounter.BorderSizePixel = 0
SaveCounter.Text = "0/" .. MAX_SAVES
SaveCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveCounter.TextSize = 14
SaveCounter.Font = Enum.Font.GothamBold
SaveCounter.Parent = ButtonContainer

local CounterCorner = Instance.new("UICorner")
CounterCorner.CornerRadius = UDim.new(0, 8)
CounterCorner.Parent = SaveCounter

local CoordFrame = Instance.new("Frame")
CoordFrame.Size = UDim2.new(1, -20, 0, 45)
CoordFrame.Position = UDim2.new(0, 10, 0, 130)
CoordFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CoordFrame.BackgroundTransparency = 0.3
CoordFrame.BorderSizePixel = 0
CoordFrame.Parent = MainFrame

local CoordCorner = Instance.new("UICorner")
CoordCorner.CornerRadius = UDim.new(0, 8)
CoordCorner.Parent = CoordFrame

local CoordLabel = Instance.new("TextLabel")
CoordLabel.Size = UDim2.new(1, -10, 0, 15)
CoordLabel.Position = UDim2.new(0, 5, 0, 2)
CoordLabel.BackgroundTransparency = 1
CoordLabel.Text = "📝 Manual Coordinates:"
CoordLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CoordLabel.TextSize = 9
CoordLabel.Font = Enum.Font.GothamBold
CoordLabel.TextXAlignment = Enum.TextXAlignment.Left
CoordLabel.Parent = CoordFrame

local CoordInput = Instance.new("TextBox")
CoordInput.Size = UDim2.new(1, -90, 0, 22)
CoordInput.Position = UDim2.new(0, 5, 0, 20)
CoordInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CoordInput.BorderSizePixel = 0
CoordInput.PlaceholderText = "X,Y,Z or X;Y;Z"
CoordInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
CoordInput.Text = ""
CoordInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CoordInput.TextSize = 11
CoordInput.Font = Enum.Font.Gotham
CoordInput.ClearTextOnFocus = false
CoordInput.Parent = CoordFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = CoordInput

local AddCoordButton = Instance.new("TextButton")
AddCoordButton.Size = UDim2.new(0, 80, 0, 22)
AddCoordButton.Position = UDim2.new(1, -85, 0, 20)
AddCoordButton.BackgroundColor3 = Color3.fromRGB(0, 139, 0)
AddCoordButton.BorderSizePixel = 0
AddCoordButton.Text = "➕ ADD"
AddCoordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AddCoordButton.TextSize = 11
AddCoordButton.Font = Enum.Font.GothamBold
AddCoordButton.Parent = CoordFrame

local AddCorner = Instance.new("UICorner")
AddCorner.CornerRadius = UDim.new(0, 6)
AddCorner.Parent = AddCoordButton

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "TeleportList"
ScrollFrame.Size = UDim2.new(1, -20, 1, -265)
ScrollFrame.Position = UDim2.new(0, 10, 0, 180)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ScrollFrame.BackgroundTransparency = 0.4
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = ScrollFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = ScrollFrame

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
end)

local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.Name = "EmptyLabel"
EmptyLabel.Size = UDim2.new(1, -20, 1, -20)
EmptyLabel.Position = UDim2.new(0, 10, 0, 10)
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "No saved positions\n\nUse SET POS or\nManual Coordinates!"
EmptyLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
EmptyLabel.TextSize = 11
EmptyLabel.Font = Enum.Font.GothamBold
EmptyLabel.TextWrapped = true
EmptyLabel.Parent = ScrollFrame

local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(1, -20, 0, 50)
InfoPanel.Position = UDim2.new(0, 10, 1, -60)
InfoPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InfoPanel.BackgroundTransparency = 0.3
InfoPanel.BorderSizePixel = 0
InfoPanel.Parent = MainFrame

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoPanel

local NoClipText = Instance.new("TextLabel")
NoClipText.Size = UDim2.new(1, -10, 0, 18)
NoClipText.Position = UDim2.new(0, 5, 0, 4)
NoClipText.BackgroundTransparency = 1
NoClipText.Text = "🔒 NoClip: OFF"
NoClipText.TextColor3 = Color3.fromRGB(255, 255, 255)
NoClipText.TextSize = 10
NoClipText.Font = Enum.Font.GothamBold
NoClipText.TextXAlignment = Enum.TextXAlignment.Left
NoClipText.Parent = InfoPanel

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 0, 16)
StatusText.Position = UDim2.new(0, 5, 0, 20)
StatusText.BackgroundTransparency = 1
StatusText.Text = "✓ Status: Ready"
StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusText.TextSize = 9
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = InfoPanel

local VersionText = Instance.new("TextLabel")
VersionText.Size = UDim2.new(1, -10, 0, 12)
VersionText.Position = UDim2.new(0, 5, 0, 36)
VersionText.BackgroundTransparency = 1
VersionText.Text = "v6.0 | Manual Coords + Save/Load"
VersionText.TextColor3 = Color3.fromRGB(100, 150, 255)
VersionText.TextSize = 7
VersionText.Font = Enum.Font.GothamBold
VersionText.TextXAlignment = Enum.TextXAlignment.Left
VersionText.Parent = InfoPanel

local function ShowDeleteConfirm(index, position, callback)
    local ConfirmFrame = Instance.new("Frame")
    ConfirmFrame.Name = "ConfirmDelete"
    ConfirmFrame.Size = UDim2.new(0, 240, 0, 120)
    ConfirmFrame.Position = UDim2.new(0.5, -120, 0.5, -60)
    ConfirmFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ConfirmFrame.BorderSizePixel = 0
    ConfirmFrame.ZIndex = 10
    ConfirmFrame.Parent = ScreenGui
    
    local ConfirmCorner = Instance.new("UICorner")
    ConfirmCorner.CornerRadius = UDim.new(0, 10)
    ConfirmCorner.Parent = ConfirmFrame
    
    local ConfirmTitle = Instance.new("TextLabel")
    ConfirmTitle.Size = UDim2.new(1, -20, 0, 25)
    ConfirmTitle.Position = UDim2.new(0, 10, 0, 10)
    ConfirmTitle.BackgroundTransparency = 1
    ConfirmTitle.Text = "⚠️ Confirm Delete"
    ConfirmTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
    ConfirmTitle.TextSize = 14
    ConfirmTitle.Font = Enum.Font.GothamBold
    ConfirmTitle.Parent = ConfirmFrame
    
    local ConfirmText = Instance.new("TextLabel")
    ConfirmText.Size = UDim2.new(1, -20, 0, 35)
    ConfirmText.Position = UDim2.new(0, 10, 0, 35)
    ConfirmText.BackgroundTransparency = 1
    ConfirmText.Text = "Delete TP SAVE " .. index .. "?\n" .. string.format("X:%.0f Y:%.0f Z:%.0f", position.X, position.Y, position.Z)
    ConfirmText.TextColor3 = Color3.fromRGB(200, 200, 200)
    ConfirmText.TextSize = 10
    ConfirmText.Font = Enum.Font.Gotham
    ConfirmText.TextWrapped = true
    ConfirmText.Parent = ConfirmFrame
    
    local YesButton = Instance.new("TextButton")
    YesButton.Size = UDim2.new(0.45, 0, 0, 35)
    YesButton.Position = UDim2.new(0.05, 0, 0, 75)
    YesButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    YesButton.BorderSizePixel = 0
    YesButton.Text = "✓ YES"
    YesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    YesButton.TextSize = 12
    YesButton.Font = Enum.Font.GothamBold
    YesButton.Parent = ConfirmFrame
    
    local YesCorner = Instance.new("UICorner")
    YesCorner.CornerRadius = UDim.new(0, 8)
    YesCorner.Parent = YesButton
    
    local NoButton = Instance.new("TextButton")
    NoButton.Size = UDim2.new(0.45, 0, 0, 35)
    NoButton.Position = UDim2.new(0.5, 0, 0, 75)
    NoButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    NoButton.BorderSizePixel = 0
    NoButton.Text = "✗ NO"
    NoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoButton.TextSize = 12
    NoButton.Font = Enum.Font.GothamBold
    NoButton.Parent = ConfirmFrame
    
    local NoCorner = Instance.new("UICorner")
    NoCorner.CornerRadius = UDim.new(0, 8)
    NoCorner.Parent = NoButton
    
    YesButton.MouseButton1Click:Connect(function()
        callback(true)
        ConfirmFrame:Destroy()
    end)
    
    NoButton.MouseButton1Click:Connect(function()
        callback(false)
        ConfirmFrame:Destroy()
    end)
    
    YesButton.MouseEnter:Connect(function()
        YesButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    end)
    
    YesButton.MouseLeave:Connect(function()
        YesButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    end)
    
    NoButton.MouseEnter:Connect(function()
        NoButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end)
    
    NoButton.MouseLeave:Connect(function()
        NoButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
end

local function CreateTeleportButton(index, position)
    local Button = Instance.new("TextButton")
    Button.Name = "TPSave" .. index
    Button.Size = UDim2.new(1, -8, 0, 45)
    Button.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Text = ""
    Button.Parent = ScrollFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 7)
    BtnCorner.Parent = Button
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -45, 0, 18)
    TitleLabel.Position = UDim2.new(0, 5, 0, 3)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "📌 TP SAVE " .. index
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 11
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Button
    
    local PosLabel = Instance.new("TextLabel")
    PosLabel.Size = UDim2.new(1, -45, 0, 20)
    PosLabel.Position = UDim2.new(0, 5, 0, 22)
    PosLabel.BackgroundTransparency = 1
    PosLabel.Text = string.format("X:%.0f Y:%.0f Z:%.0f", position.X, position.Y, position.Z)
    PosLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    PosLabel.TextSize = 8
    PosLabel.Font = Enum.Font.Gotham
    PosLabel.TextXAlignment = Enum.TextXAlignment.Left
    PosLabel.Parent = Button
    
    local DeleteBtn = Instance.new("TextButton")
    DeleteBtn.Size = UDim2.new(0, 32, 0, 32)
    DeleteBtn.Position = UDim2.new(1, -37, 0, 6.5)
    DeleteBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    DeleteBtn.BorderSizePixel = 0
    DeleteBtn.Text = "🗑️"
    DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DeleteBtn.TextSize = 14
    DeleteBtn.Font = Enum.Font.GothamBold
    DeleteBtn.Parent = Button
    
    local DelCorner = Instance.new("UICorner")
    DelCorner.CornerRadius = UDim.new(0, 7)
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
        ShowDeleteConfirm(index, position, function(confirmed)
            if confirmed then
                table.remove(SavedPositions, index)
                RefreshTeleportList()
                ShowNotification("🗑️ Save " .. index .. " deleted!", Color3.fromRGB(255, 100, 0))
            else
                ShowNotification("❌ Delete cancelled", Color3.fromRGB(200, 200, 200))
            end
        end)
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

SaveButton.MouseButton1Click:Connect(function()
    if #SavedPositions == 0 then
        ShowNotification("❌ No positions to save!", Color3.fromRGB(255, 50, 50))
        return
    end
    
    SaveButton.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
    SaveToFile()
    wait(1)
    SaveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
end)

SaveButton.MouseEnter:Connect(function()
    SaveButton.BackgroundColor3 = Color3.fromRGB(0, 130, 0)
end)

SaveButton.MouseLeave:Connect(function()
    SaveButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
end)

LoadButton.MouseButton1Click:Connect(function()
    LoadButton.BackgroundColor3 = Color3.fromRGB(0, 130, 180)
    LoadFromFile()
    wait(1)
    LoadButton.BackgroundColor3 = Color3.fromRGB(0, 100, 139)
end)

LoadButton.MouseEnter:Connect(function()
    LoadButton.BackgroundColor3 = Color3.fromRGB(0, 130, 180)
end)

LoadButton.MouseLeave:Connect(function()
    LoadButton.BackgroundColor3 = Color3.fromRGB(0, 100, 139)
end)

AddCoordButton.MouseButton1Click:Connect(function()
    local input = CoordInput.Text
    
    if input == "" then
        ShowNotification("❌ Please enter coordinates!", Color3.fromRGB(255, 50, 50))
        return
    end
    
    if #SavedPositions >= MAX_SAVES then
        ShowNotification("❌ Maximum " .. MAX_SAVES .. " saves reached!", Color3.fromRGB(255, 50, 50))
        return
    end
    
    local pos = ParseCoordinates(input)
    
    if pos then
        table.insert(SavedPositions, pos)
        RefreshTeleportList()
        
        AddCoordButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        ShowNotification("✓ Position " .. #SavedPositions .. " added!", Color3.fromRGB(0, 255, 0))
        CoordInput.Text = ""
        
        wait(1)
        AddCoordButton.BackgroundColor3 = Color3.fromRGB(0, 139, 0)
    else
        ShowNotification("❌ Invalid format!\nUse: X,Y,Z or X;Y;Z\nExample: 100,50,200", Color3.fromRGB(255, 50, 50))
    end
end)

AddCoordButton.MouseEnter:Connect(function()
    AddCoordButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
end)

AddCoordButton.MouseLeave:Connect(function()
    AddCoordButton.BackgroundColor3 = Color3.fromRGB(0, 139, 0)
end)

CoordInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        AddCoordButton.MouseButton1Click:Fire()
    end
end)

function ShowNotification(text, color)
    color = color or Color3.fromRGB(0, 155, 0)
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 260, 0, 50)
    NotifFrame.Position = UDim2.new(0.5, -130, 0, -60)
    NotifFrame.BackgroundColor3 = color
    NotifFrame.BorderSizePixel = 0
    NotifFrame.ZIndex = 5
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
    NotifText.TextSize = 11
    NotifText.Font = Enum.Font.GothamBold
    NotifText.TextWrapped = true
    NotifText.Parent = NotifFrame
    
    NotifFrame:TweenPosition(UDim2.new(0.5, -130, 0, 10), "Out", "Quad", 0.3, true)
    
    spawn(function()
        wait(2.5)
        NotifFrame:TweenPosition(UDim2.new(0.5, -130, 0, -60), "In", "Quad", 0.3, true)
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
            StatusText.Text = "🏃 Status: Moving"
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
    ShowNotification("🥷 STEALTH TP v6.0 LOADED!\n📍 Manual Coords + Save/Load", Color3.fromRGB(100, 150, 255))
    
    -- Auto-load jika ada file save
    if isfile and isfile(SAVE_FILE_NAME .. ".json") then
        wait(1)
        ShowNotification("📂 Auto-loading saved positions...", Color3.fromRGB(0, 150, 255))
        wait(0.5)
        LoadFromFile()
    end
end)

print("============================================")
print("🥷 STEALTH TELEPORT v6.0 LOADED!")
print("============================================")
print("✓ Manual Coordinates Input")
print("✓ Save/Load System (Persistent)")
print("✓ Delete Confirmation")
print("✓ Up to 20 saves")
print("✓ Compact UI")
print("============================================")
print("📝 HOW TO USE:")
print("1. SET POS - Save current position")
print("2. Manual Input - Type X,Y,Z and click ADD")
print("3. SAVE - Save all positions to file")
print("4. LOAD - Load positions from file")
print("5. Click TP button to teleport")
print("6. Click 🗑️ to delete (with confirmation)")
print("============================================")
print("📌 COORDINATE FORMATS:")
print("   • X,Y,Z  (comma)")
print("   • X;Y;Z  (semicolon)")
print("   • X:Y:Z  (colon)")
print("   Example: 100,50,200")
print("============================================")
