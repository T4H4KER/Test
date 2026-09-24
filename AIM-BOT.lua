--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// Constants for Max Overlay
local HIGHEST_ZINDEX = 2147483647
local HIGHEST_DISPLAY_ORDER = 999999999

--// Variables (Aimbot & ESP)
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local aiming = false
local espEnabled = false
local teamCheck = false
local wallCheck = false
local aimPart = "Head"
local lockToCenter = false
local drawLines = false

local maxDistance = 200
local currentTargetPart = nil
local blacklistedTargets = {}
local blacklistedTeams = {}

--// Variables (Movement Mods & Auto Shoot)
local speedValue = 32
local jumpValue = 100
local speedEnabled = false
local jumpEnabled = false
local noclipEnabled = false

local autoShootEnabled = false
local autoShootLocked = false
local lastShootTime = 0
local shootInterval = 0.05 -- 50ms

-- Helper Function: Đảm bảo tất cả UI element luôn ở ZIndex cao nhất
local function applyMaxZIndex(guiObject)
    if guiObject:IsA("GuiObject") then
        guiObject.ZIndex = HIGHEST_ZINDEX
    end
    for _, child in ipairs(guiObject:GetChildren()) do
        applyMaxZIndex(child)
    end
end

--// UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = HIGHEST_DISPLAY_ORDER
screenGui.Enabled = true
screenGui.Parent = player:WaitForChild("PlayerGui")

screenGui.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("GuiObject") then
        descendant.ZIndex = HIGHEST_ZINDEX
    end
end)

-- Gear Button (Nút cài đặt)
local gearButton = Instance.new("ImageButton")
gearButton.Size = UDim2.new(0, 36, 0, 36)
gearButton.Position = UDim2.new(0.5, -60, 0.04, 0)
gearButton.BackgroundTransparency = 1
gearButton.Image = "rbxassetid://6031091006"
gearButton.Parent = screenGui

-- Switch Target Button (Nút Refresh)
local refreshButton = Instance.new("ImageButton")
refreshButton.Size = UDim2.new(0, 40, 0, 40)
refreshButton.Position = UDim2.new(0.5, 25, 0.04, 0)
refreshButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
refreshButton.Image = "rbxassetid://7734051052"
refreshButton.ImageColor3 = Color3.new(1, 1, 1)
refreshButton.AutoButtonColor = true
refreshButton.Parent = screenGui

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(1, 0)
refreshCorner.Parent = refreshButton

-- Toggle Aim "X" Button (Nút X Bật/Tắt Auto Aim)
local xButton = Instance.new("TextButton")
xButton.Size = UDim2.new(0, 40, 0, 40)
xButton.Position = UDim2.new(0.5, -20, 0.04, 0)
xButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
xButton.Text = "X"
xButton.TextColor3 = Color3.new(1, 1, 1)
xButton.Font = Enum.Font.GothamBold
xButton.TextSize = 22
xButton.AutoButtonColor = true
xButton.BackgroundTransparency = 0.4
xButton.Parent = screenGui

local xCorner = Instance.new("UICorner")
xCorner.CornerRadius = UDim.new(1, 0)
xCorner.Parent = xButton

--------------------------------------------------------------------------------
-- AUTO SHOOT BUTTON (NÚT VÀNG TRÒN 15PX, ĐỘ TRONG SUỐT 80%)
--------------------------------------------------------------------------------
local autoShootBtn = Instance.new("TextButton")
autoShootBtn.Name = "AutoShootButton"
autoShootBtn.Size = UDim2.new(0, 15, 0, 15)
autoShootBtn.Position = UDim2.new(0.5, 80, 0.5, 0) -- Vị trí mặc định ở giữa màn hình
autoShootBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 0) -- Màu vàng
autoShootBtn.BackgroundTransparency = 0.8 -- Độ trong suốt 80%
autoShootBtn.Text = ""
autoShootBtn.Visible = false
autoShootBtn.Parent = screenGui

local shootCorner = Instance.new("UICorner")
shootCorner.CornerRadius = UDim.new(1, 0) -- Hình tròn
shootCorner.Parent = autoShootBtn

local shootStroke = Instance.new("UIStroke")
shootStroke.Color = Color3.fromRGB(255, 255, 255)
shootStroke.Thickness = 1
shootStroke.Transparency = 0.5
shootStroke.Parent = autoShootBtn

--------------------------------------------------------------------------------
-- MENU FRAME (GIAO DIỆN)
--------------------------------------------------------------------------------
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 260, 0, 320)
menuFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = menuFrame

-- Title Bar
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 32)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
titleLabel.Text = "  MOD MENU"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = menuFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleLabel

-- Container cuộn cho các Nút/Tính năng
local scrollContainer = Instance.new("ScrollingFrame")
scrollContainer.Size = UDim2.new(1, -12, 1, -40)
scrollContainer.Position = UDim2.new(0, 6, 0, 36)
scrollContainer.BackgroundTransparency = 1
scrollContainer.BorderSizePixel = 0
scrollContainer.ScrollBarThickness = 4
scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollContainer.Parent = menuFrame

-- Sắp xếp theo dạng GRID (Ngang 2 cột x Dọc)
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 118, 0, 34)
gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = scrollContainer

gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollContainer.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
end)

-- Hàm tạo Nút Bật/Tắt
local function createCompactToggle(text)
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    button.TextColor3 = Color3.fromRGB(180, 180, 180)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 12
    button.Text = text
    button.AutoButtonColor = true

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button

    return button
end

-- Cập nhật trạng thái màu nút
local function updateToggleVisual(button, state, labelText)
    if state then
        button.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = labelText .. " [ON]"
    else
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        button.TextColor3 = Color3.fromRGB(180, 180, 180)
        button.Text = labelText
    end
end

-- Hàm tạo Ô nhập số
local function createInputModTile(labelText, defaultVal)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.65, 0, 1, 0)
    toggleBtn.Position = UDim2.new(0, 0, 0, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    toggleBtn.Font = Enum.Font.GothamMedium
    toggleBtn.TextSize = 12
    toggleBtn.Text = labelText
    toggleBtn.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.35, -4, 1, -6)
    textBox.Position = UDim2.new(0.65, 0, 0, 3)
    textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    textBox.TextColor3 = Color3.fromRGB(0, 255, 150)
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 12
    textBox.Text = tostring(defaultVal)
    textBox.ClearTextOnFocus = false
    textBox.Parent = frame

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 4)
    tbCorner.Parent = textBox

    return frame, toggleBtn, textBox
end

-- Tạo các phần tử UI
local aimToggle = createCompactToggle("Auto Aim")
local autoShootToggle = createCompactToggle("Auto Shoot")
local espToggle = createCompactToggle("ESP")
local teamCheckToggle = createCompactToggle("Team Check")
local wallCheckToggle = createCompactToggle("Wall Check")
local aimPartToggle = createCompactToggle("Aim: Head")
local lockCenterToggle = createCompactToggle("Lock Center")
local drawLinesToggle = createCompactToggle("Draw Lines")
local noclipToggle = createCompactToggle("Noclip")

local speedTile, speedToggle, speedInput = createInputModTile("Speed", 32)
local jumpTile, jumpToggle, jumpInput = createInputModTile("Jump", 100)

local teamListBtn = createCompactToggle("Blacklist Team >")

-- Add vào Grid Container
aimToggle.Parent = scrollContainer
autoShootToggle.Parent = scrollContainer
espToggle.Parent = scrollContainer
teamCheckToggle.Parent = scrollContainer
wallCheckToggle.Parent = scrollContainer
aimPartToggle.Parent = scrollContainer
lockCenterToggle.Parent = scrollContainer
drawLinesToggle.Parent = scrollContainer
noclipToggle.Parent = scrollContainer

speedTile.Parent = scrollContainer
jumpTile.Parent = scrollContainer
teamListBtn.Parent = scrollContainer

-- Frame phụ chứa danh sách Team Blacklist
local teamFrame = Instance.new("ScrollingFrame")
teamFrame.Size = UDim2.new(0, 140, 0, 220)
teamFrame.Position = UDim2.new(1, 8, 0, 0)
teamFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
teamFrame.BorderSizePixel = 0
teamFrame.Visible = false
teamFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
teamFrame.Parent = menuFrame

local teamFrameCorner = Instance.new("UICorner")
teamFrameCorner.CornerRadius = UDim.new(0, 8)
teamFrameCorner.Parent = teamFrame

local teamListLayout = Instance.new("UIListLayout")
teamListLayout.Parent = teamFrame
teamListLayout.Padding = UDim.new(0, 4)
teamListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

teamListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    teamFrame.CanvasSize = UDim2.new(0, 0, 0, teamListLayout.AbsoluteContentSize.Y + 8)
end)

-- Dragging Support
local function makeDraggable(guiElement, conditionFunc)
    local dragging, dragInput, dragStart, startPos

    guiElement.InputBegan:Connect(function(input)
        if conditionFunc and not conditionFunc() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiElement.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiElement.InputChanged:Connect(function(input)
        if conditionFunc and not conditionFunc() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(gearButton)
makeDraggable(refreshButton)
makeDraggable(xButton)
makeDraggable(menuFrame)
makeDraggable(autoShootBtn, function()
    return not autoShootLocked -- Chỉ kéo được nút vàng khi chưa bị khóa vị trí
end)

-- Cập nhật danh sách Team
local function updateTeamListUI()
    for _, child in pairs(teamFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local allTeams = Teams:GetTeams()
    if #allTeams == 0 then
        local noTeamLabel = Instance.new("TextLabel")
        noTeamLabel.Size = UDim2.new(1, -10, 0, 28)
        noTeamLabel.BackgroundTransparency = 1
        noTeamLabel.Text = "Không có Team"
        noTeamLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noTeamLabel.Font = Enum.Font.Gotham
        noTeamLabel.TextSize = 11
        noTeamLabel.Parent = teamFrame
    else
        for _, team in pairs(allTeams) do
            local tBtn = Instance.new("TextButton")
            tBtn.Size = UDim2.new(1, -10, 0, 26)
            tBtn.Font = Enum.Font.GothamMedium
            tBtn.TextSize = 11
            tBtn.AutoButtonColor = true

            local isBlacklisted = blacklistedTeams[team.Name] == true
            tBtn.BackgroundColor3 = isBlacklisted and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 50)
            tBtn.TextColor3 = isBlacklisted and Color3.new(1, 1, 1) or team.TeamColor.Color
            tBtn.Text = team.Name .. (isBlacklisted and " [CẤM]" or "")
            tBtn.Parent = teamFrame

            local btnC = Instance.new("UICorner")
            btnC.CornerRadius = UDim.new(0, 4)
            btnC.Parent = tBtn

            tBtn.MouseButton1Click:Connect(function()
                blacklistedTeams[team.Name] = not blacklistedTeams[team.Name]
                local active = blacklistedTeams[team.Name]
                tBtn.BackgroundColor3 = active and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 50)
                tBtn.TextColor3 = active and Color3.new(1, 1, 1) or team.TeamColor.Color
                tBtn.Text = team.Name .. (active and " [CẤM]" or "")
                currentTargetPart = nil
            end)
        end
    end
    applyMaxZIndex(teamFrame)
end

Teams.ChildAdded:Connect(updateTeamListUI)
Teams.ChildRemoved:Connect(updateTeamListUI)
updateTeamListUI()

teamListBtn.MouseButton1Click:Connect(function()
    teamFrame.Visible = not teamFrame.Visible
end)

-- Cập nhật trạng thái Aim
local function setAimState(state)
    aiming = state
    updateToggleVisual(aimToggle, aiming, "Auto Aim")
    xButton.BackgroundTransparency = aiming and 0 or 0.4
    
    if not aiming then
        blacklistedTargets = {}
        currentTargetPart = nil
    end
end

-- Gear Toggle
gearButton.MouseButton1Click:Connect(function()
    menuFrame.Visible = not menuFrame.Visible
end)

xButton.MouseButton1Click:Connect(function()
    setAimState(not aiming)
end)

aimToggle.MouseButton1Click:Connect(function()
    setAimState(not aiming)
end)

--------------------------------------------------------------------------------
-- SỰ KIỆN AUTO SHOOT (NHẤN MỘT LẦN HOẶC ẤN GIỮ ĐỂ KHÓA VỊ TRÍ)
--------------------------------------------------------------------------------
local pressStartTime = 0
local isPressingAutoShoot = false

autoShootToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isPressingAutoShoot = true
        pressStartTime = tick()

        -- Đếm thời gian giữ nút (0.8 giây để Khóa / Mở khóa)
        task.delay(0.8, function()
            if isPressingAutoShoot and (tick() - pressStartTime >= 0.75) then
                autoShootLocked = not autoShootLocked
                if autoShootLocked then
                    autoShootToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
                    autoShootToggle.Text = "Auto Shoot [LOCKED]"
                else
                    if autoShootEnabled then
                        autoShootToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
                        autoShootToggle.Text = "Auto Shoot [ON]"
                    else
                        autoShootToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                        autoShootToggle.Text = "Auto Shoot"
                    end
                end
            end
        end)
    end
end)

autoShootToggle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local pressDuration = tick() - pressStartTime
        isPressingAutoShoot = false

        -- Nhấn nhanh (< 0.8 giây): Bật / Tắt nút vàng
        if pressDuration < 0.75 then
            autoShootEnabled = not autoShootEnabled
            autoShootBtn.Visible = autoShootEnabled

            if autoShootLocked then
                autoShootToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
                autoShootToggle.Text = "Auto Shoot [LOCKED]"
            else
                updateToggleVisual(autoShootToggle, autoShootEnabled, "Auto Shoot")
            end
        end
    end
end)

espToggle.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    updateToggleVisual(espToggle, espEnabled, "ESP")
end)

teamCheckToggle.MouseButton1Click:Connect(function()
    teamCheck = not teamCheck
    updateToggleVisual(teamCheckToggle, teamCheck, "Team Check")
end)

wallCheckToggle.MouseButton1Click:Connect(function()
    wallCheck = not wallCheck
    updateToggleVisual(wallCheckToggle, wallCheck, "Wall Check")
end)

aimPartToggle.MouseButton1Click:Connect(function()
    aimPart = (aimPart == "Head" and "HumanoidRootPart" or "Head")
    aimPartToggle.Text = "Aim: " .. (aimPart == "Head" and "Head" or "Torso")
end)

lockCenterToggle.MouseButton1Click:Connect(function()
    lockToCenter = not lockToCenter
    updateToggleVisual(lockCenterToggle, lockToCenter, "Lock Center")
end)

drawLinesToggle.MouseButton1Click:Connect(function()
    drawLines = not drawLines
    updateToggleVisual(drawLinesToggle, drawLines, "Draw Lines")
end)

-- Speed Events
speedToggle.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    speedTile.BackgroundColor3 = speedEnabled and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(45, 45, 55)
    speedToggle.TextColor3 = speedEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    if not speedEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = 16
    end
end)

speedInput.FocusLost:Connect(function()
    local val = tonumber(speedInput.Text)
    if val then
        speedValue = val
    else
        speedInput.Text = tostring(speedValue)
    end
end)

-- Jump Events
jumpToggle.MouseButton1Click:Connect(function()
    jumpEnabled = not jumpEnabled
    jumpTile.BackgroundColor3 = jumpEnabled and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(45, 45, 55)
    jumpToggle.TextColor3 = jumpEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    if not jumpEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = 50
        player.Character.Humanoid.UseJumpPower = true
    end
end)

jumpInput.FocusLost:Connect(function()
    local val = tonumber(jumpInput.Text)
    if val then
        jumpValue = val
    else
        jumpInput.Text = tostring(jumpValue)
    end
end)

-- Noclip Events
noclipToggle.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    updateToggleVisual(noclipToggle, noclipEnabled, "Noclip")
end)

-- ESP Setup
local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder"
espFolder.Parent = screenGui
local espBoxes = {}

local function createESP(playerTarget)
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 6, 2)
    box.Transparency = 0.8
    box.Color3 = Color3.new(1, 1, 0)
    box.AlwaysOnTop = true
    box.ZIndex = HIGHEST_ZINDEX
    box.Adornee = playerTarget.Character and playerTarget.Character:FindFirstChild("HumanoidRootPart")
    box.Parent = espFolder
    return box
end

local function updateESP()
    for plr, box in pairs(espBoxes) do
        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            box.Adornee = plr.Character.HumanoidRootPart
            if teamCheck and player.Team and plr.Team then
                box.Color3 = (plr.Team == player.Team) and Color3.new(0, 0, 1) or Color3.new(1, 0, 0)
            else
                box.Color3 = Color3.new(1, 1, 0)
            end
        else
            box:Destroy()
            espBoxes[plr] = nil
        end
    end
end

-- Lines Drawing
local lineDrawer = Drawing.new("Line")
lineDrawer.Color = Color3.new(1, 0, 0)
lineDrawer.Thickness = 2
lineDrawer.Transparency = 1
lineDrawer.Visible = false

-- Wall Check
local function canSeeTarget(part)
    if not wallCheck then return true end
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {player.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = Workspace:Raycast(origin, direction.Unit * direction.Magnitude, rayParams)
    if raycastResult and raycastResult.Instance and not part:IsDescendantOf(raycastResult.Instance.Parent) then
        return false
    end
    return true
end

-- Team Check
local function isTeammate(target)
    if not teamCheck then return false end
    if player.Team and target.Team and player.Team == target.Team then
        return true
    end
    return false
end

local function isBlacklistedTeam(target)
    if target and target.Team and blacklistedTeams[target.Team.Name] then
        return true
    end
    return false
end

-- Lấy mục tiêu trong bán kính 200 stud
local function getTarget()
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    local closest = nil
    local shortestDist = math.huge
    local center2d = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player and target.Character and target.Character:FindFirstChild(aimPart) then
            if blacklistedTargets[target] then continue end
            if isBlacklistedTeam(target) then continue end

            local part = target.Character[aimPart]
            local hum = target.Character:FindFirstChild("Humanoid")
            
            if hum and hum.Health > 0 then
                local worldDist = (part.Position - myPos).Magnitude
                if worldDist > maxDistance then continue end

                if isTeammate(target) then continue end
                if not canSeeTarget(part) then continue end

                if lockToCenter then
                    local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if not onScreen then continue end

                    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center2d).Magnitude
                    if distFromCenter < shortestDist then
                        shortestDist = distFromCenter
                        closest = part
                    end
                else
                    if worldDist < shortestDist then
                        shortestDist = worldDist
                        closest = part
                    end
                end
            end
        end
    end

    if not closest and next(blacklistedTargets) ~= nil then
        blacklistedTargets = {}
    end

    return closest
end

-- Nhấn nút Refresh để chuyển đổi mục tiêu & Hiệu ứng xoay
local refreshTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

refreshButton.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(refreshButton, refreshTweenInfo, {
        Rotation = refreshButton.Rotation + 360
    })
    tween:Play()

    if currentTargetPart and currentTargetPart.Parent then
        local targetPlayer = Players:GetPlayerFromCharacter(currentTargetPart.Parent)
        if targetPlayer then
            blacklistedTargets[targetPlayer] = true
        end
    end
    currentTargetPart = getTarget()
end)

-- Khóa góc nhìn camera vào mục tiêu
local function aimAt(targetPart)
    if targetPart then
        local camPos = camera.CFrame.Position
        local targetPos = targetPart.Position
        
        if targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
            local vel = targetPart.Parent.HumanoidRootPart.AssemblyLinearVelocity
            targetPos = targetPos + (vel * 0.035)
        end

        camera.CFrame = CFrame.lookAt(camPos, targetPos)
    end
end

-- Hàm kích hoạt bấm vào vị trí của nút Auto Shoot
local function triggerAutoShoot()
    if tick() - lastShootTime >= shootInterval then
        lastShootTime = tick()
        
        -- Lấy vị trí tâm của nút vàng trên màn hình
        local posX = autoShootBtn.AbsolutePosition.X + (autoShootBtn.AbsoluteSize.X / 2)
        local posY = autoShootBtn.AbsolutePosition.Y + (autoShootBtn.AbsoluteSize.Y / 2)

        -- Giả lập bấm chuột/chạm vào tâm nút vàng
        VirtualInputManager:SendMouseButtonEvent(posX, posY, 0, true, game, 1)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(posX, posY, 0, false, game, 1)
    end
end

applyMaxZIndex(screenGui)

-- Main Loop
RunService:UnbindFromRenderStep("AimbotCameraUpdate")
RunService:BindToRenderStep("AimbotCameraUpdate", Enum.RenderPriority.Camera.Value + 1, function()
    -- 1. Xử lý Speed, Jump, Noclip
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if speedEnabled then
                hum.WalkSpeed = speedValue
            end
            if jumpEnabled then
                hum.UseJumpPower = true
                hum.JumpPower = jumpValue
            end
        end

        if noclipEnabled then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end

    -- 2. Xử lý ESP
    if espEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player and not espBoxes[plr] then
                espBoxes[plr] = createESP(plr)
            end
        end
        updateESP()
    else
        for _, box in pairs(espBoxes) do
            box:Destroy()
        end
        espBoxes = {}
    end

    -- 3. Xử lý Aimbot & Auto Shoot
    if aiming then
        local isValidTarget = false
        if currentTargetPart and currentTargetPart.Parent and currentTargetPart.Parent:FindFirstChild("Humanoid") then
            local hum = currentTargetPart.Parent.Humanoid
            local targetPlr = Players:GetPlayerFromCharacter(currentTargetPart.Parent)
            local myChar = player.Character

            if hum.Health > 0 and myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local worldDist = (currentTargetPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                if worldDist <= maxDistance and canSeeTarget(currentTargetPart) and not isBlacklistedTeam(targetPlr) then
                    isValidTarget = true
                end
            end
        end

        if not isValidTarget then
            currentTargetPart = getTarget()
        end

        if currentTargetPart then
            aimAt(currentTargetPart)

            -- Nếu Auto Shoot được bật và đã aim trúng mục tiêu hợp lệ -> Tự động click nút vàng 50ms/lần
            if autoShootEnabled then
                triggerAutoShoot()
            end
        end
    else
        currentTargetPart = nil
    end

    -- 4. Draw lines
    if drawLines and aiming and currentTargetPart then
        local screenPos, onScreen = camera:WorldToViewportPoint(currentTargetPart.Position)
        if onScreen then
            lineDrawer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            lineDrawer.To = Vector2.new(screenPos.X, screenPos.Y)
            lineDrawer.Visible = true
        else
            lineDrawer.Visible = false
        end
    else
        lineDrawer.Visible = false
    end
end)