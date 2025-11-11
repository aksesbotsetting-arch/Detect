-- STEALTH MODE v2.0
-- Mini Size + Speed Boost - Perfect for Stealing Games!

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

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
local MiniSizeActive = false
local SpeedBoostActive = false
local OriginalSpeed = 16
local OriginalSize = nil

-- ==================== MINI SIZE SYSTEM ====================

local function EnableMiniSize()
    if MiniSizeActive then return end
    if not Humanoid then return end
    
    MiniSizeActive = true
    
    -- Simpan size original
    if not OriginalSize then
        OriginalSize = {
            BodyDepthScale = Humanoid.BodyDepthScale.Value,
            BodyHeightScale = Humanoid.BodyHeightScale.Value,
            BodyWidthScale = Humanoid.BodyWidthScale.Value,
            HeadScale = Humanoid.HeadScale.Value
        }
    end
    
    -- Set ke SUPER KECIL (10% dari normal = kayak semut!)
    local miniScale = 0.1
    
    pcall(function()
        Humanoid.BodyDepthScale.Value = miniScale
        Humanoid.BodyHeightScale.Value = miniScale
        Humanoid.BodyWidthScale.Value = miniScale
        Humanoid.HeadScale.Value = miniScale
    end)
    
    -- Adjust HipHeight supaya tidak terlalu rendah
    if Humanoid then
        Humanoid.HipHeight = Humanoid.HipHeight * miniScale
    end
end

local function DisableMiniSize()
    if not MiniSizeActive then return end
    if not Humanoid then return end
    
    MiniSizeActive = false
    
    -- Restore size original
    if OriginalSize then
        pcall(function()
            Humanoid.BodyDepthScale.Value = OriginalSize.BodyDepthScale
            Humanoid.BodyHeightScale.Value = OriginalSize.BodyHeightScale
            Humanoid.BodyWidthScale.Value = OriginalSize.BodyWidthScale
            Humanoid.HeadScale.Value = OriginalSize.HeadScale
        end)
    else
        -- Default Roblox scale
        pcall(function()
            Humanoid.BodyDepthScale.Value = 1
            Humanoid.BodyHeightScale.Value = 1
            Humanoid.BodyWidthScale.Value = 1
            Humanoid.HeadScale.Value = 1
        end)
    end
    
    -- Reset HipHeight
    if Humanoid then
        Humanoid.HipHeight = 0
    end
end

-- ==================== SPEED BOOST SYSTEM ====================

local function EnableSpeedBoost()
    if not Humanoid then return end
    if SpeedBoostActive then return end
    
    SpeedBoostActive = true
    OriginalSpeed = Humanoid.WalkSpeed
    Humanoid.WalkSpeed = 25 -- Speed boost ke 25 (lebih kenceng!)
end

local function DisableSpeedBoost()
    if not Humanoid then return end
    if not SpeedBoostActive then return end
    
    SpeedBoostActive = false
    Humanoid.WalkSpeed = OriginalSpeed
end

-- ==================== GUI CREATION ====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 320)
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
Title.Text = "🐜 STEALTH MODE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -55)
Container.Position = UDim2.new(0, 10, 0, 45)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

-- Button Creator Function
local function CreateToggleButton(name, text, position, callback)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 50)
    Button.Position = position
    Button.BackgroundColor3 = Color3.fromRGB(139, 0, 0) -- Merah (OFF)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamSemibold
    Button.AutoButtonColor = false
    Button.Parent = Container
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button
    
    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Size = UDim2.new(0, 50, 1, 0)
    Status.Position = UDim2.new(1, -55, 0, 0)
    Status.BackgroundTransparency = 1
    Status.Text = "OFF"
    Status.TextColor3 = Color3.fromRGB(255, 255, 255)
    Status.TextSize = 12
    Status.Font = Enum.Font.GothamBold
    Status.Parent = Button
    
    -- State variable
    local isActive = false
    
    Button.MouseButton1Click:Connect(function()
        isActive = not isActive
        callback(isActive, Button, Status)
    end)
    
    Button.MouseEnter:Connect(function()
        if isActive then
            Button.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        else
            Button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        end
    end)
    
    Button.MouseLeave:Connect(function()
        if isActive then
            Button.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
        else
            Button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        end
    end)
    
    return Button, Status
end

-- MINI SIZE Button
CreateToggleButton("MiniBtn", "MINI SIZE", UDim2.new(0, 0, 0, 0),
    function(active, btn, status)
        if active then
            EnableMiniSize()
            btn.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
            status.Text = "ON"
            ShowNotification("🐜 Mini Size: ON", Color3.fromRGB(0, 255, 0))
        else
            DisableMiniSize()
            btn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
            status.Text = "OFF"
            ShowNotification("👤 Normal Size: ON", Color3.fromRGB(255, 100, 0))
        end
    end
)

-- SPEED BOOST Button
CreateToggleButton("SpeedBtn", "SPEED BOOST", UDim2.new(0, 0, 0, 60),
    function(active, btn, status)
        if active then
            EnableSpeedBoost()
            btn.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
            status.Text = "ON"
            ShowNotification("⚡ Speed: 25", Color3.fromRGB(0, 255, 0))
        else
            DisableSpeedBoost()
            btn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
            status.Text = "OFF"
            ShowNotification("🚶 Speed: 16", Color3.fromRGB(255, 100, 0))
        end
    end
)

-- Info Panel
local InfoBox = Instance.new("Frame")
InfoBox.Size = UDim2.new(1, 0, 0, 130)
InfoBox.Position = UDim2.new(0, 0, 0, 130)
InfoBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
InfoBox.BackgroundTransparency = 0.5
InfoBox.BorderSizePixel = 0
InfoBox.Parent = Container

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoBox

local InfoTitle = Instance.new("TextLabel")
InfoTitle.Size = UDim2.new(1, -10, 0, 25)
InfoTitle.Position = UDim2.new(0, 5, 0, 5)
InfoTitle.BackgroundTransparency = 1
InfoTitle.Text = "📊 STATUS"
InfoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoTitle.TextSize = 12
InfoTitle.Font = Enum.Font.GothamBold
InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
InfoTitle.Parent = InfoBox

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 0, 95)
StatusText.Position = UDim2.new(0, 5, 0, 30)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Size: Normal\nSpeed: 16\n\n✓ Super small = hard to see\n✓ Fast speed = quick escape\n✓ Perfect for stealing!"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.TextSize = 10
StatusText.Font = Enum.Font.Gotham
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextYAlignment = Enum.TextYAlignment.Top
StatusText.Parent = InfoBox

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
    DisableMiniSize()
    DisableSpeedBoost()
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
    NotifText.TextSize = 14
    NotifText.Font = Enum.Font.GothamBold
    NotifText.Parent = NotifFrame
    
    NotifFrame:TweenPosition(UDim2.new(0.5, -125, 0, 10), "Out", "Quad", 0.3, true)
    
    spawn(function()
        wait(2)
        NotifFrame:TweenPosition(UDim2.new(0.5, -125, 0, -60), "In", "Quad", 0.3, true)
        wait(0.3)
        NotifFrame:Destroy()
    end)
end

-- Update Status Display
spawn(function()
    while wait(0.5) do
        if Humanoid then
            local sizeText = MiniSizeActive and "Mini (10%)" or "Normal"
            local speedValue = Humanoid.WalkSpeed
            
            StatusText.Text = string.format(
                "🐜 Size: %s\n⚡ Speed: %.0f\n\n✓ Mini = 90%% smaller!\n✓ Very hard to see\n✓ Perfect combo for steal!",
                sizeText,
                speedValue
            )
        end
    end
end)

-- Character Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 10)
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    
    -- Reset states
    MiniSizeActive = false
    SpeedBoostActive = false
    OriginalSize = nil
end)

-- Load Notification
spawn(function()
    wait(0.5)
    ShowNotification("🐜 Stealth Mode Loaded!", Color3.fromRGB(100, 150, 255))
end)

print("🐜 Stealth Mode v2.0 - Mini Size + Speed Boost Loaded!")
