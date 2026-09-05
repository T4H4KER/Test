--[[
    ToanCreator GUI - Dynamic Resizing, Auto Config & Distance Slider Upgrade
    Mobile & PC Optimized (Color Pickers Removed, Fixed Default Colors & Red Name Damage Logic Enabled)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

-- PREVENT MULTIPLE EXECUTIONS
if getgenv and getgenv().ToanCreatorLoaded then
    return
end
if getgenv then getgenv().ToanCreatorLoaded = true end

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local MasterControl = nil
pcall(function()
    MasterControl = require(PlayerScripts:WaitForChild("PlayerModule")):GetControls()
end)

--==================================================
-- AUTO EXECUTE / TELEPORT QUEUE FIX
--==================================================
local function GetQueueOnTeleport()
    return queue_on_teleport 
        or (syn and syn.queue_on_teleport) 
        or (fluxus and fluxus.queue_on_teleport)
        or (sentinel and sentinel.queue_on_teleport)
        or (krnl and krnl.queue_on_teleport)
        or (delta and delta.queue_on_teleport)
        or (codex and codex.queue_on_teleport)
end

local SCRIPT_LOADER_CODE = [[
    repeat task.wait() until game:IsLoaded()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/T4H4KER/Test/refs/heads/main/ESP.lua"))()
]]

--==================================================
-- CONFIG & AUTO-SAVE FILE STORAGE SYSTEM
--==================================================

local CONFIG_FILE_NAME = "ToanCreator_Configs.json"
local AUTO_CONFIG_FILE_NAME = "ToanCreator_AutoConfig.json"

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
    DistanceCheckValue = 50,
    Freecam = false,

    Fullbright = false,
    FixLag = false,
    AutoExecute = false,
    ShiftLock = false,
    MenuLock = false
}

local Settings = {}
for k, v in pairs(DefaultSettings) do Settings[k] = v end

local Locations = {}
local SavedConfigs = {}
local SelectedPlayer = nil
local SelectedLocation = nil
local UI_Controls = {}

local function Color3ToTable(c) return {R = c.R, G = c.G, B = c.B} end
local function TableToColor3(t) return Color3.new(t.R or 1, t.G or 1, t.B or 1) end

local function FormatConfigData(cfgData)
    return {
        Speed = cfgData.Speed or { Enabled = false, Value = 16 },
        Jump = cfgData.Jump or { Enabled = false, Value = 50 },
        Fly = cfgData.Fly or false,
        Noclip = cfgData.Noclip or false,
        NoGravity = cfgData.NoGravity or false,
        PlayerESP = cfgData.PlayerESP or false,
        PlayerESPColor = (type(cfgData.PlayerESPColor) == "table" and TableToColor3(cfgData.PlayerESPColor)) or cfgData.PlayerESPColor or Color3.fromRGB(255,255,255),
        PlayerHitbox = cfgData.PlayerHitbox or false,
        PlayerHitboxColor = (type(cfgData.PlayerHitboxColor) == "table" and TableToColor3(cfgData.PlayerHitboxColor)) or cfgData.PlayerHitboxColor or Color3.fromRGB(255,80,80),
        PlayerTrace = cfgData.PlayerTrace or false,
        PlayerTraceColor = (type(cfgData.PlayerTraceColor) == "table" and TableToColor3(cfgData.PlayerTraceColor)) or cfgData.PlayerTraceColor or Color3.fromRGB(0,170,255),
        DistanceCheck = cfgData.DistanceCheck or false,
        DistanceCheckValue = cfgData.DistanceCheckValue or 50,
        Freecam = cfgData.Freecam or false,
        Fullbright = cfgData.Fullbright or false,
        FixLag = cfgData.FixLag or false,
        AutoExecute = cfgData.AutoExecute or false,
        ShiftLock = cfgData.ShiftLock or false,
        MenuLock = cfgData.MenuLock or false
    }
end

local function SerializeConfigData(cfgData)
    return {
        Speed = cfgData.Speed,
        Jump = cfgData.Jump,
        Fly = cfgData.Fly,
        Noclip = cfgData.Noclip,
        NoGravity = cfgData.NoGravity,
        PlayerESP = cfgData.PlayerESP,
        PlayerESPColor = Color3ToTable(cfgData.PlayerESPColor or Color3.fromRGB(255,255,255)),
        PlayerHitbox = cfgData.PlayerHitbox,
        PlayerHitboxColor = Color3ToTable(cfgData.PlayerHitboxColor or Color3.fromRGB(255,80,80)),
        PlayerTrace = cfgData.PlayerTrace,
        PlayerTraceColor = Color3ToTable(cfgData.PlayerTraceColor or Color3.fromRGB(0,170,255)),
        DistanceCheck = cfgData.DistanceCheck,
        DistanceCheckValue = cfgData.DistanceCheckValue,
        Freecam = cfgData.Freecam,
        Fullbright = cfgData.Fullbright,
        FixLag = cfgData.FixLag,
        AutoExecute = cfgData.AutoExecute,
        ShiftLock = cfgData.ShiftLock,
        MenuLock = cfgData.MenuLock
    }
end

local function SaveAutoConfig()
    if writefile then
        pcall(function()
            writefile(AUTO_CONFIG_FILE_NAME, HttpService:JSONEncode(SerializeConfigData(Settings)))
        end)
    end
end

local function LoadAutoConfig()
    if readfile and isfile and isfile(AUTO_CONFIG_FILE_NAME) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(AUTO_CONFIG_FILE_NAME))
        end)
        if success and result then
            return FormatConfigData(result)
        end
    end
    return nil
end

local function LoadSavedConfigsFromFile()
    if readfile and isfile and isfile(CONFIG_FILE_NAME) then
        local success, result = pcall(function()
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE_NAME))
            local formatted = {}
            for cfgName, cfgData in pairs(decoded) do
                formatted[cfgName] = FormatConfigData(cfgData)
            end
            return formatted
        end)
        if success and result then SavedConfigs = result end
    end
end

local function SaveConfigsToFile()
    if writefile then
        pcall(function()
            local dataToSave = {}
            for cfgName, cfgData in pairs(SavedConfigs) do
                dataToSave[cfgName] = SerializeConfigData(cfgData)
            end
            writefile(CONFIG_FILE_NAME, HttpService:JSONEncode(dataToSave))
        end)
    end
end

LoadSavedConfigsFromFile()

-- Freecam State
local FreecamPos = Vector3.zero
local freecamYaw = 0
local freecamPitch = 0

-- Tracking
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
    Name = "ToanCreatorGUI_v9",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui,
})

local Main = Create("Frame", {
    Size = UDim2.new(0, 270, 0, 380),
    Position = UDim2.new(0.5, -135, 0.5, -190),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    Parent = ScreenGui,
})
AddCorner(Main, 10)
local MainStroke = AddStroke(Main, Color3.fromRGB(60, 60, 75), 1.5)

-- WATERFLOW BORDER EFFECT FOR RESIZING
local MainGradient = Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 50, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
    }),
    Enabled = false,
    Parent = MainStroke
})

local flowConnection = nil
local function SetWaterflowBorder(enable)
    MainGradient.Enabled = enable
    MainStroke.Color = enable and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 75)
    MainStroke.Thickness = enable and 2.5 or 1.5
    
    if enable then
        if not flowConnection then
            flowConnection = RunService.RenderStepped:Connect(function()
                MainGradient.Rotation = (tick() * 180) % 360
            end)
        end
    else
        if flowConnection then
            flowConnection:Disconnect()
            flowConnection = nil
        end
    end
end

-- RESIZING SYSTEM FROM 4 CORNERS
local MIN_WIDTH = 240
local MIN_HEIGHT = 300

local function SetupCornerResize(handle, cornerType)
    local resizing = false
    local startInputPos, startSize, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startInputPos = input.Position
            startSize = Main.AbsoluteSize
            startPos = Main.Position
            SetWaterflowBorder(true)

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    SetWaterflowBorder(false)
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInputPos
            local newW, newH = startSize.X, startSize.Y
            local newXOffset, newYOffset = startPos.X.Offset, startPos.Y.Offset

            if cornerType == "BR" then
                newW = math.max(MIN_WIDTH, startSize.X + delta.X)
                newH = math.max(MIN_HEIGHT, startSize.Y + delta.Y)
            elseif cornerType == "BL" then
                local w = startSize.X - delta.X
                if w >= MIN_WIDTH then
                    newW = w
                    newXOffset = startPos.X.Offset + delta.X
                end
                newH = math.max(MIN_HEIGHT, startSize.Y + delta.Y)
            elseif cornerType == "TR" then
                newW = math.max(MIN_WIDTH, startSize.X + delta.X)
                local h = startSize.Y - delta.Y
                if h >= MIN_HEIGHT then
                    newH = h
                    newYOffset = startPos.Y.Offset + delta.Y
                end
            elseif cornerType == "TL" then
                local w = startSize.X - delta.X
                if w >= MIN_WIDTH then
                    newW = w
                    newXOffset = startPos.X.Offset + delta.X
                end
                local h = startSize.Y - delta.Y
                if h >= MIN_HEIGHT then
                    newH = h
                    newYOffset = startPos.Y.Offset + delta.Y
                end
            end

            Main.Size = UDim2.new(0, newW, 0, newH)
            Main.Position = UDim2.new(startPos.X.Scale, newXOffset, startPos.Y.Scale, newYOffset)
        end
    end)
end

local Corners = {
    TL = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 10, Parent = Main }),
    TR = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, ZIndex = 10, Parent = Main }),
    BL = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 0, 1, -16), BackgroundTransparency = 1, ZIndex = 10, Parent = Main }),
    BR = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -16, 1, -16), BackgroundTransparency = 1, ZIndex = 10, Parent = Main }),
}

for cornerType, handle in pairs(Corners) do
    SetupCornerResize(handle, cornerType)
end

local function MakeDraggable(frame, handle, canDragCheck)
    local dragging, dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if canDragCheck and not canDragCheck() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            local touchConn
            touchConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if touchConn then touchConn:Disconnect() end
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
        Size = UDim2.new(0.32, 0, 1, 0), BackgroundColor3 = COLORS.Button, Text = name,
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
-- UI COMPONENTS & CONTROLS BINDING
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

local function CreateCombinedInput(id, parent, labelText, defaultVal, onValueChange, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)
    Create("TextLabel", { Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

    local input = Create("TextBox", { Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -85, 0.5, -10), BackgroundColor3 = COLORS.Button, Text = tostring(defaultVal), TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false, Parent = holder })
    AddCorner(input, 4)

    local check = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0.5, -10), BackgroundColor3 = COLORS.Button, Text = "", Parent = holder })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local state = false
    local function setCheckState(st, skipSave)
        state = st
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
        if not skipSave then SaveAutoConfig() end
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    input.FocusLost:Connect(function()
        local num = tonumber(input.Text)
        if num then 
            if onValueChange then onValueChange(num) end 
            SaveAutoConfig()
        else 
            input.Text = tostring(defaultVal) 
        end
    end)

    UI_Controls[id] = {
        SetState = function(s) setCheckState(s, true) end,
        SetValue = function(v) input.Text = tostring(v); if onValueChange then onValueChange(v) end end
    }
    return holder
end

local function CreateCheckbox(id, parent, labelText, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)
    Create("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

    local check = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0.5, -10), BackgroundColor3 = COLORS.Button, Text = "", Parent = holder })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local state = false
    local function setCheckState(st, skipSave)
        state = st
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
        if not skipSave then SaveAutoConfig() end
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    UI_Controls[id] = { SetState = function(s) setCheckState(s, true) end }
    return check
end

-- DISTANCE SLIDER COMPONENT (MIN: 0, MAX: 100, DEFAULT: 50)
local function CreateDistanceSlider(parent)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 52), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)

    local titleLbl = Create("TextLabel", { Size = UDim2.new(1, -40, 0, 20), Position = UDim2.new(0, 8, 0, 4), BackgroundTransparency = 1, Text = "distance check", TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

    local check = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0, 4), BackgroundColor3 = COLORS.Button, Text = "", Parent = holder })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local sliderContainer = Create("Frame", { Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 8, 0, 28), BackgroundTransparency = 1, Parent = holder })
    
    local lineBg = Create("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), BackgroundColor3 = COLORS.Button, BorderSizePixel = 0, Parent = sliderContainer })
    AddCorner(lineBg, 2)

    local lineFill = Create("Frame", { Size = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = COLORS.Accent, BorderSizePixel = 0, Parent = lineBg })
    AddCorner(lineFill, 2)

    local knob = Create("Frame", { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0.5, -7), BackgroundColor3 = COLORS.Text, Parent = sliderContainer })
    AddCorner(knob, 7)
    AddStroke(knob, COLORS.Accent, 1.5)

    local valLbl = Create("TextLabel", { Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -68, 0, 4), BackgroundTransparency = 1, Text = "50", TextColor3 = COLORS.SubText, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = holder })

    local isDragging = false
    local function UpdateSlider(inputPos)
        local relX = math.clamp(inputPos.X - sliderContainer.AbsolutePosition.X, 0, sliderContainer.AbsoluteSize.X)
        local percent = relX / sliderContainer.AbsoluteSize.X
        local val = math.floor(percent * 100)

        lineFill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -7, 0.5, -7)
        valLbl.Text = tostring(val)

        Settings.DistanceCheckValue = val
    end

    sliderContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UpdateSlider(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            isDragging = false
            SaveAutoConfig()
        end
    end)

    local state = false
    local function setCheckState(st, skipSave)
        state = st
        Settings.DistanceCheck = st
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if not skipSave then SaveAutoConfig() end
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    UI_Controls["DistanceCheck"] = {
        SetState = function(s) setCheckState(s, true) end,
        SetValue = function(v)
            v = math.clamp(v or 50, 0, 100)
            Settings.DistanceCheckValue = v
            local percent = v / 100
            lineFill.Size = UDim2.new(percent, 0, 1, 0)
            knob.Position = UDim2.new(percent, -7, 0.5, -7)
            valLbl.Text = tostring(v)
        end
    }
end

--==================================================
-- MOVE TAB SETUP & FLY CONTROLS
--==================================================

CreateCombinedInput("Speed", MovePage, "speed: enter num", Settings.Speed.Value, function(v) Settings.Speed.Value = v end, function(s) Settings.Speed.Enabled = s end)
CreateCombinedInput("Jump", MovePage, "jump: enter num", Settings.Jump.Value, function(v) Settings.Jump.Value = v end, function(s) Settings.Jump.Enabled = s end)

local FlyToggleBtn = Create("TextButton", {
    Size = UDim2.new(0, 55, 0, 30),
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 20, 0.5, -30),
    BackgroundColor3 = COLORS.Accent,
    Text = "fly",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    Visible = false,
    ZIndex = 80,
    Parent = ScreenGui
})
AddCorner(FlyToggleBtn, 6)
AddStroke(FlyToggleBtn, Color3.fromRGB(0, 0, 0), 1.5)

local FlyControls = Create("Frame", { 
    Size = UDim2.new(0, 55, 0, 55), 
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.new(0, 20, 0.5, -10),
    BackgroundTransparency = 1, 
    Visible = false, 
    ZIndex = 80,
    Parent = ScreenGui 
})

local FlyUp = Create("TextButton", { Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = COLORS.Accent, Text = "▲", TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.GothamBold, Parent = FlyControls })
AddCorner(FlyUp, 5)
AddStroke(FlyUp, Color3.fromRGB(0, 0, 0), 1)

local FlyDown = Create("TextButton", { Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = COLORS.Accent, Text = "▼", TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.GothamBold, Parent = FlyControls })
AddCorner(FlyDown, 5)
AddStroke(FlyDown, Color3.fromRGB(0, 0, 0), 1)

local flyUpHeld, flyDownHeld = false, false

local function BindPressHold(button, stateUpdate)
    button.MouseButton1Down:Connect(function() stateUpdate(true) end)
    button.MouseButton1Up:Connect(function() stateUpdate(false) end)
    button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then stateUpdate(true) end end)
    button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then stateUpdate(false) end end)
end

BindPressHold(FlyUp, function(st) flyUpHeld = st end)
BindPressHold(FlyDown, function(st) flyDownHeld = st end)

local isFlyingActive = false
FlyToggleBtn.MouseButton1Click:Connect(function()
    isFlyingActive = not isFlyingActive
    FlyControls.Visible = isFlyingActive
    FlyToggleBtn.BackgroundColor3 = isFlyingActive and COLORS.Green or COLORS.Accent
end)

CreateCheckbox("Fly", MovePage, "fly", function(v)
    Settings.Fly = v
    FlyToggleBtn.Visible = v
    if not v then
        isFlyingActive = false
        FlyControls.Visible = false
        FlyToggleBtn.BackgroundColor3 = COLORS.Accent
    end
end)

CreateCheckbox("Noclip", MovePage, "noclip", function(v) Settings.Noclip = v end)
CreateCheckbox("NoGravity", MovePage, "no gravity", function(v)
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

-- CONFIRM OVERLAY (FIXED HIGHEST ZINDEX TO TOP LAYER)
local ConfirmOverlay = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, Visible = false, ZIndex = 100, Parent = ScreenGui })
local ConfirmBox = Create("Frame", { Size = UDim2.new(0, 200, 0, 100), Position = UDim2.new(0.5, -100, 0.5, -50), BackgroundColor3 = COLORS.Panel, ZIndex = 101, Parent = ConfirmOverlay })
AddCorner(ConfirmBox, 8)

local ConfirmText = Create("TextLabel", { Size = UDim2.new(1, -10, 0, 40), Position = UDim2.new(0, 5, 0, 10), BackgroundTransparency = 1, Text = "Confirm Action?", TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.GothamBold, TextWrapped = true, ZIndex = 102, Parent = ConfirmBox })
local ConfirmYes = Create("TextButton", { Size = UDim2.new(0, 75, 0, 24), Position = UDim2.new(0, 15, 1, -34), BackgroundColor3 = COLORS.Red, Text = "Yes", TextColor3 = Color3.new(1,1,1), TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 102, Parent = ConfirmBox })
AddCorner(ConfirmYes, 5)

local ConfirmNo = Create("TextButton", { Size = UDim2.new(0, 75, 0, 24), Position = UDim2.new(1, -90, 1, -34), BackgroundColor3 = COLORS.Button, Text = "No", TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 102, Parent = ConfirmBox })
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

-- TP LOCATION LIST (FIXED SCROLL LIST CONTAINER OVERFLOW)
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
        
        BindLongPress(lBtn, 1, function()
            ShowConfirm("Delete location '"..loc.Name.."'?", function()
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
-- ESP TAB SETUP & FREECAM
--==================================================

CreateCheckbox("PlayerESP", ESPPage, "player ESP", function(s) Settings.PlayerESP = s end)
CreateCheckbox("PlayerHitbox", ESPPage, "player hitbox", function(s) Settings.PlayerHitbox = s end)
CreateCheckbox("PlayerTrace", ESPPage, "player trace", function(s) Settings.PlayerTrace = s end)

CreateDistanceSlider(ESPPage)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if not Settings.Freecam then return end
    
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Delta
        freecamYaw = freecamYaw - delta.X * 0.008
        freecamPitch = math.clamp(freecamPitch - delta.Y * 0.008, math.rad(-88), math.rad(88))
    elseif input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.X > (Camera.ViewportSize.X * 0.35) then
            local delta = input.Delta
            freecamYaw = freecamYaw - delta.X * 0.008
            freecamPitch = math.clamp(freecamPitch - delta.Y * 0.008, math.rad(-88), math.rad(88))
        end
    end
end)

CreateCheckbox("Freecam", ESPPage, "freecam", function(v)
    Settings.Freecam = v
    FlyControls.Visible = v
    local char = LocalPlayer.Character

    if v then
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = true end
            end
        end
        
        FreecamPos = Camera.CFrame.Position
        local x, y, z = Camera.CFrame:ToOrientation()
        freecamYaw = y
        freecamPitch = x
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

Players.PlayerRemoving:Connect(function(player)
    if TraceLines[player] then
        pcall(function() TraceLines[player]:Remove() end)
        TraceLines[player] = nil
    end
    PlayerStats[player] = nil
end)

--==================================================
-- OPTION TAB SETUP
--==================================================

CreateCheckbox("Fullbright", OptionPage, "fullbright", function(v) Settings.Fullbright = v end)
CreateCheckbox("FixLag", OptionPage, "fixlag", function(v)
    Settings.FixLag = v
    if v then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then obj.Material = Enum.Material.SmoothPlastic end
        end
    end
end)

CreateCheckbox("AutoExecute", OptionPage, "auto execute", function(v)
    Settings.AutoExecute = v
    if v then
        local qFunc = GetQueueOnTeleport()
        if qFunc then
            pcall(function() qFunc(SCRIPT_LOADER_CODE) end)
        end
    end
end)

CreateCheckbox("ShiftLock", OptionPage, "shift lock", function(v)
    Settings.ShiftLock = v
end)

CreateCheckbox("MenuLock", OptionPage, "menu lock", function(v)
    Settings.MenuLock = v
end)

local function ApplySettingsToUI(newSettings)
    for k, v in pairs(newSettings) do Settings[k] = v end

    if UI_Controls["Speed"] then UI_Controls["Speed"].SetState(Settings.Speed.Enabled); UI_Controls["Speed"].SetValue(Settings.Speed.Value) end
    if UI_Controls["Jump"] then UI_Controls["Jump"].SetState(Settings.Jump.Enabled); UI_Controls["Jump"].SetValue(Settings.Jump.Value) end

    if UI_Controls["Fly"] then UI_Controls["Fly"].SetState(Settings.Fly) end
    if UI_Controls["Noclip"] then UI_Controls["Noclip"].SetState(Settings.Noclip) end
    if UI_Controls["NoGravity"] then UI_Controls["NoGravity"].SetState(Settings.NoGravity) end

    if UI_Controls["PlayerESP"] then UI_Controls["PlayerESP"].SetState(Settings.PlayerESP) end
    if UI_Controls["PlayerHitbox"] then UI_Controls["PlayerHitbox"].SetState(Settings.PlayerHitbox) end
    if UI_Controls["PlayerTrace"] then UI_Controls["PlayerTrace"].SetState(Settings.PlayerTrace) end

    if UI_Controls["DistanceCheck"] then 
        UI_Controls["DistanceCheck"].SetState(Settings.DistanceCheck)
        UI_Controls["DistanceCheck"].SetValue(Settings.DistanceCheckValue or 50)
    end
    if UI_Controls["Freecam"] then UI_Controls["Freecam"].SetState(Settings.Freecam) end

    if UI_Controls["Fullbright"] then UI_Controls["Fullbright"].SetState(Settings.Fullbright) end
    if UI_Controls["FixLag"] then UI_Controls["FixLag"].SetState(Settings.FixLag) end
    if UI_Controls["AutoExecute"] then UI_Controls["AutoExecute"].SetState(Settings.AutoExecute) end
    if UI_Controls["ShiftLock"] then UI_Controls["ShiftLock"].SetState(Settings.ShiftLock) end
    if UI_Controls["MenuLock"] then UI_Controls["MenuLock"].SetState(Settings.MenuLock) end

    FlyToggleBtn.Visible = Settings.Fly
    if not Settings.Fly then
        isFlyingActive = false
        FlyControls.Visible = false
    end

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.UseJumpPower = false
    end
end

-- RESET & CONFIG
local OptionBtnHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 36), BackgroundTransparency = 1, Parent = OptionPage })
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = OptionBtnHolder })

local ResetBtn = Create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = COLORS.Red, Text = "Reset Default", TextColor3 = Color3.new(1,1,1), TextSize = 11, Font = Enum.Font.GothamBold, Parent = OptionBtnHolder })
AddCorner(ResetBtn, 6)

local ConfigBtn = Create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = COLORS.Accent, Text = "Config", TextColor3 = Color3.new(1,1,1), TextSize = 11, Font = Enum.Font.GothamBold, Parent = OptionBtnHolder })
AddCorner(ConfigBtn, 6)

ResetBtn.MouseButton1Click:Connect(function()
    ShowConfirm("Restore all settings to default?", function()
        ApplySettingsToUI(DefaultSettings)
        SaveAutoConfig()
    end)
end)

local ConfigOverlay = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, Visible = false, ZIndex = 30, Parent = ScreenGui })
local ConfigBoard = Create("Frame", { Size = UDim2.new(0, 220, 0, 230), Position = UDim2.new(0.5, -110, 0.5, -115), BackgroundColor3 = COLORS.Background, ZIndex = 31, Parent = ConfigOverlay })
AddCorner(ConfigBoard, 8)
AddStroke(ConfigBoard, COLORS.Accent, 1)

Create("TextLabel", { Size = UDim2.new(1, -30, 0, 28), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, Text = "Config Manager", TextColor3 = COLORS.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 32, Parent = ConfigBoard })

local ConfigClose = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -24, 0, 4), BackgroundColor3 = COLORS.Button, Text = "×", TextColor3 = COLORS.Text, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 32, Parent = ConfigBoard })
AddCorner(ConfigClose, 4)
ConfigClose.MouseButton1Click:Connect(function() ConfigOverlay.Visible = false end)

local ConfigNameInput = Create("TextBox", { Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 32), BackgroundColor3 = COLORS.Panel, Text = "", PlaceholderText = "New config name...", TextColor3 = COLORS.Text, TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false, ZIndex = 32, Parent = ConfigBoard })
AddCorner(ConfigNameInput, 5)

local SaveConfigBtn = Create("TextButton", { Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 62), BackgroundColor3 = COLORS.Green, Text = "+ Save Current Config", TextColor3 = Color3.new(1,1,1), TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 32, Parent = ConfigBoard })
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
            ApplySettingsToUI(cfgData)
            SaveAutoConfig()
            ConfigOverlay.Visible = false
        end)

        BindLongPress(item, 1, function()
            ShowConfirm("Delete config '"..name.."'?", function()
                SavedConfigs[name] = nil
                SaveConfigsToFile()
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
        SaveConfigsToFile()
        ConfigNameInput.Text = ""
        RefreshConfigList()
    end
end)

ConfigBtn.MouseButton1Click:Connect(function()
    RefreshConfigList()
    ConfigOverlay.Visible = true
end)

-- AUTO LOAD PREVIOUS CONFIG ON INJECTION
local autoConfig = LoadAutoConfig()
if autoConfig then
    ApplySettingsToUI(autoConfig)
    if Settings.AutoExecute then
        local qFunc = GetQueueOnTeleport()
        if qFunc then
            pcall(function() qFunc(SCRIPT_LOADER_CODE) end)
        end
    end
end

--==================================================
-- DISTANCE & ADVANCED ANOMALY DETECTOR
--==================================================

local function TriggerPurple(p)
    if not PlayerStats[p] then PlayerStats[p] = {} end
    PlayerStats[p].PurpleEndTime = os.clock() + 3
end

local function GetPlayerColor(p)
    local stats = PlayerStats[p] or {}
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not char or not hum or hum.Health <= 0 then
        return COLORS.Black
    end

    if stats.NearPlayer then
        return COLORS.Yellow
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

    if Settings.Fly and isFlyingActive and myRoot and hum then
        local moveDir = hum.MoveDirection
        local flatMoveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
        if flatMoveDir.Magnitude > 0 then
            flatMoveDir = flatMoveDir.Unit
        end

        local flySpeed = Settings.Speed.Enabled and Settings.Speed.Value or 50
        local ySpeed = (flyUpHeld and 40 or 0) - (flyDownHeld and 40 or 0)
        
        myRoot.AssemblyLinearVelocity = Vector3.new(flatMoveDir.X * flySpeed, ySpeed, flatMoveDir.Z * flySpeed)
    end

    if Settings.NoGravity and myRoot then
        local bv = myRoot:FindFirstChild("NoGravForce") or Create("BodyVelocity", { Name = "NoGravForce", MaxForce = Vector3.new(0, 100000, 0), Velocity = Vector3.zero, Parent = myRoot })
    elseif myRoot and myRoot:FindFirstChild("NoGravForce") and not isFlyingActive then
        myRoot.NoGravForce:Destroy()
    end

    if Settings.Freecam then
        Camera.CameraType = Enum.CameraType.Scriptable
        
        local moveVector = Vector3.zero
        if MasterControl and MasterControl.GetMoveVector then
            moveVector = MasterControl:GetMoveVector()
        end

        local speed = 1.5
        local yawCFrame = CFrame.Angles(0, freecamYaw, 0)
        
        local forwardDir = yawCFrame.LookVector
        local rightDir = yawCFrame.RightVector

        local moveX = moveVector.X
        local moveZ = moveVector.Z

        -- FIXED FREECAM DOWNWARD SPEED MULTIPLIER
        local verticalSpeed = (flyUpHeld and 1 or 0) - (flyDownHeld and 1 or 0)

        FreecamPos = FreecamPos + (rightDir * (moveX * speed)) + (forwardDir * (-moveZ * speed)) + Vector3.new(0, verticalSpeed * speed * 2, 0)
        
        local rotCFrame = CFrame.Angles(0, freecamYaw, 0) * CFrame.Angles(freecamPitch, 0, 0)
        Camera.CFrame = CFrame.new(FreecamPos) * rotCFrame
    end

    if Settings.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end

    -- DIRECT SHIFTLOCK (NO FLOATING BUTTON)
    if Settings.ShiftLock and myRoot then
        local lookVector = Camera.CFrame.LookVector
        myRoot.CFrame = CFrame.new(myRoot.Position, myRoot.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
    end

    -- ESP & DYNAMIC DISTANCE CHECK
    local allPlayers = Players:GetPlayers()
    
    for _, p in ipairs(allPlayers) do
        if not PlayerStats[p] then PlayerStats[p] = {} end
        PlayerStats[p].NearPlayer = false
    end

    for i = 1, #allPlayers do
        local p1 = allPlayers[i]
        local char1 = p1.Character
        local root1 = char1 and char1:FindFirstChild("HumanoidRootPart")

        if root1 then
            for j = i + 1, #allPlayers do
                local p2 = allPlayers[j]
                local char2 = p2.Character
                local root2 = char2 and char2:FindFirstChild("HumanoidRootPart")

                if root2 then
                    local dist = (root1.Position - root2.Position).Magnitude
                    local maxDist = Settings.DistanceCheckValue or 50
                    if Settings.DistanceCheck and dist <= maxDist then
                        PlayerStats[p1].NearPlayer = true
                        PlayerStats[p2].NearPlayer = true
                    end
                end
            end
        end
    end

    for _, p in ipairs(allPlayers) do
        if p ~= LocalPlayer and p.Character then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = p.Character:FindFirstChildOfClass("Humanoid")

            if targetRoot and targetHum then
                local stats = PlayerStats[p]
                if not stats.LastPos then stats.LastPos = targetRoot.Position; stats.LastHP = targetHum.Health end

                if deltaTime > 0 then
                    local realSpeed = (targetRoot.Position - stats.LastPos).Magnitude / deltaTime
                    if realSpeed > 35 then TriggerPurple(p) end
                end
                stats.LastPos = targetRoot.Position

                if targetHum.JumpPower > 65 then TriggerPurple(p) end

                if targetHum.Health < stats.LastHP then
                    TriggerPurple(p)
                    stats.KillerTime = os.clock()
                    stats.LastHP = targetHum.Health
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
                    hb.Color3 = Settings.PlayerHitboxColor
                elseif hb then
                    hb:Destroy()
                end

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

--==================================================
-- MINIMIZE BUTTON & MENU LOCK SYSTEM
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

MakeDraggable(MiniButton, MiniButton, function()
    return not Settings.MenuLock
end)

local lastClickTime = 0
MiniButton.MouseButton1Click:Connect(function()
    if Settings.MenuLock then
        local currentTime = os.clock()
        if currentTime - lastClickTime <= 0.4 then
            Main.Visible = true
            MiniButton.Visible = false
            lastClickTime = 0
        else
            lastClickTime = currentTime
        end
    else
        Main.Visible = true
        MiniButton.Visible = false
    end
end)

MinimizeButton.MouseButton1Click:Connect(function() Main.Visible = false; MiniButton.Visible = true end)

CloseButton.MouseButton1Click:Connect(function()
    ShowConfirm("Exit ToanCreator Script?", function()
        if getgenv then getgenv().ToanCreatorLoaded = false end
        for _, l in pairs(TraceLines) do pcall(function() l:Remove() end) end
        if workspace:FindFirstChild("ToanCreator_Markers") then workspace.ToanCreator_Markers:Destroy() end
        ScreenGui:Destroy()
    end)
end)

print("ToanCreator GUI v9 - Config Auto-Save & Resizable UI Loaded!")
