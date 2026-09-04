-- Script ESP + Hitbox tùy chỉnh
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Cấu hình tùy chỉnh
local Config = {
    HitboxSize = Vector3.new(6, 6, 6),
    HitboxColor = Color3.new(0, 1, 0),
    TextColor = Color3.new(1, 1, 1)
}

-- Hàm tạo ESP và hitbox
local function createESP(player)
    if player == LocalPlayer then return end
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    -- Tên player
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 120, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = rootPart

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = player.Name
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Config.TextColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = billboard

    -- Hitbox ảo
    local hitbox = Instance.new("Part")
    hitbox.Size = Config.HitboxSize
    hitbox.Color = Config.HitboxColor
    hitbox.Transparency = 0.7
    hitbox.CanCollide = false
    hitbox.Anchored = false
    hitbox.CanTouch = true
    hitbox.Material = Enum.Material.SmoothPlastic
    hitbox.Parent = character

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rootPart
    weld.Part1 = hitbox
    weld.Parent = hitbox
end

-- Khởi tạo và lắng nghe player
for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(function(player)
    createESP(player)
    player.CharacterAdded:Connect(function() createESP(player) end)
end)
Players.PlayerRemoving:Connect(function(player)
    local char = player.Character
    if char then char:FindFirstChild("PlayerESP"):Destroy() char:FindFirstChild("PlayerHitbox"):Destroy() end
end)
