--[[
    ToanCreator GUI - Extended Version
    Mobile Optimized (270x360)
    Credit: ToanCreator
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- CONFIG & COLORS
--==================================================

local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    Panel = Color3.fromRGB(25, 25, 30),
    Button = Color3.fromRGB(42, 42, 52),
    Accent = Color3.fromRGB(75, 170, 255),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(165, 165, 175),
    Green = Color3.fromRGB(80, 220, 130),
    Red = Color3.fromRGB(235, 70, 70),
    Yellow = Color3.fromRGB(255, 215, 70),
    Purple = Color3.fromRGB(170, 0, 255),
    Black = Color3.fromRGB(20, 20, 20)
}

local DefaultSettings = {
    Speed = { Enabled = false, Value = 16 },
    Jump = { Enabled = false, Value = 50 },
    Fly = false,
    Noclip = false,
    NoGravity = false,

    PlayerESP = false,
    PlayerESPColor = Color3.fromRGB(255, 255, 255),

    PlayerHitbox = false,
    PlayerHitboxColor = Color3.fromRGB(255, 80, 80),

    PlayerTrace = false,
    PlayerTraceColor = Color3.fromRGB(0, 170, 255),

    DistanceCheck = false,
    Freecam = false,

    Fullbright = false,
    FixLag = false,
    AutoExecute = false,
    ShiftLock = false
}

local Settings = {}
for k, v in pairs(DefaultSettings) do Settings[k] = v end

local Locations = {}
local SavedConfigs = {}
local SelectedPlayer = nil
local SelectedLocation = nil

-- Freecam System Variables
local TouchStart = nil
local TouchRotStart = Vector2.zero
local FreecamRot = Vector2.zero

-- System Tracking
local PlayerStats = {}
local TraceLines = {}

--==================================================
-- UTILS & SCREEN GUI
--==================================================

local function Create(cls, props)
    local obj = Instance.new(cls)
    for k, v in pairs(props or {}) do obj[k] = v end
    return obj
end

local function AddCorner(parent, r)
    return Create("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent })
end

local function AddStroke(parent, col, th)
    return Create("UIStroke", { Color = col or Color3.fromRGB(60, 60, 70), Thickness = th or 1, Parent = parent })
end

local ScreenGui = Create("ScreenGui", {
    Name = "ToanCreatorGUI_v5",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui,
})

local Main = Create("Frame", {
    Size = UDim2.new(0, 270, 0, 360),
    Position = UDim2.new(0.5, -135, 0.5, -180),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    Parent = ScreenGui,
})
AddCorner(Main, 10)
AddStroke(Main, Color3.fromRGB(60, 60, 75), 1.5)

-- DRAG SYSTEM
local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
MakeDraggable(Main, Main)

-- HEADER
local Header = Create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = COLORS.Panel, Parent = Main })
AddCorner(Header, 10)

Create("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "ToanCreator", TextColor3 = COLORS.Text,
    TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = Header
})

local MinimizeButton = Create("TextButton", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -56, 0, 6), BackgroundColor3 = COLORS.Button, Text = "—", TextColor3 = COLORS.Text, Font = Enum.Font.GothamBold, Parent = Header })
AddCorner(MinimizeButton, 5)

local CloseButton = Create("TextButton", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -28, 0, 6), BackgroundColor3 = COLORS.Button, Text = "×", TextColor3 = COLORS.Text, TextSize = 15, Font = Enum.Font.GothamBold, Parent = Header })
AddCorner(CloseButton, 5)

-- TAB SYSTEM
local TabBar = Create("Frame", { Size = UDim2.new(1, -12, 0, 30), Position = UDim2.new(0, 6, 0, 40), BackgroundTransparency = 1, Parent = Main })
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabBar })

local Content = Create("Frame", { Size = UDim2.new(1, -12, 1, -78), Position = UDim2.new(0, 6, 0, 74), BackgroundTransparency = 1, Parent = Main })

local Tabs, Pages = {}, {}
local tabOrderCount = 0

local function CreateTab(name)
    tabOrderCount = tabOrderCount + 1
    local btn = Create("TextButton", {
        Size = UDim2.new(0, 82, 1, 0), BackgroundColor3 = COLORS.Button, Text = name,
        TextColor3 = COLORS.SubText, TextSize = 11, Font = Enum.Font.GothamBold, LayoutOrder = tabOrderCount, Parent = TabBar
    })
    AddCorner(btn, 5)

    local page = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = Content
    })
    Create("UIListLayout", { Padding = UDim.new(0, 5), Parent = page })

    Tabs[name], Pages[name] = btn, page
    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(Tabs) do
            local sel = (tName == name)
            tBtn.BackgroundColor3 = sel and COLORS.Accent or COLORS.Button
            tBtn.TextColor3 = sel and Color3.new(1, 1, 1) or COLORS.SubText
            Pages[tName].Visible = sel
        end
    end)
    return page
end

local MovePage = CreateTab("MOVE")
local ESPPage = CreateTab("ESP")
local OptionPage = CreateTab("OPTION")

Tabs["MOVE"].BackgroundColor3 = COLORS.Accent
Tabs["MOVE"].TextColor3 = Color3.new(1, 1, 1)
Pages["MOVE"].Visible = true

--==================================================
-- UI COMPONENTS
--==================================================

local function BindLongPress(button, duration, callback)
    local pressTimer = 0
    local isHolding = false
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isHolding = true
            pressTimer = os.clock()
            task.delay(duration, function()
                if isHolding and (os.clock() - pressTimer >= duration) then
                    callback()
                    isHolding = false
                end
            end)
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isHolding = false
        end
    end)
end

local function CreateCombinedInput(parent, labelText, defaultVal, onValueChange, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)
    Create("TextLabel", { Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

    local input = Create("TextBox", { Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -85, 0.5, -10), BackgroundColor3 = COLORS.Button, Text = tostring(defaultVal), TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false, Parent = holder })
    AddCorner(input, 4)

    local check = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0.5, -10), BackgroundColor3 = COLORS.Button, Text = "", Parent = holder })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local state = false
    check.MouseButton1Click:Connect(function()
        state = not state
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
    end)

    input.FocusLost:Connect(function()
        local num = tonumber(input.Text)
        if num then if onValueChange then onValueChange(num) end else input.Text = tostring(defaultVal) end
    end)
    return holder
end

local function CreateCheckbox(parent, labelText, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)
    Create("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

    local check = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0.5, -10), BackgroundColor3 = COLORS.Button, Text = "", Parent = holder })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local state = false
    check.MouseButton1Click:Connect(function()
        state = not state
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
    end)
    return check
end

local function CreateESPCombo(parent, labelText, defaultColor, onColorChange, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)
    Create("TextLabel", { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

    local colorBtn = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -55, 0.5, -10), BackgroundColor3 = defaultColor, Text = "", Parent = holder })
    AddCorner(colorBtn, 4)

    local check = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0.5, -10), BackgroundColor3 = COLORS.Button, Text = "", Parent = holder })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local colors = { Color3.fromRGB(255,255,255), Color3.fromRGB(255,80,80), Color3.fromRGB(80,220,130), Color3.fromRGB(75,170,255), Color3.fromRGB(0,170,255) }
    local idx = 1
    colorBtn.MouseButton1Click:Connect(function()
        idx = (idx % #colors) + 1
        colorBtn.BackgroundColor3 = colors[idx]
        if onColorChange then onColorChange(colors[idx]) end
    end)

    local state = false
    check.MouseButton1Click:Connect(function()
        state = not state
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
    end)
    return holder
end

--==================================================
-- MOVE TAB SETUP
--==================================================

CreateCombinedInput(MovePage, "speed: enter num", Settings.Speed.Value, function(v) Settings.Speed.Value = v end, function(s) Settings.Speed.Enabled = s end)
CreateCombinedInput(MovePage, "jump: enter num", Settings.Jump.Value, function(v) Settings.Jump.Value = v end, function(s) Settings.Jump.Enabled = s end)

local FlyControls = Create("Frame", { Size = UDim2.new(0, 100, 0, 45), Position = UDim2.new(1, -110, 0.5, -22), BackgroundTransparency = 1, Visible = false, Parent = ScreenGui })
local FlyUp = Create("TextButton", { Size = UDim2.new(0, 45, 0, 45), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = COLORS.Accent, Text = "↑", TextColor3 = Color3.new(1,1,1), TextSize = 22, Font = Enum.Font.GothamBold, Parent = FlyControls })
AddCorner(FlyUp, 22)

local FlyDown = Create("TextButton", { Size = UDim2.new(0, 45, 0, 45), Position = UDim2.new(0, 50, 0, 0), BackgroundColor3 = COLORS.Accent, Text = "↓", TextColor3 = Color3.new(1,1,1), TextSize = 22, Font = Enum.Font.GothamBold, Parent = FlyControls })
AddCorner(FlyDown, 22)

local flyUpHeld, flyDownHeld = false, false

local function BindPressHold(button, stateUpdate)
    button.MouseButton1Down:Connect(function() stateUpdate(true) end)
    button.MouseButton1Up:Connect(function() stateUpdate(false) end)
    button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then stateUpdate(true) end end)
    button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then stateUpdate(false) end end)
end

BindPressHold(FlyUp, function(st) flyUpHeld = st end)
BindPressHold(FlyDown, function(st) flyDownHeld = st end)

CreateCheckbox(MovePage, "fly", function(v) Settings.Fly = v; FlyControls.Visible = v end)
CreateCheckbox(MovePage, "noclip", function(v) Settings.Noclip = v end)
CreateCheckbox(MovePage, "no gravity", function(v)
    Settings.NoGravity = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local bv = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("NoGravForce")
        if bv then bv:Destroy() end
    end
end)

-- TP PLAYER LIST
local TpPlayerHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 80), BackgroundColor3 = COLORS.Panel, Parent = MovePage })
AddCorner(TpPlayerHolder, 5)
Create("TextLabel", { Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 6, 0, 2), BackgroundTransparency = 1, Text = "tp player list:", TextColor3 = COLORS.SubText, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = TpPlayerHolder })

local PlayerTpBtn = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -24, 0, 2), BackgroundColor3 = COLORS.Accent, Text = "🖱", TextColor3 = Color3.new(1,1,1), TextSize = 10, Parent = TpPlayerHolder })
AddCorner(PlayerTpBtn, 4)

local PlayerScrollList = Create("ScrollingFrame", { Size = UDim2.new(1, -12, 0, 52), Position = UDim2.new(0, 6, 0, 22), BackgroundTransparency = 1, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = TpPlayerHolder })
Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = PlayerScrollList })

local function RefreshPlayerList()
    for _, c in ipairs(PlayerScrollList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pBtn = Create("TextButton", {
                Size = UDim2.new(1, -4, 0, 18), BackgroundColor3 = (SelectedPlayer == p) and COLORS.Accent or COLORS.Button,
                Text = p.Name, TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, Parent = PlayerScrollList
            })
            AddCorner(pBtn, 3)
            pBtn.MouseButton1Click:Connect(function() SelectedPlayer = p; RefreshPlayerList() end)
        end
    end
end
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(RefreshPlayerList)
RefreshPlayerList()

PlayerTpBtn.MouseButton1Click:Connect(function()
    if SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = SelectedPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0) end
    end
end)

-- CONFIRM OVERLAY DIỄN HOẠT
local ConfirmOverlay = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, Visible = false, ZIndex = 20, Parent = ScreenGui })
local ConfirmBox = Create("Frame", { Size = UDim2.new(0, 200, 0, 100), Position = UDim2.new(0.5, -100, 0.5, -50), BackgroundColor3 = COLORS.Panel, ZIndex = 21, Parent = ConfirmOverlay })
AddCorner(ConfirmBox, 8)

local ConfirmText = Create("TextLabel", { Size = UDim2.new(1, -10, 0, 40), Position = UDim2.new(0, 5, 0, 10), BackgroundTransparency = 1, Text = "Xác nhận?", TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextWrapped = true, ZIndex = 22, Parent = ConfirmBox })
local ConfirmYes = Create("TextButton", { Size = UDim2.new(0, 75, 0, 24), Position = UDim2.new(0, 15, 1, -34), BackgroundColor3 = COLORS.Red, Text = "Có", TextColor3 = Color3.new(1,1,1), TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 22, Parent = ConfirmBox })
AddCorner(ConfirmYes, 5)

local ConfirmNo = Create("TextButton", { Size = UDim2.new(0, 75, 0, 24), Position = UDim2.new(1, -90, 1, -34), BackgroundColor3 = COLORS.Button, Text = "Không", TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 22, Parent = ConfirmBox })
AddCorner(ConfirmNo, 5)

local currentConfirmAction = nil
local function ShowConfirm(text, onYes)
    ConfirmText.Text = text
    currentConfirmAction = onYes
    ConfirmOverlay.Visible = true
end
ConfirmNo.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = false end)
ConfirmYes.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false
    if currentConfirmAction then currentConfirmAction() end
end)

-- TP LOCATION LIST
local TpLocHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 80), BackgroundColor3 = COLORS.Panel, Parent = MovePage })
AddCorner(TpLocHolder, 5)
Create("TextLabel", { Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 6, 0, 2), BackgroundTransparency = 1, Text = "tp location list:", TextColor3 = COLORS.SubText, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = TpLocHolder })

local LocTpBtn = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -24, 0, 2), BackgroundColor3 = COLORS.Accent, Text = "🖱", TextColor3 = Color3.new(1,1,1), TextSize = 10, Parent = TpLocHolder })
AddCorner(LocTpBtn, 4)

local LocScrollList = Create("ScrollingFrame", { Size = UDim2.new(1, -12, 0, 52), Position = UDim2.new(0, 6, 0, 22), BackgroundTransparency = 1, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = TpLocHolder })
Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = LocScrollList })

local function RefreshLocationList()
    for _, c in ipairs(LocScrollList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for idx, loc in ipairs(Locations) do
        local lBtn = Create("TextButton", {
            Size = UDim2.new(1, -4, 0, 18), BackgroundColor3 = (SelectedLocation == loc) and COLORS.Accent or COLORS.Button,
            Text = loc.Name, TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, Parent = LocScrollList
        })
        AddCorner(lBtn, 3)
        lBtn.MouseButton1Click:Connect(function() SelectedLocation = loc; RefreshLocationList() end)
        
        -- Nhấn giữ 1s để xóa Location
        BindLongPress(lBtn, 1, function()
            ShowConfirm("Bạn muốn xóa vị trí '"..loc.Name.."'?", function()
                if loc.Part then loc.Part:Destroy() end
                table.remove(Locations, idx)
                if SelectedLocation == loc then SelectedLocation = nil end
                RefreshLocationList()
            end)
        end)
    end
end

local SetLocHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = MovePage })
AddCorner(SetLocHolder, 5)

local LocNameInput = Create("TextBox", { Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "+ set locate", PlaceholderColor3 = COLORS.SubText, TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false, Parent = SetLocHolder })
local SetBtn = Create("TextButton", { Size = UDim2.new(0, 38, 0, 20), Position = UDim2.new(1, -42, 0.5, -10), BackgroundColor3 = COLORS.Green, Text = "Set", TextColor3 = Color3.new(1,1,1), TextSize = 10, Font = Enum.Font.GothamBold, Parent = SetLocHolder })
AddCorner(SetBtn, 4)

SetBtn.MouseButton1Click:Connect(function()
    local name = LocNameInput.Text
    if name == "" or #Locations >= 10 then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local folder = workspace:FindFirstChild("ToanCreator_Markers") or Create("Folder", { Name = "ToanCreator_Markers", Parent = workspace })
    
    -- Tạo khối vuông Marker rực rỡ kèm ESP Billboard
    local part = Create("Part", { Name = name, Size = Vector3.new(1.5, 1.5, 1.5), Position = myRoot.Position, Anchored = true, CanCollide = false, Material = Enum.Material.Neon, Color = Color3.fromRGB(0, 255, 170), Parent = folder })
    local bill = Create("BillboardGui", { Size = UDim2.new(0, 100, 0, 30), StudsOffset = Vector3.new(0, 2, 0), AlwaysOnTop = true, Adornee = part, Parent = part })
    Create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "📍 "..name, TextColor3 = Color3.fromRGB(0, 255, 170), TextStrokeTransparency = 0, TextSize = 11, Font = Enum.Font.GothamBold, Parent = bill })

    local locData = { Name = name, CFrame = myRoot.CFrame, Part = part }
    table.insert(Locations, locData)

    LocNameInput.Text = ""
    SelectedLocation = locData
    RefreshLocationList()
end)

LocTpBtn.MouseButton1Click:Connect(function()
    if SelectedLocation then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = SelectedLocation.CFrame * CFrame.new(0, 2, 0) end
    end
end)

--==================================================
-- ESP TAB SETUP
--==================================================

CreateESPCombo(ESPPage, "player ESP", Settings.PlayerESPColor, function(c) Settings.PlayerESPColor = c end, function(s) Settings.PlayerESP = s end)
CreateESPCombo(ESPPage, "player hitbox", Settings.PlayerHitboxColor, function(c) Settings.PlayerHitboxColor = c end, function(s) Settings.PlayerHitbox = s end)
CreateESPCombo(ESPPage, "player trace", Settings.PlayerTraceColor, function(c) Settings.PlayerTraceColor = c end, function(s) Settings.PlayerTrace = s end)

CreateCheckbox(ESPPage, "distance check", function(v) Settings.DistanceCheck = v end)

-- FREECAM
CreateCheckbox(ESPPage, "freecam", function(v)
    Settings.Freecam = v
    FlyControls.Visible = v
    local char = LocalPlayer.Character

    if v then
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = true end
            end
        end
        Camera.CameraType = Enum.CameraType.Scriptable
    else
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = false end
            end
        end
        Camera.CameraType = Enum.CameraType.Custom
        if char and char:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
        end
    end
end)

-- XOAY MÀN HÌNH FREECAM MƯỢT MÀ
UserInputService.InputBegan:Connect(function(input)
    if Settings.Freecam and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        TouchStart = input.Position
        local x, y, _ = Camera.CFrame:ToOrientation()
        TouchRotStart = Vector2.new(math.deg(x), math.deg(y))
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Settings.Freecam and TouchStart and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - TouchStart
        FreecamRot = Vector2.new(
            math.clamp(TouchRotStart.X - (delta.Y * 0.25), -80, 80),
            TouchRotStart.Y - (delta.X * 0.25)
        )
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(0, math.rad(FreecamRot.Y), 0) * CFrame.Angles(math.rad(FreecamRot.X), 0, 0)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        TouchStart = nil
    end
end)

--==================================================
-- OPTION TAB SETUP
--==================================================

CreateCheckbox(OptionPage, "fullbright", function(v) Settings.Fullbright = v end)
CreateCheckbox(OptionPage, "fixlag", function(v)
    Settings.FixLag = v
    if v then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then obj.Material = Enum.Material.SmoothPlastic end
        end
    end
end)
CreateCheckbox(OptionPage, "auto execute", function(v) Settings.AutoExecute = v end)

-- TÍNH NĂNG LOCKS (SHIFT LOCK)
CreateCheckbox(OptionPage, "locks", function(v)
    Settings.ShiftLock = v
    UserInputService.MouseBehavior = v and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
end)

-- NÚT RESET & CONFIG DẠNG HÌNH CHỮ NHẬT
local OptionBtnHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 36), BackgroundTransparency = 1, Parent = OptionPage })
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = OptionBtnHolder })

local ResetBtn = Create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = COLORS.Red, Text = "Reset Default", TextColor3 = Color3.new(1,1,1), TextSize = 11, Font = Enum.Font.GothamBold, Parent = OptionBtnHolder })
AddCorner(ResetBtn, 6)

local ConfigBtn = Create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = COLORS.Accent, Text = "Config", TextColor3 = Color3.new(1,1,1), TextSize = 11, Font = Enum.Font.GothamBold, Parent = OptionBtnHolder })
AddCorner(ConfigBtn, 6)

ResetBtn.MouseButton1Click:Connect(function()
    ShowConfirm("Khôi phục tất cả cài đặt về mặc định?", function()
        for k, v in pairs(DefaultSettings) do Settings[k] = v end
        print("Settings reset to default!")
    end)
end)

-- BOARD POPUP CONFIG SYSTEM
local ConfigOverlay = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, Visible = false, ZIndex = 30, Parent = ScreenGui })
local ConfigBoard = Create("Frame", { Size = UDim2.new(0, 220, 0, 230), Position = UDim2.new(0.5, -110, 0.5, -115), BackgroundColor3 = COLORS.Background, ZIndex = 31, Parent = ConfigOverlay })
AddCorner(ConfigBoard, 8)
AddStroke(ConfigBoard, COLORS.Accent, 1)

Create("TextLabel", { Size = UDim2.new(1, -30, 0, 28), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, Text = "Config Manager", TextColor3 = COLORS.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 32, Parent = ConfigBoard })

local ConfigClose = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -24, 0, 4), BackgroundColor3 = COLORS.Button, Text = "×", TextColor3 = COLORS.Text, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 32, Parent = ConfigBoard })
AddCorner(ConfigClose, 4)
ConfigClose.MouseButton1Click:Connect(function() ConfigOverlay.Visible = false end)

local ConfigNameInput = Create("TextBox", { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 32), BackgroundColor3 = COLORS.Panel, Text = "", PlaceholderText = "Tên config mới...", TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false, ZIndex = 32, Parent = ConfigBoard })
AddCorner(ConfigNameInput, 5)

local SaveConfigBtn = Create("TextButton", { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 62), BackgroundColor3 = COLORS.Green, Text = "+ Lưu Config Hiện Tại", TextColor3 = Color3.new(1,1,1), TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 32, Parent = ConfigBoard })
AddCorner(SaveConfigBtn, 5)

local ConfigScroll = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 0, 130), Position = UDim2.new(0, 10, 0, 92), BackgroundTransparency = 1, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 32, Parent = ConfigBoard })
Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = ConfigScroll })

local function RefreshConfigList()
    for _, c in ipairs(ConfigScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for name, cfgData in pairs(SavedConfigs) do
        local item = Create("Frame", { Size = UDim2.new(1, -4, 0, 24), BackgroundColor3 = COLORS.Panel, ZIndex = 33, Parent = ConfigScroll })
        AddCorner(item, 4)

        local nameLbl = Create("TextLabel", { Size = UDim2.new(1, -55, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 34, Parent = item })
        local loadBtn = Create("TextButton", { Size = UDim2.new(0, 42, 0, 18), Position = UDim2.new(1, -46, 0.5, -9), BackgroundColor3 = COLORS.Accent, Text = "Load", TextColor3 = Color3.new(1,1,1), TextSize = 9, Font = Enum.Font.GothamBold, ZIndex = 34, Parent = item })
        AddCorner(loadBtn, 3)

        loadBtn.MouseButton1Click:Connect(function()
            for k, v in pairs(cfgData) do Settings[k] = v end
            ConfigOverlay.Visible = false
            print("Config loaded: "..name)
        end)

        -- Nhấn giữ 1s để xóa Config
        BindLongPress(item, 1, function()
            ShowConfirm("Xóa config '"..name.."'?", function()
                SavedConfigs[name] = nil
                RefreshConfigList()
            end)
        end)
    end
end

SaveConfigBtn.MouseButton1Click:Connect(function()
    local name = ConfigNameInput.Text
    if name ~= "" then
        local copy = {}
        for k, v in pairs(Settings) do copy[k] = v end
        SavedConfigs[name] = copy
        ConfigNameInput.Text = ""
        RefreshConfigList()
    end
end)

ConfigBtn.MouseButton1Click:Connect(function()
    RefreshConfigList()
    ConfigOverlay.Visible = true
end)

--==================================================
-- DISTANCE & ADVANCED ANOMALY DETECTOR
--==================================================

local function TriggerPurple(p)
    if not PlayerStats[p] then PlayerStats[p] = {} end
    PlayerStats[p].PurpleEndTime = os.clock() + 5
end

local function GetPlayerColor(p)
    local stats = PlayerStats[p] or {}
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not char or not hum or hum.Health <= 0 then
        return COLORS.Black
    end

    if stats.KillerTime and (os.clock() - stats.KillerTime <= 10) then
        return COLORS.Red
    end

    if stats.PurpleEndTime and os.clock() < stats.PurpleEndTime then
        return COLORS.Purple
    end

    return Settings.PlayerESPColor
end

--==================================================
-- RENDER LOOP
--==================================================

local function GetLine(p)
    if not TraceLines[p] then
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Transparency = 1
        TraceLines[p] = line
    end
    return TraceLines[p]
end

RunService.RenderStepped:Connect(function(deltaTime)
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum then
        if Settings.Speed.Enabled then hum.WalkSpeed = Settings.Speed.Value end
        if Settings.Jump.Enabled then hum.UseJumpPower = true; hum.JumpPower = Settings.Jump.Value end
    end

    if Settings.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if Settings.Fly and myRoot and hum then
        local moveDir = hum.MoveDirection
        local flyVel = moveDir * 50
        local ySpeed = (flyUpHeld and 40 or 0) - (flyDownHeld and 40 or 0)
        myRoot.AssemblyLinearVelocity = Vector3.new(flyVel.X, ySpeed, flyVel.Z)
    end

    if Settings.NoGravity and myRoot then
        local bv = myRoot:FindFirstChild("NoGravForce") or Create("BodyVelocity", { Name = "NoGravForce", MaxForce = Vector3.new(0, 100000, 0), Velocity = Vector3.zero, Parent = myRoot })
    elseif myRoot and myRoot:FindFirstChild("NoGravForce") and not Settings.Fly then
        myRoot.NoGravForce:Destroy()
    end

    -- FREECAM CHUẨN XÁC THEO HƯỚNG MẮT NHÌN CAMERA
    if Settings.Freecam then
        Camera.CameraType = Enum.CameraType.Scriptable
        local speed = 1.2
        local moveDir = Vector3.zero

        if hum then moveDir = hum.MoveDirection end

        local ySpeed = (flyUpHeld and 1 or 0) - (flyDownHeld and 1 or 0)
        local camCFrame = Camera.CFrame
        local targetVel = (camCFrame:VectorToWorldSpace(Vector3.new(moveDir.X, 0, moveDir.Z)) + Vector3.new(0, ySpeed, 0)) * speed
        
        Camera.CFrame = camCFrame + targetVel
    end

    if Settings.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end

    if Settings.ShiftLock then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end

    local allPlayers = Players:GetPlayers()
    for i, p in ipairs(allPlayers) do
        if p ~= LocalPlayer and p.Character then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = p.Character:FindFirstChildOfClass("Humanoid")

            if targetRoot and targetHum then
                if not PlayerStats[p] then PlayerStats[p] = { LastPos = targetRoot.Position, LastHP = targetHum.Health } end
                local stats = PlayerStats[p]

                if deltaTime > 0 then
                    local frameDist = (targetRoot.Position - stats.LastPos).Magnitude
                    local realSpeed = frameDist / deltaTime

                    if realSpeed > 35 then TriggerPurple(p) end
                end
                stats.LastPos = targetRoot.Position

                if targetHum.JumpPower > 65 then TriggerPurple(p) end

                if targetHum.Health < stats.LastHP then
                    TriggerPurple(p)
                    stats.LastHP = targetHum.Health
                end

                if Settings.DistanceCheck then
                    for j = i + 1, #allPlayers do
                        local otherP = allPlayers[j]
                        if otherP ~= LocalPlayer and otherP.Character and otherP.Character:FindFirstChild("HumanoidRootPart") then
                            local otherRoot = otherP.Character.HumanoidRootPart
                            local pDistance = (targetRoot.Position - otherRoot.Position).Magnitude
                            if pDistance <= 3.5 then
                                TriggerPurple(p)
                                TriggerPurple(otherP)
                            end
                        end
                    end
                end

                local displayColor = GetPlayerColor(p)

                local espTag = targetRoot:FindFirstChild("ToanESP")
                if Settings.PlayerESP then
                    if not espTag then
                        local bill = Create("BillboardGui", { Name = "ToanESP", Size = UDim2.new(0, 120, 0, 20), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, Adornee = targetRoot, Parent = targetRoot })
                        Create("TextLabel", { Name = "Txt", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextSize = 11, Font = Enum.Font.GothamBold, Parent = bill })
                    end
                    local label = targetRoot.ToanESP.Txt
                    label.TextColor3 = displayColor
                    label.Text = p.Name
                elseif espTag then
                    espTag:Destroy()
                end

                local hb = targetRoot:FindFirstChild("ToanHitboxAdorn")
                if Settings.PlayerHitbox then
                    if not hb then
                        hb = Create("BoxHandleAdornment", { Name = "ToanHitboxAdorn", Size = Vector3.new(4, 5, 4), AlwaysOnTop = true, ZIndex = 10, Transparency = 0.5, Adornee = targetRoot, Parent = targetRoot })
                    end
                    hb.Color3 = displayColor
                elseif hb then
                    hb:Destroy()
                end

                local line = GetLine(p)
                if Settings.PlayerTrace then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetRoot.Position)
                    if onScreen then
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(screenPos.X, screenPos.Y)
                        line.Color = displayColor
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        else
            if TraceLines[p] then TraceLines[p].Visible = false end
        end
    end
end)

--==================================================
-- MINIMIZE BUTTON
--==================================================

local MiniButton = Create("ImageButton", {
    Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 15, 0.5, -25),
    BackgroundColor3 = COLORS.Panel, BackgroundTransparency = 1, BorderSizePixel = 0,
    Visible = false, ZIndex = 100, Parent = ScreenGui
})
AddCorner(MiniButton, 10)
AddStroke(MiniButton, COLORS.Accent, 1.5)

task.spawn(function()
    local imgUrl = "https://raw.githubusercontent.com/T4H4KER/Test/refs/heads/main/1781919848774.png"
    local fileName = "ToanCreator_Icon.png"
    
    if writefile and getcustomasset then
        if not isfile or not isfile(fileName) then
            local success, content = pcall(function() return game:HttpGet(imgUrl) end)
            if success and content then writefile(fileName, content) end
        end
        if isfile and isfile(fileName) then MiniButton.Image = getcustomasset(fileName) end
    else
        MiniButton.Image = imgUrl
    end
end)

MakeDraggable(MiniButton, MiniButton)

MiniButton.MouseButton1Click:Connect(function() Main.Visible = true; MiniButton.Visible = false end)
MinimizeButton.MouseButton1Click:Connect(function() Main.Visible = false; MiniButton.Visible = true end)

CloseButton.MouseButton1Click:Connect(function()
    ShowConfirm("Đóng Script ToanCreator?", function()
        for _, l in pairs(TraceLines) do l:Remove() end
        if workspace:FindFirstChild("ToanCreator_Markers") then workspace.ToanCreator_Markers:Destroy() end
        ScreenGui:Destroy()
    end)
end)

print("ToanCreator GUI v5 Updated Successfully!")
