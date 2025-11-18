-- AUTO WALK RECORDER - RECORD SYSTEM
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Hapus GUI lama jika ada
if player.PlayerGui:FindFirstChild("RecordGUI") then
    player.PlayerGui:FindFirstChild("RecordGUI"):Destroy()
end

-- Variabel recording
local IsRecording = false
local RecordConnection = nil
local CurrentRecording = {
    positions = {},
    timestamps = {},
    states = {}
}

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RecordGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 120)
MainFrame.Position = UDim2.new(0.5, -125, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔴 AUTO WALK RECORDER"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Record Button
local RecordButton = Instance.new("TextButton")
RecordButton.Size = UDim2.new(0.8, 0, 0, 35)
RecordButton.Position = UDim2.new(0.1, 0, 0, 35)
RecordButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
RecordButton.BorderSizePixel = 0
RecordButton.Text = "⏺️ RECORD"
RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordButton.TextSize = 14
RecordButton.Font = Enum.Font.GothamBold
RecordButton.Parent = MainFrame

local RecordCorner = Instance.new("UICorner")
RecordCorner.CornerRadius = UDim.new(0, 6)
RecordCorner.Parent = RecordButton

-- Save Button
local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0.8, 0, 0, 35)
SaveButton.Position = UDim2.new(0.1, 0, 0, 75)
SaveButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
SaveButton.BorderSizePixel = 0
SaveButton.Text = "💾 SAVE JSON"
SaveButton.TextColor3 = Color3.fromRGB(0, 0, 0)
SaveButton.TextSize = 14
SaveButton.Font = Enum.Font.GothamBold
SaveButton.Parent = MainFrame

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 6)
SaveCorner.Parent = SaveButton

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0, 115)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- Fungsi recording
local function StartRecording()
    if IsRecording then return end
    
    IsRecording = true
    CurrentRecording = {
        positions = {},
        timestamps = {},
        states = {},
        startTime = tick()
    }
    
    StatusLabel.Text = "Status: 🔴 RECORDING..."
    RecordButton.Text = "⏹️ STOP RECORD"
    RecordButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    
    -- Record posisi pertama
    table.insert(CurrentRecording.positions, {
        X = rootPart.Position.X,
        Y = rootPart.Position.Y, 
        Z = rootPart.Position.Z
    })
    table.insert(CurrentRecording.timestamps, 0)
    table.insert(CurrentRecording.states, "Start")
    
    -- Mulai recording
    RecordConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not IsRecording or not rootPart then return end
        
        local currentTime = tick() - CurrentRecording.startTime
        local currentPos = rootPart.Position
        
        table.insert(CurrentRecording.positions, {
            X = currentPos.X,
            Y = currentPos.Y,
            Z = currentPos.Z
        })
        table.insert(CurrentRecording.timestamps, currentTime)
        
        -- Deteksi state
        local state = "Walking"
        if humanoid.MoveDirection.Magnitude < 0.1 then
            state = "Idle"
        end
        table.insert(CurrentRecording.states, state)
    end)
end

local function StopRecording()
    if not IsRecording then return end
    
    IsRecording = false
    if RecordConnection then
        RecordConnection:Disconnect()
        RecordConnection = nil
    end
    
    StatusLabel.Text = "Status: Recording Stopped"
    RecordButton.Text = "⏺️ RECORD"
    RecordButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
end

-- Fungsi save ke JSON
local function SaveToJSON()
    if #CurrentRecording.positions < 2 then
        StatusLabel.Text = "Status: No recording data!"
        return
    end
    
    local success, result = pcall(function()
        local recordingData = {
            recordingName = "AutoWalk_Recording",
            points = #CurrentRecording.positions,
            duration = CurrentRecording.timestamps[#CurrentRecording.timestamps],
            data = {
                positions = CurrentRecording.positions,
                timestamps = CurrentRecording.timestamps,
                states = CurrentRecording.states
            }
        }
        
        local jsonString = HttpService:JSONEncode(recordingData)
        
        -- Simpan ke file atau set clipboard (sesuai executor)
        if writefile then
            writefile("AutoWalk_Recording.json", jsonString)
            StatusLabel.Text = "Status: ✅ Saved to file!"
        else
            -- Untuk executor tanpa writefile, tampilkan di console
            print("=== AUTO WALK RECORDING DATA ===")
            print(jsonString)
            print("=== COPY DATA DI ATAS ===")
            StatusLabel.Text = "Status: ✅ Check console for data!"
        end
        
        return jsonString
    end)
    
    if not success then
        StatusLabel.Text = "Status: ❌ Save failed!"
    end
end

-- Event handlers
RecordButton.MouseButton1Click:Connect(function()
    if not IsRecording then
        StartRecording()
    else
        StopRecording()
    end
end)

SaveButton.MouseButton1Click:Connect(function()
    SaveToJSON()
end)

-- Auto cleanup
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    
    if IsRecording then
        StopRecording()
    end
end)

print("🎯 AUTO WALK RECORDER LOADED!")
print("1. Click RECORD to start recording")
print("2. Move around to record your path") 
print("3. Click SAVE JSON to get recording data")
