-- ================================================
-- SUPER ANTI LAG SCRIPT - BY TOANCREATOR
-- ================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local MaterialService = game:GetService("MaterialService")

-- 1. TẮT ĐỔ BÓNG, BÓNG TỐI, SHADER & TỐI ƯU ÁNH SÁNG
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 2
Lighting.ClockTime = 12
Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
Lighting.Ambient = Color3.fromRGB(255, 255, 255)

-- Xóa toàn bộ hiệu ứng hình ảnh (Post-processing)
for _, effect in ipairs(Lighting:GetChildren()) do
    if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
        effect:Destroy()
    end
end

-- Tạo bầu trời màu Cyan
local Sky = Instance.new("Sky")
Sky.SkyboxBk = "rbxassetid://0"
Sky.SkyboxDn = "rbxassetid://0"
Sky.SkyboxFt = "rbxassetid://0"
Sky.SkyboxLf = "rbxassetid://0"
Sky.SkyboxRt = "rbxassetid://0"
Sky.SkyboxUp = "rbxassetid://0"
Sky.StarCount = 0
Sky.Parent = Lighting
Lighting.SkyBox = Sky
Lighting.Ambient = Color3.fromRGB(0, 255, 255) -- Môi trường tông Cyan

-- 2. TỐI ƯU DỊA HÌNH (TERRAIN) THÀNH MÀU ĐEN
if Workspace:FindFirstChildOfClass("Terrain") then
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    terrain.WaterWaveSize = 0
    terrain.WaterWaveSpeed = 0
    terrain.WaterReflectance = 0
    terrain.WaterTransparency = 0
    
    -- Đổi tất cả màu địa hình sang màu đen
    for _, enum in ipairs(Enum.Material:GetEnumItems()) do
        pcall(function()
            terrain:SetMaterialColor(enum, Color3.fromRGB(0, 0, 0))
        end)
    end
end

-- Danh sách màu ngẫu nhiên cho viền vật thể
local colors = {
    Color3.fromRGB(255, 255, 255), -- Trắng
    Color3.fromRGB(0, 255, 0),   -- Xanh
    Color3.fromRGB(255, 0, 0),   -- Đỏ
    Color3.fromRGB(255, 255, 0), -- Vàng
    Color3.fromRGB(170, 0, 255)  -- Tím
}

-- Hàm tạo viền (Highlight)
local function addOutline(obj)
    if not obj:FindFirstChildOfClass("Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 1 -- Trong suốt bên trong
        highlight.OutlineTransparency = 0 -- Viền rõ nét
        highlight.OutlineColor = colors[math.random(1, #colors)]
        highlight.Adornee = obj
        highlight.Parent = obj
    end
end

-- 3. XỬ LÝ VẬT THỂ, TƯỜNG, CÂY CỐI, CẦU THANG & ĐÁY SÀN
local function processPart(v)
    if v:IsA("BasePart") then
        -- Tắt đổ bóng từng part
        v.CastShadow = false
        v.Material = Enum.Material.SmoothPlastic
        
        -- Nếu là mặt sàn nền (Baseplate/Floor) -> Tô màu đen
        if v.Name:lower():find("floor") or v.Name:lower():find("baseplate") or v.Size.X > 200 or v.Size.Z > 200 then
            v.Color = Color3.fromRGB(0, 0, 0)
            v.Transparency = 0
        else
            -- Các vật thể khác (Cây cối, xe, tường, cầu thang...): Biến trong suốt & tạo viền
            v.Transparency = 0.9
            addOutline(v)
        end
    end
end

-- Quét toàn bộ map
for _, v in ipairs(Workspace:GetDescendants()) do
    processPart(v)
end

-- Tự động áp dụng cho các vật thể mới xuất hiện sau đó
Workspace.DescendantAdded:Connect(processPart)

-- 4. BIẾN PLAYER THÀNH KHỐI HÌNH CHỮ NHẬT DỌC MÀU TRẮNG
local function makeBoxCharacter(char)
    task.wait(0.2)
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("CharacterMesh") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("Accessory") or item:IsA("Decal") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Color = Color3.fromRGB(255, 255, 255)
            item.Material = Enum.Material.SmoothPlastic
            item.Transparency = 0
            if item:IsA("MeshPart") then
                item.TextureID = ""
            end
        end
    end
end

-- Lắng nghe người chơi vào game và respawn
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then makeBoxCharacter(player.Character) end
    player.CharacterAdded:Connect(makeBoxCharacter)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(makeBoxCharacter)
end)

-- 5. HIỂN THỊ BẢNG THÔNG BÁO TỰ ẨN SAU 5 GIÂY
local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Xóa Gui cũ nếu có
if PlayerGui:FindFirstChild("AntiLagGui") then
    PlayerGui.AntiLagGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiLagGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 320, 0, 140)
Frame.Position = UDim2.new(0.5, -160, 0.4, -70)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 255)
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, 0, 1, 0)
Label.BackgroundTransparency = 1
Label.Text = "SUPER ANTI FIXLAG\nHAS BEEN LOADED\nby ToanCreator"
Label.TextColor3 = Color3.fromRGB(0, 255, 255)
Label.TextSize = 18
Label.Font = Enum.Font.SourceSansBold
Label.TextWrapped = true
Label.Parent = Frame

-- Tự động biến mất sau 5 giây
task.delay(5, function()
    if ScreenGui then
        ScreenGui:Destroy()
    end
end)