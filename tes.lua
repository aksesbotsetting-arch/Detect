-- GHOST MODE v1.0
-- Invisible + Speed Boost - Simple & Powerful

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
local InvisibleActive = false
local SpeedBoostActive = false
local OriginalSpeed = 16
local InvisibleConnection = nil

-- ==================== INVISIBLE SYSTEM ====================

local function EnableInvisible()
    if InvisibleActive then return end
    InvisibleActive = true
    
    -- Method 1: Set Transparency untuk CHARACTER parts
    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Transparency = 1
            part.CanCollide = false
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
        elseif part:IsA("Accessory") or part:IsA("Hat") then
            -- Sembunyikan accessories/items
            for _, child in pairs(part:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    child.Transparency = 1
                end
            end
        end
    end
    
    -- Sembunyikan face
    if Character:FindFirstChild("Head") then
        local head = Character.Head
        if head:FindFirstChild("face") then
            head.face.Transparency = 1
        end
    end
    
    -- HumanoidRootPart tetap ada tapi invisible
    if HumanoidRootPart then
        HumanoidRootPart.Transparency = 1
    end
    
    -- Continuous invisible (untuk character + ITEMS YANG DIPEGANG!)
    InvisibleConnection = RunService.Heartbeat:Connect(function()
        if not InvisibleActive then return end
        
        -- Hide CHARACTER parts
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                if part.Transparency ~= 1 then
                    part.Transparency = 1
                end
            elseif part:IsA("Decal") or part:IsA("Texture") then
                if part.Transparency ~= 1 then
                    part.Transparency = 1
                end
            end
        end
        
        -- IMPORTANT: Hide TOOLS/PETS/OBJECTS yang dipegang!
        -- Cari semua Weld/WeldConstraint yang connect ke character
        for _, obj in pairs(workspace:GetDescendants()) do
            local shouldHide = false
            
            -- Check 1: Apakah object ini di-weld ke character?
            if obj:IsA("Weld") or obj:IsA("WeldConstraint") or obj:IsA("Motor6D") then
                local part0 = obj.Part0
                local part1 = obj.Part1
                
                -- Kalau salah satu part nya adalah bagian dari character
                if (part0 and part0:IsDescendantOf(Character)) or (part1 and part1:IsDescendantOf(Character)) then
                    -- Hide object yang terhubung
                    local targetPart = nil
                    if part0 and not part0:IsDescendantOf(Character) then
                        targetPart = part0
                    elseif part1 and not part1:IsDescendantOf(Character) then
                        targetPart = part1
                    end
                    
                    if targetPart then
                        -- Hide part dan semua descendants nya
                        if targetPart:IsA("BasePart") or targetPart:IsA("MeshPart") then
                            targetPart.Transparency = 1
                        end
                        
                        -- Hide parent model juga (untuk pets/animals)
                        local model = targetPart.Parent
                        if model and model:IsA("Model") then
                            for _, child in pairs(model:GetDescendants()) do
                                if child:IsA("BasePart") or child:IsA("MeshPart") then
                                    child.Transparency = 1
                                elseif child:IsA("Decal") or child:IsA("Texture") then
                                    child.Transparency = 1
                                end
                            end
                        end
                    end
                end
            end
            
            -- Check 2: Object yang di-parent langsung ke character (Tools, etc)
            if obj.Parent and obj.Parent:IsDescendantOf(Character) then
                if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                    obj.Transparency = 1
                elseif obj:IsA("Model") then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") or child:IsA("MeshPart") then
                            child.Transparency = 1
                        elseif child:IsA("Decal") or child:IsA("Texture") then
                            child.Transparency = 1
                        end
                    end
                end
            end
            
            -- Check 3: Object yang distance nya dekat dengan character (holding)
            if obj:IsA("Model") and obj ~= Character then
                local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primaryPart and HumanoidRootPart then
                    local distance = (primaryPart.Position - HumanoidRootPart.Position).Magnitude
                    
                    -- Kalau jarak < 10 studs, kemungkinan besar dipegang
                    if distance < 10 then
                        -- Check kalau ada Weld/Constraint ke character
                        local hasConnection = false
                        for _, child in pairs(obj:GetDescendants()) do
                            if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Motor6D") then
                                local p0 = child.Part0
                                local p1 = child.Part1
                                if (p0 and p0:IsDescendantOf(Character)) or (p1 and p1:IsDescendantOf(Character)) then
                                    hasConnection = true
                                    break
                                end
                            end
                        end
                        
                        if hasConnection then
                            -- Hide seluruh model
                            for _, part in pairs(obj:GetDescendants()) do
                                if part:IsA("BasePart") or part:IsA("MeshPart") then
                                    part.Transparency = 1
                                elseif part:IsA("Decal") or part:IsA("Texture") then
                                    part.Transparency = 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function DisableInvisible()
    if not InvisibleActive then return end
    InvisibleActive = false
    
    -- Disconnect continuous check
    if InvisibleConnection then
        InvisibleConnection:Disconnect()
        InvisibleConnection = nil
    end
    
    -- Restore visibility for CHARACTER
    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Transparency = 0
            if part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0
        elseif part:IsA("Accessory") or part:IsA("Hat") then
            for _, child in pairs(part:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    child.Transparency = 0
                end
            end
        end
    end
    
    -- Restore face
    if Character:FindFirstChild("Head") then
        local head = Character.Head
        if head:FindFirstChild("face") then
            head.face.Transparency = 0
        end
    end
    
    -- HumanoidRootPart tetap invisible (default Roblox)
    if HumanoidRootPart then
        HumanoidRootPart.Transparency = 1
    end
    
    -- Restore visibility untuk SEMUA OBJECTS di workspace (pets/animals yang dibawa)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            -- Restore transparency ke default (0)
            -- KECUALI kalau memang part nya transparan by design
            if obj.Name ~= "HumanoidRootPart" then
                pcall(function()
                    obj.Transparency = 0
                end)
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            pcall(function()
                obj.Transparency = 0
            end)
        end
    end
end

-- ==================== SPEED BOOST SYSTEM ====================

local function EnableSpeedBoost()
    if not Humanoid then return end
    if SpeedBoostActive then return end
    
    SpeedBoostActive = true
    OriginalSpeed = Humanoid.WalkSpeed
    Humanoid.WalkSpeed = 20
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
Title.Text = "👻 GHOST MODE"
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

-- INVISIBLE Button
CreateToggleButton("InvisibleBtn", "INVISIBLE", UDim2.new(0, 0, 0, 0),
    function(active, btn, status)
        if active then
            EnableInvisible()
            btn.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
            status.Text = "ON"
            ShowNotification("👻 Invisible: ON", Color3.fromRGB(0, 255, 0))
        else
            DisableInvisible()
            btn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
            status.Text = "OFF"
            ShowNotification("👁️ Invisible: OFF", Color3.fromRGB(255, 100, 0))
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
            ShowNotification("⚡ Speed: 20", Color3.fromRGB(0, 255, 0))
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
InfoBox.Size = UDim2.new(1, 0, 0, 120)
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
StatusText.Size = UDim2.new(1, -10, 0, 85)
StatusText.Position = UDim2.new(0, 5, 0, 30)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Invisible: OFF\nSpeed: 16\n\n✓ Hide character\n✓ Hide pets/animals held\n✓ Both work together!"
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
    DisableInvisible()
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
            local invisText = InvisibleActive and "ON" or "OFF"
            local speedValue = Humanoid.WalkSpeed
            
            StatusText.Text = string.format(
                "👻 Invisible: %s\n⚡ Speed: %.0f\n\n✓ Hide character\n✓ Hide pets/animals\n✓ Perfect for stealing!",
                invisText,
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
    InvisibleActive = false
    SpeedBoostActive = false
    if InvisibleConnection then
        InvisibleConnection:Disconnect()
        InvisibleConnection = nil
    end
end)

-- Load Notification
spawn(function()
    wait(0.5)
    ShowNotification("👻 Ghost Mode Loaded!", Color3.fromRGB(100, 150, 255))
end)

print("👻 Ghost Mode v1.0 - Invisible + Speed Boost Loaded!")
