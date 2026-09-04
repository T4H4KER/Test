--[[
    ToanCreator GUI - Mobile Optimized & Auto Execute Support
    Place in: StarterPlayer > StarterPlayerScripts (or Executed via Delta)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- AUTO EXECUTE HELPER
--==================================================
local function QueueScript(source)
    local queueFunc = queue_on_teleport or (syn and syn.queue_on_teleport) or queue_for_teleport
    if queueFunc then
        queueFunc(source)
    end
end

--==================================================
-- CONFIG
--==================================================

local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    Panel = Color3.fromRGB(25, 25, 30),
    Panel2 = Color3.fromRGB(31, 31, 37),
    Button = Color3.fromRGB(42, 42, 50),
    ButtonHover = Color3.fromRGB(55, 55, 65),
    Accent = Color3.fromRGB(75, 170, 255),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(165, 165, 175),
    Green = Color3.fromRGB(80, 220, 130),
    Red = Color3.fromRGB(235, 70, 70),
    Yellow = Color3.fromRGB(255, 215, 70),
    Black = Color3.fromRGB(0, 0, 0),
}

local guiOpen = true
local minimized = false

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
    AutoExecute = false
}

local Locations = {}

--==================================================
-- UTILITY
--==================================================

local function Create(className, properties)
    local obj = Instance.new(className)
    for property, value in pairs(properties or {}) do
        obj[property] = value
    end
    return obj
end

local function AddCorner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = parent,
    })
end

local function AddStroke(parent, color, thickness)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 70),
        Thickness = thickness or 1,
        Parent = parent,
    })
end

local function Tween(obj, properties, duration)
    local info = TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(obj, info, properties):Play()
end

--==================================================
-- SCREEN GUI & MAIN WINDOW (MOBILE OPTIMIZED: 280x360)
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
    Size = UDim2.new(0, 280, 0, 360),
    Position = UDim2.new(0.5, -140, 0.5, -180),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    Parent = ScreenGui,
})

AddCorner(Main, 10)
AddStroke(Main, Color3.fromRGB(55, 55, 65), 1.5)

--==================================================
-- HEADER
--==================================================

local Header = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
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

local Title = Create("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0),
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
    Size = UDim2.new(0, 28, 0, 26),
    Position = UDim2.new(1, -62, 0, 6),
    BackgroundColor3 = COLORS.Button,
    Text = "—",
    TextColor3 = COLORS.Text,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Parent = Header,
})
AddCorner(MinimizeButton, 5)

local CloseButton = Create("TextButton", {
    Size = UDim2.new(0, 28, 0, 26),
    Position = UDim2.new(1, -32, 0, 6),
    BackgroundColor3 = COLORS.Button,
    Text = "×",
    TextColor3 = COLORS.Text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Parent = Header,
})
AddCorner(CloseButton, 5)

--==================================================
-- TAB BAR
--==================================================

local TabBar = Create("ScrollingFrame", {
    Size = UDim2.new(1, -12, 0, 32),
    Position = UDim2.new(0, 6, 0, 42),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X,
    Parent = Main,
})

local TabLayout = Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 5),
    Parent = TabBar,
})

local Content = Create("Frame", {
    Size = UDim2.new(1, -12, 1, -82),
    Position = UDim2.new(0, 6, 0, 78),
    BackgroundTransparency = 1,
    Parent = Main,
})

--==================================================
-- TAB SYSTEM
--==================================================

local Tabs, Pages = {}, {}

local function CreateTab(name)
    local button = Create("TextButton", {
        Size = UDim2.new(0, 62, 1, 0),
        BackgroundColor3 = COLORS.Button,
        Text = name,
        TextColor3 = COLORS.SubText,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = TabBar,
    })
    AddCorner(button, 5)

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
        Padding = UDim.new(0, 6),
        Parent = page,
    })

    Tabs[name] = button
    Pages[name] = page

    return button, page
end

local MoveTab, MovePage = CreateTab("MOVE")
local ESPTab, ESPPage = CreateTab("ESP")
local VisualTab, VisualPage = CreateTab("VISUAL")
local OptionTab, OptionPage = CreateTab("OPTION")

local function SelectTab(name)
    for tabName, button in pairs(Tabs) do
        local selected = tabName == name
        button:SetAttribute("Selected", selected)
        button.BackgroundColor3 = selected and COLORS.Accent or COLORS.Button
        button.TextColor3 = selected and Color3.new(1, 1, 1) or COLORS.SubText
    end
    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end
end

MoveTab.MouseButton1Click:Connect(function() SelectTab("MOVE") end)
ESPTab.MouseButton1Click:Connect(function() SelectTab("ESP") end)
VisualTab.MouseButton1Click:Connect(function() SelectTab("VISUAL") end)
OptionTab.MouseButton1Click:Connect(function() SelectTab("OPTION") end)

--==================================================
-- UI COMPONENTS
--==================================================

local function CreateSectionLabel(parent, text)
    return Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.SubText,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })
end

local function CreateCheckbox(parent, label, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -2, 0, 34),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Parent = parent,
    })
    AddCorner(holder, 6)

    local text = Create("TextLabel", {
        Size = UDim2.new(1, -45, 1, 0),
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
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -28, 0.5, -11),
        BackgroundColor3 = COLORS.Button,
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })
    AddCorner(check, 4)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local enabled = false

    local function SetEnabled(value)
        enabled = value
        if enabled then
            check.BackgroundColor3 = COLORS.Accent
            check.Text = "✓"
            check.TextColor3 = Color3.new(1, 1, 1)
            check.TextSize = 12
            check.Font = Enum.Font.GothamBold
        else
            check.BackgroundColor3 = COLORS.Button
            check.Text = ""
        end
        if callback then callback(enabled) end
    end

    check.MouseButton1Click:Connect(function()
        SetEnabled(not enabled)
    end)

    return holder, SetEnabled
end

local function CreateNumberInput(parent, label, defaultValue, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -2, 0, 34),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Parent = parent,
    })
    AddCorner(holder, 6)

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
        Size = UDim2.new(0, 60, 0, 24),
        Position = UDim2.new(1, -66, 0.5, -12),
        BackgroundColor3 = COLORS.Button,
        Text = tostring(defaultValue),
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = holder,
    })
    AddCorner(input, 4)

    input.FocusLost:Connect(function()
        local number = tonumber(input.Text)
        if number then
            number = math.clamp(number, 0, 1000)
            input.Text = tostring(number)
            if callback then callback(number) end
        else
            input.Text = tostring(defaultValue)
        end
    end)

    return holder, input
end

local function CreateColorPicker(parent, label, defaultColor, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -2, 0, 34),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Parent = parent,
    })
    AddCorner(holder, 6)

    Create("TextLabel", {
        Size = UDim2.new(1, -45, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local colorButton = Create("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -28, 0.5, -11),
        BackgroundColor3 = defaultColor,
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })
    AddCorner(colorButton, 4)

    return holder
end

--==================================================
-- MOVE TAB
--==================================================

CreateSectionLabel(MovePage, "MOVEMENT")

CreateNumberInput(MovePage, "Speed Val", Settings.Speed.Value, function(v) Settings.Speed.Value = v end)
CreateCheckbox(MovePage, "Enable Speed", function(v) Settings.Speed.Enabled = v end)
CreateNumberInput(MovePage, "Jump Val", Settings.Jump.Value, function(v) Settings.Jump.Value = v end)
CreateCheckbox(MovePage, "Enable Jump", function(v) Settings.Jump.Enabled = v end)
CreateCheckbox(MovePage, "Fly", function(v) Settings.Fly = v end)
CreateCheckbox(MovePage, "Noclip", function(v) Settings.Noclip = v end)
CreateCheckbox(MovePage, "No Gravity", function(v) Settings.NoGravity = v end)

--==================================================
-- ESP TAB
--==================================================

CreateSectionLabel(ESPPage, "PLAYER ESP")

CreateColorPicker(ESPPage, "ESP Color", Settings.PlayerESPColor, function(c) Settings.PlayerESPColor = c end)
CreateCheckbox(ESPPage, "Player ESP", function(v) Settings.PlayerESP = v end)
CreateColorPicker(ESPPage, "Hitbox Color", Settings.PlayerHitboxColor, function(c) Settings.PlayerHitboxColor = c end)
CreateCheckbox(ESPPage, "Player Hitbox", function(v) Settings.PlayerHitbox = v end)
CreateColorPicker(ESPPage, "Trace Color", Settings.PlayerTraceColor, function(c) Settings.PlayerTraceColor = c end)
CreateCheckbox(ESPPage, "Player Trace", function(v) Settings.PlayerTrace = v end)
CreateCheckbox(ESPPage, "Distance Check", function(v) Settings.DistanceCheck = v end)
CreateCheckbox(ESPPage, "Freecam", function(v) Settings.Freecam = v end)

--==================================================
-- VISUAL TAB
--==================================================

CreateSectionLabel(VisualPage, "VISUAL")

local visualText = Create("TextLabel", {
    Size = UDim2.new(1, -2, 0, 50),
    BackgroundColor3 = COLORS.Panel,
    Text = "Visual features tab.",
    TextColor3 = COLORS.SubText,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    Parent = VisualPage,
})
AddCorner(visualText, 6)

--==================================================
-- OPTION TAB
--==================================================

CreateSectionLabel(OptionPage, "OPTIONS")

CreateCheckbox(OptionPage, "Fullbright", function(v) Settings.Fullbright = v end)
CreateCheckbox(OptionPage, "Fixlag", function(v) Settings.FixLag = v end)

-- AUTO EXECUTE OPTION
local _, SetAutoExec = CreateCheckbox(OptionPage, "Auto Execute", function(v)
    Settings.AutoExecute = v
    if v then
        -- Lưu script để tự kích hoạt khi đổi server/teleport
        local source = [[
            task.wait(1)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/"))() -- Tự động nạp lại
        ]]
        -- Nếu dùng executor có hỗ trợ queue_on_teleport
        QueueScript("loadstring(game:HttpGet('...'))()")
    end
end)

--==================================================
-- DRAGGABLE SYSTEM (KÉO DI CHUYỂN BẰNG TẤT CẢ VIỀN/KHUNG BẢNG)
--==================================================

local function EnableDragging(guiObject)
    local dragging = false
    local dragStart, startPos

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- Cho phép di chuyển khi bấm vào viền/khung chính (tránh xung đột với scroll/button nếu bấm vào con)
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Cho phép kéo ở cả khung Main và Header
EnableDragging(Main)

--==================================================
-- MOVEMENT & LOGIC LOOPS
--==================================================

local originalGravity = workspace.Gravity

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Settings.Speed.Enabled then hum.WalkSpeed = Settings.Speed.Value else hum.WalkSpeed = 16 end
            if Settings.Jump.Enabled then hum.UseJumpPower = true; hum.JumpPower = Settings.Jump.Value else hum.JumpPower = 50 end
        end
        if Settings.Noclip then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
    workspace.Gravity = Settings.NoGravity and 0 or originalGravity
end)

--==================================================
-- MINIMIZE & CLOSE
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
EnableDragging(MiniButton)

MinimizeButton.MouseButton1Click:Connect(function()
    Main.Visible = false
    MiniButton.Visible = true
end)

MiniButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    MiniButton.Visible = false
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

SelectTab("MOVE")
print("ToanCreator GUI Mobile Loaded.")
