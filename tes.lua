
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Hapus GUI lama
if LocalPlayer.PlayerGui:FindFirstChild("WalkRecorderGUI") then
    LocalPlayer.PlayerGui:FindFirstChild("WalkRecorderGUI"):Destroy()
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
local Humanoid = Character:WaitForChild("Humanoid", 10)

if not HumanoidRootPart or not Humanoid then
    warn("Failed to load character")
    return
end


local RecordedWalks = {} -- Array untuk menyimpan semua rekaman
local CurrentRecording = {} -- Rekaman yang sedang berlangsung
local MAX_WALKS = 20
local RECORD_INTERVAL = 0.1 -- Record setiap 0.1 detik
local SAVE_FILE_NAME = "AutoWalkRecorder_v1"

-- States
local IsRecording = false
local IsPlaying = false
local IsPaused = false
local IsReversed = false -- Balik badan mode
local CurrentPlayingWalk = nil
local CurrentPlayingIndex = 1
local PlayConnection = nil

-- Forward declarations
local ShowNotification
local RefreshWalkList
local SaveWalksToFile
local LoadWalksFromFile


local RecordConnection = nil

local function StartRecording()
    if IsRecording then return end
    
    IsRecording = true
    CurrentRecording = {}
    
    ShowNotification("🔴 Recording Started!", Color3.fromRGB(255, 0, 0))
    
    -- Record posisi setiap interval
    RecordConnection = RunService.Heartbeat:Connect(function()
        if not IsRecording then return end
        if not HumanoidRootPart or not HumanoidRootPart.Parent then return end
        
        -- Simpan posisi dan orientasi
        table.insert(CurrentRecording, {
            Position = HumanoidRootPart.Position,
            CFrame = HumanoidRootPart.CFrame,
            Orientation = HumanoidRootPart.Orientation,
            Time = tick()
        })
        
        wait(RECORD_INTERVAL)
    end)
end

local function StopRecording()
    if not IsRecording then return end
    
    IsRecording = false
    
    if RecordConnection then
        RecordConnection:Disconnect()
        RecordConnection = nil
    end
    
    -- Simpan rekaman ke array
    if #CurrentRecording > 5 then -- Minimal 5 waypoints
        table.insert(RecordedWalks, {
            Name = "WALK CP " .. #RecordedWalks + 1,
            Path = CurrentRecording,
            Duration = #CurrentRecording * RECORD_INTERVAL,
            RecordedAt = os.date("%H:%M:%S")
        })
        
        RefreshWalkList()
        ShowNotification("💾 Walk saved! Total: " .. #RecordedWalks, Color3.fromRGB(0, 255, 0))
    else
        ShowNotification("❌ Recording too short!", Color3.fromRGB(255, 50, 50))
    end
    
    CurrentRecording = {}
end


local function StopPlayback()
    IsPlaying = false
    IsPaused = false
    
    if PlayConnection then
        PlayConnection:Disconnect()
        PlayConnection = nil
    end
    
    -- Reset humanoid state
    if Humanoid then
        Humanoid.WalkSpeed = 16
    end
end

local function PlayWalk(walkData, reversed)
    if IsPlaying then
        ShowNotification("⏳ Already playing!", Color3.fromRGB(255, 100, 0))
        return
    end
    
    if not walkData or not walkData.Path or #walkData.Path == 0 then
        ShowNotification("❌ Invalid walk data!", Color3.fromRGB(255, 50, 50))
        return
    end
    
    IsPlaying = true
    IsPaused = false
    IsReversed = reversed or false
    CurrentPlayingWalk = walkData
    CurrentPlayingIndex = 1
    
    local path = walkData.Path
    local pathLength = #path
    
    ShowNotification("▶️ Playing: " .. walkData.Name, Color3.fromRGB(0, 200, 255))
    
    -- Set walking animation
    if Humanoid then
        Humanoid.WalkSpeed = 16
    end
    
    spawn(function()
        while IsPlaying and CurrentPlayingIndex <= pathLength do
            -- Check pause
            while IsPaused and IsPlaying do
                wait(0.1)
            end
            
            if not IsPlaying then break end
            if not HumanoidRootPart or not HumanoidRootPart.Parent then break end
            
            local waypoint = path[CurrentPlayingIndex]
            
            if waypoint then
                -- Calculate target CFrame
                local targetCFrame = waypoint.CFrame
                
                -- Apply reverse if enabled
                if IsReversed then
                    local lookVector = targetCFrame.LookVector
                    targetCFrame = CFrame.new(waypoint.Position) * CFrame.Angles(0, math.pi, 0)
                end
                
                -- Smooth movement using Humanoid:MoveTo
                local currentPos = HumanoidRootPart.Position
                local targetPos = waypoint.Position
                local distance = (targetPos - currentPos).Magnitude
                
                if distance > 1 then
                    -- Use MoveTo for smooth walking animation
                    Humanoid:MoveTo(targetPos)
                    
                    -- Wait for movement or timeout
                    local moveStartTime = tick()
                    local moveTimeout = distance / 16 + 1 -- Based on WalkSpeed
                    
                    while (HumanoidRootPart.Position - targetPos).Magnitude > 2 do
                        if tick() - moveStartTime > moveTimeout then break end
                        if not IsPlaying or IsPaused then break end
                        wait(0.03)
                    end
                else
                    -- Direct CFrame for close positions
                    HumanoidRootPart.CFrame = targetCFrame
                    wait(RECORD_INTERVAL)
                end
            end
            
            CurrentPlayingIndex = CurrentPlayingIndex + 1
        end
        
        -- Playback finished
        if IsPlaying then
            StopPlayback()
            ShowNotification("✓ Playback Complete!", Color3.fromRGB(0, 255, 0))
        end
    end)
end

local function PausePlayback()
    if not IsPlaying then return end
    
    IsPaused = not IsPaused
    
    if IsPaused then
        ShowNotification("⏸️ Paused", Color3.fromRGB(255, 200, 0))
    else
        ShowNotification("▶️ Resumed", Color3.fromRGB(0, 200, 255))
    end
end

local function ToggleReverse()
    IsReversed = not IsReversed
    
    if IsReversed then
        ShowNotification("🔄 Reverse Mode: ON", Color3.fromRGB(255, 100, 200))
    else
        ShowNotification("➡️ Normal Mode", Color3.fromRGB(0, 200, 255))
    end
end


function SaveWalksToFile()
    if #RecordedWalks == 0 then
        ShowNotification("❌ No walks to save!", Color3.fromRGB(255, 50, 50))
        return false
    end
    
    local success, result = pcall(function()
        local data = {}
        
        for i, walk in ipairs(RecordedWalks) do
            local pathData = {}
            
            for j, waypoint in ipairs(walk.Path) do
                table.insert(pathData, {
                    X = waypoint.Position.X,
                    Y = waypoint.Position.Y,
                    Z = waypoint.Position.Z,
                    RX = waypoint.Orientation.X,
                    RY = waypoint.Orientation.Y,
                    RZ = waypoint.Orientation.Z
                })
            end
            
            table.insert(data, {
                Name = walk.Name,
                Path = pathData,
                Duration = walk.Duration,
                RecordedAt = walk.RecordedAt
            })
        end
        
        local encoded = HttpService:JSONEncode(data)
        writefile(SAVE_FILE_NAME .. ".json", encoded)
        return true
    end)
    
    if success and result then
        ShowNotification("💾 Saved " .. #RecordedWalks .. " walks!", Color3.fromRGB(0, 255, 0))
        return true
    else
        ShowNotification("❌ Save failed!", Color3.fromRGB(255, 50, 50))
        return false
    end
end

function LoadWalksFromFile()
    local success, result = pcall(function()
        if not isfile(SAVE_FILE_NAME .. ".json") then
            return nil
        end
        
        local content = readfile(SAVE_FILE_NAME .. ".json")
        local data = HttpService:JSONDecode(content)
        return data
    end)
    
    if success and result then
        RecordedWalks = {}
        
        for i, walk in ipairs(result) do
            local pathData = {}
            
            for j, waypoint in ipairs(walk.Path) do
                local pos = Vector3.new(waypoint.X, waypoint.Y, waypoint.Z)
                local rot = Vector3.new(waypoint.RX or 0, waypoint.RY or 0, waypoint.RZ or 0)
                
                table.insert(pathData, {
                    Position = pos,
                    CFrame = CFrame.new(pos) * CFrame.Angles(
                        math.rad(rot.X),
                        math.rad(rot.Y),
                        math.rad(rot.Z)
                    ),
                    Orientation = rot,
                    Time = 0
                })
            end
            
            table.insert(RecordedWalks, {
                Name = walk.Name,
                Path = pathData,
                Duration = walk.Duration,
                RecordedAt = walk.RecordedAt
            })
        end
        
        RefreshWalkList()
        ShowNotification("📂 Loaded " .. #RecordedWalks .. " walks!", Color3.fromRGB(0, 255, 0))
        return true
    elseif not success then
        ShowNotification("❌ Load failed!", Color3.fromRGB(255, 50, 50))
        return false
    else
        ShowNotification("📂 No save file found", Color3.fromRGB(255, 200, 0))
        return false
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WalkRecorderGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 450)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -225)
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
Title.Text = "🚶 AUTO WALK RECORDER"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Minimize Icon
local MinimizeIcon = Instance.new("ImageButton")
MinimizeIcon.Name = "MinimizeIcon"
MinimizeIcon.Size = UDim2.new(0, 50, 0, 50)
MinimizeIcon.Position = UDim2.new(0, 10, 0, 10)
MinimizeIcon.BackgroundTransparency = 1
MinimizeIcon.BorderSizePixel = 0
MinimizeIcon.Active = true
MinimizeIcon.Draggable = true
MinimizeIcon.Visible = false
MinimizeIcon.Image = "rbxassetid://110225912398772"
MinimizeIcon.ScaleType = Enum.ScaleType.Fit
MinimizeIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 10)
IconCorner.Parent = MinimizeIcon

MinimizeIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizeIcon.Visible = false
end)

MinimizeIcon.MouseEnter:Connect(function()
    MinimizeIcon.Size = UDim2.new(0, 55, 0, 55)
end)

MinimizeIcon.MouseLeave:Connect(function()
    MinimizeIcon.Size = UDim2.new(0, 50, 0, 50)
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
    ShowNotification("⚡ Minimized!", Color3.fromRGB(255, 100, 0))
end)

CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
end)


local ControlContainer = Instance.new("Frame")
ControlContainer.Size = UDim2.new(1, -20, 0, 140)
ControlContainer.Position = UDim2.new(0, 10, 0, 35)
ControlContainer.BackgroundTransparency = 1
ControlContainer.Parent = MainFrame

-- Record/Save Button (Toggle)
local RecordButton = Instance.new("TextButton")
RecordButton.Name = "RecordButton"
RecordButton.Size = UDim2.new(1, 0, 0, 40)
RecordButton.Position = UDim2.new(0, 0, 0, 0)
RecordButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
RecordButton.BorderSizePixel = 0
RecordButton.Text = "🔴 RECORD"
RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordButton.TextSize = 13
RecordButton.Font = Enum.Font.GothamBold
RecordButton.Parent = ControlContainer

local RecordCorner = Instance.new("UICorner")
RecordCorner.CornerRadius = UDim.new(0, 8)
RecordCorner.Parent = RecordButton

-- Pause/Resume Button (Toggle)
local PauseButton = Instance.new("TextButton")
PauseButton.Name = "PauseButton"
PauseButton.Size = UDim2.new(0.48, 0, 0, 40)
PauseButton.Position = UDim2.new(0, 0, 0, 48)
PauseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PauseButton.BorderSizePixel = 0
PauseButton.Text = "⏸️ PAUSE"
PauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PauseButton.TextSize = 12
PauseButton.Font = Enum.Font.GothamBold
PauseButton.Parent = ControlContainer

local PauseCorner = Instance.new("UICorner")
PauseCorner.CornerRadius = UDim.new(0, 8)
PauseCorner.Parent = PauseButton

-- Reverse/Normal Button (Toggle)
local ReverseButton = Instance.new("TextButton")
ReverseButton.Name = "ReverseButton"
ReverseButton.Size = UDim2.new(0.48, 0, 0, 40)
ReverseButton.Position = UDim2.new(0.52, 0, 0, 48)
ReverseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ReverseButton.BorderSizePixel = 0
ReverseButton.Text = "🔄 BALIK BADAN"
ReverseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ReverseButton.TextSize = 11
ReverseButton.Font = Enum.Font.GothamBold
ReverseButton.Parent = ControlContainer

local ReverseCorner = Instance.new("UICorner")
ReverseCorner.CornerRadius = UDim.new(0, 8)
ReverseCorner.Parent = ReverseButton

-- Save Walk Button
local SaveWalkButton = Instance.new("TextButton")
SaveWalkButton.Name = "SaveWalkButton"
SaveWalkButton.Size = UDim2.new(0.48, 0, 0, 40)
SaveWalkButton.Position = UDim2.new(0, 0, 0, 96)
SaveWalkButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
SaveWalkButton.BorderSizePixel = 0
SaveWalkButton.Text = "💾 SAVE WALK"
SaveWalkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveWalkButton.TextSize = 11
SaveWalkButton.Font = Enum.Font.GothamBold
SaveWalkButton.Parent = ControlContainer

local SaveWalkCorner = Instance.new("UICorner")
SaveWalkCorner.CornerRadius = UDim.new(0, 8)
SaveWalkCorner.Parent = SaveWalkButton

-- Load Walk Button
local LoadWalkButton = Instance.new("TextButton")
LoadWalkButton.Name = "LoadWalkButton"
LoadWalkButton.Size = UDim2.new(0.48, 0, 0, 40)
LoadWalkButton.Position = UDim2.new(0.52, 0, 0, 96)
LoadWalkButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
LoadWalkButton.BorderSizePixel = 0
LoadWalkButton.Text = "📂 LOAD WALK"
LoadWalkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadWalkButton.TextSize = 11
LoadWalkButton.Font = Enum.Font.GothamBold
LoadWalkButton.Parent = ControlContainer

local LoadWalkCorner = Instance.new("UICorner")
LoadWalkCorner.CornerRadius = UDim.new(0, 8)
LoadWalkCorner.Parent = LoadWalkButton

-- Counter Label
local WalkCounter = Instance.new("TextLabel")
WalkCounter.Size = UDim2.new(1, 0, 0, 20)
WalkCounter.Position = UDim2.new(0, 0, 0, 180)
WalkCounter.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
WalkCounter.BackgroundTransparency = 0.3
WalkCounter.BorderSizePixel = 0
WalkCounter.Text = "Recorded Walks: 0/" .. MAX_WALKS
WalkCounter.TextColor3 = Color3.fromRGB(200, 200, 200)
WalkCounter.TextSize = 10
WalkCounter.Font = Enum.Font.GothamBold
WalkCounter.Parent = MainFrame

local CounterCorner = Instance.new("UICorner")
CounterCorner.CornerRadius = UDim.new(0, 6)
CounterCorner.Parent = WalkCounter


local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "WalkList"
ScrollFrame.Size = UDim2.new(1, -20, 1, -290)
ScrollFrame.Position = UDim2.new(0, 10, 0, 210)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ScrollFrame.BackgroundTransparency = 0.4
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 0)
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
EmptyLabel.Text = "No recorded walks\n\nPress RECORD to start!"
EmptyLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
EmptyLabel.TextSize = 11
EmptyLabel.Font = Enum.Font.GothamBold
EmptyLabel.TextWrapped = true
EmptyLabel.Parent = ScrollFrame

-- Info Panel
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

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 0, 18)
StatusText.Position = UDim2.new(0, 5, 0, 4)
StatusText.BackgroundTransparency = 1
StatusText.Text = "✓ Status: Ready"
StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusText.TextSize = 10
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = InfoPanel

local ModeText = Instance.new("TextLabel")
ModeText.Size = UDim2.new(1, -10, 0, 16)
ModeText.Position = UDim2.new(0, 5, 0, 20)
ModeText.BackgroundTransparency = 1
ModeText.Text = "➡️ Mode: Normal"
ModeText.TextColor3 = Color3.fromRGB(200, 200, 200)
ModeText.TextSize = 9
ModeText.Font = Enum.Font.GothamBold
ModeText.TextXAlignment = Enum.TextXAlignment.Left
ModeText.Parent = InfoPanel

local VersionText = Instance.new("TextLabel")
VersionText.Size = UDim2.new(1, -10, 0, 12)
VersionText.Position = UDim2.new(0, 5, 0, 36)
VersionText.BackgroundTransparency = 1
VersionText.Text = "v1.0 | Auto Walk Recorder"
VersionText.TextColor3 = Color3.fromRGB(255, 100, 0)
VersionText.TextSize = 7
VersionText.Font = Enum.Font.GothamBold
VersionText.TextXAlignment = Enum.TextXAlignment.Left
VersionText.Parent = InfoPanel

local function ShowDeleteConfirm(index, walkData, callback)
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
    ConfirmText.Text = "Delete " .. walkData.Name .. "?\nDuration: " .. string.format("%.1fs", walkData.Duration)
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

local function CreateWalkButton(index, walkData)
    local Button = Instance.new("TextButton")
    Button.Name = "Walk" .. index
    Button.Size = UDim2.new(1, -8, 0, 50)
    Button.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Text = ""
    Button.Parent = ScrollFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 7)
    BtnCorner.Parent = Button
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -45, 0, 20)
    TitleLabel.Position = UDim2.new(0, 5, 0, 3)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "🚶 " .. walkData.Name
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 11
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Button
    
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -45, 0, 24)
    InfoLabel.Position = UDim2.new(0, 5, 0, 23)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = string.format("Duration: %.1fs | Points: %d\nRecorded: %s", 
        walkData.Duration, 
        #walkData.Path, 
        walkData.RecordedAt
    )
    InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    InfoLabel.TextSize = 8
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
    InfoLabel.Parent = Button
    
    local DeleteBtn = Instance.new("TextButton")
    DeleteBtn.Size = UDim2.new(0, 35, 0, 35)
    DeleteBtn.Position = UDim2.new(1, -40, 0, 7.5)
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
    
    -- Play button click
    Button.MouseButton1Click:Connect(function()
        if IsRecording then
            ShowNotification("❌ Stop recording first!", Color3.fromRGB(255, 50, 50))
            return
        end
        
        if IsPlaying then
            StopPlayback()
            ShowNotification("⏹️ Playback stopped!", Color3.fromRGB(255, 100, 0))
        else
            PlayWalk(walkData, IsReversed)
        end
    end)
    
    -- Delete button click
    DeleteBtn.MouseButton1Click:Connect(function()
        ShowDeleteConfirm(index, walkData, function(confirmed)
            if confirmed then
                table.remove(RecordedWalks, index)
                RefreshWalkList()
                ShowNotification("🗑️ " .. walkData.Name .. " deleted!", Color3.fromRGB(255, 100, 0))
            else
                ShowNotification("❌ Delete cancelled", Color3.fromRGB(200, 200, 200))
            end
        end)
    end)
    
    Button.MouseEnter:Connect(function()
        if not IsPlaying then
            Button.BackgroundColor3 = Color3.fromRGB(255, 130, 30)
        end
    end)
    
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    end)
    
    DeleteBtn.MouseEnter:Connect(function()
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    end)
    
    DeleteBtn.MouseLeave:Connect(function()
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    end)
    
    return Button
end


function RefreshWalkList()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    WalkCounter.Text = "Recorded Walks: " .. #RecordedWalks .. "/" .. MAX_WALKS
    
    if #RecordedWalks == 0 then
        EmptyLabel.Visible = true
    else
        EmptyLabel.Visible = false
        
        for i, walk in ipairs(RecordedWalks) do
            CreateWalkButton(i, walk)
        end
    end
end

-- Record/Save Button Handler
RecordButton.MouseButton1Click:Connect(function()
    if IsPlaying then
        ShowNotification("❌ Stop playback first!", Color3.fromRGB(255, 50, 50))
        return
    end
    
    if not IsRecording then
        -- Start Recording
        if #RecordedWalks >= MAX_WALKS then
            ShowNotification("❌ Maximum " .. MAX_WALKS .. " walks reached!", Color3.fromRGB(255, 50, 50))
            return
        end
        
        StartRecording()
        RecordButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        RecordButton.Text = "💾 SAVE"
    else
        -- Stop & Save Recording
        StopRecording()
        RecordButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        RecordButton.Text = "🔴 RECORD"
    end
end)

RecordButton.MouseEnter:Connect(function()
    if IsRecording then
        RecordButton.BackgroundColor3 = Color3.fromRGB(0, 230, 0)
    else
        RecordButton.BackgroundColor3 = Color3.fromRGB(255, 130, 30)
    end
end)

RecordButton.MouseLeave:Connect(function()
    if IsRecording then
        RecordButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        RecordButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    end
end)

-- Pause/Resume Button Handler
PauseButton.MouseButton1Click:Connect(function()
    if not IsPlaying then
        ShowNotification("❌ No playback active!", Color3.fromRGB(255, 50, 50))
        return
    end
    
    PausePlayback()
    
    if IsPaused then
        PauseButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        PauseButton.Text = "▶️ LANJUTKAN"
    else
        PauseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        PauseButton.Text = "⏸️ PAUSE"
    end
end)

PauseButton.MouseEnter:Connect(function()
    if IsPaused then
        PauseButton.BackgroundColor3 = Color3.fromRGB(255, 220, 50)
    else
        PauseButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

PauseButton.MouseLeave:Connect(function()
    if IsPaused then
        PauseButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    else
        PauseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end)

-- Reverse/Normal Button Handler
ReverseButton.MouseButton1Click:Connect(function()
    ToggleReverse()
    
    if IsReversed then
        ReverseButton.BackgroundColor3 = Color3.fromRGB(255, 100, 200)
        ReverseButton.Text = "➡️ NORMAL"
    else
        ReverseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        ReverseButton.Text = "🔄 BALIK BADAN"
    end
end)

ReverseButton.MouseEnter:Connect(function()
    if IsReversed then
        ReverseButton.BackgroundColor3 = Color3.fromRGB(255, 130, 220)
    else
        ReverseButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

ReverseButton.MouseLeave:Connect(function()
    if IsReversed then
        ReverseButton.BackgroundColor3 = Color3.fromRGB(255, 100, 200)
    else
        ReverseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end)

-- Save Walk Button Handler
SaveWalkButton.MouseButton1Click:Connect(function()
    SaveWalkButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    SaveWalksToFile()
    wait(1)
    SaveWalkButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
end)

SaveWalkButton.MouseEnter:Connect(function()
    SaveWalkButton.BackgroundColor3 = Color3.fromRGB(255, 130, 30)
end)

SaveWalkButton.MouseLeave:Connect(function()
    SaveWalkButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
end)

-- Load Walk Button Handler
LoadWalkButton.MouseButton1Click:Connect(function()
    LoadWalkButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    LoadWalksFromFile()
    wait(1)
    LoadWalkButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
end)

LoadWalkButton.MouseEnter:Connect(function()
    LoadWalkButton.BackgroundColor3 = Color3.fromRGB(255, 130, 30)
end)

LoadWalkButton.MouseLeave:Connect(function()
    LoadWalkButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
end)

-- Variable global
local IsReversed = false

-- Function bisa dipanggil kapan saja
local function ToggleReverse()
    IsReversed = not IsReversed
    
    if IsReversed then
        ShowNotification("🔄 Reverse Mode: ON", Color3.fromRGB(255, 100, 200))
    else
        ShowNotification("➡️ Normal Mode", Color3.fromRGB(0, 200, 255))
    end
end

-- Button handler - TIDAK ADA kondisi IsPlaying
ReverseButton.MouseButton1Click:Connect(function()
    ToggleReverse()  -- Langsung toggle, no condition!
    
    if IsReversed then
        ReverseButton.BackgroundColor3 = Color3.fromRGB(255, 100, 200)
        ReverseButton.Text = "➡️ NORMAL"
    else
        ReverseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        ReverseButton.Text = "🔄 BALIK BADAN"
    end
end)
