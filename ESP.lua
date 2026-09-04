-- Script ESP + Hitbox tùy chỉnh
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Cấu hình tùy chỉnh
local Config = {
    HitboxSize = Vector3.new(6, 6, 6),
    HitboxColor = Color3.new(0, 1, 0), -- Màu hitbox mặc định (xanh lá)
    TextColorDefault = Color3.new(1, 1, 1), -- Màu tên mặc định (trắng)

    -- Màu tên theo phe
    TextColorCivilian = Color3.new(0, 1, 0), -- Xanh lá cho dân thường
    TextColorNeutral = Color3.new(1, 0.6, 0), -- Cam cho phe trung lập
    TextColorImposter = Color3.new(1, 0, 0), -- Đỏ cho Imposter
    TextColorObserver = Color3.new(0.8, 0.8, 0.8), -- Trắng/Xám nhạt cho người quan sát/bị chết
}

-- Hàm tạo ESP và hitbox
local function createESP(player)
    if player == LocalPlayer then return end -- Không hiển thị cho người chơi cục bộ

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
    -- nameLabel.TextColor3 = Config.TextColorDefault -- Sẽ được cập nhật sau
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = billboard

    -- Logic xác định phe và cập nhật màu tên
    local playerTeam = "Unknown" -- Mặc định
    -- !!! LƯU Ý: Bạn cần điều chỉnh phần này dựa trên cách game xác định phe !!!
    -- Ví dụ: Nếu game sử dụng Attribute trên HumanoidRootPart hoặc UserId để xác định phe, hãy thay thế phần này.
    -- Dưới đây là một ví dụ giả định dựa trên tên nhân vật hoặc một số thuộc tính chung.

    if player.UserId == 123456789 then -- Thay thế bằng UserId của bạn để test, nếu cần
        playerTeam = "LocalPlayer" -- Giả sử bạn là người chơi chính, không hiển thị thông tin này
    else
        -- Giả định đơn giản: Kiểm tra tên nhân vật hoặc một thuộc tính nào đó của player/character
        -- Bạn cần thay thế logic này bằng cách thực tế của game bạn đang làm.
        -- Ví dụ: Nếu Imposter có một Tag "Imposter" hoặc một Folder trong Character
        if character:FindFirstChild("ImposterTag") then -- Giả sử có một Tag tên là "ImposterTag"
            playerTeam = "Imposter"
        elseif character:FindFirstChild("CivilianTag") then -- Giả sử có một Tag tên là "CivilianTag"
            playerTeam = "Civilian"
        elseif character:FindFirstChild("NeutralTag") then -- Giả sử có một Tag tên là "NeutralTag"
            playerTeam = "Neutral"
        elseif not character:FindFirstChild("Humanoid") or character.Humanoid.Health == 0 then -- Kiểm tra nếu Humanoid không tồn tại hoặc Health là 0
            playerTeam = "Observer"
        else
            -- Nếu không xác định được, có thể coi là dân thường hoặc người quan sát tùy game
            playerTeam = "Civilian" -- Hoặc "Observer"
        end
    end

    -- Cập nhật màu tên dựa trên phe
    if playerTeam == "Civilian" then
        nameLabel.TextColor3 = Config.TextColorCivilian
    elseif playerTeam == "Neutral" then
        nameLabel.TextColor3 = Config.TextColorNeutral
    elseif playerTeam == "Imposter" then
        nameLabel.TextColor3 = Config.TextColorImposter
    elseif playerTeam == "Observer" then
        nameLabel.TextColor3 = Config.TextColorObserver
    else -- Trường hợp mặc định hoặc không xác định
        nameLabel.TextColor3 = Config.TextColorDefault
    end

    -- Hitbox ảo
    local hitbox = Instance.new("Part")
    hitbox.Name = "PlayerHitbox" -- Đặt tên để dễ quản lý khi xóa
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
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- Xử lý khi Character của player được thêm vào hoặc thay đổi
-- Cần đảm bảo createESP được gọi lại khi character mới xuất hiện (ví dụ: hồi sinh)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        createESP(player) -- Gọi cho các player đã có character khi script bắt đầu
    end
    player.CharacterAdded:Connect(function(character)
        -- Chờ HumanoidRootPart để đảm bảo mọi thứ sẵn sàng
        local rootPart = character:WaitForChild("HumanoidRootPart")
        -- Gọi createESP sau khi character đã được thiết lập đầy đủ
        -- Có thể cần thêm một chút delay tùy thuộc vào thời điểm character được tạo ra
        delay(0.1, function()
            createESP(player)
        end)
    end)
end

-- Xử lý khi player rời đi
Players.PlayerRemoving:Connect(function(player)
    local char = player.Character
    if char then
        -- Tìm và xóa các đối tượng ESP và Hitbox đã tạo
        local playerESP = char:FindFirstChild("PlayerESP")
        if playerESP then playerESP:Destroy() end

        local playerHitbox = char:FindFirstChild("PlayerHitbox")
        if playerHitbox then playerHitbox:Destroy() end
    end
end)

