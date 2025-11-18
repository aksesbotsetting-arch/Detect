-- AUTO WALK RECORDER - RECORD SYSTEM WITH SPEED LOCK
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
local SpeedConnection = nil
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
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title Bar (untuk drag)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 25)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
TitleBar.BackgroundTransparency = 0.9
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔴 RECORDER - SPEED LOCK 32"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -25, 0, 2)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 12
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseButton

-- Button Container
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, 0, 0, 110)
ButtonContainer.Position = UDim2.new(0, 0, 0, 30)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

-- Record Button
local RecordButton = Instance.new("TextButton")
RecordButton.Size = UDim2.new(0.8, 0, 0, 30)
RecordButton.Position = UDim2.new(0.1, 0, 0, 0)
RecordButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
RecordButton.BorderSizePixel = 0
RecordButton.Text = "⏺️ RECORD (SPEED 32)"
RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordButton.TextSize = 12
RecordButton.Font = Enum.Font.GothamBold
RecordButton.Parent = ButtonContainer

local RecordCorner = Instance.new("UICorner")
RecordCorner.CornerRadius = UDim.new(0, 6)
RecordCorner.Parent = RecordButton

-- Save Button
local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0.8, 0, 0, 30)
SaveButton.Position = UDim2.new(0.1, 0, 0, 35)
SaveButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
SaveButton.BorderSizePixel = 0
SaveButton.Text = "💾 SAVE JSON"
SaveButton.TextColor3 = Color3.fromRGB(0, 0, 0)
SaveButton.TextSize = 12
SaveButton.Font = Enum.Font.GothamBold
SaveButton.Parent = ButtonContainer

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 6)
SaveCorner.Parent = SaveButton

-- Delete Button
local DeleteButton = Instance.new("TextButton")
DeleteButton.Size = UDim2.new(0.8, 0, 0, 25)
DeleteButton.Position = UDim2.new(0.1, 0, 0, 70)
DeleteButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
DeleteButton.BorderSizePixel = 0
DeleteButton.Text = "🗑️ DELETE JSON"
DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeleteButton.TextSize = 11
DeleteButton.Font = Enum.Font.GothamBold
DeleteButton.Parent = ButtonContainer

local DeleteCorner = Instance.new("UICorner")
DeleteCorner.CornerRadius = UDim.new(0, 6)
DeleteCorner.Parent = DeleteButton

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0, 135)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Ready - Speed will lock to 32"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- Minimize Icon
local MinimizeIcon = Instance.new("ImageButton")
MinimizeIcon.Name = "MinimizeIcon"
MinimizeIcon.Size = UDim2.new(0, 40, 0, 40)
MinimizeIcon.Position = UDim2.new(0, 20, 0, 20)
MinimizeIcon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MinimizeIcon.BackgroundTransparency = 0.3
MinimizeIcon.BorderSizePixel = 0
MinimizeIcon.Visible = false
MinimizeIcon.Image = "rbxassetid://110225912398772"
MinimizeIcon.ScaleType = Enum.ScaleType.Fit
MinimizeIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 8)
IconCorner.Parent = MinimizeIcon

-- Fungsi apply speed lock 32
local function ApplySpeedLock()
    if not rootPart then return end
    
    -- Hapus velocity lama
    local oldVelocity = rootPart:FindFirstChild("RecordSpeedLock")
    if oldVelocity then oldVelocity:Destroy() end
    
    -- Buat velocity untuk speed lock
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "RecordSpeedLock"
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000) -- X dan Z saja
    bodyVelocity.P = 1000
    bodyVelocity.Parent = rootPart
    
    -- Terus update velocity ke arah movement
    SpeedConnection = RunService.Heartbeat:Connect(function()
        if not IsRecording or not rootPart then return end
        
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0.1 then
            bodyVelocity.Velocity = moveDirection.Unit * 32 -- SPEED LOCK 32
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function RemoveSpeedLock()
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end
    
    if rootPart then
        local velocity = rootPart:FindFirstChild("RecordSpeedLock")
        if velocity then velocity:Destroy() end
    end
end

-- Fungsi recording
local function StartRecording()
    if IsRecording then return end
    
    IsRecording = true
    
    -- Apply speed lock 32
    ApplySpeedLock()
    
    CurrentRecording = {
        positions = {},
        timestamps = {},
        states = {},
        startTime = tick()
    }
    
    StatusLabel.Text = "Status: 🔴 RECORDING (Speed 32)"
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
        local state = humanoid.MoveDirection.Magnitude > 0.1 and "Walking" or "Idle"
        table.insert(CurrentRecording.states, state)
        
        -- Update status
        StatusLabel.Text = string.format("Recording: %d points - %.1fs (Speed 32)", 
            #CurrentRecording.positions, currentTime)
    end)
end

local function StopRecording()
    if not IsRecording then return end
    
    IsRecording = false
    
    -- Remove speed lock
    RemoveSpeedLock()
    
    if RecordConnection then
        RecordConnection:Disconnect()
        RecordConnection = nil
    end
    
    StatusLabel.Text = string.format("Status: Stopped - %d points (Speed 32)", 
        #CurrentRecording.positions)
    RecordButton.Text = "⏺️ RECORD (SPEED 32)"
    RecordButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
end

-- Fungsi save ke JSON
local function SaveToJSON()
    if #CurrentRecording.positions < 2 then
        StatusLabel.Text = "Status: No recording data!"
        return nil
    end
    
    local success, result = pcall(function()
        local recordingData = {
            recordingName = "AutoWalk_Speed32",
            points = #CurrentRecording.positions,
            duration = CurrentRecording.timestamps[#CurrentRecording.timestamps],
            speedLock = 32, -- Tandai bahwa ini recording dengan speed 32
            data = {
                positions = CurrentRecording.positions,
                timestamps = CurrentRecording.timestamps,
                states = CurrentRecording.states
            }
        }
        
        local jsonString = HttpService:JSONEncode(recordingData)
        
        -- Simpan ke file
        if writefile then
            writefile("AutoWalk_Speed32.json", jsonString)
            StatusLabel.Text = "Status: ✅ Saved to file! (Speed 32)"
        else
            print("=== AUTO WALK RECORDING DATA (SPEED 32) ===")
            print(jsonString)
            print("=== COPY DATA DI ATAS ===")
            StatusLabel.Text = "Status: ✅ Check console! (Speed 32)"
        end
        
        return jsonString
    end)
    
    if not success then
        StatusLabel.Text = "Status: ❌ Save failed!"
        return nil
    end
    
    return result
end

-- Fungsi delete JSON
local function DeleteJSON()
    if readfile and isfile then
        if isfile("AutoWalk_Speed32.json") then
            delfile("AutoWalk_Speed32.json")
            StatusLabel.Text = "Status: 🗑️ JSON file deleted!"
            
            CurrentRecording = {
                positions = {},
                timestamps = {}, 
                states = {}
            }
        else
            StatusLabel.Text = "Status: No JSON file found!"
        end
    else
        StatusLabel.Text = "Status: Delete not supported!"
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

DeleteButton.MouseButton1Click:Connect(function()
    DeleteJSON()
end)

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinimizeIcon.Visible = true
end)

MinimizeIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizeIcon.Visible = false
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
print("🚀 SPEED LOCK 32 ACTIVE during recording")
print("1. Click RECORD - Speed auto lock to 32")
print("2. Move around - Consistent speed 32")
print("3. Click SAVE JSON - Save recording")
print("4. Playback will also use speed 32")
