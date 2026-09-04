--[[
    ToanCreator GUI
    Roblox Mobile Script
    Credit: ToanCreator
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- CONFIG & SETTINGS
--==================================================

local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    Panel = Color3.fromRGB(25, 25, 30),
    Panel2 = Color3.fromRGB(32, 32, 40),
    Button = Color3.fromRGB(42, 42, 52),
    ButtonHover = Color3.fromRGB(55, 55, 68),
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
    PlayerTraceColor = Color3.fromRGB(0, 0, 0),

    DistanceCheck = false,
    Freecam = false,

    Fullbright = false,
    FixLag = false,
    AutoExecute = false,
}

local Locations = {}
local Connections = {}

-- Auto Execute Support (Delta / Executors)
local function RegisterAutoExecute()
    local queueFunc = queue_on_teleport or (syn and syn.queue_on_teleport) or queue_for_teleport
    if queueFunc and Settings.AutoExecute then
        -- Lưu đường dẫn script hoặc logic tải lại script tại đây
        queueFunc([[
            task.wait(1)
            print("Auto Executed ToanCreator GUI!")
        ]])
    end
end

--==================================================
-- UTILITY FUNCTIONS
--==================================================

local function Create(className, properties)
    local obj = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        obj[prop] = val
    end
    return obj
end

local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function AddStroke(parent, color, thickness)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 70),
        Thickness = thickness or 1,
        Parent = parent
    })
end

--==================================================
-- SCREEN GUI & MAIN WINDOW (MOBILE OPTIMIZED: 270x360)
--==================================================

local ScreenGui = Create("ScreenGui", {
    Name = "ToanCreatorGUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui,
})

local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 270, 0, 360),
    Position = UDim2.new(0.5, -135, 0.5, -180),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    Parent = ScreenGui,
})

AddCorner(Main, 10)
AddStroke(Main, Color3.fromRGB(60, 60, 75), 1.5)

--==================================================
-- HEADER & BUTTONS (MINIMIZE / CLOSE)
--==================================================

local Header = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Parent = Main,
})
AddCorner(Header, 10)

local HeaderCover = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Parent = Header,
})

Create("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "ToanCreator",
    TextColor3 = COLORS.Text,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header,
})

local MinimizeButton = Create("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -56, 0, 6),
    BackgroundColor3 = COLORS.Button,
    Text = "—",
    TextColor3 = COLORS.Text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    Parent = Header,
})
AddCorner(MinimizeButton, 5)

local CloseButton = Create("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -28, 0, 6),
    BackgroundColor3 = COLORS.Button,
    Text = "×",
    TextColor3 = COLORS.Text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    Parent = Header,
})
AddCorner(CloseButton, 5)

--==================================================
-- DRAGGABLE SYSTEM (NHẤN GIỮ VIỀN BẢNG ĐỂ DỊCH CHUYỂN)
--==================================================

local function MakeDraggable(frame, dragHandle)
    local dragging, dragStart, startPos
    dragHandle = dragHandle or frame

    dragHandle.InputBegan:Connect(function(input)
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
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

MakeDraggable(Main, Main)

--==================================================
-- TAB BAR & CONTENT CONTAINER
--==================================================

local TabBar = Create("ScrollingFrame", {
    Size = UDim2.new(1, -12, 0, 30),
    Position = UDim2.new(0, 6, 0, 40),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X,
    Parent = Main,
})

Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    Parent = TabBar,
})

local Content = Create("Frame", {
    Size = UDim2.new(1, -12, 1, -78),
    Position = UDim2.new(0, 6, 0, 74),
    BackgroundTransparency = 1,
    Parent = Main,
})

local Tabs, Pages = {}, {}

local function CreateTab(name)
    local btn = Create("TextButton", {
        Size = UDim2.new(0, 75, 1, 0),
        BackgroundColor3 = COLORS.Button,
        Text = name,
        TextColor3 = COLORS.SubText,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = TabBar,
    })
    AddCorner(btn, 5)

    local page = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = Content,
    })

    Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        Parent = page,
    })

    Tabs[name] = btn
    Pages[name] = page

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

--==================================================
-- UI CREATION COMPONENTS
--==================================================

local function CreateCheckbox(parent, label, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -2, 0, 32),
        BackgroundColor3 = COLORS.Panel,
        Parent = parent,
    })
    AddCorner(holder, 5)

    Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local check = Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundColor3 = COLORS.Button,
        Text = "",
        Parent = holder,
    })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local state = false
    check.MouseButton1Click:Connect(function()
        state = not state
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        check.TextSize = 12
        if callback then callback(state) end
    end)

    return holder
end

local function CreateNumberInput(parent, label, defaultVal, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -2, 0, 32),
        BackgroundColor3 = COLORS.Panel,
        Parent = parent,
    })
    AddCorner(holder, 5)

    Create("TextLabel", {
        Size = UDim2.new(1, -75, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local input = Create("TextBox", {
        Size = UDim2.new(0, 60, 0, 22),
        Position = UDim2.new(1, -65, 0.5, -11),
        BackgroundColor3 = COLORS.Button,
        Text = tostring(defaultVal),
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = holder,
    })
    AddCorner(input, 4)

    input.FocusLost:Connect(function()
        local num = tonumber(input.Text)
        if num then
            if callback then callback(num) end
        else
            input.Text = tostring(defaultVal)
        end
    end)

    return holder
end

local function CreateColorPicker(parent, label, defaultColor, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -2, 0, 32),
        BackgroundColor3 = COLORS.Panel,
        Parent = parent,
    })
    AddCorner(holder, 5)

    Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local colorBtn = Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundColor3 = defaultColor,
        Text = "",
        Parent = holder,
    })
    AddCorner(colorBtn, 4)

    local colors = {
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 80, 80),
        Color3.fromRGB(80, 220, 130), Color3.fromRGB(75, 170, 255),
        Color3.fromRGB(255, 215, 70), Color3.fromRGB(0, 0, 0)
    }
    local idx = 1

    colorBtn.MouseButton1Click:Connect(function()
        idx = (idx % #colors) + 1
        local newColor = colors[idx]
        colorBtn.BackgroundColor3 = newColor
        if callback then callback(newColor) end
    end)

    return holder
end

--==================================================
-- MOVE TAB SETUP
--==================================================

CreateNumberInput(MovePage, "speed: enter num", Settings.Speed.Value, function(v) Settings.Speed.Value = v end)
CreateCheckbox(MovePage, "enable speed", function(v) Settings.Speed.Enabled = v end)

CreateNumberInput(MovePage, "jump: enter num", Settings.Jump.Value, function(v) Settings.Jump.Value = v end)
CreateCheckbox(MovePage, "enable jump", function(v) Settings.Jump.Enabled = v end)

-- FLY & MOBILE CONTROLS
local FlyControls = Create("Frame", {
    Size = UDim2.new(0, 110, 0, 50),
    Position = UDim2.new(1, -120, 0.5, -25),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = ScreenGui,
})

local FlyUp = Create("TextButton", {
    Size = UDim2.new(0, 48, 0, 48),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = COLORS.Accent,
    Text = "↑",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    Parent = FlyControls,
})
AddCorner(FlyUp, 24)

local FlyDown = Create("TextButton", {
    Size = UDim2.new(0, 48, 0, 48),
    Position = UDim2.new(0, 56, 0, 0),
    BackgroundColor3 = COLORS.Accent,
    Text = "↓",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    Parent = FlyControls,
})
AddCorner(FlyDown, 24)

local flyUpHeld, flyDownHeld = false, false
FlyUp.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyUpHeld = true end end)
FlyUp.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyUpHeld = false end end)
FlyDown.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyDownHeld = true end end)
FlyDown.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then flyDownHeld = false end end)

CreateCheckbox(MovePage, "fly", function(v)
    Settings.Fly = v
    FlyControls.Visible = v
end)

CreateCheckbox(MovePage, "noclip", function(v) Settings.Noclip = v end)
CreateCheckbox(MovePage, "no gravity", function(v) Settings.NoGravity = v end)

-- TP PLAYER
local selectedPlayer = nil
local TpPlayerHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = MovePage })
AddCorner(TpPlayerHolder, 5)

local PlayerListBtn = Create("TextButton", {
    Size = UDim2.new(1, -36, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "tp player: none",
    TextColor3 = COLORS.Text,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TpPlayerHolder,
})

local PlayerTpBtn = Create("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -28, 0.5, -12),
    BackgroundColor3 = COLORS.Accent,
    Text = "🖱",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Parent = TpPlayerHolder,
})
AddCorner(PlayerTpBtn, 4)

PlayerListBtn.MouseButton1Click:Connect(function()
    local plist = Players:GetPlayers()
    if #plist <= 1 then return end
    local currentIdx = 1
    for i, p in ipairs(plist) do if p == selectedPlayer then currentIdx = i break end end
    local nextP = plist[(currentIdx % #plist) + 1]
    if nextP == LocalPlayer then nextP = plist[((currentIdx + 1) % #plist) + 1] end
    selectedPlayer = nextP
    PlayerListBtn.Text = "tp player: " .. (selectedPlayer and selectedPlayer.Name or "none")
end)

PlayerTpBtn.MouseButton1Click:Connect(function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
            myRoot.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0)
        end
    end
end)

-- TP LOCATION
local selectedLocation = nil
local TpLocHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = MovePage })
AddCorner(TpLocHolder, 5)

local LocListBtn = Create("TextButton", {
    Size = UDim2.new(1, -36, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "tp location: none",
    TextColor3 = COLORS.Text,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = TpLocHolder,
})

local LocTpBtn = Create("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -28, 0.5, -12),
    BackgroundColor3 = COLORS.Accent,
    Text = "🖱",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Parent = TpLocHolder,
})
AddCorner(LocTpBtn, 4)

local SetLocHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = MovePage })
AddCorner(SetLocHolder, 5)

local LocNameInput = Create("TextBox", {
    Size = UDim2.new(1, -55, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "+ set locate",
    PlaceholderColor3 = COLORS.SubText,
    TextColor3 = COLORS.Text,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    Parent = SetLocHolder,
})

local SetBtn = Create("TextButton", {
    Size = UDim2.new(0, 40, 0, 22),
    Position = UDim2.new(1, -45, 0.5, -11),
    BackgroundColor3 = COLORS.Green,
    Text = "Set",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    Parent = SetLocHolder,
})
AddCorner(SetBtn, 4)

local function CreateLocationMarker(name, cframe)
    local folder = workspace:FindFirstChild("ToanCreator_Markers") or Create("Folder", { Name = "ToanCreator_Markers", Parent = workspace })

    local part = Create("Part", {
        Name = name,
        Size = Vector3.new(1.5, 1.5, 1.5),
        Position = cframe.Position,
        Anchored = true,
        CanCollide = false,
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(160, 255, 200),
        Transparency = 0.2,
        Parent = folder,
    })

    local bill = Create("BillboardGui", {
        Size = UDim2.new(0, 120, 0, 30),
        StudsOffset = Vector3.new(0, 2, 0),
        AlwaysOnTop = true,
        Adornee = part,
        Parent = part,
    })

    Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.new(1, 1, 1),
        TextStrokeTransparency = 0,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = bill,
    })
end

SetBtn.MouseButton1Click:Connect(function()
    local name = LocNameInput.Text
    if name == "" or #Locations >= 10 then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local locData = { Name = name, CFrame = myRoot.CFrame }
    table.insert(Locations, locData)
    CreateLocationMarker(name, myRoot.CFrame)

    LocNameInput.Text = ""
    selectedLocation = locData
    LocListBtn.Text = "tp location: " .. name
end)

LocListBtn.MouseButton1Click:Connect(function()
    if #Locations == 0 then return end
    local currentIdx = 0
    for i, l in ipairs(Locations) do if l == selectedLocation then currentIdx = i break end end
    selectedLocation = Locations[(currentIdx % #Locations) + 1]
    LocListBtn.Text = "tp location: " .. selectedLocation.Name
end)

LocTpBtn.MouseButton1Click:Connect(function()
    if selectedLocation then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = selectedLocation.CFrame * CFrame.new(0, 2, 0) end
    end
end)

--==================================================
-- ESP TAB SETUP
--==================================================

CreateColorPicker(ESPPage, "player ESP color", Settings.PlayerESPColor, function(c) Settings.PlayerESPColor = c end)
CreateCheckbox(ESPPage, "player ESP", function(v) Settings.PlayerESP = v end)

CreateColorPicker(ESPPage, "player hitbox color", Settings.PlayerHitboxColor, function(c) Settings.PlayerHitboxColor = c end)
CreateCheckbox(ESPPage, "player hitbox", function(v) Settings.PlayerHitbox = v end)

CreateColorPicker(ESPPage, "player trace color", Settings.PlayerTraceColor, function(c) Settings.PlayerTraceColor = c end)
CreateCheckbox(ESPPage, "player trace", function(v) Settings.PlayerTrace = v end)

CreateCheckbox(ESPPage, "distance check", function(v) Settings.DistanceCheck = v end)
CreateCheckbox(ESPPage, "freecam", function(v) Settings.Freecam = v end)

--==================================================
-- OPTION TAB SETUP
--==================================================

CreateCheckbox(OptionPage, "fullbright", function(v) Settings.Fullbright = v end)
CreateCheckbox(OptionPage, "fixlag", function(v) Settings.FixLag = v end)
CreateCheckbox(OptionPage, "auto execute", function(v)
    Settings.AutoExecute = v
    RegisterAutoExecute()
end)

--==================================================
-- ESP / HITBOX / TRACE LOGIC
--==================================================

local ESPFolder = Create("Folder", { Name = "ToanCreator_ESPFolder", Parent = ScreenGui })

RunService.RenderStepped:Connect(function()
    ESPFolder:ClearAllChildren()

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    -- Movement Modifications
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Settings.Speed.Enabled then hum.WalkSpeed = Settings.Speed.Value end
        if Settings.Jump.Enabled then hum.UseJumpPower = true; hum.JumpPower = Settings.Jump.Value end
    end

    if Settings.Noclip and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    workspace.Gravity = Settings.NoGravity and 0 or 196.2

    -- Fly Vertical Logic
    if Settings.Fly and myRoot then
        local flyVel = myRoot:FindFirstChild("ToanFlyVel") or Create("BodyVelocity", {
            Name = "ToanFlyVel",
            MaxForce = Vector3.new(100000, 100000, 100000),
            Velocity = Vector3.zero,
            Parent = myRoot
        })
        local yDir = (flyUpHeld and 50 or 0) - (flyDownHeld and 50 or 0)
        flyVel.Velocity = Vector3.new(0, yDir, 0)
    else
        if myRoot and myRoot:FindFirstChild("ToanFlyVel") then
            myRoot.ToanFlyVel:Destroy()
        end
    end

    -- ESP Loops
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pRoot = p.Character.HumanoidRootPart
            local dist = myRoot and (myRoot.Position - pRoot.Position).Magnitude or 0

            -- Player ESP
            if Settings.PlayerESP then
                local bill = Create("BillboardGui", {
                    Size = UDim2.new(0, 100, 0, 20),
                    StudsOffset = Vector3.new(0, 3, 0),
                    AlwaysOnTop = true,
                    Adornee = pRoot,
                    Parent = ESPFolder
                })
                local textStr = p.Name
                if Settings.DistanceCheck and dist <= 50 then textStr = textStr .. " [•]" end

                Create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = textStr,
                    TextColor3 = (Settings.DistanceCheck and dist <= 50) and COLORS.Yellow or Settings.PlayerESPColor,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    Parent = bill
                })
            end

            -- Player Hitbox
            if Settings.PlayerHitbox then
                local box = Create("SelectionBox", {
                    Adornee = p.Character,
                    Color3 = Settings.PlayerHitboxColor,
                    LineThickness = 0.05,
                    SurfaceColor3 = Settings.PlayerHitboxColor,
                    SurfaceTransparency = 0.8,
                    Parent = ESPFolder
                })
            end
        end
    end
end)

--==================================================
-- MINIMIZE & CLOSE CONFIRMATION SYSTEM
--==================================================

local MiniButton = Create("TextButton", {
    Size = UDim2.new(0, 42, 0, 42),
    Position = UDim2.new(0, 15, 0.5, -21),
    BackgroundColor3 = COLORS.Accent,
    Text = "TC",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Visible = false,
    Parent = ScreenGui,
})
AddCorner(MiniButton, 8)
MakeDraggable(MiniButton, MiniButton)

local lastClickTime = 0
MiniButton.MouseButton1Click:Connect(function()
    local now = os.clock()
    if now - lastClickTime <= 0.35 then
        Main.Visible = true
        MiniButton.Visible = false
    end
    lastClickTime = now
end)

MinimizeButton.MouseButton1Click:Connect(function()
    Main.Visible = false
    MiniButton.Visible = true
end)

-- Close Alert Dialog
local ConfirmOverlay = Create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.5,
    Visible = false,
    ZIndex = 10,
    Parent = ScreenGui,
})

local ConfirmBox = Create("Frame", {
    Size = UDim2.new(0, 200, 0, 110),
    Position = UDim2.new(0.5, -100, 0.5, -55),
    BackgroundColor3 = COLORS.Panel2,
    ZIndex = 11,
    Parent = ConfirmOverlay,
})
AddCorner(ConfirmBox, 8)
AddStroke(ConfirmBox, Color3.fromRGB(80, 80, 95), 1)

Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 10),
    BackgroundTransparency = 1,
    Text = "Close Script?",
    TextColor3 = COLORS.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    ZIndex = 12,
    Parent = ConfirmBox,
})

local YesBtn = Create("TextButton", {
    Size = UDim2.new(0, 75, 0, 26),
    Position = UDim2.new(0, 18, 1, -36),
    BackgroundColor3 = COLORS.Red,
    Text = "Yes",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    ZIndex = 12,
    Parent = ConfirmBox,
})
AddCorner(YesBtn, 5)

local NoBtn = Create("TextButton", {
    Size = UDim2.new(0, 75, 0, 26),
    Position = UDim2.new(1, -93, 1, -36),
    BackgroundColor3 = COLORS.Button,
    Text = "No",
    TextColor3 = COLORS.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    ZIndex = 12,
    Parent = ConfirmBox,
})
AddCorner(NoBtn, 5)

CloseButton.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = true end)
NoBtn.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = false end)
YesBtn.MouseButton1Click:Connect(function()
    if workspace:FindFirstChild("ToanCreator_Markers") then
        workspace.ToanCreator_Markers:Destroy()
    end
    ScreenGui:Destroy()
end)

print("ToanCreator GUI Loaded Successfully!")
