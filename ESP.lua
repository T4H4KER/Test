--[[
    ToanCreator GUI - Fully Fixed Version
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
}

local Settings = {
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
}

local Locations = {}
local SelectedPlayer = nil
local SelectedLocation = nil

-- Freecam Variables
local FreecamPos = Vector3.zero

-- Cache Drawing Tracers (Đảm bảo hoạt động xuyên tường 100%)
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
    Name = "ToanCreatorGUI_FinalFixed",
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

--==================================================
-- TAB SYSTEM
--==================================================

local TabBar = Create("Frame", {
    Size = UDim2.new(1, -12, 0, 30), Position = UDim2.new(0, 6, 0, 40),
    BackgroundTransparency = 1, Parent = Main
})

Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = TabBar
})

local Content = Create("Frame", { Size = UDim2.new(1, -12, 1, -78), Position = UDim2.new(0, 6, 0, 74), BackgroundTransparency = 1, Parent = Main })

local Tabs, Pages = {}, {}
local tabOrderCount = 0

local function CreateTab(name)
    tabOrderCount = tabOrderCount + 1
    local btn = Create("TextButton", {
        Size = UDim2.new(0, 82, 1, 0),
        BackgroundColor3 = COLORS.Button,
        Text = name,
        TextColor3 = COLORS.SubText,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        LayoutOrder = tabOrderCount,
        Parent = TabBar
    })
    AddCorner(btn, 5)

    local page = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = Content
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

local function CreateCombinedInput(parent, labelText, defaultVal, onValueChange, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)

    Create("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text,
        TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder
    })

    local input = Create("TextBox", {
        Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -85, 0.5, -10),
        BackgroundColor3 = COLORS.Button, Text = tostring(defaultVal), TextColor3 = COLORS.Text,
        TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false, Parent = holder
    })
    AddCorner(input, 4)

    local check = Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundColor3 = COLORS.Button, Text = "", Parent = holder
    })
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
        if num then
            if onValueChange then onValueChange(num) end
        else
            input.Text = tostring(defaultVal)
        end
    end)
    return holder
end

local function CreateCheckbox(parent, labelText, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)

    Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text,
        TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder
    })

    local check = Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundColor3 = COLORS.Button, Text = "", Parent = holder
    })
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
    return holder
end

local function CreateESPCombo(parent, labelText, defaultColor, onColorChange, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)

    Create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text,
        TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder
    })

    local colorBtn = Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -55, 0.5, -10),
        BackgroundColor3 = defaultColor, Text = "", Parent = holder
    })
    AddCorner(colorBtn, 4)

    local check = Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundColor3 = COLORS.Button, Text = "", Parent = holder
    })
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
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then stateUpdate(true) end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then stateUpdate(false) end
    end)
end

BindPressHold(FlyUp, function(st) flyUpHeld = st end)
BindPressHold(FlyDown, function(st) flyDownHeld = st end)

CreateCheckbox(MovePage, "fly", function(v)
    Settings.Fly = v
    FlyControls.Visible = v
end)

CreateCheckbox(MovePage, "noclip", function(v) Settings.Noclip = v end)
CreateCheckbox(MovePage, "no gravity", function(v)
    Settings.NoGravity = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local bv = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("NoGravForce")
        if bv then bv:Destroy() end
    end
end)

-- TP PLAYER SCROLL LIST
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
            pBtn.MouseButton1Click:Connect(function()
                SelectedPlayer = p
                RefreshPlayerList()
            end)
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

-- TP LOCATION SCROLL LIST
local TpLocHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 80), BackgroundColor3 = COLORS.Panel, Parent = MovePage })
AddCorner(TpLocHolder, 5)

Create("TextLabel", { Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 6, 0, 2), BackgroundTransparency = 1, Text = "tp location list:", TextColor3 = COLORS.SubText, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = TpLocHolder })

local LocTpBtn = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -24, 0, 2), BackgroundColor3 = COLORS.Accent, Text = "🖱", TextColor3 = Color3.new(1,1,1), TextSize = 10, Parent = TpLocHolder })
AddCorner(LocTpBtn, 4)

local LocScrollList = Create("ScrollingFrame", { Size = UDim2.new(1, -12, 0, 52), Position = UDim2.new(0, 6, 0, 22), BackgroundTransparency = 1, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = TpLocHolder })
Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = LocScrollList })

local function RefreshLocationList()
    for _, c in ipairs(LocScrollList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, loc in ipairs(Locations) do
        local lBtn = Create("TextButton", {
            Size = UDim2.new(1, -4, 0, 18), BackgroundColor3 = (SelectedLocation == loc) and COLORS.Accent or COLORS.Button,
            Text = loc.Name, TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, Parent = LocScrollList
        })
        AddCorner(lBtn, 3)
        lBtn.MouseButton1Click:Connect(function()
            SelectedLocation = loc
            RefreshLocationList()
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

    local locData = { Name = name, CFrame = myRoot.CFrame }
    table.insert(Locations, locData)

    local folder = workspace:FindFirstChild("ToanCreator_Markers") or Create("Folder", { Name = "ToanCreator_Markers", Parent = workspace })
    local part = Create("Part", { Name = name, Size = Vector3.new(1.2, 1.2, 1.2), Position = myRoot.Position, Anchored = true, CanCollide = false, Material = Enum.Material.Neon, Color = Color3.fromRGB(130, 255, 170), Parent = folder })
    local bill = Create("BillboardGui", { Size = UDim2.new(0, 100, 0, 25), StudsOffset = Vector3.new(0, 1.8, 0), AlwaysOnTop = true, Adornee = part, Parent = part })
    Create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Color3.new(1,1,1), TextStrokeTransparency = 0, TextSize = 11, Font = Enum.Font.GothamBold, Parent = bill })

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

-- FIXED FREECAM (GIỮ NÚT DI CHUYỂN HOẠT ĐỘNG BÌNH THƯỜNG)
CreateCheckbox(ESPPage, "freecam", function(v)
    Settings.Freecam = v
    local char = LocalPlayer.Character

    if v then
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = true end
            end
        end
        FreecamPos = Camera.CFrame.Position
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

--==================================================
-- RENDER LOOP & ESP / TRACE / HITBOX FIX
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

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    -- Speed & Jump
    if hum then
        if Settings.Speed.Enabled then hum.WalkSpeed = Settings.Speed.Value end
        if Settings.Jump.Enabled then hum.UseJumpPower = true; hum.JumpPower = Settings.Jump.Value end
    end

    -- Noclip
    if Settings.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- Fly Vertical Fix
    if Settings.Fly and myRoot and hum then
        local moveDir = hum.MoveDirection
        local flyVel = moveDir * 50
        local ySpeed = (flyUpHeld and 40 or 0) - (flyDownHeld and 40 or 0)
        myRoot.AssemblyLinearVelocity = Vector3.new(flyVel.X, ySpeed, flyVel.Z)
    end

    -- No Gravity
    if Settings.NoGravity and myRoot then
        local bv = myRoot:FindFirstChild("NoGravForce") or Create("BodyVelocity", { Name = "NoGravForce", MaxForce = Vector3.new(0, 100000, 0), Velocity = Vector3.zero, Parent = myRoot })
    elseif myRoot and myRoot:FindFirstChild("NoGravForce") and not Settings.Fly then
        myRoot.NoGravForce:Destroy()
    end

    -- FREECAM DIEU KHIEN BANG CAN GAT/MUT DI CHUYEN ROBLOX
    if Settings.Freecam then
        Camera.CameraType = Enum.CameraType.Scriptable
        local speed = 1.5
        local moveDir = (hum and hum.MoveDirection) or Vector3.zero
        
        if flyUpHeld then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if flyDownHeld then moveDir = moveDir - Vector3.new(0, 1, 0) end

        FreecamPos = FreecamPos + (moveDir * speed)
        Camera.CFrame = CFrame.new(FreecamPos) * (Camera.CFrame - Camera.CFrame.Position)
    end

    -- Fullbright
    if Settings.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end

    -- PLAYER ESP / HITBOX / TRACE LOGIC
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = myRoot and (myRoot.Position - targetRoot.Position).Magnitude or 9999

                -- 1. PLAYER ESP
                local espTag = targetRoot:FindFirstChild("ToanESP")
                if Settings.PlayerESP then
                    if not espTag then
                        local bill = Create("BillboardGui", { Name = "ToanESP", Size = UDim2.new(0, 120, 0, 20), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, Adornee = targetRoot, Parent = targetRoot })
                        Create("TextLabel", { Name = "Txt", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextSize = 11, Font = Enum.Font.GothamBold, Parent = bill })
                    end
                    local label = targetRoot.ToanESP.Txt
                    local displayStr = p.Name
                    if Settings.DistanceCheck and dist <= 50 then
                        displayStr = displayStr .. " [•]"
                        label.TextColor3 = COLORS.Yellow
                    else
                        label.TextColor3 = Settings.PlayerESPColor
                    end
                    label.Text = displayStr
                elseif espTag then
                    espTag:Destroy()
                end

                -- 2. HITBOX XEM XUYÊN TƯỜNG CẢ TRONG TRẬN (BoxHandleAdornment)
                local hb = targetRoot:FindFirstChild("ToanHitboxAdorn")
                if Settings.PlayerHitbox then
                    if not hb then
                        hb = Create("BoxHandleAdornment", {
                            Name = "ToanHitboxAdorn",
                            Size = Vector3.new(4, 5, 4),
                            AlwaysOnTop = true, -- Xuyên tường cả trong trận
                            ZIndex = 10,
                            Transparency = 0.5,
                            Adornee = targetRoot,
                            Parent = targetRoot
                        })
                    end
                    hb.Color3 = Settings.PlayerHitboxColor
                elseif hb then
                    hb:Destroy()
                end

                -- 3. ESP TRACE LINE (DRAWING API - HOẠT ĐỘNG 100%)
                local line = GetLine(p)
                if Settings.PlayerTrace then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetRoot.Position)
                    if onScreen then
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(screenPos.X, screenPos.Y)
                        line.Color = Settings.PlayerTraceColor
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

-- Clear Trace lines khi người chơi rời khỏi game
Players.PlayerRemoving:Connect(function(p)
    if TraceLines[p] then
        TraceLines[p]:Remove()
        TraceLines[p] = nil
    end
end)

--==================================================
-- MINIMIZE BUTTON FIX (TC -> AVATAR & CLICK 1 LẦN)
--==================================================

local MiniButton = Create("ImageButton", {
    Size = UDim2.new(0, 45, 0, 45),
    Position = UDim2.new(0, 15, 0.5, -22),
    Image = "https://i.ibb.co/G4sFk4K6/1781919848774.png",
    BackgroundTransparency = 1,
    Visible = false,
    Parent = ScreenGui
})
AddCorner(MiniButton, 22)
MakeDraggable(MiniButton, MiniButton)

-- Mở Menu chỉ với 1 LẦN BẤM
MiniButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    MiniButton.Visible = false
end)

MinimizeButton.MouseButton1Click:Connect(function()
    Main.Visible = false
    MiniButton.Visible = true
end)

-- CONFIRM CLOSE
local ConfirmOverlay = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, Visible = false, ZIndex = 10, Parent = ScreenGui })
local ConfirmBox = Create("Frame", { Size = UDim2.new(0, 190, 0, 100), Position = UDim2.new(0.5, -95, 0.5, -50), BackgroundColor3 = COLORS.Panel, ZIndex = 11, Parent = ConfirmOverlay })
AddCorner(ConfirmBox, 8)

Create("TextLabel", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 10), BackgroundTransparency = 1, Text = "Close Script?", TextColor3 = COLORS.Text, TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 12, Parent = ConfirmBox })

local YesBtn = Create("TextButton", { Size = UDim2.new(0, 70, 0, 24), Position = UDim2.new(0, 18, 1, -34), BackgroundColor3 = COLORS.Red, Text = "Yes", TextColor3 = Color3.new(1,1,1), TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 12, Parent = ConfirmBox })
AddCorner(YesBtn, 5)

local NoBtn = Create("TextButton", { Size = UDim2.new(0, 70, 0, 24), Position = UDim2.new(1, -88, 1, -34), BackgroundColor3 = COLORS.Button, Text = "No", TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 12, Parent = ConfirmBox })
AddCorner(NoBtn, 5)

CloseButton.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = true end)
NoBtn.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = false end)
YesBtn.MouseButton1Click:Connect(function()
    for _, l in pairs(TraceLines) do l:Remove() end
    if workspace:FindFirstChild("ToanCreator_Markers") then workspace.ToanCreator_Markers:Destroy() end
    ScreenGui:Destroy()
end)

print("ToanCreator GUI Updated Successfully!")
