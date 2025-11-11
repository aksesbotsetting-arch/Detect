-- HITBOX EXTENDER v2.0 - PREMIUM EDITION
-- By NazamOfficial - Upgraded UI & Fixed Melee Detection

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Delete old GUI if exists
if game.CoreGui:FindFirstChild("HitboxExtenderGUI") then
    game.CoreGui:FindFirstChild("HitboxExtenderGUI"):Destroy()
end

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HitboxExtenderGUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 220, 0, 250)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Accent line (top)
local AccentLine = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.Parent = MainFrame
AccentLine.Size = UDim2.new(1, 0, 0, 3)
AccentLine.Position = UDim2.new(0, 0, 0, 35)
AccentLine.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
AccentLine.BorderSizePixel = 0

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = TitleBar
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ HITBOX EXTENDER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeBtn"
MinimizeButton.Parent = TitleBar
MinimizeButton.Size = UDim2.new(0, 30, 0, 25)
MinimizeButton.Position = UDim2.new(1, -35, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 18
MinimizeButton.Font = Enum.Font.GothamBold

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeButton

-- Container for controls
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Parent = MainFrame
Container.Size = UDim2.new(1, -20, 1, -55)
Container.Position = UDim2.new(0, 10, 0, 45)
Container.BackgroundTransparency = 1

-- Size Label
local SizeLabel = Instance.new("TextLabel")
SizeLabel.Name = "SizeLabel"
SizeLabel.Parent = Container
SizeLabel.Size = UDim2.new(1, 0, 0, 20)
SizeLabel.Position = UDim2.new(0, 0, 0, 10)
SizeLabel.BackgroundTransparency = 1
SizeLabel.Text = "HITBOX SIZE"
SizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeLabel.TextSize = 12
SizeLabel.Font = Enum.Font.GothamBold
SizeLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Size TextBox
local SizeTextBox = Instance.new("TextBox")
SizeTextBox.Name = "SizeBox"
SizeTextBox.Parent = Container
SizeTextBox.Size = UDim2.new(1, 0, 0, 35)
SizeTextBox.Position = UDim2.new(0, 0, 0, 35)
SizeTextBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SizeTextBox.BorderSizePixel = 0
SizeTextBox.Text = "15"
SizeTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SizeTextBox.TextSize = 16
SizeTextBox.Font = Enum.Font.GothamBold
SizeTextBox.PlaceholderText = "Enter size (5-50)"
SizeTextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
SizeTextBox.ClearTextOnFocus = false

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 8)
BoxCorner.Parent = SizeTextBox

-- Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleBtn"
ToggleButton.Parent = Container
ToggleButton.Size = UDim2.new(1, 0, 0, 40)
ToggleButton.Position = UDim2.new(0, 0, 0, 85)
ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "🔴 DISABLED"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.AutoButtonColor = false

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = Container
StatusLabel.Size = UDim2.new(1, 0, 0, 50)
StatusLabel.Position = UDim2.new(0, 0, 0, 135)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
StatusLabel.BorderSizePixel = 0
StatusLabel.Text = "STATUS: INACTIVE\nTargets: 0\nSize: 15"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusLabel

local StatusPadding = Instance.new("UIPadding")
StatusPadding.Parent = StatusLabel
StatusPadding.PaddingLeft = UDim.new(0, 8)
StatusPadding.PaddingTop = UDim.new(0, 8)

-- Variables
local isEnabled = false
local isMinimized = false
local HeadSize = 15
local targetPlayers = {}
local originalSizes = {}

-- Functions
local function Notification(text, color)
    local notif = Instance.new("TextLabel")
    notif.Parent = ScreenGui
    notif.Size = UDim2.new(0, 200, 0, 40)
    notif.Position = UDim2.new(0.5, -100, 0, -50)
    notif.BackgroundColor3 = color or Color3.fromRGB(0, 255, 0)
    notif.BorderSizePixel = 0
    notif.Text = text
    notif.TextColor3 = Color3.fromRGB(255, 255, 255)
    notif.TextSize = 12
    notif.Font = Enum.Font.GothamBold
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    notif:TweenPosition(UDim2.new(0.5, -100, 0, 20), "Out", "Quad", 0.3, true)
    
    task.spawn(function()
        task.wait(2)
        notif:TweenPosition(UDim2.new(0.5, -100, 0, -50), "In", "Quad", 0.3, true)
        task.wait(0.3)
        notif:Destroy()
    end)
end

local function updateTargetPlayers()
    targetPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                table.insert(targetPlayers, player)
                
                -- Save original size if not saved
                if not originalSizes[player.UserId] then
                    originalSizes[player.UserId] = {
                        Size = hrp.Size,
                        Transparency = hrp.Transparency,
                        Material = hrp.Material,
                        CanCollide = hrp.CanCollide
                    }
                end
            end
        end
    end
end

local function resetHitbox(player)
    if player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and originalSizes[player.UserId] then
            local original = originalSizes[player.UserId]
            hrp.Size = original.Size
            hrp.Transparency = original.Transparency
            hrp.Material = original.Material
            hrp.CanCollide = original.CanCollide
        end
    end
end

local function resetAllHitboxes()
    for _, player in ipairs(targetPlayers) do
        resetHitbox(player)
    end
end

local function applyHitbox(player)
    if player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- IMPORTANT: Set size untuk hitbox detection
            hrp.Size = Vector3.new(HeadSize, HeadSize, HeadSize)
            hrp.Transparency = 0.7
            hrp.Material = Enum.Material.ForceField
            hrp.CanCollide = false
            
            -- CRITICAL FIX: Set Massless untuk melee detection!
            hrp.Massless = true
            
            -- OPTIONAL: Set CustomPhysicalProperties untuk melee
            local physicalProps = PhysicalProperties.new(
                0.7,  -- Density
                0.3,  -- Friction
                0.5,  -- Elasticity
                1,    -- FrictionWeight
                1     -- ElasticityWeight
            )
            hrp.CustomPhysicalProperties = physicalProps
        end
    end
end

-- TextBox Event
SizeTextBox.FocusLost:Connect(function()
    local newSize = tonumber(SizeTextBox.Text)
    if newSize and newSize >= 5 and newSize <= 50 then
        HeadSize = newSize
        Notification("Size: " .. HeadSize, Color3.fromRGB(0, 200, 255))
    else
        SizeTextBox.Text = tostring(HeadSize)
        Notification("Invalid! Use 5-50", Color3.fromRGB(255, 100, 0))
    end
end)

-- Toggle Button Event
ToggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    
    if isEnabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 220, 60)
        ToggleButton.Text = "🟢 ENABLED"
        AccentLine.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        Notification("Hitbox Enabled!", Color3.fromRGB(0, 255, 0))
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
        ToggleButton.Text = "🔴 DISABLED"
        AccentLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        resetAllHitboxes()
        Notification("Hitbox Disabled", Color3.fromRGB(255, 100, 0))
    end
end)

-- Minimize Button Event
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    
    local targetSize = isMinimized and UDim2.new(0, 220, 0, 38) or UDim2.new(0, 220, 0, 250)
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(MainFrame, tweenInfo, {Size = targetSize})
    
    tween:Play()
    MinimizeButton.Text = isMinimized and "+" or "−"
    AccentLine.Visible = not isMinimized
end)

-- Hover effects
ToggleButton.MouseEnter:Connect(function()
    if isEnabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 255, 80)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
    end
end)

ToggleButton.MouseLeave:Connect(function()
    if isEnabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 220, 60)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
    end
end)

MinimizeButton.MouseEnter:Connect(function()
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)

MinimizeButton.MouseLeave:Connect(function()
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
end)

-- Main Loop
RunService.Heartbeat:Connect(function()
    if isEnabled then
        for _, player in ipairs(targetPlayers) do
            applyHitbox(player)
        end
    end
end)

-- Status Update Loop
task.spawn(function()
    while task.wait(0.5) do
        updateTargetPlayers()
        
        local statusText = string.format(
            "STATUS: %s\nTargets: %d\nSize: %d",
            isEnabled and "ACTIVE" or "INACTIVE",
            #targetPlayers,
            HeadSize
        )
        
        StatusLabel.Text = statusText
        StatusLabel.TextColor3 = isEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(180, 180, 180)
    end
end)

-- Player Added/Removed Events
Players.PlayerAdded:Connect(function()
    task.wait(1)
    updateTargetPlayers()
end)

Players.PlayerRemoving:Connect(function(player)
    originalSizes[player.UserId] = nil
    updateTargetPlayers()
end)

-- Initial load
task.wait(1)
updateTargetPlayers()
Notification("Hitbox Loaded!", Color3.fromRGB(0, 255, 0))

print("✅ Hitbox Extender v2.0 Premium Loaded!")
