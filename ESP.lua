--[[
    ToanCreator GUI - Advanced Floating Widgets & Dynamic Auto-Config
    Mobile & PC Optimized
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- PREVENT MULTIPLE EXECUTIONS
if getgenv and getgenv().ToanCreatorLoaded then
    return
end
if getgenv then getgenv().ToanCreatorLoaded = true end

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Roblox Player Control Module
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local MasterControl = nil
pcall(function()
    MasterControl = require(PlayerScripts:WaitForChild("PlayerModule")):GetControls()
end)

-- AUTO EXECUTE QUEUE
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

-- CONFIG & FILE STORAGE (AUTO SAVE LAST SESSION)
local CONFIG_FILE_NAME = "ToanCreator_Configs.json"
local LAST_SESSION_FILE = "ToanCreator_LastSession.json"

local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    Panel = Color3.fromRGB(25, 25, 30),
    Button = Color3.fromRGB(42, 42, 52),
    Accent = Color3.fromRGB(75, 170, 255),
    NeonFlow = Color3.fromRGB(0, 210, 255),
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
    DistanceVal = 50,
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

local function Color3ToTable(c) return {R = c.R, G = c.G, B = c.B} end
local function TableToColor3(t) return Color3.new(t.R or 1, t.G or 1, t.B or 1) end

local function SaveLastSession()
    if writefile then
        pcall(function()
            local data = {
                Speed = Settings.Speed,
                Jump = Settings.Jump,
                Fly = Settings.Fly,
                Noclip = Settings.Noclip,
                NoGravity = Settings.NoGravity,
                PlayerESP = Settings.PlayerESP,
                PlayerESPColor = Color3ToTable(Settings.PlayerESPColor),
                PlayerHitbox = Settings.PlayerHitbox,
                PlayerHitboxColor = Color3ToTable(Settings.PlayerHitboxColor),
                PlayerTrace = Settings.PlayerTrace,
                PlayerTraceColor = Color3ToTable(Settings.PlayerTraceColor),
                DistanceCheck = Settings.DistanceCheck,
                DistanceVal = Settings.DistanceVal,
                Freecam = Settings.Freecam,
                Fullbright = Settings.Fullbright,
                FixLag = Settings.FixLag,
                AutoExecute = Settings.AutoExecute,
                ShiftLock = Settings.ShiftLock,
                MenuLock = Settings.MenuLock
            }
            writefile(LAST_SESSION_FILE, HttpService:JSONEncode(data))
        end)
    end
end

-- UI CONTROLS REGISTRATION
local UI_Controls = {}
local ApplySettingsToUI -- forward decl

local function LoadLastSession()
    if readfile and isfile and isfile(LAST_SESSION_FILE) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(LAST_SESSION_FILE))
            if decoded then
                local formatted = {
                    Speed = decoded.Speed or { Enabled = false, Value = 16 },
                    Jump = decoded.Jump or { Enabled = false, Value = 50 },
                    Fly = decoded.Fly or false,
                    Noclip = decoded.Noclip or false,
                    NoGravity = decoded.NoGravity or false,
                    PlayerESP = decoded.PlayerESP or false,
                    PlayerESPColor = decoded.PlayerESPColor and TableToColor3(decoded.PlayerESPColor) or Color3.fromRGB(255,255,255),
                    PlayerHitbox = decoded.PlayerHitbox or false,
                    PlayerHitboxColor = decoded.PlayerHitboxColor and TableToColor3(decoded.PlayerHitboxColor) or Color3.fromRGB(255,80,80),
                    PlayerTrace = decoded.PlayerTrace or false,
                    PlayerTraceColor = decoded.PlayerTraceColor and TableToColor3(decoded.PlayerTraceColor) or Color3.fromRGB(0,170,255),
                    DistanceCheck = decoded.DistanceCheck or false,
                    DistanceVal = decoded.DistanceVal or 50,
                    Freecam = decoded.Freecam or false,
                    Fullbright = decoded.Fullbright or false,
                    FixLag = decoded.FixLag or false,
                    AutoExecute = decoded.AutoExecute or false,
                    ShiftLock = decoded.ShiftLock or false,
                    MenuLock = decoded.MenuLock or false
                }
                for k, v in pairs(formatted) do Settings[k] = v end
            end
        end)
    end
end

-- Freecam State Variables
local FreecamPos = Vector3.zero
local freecamYaw = 0
local freecamPitch = 0

-- System Tracking
local PlayerStats = {}
local TraceLines = {}

-- UTILS & SCREEN GUI
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

-- TRASH CAN FOR DETACHED WIDGETS
local TrashBin = Create("Frame", {
    Size = UDim2.new(0, 60, 0, 60),
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -25),
    BackgroundColor3 = COLORS.Red,
    BackgroundTransparency = 0.5,
    Visible = false,
    ZIndex = 200,
    Parent = ScreenGui
})
AddCorner(TrashBin, 30)
AddStroke(TrashBin, Color3.fromRGB(255, 255, 255), 2)

local TrashLabel = Create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "×",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 32,
    Font = Enum.Font.GothamBold,
    ZIndex = 201,
    Parent = TrashBin
})

-- MAIN FRAME SETUP
local Main = Create("Frame", {
    Size = UDim2.new(0, 270, 0, 380),
    Position = UDim2.new(0.5, -135, 0.5, -190),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    Parent = ScreenGui,
})
AddCorner(Main, 10)

local MainStroke = AddStroke(Main, Color3.fromRGB(60, 60, 75), 1.5)

-- NEON FLOW EFFECT FOR RESIZING
local FlowEffect = Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.Accent),
        ColorSequenceKeypoint.new(0.5, COLORS.NeonFlow),
        ColorSequenceKeypoint.new(1, COLORS.Accent)
    }),
    Rotation = 0,
    Parent = MainStroke
})

local isResizing = false
RunService.RenderStepped:Connect(function()
    if isResizing then
        FlowEffect.Rotation = (FlowEffect.Rotation + 4) % 360
    end
end)

-- DRAGGABLE SYSTEM
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

-- RESIZABLE MAIN WINDOW (4 CORNERS)
local MIN_SIZE = Vector2.new(240, 320)
local MAX_SIZE = Vector2.new(500, 600)

local function SetupResizer(cornerFrame, cursorType, calcNewSize)
    cornerFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isResizing = true
            MainStroke.Color = Color3.fromRGB(255, 255, 255)
            MainStroke.Thickness = 2.5

            local startMouse = input.Position
            local startSize = Main.Size
            local startPos = Main.Position

            local moveConn, releaseConn
            moveConn = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    local delta = inp.Position - startMouse
                    local newSize, newPos = calcNewSize(startSize, startPos, delta)
                    
                    if newSize.X.Offset >= MIN_SIZE.X and newSize.X.Offset <= MAX_SIZE.X then
                        Main.Size = UDim2.new(0, newSize.X.Offset, Main.Size.Y.Scale, Main.Size.Y.Offset)
                        if newPos and newPos.X then Main.Position = UDim2.new(Main.Position.X.Scale, newPos.X.Offset, Main.Position.Y.Scale, Main.Position.Y.Offset) end
                    end
                    if newSize.Y.Offset >= MIN_SIZE.Y and newSize.Y.Offset <= MAX_SIZE.Y then
                        Main.Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, newSize.Y.Offset)
                        if newPos and newPos.Y then Main.Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, Main.Position.Y.Scale, newPos.Y.Offset) end
                    end
                end
            end)

            releaseConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    isResizing = false
                    MainStroke.Color = Color3.fromRGB(60, 60, 75)
                    MainStroke.Thickness = 1.5
                    if moveConn then moveConn:Disconnect() end
                    if releaseConn then releaseConn:Disconnect() end
                end
            end)
        end
    end)
end

-- 4 Corner Hotspots
local TopLeftGrip = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 50, Parent = Main })
local TopRightGrip = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, ZIndex = 50, Parent = Main })
local BottomLeftGrip = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 0, 1, -16), BackgroundTransparency = 1, ZIndex = 50, Parent = Main })
local BottomRightGrip = Create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -16, 1, -16), BackgroundTransparency = 1, ZIndex = 50, Parent = Main })

SetupResizer(BottomRightGrip, "", function(s, p, d)
    return UDim2.new(0, s.X.Offset + d.X, 0, s.Y.Offset + d.Y), nil
end)
SetupResizer(BottomLeftGrip, "", function(s, p, d)
    return UDim2.new(0, s.X.Offset - d.X, 0, s.Y.Offset + d.Y), UDim2.new(0, p.X.Offset + d.X, 0, p.Y.Offset)
end)
SetupResizer(TopRightGrip, "", function(s, p, d)
    return UDim2.new(0, s.X.Offset + d.X, 0, s.Y.Offset - d.Y), UDim2.new(0, p.X.Offset, 0, p.Y.Offset + d.Y)
end)
SetupResizer(TopLeftGrip, "", function(s, p, d)
    return UDim2.new(0, s.X.Offset - d.X, 0, s.Y.Offset - d.Y), UDim2.new(0, p.X.Offset + d.X, 0, p.Y.Offset + d.Y)
end)

-- HEADER
local Header = Create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = COLORS.Panel, Parent = Main })
AddCorner(Header, 10)
MakeDraggable(Main, Header)

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

-- DETACHABLE FLOATING WIDGET SYSTEM
local function MakeWidgetDetachable(holder, minWidth)
    minWidth = minWidth or 160
    local originalParent = holder.Parent
    local originalSize = holder.Size
    local isDetached = false
    local isLocked = false

    -- Lock Icon Button
    local lockBtn = Create("TextButton", {
        Size = UDim2.new(0, 15, 0, 15),
        Position = UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = COLORS.Button,
        Text = "🔒",
        TextColor3 = COLORS.SubText,
        TextSize = 8,
        Visible = false,
        ZIndex = 110,
        Parent = holder
    })
    AddCorner(lockBtn, 3)

    lockBtn.MouseButton1Click:Connect(function()
        isLocked = not isLocked
        lockBtn.BackgroundColor3 = isLocked and COLORS.Accent or COLORS.Button
        lockBtn.TextColor3 = isLocked and Color3.new(1,1,1) or COLORS.SubText
    end)

    local dragging = false
    local dragStart, startPos

    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isLocked then return end

            local clickX = input.Position.X
            local mainLeft = Main.AbsolutePosition.X
            local mainRight = mainLeft + Main.AbsoluteSize.X

            -- Check horizontal pull outside main UI
            if not isDetached and (clickX < mainLeft or clickX > mainRight) then
                isDetached = true
                TrashBin.Visible = true
                lockBtn.Visible = true

                holder.Parent = ScreenGui
                holder.Size = UDim2.new(0, math.max(minWidth, holder.AbsoluteSize.X), 0, holder.AbsoluteSize.Y)
                holder.Position = UDim2.new(0, input.Position.X - holder.AbsoluteSize.X/2, 0, input.Position.Y - 15)
                AddStroke(holder, COLORS.Accent, 1.5)
            end

            if isDetached then
                dragging = true
                TrashBin.Visible = true
                dragStart = input.Position
                startPos = holder.Position

                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        TrashBin.Visible = false

                        -- Check Trash Bin Overlap
                        local mousePos = UserInputService:GetMouseLocation()
                        local trashCenter = TrashBin.AbsolutePosition + (TrashBin.AbsoluteSize / 2)
                        if (Vector2.new(mousePos.X, mousePos.Y) - trashCenter).Magnitude < 45 then
                            -- Reattach back to Main UI
                            isDetached = false
                            isLocked = false
                            lockBtn.Visible = false
                            holder.Parent = originalParent
                            holder.Size = originalSize
                            AddStroke(holder, Color3.fromRGB(60, 60, 70), 1)
                        end
                        if conn then conn:Disconnect() end
                    end
                end)
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and isDetached and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- UI BUILDER COMPONENTS
local function CreateCombinedInput(id, parent, labelText, defaultVal, onValueChange, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)
    
    local lbl = Create("TextLabel", { Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

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
        SaveLastSession()
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    input.FocusLost:Connect(function()
        local num = tonumber(input.Text)
        if num then
            if onValueChange then onValueChange(num) end
            SaveLastSession()
        else
            input.Text = tostring(defaultVal)
        end
    end)

    UI_Controls[id] = {
        SetState = setCheckState,
        SetValue = function(v) input.Text = tostring(v); if onValueChange then onValueChange(v) end end
    }

    MakeWidgetDetachable(holder, 180)
    return holder
end

local function CreateCheckbox(id, parent, labelText, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)
    
    Create("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

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
        SaveLastSession()
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    UI_Controls[id] = { SetState = setCheckState }
    MakeWidgetDetachable(holder, 140)
    return holder
end

local function CreateESPCombo(id, parent, labelText, defaultColor, onColorChange, onToggle)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)
    
    Create("TextLabel", { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

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
        SaveLastSession()
    end)

    local state = false
    local function setCheckState(st)
        state = st
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        if onToggle then onToggle(state) end
        SaveLastSession()
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    UI_Controls[id] = {
        SetState = setCheckState,
        SetColor = function(c) colorBtn.BackgroundColor3 = c; if onColorChange then onColorChange(c) end end
    }

    MakeWidgetDetachable(holder, 170)
    return holder
end

-- ESP DISTANCE CHECK SLIDER WIDGET
local function CreateDistanceSlider(parent)
    local holder = Create("Frame", { Size = UDim2.new(1, -2, 0, 50), BackgroundColor3 = COLORS.Panel, Parent = parent })
    AddCorner(holder, 5)

    local titleLbl = Create("TextLabel", { Size = UDim2.new(1, -40, 0, 20), Position = UDim2.new(0, 20, 0, 2), BackgroundTransparency = 1, Text = "distance check", TextColor3 = COLORS.Text, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder })

    local check = Create("TextButton", { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -25, 0, 3), BackgroundColor3 = COLORS.Button, Text = "", Parent = holder })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local track = Create("Frame", { Size = UDim2.new(1, -30, 0, 4), Position = UDim2.new(0, 15, 0, 32), BackgroundColor3 = COLORS.Button, Parent = holder })
    AddCorner(track, 2)

    local fill = Create("Frame", { Size = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = COLORS.Accent, Parent = track })
    AddCorner(fill, 2)

    local knob = Create("Frame", { Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.new(1,1,1), Parent = track })
    AddCorner(knob, 7)
    AddStroke(knob, COLORS.Accent, 1.5)

    local valLbl = Create("TextLabel", { Size = UDim2.new(0, 40, 0, 15), Position = UDim2.new(1, -65, 0, 2), BackgroundTransparency = 1, Text = "50s", TextColor3 = COLORS.Accent, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = holder })

    local isDragging = false
    local function UpdateSlider(inputPos)
        local relX = math.clamp(inputPos.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
        local pct = relX / track.AbsoluteSize.X
        local val = math.floor(pct * 100)

        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = tostring(val) .. "s"
        Settings.DistanceVal = val
        SaveLastSession()
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    local state = false
    local function setCheckState(st)
        state = st
        Settings.DistanceCheck = st
        check.BackgroundColor3 = state and COLORS.Accent or COLORS.Button
        check.Text = state and "✓" or ""
        check.TextColor3 = Color3.new(1, 1, 1)
        SaveLastSession()
    end

    check.MouseButton1Click:Connect(function()
        setCheckState(not state)
    end)

    UI_Controls["DistanceCheck"] = {
        SetState = setCheckState,
        SetValue = function(v)
            local pct = math.clamp(v, 0, 100) / 100
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
            valLbl.Text = tostring(v) .. "s"
            Settings.DistanceVal = v
        end
    }

    MakeWidgetDetachable(holder, 200)
end

-- MOVE TAB SETUP
CreateCombinedInput("Speed", MovePage, "speed: enter num", Settings.Speed.Value, function(v) Settings.Speed.Value = v end, function(s) Settings.Speed.Enabled = s end)
CreateCombinedInput("Jump", MovePage, "jump: enter num", Settings.Jump.Value, function(v) Settings.Jump.Value = v end, function(s) Settings.Jump.Enabled = s end)

local FlyToggleBtn = Create("TextButton", {
    Size = UDim2.new(0, 55, 0, 30), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 20, 0.5, -30),
    BackgroundColor3 = COLORS.Accent, Text = "fly", TextColor3 = Color3.new(1, 1, 1), TextSize = 13,
    Font = Enum.Font.GothamBold, Visible = false, ZIndex = 80, Parent = ScreenGui
})
AddCorner(FlyToggleBtn, 6)

local FlyControls = Create("Frame", { Size = UDim2.new(0, 55, 0, 55), Position = UDim2.new(0, 20, 0.5, -10), BackgroundTransparency = 1, Visible = false, ZIndex = 80, Parent = ScreenGui })
local FlyUp = Create("TextButton", { Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = COLORS.Accent, Text = "▲", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, Parent = FlyControls })
AddCorner(FlyUp, 5)

local FlyDown = Create("TextButton", { Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = COLORS.Accent, Text = "▼", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, Parent = FlyControls })
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
    if not v then isFlyingActive = false; FlyControls.Visible = false; FlyToggleBtn.BackgroundColor3 = COLORS.Accent end
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
Create("TextLabel", { Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 20, 0, 2), BackgroundTransparency = 1, Text = "tp player list:", TextColor3 = COLORS.SubText, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = TpPlayerHolder })

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
MakeWidgetDetachable(TpPlayerHolder, 200)

-- TP LOCATION LIST
local TpLocHolder = Create("Frame", { Size = UDim2.new(1, -2, 0, 80), BackgroundColor3 = COLORS.Panel, Parent = MovePage })
AddCorner(TpLocHolder, 5)
Create("TextLabel", { Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 20, 0, 2), BackgroundTransparency = 1, Text = "tp location list:", TextColor3 = COLORS.SubText, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = TpLocHolder })

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

LocTpBtn.MouseButton1Click:Connect(function()
    if SelectedLocation then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = SelectedLocation.CFrame * CFrame.new(0, 2, 0) end
    end
end)
MakeWidgetDetachable(TpLocHolder, 200)

-- ESP TAB SETUP
CreateESPCombo("PlayerESP", ESPPage, "player ESP", Settings.PlayerESPColor, function(c) Settings.PlayerESPColor = c end, function(s) Settings.PlayerESP = s end)
CreateESPCombo("PlayerHitbox", ESPPage, "player hitbox", Settings.PlayerHitboxColor, function(c) Settings.PlayerHitboxColor = c end, function(s) Settings.PlayerHitbox = s end)
CreateESPCombo("PlayerTrace", ESPPage, "player trace", Settings.PlayerTraceColor, function(c) Settings.PlayerTraceColor = c end, function(s) Settings.PlayerTrace = s end)

CreateDistanceSlider(ESPPage)

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

-- OPTION TAB SETUP
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

-- APPLY SETTINGS TO UI SYSTEM
ApplySettingsToUI = function(newSettings)
    for k, v in pairs(newSettings) do Settings[k] = v end

    if UI_Controls["Speed"] then UI_Controls["Speed"].SetState(Settings.Speed.Enabled); UI_Controls["Speed"].SetValue(Settings.Speed.Value) end
    if UI_Controls["Jump"] then UI_Controls["Jump"].SetState(Settings.Jump.Enabled); UI_Controls["Jump"].SetValue(Settings.Jump.Value) end

    if UI_Controls["Fly"] then UI_Controls["Fly"].SetState(Settings.Fly) end
    if UI_Controls["Noclip"] then UI_Controls["Noclip"].SetState(Settings.Noclip) end
    if UI_Controls["NoGravity"] then UI_Controls["NoGravity"].SetState(Settings.NoGravity) end

    if UI_Controls["PlayerESP"] then UI_Controls["PlayerESP"].SetState(Settings.PlayerESP); UI_Controls["PlayerESP"].SetColor(Settings.PlayerESPColor) end
    if UI_Controls["PlayerHitbox"] then UI_Controls["PlayerHitbox"].SetState(Settings.PlayerHitbox); UI_Controls["PlayerHitbox"].SetColor(Settings.PlayerHitboxColor) end
    if UI_Controls["PlayerTrace"] then UI_Controls["PlayerTrace"].SetState(Settings.PlayerTrace); UI_Controls["PlayerTrace"].SetColor(Settings.PlayerTraceColor) end

    if UI_Controls["DistanceCheck"] then UI_Controls["DistanceCheck"].SetState(Settings.DistanceCheck); UI_Controls["DistanceCheck"].SetValue(Settings.DistanceVal) end
    if UI_Controls["Freecam"] then UI_Controls["Freecam"].SetState(Settings.Freecam) end

    if UI_Controls["Fullbright"] then UI_Controls["Fullbright"].SetState(Settings.Fullbright) end
    if UI_Controls["FixLag"] then UI_Controls["FixLag"].SetState(Settings.FixLag) end
    if UI_Controls["AutoExecute"] then UI_Controls["AutoExecute"].SetState(Settings.AutoExecute) end
    if UI_Controls["ShiftLock"] then UI_Controls["ShiftLock"].SetState(Settings.ShiftLock) end
    if UI_Controls["MenuLock"] then UI_Controls["MenuLock"].SetState(Settings.MenuLock) end

    FlyToggleBtn.Visible = Settings.Fly
    if not Settings.Fly then isFlyingActive = false; FlyControls.Visible = false end
end

-- AUTO LOAD PREVIOUS SESSION ON TELEPORT/REJOIN
LoadLastSession()
task.defer(function()
    ApplySettingsToUI(Settings)
end)

-- ANOMALY DETECTOR & COLOR CONTROLS
local function TriggerPurple(p)
    if not PlayerStats[p] then PlayerStats[p] = {} end
    PlayerStats[p].PurpleEndTime = os.clock() + 3
end

local function GetPlayerColor(p)
    local stats = PlayerStats[p] or {}
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not char or not hum or hum.Health <= 0 then return COLORS.Black end
    if stats.NearPlayer then return COLORS.Yellow end
    if stats.PurpleEndTime and os.clock() < stats.PurpleEndTime then return COLORS.Purple end
    return Settings.PlayerESPColor
end

-- RENDER LOOP
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
        if flatMoveDir.Magnitude > 0 then flatMoveDir = flatMoveDir.Unit end

        local flySpeed = Settings.Speed.Enabled and Settings.Speed.Value or 50
        local ySpeed = (flyUpHeld and 40 or 0) - (flyDownHeld and 40 or 0)
        myRoot.AssemblyLinearVelocity = Vector3.new(flatMoveDir.X * flySpeed, ySpeed, flatMoveDir.Z * flySpeed)
    end

    if Settings.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end

    -- DIRECT SHIFT LOCK (NO BUTTON NEEDED)
    if Settings.ShiftLock and myRoot then
        local lookVector = Camera.CFrame.LookVector
        myRoot.CFrame = CFrame.new(myRoot.Position, myRoot.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
    end

    -- ESP DISTANCE CHECK CALCULATIONS
    local allPlayers = Players:GetPlayers()
    for _, p in ipairs(allPlayers) do
        if not PlayerStats[p] then PlayerStats[p] = {} end
        PlayerStats[p].NearPlayer = false
    end

    if Settings.DistanceCheck then
        for i = 1, #allPlayers do
            local p1 = allPlayers[i]
            local root1 = p1.Character and p1.Character:FindFirstChild("HumanoidRootPart")
            if root1 then
                for j = i + 1, #allPlayers do
                    local p2 = allPlayers[j]
                    local root2 = p2.Character and p2.Character:FindFirstChild("HumanoidRootPart")
                    if root2 then
                        local dist = (root1.Position - root2.Position).Magnitude
                        if dist <= Settings.DistanceVal then
                            PlayerStats[p1].NearPlayer = true
                            PlayerStats[p2].NearPlayer = true
                        end
                    end
                end
            end
        end
    end

    -- ESP & TRACE RENDERING
    for _, p in ipairs(allPlayers) do
        if p ~= LocalPlayer and p.Character then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = p.Character:FindFirstChildOfClass("Humanoid")

            if targetRoot and targetHum then
                local displayColor = GetPlayerColor(p)

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

-- MINIMIZE BUTTON
local MiniButton = Create("ImageButton", {
    Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 15, 0.5, -25),
    BackgroundColor3 = COLORS.Panel, BackgroundTransparency = 1, BorderSizePixel = 0,
    Visible = false, ZIndex = 100, Parent = ScreenGui
})
AddCorner(MiniButton, 10)
AddStroke(MiniButton, COLORS.Accent, 1.5)

MinimizeButton.MouseButton1Click:Connect(function() Main.Visible = false; MiniButton.Visible = true end)
MiniButton.MouseButton1Click:Connect(function() Main.Visible = true; MiniButton.Visible = false end)

CloseButton.MouseButton1Click:Connect(function()
    if getgenv then getgenv().ToanCreatorLoaded = false end
    for _, l in pairs(TraceLines) do pcall(function() l:Remove() end) end
    ScreenGui:Destroy()
end)

print("ToanCreator GUI v9 - Dynamic Resizable & Floating Widgets Loaded Successfully!")
