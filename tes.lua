local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

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
local WalkRecordings = {} -- {["WALK CP1"] = {positions = {Vector3,...}, timestamps = {number,...}}}
local CurrentRecording = nil
local IsRecording = false
local IsPlaying = false
local IsPaused = false
local ReverseOrientation = false
local PlaybackConnection = nil
local RecordConnection = nil
local MAX_RECORDINGS = 20
local RECORDING_INTERVAL = 0.1 -- Detik antara setiap pencatatan posisi
local SAVE_FILE_NAME = "AutoWalkRecorder_Saves"

-- Forward declarations
local ShowNotification
local RefreshWalkCPList
local SaveWalkToFile
local LoadWalkFromFile
local StartRecording
local StopRecording
local PlayWalkRecording
local StopPlayback

-- Fungsi untuk memulai recording
function StartRecording()
    if IsRecording then return end
    
    IsRecording = true
    CurrentRecording = {
        positions = {},
        timestamps = {},
        startTime = tick()
    }
    
    ShowNotification("🔴 RECORDING STARTED", Color3.fromRGB(255, 0, 0))
    
    -- Catat posisi awal
    table.insert(CurrentRecording.positions, HumanoidRootPart.Position)
    table.insert(CurrentRecording.timestamps, 0)
    
    -- Connection untuk mencatat pergerakan
    RecordConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not IsRecording or not HumanoidRootPart then return end
        
        local currentTime = tick() - CurrentRecording.startTime
        local currentPos = HumanoidRootPart.Position
        local lastPos = CurrentRecording.positions[#CurrentRecording.positions]
        
        -- Hanya catat jika posisi berubah signifikan
        if lastPos and (currentPos - lastPos).Magnitude > 0.5 then
            table.insert(CurrentRecording.positions, currentPos)
            table.insert(CurrentRecording.timestamps, currentTime)
        end
    end)
end

-- Fungsi untuk menghentikan recording dan menyimpan
function StopRecording()
    if not IsRecording then return end
    
    IsRecording = false
    if RecordConnection then
        RecordConnection:Disconnect()
        RecordConnection = nil
    end
    
    if #CurrentRecording.positions < 2 then
        ShowNotification("❌ Recording too short!", Color3.fromRGB(255, 50, 50))
        CurrentRecording = nil
        return
    end
    
    -- Cari nama yang tersedia
    local recordingName = "WALK CP1"
    local index = 1
    while WalkRecordings[recordingName] and index <= MAX_RECORDINGS do
        index = index + 1
        recordingName = "WALK CP" .. index
    end
    
    if index > MAX_RECORDINGS then
        ShowNotification("❌ Maximum recordings reached!", Color3.fromRGB(255, 50, 50))
        CurrentRecording = nil
        return
    end
    
    -- Simpan recording
    WalkRecordings[recordingName] = CurrentRecording
    CurrentRecording = nil
    
    ShowNotification("💾 Saved as: " .. recordingName, Color3.fromRGB(0, 255, 0))
    RefreshWalkCPList()
end

-- Fungsi untuk memainkan ulang rekaman
function PlayWalkRecording(recordingName)
    if IsPlaying or not WalkRecordings[recordingName] then return end
    
    local recording = WalkRecordings[recordingName]
    if #recording.positions < 2 then return end
    
    IsPlaying = true
    IsPaused = false
    local startPlaybackTime = tick()
    local currentIndex = 1
    
    ShowNotification("▶️ PLAYING: " .. recordingName, Color3.fromRGB(0, 255, 0))
    
    -- Enable NoClip selama playback
    local NoClipConnection = RunService.Stepped:Connect(function()
        pcall(function()
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end)
    
    PlaybackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not IsPlaying or not HumanoidRootPart then
            if PlaybackConnection then PlaybackConnection:Disconnect() PlaybackConnection = nil end
            if NoClipConnection then NoClipConnection:Disconnect() NoClipConnection = nil end
            return
        end
        
        if IsPaused then return end
        
        local currentTime = tick() - startPlaybackTime
        
        -- Cari posisi berikutnya berdasarkan waktu
        while currentIndex < #recording.timestamps and recording.timestamps[currentIndex + 1] <= currentTime do
            currentIndex = currentIndex + 1
        end
        
        if currentIndex >= #recording.positions then
            -- Selesai playback
            StopPlayback()
            ShowNotification("✅ Playback Complete: " .. recordingName, Color3.fromRGB(0, 255, 0))
            return
        end
        
        -- Interpolasi posisi
        local targetPos
        if currentIndex < #recording.positions then
            local nextIndex = currentIndex + 1
            local timeDiff = recording.timestamps[nextIndex] - recording.timestamps[currentIndex]
            local progress = (currentTime - recording.timestamps[currentIndex]) / timeDiff
            
            if progress > 1 then progress = 1 end
            
            targetPos = recording.positions[currentIndex]:Lerp(
                recording.positions[nextIndex], 
                progress
            )
        else
            targetPos = recording.positions[currentIndex]
        end
        
        -- Terapkan posisi dengan orientasi
        if targetPos then
            local currentCFrame = HumanoidRootPart.CFrame
            local lookDirection = (targetPos - currentCFrame.Position).Unit
            
            if ReverseOrientation then
                -- Balik orientasi
                HumanoidRootPart.CFrame = CFrame.new(targetPos, targetPos - lookDirection)
            else
                -- Orientasi normal
                HumanoidRootPart.CFrame = CFrame.new(targetPos, targetPos + lookDirection)
            end
        end
    end)
end

-- Fungsi untuk menghentikan playback
function StopPlayback()
    IsPlaying = false
    IsPaused = false
    
    if PlaybackConnection then
        PlaybackConnection:Disconnect()
        PlaybackConnection = nil
    end
    
    -- Disable NoClip
    pcall(function()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
        if HumanoidRootPart then
            HumanoidRootPart.CanCollide = false
        end
    end)
end

-- Fungsi untuk pause/lanjutkan playback
local function TogglePause()
    if not IsPlaying then return end
    
    IsPaused = not IsPaused
    if IsPaused then
        ShowNotification("⏸️ PLAYBACK PAUSED", Color3.fromRGB(255, 200, 0))
    else
        ShowNotification("▶️ PLAYBACK RESUMED", Color3.fromRGB(0, 255, 0))
    end
end

-- Fungsi save/load
function SaveWalkToFile()
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
        ShowNotification("💾 All recordings saved!", Color3.fromRGB(0, 255, 0))
        return true
    else
        ShowNotification("❌ Save failed!", Color3.fromRGB(255, 50, 50))
        return false
    end
end

function LoadWalkFromFile()
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
        ShowNotification("📂 Loaded " .. #WalkRecordings .. " recordings!", Color3.fromRGB(0, 255, 0))
        return true
    elseif not success then
        ShowNotification("❌ Load failed!", Color3.fromRGB(255, 50, 50))
        return false
    else
        ShowNotification("📂 No save file found", Color3.fromRGB(255, 200, 0))
        return false
    end
end

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WalkRecorderGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

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
Title.Position = UDim2.new(0, 20, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "🚶 AUTO WALK RECORDER"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Tombol Utama (Record/Save, Pause/Lanjutkan, Balik Badan/Normal)
local MainButtonsFrame = Instance.new("Frame")
MainButtonsFrame.Size = UDim2.new(1, -20, 0, 120)
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

-- Save/Load Walk Buttons
local SaveLoadFrame = Instance.new("Frame")
SaveLoadFrame.Size = UDim2.new(1, -20, 0, 35)
SaveLoadFrame.Position = UDim2.new(0, 10, 0, 170)
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
RecordingCounter.Position = UDim2.new(0, 10, 0, 210)
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
ScrollFrame.Size = UDim2.new(1, -20, 1, -300)
ScrollFrame.Position = UDim2.new(0, 10, 0, 240)
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
StatusPanel.Size = UDim2.new(1, -20, 0, 45)
StatusPanel.Position = UDim2.new(0, 10, 1, -55)
StatusPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusPanel.BackgroundTransparency = 0.3
StatusPanel.BorderSizePixel = 0
StatusPanel.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusPanel

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 0, 20)
StatusText.Position = UDim2.new(0, 5, 0, 3)
StatusText.BackgroundTransparency = 1
StatusText.Text = "📊 Status: Ready"
StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusText.TextSize = 11
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusPanel

local OrientationText = Instance.new("TextLabel")
OrientationText.Size = UDim2.new(1, -10, 0, 18)
OrientationText.Position = UDim2.new(0, 5, 0, 22)
OrientationText.BackgroundTransparency = 1
OrientationText.Text = "🧭 Orientation: Normal"
OrientationText.TextColor3 = Color3.fromRGB(255, 255, 255)
OrientationText.TextSize = 9
OrientationText.Font = Enum.Font.GothamBold
OrientationText.TextXAlignment = Enum.TextXAlignment.Left
OrientationText.Parent = StatusPanel

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
    
    -- Event handlers
    Button.MouseButton1Click:Connect(function()
        if IsPlaying then
            StopPlayback()
            wait(0.1)
        end
        PlayWalkRecording(recordingName)
    end)
    
    DeleteBtn.MouseButton1Click:Connect(function()
        WalkRecordings[recordingName] = nil
        RefreshWalkCPList()
        ShowNotification("🗑️ Deleted: " .. recordingName, Color3.fromRGB(255, 100, 0))
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

-- Event handlers untuk tombol utama
RecordSaveButton.MouseButton1Click:Connect(function()
    if not IsRecording then
        -- Mulai recording
        StartRecording()
        RecordSaveButton.Text = "💾 SAVE"
        RecordSaveButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    else
        -- Stop dan save recording
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
    else
        ShowNotification("❌ No playback active!", Color3.fromRGB(255, 50, 50))
    end
end)

ReverseButton.MouseButton1Click:Connect(function()
    ReverseOrientation = not ReverseOrientation
    if ReverseOrientation then
        ReverseButton.Text = "🔄 NORMAL"
        ReverseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        OrientationText.Text = "🧭 Orientation: Reversed"
        ShowNotification("🔄 Orientation: REVERSED", Color3.fromRGB(255, 100, 0))
    else
        ReverseButton.Text = "🔄 BALIK BADAN"
        ReverseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        OrientationText.Text = "🧭 Orientation: Normal"
        ShowNotification("🧭 Orientation: NORMAL", Color3.fromRGB(0, 255, 0))
    end
end)

SaveWalkButton.MouseButton1Click:Connect(function()
    if next(WalkRecordings) == nil then
        ShowNotification("❌ No recordings to save!", Color3.fromRGB(255, 50, 50))
        return
    end
    
    SaveWalkButton.BackgroundColor3 = Color3.fromRGB(0, 80, 160)
    SaveWalkToFile()
    wait(0.5)
    SaveWalkButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
end)

LoadWalkButton.MouseButton1Click:Connect(function()
    LoadWalkButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    LoadWalkFromFile()
    wait(0.5)
    LoadWalkButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
end)

-- Fungsi notification
function ShowNotification(text, color)
    color = color or Color3.fromRGB(0, 155, 0)
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 280, 0, 60)
    NotifFrame.Position = UDim2.new(0.5, -140, 0, -70)
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
    
    NotifFrame:TweenPosition(UDim2.new(0.5, -140, 0, 10), "Out", "Quad", 0.3, true)
    
    spawn(function()
        wait(3)
        NotifFrame:TweenPosition(UDim2.new(0.5, -140, 0, -70), "In", "Quad", 0.3, true)
        wait(0.3)
        NotifFrame:Destroy()
    end)
end

-- Update status secara real-time
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
    end
end)

-- Cleanup saat karakter berubah
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 10)
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    StopPlayback()
    if IsRecording then
        StopRecording()
        RecordSaveButton.Text = "🔴 RECORD"
        RecordSaveButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    end
end)

-- Auto-load saat start
spawn(function()
    wait(1)
    if isfile and isfile(SAVE_FILE_NAME .. ".json") then
        ShowNotification("📂 Auto-loading recordings...", Color3.fromRGB(0, 150, 255))
        LoadWalkFromFile()
    end
end)

print("============================================")
print("🚶 AUTO WALK RECORDER LOADED!")
print("============================================")
print("✓ Record & Playback System")
print("✓ Pause/Resume Functionality") 
print("✓ Reverse Orientation Mode")
print("✓ Save/Load All Recordings")
print("✓ Up to 20 walk recordings")
print("============================================")
print("📝 HOW TO USE:")
print("1. RECORD - Start recording movement")
print("2. SAVE - Stop and save as WALK CP")
print("3. Click WALK CP button to play back")
print("4. PAUSE - Pause/resume playback")
print("5. BALIK BADAN - Reverse orientation")
print("6. SAVE WALK - Save all to file")
print("7. LOAD WALK - Load from file")
print("============================================")
