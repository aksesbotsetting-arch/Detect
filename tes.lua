local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local isLockedBack = false
local connection = nil

-- Hapus GUI lama jika ada
if player.PlayerGui:FindFirstChild("LockBackGUI") then
    player.PlayerGui:FindFirstChild("LockBackGUI"):Destroy()
end

-- Buat GUI sederhana
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockBackGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 80)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔁 PUTAR BADAN"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local LockButton = Instance.new("TextButton")
LockButton.Size = UDim2.new(0.8, 0, 0, 35)
LockButton.Position = UDim2.new(0.1, 0, 0, 35)
LockButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LockButton.BorderSizePixel = 0
LockButton.Text = "🔓 AKTIFKAN PUTAR BADAN"
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.TextSize = 12
LockButton.Font = Enum.Font.GothamBold
LockButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = LockButton

-- Fungsi untuk lock menghadap belakang
local function lockToBack()
    if not rootPart then return end
    
    -- Putar badan 180 derajat
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position - rootPart.CFrame.LookVector)
    
    -- Nonaktifkan auto rotate humanoid
    humanoid.AutoRotate = false
end

-- Fungsi untuk unlock
local function unlockFromBack()
    if not rootPart then return end
    
    -- Aktifkan kembali auto rotate
    humanoid.AutoRotate = true
    
    -- Hentikan connection
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

-- Fungsi untuk maintain orientasi ke belakang
local function maintainBackOrientation()
    if not rootPart or not isLockedBack then return end
    
    -- Terus pertahankan menghadap belakang
    local currentLook = rootPart.CFrame.LookVector
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position - currentLook)
end

-- Toggle lock back
LockButton.MouseButton1Click:Connect(function()
    isLockedBack = not isLockedBack
    
    if isLockedBack then
        -- AKTIF
        LockButton.Text = "🔒 PUTAR BADAN AKTIF"
        LockButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        
        lockToBack()
        
        -- Jalankan maintain orientation
        connection = RunService.Heartbeat:Connect(function()
            maintainBackOrientation()
        end)
        
        print("🔒 PUTAR BADAN: AKTIF - Karakter terkunci menghadap belakang")
        
    else
        -- NONAKTIF
        LockButton.Text = "🔓 AKTIFKAN PUTAR BADAN"
        LockButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        
        unlockFromBack()
        
        print("🔓 PUTAR BADAN: NONAKTIF - Karakter normal")
    end
end)

-- Handle character change
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    
    -- Reset state ketika ganti karakter
    isLockedBack = false
    LockButton.Text = "🔓 AKTIFKAN PUTAR BADAN"
    LockButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    unlockFromBack()
end)

print("🔁 SCRIPT PUTAR BADAN LOADED!")
print("Fitur: Tekan tombol untuk mengunci karakter menghadap belakang")
print("Karakter akan tetap menghadap belakang meskipun analog digerakkan!")
