-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- GUI Elements
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local MainCorner = Instance.new("UICorner")
local SizeTextBox = Instance.new("TextBox")
local TextBoxCorner = Instance.new("UICorner")
local ToggleButton = Instance.new("TextButton")
local ToggleCorner = Instance.new("UICorner")
local MinimizeButton = Instance.new("TextButton")
local MinimizeCorner = Instance.new("UICorner")

-- Variables
local isMinimized = false

-- GUI Setup
ScreenGui.Parent = game.CoreGui

MainFrame.Parent = ScreenGui
SizeTextBox.Parent = MainFrame
ToggleButton.Parent = MainFrame
MinimizeButton.Parent = MainFrame
MainCorner.Parent = MainFrame
TextBoxCorner.Parent = SizeTextBox
ToggleCorner.Parent = ToggleButton
MinimizeCorner.Parent = MinimizeButton

-- MainFrame Properties
MainFrame.Size = UDim2.new(0, 160, 0, 110)
MainFrame.Position = UDim2.new(0.5, -80, 0.5, -55)
MainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.BackgroundTransparency = 0.2
MainFrame.Visible = true
MainCorner.CornerRadius = UDim.new(0, 10)

-- Minimize Button Properties
MinimizeButton.Size = UDim2.new(0, 160, 0, 20)
MinimizeButton.Position = UDim2.new(0, 0, 0, 0)
MinimizeButton.Text = "Hitbox | NazamOfficial"
MinimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeCorner.CornerRadius = UDim.new(0, 10)

-- TextBox Properties
SizeTextBox.Size = UDim2.new(0, 140, 0, 25)
SizeTextBox.Position = UDim2.new(0, 10, 0, 25)
SizeTextBox.Text = "10"
SizeTextBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
SizeTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBoxCorner.CornerRadius = UDim.new(0, 10)

-- Toggle Button Properties
ToggleButton.Size = UDim2.new(0, 140, 0, 25)
ToggleButton.Position = UDim2.new(0, 10, 0, 55)
ToggleButton.Text = "Enable Hitbox"
ToggleButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleCorner.CornerRadius = UDim.new(0, 10)

-- Global Variables
_G.HeadSize = tonumber(SizeTextBox.Text) or 10
_G.Disabled = true

-- Player List
local targetPlayers = {}

-- Function to update target players
local function updateTargetPlayers()
    targetPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(targetPlayers, player)
        end
    end
end

-- TextBox Focus Lost Event
SizeTextBox.FocusLost:Connect(function()
    local newSize = tonumber(SizeTextBox.Text)
    if newSize then
        _G.HeadSize = newSize
    else
        SizeTextBox.Text = tostring(_G.HeadSize)
    end
end)

-- Toggle Button Click Event
ToggleButton.MouseButton1Click:Connect(function()
    _G.Disabled = not _G.Disabled
    ToggleButton.Text = (_G.Disabled and "Enable Hitbox") or "Disable Hitbox"
    
    -- Reset hitboxes when disabled
    if _G.Disabled then
        for _, player in ipairs(targetPlayers) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 0
                hrp.BrickColor = BrickColor.new("Medium stone grey")
                hrp.Material = Enum.Material.Plastic
                hrp.CanCollide = true
            end
        end
    end
end)

-- Minimize Button Click Event
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = (isMinimized and UDim2.new(0, 160, 0, 20)) or UDim2.new(0, 160, 0, 110)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(MainFrame, tweenInfo, {Size = targetSize})
    
    tween:Play()
    MinimizeButton.Text = (isMinimized and "▲") or "▼"
end)

-- Main Loop - Update Hitboxes
RunService.RenderStepped:Connect(function()
    if not _G.Disabled then
        for _, player in ipairs(targetPlayers) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                hrp.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                hrp.Transparency = 0.7
                hrp.BrickColor = BrickColor.new("White")
                hrp.Material = Enum.Material.Neon
                hrp.CanCollide = false
            end
        end
    end
end)

-- Update Target Players Loop
while true do
    updateTargetPlayers()
    wait(1)
end
