--[[
    ToanCreator GUI - Extended Custom Feature Edition
    Mobile & PC Optimized
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

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
local AUTO_CONFIG_FILE = "ToanCreator_AutoSave.json"
local CONFIG_FILE_NAME = "ToanCreator_Configs.json"

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
    Black = Color3.fromRGB(20, 20, 20),
    WaterBlue = Color3.fromRGB(0, 195, 255)
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
    DistanceCheckVal = 50,
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

local function SerializeSettings(st)
    return {
        Speed = st.Speed,
        Jump = st.Jump,
        Fly = st.Fly,
        Noclip = st.Noclip,
        NoGravity = st.NoGravity,
        PlayerESP = st.PlayerESP,
        PlayerESPColor = Color3ToTable(st.PlayerESPColor or Color3.fromRGB(255,255,255)),
        PlayerHitbox = st.PlayerHitbox,
        PlayerHitboxColor = Color3ToTable(st.PlayerHitboxColor or Color3.fromRGB(255,80,80)),
        PlayerTrace = st.PlayerTrace,
        PlayerTraceColor = Color3ToTable(st.PlayerTraceColor or Color3.fromRGB(0,170,255)),
        DistanceCheck = st.DistanceCheck,
        DistanceCheckVal = st.DistanceCheckVal or 50,
        Freecam = st.Freecam,
        Fullbright = st.Fullbright,
        FixLag = st.FixLag,
        AutoExecute = st.AutoExecute,
        ShiftLock = st.ShiftLock,
        MenuLock = st.MenuLock
    }
end

local function DeserializeSettings(data)
    if not data then return end
    Settings.Speed = data.Speed or { Enabled = false, Value = 16 }
    Settings.Jump = data.Jump or { Enabled = false, Value = 50 }
    Settings.Fly = data.Fly or false
    Settings.Noclip = data.Noclip or false
    Settings.NoGravity = data.NoGravity or false
    Settings.PlayerESP = data.PlayerESP or false
    Settings.PlayerESPColor = data.PlayerESPColor and TableToColor3(data.PlayerESPColor) or Color3.fromRGB(255,255,255)
    Settings.PlayerHitbox = data.PlayerHitbox or false
    Settings.PlayerHitboxColor = data.PlayerHitboxColor and TableToColor3(data.PlayerHitboxColor) or Color3.fromRGB(255,80,80)
    Settings.PlayerTrace = data.PlayerTrace or false
    Settings.PlayerTraceColor = data.PlayerTraceColor and TableToColor3(data.PlayerTraceColor) or Color3.fromRGB(0,170,255)
    Settings.DistanceCheck = data.DistanceCheck or false
    Settings.DistanceCheckVal = data.DistanceCheckVal or 50
    Settings.Freecam = data.Freecam or false
    Settings.Fullbright = data.Fullbright or false
    Settings.FixLag = data.FixLag or false
    Settings.AutoExecute = data.AutoExecute or false
    Settings.ShiftLock = data.ShiftLock or false
    Settings.MenuLock = data.MenuLock or false
end

local function SaveAutoConfig()
    if writefile then
        pcall(function()
            writefile(AUTO_CONFIG_FILE, HttpService:JSONEncode(SerializeSettings(Settings)))
        end)
    end
end

local function LoadAutoConfig()
    if readfile and isfile and isfile(AUTO_CONFIG_FILE) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(AUTO_CONFIG_FILE))
            DeserializeSettings(decoded)
        end)
    end
end

local function LoadSavedConfigsFromFile()
    if readfile and isfile and isfile(CONFIG_FILE_NAME) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE_NAME))
            SavedConfigs = decoded
        end)
    end
end

local function SaveConfigsToFile()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE_NAME, HttpService:JSONEncode(SavedConfigs))
        end)
    end
end

LoadAutoConfig()
LoadSavedConfigsFromFile()

-- Auto Execute Handling on Teleport
if Settings.AutoExecute then
    local qFunc = GetQueueOnTeleport()
    if qFunc then
        pcall(function() qFunc(SCRIPT_LOADER_CODE) end)
    end
end

-- Freecam State
local FreecamPos = Vector3.zero
local freecamYaw, freecamPitch = 0, 0
local PlayerStats, TraceLines = {}, {}

--==================================================
-- UTILS & SCREEN GUI SETUP
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

-- TRASH DROP ZONE (FOR DETACHED CARDS)
local TrashZone = Create("Frame", {
    Size = UDim2.new(0, 50, 0, 50),
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -20),
    BackgroundColor3 = COLORS.Red,
    BackgroundTransparency = 0.5,
    Visible = false,
    ZIndex = 150,
    Parent = ScreenGui
})
AddCorner(TrashZone, 25)
AddStroke(TrashZone, Color3.fromRGB(255, 255, 255), 2)

local TrashLabel = Create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    ZIndex = 151,
    Parent = TrashZone
})

-- MAIN WINDOW
local Main = Create("Frame", {
    Size = UDim2.new(0, 270, 0, 360),
    Position = UDim2.new(0.5, -135, 0.5, -180),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    Parent = ScreenGui,
})
AddCorner(Main, 10)
local MainStroke = AddStroke(Main, Color3.fromRGB(60, 60, 75), 1.5)

-- RESIZE BORDER EFFECT & CORNER HANDLES
local CornerTL = Create("Frame", { Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 30, Parent = Main })
local CornerTR = Create("Frame", { Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(1, -15, 0, 0), BackgroundTransparency = 1, ZIndex = 30, Parent = Main })
local CornerBL = Create("Frame", { Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(0, 0, 1, -15), BackgroundTransparency = 1, ZIndex = 30, Parent = Main })
local CornerBR = Create("Frame", { Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(1, -15, 1, -15), BackgroundTransparency = 1, ZIndex = 30, Parent = Main })

local isResizingUI = false
local resizeAnimConnection = nil

local function StartBorderFlowAnimation()
    if resizeAnimConnection then return end
    MainStroke.Thickness = 2.5
    resizeAnimConnection = RunService.RenderStepped:Connect(function()
        local t = os.clock() * 4
        local r = (math.sin(t) + 1) / 2
        local g = (math.sin(t + 2) + 1) / 2
        MainStroke.Color = Color3.fromRGB(0, math.floor(150 + g * 105), 255)
    end)
end

local function StopBorderFlowAnimation()
    if resizeAnimConnection then
        resizeAnimConnection:Disconnect()
        resizeAnimConnection = nil
    end
    MainStroke.Thickness = 1.5
    MainStroke.Color = Color3.fromRGB(60, 60, 75)
end

local function SetupResizer(handleCorner)
    handleCorner.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isResizingUI = true
            StartBorderFlowAnimation()
            
            local startPos = input.Position
            local startSize = Main.Size
            
            local moveConn, endConn
            moveConn = UserInputService.InputChanged:Connect(function(inp)
                if isResizingUI and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    local delta = inp.Position - startPos
                    local newWidth = math.max(200, startSize.X.Offset + delta.X)
                    local newHeight = math.max(260, startSize.Y.Offset + delta.Y)
                    Main.Size = UDim2.new(0, newWidth, 0, newHeight)
                end
            end)
            
            endConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    isResizingUI = false
                    StopBorderFlowAnimation()
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end)
end

SetupResizer(CornerTL)
SetupResizer(CornerTR)
SetupResizer(CornerBL)
SetupResizer(CornerBR)

local function MakeDraggable(frame, handle, canDragCheck)
    local dragging, dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if canDragCheck and not canDragCheck() then return end
        if isResizingUI then return end
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

-- HEADER & TABS
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
-- DETACHABLE FLOATING FEATURE CARDS
--==================================================
local function MakeComponentDetachable(cardHolder, minWidth)
    minWidth = minWidth or 120
    local isDetached = false
    local isLocked = false
    local parentPage = cardHolder.Parent
    local originalSize = cardHolder.Size

    -- Lock Button (15px Icon)
    local LockBtn = Create("ImageButton", {
        Size = UDim2.new(0, 15, 0, 15),
        Position = UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = COLORS.Button,
        Image = "rbxassetid://6031082533", -- Lock icon
        ImageColor3 = Color3.fromRGB(150, 150, 150),
        Visible = false,
        ZIndex = 50,
        Parent = cardHolder
    })
    AddCorner(LockBtn, 3)

    LockBtn.MouseButton1Click:Connect(function()
        isLocked = not isLocked
        LockBtn.ImageColor3 = isLocked and COLORS.Accent or Color3.fromRGB(150, 150, 150)
    end)

    -- Resizers for Detached Card
    local CardResizeHandle = Create("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(1, -10, 1, -10),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 51,
        Parent = cardHolder
    })

    local isCardResizing = false
    CardResizeHandle.InputBegan:Connect(function(input)
        if not isDetached or isLocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isCardResizing = true
            local startPos = input.Position
            local startSize = cardHolder.Size

            local moveConn, endConn
            moveConn = UserInputService.InputChanged:Connect(function(inp)
                if isCardResizing and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    local delta = inp.Position - startPos
                    local newW = math.max(minWidth, startSize.X.Offset + delta.X)
                    local newH = math.max(32, startSize.Y.Offset + delta.Y)
                    cardHolder.Size = UDim2.new(0, newW, 0, newH)
                end
            end)

            endConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    isCardResizing = false
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end)

    -- Detach & Drag Logic
    local draggingCard, dragStart, startPos
    cardHolder.InputBegan:Connect(function(input)
        if isLocked or isCardResizing then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingCard = true
            dragStart = input.Position
            startPos = cardHolder.Position

            if isDetached then TrashZone.Visible = true end

            local touchConn
            touchConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingCard = false
                    TrashZone.Visible = false
                    if touchConn then touchConn:Disconnect() end

                    -- Check drop inside Trash Zone
                    if isDetached then
                        local mousePos = UserInputService:GetMouseLocation()
                        local trashAbsPos = TrashZone.AbsolutePosition
                        local trashAbsSize = TrashZone.AbsoluteSize
                        if mousePos.X >= trashAbsPos.X and mousePos.X <= (trashAbsPos.X + trashAbsSize.X)
                            and mousePos.Y >= trashAbsPos.Y and mousePos.Y <= (trashAbsPos.Y + trashAbsSize.Y) then
                            -- Re-attach
                            isDetached = false
                            isLocked = false
                            cardHolder.Parent = parentPage
                            cardHolder.Size = originalSize
                            LockBtn.Visible = false
                            CardResizeHandle.Visible = false
                            LockBtn.ImageColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingCard and not isLocked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            
            if not isDetached and math.abs(delta.X) > 20 then
                -- Detach to ScreenGui
                isDetached = true
                cardHolder.Parent = ScreenGui
                cardHolder.Position = UDim2.new(0, input.Position.X - 50, 0, input.Position.Y - 15)
                cardHolder.Size = UDim2.new(0, math.max(minWidth, originalSize.X.Offset), 0, originalSize.Y.Offset)
                LockBtn.Visible = true
                CardResizeHandle.Visible = true
                TrashZone.Visible = true
            elseif isDetached then
                cardHolder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

--==================================================
-- UI COMPONENTS SETUP
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
    local function setCheckState(st)
        state = st
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
        SaveAutoConfig()
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
        SetState = setCheckState,
        SetValue = function(v) input.Text = tostring(v); if onValueChange then onValueChange(v) end end
    }
    MakeComponentDetachable(holder, 130)
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
    local function setCheckState(st)
        state = st
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
        SaveAutoConfig()
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    UI_Controls[id] = { SetState = setCheckState }
    MakeComponentDetachable(holder, 80)
    return holder
end

local function CreateESPCombo(id, parent, labelText, defaultColor, onColorChange, onToggle)
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
        SaveAutoConfig()
    end)

    local state = false
    local function setCheckState(st)
        state = st
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
        SaveAutoConfig()
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    UI_Controls[id] = {
        SetState = setCheckState,
        SetColor = function(c) colorBtn.BackgroundColor3 = c; if onColorChange then onColorChange(c) end end
    }
    MakeComponentDetachable(holder, 100)
    return holder
end

--==================================================
-- MOVE TAB SETUP
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
local FlyDown = Create("TextButton", { Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = COLORS.Accent, Text = "▼", TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.GothamBold, Parent = FlyControls })
AddCorner(FlyDown, 5)

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
MakeComponentDetachable(TpPlayerHolder, 150)

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
MakeComponentDetachable(TpLocHolder, 150)

--==================================================
-- ESP TAB SETUP & SLIDER DISTANCE CHECK
--==================================================

CreateESPCombo("PlayerESP", ESPPage, "player ESP", Settings.PlayerESPColor, function(c) Settings.PlayerESPColor = c end, function(s) Settings.PlayerESP = s end)
CreateESPCombo("PlayerHitbox", ESPPage, "player hitbox", Settings.PlayerHitboxColor, function(c) Settings.PlayerHitboxColor = c end, function(s) Settings.PlayerHitbox = s end)
CreateESPCombo("PlayerTrace", ESPPage, "player trace", Settings.PlayerTraceColor, function(c) Settings.PlayerTraceColor = c end, function(s) Settings.PlayerTrace = s end)

-- DISTANCE CHECK SLIDER COMPONENT
local DistCheckHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 52), BackgroundColor3 = COLORS.Panel, Parent = ESPPage })
AddCorner(DistCheckHolder, 5)

local DistTitle = Create("TextLabel", { Size = UDim2.new(1, -40, 0, 24), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = "distance check: 50", TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = DistCheckHolder })

local DistCheck = Create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0, 2), BackgroundColor3 = COLORS.Button, Text = "", Parent = DistCheckHolder })
AddCorner(DistCheck, 4)
AddStroke(DistCheck, Color3.fromRGB(75, 75, 85), 1)

local DistSliderBar = Create("Frame", { Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 34), BackgroundColor3 = COLORS.Button, Parent = DistCheckHolder })
AddCorner(DistSliderBar, 3)

local DistSliderFill = Create("Frame", { Size = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = COLORS.Accent, Parent = DistSliderBar })
AddCorner(DistSliderFill, 3)

local DistSliderKnob = Create("Frame", { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = DistSliderBar })
AddCorner(DistSliderKnob, 7)

local function UpdateDistanceSlider(val)
    val = math.clamp(math.floor(val), 0, 100)
    Settings.DistanceCheckVal = val
    DistTitle.Text = "distance check: " .. tostring(val)
    local pct = val / 100
    DistSliderFill.Size = UDim2.new(pct, 0, 1, 0)
    DistSliderKnob.Position = UDim2.new(pct, -7, 0.5, -7)
    SaveAutoConfig()
end

local isDraggingDistSlider = false
DistSliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingDistSlider = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingDistSlider = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingDistSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local barAbsPos = DistSliderBar.AbsolutePosition.X
        local barAbsSize = DistSliderBar.AbsoluteSize.X
        local mouseX = input.Position.X
        local pct = math.clamp((mouseX - barAbsPos) / barAbsSize, 0, 1)
        UpdateDistanceSlider(pct * 100)
    end
end)

local distState = false
local function SetDistCheckState(st)
    distState = st
    Settings.DistanceCheck = st
    DistCheck.BackgroundColor3 = distState and COLORS.Accent or COLORS.Button
    DistCheck.Text = distState and "✓" or ""
    DistCheck.TextColor3 = Color3.new(1, 1, 1)
    SaveAutoConfig()
end

DistCheck.MouseButton1Click:Connect(function()
    SetDistCheckState(not distState)
end)

UI_Controls["DistanceCheck"] = {
    SetState = SetDistCheckState,
    SetValue = UpdateDistanceSlider
}
MakeComponentDetachable(DistCheckHolder, 120)

-- FREECAM
UserInputService.InputChanged:Connect(function(input)
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
        freecamYaw, freecamPitch = y, x
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
        if qFunc then pcall(function() qFunc(SCRIPT_LOADER_CODE) end) end
    end
end)

CreateCheckbox("ShiftLock", OptionPage, "shift lock", function(v)
    Settings.ShiftLock = v
end)

CreateCheckbox("MenuLock", OptionPage, "menu lock", function(v)
    Settings.MenuLock = v
end)

local function ApplySettingsToUI(newSettings)
    DeserializeSettings(newSettings)

    if UI_Controls["Speed"] then UI_Controls["Speed"].SetState(Settings.Speed.Enabled); UI_Controls["Speed"].SetValue(Settings.Speed.Value) end
    if UI_Controls["Jump"] then UI_Controls["Jump"].SetState(Settings.Jump.Enabled); UI_Controls["Jump"].SetValue(Settings.Jump.Value) end

    if UI_Controls["Fly"] then UI_Controls["Fly"].SetState(Settings.Fly) end
    if UI_Controls["Noclip"] then UI_Controls["Noclip"].SetState(Settings.Noclip) end
    if UI_Controls["NoGravity"] then UI_Controls["NoGravity"].SetState(Settings.NoGravity) end

    if UI_Controls["PlayerESP"] then UI_Controls["PlayerESP"].SetState(Settings.PlayerESP); UI_Controls["PlayerESP"].SetColor(Settings.PlayerESPColor) end
    if UI_Controls["PlayerHitbox"] then UI_Controls["PlayerHitbox"].SetState(Settings.PlayerHitbox); UI_Controls["PlayerHitbox"].SetColor(Settings.PlayerHitboxColor) end
    if UI_Controls["PlayerTrace"] then UI_Controls["PlayerTrace"].SetState(Settings.PlayerTrace); UI_Controls["PlayerTrace"].SetColor(Settings.PlayerTraceColor) end

    if UI_Controls["DistanceCheck"] then UI_Controls["DistanceCheck"].SetState(Settings.DistanceCheck); UI_Controls["DistanceCheck"].SetValue(Settings.DistanceCheckVal) end
    if UI_Controls["Freecam"] then UI_Controls["Freecam"].SetState(Settings.Freecam) end

    if UI_Controls["Fullbright"] then UI_Controls["Fullbright"].SetState(Settings.Fullbright) end
    if UI_Controls["FixLag"] then UI_Controls["FixLag"].SetState(Settings.FixLag) end
    if UI_Controls["AutoExecute"] then UI_Controls["AutoExecute"].SetState(Settings.AutoExecute) end
    if UI_Controls["ShiftLock"] then UI_Controls["ShiftLock"].SetState(Settings.ShiftLock) end
    if UI_Controls["MenuLock"] then UI_Controls["MenuLock"].SetState(Settings.MenuLock) end
end

-- RESET & CONFIG BUTTONS
local OptionBtnHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 36), BackgroundTransparency = 1, Parent = OptionPage })
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = OptionBtnHolder })

local ResetBtn = Create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = COLORS.Red, Text = "Reset Default", TextColor3 = Color3.new(1,1,1), TextSize = 11, Font = Enum.Font.GothamBold, Parent = OptionBtnHolder })
AddCorner(ResetBtn, 6)

ResetBtn.MouseButton1Click:Connect(function()
    ApplySettingsToUI(DefaultSettings)
    SaveAutoConfig()
end)

--==================================================
-- MAIN RENDER LOOP & SHIFTLOCK HANDLER
--==================================================
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
        if flatMoveDir.Magnitude > 0 then flatMoveDir = flatMoveDir.Unit end

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
        if MasterControl and MasterControl.GetMoveVector then moveVector = MasterControl:GetMoveVector() end

        local speed = 1.5
        local yawCFrame = CFrame.Angles(0, freecamYaw, 0)
        local forwardDir = yawCFrame.LookVector
        local rightDir = yawCFrame.RightVector

        local verticalSpeed = (flyUpHeld and 1 or 0) - (flyDownHeld and 1 or 0)
        FreecamPos = FreecamPos + (rightDir * (moveVector.X * speed)) + (forwardDir * (-moveVector.Z * speed)) + Vector3.new(0, verticalSpeed * speed * 2, 0)
        
        local rotCFrame = CFrame.Angles(0, freecamYaw, 0) * CFrame.Angles(freecamPitch, 0, 0)
        Camera.CFrame = CFrame.new(FreecamPos) * rotCFrame
    end

    if Settings.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end

    -- SHIFTLOCK (LOCK CAMERA DIRECTION IMMEDIATELY WHEN CHECKED)
    if Settings.ShiftLock and myRoot then
        local lookVector = Camera.CFrame.LookVector
        myRoot.CFrame = CFrame.new(myRoot.Position, myRoot.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
    end

    -- ESP & DISTANCE CHECK LOGIC
    local allPlayers = Players:GetPlayers()
    for _, p in ipairs(allPlayers) do
        if not PlayerStats[p] then PlayerStats[p] = {} end
        PlayerStats[p].NearPlayer = false
    end

    for i = 1, #allPlayers do
        local p1 = allPlayers[i]
        local root1 = p1.Character and p1.Character:FindFirstChild("HumanoidRootPart")

        if root1 then
            for j = i + 1, #allPlayers do
                local p2 = allPlayers[j]
                local root2 = p2.Character and p2.Character:FindFirstChild("HumanoidRootPart")

                if root2 then
                    local dist = (root1.Position - root2.Position).Magnitude
                    if Settings.DistanceCheck and dist <= Settings.DistanceCheckVal then
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
            if targetRoot then
                local displayColor = PlayerStats[p].NearPlayer and COLORS.Yellow or Settings.PlayerESPColor

                local espTag = targetRoot:FindFirstChild("ToanESP")
                if Settings.PlayerESP then
                    if not espTag then
                        local bill = Create("BillboardGui", { Name = "ToanESP", Size = UDim2.new(0, 120, 0, 20), StudsOffset = Vector3.new(0, 3, 0), AlwaysOnTop = true, Adornee = targetRoot, Parent = targetRoot })
                        Create("TextLabel", { Name = "Txt", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextSize = 11, Font = Enum.Font.GothamBold, Parent = bill })
                    end
                    targetRoot.ToanESP.Txt.TextColor3 = displayColor
                    targetRoot.ToanESP.Txt.Text = p.Name
                elseif espTag then
                    espTag:Destroy()
                end
            end
        end
    end
end)

-- LOAD SAVED CONFIG TO UI UPON SCRIPT LOAD
ApplySettingsToUI(Settings)

-- MINIMIZE SYSTEM
MinimizeButton.MouseButton1Click:Connect(function() Main.Visible = false end)
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

print("ToanCreator GUI - Advanced Config, Detachable UI & Dynamic Slider Loaded!")
