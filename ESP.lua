--[[
    ToanCreator GUI
    Roblox LocalScript
    Place in: StarterPlayer > StarterPlayerScripts

    Tabs:
    MOVE / ESP / VISUAL / OPTION

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
    Speed = {
        Enabled = false,
        Value = 16,
    },

    Jump = {
        Enabled = false,
        Value = 50,
    },

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
    local corner = Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = parent,
    })

    return corner
end

local function AddStroke(parent, color, thickness)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 70),
        Thickness = thickness or 1,
        Parent = parent,
    })
end

local function Tween(obj, properties, duration)
    local info = TweenInfo.new(
        duration or 0.15,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    TweenService:Create(obj, info, properties):Play()
end

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = Create("ScreenGui", {
    Name = "ToanCreatorGUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui,
})

--==================================================
-- MAIN WINDOW
--==================================================

local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 410, 0, 620),
    Position = UDim2.new(0.5, -205, 0.5, -310),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    Parent = ScreenGui,
})

AddCorner(Main, 10)
AddStroke(Main, Color3.fromRGB(55, 55, 65), 1)

--==================================================
-- HEADER
--==================================================

local Header = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Parent = Main,
})

AddCorner(Header, 10)

local HeaderCover = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Parent = Header,
})

local Title = Create("TextLabel", {
    Size = UDim2.new(1, -120, 1, 0),
    Position = UDim2.new(0, 15, 0, 0),
    BackgroundTransparency = 1,
    Text = "ToanCreator",
    TextColor3 = COLORS.Text,
    TextSize = 19,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header,
})

local MinimizeButton = Create("TextButton", {
    Size = UDim2.new(0, 38, 0, 32),
    Position = UDim2.new(1, -85, 0, 10),
    BackgroundColor3 = COLORS.Button,
    Text = "—",
    TextColor3 = COLORS.Text,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Parent = Header,
})

AddCorner(MinimizeButton, 6)

local CloseButton = Create("TextButton", {
    Size = UDim2.new(0, 38, 0, 32),
    Position = UDim2.new(1, -43, 0, 10),
    BackgroundColor3 = COLORS.Button,
    Text = "×",
    TextColor3 = COLORS.Text,
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Parent = Header,
})

AddCorner(CloseButton, 6)

--==================================================
-- TAB BAR
--==================================================

local TabBar = Create("ScrollingFrame", {
    Size = UDim2.new(1, -20, 0, 42),
    Position = UDim2.new(0, 10, 0, 62),
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
    Padding = UDim.new(0, 7),
    Parent = TabBar,
})

local Content = Create("Frame", {
    Size = UDim2.new(1, -20, 1, -115),
    Position = UDim2.new(0, 10, 0, 110),
    BackgroundTransparency = 1,
    Parent = Main,
})

--==================================================
-- TAB SYSTEM
--==================================================

local Tabs = {}
local Pages = {}

local function CreateTab(name)
    local button = Create("TextButton", {
        Size = UDim2.new(0, 85, 1, -4),
        BackgroundColor3 = COLORS.Button,
        Text = name,
        TextColor3 = COLORS.SubText,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = TabBar,
    })

    AddCorner(button, 6)

    local page = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = Content,
    })

    Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        Parent = page,
    })

    Tabs[name] = button
    Pages[name] = page

    button.MouseEnter:Connect(function()
        if button:GetAttribute("Selected") ~= true then
            Tween(button, {BackgroundColor3 = COLORS.ButtonHover})
        end
    end)

    button.MouseLeave:Connect(function()
        if button:GetAttribute("Selected") ~= true then
            Tween(button, {BackgroundColor3 = COLORS.Button})
        end
    end)

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

        if selected then
            button.BackgroundColor3 = COLORS.Accent
            button.TextColor3 = Color3.new(1, 1, 1)
        else
            button.BackgroundColor3 = COLORS.Button
            button.TextColor3 = COLORS.SubText
        end
    end

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end
end

--==================================================
-- UI COMPONENTS
--==================================================

local function CreateSectionLabel(parent, text)
    return Create("TextLabel", {
        Size = UDim2.new(1, -4, 0, 25),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.SubText,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })
end

local function CreateCheckbox(parent, label, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 45),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Parent = parent,
    })

    AddCorner(holder, 7)

    local text = Create("TextLabel", {
        Size = UDim2.new(1, -65, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local check = Create("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -38, 0.5, -13),
        BackgroundColor3 = COLORS.Button,
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })

    AddCorner(check, 6)
    AddStroke(check, Color3.fromRGB(75, 75, 85), 1)

    local enabled = false

    local function SetEnabled(value)
        enabled = value

        if enabled then
            check.BackgroundColor3 = COLORS.Accent
            check.Text = "✓"
            check.TextColor3 = Color3.new(1, 1, 1)
            check.TextSize = 16
            check.Font = Enum.Font.GothamBold
        else
            check.BackgroundColor3 = COLORS.Button
            check.Text = ""
        end

        if callback then
            callback(enabled)
        end
    end

    check.MouseButton1Click:Connect(function()
        SetEnabled(not enabled)
    end)

    return holder, SetEnabled
end

local function CreateNumberInput(parent, label, defaultValue, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 45),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Parent = parent,
    })

    AddCorner(holder, 7)

    Create("TextLabel", {
        Size = UDim2.new(1, -115, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local input = Create("TextBox", {
        Size = UDim2.new(0, 85, 0, 30),
        Position = UDim2.new(1, -97, 0.5, -15),
        BackgroundColor3 = COLORS.Button,
        Text = tostring(defaultValue),
        PlaceholderText = "number",
        TextColor3 = COLORS.Text,
        PlaceholderColor3 = COLORS.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        Parent = holder,
    })

    AddCorner(input, 6)

    input.FocusLost:Connect(function()
        local number = tonumber(input.Text)

        if number then
            number = math.clamp(number, 0, 1000)
            input.Text = tostring(number)

            if callback then
                callback(number)
            end
        else
            input.Text = tostring(defaultValue)
        end
    end)

    return holder, input
end

local function CreateColorPicker(parent, label, defaultColor, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 45),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Parent = parent,
    })

    AddCorner(holder, 7)

    Create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local colorButton = Create("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -42, 0.5, -15),
        BackgroundColor3 = defaultColor,
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })

    AddCorner(colorButton, 6)
    AddStroke(colorButton, Color3.fromRGB(100, 100, 110), 1)

    local popup

    local function CreateColorPopup()
        if popup then
            popup:Destroy()
            popup = nil
            return
        end

        popup = Create("Frame", {
            Size = UDim2.new(0, 230, 0, 135),
            Position = UDim2.new(1, -235, 1, 5),
            BackgroundColor3 = COLORS.Panel2,
            BorderSizePixel = 0,
            ZIndex = 20,
            Parent = holder,
        })

        AddCorner(popup, 7)
        AddStroke(popup, Color3.fromRGB(70, 70, 80), 1)

        local colors = {
            Color3.fromRGB(255, 80, 80),
            Color3.fromRGB(255, 170, 60),
            Color3.fromRGB(255, 230, 60),
            Color3.fromRGB(80, 220, 120),
            Color3.fromRGB(70, 180, 255),
            Color3.fromRGB(130, 90, 255),
            Color3.fromRGB(255, 80, 220),
            Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(0, 0, 0),
            Color3.fromRGB(100, 255, 255),
        }

        for i, color in ipairs(colors) do
            local x = ((i - 1) % 5)
            local y = math.floor((i - 1) / 5)

            local c = Create("TextButton", {
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 8 + x * 43, 0, 8 + y * 55),
                BackgroundColor3 = color,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 21,
                Parent = popup,
            })

            AddCorner(c, 5)

            c.MouseButton1Click:Connect(function()
                colorButton.BackgroundColor3 = color

                if callback then
                    callback(color)
                end

                popup:Destroy()
                popup = nil
            end)
        end
    end

    colorButton.MouseButton1Click:Connect(CreateColorPopup)

    return holder
end

--==================================================
-- MOVE TAB
--==================================================

CreateSectionLabel(MovePage, "MOVEMENT")

local speedInput = CreateNumberInput(
    MovePage,
    "Speed: enter number",
    Settings.Speed.Value,
    function(value)
        Settings.Speed.Value = value
    end
)

local _, speedToggle = CreateCheckbox(
    MovePage,
    "Enable Speed",
    function(value)
        Settings.Speed.Enabled = value
    end
)

local jumpInput = CreateNumberInput(
    MovePage,
    "Jump: enter number",
    Settings.Jump.Value,
    function(value)
        Settings.Jump.Value = value
    end
)

local _, jumpToggle = CreateCheckbox(
    MovePage,
    "Enable Jump",
    function(value)
        Settings.Jump.Enabled = value
    end
)

local _, flyToggle = CreateCheckbox(
    MovePage,
    "Fly",
    function(value)
        Settings.Fly = value
    end
)

local _, noclipToggle = CreateCheckbox(
    MovePage,
    "Noclip",
    function(value)
        Settings.Noclip = value
    end
)

local _, gravityToggle = CreateCheckbox(
    MovePage,
    "No Gravity",
    function(value)
        Settings.NoGravity = value
    end
)

--==================================================
-- PLAYER TELEPORT
--==================================================

CreateSectionLabel(MovePage, "TELEPORT PLAYER")

local PlayerDropdown = Create("TextButton", {
    Size = UDim2.new(1, -4, 0, 42),
    BackgroundColor3 = COLORS.Panel,
    Text = "None  ▼",
    TextColor3 = COLORS.Text,
    TextSize = 13,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    AutoButtonColor = false,
    Parent = MovePage,
})

AddCorner(PlayerDropdown, 7)

local playerTeleportButton = Create("TextButton", {
    Size = UDim2.new(0, 42, 0, 42),
    Position = UDim2.new(1, -46, 0, 0),
    BackgroundColor3 = COLORS.Accent,
    Text = "🖱",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Parent = PlayerDropdown,
})

AddCorner(playerTeleportButton, 7)

local selectedPlayer = nil
local playerMenu

local function RefreshPlayerList()
    if playerMenu then
        playerMenu:Destroy()
        playerMenu = nil
    end

    playerMenu = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 150),
        BackgroundColor3 = COLORS.Panel2,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = MovePage,
    })

    AddCorner(playerMenu, 7)

    local scroll = Create("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 11,
        Parent = playerMenu,
    })

    Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        Parent = scroll,
    })

    local noneButton = Create("TextButton", {
        Size = UDim2.new(1, -5, 0, 30),
        BackgroundColor3 = COLORS.Button,
        Text = "None",
        TextColor3 = COLORS.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ZIndex = 12,
        Parent = scroll,
    })

    AddCorner(noneButton, 5)

    noneButton.MouseButton1Click:Connect(function()
        selectedPlayer = nil
        PlayerDropdown.Text = "None  ▼"
        playerMenu:Destroy()
        playerMenu = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local button = Create("TextButton", {
                Size = UDim2.new(1, -5, 0, 30),
                BackgroundColor3 = COLORS.Button,
                Text = player.Name,
                TextColor3 = COLORS.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                ZIndex = 12,
                Parent = scroll,
            })

            AddCorner(button, 5)

            button.MouseButton1Click:Connect(function()
                selectedPlayer = player
                PlayerDropdown.Text = player.Name .. "  ▼"

                playerMenu:Destroy()
                playerMenu = nil
            end)
        end
    end
end

PlayerDropdown.MouseButton1Click:Connect(function()
    RefreshPlayerList()
end)

playerTeleportButton.MouseButton1Click:Connect(function()
    if selectedPlayer
        and selectedPlayer.Character
        and selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        and LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then

        LocalPlayer.Character.HumanoidRootPart.CFrame =
            selectedPlayer.Character.HumanoidRootPart.CFrame
            * CFrame.new(0, 3, 0)
    end
end)

--==================================================
-- TELEPORT LOCATIONS
--==================================================

CreateSectionLabel(MovePage, "TELEPORT LOCATION")

local LocationDropdown = Create("TextButton", {
    Size = UDim2.new(1, -4, 0, 42),
    BackgroundColor3 = COLORS.Panel,
    Text = "None  ▼",
    TextColor3 = COLORS.Text,
    TextSize = 13,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    AutoButtonColor = false,
    Parent = MovePage,
})

AddCorner(LocationDropdown, 7)

local locationTeleportButton = Create("TextButton", {
    Size = UDim2.new(0, 42, 0, 42),
    Position = UDim2.new(1, -46, 0, 0),
    BackgroundColor3 = COLORS.Accent,
    Text = "🖱",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Parent = LocationDropdown,
})

AddCorner(locationTeleportButton, 7)

local LocationInputHolder = Create("Frame", {
    Size = UDim2.new(1, -4, 0, 42),
    BackgroundTransparency = 1,
    Parent = MovePage,
})

local LocationInput = Create("TextBox", {
    Size = UDim2.new(1, -105, 1, 0),
    BackgroundColor3 = COLORS.Panel,
    Text = "",
    PlaceholderText = "＋  Set locate",
    TextColor3 = COLORS.Text,
    PlaceholderColor3 = COLORS.SubText,
    TextSize = 13,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    Parent = LocationInputHolder,
})

AddCorner(LocationInput, 7)

local SetLocationButton = Create("TextButton", {
    Size = UDim2.new(0, 95, 1, 0),
    Position = UDim2.new(1, -95, 0, 0),
    BackgroundColor3 = COLORS.Green,
    Text = "Set",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    Parent = LocationInputHolder,
})

AddCorner(SetLocationButton, 7)

local selectedLocation = nil
local locationMenu

local function CreateLocationMarker(name, cframe)
    local folder = workspace:FindFirstChild("ToanCreator_LocationMarkers")

    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ToanCreator_LocationMarkers"
        folder.Parent = workspace
    end

    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(2, 2, 2)
    part.Position = cframe.Position + Vector3.new(0, 1, 0)
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(100, 255, 170)
    part.Transparency = 0.15
    part.Parent = folder

    AddCorner(part, 0)

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 160, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
end

local function RefreshLocationList()
    if locationMenu then
        locationMenu:Destroy()
        locationMenu = nil
    end

    locationMenu = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 150),
        BackgroundColor3 = COLORS.Panel2,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = MovePage,
    })

    AddCorner(locationMenu, 7)

    local scroll = Create("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 11,
        Parent = locationMenu,
    })

    Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        Parent = scroll,
    })

    local none = Create("TextButton", {
        Size = UDim2.new(1, -5, 0, 30),
        BackgroundColor3 = COLORS.Button,
        Text = "None",
        TextColor3 = COLORS.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ZIndex = 12,
        Parent = scroll,
    })

    AddCorner(none, 5)

    none.MouseButton1Click:Connect(function()
        selectedLocation = nil
        LocationDropdown.Text = "None  ▼"

        locationMenu:Destroy()
        locationMenu = nil
    end)

    for _, data in ipairs(Locations) do
        local button = Create("TextButton", {
            Size = UDim2.new(1, -5, 0, 30),
            BackgroundColor3 = COLORS.Button,
            Text = data.Name,
            TextColor3 = COLORS.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            ZIndex = 12,
            Parent = scroll,
        })

        AddCorner(button, 5)

        button.MouseButton1Click:Connect(function()
            selectedLocation = data
            LocationDropdown.Text = data.Name .. "  ▼"

            locationMenu:Destroy()
            locationMenu = nil
        end)
    end
end

LocationDropdown.MouseButton1Click:Connect(function()
    RefreshLocationList()
end)

SetLocationButton.MouseButton1Click:Connect(function()
    local name = LocationInput.Text

    if name == "" then
        return
    end

    if #Locations >= 10 then
        LocationInput.Text = ""
        LocationInput.PlaceholderText = "Maximum 10 locations"
        task.delay(2, function()
            LocationInput.PlaceholderText = "＋  Set locate"
        end)
        return
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local data = {
        Name = name,
        CFrame = root.CFrame,
    }

    table.insert(Locations, data)

    CreateLocationMarker(name, root.CFrame)

    LocationInput.Text = ""
    selectedLocation = data
    LocationDropdown.Text = name .. "  ▼"
end)

locationTeleportButton.MouseButton1Click:Connect(function()
    if selectedLocation
        and LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then

        LocalPlayer.Character.HumanoidRootPart.CFrame =
            selectedLocation.CFrame * CFrame.new(0, 3, 0)
    end
end)

--==================================================
-- ESP TAB
--==================================================

CreateSectionLabel(ESPPage, "PLAYER ESP")

CreateColorPicker(
    ESPPage,
    "Player ESP color",
    Settings.PlayerESPColor,
    function(color)
        Settings.PlayerESPColor = color
    end
)

local _, playerESPtoggle = CreateCheckbox(
    ESPPage,
    "Player ESP",
    function(value)
        Settings.PlayerESP = value
    end
)

CreateColorPicker(
    ESPPage,
    "Player Hitbox color",
    Settings.PlayerHitboxColor,
    function(color)
        Settings.PlayerHitboxColor = color
    end
)

local _, hitboxToggle = CreateCheckbox(
    ESPPage,
    "Player Hitbox",
    function(value)
        Settings.PlayerHitbox = value
    end
)

CreateColorPicker(
    ESPPage,
    "Player Trace color",
    Settings.PlayerTraceColor,
    function(color)
        Settings.PlayerTraceColor = color
    end
)

local _, traceToggle = CreateCheckbox(
    ESPPage,
    "Player Trace",
    function(value)
        Settings.PlayerTrace = value
    end
)

local _, distanceToggle = CreateCheckbox(
    ESPPage,
    "Distance Check (≤ 50 studs)",
    function(value)
        Settings.DistanceCheck = value
    end
)

local _, freecamToggle = CreateCheckbox(
    ESPPage,
    "Freecam",
    function(value)
        Settings.Freecam = value
    end
)

--==================================================
-- VISUAL TAB
--==================================================

CreateSectionLabel(VisualPage, "VISUAL")

local _, visualInfo = CreateCheckbox(
    VisualPage,
    "Visual features",
    function(value)
        -- Reserved for future visual options.
    end
)

local visualText = Create("TextLabel", {
    Size = UDim2.new(1, -4, 0, 70),
    BackgroundColor3 = COLORS.Panel,
    Text = "Visual tab reserved for additional visual features.",
    TextColor3 = COLORS.SubText,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    Parent = VisualPage,
})

AddCorner(visualText, 7)

--==================================================
-- OPTION TAB
--==================================================

CreateSectionLabel(OptionPage, "OPTIONS")

local _, fullbrightToggle = CreateCheckbox(
    OptionPage,
    "Fullbright",
    function(value)
        Settings.Fullbright = value
    end
)

local _, fixlagToggle = CreateCheckbox(
    OptionPage,
    "Fixlag",
    function(value)
        Settings.FixLag = value
    end
)

--==================================================
-- SPEED / JUMP / NOCLIP / GRAVITY
--==================================================

local originalGravity = workspace.Gravity
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
}

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local character = GetCharacter()

    if character then
        return character:FindFirstChildOfClass("Humanoid")
    end
end

local function GetRoot()
    local character = GetCharacter()

    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
end

local function UpdateMovement()
    local humanoid = GetHumanoid()

    if not humanoid then
        return
    end

    if Settings.Speed.Enabled then
        humanoid.WalkSpeed = Settings.Speed.Value
    else
        humanoid.WalkSpeed = 16
    end

    if Settings.Jump.Enabled then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Settings.Jump.Value
    else
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 50
    end
end

local function UpdateNoclip()
    local character = GetCharacter()

    if not character then
        return
    end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = not Settings.Noclip
        end
    end
end

local function UpdateGravity()
    if Settings.NoGravity then
        workspace.Gravity = 0
    else
        workspace.Gravity = originalGravity
    end
end

--==================================================
-- FLY
--==================================================

local flyVelocity
local flyConnection

local function StopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
end

local function StartFly()
    StopFly()

    local root = GetRoot()

    if not root then
        return
    end

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root

    flyConnection = RunService.RenderStepped:Connect(function()
        if not Settings.Fly then
            StopFly()
            return
        end

        local characterRoot = GetRoot()

        if not characterRoot then
            return
        end

        local camera = workspace.CurrentCamera
        local move = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            move += camera.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            move -= camera.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            move -= camera.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            move += camera.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            move += Vector3.new(0, 1, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            move -= Vector3.new(0, 1, 0)
        end

        if move.Magnitude > 0 then
            move = move.Unit * 60
        end

        flyVelocity.Velocity = move
    end)
end

flyToggle = flyToggle

--==================================================
-- MOBILE / TOUCH FLY BUTTONS
--==================================================

local FlyControls = Create("Frame", {
    Size = UDim2.new(0, 145, 0, 75),
    Position = UDim2.new(1, -160, 0.55, 0),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = ScreenGui,
})

local FlyUp = Create("TextButton", {
    Size = UDim2.new(0, 62, 0, 62),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = COLORS.Accent,
    Text = "↑",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 28,
    Font = Enum.Font.GothamBold,
    Parent = FlyControls,
})

AddCorner(FlyUp, 31)

local FlyDown = Create("TextButton", {
    Size = UDim2.new(0, 62, 0, 62),
    Position = UDim2.new(0, 72, 0, 0),
    BackgroundColor3 = COLORS.Accent,
    Text = "↓",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 28,
    Font = Enum.Font.GothamBold,
    Parent = FlyControls,
})

AddCorner(FlyDown, 31)

local upHeld = false
local downHeld = false

FlyUp.MouseButton1Down:Connect(function()
    upHeld = true
end)

FlyUp.MouseButton1Up:Connect(function()
    upHeld = false
end)

FlyDown.MouseButton1Down:Connect(function()
    downHeld = true
end)

FlyDown.MouseButton1Up:Connect(function()
    downHeld = false
end)

--==================================================
-- ESP SYSTEM
--==================================================

local ESPObjects = {}

local function RemoveESP(player)
    local data = ESPObjects[player]

    if not data then
        return
    end

    for _, object in pairs(data) do
        if typeof(object) == "Instance" then
            object:Destroy()
        end
    end

    ESPObjects[player] = nil
end

local function CreateESP(player)
    if player == LocalPlayer then
        return
    end

    RemoveESP(player)

    local data = {}

    local highlight = Instance.new("Highlight")
    highlight.Name = "ToanCreator_ESP"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Settings.PlayerESPColor
    highlight.Enabled = Settings.PlayerESP or Settings.PlayerHitbox

    data.Highlight = highlight

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ToanCreator_Name"
    billboard.Size = UDim2.new(0, 180, 0, 45)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = Settings.PlayerESP

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Settings.PlayerESPColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    data.Billboard = billboard
    data.NameLabel = nameLabel

    ESPObjects[player] = data

    local function CharacterAdded(character)
        highlight.Adornee = character
        highlight.Parent = character

        billboard.Adornee = character
        billboard.Parent = character
    end

    if player.Character then
        CharacterAdded(player.Character)
    end

    player.CharacterAdded:Connect(CharacterAdded)
end

for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

local function UpdateESP()
    for player, data in pairs(ESPObjects) do
        if data.Highlight then
            data.Highlight.Enabled =
                Settings.PlayerHitbox or Settings.PlayerESP

            if Settings.PlayerHitbox then
                data.Highlight.OutlineColor =
                    Settings.PlayerHitboxColor
                data.Highlight.FillColor =
                    Settings.PlayerHitboxColor
                data.Highlight.FillTransparency = 0.85
            else
                data.Highlight.FillTransparency = 1
            end

            if Settings.PlayerESP then
                data.Highlight.OutlineColor =
                    Settings.PlayerESPColor
            end
        end

        if data.Billboard then
            data.Billboard.Enabled = Settings.PlayerESP

            if data.NameLabel then
                data.NameLabel.TextColor3 =
                    Settings.PlayerESPColor
            end
        end
    end
end

--==================================================
-- TRACE SYSTEM
--==================================================

local TraceFolder = Instance.new("Folder")
TraceFolder.Name = "ToanCreator_Traces"
TraceFolder.Parent = workspace

local function ClearTraces()
    for _, obj in ipairs(TraceFolder:GetChildren()) do
        obj:Destroy()
    end
end

local function CreateTrace(fromPosition, toPosition)
    local distance = (toPosition - fromPosition).Magnitude

    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Settings.PlayerTraceColor
    part.Size = Vector3.new(0.05, 0.05, distance)
    part.CFrame = CFrame.lookAt(
        (fromPosition + toPosition) / 2,
        toPosition
    )
    part.Parent = TraceFolder

    return part
end

local function UpdateTraces()
    ClearTraces()

    if not Settings.PlayerTrace then
        return
    end

    local root = GetRoot()

    if not root then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild("HumanoidRootPart") then

            CreateTrace(
                root.Position,
                player.Character.HumanoidRootPart.Position
            )
        end
    end
end

--==================================================
-- DISTANCE CHECK
--==================================================

local function UpdateDistanceCheck()
    for player, data in pairs(ESPObjects) do
        if data.NameLabel and player.Character then
            local root = GetRoot()
            local otherRoot =
                player.Character:FindFirstChild("HumanoidRootPart")

            if root and otherRoot then
                local distance =
                    (root.Position - otherRoot.Position).Magnitude

                if Settings.DistanceCheck and distance <= 50 then
                    data.NameLabel.Text =
                        player.Name .. " [•]"
                    data.NameLabel.TextColor3 = COLORS.Yellow
                else
                    data.NameLabel.Text = player.Name
                    data.NameLabel.TextColor3 =
                        Settings.PlayerESPColor
                end
            end
        end
    end
end

--==================================================
-- FREECAM
--==================================================

local originalCameraType
local freecamConnection
local freecamPosition
local freecamYaw = 0
local freecamPitch = 0

local function StopFreecam()
    if freecamConnection then
        freecamConnection:Disconnect()
        freecamConnection = nil
    end

    local camera = workspace.CurrentCamera

    camera.CameraType = originalCameraType
    camera.CameraSubject = GetHumanoid()
end

local function StartFreecam()
    StopFreecam()

    local camera = workspace.CurrentCamera

    originalCameraType = camera.CameraType
    camera.CameraType = Enum.CameraType.Scriptable

    freecamPosition = camera.CFrame.Position

    local x, y, z = camera.CFrame:ToOrientation()
    freecamYaw = y
    freecamPitch = x

    freecamConnection = RunService.RenderStepped:Connect(function(dt)
        if not Settings.Freecam then
            StopFreecam()
            return
        end

        local move = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            move += Vector3.new(0, 0, -1)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            move += Vector3.new(0, 0, 1)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            move += Vector3.new(-1, 0, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            move += Vector3.new(1, 0, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            move += Vector3.new(0, 1, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            move += Vector3.new(0, -1, 0)
        end

        local speed = 50

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            speed = 100
        end

        local rotation =
            CFrame.Angles(0, freecamYaw, 0)
            * CFrame.Angles(freecamPitch, 0, 0)

        freecamPosition +=
            rotation:VectorToWorldSpace(move) * speed * dt

        camera.CFrame =
            CFrame.new(freecamPosition)
            * CFrame.Angles(0, freecamYaw, 0)
            * CFrame.Angles(freecamPitch, 0, 0)
    end)
end

-- Mouse look for freecam
UserInputService.InputChanged:Connect(function(input)
    if not Settings.Freecam then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        freecamYaw -= input.Delta.X * 0.003
        freecamPitch -= input.Delta.Y * 0.003

        freecamPitch = math.clamp(
            freecamPitch,
            -math.rad(85),
            math.rad(85)
        )
    end
end)

--==================================================
-- FULLBRIGHT
--==================================================

local function UpdateFullbright()
    if Settings.Fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
    end
end

--==================================================
-- FIXLAG
--==================================================

local function ApplyFixLag()
    if not Settings.FixLag then
        return
    end

    -- Conservative client-side optimization.
    -- It does NOT delete important game objects.

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("ParticleEmitter")
            or object:IsA("Trail")
            or object:IsA("Beam") then

            object.Enabled = false
        end
    end
end

--==================================================
-- FLY CONTROL LOOP
--==================================================

RunService.RenderStepped:Connect(function()
    if Settings.Fly then
        if not flyConnection then
            StartFly()
        end

        local root = GetRoot()

        if root and flyVelocity then
            local vertical = 0

            if upHeld then
                vertical += 60
            end

            if downHeld then
                vertical -= 60
            end

            local velocity = flyVelocity.Velocity
            flyVelocity.Velocity =
                Vector3.new(
                    velocity.X,
                    vertical,
                    velocity.Z
                )
        end

        FlyControls.Visible = true
    else
        StopFly()
        FlyControls.Visible = false
    end

    UpdateMovement()
    UpdateNoclip()
    UpdateGravity()
    UpdateESP()
    UpdateDistanceCheck()
    UpdateTraces()
    UpdateFullbright()
end)

--==================================================
-- FREECAM UPDATE
--==================================================

RunService.RenderStepped:Connect(function()
    if Settings.Freecam then
        if not freecamConnection then
            StartFreecam()
        end
    else
        if freecamConnection then
            StopFreecam()
        end
    end
end)

--==================================================
-- FIXLAG
--==================================================

task.spawn(function()
    while ScreenGui.Parent do
        if Settings.FixLag then
            ApplyFixLag()
        end

        task.wait(5)
    end
end)

--==================================================
-- MINIMIZE SYSTEM
--==================================================

local MiniButton = Create("TextButton", {
    Name = "MiniButton",
    Size = UDim2.new(0, 55, 0, 55),
    Position = UDim2.new(0, 20, 0.5, -27),
    BackgroundColor3 = COLORS.Accent,
    Text = "TC",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Visible = false,
    AutoButtonColor = false,
    Parent = ScreenGui,
})

AddCorner(MiniButton, 8)
AddStroke(MiniButton, Color3.fromRGB(130, 200, 255), 1)

-- Drag helper
local function MakeDraggable(object, handle)
    local dragging = false
    local dragStart
    local startPos

    handle = handle or object

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - dragStart

            object.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

MakeDraggable(Main, Header)
MakeDraggable(MiniButton, MiniButton)

--==================================================
-- DOUBLE CLICK MINI BUTTON
--==================================================

local lastClick = 0

MiniButton.MouseButton1Click:Connect(function()
    local now = os.clock()

    if now - lastClick <= 0.35 then
        minimized = false
        guiOpen = true

        MiniButton.Visible = false
        Main.Visible = true
    end

    lastClick = now
end)

--==================================================
-- MINIMIZE
--==================================================

MinimizeButton.MouseButton1Click:Connect(function()
    minimized = true
    guiOpen = false

    Main.Visible = false
    MiniButton.Visible = true
end)

--==================================================
-- CLOSE CONFIRMATION
--==================================================

local ConfirmOverlay = Create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.35,
    Visible = false,
    ZIndex = 100,
    Parent = ScreenGui,
})

local ConfirmBox = Create("Frame", {
    Size = UDim2.new(0, 300, 0, 160),
    Position = UDim2.new(0.5, -150, 0.5, -80),
    BackgroundColor3 = COLORS.Panel2,
    BorderSizePixel = 0,
    ZIndex = 101,
    Parent = ConfirmOverlay,
})

AddCorner(ConfirmBox, 10)
AddStroke(ConfirmBox, Color3.fromRGB(80, 80, 90), 1)

Create("TextLabel", {
    Size = UDim2.new(1, -25, 0, 40),
    Position = UDim2.new(0, 12, 0, 15),
    BackgroundTransparency = 1,
    Text = "Close Script?",
    TextColor3 = COLORS.Text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    ZIndex = 102,
    Parent = ConfirmBox,
})

Create("TextLabel", {
    Size = UDim2.new(1, -30, 0, 45),
    Position = UDim2.new(0, 15, 0, 53),
    BackgroundTransparency = 1,
    Text = "Are you sure you want to close this script?",
    TextColor3 = COLORS.SubText,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    ZIndex = 102,
    Parent = ConfirmBox,
})

local ConfirmYes = Create("TextButton", {
    Size = UDim2.new(0, 120, 0, 35),
    Position = UDim2.new(0, 20, 1, -48),
    BackgroundColor3 = COLORS.Red,
    Text = "Close",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    ZIndex = 102,
    Parent = ConfirmBox,
})

AddCorner(ConfirmYes, 6)

local ConfirmNo = Create("TextButton", {
    Size = UDim2.new(0, 120, 0, 35),
    Position = UDim2.new(1, -140, 1, -48),
    BackgroundColor3 = COLORS.Button,
    Text = "Cancel",
    TextColor3 = COLORS.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    ZIndex = 102,
    Parent = ConfirmBox,
})

AddCorner(ConfirmNo, 6)

CloseButton.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = true
end)

ConfirmNo.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false
end)

ConfirmYes.MouseButton1Click:Connect(function()
    -- Restore modified properties
    workspace.Gravity = originalGravity

    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.GlobalShadows = originalLighting.GlobalShadows

    StopFly()
    StopFreecam()
    ClearTraces()

    local markerFolder =
        workspace:FindFirstChild("ToanCreator_LocationMarkers")

    if markerFolder then
        markerFolder:Destroy()
    end

    ScreenGui:Destroy()
end)

--==================================================
-- RESPAWN SUPPORT
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)

    if Settings.Fly then
        StartFly()
    end

    UpdateMovement()
end)

--==================================================
-- START
--==================================================

SelectTab("MOVE")

print("ToanCreator GUI loaded successfully.")
