--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

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

-- Bảng lưu danh sách Bot và theo dõi di chuyển
local botCache = {}
local botMovementTracker = {} 

--// Variables (Movement Mods & Teleport)
local speedValue = 32
local jumpValue = 70
local speedEnabled = false
local jumpEnabled = false
local noclipEnabled = false
local tpLerkEnabled = false

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

-- Hỗ trợ Executor (gethui/protect_gui)
if gethui then
    screenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = game:GetService("CoreGui")
else
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

screenGui.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("GuiObject") then
        descendant.ZIndex = HIGHEST_ZINDEX
    end
end)

-- Gear Button
local gearButton = Instance.new("ImageButton")
gearButton.Size = UDim2.new(0, 36, 0, 36)
gearButton.Position = UDim2.new(0.5, -60, 0.04, 0)
gearButton.BackgroundTransparency = 1
gearButton.Image = "rbxassetid://6031091006"
gearButton.Parent = screenGui

-- Switch Target Button
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

-- Toggle Aim "X" Button
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
-- MENU FRAME (GIAO DIỆN)
--------------------------------------------------------------------------------
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 260, 0, 340)
menuFrame.Position = UDim2.new(0.5, -130, 0.5, -170)
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

-- Scroll Container
local scrollContainer = Instance.new("ScrollingFrame")
scrollContainer.Size = UDim2.new(1, -12, 1, -40)
scrollContainer.Position = UDim2.new(0, 6, 0, 36)
scrollContainer.BackgroundTransparency = 1
scrollContainer.BorderSizePixel = 0
scrollContainer.ScrollBarThickness = 4
scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollContainer.Parent = menuFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 118, 0, 34)
gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = scrollContainer

gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollContainer.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
end)

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

local function createAlwaysOnInputTile(labelText, defaultVal)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(0, 140, 80)

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.Text = labelText
    label.Parent = frame

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

    return frame, textBox
end

-- Tải các nút lên Menu Grid
local aimToggle = createCompactToggle("Auto Aim")
local espToggle = createCompactToggle("ESP")
local teamCheckToggle = createCompactToggle("Team Check")
local wallCheckToggle = createCompactToggle("Wall Check")
local aimPartToggle = createCompactToggle("Aim: Head")
local lockCenterToggle = createCompactToggle("Lock Center")
local drawLinesToggle = createCompactToggle("Draw Lines")
local noclipToggle = createCompactToggle("Noclip")
local tpLerkToggle = createCompactToggle("TP Lerk")

local aimDistTile, aimDistInput = createAlwaysOnInputTile("Aim Dist", 200)
local speedTile, speedToggle, speedInput = createInputModTile("Speed", 32)
local jumpTile, jumpToggle, jumpInput = createInputModTile("Jump", 70)

local teamListBtn = createCompactToggle("Blacklist Team >")

aimToggle.Parent = scrollContainer
aimDistTile.Parent = scrollContainer
espToggle.Parent = scrollContainer
teamCheckToggle.Parent = scrollContainer
wallCheckToggle.Parent = scrollContainer
aimPartToggle.Parent = scrollContainer
lockCenterToggle.Parent = scrollContainer
drawLinesToggle.Parent = scrollContainer
noclipToggle.Parent = scrollContainer
tpLerkToggle.Parent = scrollContainer

speedTile.Parent = scrollContainer
jumpTile.Parent = scrollContainer
teamListBtn.Parent = scrollContainer

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

--------------------------------------------------------------------------------
-- CẬP NHẬT BLACKLIST UI (CÓ ROLE "BOT" MẶC ĐỊNH)
--------------------------------------------------------------------------------
local function updateTeamListUI()
    for _, child in pairs(teamFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- 1. Tạo Nút Role Mặc Định "BOT"
    local botBtn = Instance.new("TextButton")
    botBtn.Size = UDim2.new(1, -10, 0, 26)
    botBtn.Font = Enum.Font.GothamBold
    botBtn.TextSize = 11
    botBtn.AutoButtonColor = true

    local isBotBlacklisted = blacklistedTeams["BOT"] == true
    botBtn.BackgroundColor3 = isBotBlacklisted and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 50)
    botBtn.TextColor3 = isBotBlacklisted and Color3.new(1, 1, 1) or Color3.fromRGB(255, 140, 0)
    botBtn.Text = "BOT " .. (isBotBlacklisted and "[CẤM]" or "")
    botBtn.Parent = teamFrame

    local botBtnCorner = Instance.new("UICorner")
    botBtnCorner.CornerRadius = UDim.new(0, 4)
    botBtnCorner.Parent = botBtn

    botBtn.MouseButton1Click:Connect(function()
        blacklistedTeams["BOT"] = not blacklistedTeams["BOT"]
        local active = blacklistedTeams["BOT"]
        botBtn.BackgroundColor3 = active and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 50)
        botBtn.TextColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(255, 140, 0)
        botBtn.Text = "BOT " .. (active and "[CẤM]" or "")
        currentTargetPart = nil
    end)

    -- 2. Thêm Các Team Thực Tế Trong Game
    local allTeams = Teams:GetTeams()
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
    
    applyMaxZIndex(teamFrame)
end

Teams.ChildAdded:Connect(updateTeamListUI)
Teams.ChildRemoved:Connect(updateTeamListUI)
updateTeamListUI()

teamListBtn.MouseButton1Click:Connect(function()
    teamFrame.Visible = not teamFrame.Visible
end)

local function setAimState(state)
    aiming = state
    updateToggleVisual(aimToggle, aiming, "Auto Aim")
    xButton.BackgroundTransparency = aiming and 0 or 0.4
    
    if not aiming then
        blacklistedTargets = {}
        currentTargetPart = nil
    end
end

gearButton.MouseButton1Click:Connect(function() menuFrame.Visible = not menuFrame.Visible end)
xButton.MouseButton1Click:Connect(function() setAimState(not aiming) end)
aimToggle.MouseButton1Click:Connect(function() setAimState(not aiming) end)

aimDistInput.FocusLost:Connect(function()
    local val = tonumber(aimDistInput.Text)
    if val then maxDistance = val else aimDistInput.Text = tostring(maxDistance) end
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
    aimPart = (aimPart == "Head" and "Torso" or "Head")
    aimPartToggle.Text = "Aim: " .. aimPart
end)

lockCenterToggle.MouseButton1Click:Connect(function()
    lockToCenter = not lockToCenter
    updateToggleVisual(lockCenterToggle, lockToCenter, "Lock Center")
end)

drawLinesToggle.MouseButton1Click:Connect(function()
    drawLines = not drawLines
    updateToggleVisual(drawLinesToggle, drawLines, "Draw Lines")
end)

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
    if val then speedValue = val else speedInput.Text = tostring(speedValue) end
end)

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
    if val then jumpValue = val else jumpInput.Text = tostring(jumpValue) end
end)

noclipToggle.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    updateToggleVisual(noclipToggle, noclipEnabled, "Noclip")
end)

-- ESP Engine Dynamic
local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder"
espFolder.Parent = screenGui
local espBoxes = {}

local function createESP()
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 6, 2)
    box.Transparency = 0.8
    box.AlwaysOnTop = true
    box.ZIndex = HIGHEST_ZINDEX
    box.Parent = espFolder
    return box
end

local function scanBot(obj)
    if obj:IsA("Model") and obj ~= player.Character and not Players:GetPlayerFromCharacter(obj) then
        if obj:FindFirstChildOfClass("Humanoid") then
            botCache[obj] = true
        end
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do scanBot(obj) end
Workspace.DescendantAdded:Connect(scanBot)
Workspace.DescendantRemoving:Connect(function(obj)
    botCache[obj] = nil
    botMovementTracker[obj] = nil
end)

local function getValidCharacter(obj)
    local char = nil
    if typeof(obj) == "Instance" and obj:IsA("Player") then
        char = obj.Character or Workspace:FindFirstChild(obj.Name)
    elseif typeof(obj) == "Instance" and obj:IsA("Model") then
        char = obj
    end

    if char and char:IsDescendantOf(Workspace) then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
        if hum and root and hum.Health > 0 then
            return char, hum, root
        end
    end
    return nil, nil, nil
end

local function getAllEntities()
    local entities = {}
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(entities, plr)
        end
    end

    for botModel, _ in pairs(botCache) do
        if botModel:IsDescendantOf(Workspace) then
            table.insert(entities, botModel)
        else
            botCache[botModel] = nil
        end
    end

    return entities
end

local function isBotStationary(botModel, currentRoot)
    local currentTime = tick()
    local currentPos = currentRoot.Position

    if not botMovementTracker[botModel] then
        botMovementTracker[botModel] = {
            lastPos = currentPos,
            lastMoveTime = currentTime
        }
        return false
    end

    local tracker = botMovementTracker[botModel]
    local moveDistance = (currentPos - tracker.lastPos).Magnitude

    if moveDistance > 0.2 then
        tracker.lastPos = currentPos
        tracker.lastMoveTime = currentTime
        return false
    else
        if (currentTime - tracker.lastMoveTime) >= 10 then
            return true
        end
    end

    return false
end

local function updateESP()
    local activeEntities = {}
    local entities = getAllEntities()

    for _, entity in ipairs(entities) do
        activeEntities[entity] = true
        local char, hum, root = getValidCharacter(entity)

        if char and hum and root then
            if not espBoxes[entity] or not espBoxes[entity].Parent then
                espBoxes[entity] = createESP()
            end

            local box = espBoxes[entity]
            box.Adornee = root

            local isBot = not (typeof(entity) == "Instance" and entity:IsA("Player"))
            
            if isBot then
                box.Color3 = Color3.fromRGB(255, 140, 0)
            else
                local targetPlr = entity
                if teamCheck and player.Team and targetPlr and targetPlr.Team then
                    box.Color3 = (targetPlr.Team == player.Team) and Color3.new(0, 0, 1) or Color3.new(1, 0, 0)
                else
                    box.Color3 = Color3.new(1, 1, 0)
                end
            end
        else
            if espBoxes[entity] then
                espBoxes[entity]:Destroy()
                espBoxes[entity] = nil
            end
        end
    end

    for entity, box in pairs(espBoxes) do
        if not activeEntities[entity] then
            box:Destroy()
            espBoxes[entity] = nil
            botMovementTracker[entity] = nil
        end
    end
end

-- Lines Drawing (Dây nối màu Đỏ)
local lineDrawer = Drawing.new("Line")
lineDrawer.Color = Color3.fromRGB(255, 0, 0)
lineDrawer.Thickness = 2
lineDrawer.Transparency = 1
lineDrawer.Visible = false

local function getAimTargetPart(char)
    if not char then return nil end
    if aimPart == "Head" then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    end
end

local function canSeeTarget(part)
    if not wallCheck then return true end
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin)
    
    local rayParams = RaycastParams.new()
    local ignoreList = {camera}
    if player.Character then table.insert(ignoreList, player.Character) end
    if part.Parent then table.insert(ignoreList, part.Parent) end
    
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastResult = Workspace:Raycast(origin, direction, rayParams)
    return raycastResult == nil
end

local function isTeammate(targetObj)
    if not teamCheck then return false end
    local targetPlr = typeof(targetObj) == "Instance" and targetObj:IsA("Player") and targetObj or Players:GetPlayerFromCharacter(targetObj)
    if player.Team and targetPlr and targetPlr.Team and player.Team == targetPlr.Team then
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- CHECK BLACKLIST TEAM & ROLE "BOT"
--------------------------------------------------------------------------------
local function isBlacklistedTeam(targetObj)
    local isBot = not (typeof(targetObj) == "Instance" and targetObj:IsA("Player"))
    
    -- Nếu là Bot và role "BOT" đang bật CẤM
    if isBot and blacklistedTeams["BOT"] then
        return true
    end

    -- Kiểm tra Team bình thường nếu là Player
    local targetPlr = typeof(targetObj) == "Instance" and targetObj:IsA("Player") and targetObj or Players:GetPlayerFromCharacter(targetObj)
    if targetPlr and targetPlr.Team and blacklistedTeams[targetPlr.Team.Name] then
        return true
    end

    return false
end

local function getTarget()
    local _, _, myRoot = getValidCharacter(player)
    if not myRoot then return nil end
    local myPos = myRoot.Position

    local closest = nil
    local shortestDist = math.huge
    local center2d = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    local entities = getAllEntities()

    for _, target in pairs(entities) do
        if blacklistedTargets[target] then continue end
        if isBlacklistedTeam(target) then continue end

        local char, hum, root = getValidCharacter(target)
        if char and hum and root then
            local isBot = not (typeof(target) == "Instance" and target:IsA("Player"))
            
            if isBot and isBotStationary(target, root) then
                continue
            end

            local part = getAimTargetPart(char)
            if part then
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

--------------------------------------------------------------------------------
-- CƠ CHẾ TP LERK VÒNG TƯỜNG (PATHFINDING NÉ VẬT CẢN)
--------------------------------------------------------------------------------
local function startTPLerkLoop()
    local SPEED = 50          -- Tốc độ: 50 studs/s
    local SEGMENT_LIMIT = 200 -- Di chuyển tối đa 200 studs mỗi chặng nghỉ
    local PAUSE_TIME = 0.5    -- Nghỉ 500ms

    task.spawn(function()
        while tpLerkEnabled do
            pcall(function()
                local targetPart = getTarget()
                if not targetPart or not targetPart.Parent then
                    task.wait(0.2)
                    return
                end

                local myChar, _, myRoot = getValidCharacter(player)
                if not myChar or not myRoot then
                    task.wait(0.2)
                    return
                end

                -- Tạo đường đi né tường
                local path = PathfindingService:CreatePath({
                    AgentRadius = 2,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    WaypointSpacing = 4
                })

                local success, _ = pcall(function()
                    path:ComputeAsync(myRoot.Position, targetPart.Position)
                end)

                if not success or path.Status ~= Enum.PathStatus.Success then
                    task.wait(0.2)
                    return
                end

                local waypoints = path:GetWaypoints()
                local totalMovedDistance = 0

                -- Di chuyển theo lộ trình né tường
                for idx = 2, #waypoints do
                    if not tpLerkEnabled then break end

                    local waypoint = waypoints[idx]
                    local wpPos = waypoint.Position

                    -- Nhảy nếu waypoint yêu cầu
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        local hum = myChar:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Jump = true end
                    end

                    local startPos = myRoot.Position
                    local distanceToWP = (wpPos - startPos).Magnitude

                    if distanceToWP > 0.1 then
                        local direction = (wpPos - startPos).Unit
                        local distanceTraveled = 0

                        while distanceTraveled < distanceToWP and tpLerkEnabled do
                            local dt = RunService.Heartbeat:Wait()
                            if not myRoot or not myRoot.Parent then break end

                            local step = SPEED * dt
                            distanceTraveled = math.min(distanceTraveled + step, distanceToWP)

                            myRoot.AssemblyLinearVelocity = Vector3.zero
                            myRoot.CFrame = CFrame.new(startPos + (direction * distanceTraveled))

                            totalMovedDistance = totalMovedDistance + step

                            -- Dừng lại nghỉ 500ms nếu tổng quãng đường đi qua các waypoint đạt 200 studs
                            if totalMovedDistance >= SEGMENT_LIMIT then
                                totalMovedDistance = 0
                                task.wait(PAUSE_TIME)
                            end
                        end
                    end
                end

                -- Sau khi đi hết lộ trình, nghỉ ngắn rồi cập nhật đường đi mới theo mục tiêu
                if tpLerkEnabled then
                    task.wait(PAUSE_TIME)
                end
            end)
            task.wait()
        end
    end)
end

tpLerkToggle.MouseButton1Click:Connect(function()
    tpLerkEnabled = not tpLerkEnabled
    updateToggleVisual(tpLerkToggle, tpLerkEnabled, "TP Lerk")
    if tpLerkEnabled then
        startTPLerkLoop()
    end
end)

--------------------------------------------------------------------------------
-- REFRESH & AIM LOGIC
--------------------------------------------------------------------------------
local refreshTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

refreshButton.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(refreshButton, refreshTweenInfo, {
        Rotation = refreshButton.Rotation + 360
    })
    tween:Play()

    if currentTargetPart and currentTargetPart.Parent then
        local targetEntity = Players:GetPlayerFromCharacter(currentTargetPart.Parent) or currentTargetPart.Parent
        if targetEntity then
            blacklistedTargets[targetEntity] = true
        end
    end
    currentTargetPart = getTarget()
end)

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

applyMaxZIndex(screenGui)

-- Main Loop
RunService:UnbindFromRenderStep("AimbotCameraUpdate")
RunService:BindToRenderStep("AimbotCameraUpdate", Enum.RenderPriority.Camera.Value + 1, function()
    -- 1. Movement Mods
    local char, hum, _ = getValidCharacter(player)
    if char and hum then
        if speedEnabled then hum.WalkSpeed = speedValue end
        if jumpEnabled then hum.UseJumpPower = true hum.JumpPower = jumpValue end
        if noclipEnabled then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end

    -- 2. ESP
    if espEnabled then
        updateESP()
    else
        for entity, box in pairs(espBoxes) do
            box:Destroy()
            espBoxes[entity] = nil
        end
    end

    -- 3. Aimbot
    if aiming then
        local isValidTarget = false
        
        if currentTargetPart and currentTargetPart:IsDescendantOf(Workspace) and currentTargetPart.Parent then
            local hum = currentTargetPart.Parent:FindFirstChildOfClass("Humanoid")
            local targetEntity = Players:GetPlayerFromCharacter(currentTargetPart.Parent) or currentTargetPart.Parent
            local _, _, myRoot = getValidCharacter(player)

            if hum and hum.Health > 0 and myRoot then
                local isBot = not (typeof(targetEntity) == "Instance" and targetEntity:IsA("Player"))
                local rootPart = currentTargetPart.Parent:FindFirstChild("HumanoidRootPart") or currentTargetPart

                local botAFK = isBot and rootPart and isBotStationary(targetEntity, rootPart)
                local worldDist = (currentTargetPart.Position - myRoot.Position).Magnitude

                if worldDist <= maxDistance and canSeeTarget(currentTargetPart) and not isBlacklistedTeam(targetEntity) and not botAFK then
                    isValidTarget = true
                end
            end
        end

        if not isValidTarget then
            currentTargetPart = getTarget()
        end

        if currentTargetPart then
            aimAt(currentTargetPart)
        end
    else
        currentTargetPart = nil
    end

    -- 4. Draw Lines (Đường dây màu Đỏ)
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