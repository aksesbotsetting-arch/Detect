local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local isReverseMode = false
local connection = nil

-- Hapus GUI lama jika ada
if player.PlayerGui:FindFirstChild("ReverseShiftLockGUI") then
    player.PlayerGui:FindFirstChild("ReverseShiftLockGUI"):Destroy()
end

-- Buat GUI sederhana
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ReverseShiftLockGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 80)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local LockButton = Instance.new("TextButton")
LockButton.Size = UDim2.new(0.9, 0, 0, 40)
LockButton.Position = UDim2.new(0.05, 0, 0.2, 0)
LockButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LockButton.BorderSizePixel = 0
LockButton.Text = "🔄 SHIFT LOCK BELAKANG"
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.TextSize = 12
LockButton.Font = Enum.Font.GothamBold
LockButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = LockButton

-- Simpan orientasi asli
local originalAutoRotate = humanoid.AutoRotate

-- Fungsi untuk reverse shift lock
local function enableReverseShiftLock()
    if not rootPart then return end
    
    -- Nonaktifkan auto rotate
    humanoid.AutoRotate = false
    
    -- Putar karakter 180 derajat
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position - rootPart.CFrame.LookVector)
end

-- Fungsi untuk disable reverse
local function disableReverseShiftLock()
    if not rootPart then return end
    
    -- Kembalikan auto rotate ke settingan asli
    humanoid.AutoRotate = originalAutoRotate
end

-- Fungsi untuk maintain reverse orientation dengan smooth
local function maintainReverseOrientation()
    if not rootPart or not isReverseMode then return end
    
    -- Dapatkan arah camera
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    local cameraLookVector = cameraCFrame.LookVector
    
    -- Reverse arah camera (180 derajat)
    local reverseLookVector = -cameraLookVector
    
    -- Terapkan orientasi reverse ke karakter
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + Vector3.new(reverseLookVector.X, 0, reverseLookVector.Z))
end

-- Toggle reverse shift lock
LockButton.MouseButton1Click:Connect(function()
    isReverseMode = not isReverseMode
    
    if isReverseMode then
        -- AKTIFKAN REVERSE MODE
        LockButton.Text = "🔒 SHIFT LOCK BELAKANG AKTIF"
        LockButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        
        enableReverseShiftLock()
        
        -- Jalankan maintain orientation dengan smooth
        connection = RunService.Heartbeat:Connect(function()
            maintainReverseOrientation()
        end)
        
        print("🔒 SHIFT LOCK BELAKANG: AKTIF")
        
    else
        -- NONAKTIFKAN REVERSE MODE
        LockButton.Text = "🔄 SHIFT LOCK BELAKANG"
        LockButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        
        disableReverseShiftLock()
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        print("🔓 SHIFT LOCK BELAKANG: NONAKTIF")
    end
end)

-- Handle input untuk prevent conflict dengan shift lock original
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        -- Biarkan shift lock original bekerja
        wait(0.1) -- Kasih delay sedikit
        if isReverseMode then
            maintainReverseOrientation()
        end
    end
end)

-- Handle character change
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    originalAutoRotate = humanoid.AutoRotate
    
    -- Reset state ketika ganti karakter
    isReverseMode = false
    LockButton.Text = "🔄 SHIFT LOCK BELAKANG"
    LockButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
end)

print("🔄 SHIFT LOCK BELAKANG LOADED!")
print("Fitur: Shift Lock versi berlawanan arah")
print("Tekan tombol untuk mengaktifkan/menonaktifkan")
