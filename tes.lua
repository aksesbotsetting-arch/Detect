local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Hapus GUI lama jika ada
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

-- Variabel sistem Auto Walk Recorder
local WalkRecordings = {}
local CurrentRecording = nil
local IsRecording = false
local IsPlaying = false
local IsPaused = false
local ReverseOrientation = false
local PlaybackConnection = nil
local RecordConnection = nil
local MAX_RECORDINGS = 20
local SAVE_FILE_NAME = "AutoWalkRecorder_Saves"
local UseCustomAnim = false
local CurrentState = "Idle"
local StateDetectionConnection = nil
local CurrentAnimTrack = nil

-- Animasi custom (ganti dengan animation ID kamu)
local CUSTOM_ANIMATIONS = {
    -- Basic Movements
    Walk = "rbxassetid://4845126998",
    Run = "rbxassetid://4845126998", 
    Idle = "rbxassetid://6161589299",
    Jump = "rbxassetid://6312531221",
    
    -- Advanced Movements
    Swim = "rbxassetid://6161658570",
    SwimIdle = "rbxassetid://6161660330",
    Climb = "rbxassetid://6161557492", 
    ClimbIdle = "rbxassetid://6161561192",
    Fall = "rbxassetid://6161680092",
    Land = "rbxassetid://6161660330"
}

-- Load animasi
local AnimationTracks = {}
local function LoadAnimations()
    for animName, animId in pairs(CUSTOM_ANIMATIONS) do
        local animation = Instance.new("Animation")
        animation.AnimationId = animId
        AnimationTracks[animName] = Humanoid:LoadAnimation(animation)
    end
end

LoadAnimations()

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WalkRecorderGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

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

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 500)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
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
Title.Position = UDim2.new(0, 20, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "🚶 AUTO WALK RECORDER + ANIMASI"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 28, 0, 28)
MinimizeButton.Position = UDim2.new(1, -33, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 18
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = MainFrame

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 7)
MinimizeCorner.Parent = MinimizeButton

-- Tombol Utama
local MainButtonsFrame = Instance.new("Frame")
MainButtonsFrame.Size = UDim2.new(1, -20, 0, 150)
MainButtonsFrame.Position = UDim2.new(0, 10, 0, 40)
MainButtonsFrame.BackgroundTransparency = 1
MainButtonsFrame.Parent = MainFrame

-- Record/Save Button
local RecordSaveButton = Instance.new("TextButton")
RecordSaveButton.Name = "RecordSaveButton"
RecordSaveButton.Size = UDim2.new(1, 0, 0, 35)
RecordSaveButton.Position = UDim2.new(0, 0, 0, 0)
RecordSaveButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
RecordSaveButton.BorderSizePixel = 0
RecordSaveButton.Text = "🔴 RECORD"
RecordSaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordSaveButton.TextSize = 14
RecordSaveButton.Font = Enum.Font.GothamBold
RecordSaveButton.Parent = MainButtonsFrame

local RecordCorner = Instance.new("UICorner")
RecordCorner.CornerRadius = UDim.new(0, 8)
RecordCorner.Parent = RecordSaveButton

-- Pause/Lanjutkan Button
local PauseResumeButton = Instance.new("TextButton")
PauseResumeButton.Name = "PauseResumeButton"
PauseResumeButton.Size = UDim2.new(1, 0, 0, 35)
PauseResumeButton.Position = UDim2.new(0, 0, 0, 42)
PauseResumeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PauseResumeButton.BorderSizePixel = 0
PauseResumeButton.Text = "⏸️ PAUSE"
PauseResumeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PauseResumeButton.TextSize = 14
PauseResumeButton.Font = Enum.Font.GothamBold
PauseResumeButton.Parent = MainButtonsFrame

local PauseCorner = Instance.new("UICorner")
PauseCorner.CornerRadius = UDim.new(0, 8)
PauseCorner.Parent = PauseResumeButton

-- Balik Badan/Normal Button
local ReverseButton = Instance.new("TextButton")
ReverseButton.Name = "ReverseButton"
ReverseButton.Size = UDim2.new(1, 0, 0, 35)
ReverseButton.Position = UDim2.new(0, 0, 0, 84)
ReverseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ReverseButton.BorderSizePixel = 0
ReverseButton.Text = "🔄 BALIK BADAN"
ReverseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ReverseButton.TextSize = 14
ReverseButton.Font = Enum.Font.GothamBold
ReverseButton.Parent = MainButtonsFrame

local ReverseCorner = Instance.new("UICorner")
ReverseCorner.CornerRadius = UDim.new(0, 8)
ReverseCorner.Parent = ReverseButton

-- Use Custom Anim Button
local UseAnimButton = Instance.new("TextButton")
UseAnimButton.Name = "UseAnimButton"
UseAnimButton.Size = UDim2.new(1, 0, 0, 35)
UseAnimButton.Position = UDim2.new(0, 0, 0, 126)
UseAnimButton.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
UseAnimButton.BorderSizePixel = 0
UseAnimButton.Text = "🎭 GUNAKAN ANIMASI CUSTOM"
UseAnimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UseAnimButton.TextSize = 12
UseAnimButton.Font = Enum.Font.GothamBold
UseAnimButton.Parent = MainButtonsFrame

local UseAnimCorner = Instance.new("UICorner")
UseAnimCorner.CornerRadius = UDim.new(0, 8)
UseAnimCorner.Parent = UseAnimButton

-- Save/Load Walk Buttons
local SaveLoadFrame = Instance.new("Frame")
SaveLoadFrame.Size = UDim2.new(1, -20, 0, 35)
SaveLoadFrame.Position = UDim2.new(0, 10, 0, 200)
SaveLoadFrame.BackgroundTransparency = 1
SaveLoadFrame.Parent = MainFrame

local SaveWalkButton = Instance.new("TextButton")
SaveWalkButton.Name = "SaveWalkButton"
SaveWalkButton.Size = UDim2.new(0.48, 0, 1, 0)
SaveWalkButton.Position = UDim2.new(0, 0, 0, 0)
SaveWalkButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
SaveWalkButton.BorderSizePixel = 0
SaveWalkButton.Text = "💾 SAVE WALK"
SaveWalkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveWalkButton.TextSize = 12
SaveWalkButton.Font = Enum.Font.GothamBold
SaveWalkButton.Parent = SaveLoadFrame

local SaveWalkCorner = Instance.new("UICorner")
SaveWalkCorner.CornerRadius = UDim.new(0, 8)
SaveWalkCorner.Parent = SaveWalkButton

local LoadWalkButton = Instance.new("TextButton")
LoadWalkButton.Name = "LoadWalkButton"
LoadWalkButton.Size = UDim2.new(0.48, 0, 1, 0)
LoadWalkButton.Position = UDim2.new(0.52, 0, 0, 0)
LoadWalkButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
LoadWalkButton.BorderSizePixel = 0
LoadWalkButton.Text = "📂 LOAD WALK"
LoadWalkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadWalkButton.TextSize = 12
LoadWalkButton.Font = Enum.Font.GothamBold
LoadWalkButton.Parent = SaveLoadFrame

local LoadWalkCorner = Instance.new("UICorner")
LoadWalkCorner.CornerRadius = UDim.new(0, 8)
LoadWalkCorner.Parent = LoadWalkButton

-- Counter Label
local RecordingCounter = Instance.new("TextLabel")
RecordingCounter.Size = UDim2.new(1, -20, 0, 25)
RecordingCounter.Position = UDim2.new(0, 10, 0, 240)
RecordingCounter.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
RecordingCounter.BackgroundTransparency = 0.3
RecordingCounter.BorderSizePixel = 0
RecordingCounter.Text = "Recordings: 0/" .. MAX_RECORDINGS
RecordingCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordingCounter.TextSize = 12
RecordingCounter.Font = Enum.Font.GothamBold
RecordingCounter.Parent = MainFrame

local CounterCorner = Instance.new("UICorner")
CounterCorner.CornerRadius = UDim.new(0, 6)
CounterCorner.Parent = RecordingCounter

-- Scroll Frame untuk WALK CP buttons
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "WalkCPList"
ScrollFrame.Size = UDim2.new(1, -20, 1, -350)
ScrollFrame.Position = UDim2.new(0, 10, 0, 270)
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
EmptyLabel.Text = "No recordings yet!\n\nClick RECORD to start recording your movement"
EmptyLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
EmptyLabel.TextSize = 11
EmptyLabel.Font = Enum.Font.GothamBold
EmptyLabel.TextWrapped = true
EmptyLabel.Parent = ScrollFrame

-- Status Panel
local StatusPanel = Instance.new("Frame")
StatusPanel.Size = UDim2.new(1, -20, 0, 60)
StatusPanel.Position = UDim2.new(0, 10, 1, -70)
StatusPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusPanel.BackgroundTransparency = 0.3
StatusPanel.BorderSizePixel = 0
StatusPanel.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusPanel

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 0, 18)
StatusText.Position = UDim2.new(0, 5, 0, 3)
StatusText.BackgroundTransparency = 1
StatusText.Text = "📊 Status: Ready"
StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusText.TextSize = 11
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusPanel

local OrientationText = Instance.new("TextLabel")
OrientationText.Size = UDim2.new(1, -10, 0, 16)
OrientationText.Position = UDim2.new(0, 5, 0, 20)
OrientationText.BackgroundTransparency = 1
OrientationText.Text = "🧭 Orientation: Normal"
OrientationText.TextColor3 = Color3.fromRGB(255, 255, 255)
OrientationText.TextSize = 9
OrientationText.Font = Enum.Font.GothamBold
OrientationText.TextXAlignment = Enum.TextXAlignment.Left
OrientationText.Parent = StatusPanel

local AnimText = Instance.new("TextLabel")
AnimText.Size = UDim2.new(1, -10, 0, 16)
AnimText.Position = UDim2.new(0, 5, 0, 38)
AnimText.BackgroundTransparency = 1
AnimText.Text = "🎭 Animasi: Default"
AnimText.TextColor3 = Color3.fromRGB(200, 200, 255)
AnimText.TextSize = 9
AnimText.Font = Enum.Font.GothamBold
AnimText.TextXAlignment = Enum.TextXAlignment.Left
AnimText.Parent = StatusPanel

-- Fungsi untuk memulai recording
local function StartRecording()
    if IsRecording then return end
    
    IsRecording = true
    CurrentRecording = {
        positions = {},
        timestamps = {},
        startTime = tick()
    }
    
    ShowNotification("🔴 RECORDING STARTED", Color3.fromRGB(255, 0, 0))
    
    table.insert(CurrentRecording.positions, HumanoidRootPart.Position)
    table.insert(CurrentRecording.timestamps, 0)
    
    RecordConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not IsRecording or not HumanoidRootPart then return end
        
        local currentTime = tick() - CurrentRecording.startTime
        local currentPos = HumanoidRootPart.Position
        
        table.insert(CurrentRecording.positions, currentPos)
        table.insert(CurrentRecording.timestamps, currentTime)
    end)
end

-- Fungsi untuk menghentikan recording dan menyimpan
local function StopRecording()
    if not IsRecording then return end
    
    IsRecording = false
    if RecordConnection then
        RecordConnection:Disconnect()
        RecordConnection = nil
    end
    
    if #CurrentRecording.positions < 2 then
        ShowNotification("Recording too short", Color3.fromRGB(255, 50, 50))
        CurrentRecording = nil
        return
    end
    
    local recordingName = "WALK CP1"
    local index = 1
    while WalkRecordings[recordingName] and index <= MAX_RECORDINGS do
        index = index + 1
        recordingName = "WALK CP" .. index
    end
    
    if index > MAX_RECORDINGS then
        ShowNotification("Max recordings reached", Color3.fromRGB(255, 50, 50))
        CurrentRecording = nil
        return
    end
    
    WalkRecordings[recordingName] = CurrentRecording
    CurrentRecording = nil
    
    ShowNotification("Saved: " .. recordingName, Color3.fromRGB(0, 255, 0))
    RefreshWalkCPList()
end

-- Fungsi untuk detect state karakter
local function DetectCharacterState()
    if not Humanoid or not HumanoidRootPart then return "Idle" end
    
    local velocity = HumanoidRootPart.Velocity
    local isGrounded = Humanoid:GetState() == Enum.HumanoidStateType.Running or 
                      Humanoid:GetState() == Enum.HumanoidStateType.Walking
    
    local isClimbing = Humanoid:GetState() == Enum.HumanoidStateType.Climbing
    local isFalling = Humanoid:GetState() == Enum.HumanoidStateType.Freefall
    local isSwimming = Humanoid:GetState() == Enum.HumanoidStateType.Swimming
    local isJumping = Humanoid:GetState() == Enum.HumanoidStateType.Jumping
    
    -- Tentukan state
    if isSwimming then
        return velocity.Magnitude > 2 and "Swim" or "SwimIdle"
    elseif isClimbing then
        return velocity.Magnitude > 2 and "Climb" or "ClimbIdle"
    elseif isFalling then
        return "Fall"
    elseif isJumping then
        return "Jump"
    elseif not isGrounded then
        return "Jump"
    elseif velocity.Magnitude > 10 then
        return "Run"
    elseif velocity.Magnitude > 2 then
        return "Walk"
    else
        return "Idle"
    end
end

local function StartStateDetection()
    if StateDetectionConnection then return end
    
    StateDetectionConnection = RunService.Heartbeat:Connect(function()
        CurrentState = DetectCharacterState()
    end)
end

local function StopStateDetection()
    if StateDetectionConnection then
        StateDetectionConnection:Disconnect()
        StateDetectionConnection = nil
    end
end

-- Fungsi untuk memainkan animasi custom
local function PlayCustomAnimation()
    if not UseCustomAnim then return end
    
    -- Stop animasi sebelumnya
    if CurrentAnimTrack then
        CurrentAnimTrack:Stop()
        CurrentAnimTrack = nil
    end
    
    -- Tentukan animasi yang akan diputar
    local animName = CurrentState
    if not CUSTOM_ANIMATIONS[animName] then
        -- Fallback ke basic animation
        local velocity = HumanoidRootPart.Velocity.Magnitude
        if velocity > 10 then
            animName = "Run"
        elseif velocity > 2 then
            animName = "Walk"
        else
            animName = "Idle"
        end
    end
    
    -- Mainkan animasi
    if CUSTOM_ANIMATIONS[animName] then
        local animation = Instance.new("Animation")
        animation.AnimationId = CUSTOM_ANIMATIONS[animName]
        CurrentAnimTrack = Humanoid:LoadAnimation(animation)
        CurrentAnimTrack:Play()
    end
end

-- Fungsi untuk memainkan ulang rekaman
local function PlayWalkRecording(recordingName)
    if IsPlaying or not WalkRecordings[recordingName] then return end
    
    local recording = WalkRecordings[recordingName]
    if #recording.positions < 2 then return end
    
    IsPlaying = true
    IsPaused = false
    local startPlaybackTime = tick()
    local currentIndex = 1
    
    ShowNotification("Playing: " .. recordingName, Color3.fromRGB(0, 255, 0))
    
    -- Mainkan animasi custom jika aktif
    if UseCustomAnim then
        StartStateDetection()
        PlayCustomAnimation()
    end
    
    PlaybackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not IsPlaying or not HumanoidRootPart then
            if PlaybackConnection then PlaybackConnection:Disconnect() PlaybackConnection = nil end
            return
        end
        
        if IsPaused then return end
        
        local currentTime = tick() - startPlaybackTime
        
        while currentIndex < #recording.timestamps and recording.timestamps[currentIndex + 1] <= currentTime do
            currentIndex = currentIndex + 1
        end
        
        if currentIndex >= #recording.positions then
            StopPlayback()
            ShowNotification("✅ Playback Complete", Color3.fromRGB(0, 255, 0))
            return
        end
        
        local targetPos
        if currentIndex < #recording.positions then
            local nextIndex = currentIndex + 1
            local timeDiff = recording.timestamps[nextIndex] - recording.timestamps[currentIndex]
            local progress = 0
            
            if timeDiff > 0 then
                progress = (currentTime - recording.timestamps[currentIndex]) / timeDiff
                if progress > 1 then progress = 1 end
            end
            
            targetPos = recording.positions[currentIndex]:Lerp(
                recording.positions[nextIndex], 
                progress
            )
        else
            targetPos = recording.positions[currentIndex]
        end
        
        -- Gunakan BodyPosition untuk animasi natural
        if targetPos then
            local oldBodyPosition = HumanoidRootPart:FindFirstChild("WalkRecorderBodyPosition")
            if oldBodyPosition then
                oldBodyPosition:Destroy()
            end
            
            local bodyPosition = Instance.new("BodyPosition")
            bodyPosition.Name = "WalkRecorderBodyPosition"
            bodyPosition.Position = targetPos
            bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
            bodyPosition.P = 10000
            bodyPosition.Parent = HumanoidRootPart
            
            -- Update animasi
            if UseCustomAnim then
                PlayCustomAnimation()
            end
            
            if ReverseOrientation then
                HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0, math.pi, 0)
            end
        end
    end)
end

-- Fungsi untuk menghentikan playback
local function StopPlayback()
    IsPlaying = false
    IsPaused = false
    
    if PlaybackConnection then
        PlaybackConnection:Disconnect()
        PlaybackConnection = nil
    end
    
    -- Hapus BodyPosition
    if HumanoidRootPart then
        local bodyPosition = HumanoidRootPart:FindFirstChild("WalkRecorderBodyPosition")
        if bodyPosition then
            bodyPosition:Destroy()
        end
    end
    
    -- Stop state detection
    StopStateDetection()
    
    -- Stop animasi
    if CurrentAnimTrack then
        CurrentAnimTrack:Stop()
        CurrentAnimTrack = nil
    end
end

-- Fungsi untuk pause/lanjutkan playback
local function TogglePause()
    if not IsPlaying then return end
    
    IsPaused = not IsPaused
    if IsPaused and CurrentAnimTrack then
        CurrentAnimTrack:AdjustSpeed(0)
    elseif CurrentAnimTrack then
        CurrentAnimTrack:AdjustSpeed(1)
    end
end

-- Fungsi save/load
local function SaveWalkToFile()
    local success, result = pcall(function()
        local data = {}
        for name, recording in pairs(WalkRecordings) do
            data[name] = {
                positions = {},
                timestamps = recording.timestamps
            }
            for _, pos in ipairs(recording.positions) do
                table.insert(data[name].positions, {X = pos.X, Y = pos.Y, Z = pos.Z})
            end
        end
        local encoded = HttpService:JSONEncode(data)
        writefile(SAVE_FILE_NAME .. ".json", encoded)
        return true
    end)
    
    if success and result then
        ShowNotification("All recordings saved", Color3.fromRGB(0, 255, 0))
        return true
    else
        ShowNotification("Save failed", Color3.fromRGB(255, 50, 50))
        return false
    end
end

local function LoadWalkFromFile()
    local success, result = pcall(function()
        if not isfile(SAVE_FILE_NAME .. ".json") then
            return nil
        end
        local content = readfile(SAVE_FILE_NAME .. ".json")
        local data = HttpService:JSONDecode(content)
        return data
    end)
    
    if success and result then
        WalkRecordings = {}
        for name, recordingData in pairs(result) do
            local positions = {}
            for _, pos in ipairs(recordingData.positions) do
                table.insert(positions, Vector3.new(pos.X, pos.Y, pos.Z))
            end
            WalkRecordings[name] = {
                positions = positions,
                timestamps = recordingData.timestamps
            }
        end
        RefreshWalkCPList()
        ShowNotification("Loaded recordings", Color3.fromRGB(0, 255, 0))
        return true
    else
        ShowNotification("Load failed", Color3.fromRGB(255, 50, 50))
        return false
    end
end

-- Fungsi untuk membuat tombol WALK CP
local function CreateWalkCPButton(recordingName, recordingData)
    local Button = Instance.new("TextButton")
    Button.Name = recordingName
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
    TitleLabel.Size = UDim2.new(1, -10, 0, 20)
    TitleLabel.Position = UDim2.new(0, 5, 0, 5)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "🚶 " .. recordingName
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 12
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Button
    
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -10, 0, 15)
    InfoLabel.Position = UDim2.new(0, 5, 0, 25)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = string.format("Points: %d | Duration: %.1fs", 
        #recordingData.positions, 
        recordingData.timestamps[#recordingData.timestamps] or 0)
    InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    InfoLabel.TextSize = 9
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.Parent = Button
    
    local DeleteBtn = Instance.new("TextButton")
    DeleteBtn.Size = UDim2.new(0, 25, 0, 25)
    DeleteBtn.Position = UDim2.new(1, -30, 0, 12.5)
    DeleteBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    DeleteBtn.BorderSizePixel = 0
    DeleteBtn.Text = "🗑️"
    DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DeleteBtn.TextSize = 12
    DeleteBtn.Font = Enum.Font.GothamBold
    DeleteBtn.Parent = Button
    
    local DelCorner = Instance.new("UICorner")
    DelCorner.CornerRadius = UDim.new(0, 6)
    DelCorner.Parent = DeleteBtn
    
    Button.MouseButton1Click:Connect(function()
        if IsPlaying then
            StopPlayback()
            wait(0.1)
        end
        PlayWalkRecording(recordingName)
    end)
    
    DeleteBtn.MouseButton1Click:Connect(function()
        local ConfirmFrame = Instance.new("Frame")
        ConfirmFrame.Size = UDim2.new(0, 250, 0, 120)
        ConfirmFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
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
        ConfirmTitle.Text = "⚠️ Konfirmasi Hapus"
        ConfirmTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
        ConfirmTitle.TextSize = 14
        ConfirmTitle.Font = Enum.Font.GothamBold
        ConfirmTitle.Parent = ConfirmFrame
        
        local ConfirmText = Instance.new("TextLabel")
        ConfirmText.Size = UDim2.new(1, -20, 0, 40)
        ConfirmText.Position = UDim2.new(0, 10, 0, 35)
        ConfirmText.BackgroundTransparency = 1
        ConfirmText.Text = "Apakah kamu yakin ingin menghapus:\n" .. recordingName .. "?"
        ConfirmText.TextColor3 = Color3.fromRGB(200, 200, 200)
        ConfirmText.TextSize = 11
        ConfirmText.Font = Enum.Font.Gotham
        ConfirmText.TextWrapped = true
        ConfirmText.Parent = ConfirmFrame
        
        local YesButton = Instance.new("TextButton")
        YesButton.Size = UDim2.new(0.4, 0, 0, 30)
        YesButton.Position = UDim2.new(0.1, 0, 0, 80)
        YesButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        YesButton.BorderSizePixel = 0
        YesButton.Text = "✓ YA"
        YesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        YesButton.TextSize = 12
        YesButton.Font = Enum.Font.GothamBold
        YesButton.Parent = ConfirmFrame
        
        local NoButton = Instance.new("TextButton")
        NoButton.Size = UDim2.new(0.4, 0, 0, 30)
        NoButton.Position = UDim2.new(0.5, 0, 0, 80)
        NoButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        NoButton.BorderSizePixel = 0
        NoButton.Text = "✗ TIDAK"
        NoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        NoButton.TextSize = 12
        NoButton.Font = Enum.Font.GothamBold
        NoButton.Parent = ConfirmFrame
        
        YesButton.MouseButton1Click:Connect(function()
            WalkRecordings[recordingName] = nil
            RefreshWalkCPList()
            ConfirmFrame:Destroy()
        end)
        
        NoButton.MouseButton1Click:Connect(function()
            ConfirmFrame:Destroy()
        end)
    end)
    
    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(255, 120, 20)
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

-- Fungsi refresh list WALK CP
function RefreshWalkCPList()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local recordingCount = 0
    for name, recording in pairs(WalkRecordings) do
        recordingCount = recordingCount + 1
        CreateWalkCPButton(name, recording)
    end
    
    RecordingCounter.Text = "Recordings: " .. recordingCount .. "/" .. MAX_RECORDINGS
    
    if recordingCount == 0 then
        EmptyLabel.Visible = true
    else
        EmptyLabel.Visible = false
    end
end

-- Fungsi notification
function ShowNotification(text, color)
    color = color or Color3.fromRGB(0, 155, 0)
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 300, 0, 60)
    NotifFrame.Position = UDim2.new(0.5, -150, 0, -70)
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
    NotifText.TextSize = 12
    NotifText.Font = Enum.Font.GothamBold
    NotifText.TextWrapped = true
    NotifText.Parent = NotifFrame
    
    NotifFrame:TweenPosition(UDim2.new(0.5, -150, 0, 10), "Out", "Quad", 0.3, true)
    
    spawn(function()
        wait(2)
        NotifFrame:TweenPosition(UDim2.new(0.5, -150, 0, -70), "In", "Quad", 0.3, true)
        wait(0.3)
        NotifFrame:Destroy()
    end)
end

-- Event handlers
MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinimizeIcon.Visible = true
end)

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

RecordSaveButton.MouseButton1Click:Connect(function()
    if not IsRecording then
        StartRecording()
        RecordSaveButton.Text = "💾 SAVE"
        RecordSaveButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    else
        StopRecording()
        RecordSaveButton.Text = "🔴 RECORD"
        RecordSaveButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    end
end)

PauseResumeButton.MouseButton1Click:Connect(function()
    if IsPlaying then
        TogglePause()
        if IsPaused then
            PauseResumeButton.Text = "▶️ LANJUTKAN"
            PauseResumeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        else
            PauseResumeButton.Text = "⏸️ PAUSE"
            PauseResumeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
end)

ReverseButton.MouseButton1Click:Connect(function()
    ReverseOrientation = not ReverseOrientation
    
    if ReverseOrientation then
        ReverseButton.Text = "🔄 NORMAL"
        ReverseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0, math.pi, 0)
        end
    else
        ReverseButton.Text = "🔄 BALIK BADAN"
        ReverseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0, math.pi, 0)
        end
    end
end)

UseAnimButton.MouseButton1Click:Connect(function()
    UseCustomAnim = not UseCustomAnim
    
    if UseCustomAnim then
        UseAnimButton.Text = "🎭 ANIMASI CUSTOM: ON"
        UseAnimButton.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
        ShowNotification("Animasi Custom: ON", Color3.fromRGB(150, 0, 255))
    else
        UseAnimButton.Text = "🎭 GUNAKAN ANIMASI CUSTOM"
        UseAnimButton.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
        ShowNotification("Animasi Custom: OFF", Color3.fromRGB(100, 0, 200))
        
        -- Stop animasi jika sedang bermain
        if CurrentAnimTrack then
            CurrentAnimTrack:Stop()
            CurrentAnimTrack = nil
        end
        StopStateDetection()
    end
end)

SaveWalkButton.MouseButton1Click:Connect(function()
    if next(WalkRecordings) == nil then return end
    SaveWalkToFile()
end)

LoadWalkButton.MouseButton1Click:Connect(function()
    LoadWalkFromFile()
end)

-- Update status
spawn(function()
    while wait(0.5) do
        if IsRecording then
            StatusText.Text = "📊 Status: Recording..."
            StatusText.TextColor3 = Color3.fromRGB(255, 0, 0)
        elseif IsPlaying then
            if IsPaused then
                StatusText.Text = "📊 Status: Playback Paused"
                StatusText.TextColor3 = Color3.fromRGB(255, 200, 0)
            else
                StatusText.Text = "📊 Status: Playing Back"
                StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
        else
            StatusText.Text = "📊 Status: Ready"
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
        end
        
        if ReverseOrientation then
            OrientationText.Text = "🧭 Orientation: Reversed"
        else
            OrientationText.Text = "🧭 Orientation: Normal"
        end
        
        if UseCustomAnim then
            AnimText.Text = "🎭 Animasi: Custom"
        else
            AnimText.Text = "🎭 Animasi: Default"
        end
    end
end)

-- Cleanup
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 10)
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    
    -- Reload animasi untuk karakter baru
    LoadAnimations()
    
    StopPlayback()
    if IsRecording then
        StopRecording()
        RecordSaveButton.Text = "🔴 RECORD"
        RecordSaveButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    end
end)

-- Auto-load
spawn(function()
    wait(1)
    if isfile and isfile(SAVE_FILE_NAME .. ".json") then
        LoadWalkFromFile()
    end
end)

print("🚶 AUTO WALK RECORDER + ANIMASI CUSTOM LOADED!")
