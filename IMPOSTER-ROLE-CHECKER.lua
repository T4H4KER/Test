--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.9) ~  Much Love, Ferib 

]]--

local Players = game:GetService("Players");
local CoreGui = game:GetService("CoreGui");
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Workspace = game:GetService("Workspace");
local Lighting = game:GetService("Lighting");
local LocalPlayer = Players.LocalPlayer;
local Camera = Workspace.CurrentCamera;
if CoreGui:FindFirstChild("RoleCheckerUI") then
	CoreGui.RoleCheckerUI:Destroy();
end
local DetectedRoles = {};
local IsAliveCache = {};
local LastPositions = {};
local SpectatingPlayer = nil;
local TraceLines = {};
local FullbrightEnabled = false;
local COLOR_MAP = {[1]={Name="Red",Color=Color3.fromRGB(197, 17, 17)},[2]={Name="Blue",Color=Color3.fromRGB(19, 46, 209)},[3]={Name="Dark Green",Color=Color3.fromRGB(17, 127, 45)},[4]={Name="Pink",Color=Color3.fromRGB(237, 84, 186)},[5]={Name="Orange",Color=Color3.fromRGB(239, 125, 13)},[6]={Name="Yellow",Color=Color3.fromRGB(245, 245, 11)},[7]={Name="Black",Color=Color3.fromRGB(60, 60, 60)},[8]={Name="White",Color=Color3.fromRGB(214, 224, 240)},[9]={Name="Purple",Color=Color3.fromRGB(107, 15, 222)},[10]={Name="Brown",Color=Color3.fromRGB(113, 73, 30)},[11]={Name="Cyan",Color=Color3.fromRGB(56, 254, 220)},[12]={Name="Green",Color=Color3.fromRGB(111, 229, 74)},[13]={Name="Gray",Color=Color3.fromRGB(131, 148, 155)},[14]={Name="Lemon",Color=Color3.fromRGB(240, 247, 163)},[15]={Name="Bubble Gum",Color=Color3.fromRGB(255, 160, 193)},[16]={Name="Stone",Color=Color3.fromRGB(180, 180, 180)},[17]={Name="Cocoa",Color=Color3.fromRGB(190, 150, 115)},[18]={Name="Sky",Color=Color3.fromRGB(110, 185, 239)},[19]={Name="Swamp",Color=Color3.fromRGB(35, 75, 20)},[20]={Name="Magenta",Color=Color3.fromRGB(90, 10, 80)}};
local ESP_COLORS = {RED=Color3.fromRGB(235, 70, 70),CYAN=Color3.fromRGB(0, 255, 255),ORANGE=Color3.fromRGB(255, 180, 0),YELLOW=Color3.fromRGB(255, 215, 70),GRAY=Color3.fromRGB(120, 120, 120),WHITE=Color3.fromRGB(255, 255, 255)};
local function GetPlayerColorData(player)
	local FlatIdent_2584C = 0;
	local colorId;
	local sources;
	while true do
		if (FlatIdent_2584C == 1) then
			for _, src in ipairs(sources) do
				if src then
					local val = src:FindFirstChild("Color");
					if (val and (val:IsA("IntValue") or val:IsA("NumberValue"))) then
						colorId = val.Value;
						break;
					end
					local attrVal = src:GetAttribute("Color");
					if (type(attrVal) == "number") then
						colorId = attrVal;
						break;
					end
				end
			end
			if (colorId and COLOR_MAP[colorId]) then
				return COLOR_MAP[colorId].Color, COLOR_MAP[colorId].Name;
			end
			FlatIdent_2584C = 2;
		end
		if (FlatIdent_2584C == 0) then
			colorId = nil;
			sources = {player,player.Character,player:FindFirstChild("PublicStates"),player:FindFirstChild("States")};
			FlatIdent_2584C = 1;
		end
		if (FlatIdent_2584C == 2) then
			return Color3.fromRGB(180, 180, 180), "Stone";
		end
	end
end
local screenGui = Instance.new("ScreenGui");
screenGui.Name = "RoleCheckerUI";
screenGui.ResetOnSpawn = false;
screenGui.DisplayOrder = 999999;
pcall(function()
	screenGui.Parent = CoreGui;
end);
local tooltip = Instance.new("TextLabel");
tooltip.Size = UDim2.new(0, 160, 0, 24);
tooltip.BackgroundColor3 = Color3.fromRGB(15, 15, 15);
tooltip.BorderColor3 = Color3.fromRGB(255, 255, 255);
tooltip.BorderSizePixel = 1;
tooltip.TextColor3 = Color3.fromRGB(255, 255, 255);
tooltip.TextSize = 11;
tooltip.Font = Enum.Font.SourceSansBold;
tooltip.Visible = false;
tooltip.ZIndex = 2000;
tooltip.Parent = screenGui;
local frame = Instance.new("Frame");
frame.Size = UDim2.new(0, 320, 0, 100);
frame.Position = UDim2.new(0, 50, 0.2, 0);
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
frame.BorderSizePixel = 1;
frame.Active = true;
frame.ZIndex = 10;
frame.Parent = screenGui;
local dragBtn = Instance.new("TextButton");
dragBtn.Size = UDim2.new(0, 28, 0, 28);
dragBtn.Position = UDim2.new(0, -38, 0.5, -14);
dragBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40);
dragBtn.BorderColor3 = Color3.fromRGB(255, 255, 255);
dragBtn.BorderSizePixel = 1;
dragBtn.Text = "🕹️";
dragBtn.TextSize = 14;
dragBtn.ZIndex = 20;
dragBtn.Parent = frame;
local dragging = false;
local dragInput, dragStart, startPos;
dragBtn.InputBegan:Connect(function(input)
	if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
		local FlatIdent_2FBEB = 0;
		while true do
			if (FlatIdent_2FBEB == 1) then
				startPos = frame.Position;
				input.Changed:Connect(function()
					if (input.UserInputState == Enum.UserInputState.End) then
						dragging = false;
					end
				end);
				break;
			end
			if (FlatIdent_2FBEB == 0) then
				dragging = true;
				dragStart = input.Position;
				FlatIdent_2FBEB = 1;
			end
		end
	end
end);
dragBtn.InputChanged:Connect(function(input)
	if ((input.UserInputType == Enum.UserInputType.MouseMovement) or (input.UserInputType == Enum.UserInputType.Touch)) then
		dragInput = input;
	end
end);
UserInputService.InputChanged:Connect(function(input)
	if ((input == dragInput) and dragging) then
		local FlatIdent_63487 = 0;
		local delta;
		while true do
			if (FlatIdent_63487 == 0) then
				delta = input.Position - dragStart;
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
				break;
			end
		end
	end
end);
local header = Instance.new("Frame");
header.Size = UDim2.new(1, 0, 0, 26);
header.BackgroundColor3 = Color3.fromRGB(35, 35, 35);
header.BorderSizePixel = 0;
header.ZIndex = 11;
header.Parent = frame;
local title = Instance.new("TextLabel");
title.Size = UDim2.new(1, -125, 1, 0);
title.Position = UDim2.new(0, 8, 0, 0);
title.BackgroundTransparency = 1;
title.Text = "IMPOSTER ROLE CHECKER";
title.TextColor3 = Color3.fromRGB(255, 255, 255);
title.TextSize = 11;
title.Font = Enum.Font.SourceSansBold;
title.TextXAlignment = Enum.TextXAlignment.Left;
title.ZIndex = 12;
title.Parent = header;
local minBtn = Instance.new("TextButton");
minBtn.Size = UDim2.new(0, 22, 0, 22);
minBtn.Position = UDim2.new(1, -24, 0, 2);
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
minBtn.Text = "-";
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
minBtn.TextSize = 14;
minBtn.Font = Enum.Font.SourceSansBold;
minBtn.ZIndex = 12;
minBtn.Parent = header;
local refreshBtn = Instance.new("TextButton");
refreshBtn.Size = UDim2.new(0, 48, 0, 22);
refreshBtn.Position = UDim2.new(1, -74, 0, 2);
refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215);
refreshBtn.Text = "Refresh";
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
refreshBtn.TextSize = 10;
refreshBtn.Font = Enum.Font.SourceSansBold;
refreshBtn.ZIndex = 12;
refreshBtn.Parent = header;
local fbBtn = Instance.new("TextButton");
fbBtn.Size = UDim2.new(0, 26, 0, 22);
fbBtn.Position = UDim2.new(1, -102, 0, 2);
fbBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60);
fbBtn.Text = "💡";
fbBtn.TextSize = 12;
fbBtn.ZIndex = 12;
fbBtn.Parent = header;
local contentFrame = Instance.new("Frame");
contentFrame.Size = UDim2.new(1, 0, 1, -26);
contentFrame.Position = UDim2.new(0, 0, 0, 26);
contentFrame.BackgroundTransparency = 1;
contentFrame.ZIndex = 10;
contentFrame.Parent = frame;
local scroll = Instance.new("ScrollingFrame");
scroll.Size = UDim2.new(1, -8, 1, -34);
scroll.Position = UDim2.new(0, 4, 0, 4);
scroll.BackgroundTransparency = 1;
scroll.CanvasSize = UDim2.new(0, 0, 0, 0);
scroll.ScrollBarThickness = 5;
scroll.ZIndex = 11;
scroll.Parent = contentFrame;
local listLayout = Instance.new("UIListLayout");
listLayout.Parent = scroll;
listLayout.SortOrder = Enum.SortOrder.LayoutOrder;
listLayout.Padding = UDim.new(0, 4);
local infoToggleBtn = Instance.new("TextButton");
infoToggleBtn.Size = UDim2.new(0.48, -2, 0, 22);
infoToggleBtn.Position = UDim2.new(0, 4, 1, -26);
infoToggleBtn.BackgroundColor3 = Color3.fromRGB(210, 170, 20);
infoToggleBtn.Text = "❓ Instructions";
infoToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0);
infoToggleBtn.TextSize = 10;
infoToggleBtn.Font = Enum.Font.SourceSansBold;
infoToggleBtn.ZIndex = 12;
infoToggleBtn.Parent = contentFrame;
local clearBtn = Instance.new("TextButton");
clearBtn.Size = UDim2.new(0.48, -2, 0, 22);
clearBtn.Position = UDim2.new(0.52, 0, 1, -26);
clearBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40);
clearBtn.Text = "Clear History 🗑";
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
clearBtn.TextSize = 10;
clearBtn.Font = Enum.Font.SourceSansBold;
clearBtn.ZIndex = 12;
clearBtn.Parent = contentFrame;
local modalOverlay = Instance.new("TextButton");
modalOverlay.Size = UDim2.new(1, 0, 1, 0);
modalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
modalOverlay.BackgroundTransparency = 0.5;
modalOverlay.Text = "";
modalOverlay.Visible = false;
modalOverlay.ZIndex = 500;
modalOverlay.Parent = screenGui;
local modalFrame = Instance.new("Frame");
modalFrame.Size = UDim2.new(0, 320, 0, 230);
modalFrame.Position = UDim2.new(0.5, -160, 0.5, -115);
modalFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25);
modalFrame.BorderSizePixel = 2;
modalFrame.BorderColor3 = Color3.fromRGB(255, 215, 0);
modalFrame.ZIndex = 501;
modalFrame.Parent = modalOverlay;
local modalTitle = Instance.new("TextLabel");
modalTitle.Size = UDim2.new(1, 0, 0, 30);
modalTitle.BackgroundColor3 = Color3.fromRGB(35, 35, 35);
modalTitle.Text = "📌 INSTRUCTIONS & NOTICES";
modalTitle.TextColor3 = Color3.fromRGB(255, 215, 0);
modalTitle.TextSize = 12;
modalTitle.Font = Enum.Font.SourceSansBold;
modalTitle.ZIndex = 502;
modalTitle.Parent = modalFrame;
local modalText = Instance.new("TextLabel");
modalText.Size = UDim2.new(1, -20, 1, -40);
modalText.Position = UDim2.new(0, 10, 0, 35);
modalText.BackgroundTransparency = 1;
modalText.TextColor3 = Color3.fromRGB(240, 240, 240);
modalText.TextSize = 11;
modalText.Font = Enum.Font.SourceSans;
modalText.TextWrapped = true;
modalText.TextXAlignment = Enum.TextXAlignment.Left;
modalText.TextYAlignment = Enum.TextYAlignment.Top;
modalText.ZIndex = 502;
modalText.Text = "⚠️ MANDATORY REQUIREMENT:\n• Click 'Clear History 🗑' at the start of every new round or if false detection occurs!\n• The conclusion isn't always correct\n• This script uses a transformation mechanism that activates when a player performs a kill or enters a vent so that you need to wait.\n\n🎨 COLOR CODES:\n• Red: Killer / Impostor | Cyan: Vent / Teleport\n• Orange: Suspect | Gray: Dead 💀\n• Press & Hold color square to inspect color name.\n\n✨ Credit: ToanCreator\n💡 Click anywhere outside to close.";
modalText.Parent = modalFrame;
infoToggleBtn.MouseButton1Click:Connect(function()
	modalOverlay.Visible = true;
end);
modalOverlay.MouseButton1Click:Connect(function()
	modalOverlay.Visible = false;
end);
local origBrightness = Lighting.Brightness;
local origClockTime = Lighting.ClockTime;
local origFogEnd = Lighting.FogEnd;
local origGlobalShadows = Lighting.GlobalShadows;
local origAmbient = Lighting.Ambient;
fbBtn.MouseButton1Click:Connect(function()
	local FlatIdent_44839 = 0;
	while true do
		if (FlatIdent_44839 == 0) then
			FullbrightEnabled = not FullbrightEnabled;
			if FullbrightEnabled then
				fbBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80);
			else
				local FlatIdent_25011 = 0;
				while true do
					if (FlatIdent_25011 == 2) then
						Lighting.GlobalShadows = origGlobalShadows;
						Lighting.Ambient = origAmbient;
						break;
					end
					if (FlatIdent_25011 == 1) then
						Lighting.ClockTime = origClockTime;
						Lighting.FogEnd = origFogEnd;
						FlatIdent_25011 = 2;
					end
					if (FlatIdent_25011 == 0) then
						fbBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60);
						Lighting.Brightness = origBrightness;
						FlatIdent_25011 = 1;
					end
				end
			end
			break;
		end
	end
end);
RunService.RenderStepped:Connect(function()
	if FullbrightEnabled then
		local FlatIdent_61585 = 0;
		while true do
			if (FlatIdent_61585 == 2) then
				Lighting.Ambient = Color3.fromRGB(255, 255, 255);
				break;
			end
			if (1 == FlatIdent_61585) then
				Lighting.FogEnd = 100000;
				Lighting.GlobalShadows = false;
				FlatIdent_61585 = 2;
			end
			if (0 == FlatIdent_61585) then
				Lighting.Brightness = 2;
				Lighting.ClockTime = 14;
				FlatIdent_61585 = 1;
			end
		end
	end
end);
local resizeBtn = Instance.new("TextButton");
resizeBtn.Size = UDim2.new(0, 16, 0, 16);
resizeBtn.Position = UDim2.new(1, -16, 1, -16);
resizeBtn.BackgroundTransparency = 1;
resizeBtn.Text = "◢";
resizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200);
resizeBtn.TextSize = 12;
resizeBtn.ZIndex = 15;
resizeBtn.Parent = frame;
local resizing = false;
local startPosResize, startSize;
resizeBtn.InputBegan:Connect(function(input)
	if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
		resizing = true;
		startPosResize = input.Position;
		startSize = frame.Size;
	end
end);
UserInputService.InputChanged:Connect(function(input)
	if (resizing and ((input.UserInputType == Enum.UserInputType.MouseMovement) or (input.UserInputType == Enum.UserInputType.Touch))) then
		local FlatIdent_E652 = 0;
		local delta;
		while true do
			if (0 == FlatIdent_E652) then
				delta = input.Position - startPosResize;
				frame.Size = UDim2.new(0, math.max(260, startSize.X.Offset + delta.X), 0, math.max(120, startSize.Y.Offset + delta.Y));
				break;
			end
		end
	end
end);
local function stopResizing(input)
	if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
		resizing = false;
	end
end
resizeBtn.InputEnded:Connect(stopResizing);
UserInputService.InputEnded:Connect(stopResizing);
local specGui = Instance.new("Frame");
specGui.Size = UDim2.new(0, 260, 0, 28);
specGui.Position = UDim2.new(0.5, -130, 1, -60);
specGui.BackgroundColor3 = Color3.fromRGB(25, 25, 25);
specGui.BorderSizePixel = 1;
specGui.Visible = false;
specGui.ZIndex = 100;
specGui.Parent = screenGui;
local prevSpecBtn = Instance.new("TextButton");
prevSpecBtn.Size = UDim2.new(0, 26, 0, 22);
prevSpecBtn.Position = UDim2.new(0, 3, 0, 3);
prevSpecBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
prevSpecBtn.Text = "<";
prevSpecBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
prevSpecBtn.TextSize = 12;
prevSpecBtn.Font = Enum.Font.SourceSansBold;
prevSpecBtn.ZIndex = 101;
prevSpecBtn.Parent = specGui;
local nextSpecBtn = Instance.new("TextButton");
nextSpecBtn.Size = UDim2.new(0, 26, 0, 22);
nextSpecBtn.Position = UDim2.new(1, -56, 0, 3);
nextSpecBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
nextSpecBtn.Text = ">";
nextSpecBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
nextSpecBtn.TextSize = 12;
nextSpecBtn.Font = Enum.Font.SourceSansBold;
nextSpecBtn.ZIndex = 101;
nextSpecBtn.Parent = specGui;
local specNameBtn = Instance.new("TextButton");
specNameBtn.Size = UDim2.new(1, -88, 1, 0);
specNameBtn.Position = UDim2.new(0, 32, 0, 0);
specNameBtn.BackgroundTransparency = 1;
specNameBtn.Text = "Player";
specNameBtn.TextColor3 = Color3.fromRGB(0, 255, 255);
specNameBtn.TextSize = 11;
specNameBtn.Font = Enum.Font.SourceSansBold;
specNameBtn.ZIndex = 101;
specNameBtn.Parent = specGui;
local stopSpecBtn = Instance.new("TextButton");
stopSpecBtn.Size = UDim2.new(0, 24, 0, 22);
stopSpecBtn.Position = UDim2.new(1, -27, 0, 3);
stopSpecBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40);
stopSpecBtn.Text = "X";
stopSpecBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
stopSpecBtn.TextSize = 11;
stopSpecBtn.Font = Enum.Font.SourceSansBold;
stopSpecBtn.ZIndex = 101;
stopSpecBtn.Parent = specGui;
local isMinimized = false;
local originalHeight = 220;
minBtn.MouseButton1Click:Connect(function()
	local FlatIdent_27957 = 0;
	while true do
		if (0 == FlatIdent_27957) then
			isMinimized = not isMinimized;
			if isMinimized then
				local FlatIdent_77C29 = 0;
				while true do
					if (FlatIdent_77C29 == 2) then
						minBtn.Text = "∨";
						break;
					end
					if (FlatIdent_77C29 == 1) then
						resizeBtn.Visible = false;
						frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 26);
						FlatIdent_77C29 = 2;
					end
					if (FlatIdent_77C29 == 0) then
						originalHeight = frame.Size.Y.Offset;
						contentFrame.Visible = false;
						FlatIdent_77C29 = 1;
					end
				end
			else
				local FlatIdent_8CEDF = 0;
				while true do
					if (FlatIdent_8CEDF == 1) then
						frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, originalHeight);
						minBtn.Text = "-";
						break;
					end
					if (FlatIdent_8CEDF == 0) then
						contentFrame.Visible = true;
						resizeBtn.Visible = true;
						FlatIdent_8CEDF = 1;
					end
				end
			end
			break;
		end
	end
end);
local function stopSpectate()
	local FlatIdent_1B1BA = 0;
	while true do
		if (FlatIdent_1B1BA == 0) then
			SpectatingPlayer = nil;
			specGui.Visible = false;
			FlatIdent_1B1BA = 1;
		end
		if (FlatIdent_1B1BA == 1) then
			if (Camera and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")) then
				Camera.CameraSubject = LocalPlayer.Character.Humanoid;
			end
			break;
		end
	end
end
local function startSpectate(targetPlayer)
	if (targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid")) then
		local FlatIdent_8DCA9 = 0;
		local pColor;
		local _;
		while true do
			if (FlatIdent_8DCA9 == 0) then
				SpectatingPlayer = targetPlayer;
				Camera.CameraSubject = targetPlayer.Character.Humanoid;
				FlatIdent_8DCA9 = 1;
			end
			if (FlatIdent_8DCA9 == 2) then
				specNameBtn.Text = "👁️ " .. targetPlayer.Name .. " (TP)";
				specGui.Visible = true;
				break;
			end
			if (FlatIdent_8DCA9 == 1) then
				pColor, _ = GetPlayerColorData(targetPlayer);
				specNameBtn.TextColor3 = pColor;
				FlatIdent_8DCA9 = 2;
			end
		end
	end
end
local function cycleSpectate(direction)
	local FlatIdent_324DE = 0;
	local playerList;
	local currentIndex;
	local nextIndex;
	while true do
		if (FlatIdent_324DE == 2) then
			nextIndex = currentIndex + direction;
			if (nextIndex > #playerList) then
				nextIndex = 1;
			end
			FlatIdent_324DE = 3;
		end
		if (FlatIdent_324DE == 1) then
			currentIndex = 1;
			for idx, p in ipairs(playerList) do
				if (p == SpectatingPlayer) then
					currentIndex = idx;
					break;
				end
			end
			FlatIdent_324DE = 2;
		end
		if (0 == FlatIdent_324DE) then
			playerList = Players:GetPlayers();
			if (#playerList <= 1) then
				return;
			end
			FlatIdent_324DE = 1;
		end
		if (FlatIdent_324DE == 3) then
			if (nextIndex < 1) then
				nextIndex = #playerList;
			end
			startSpectate(playerList[nextIndex]);
			break;
		end
	end
end
prevSpecBtn.MouseButton1Click:Connect(function()
	cycleSpectate(-1);
end);
nextSpecBtn.MouseButton1Click:Connect(function()
	cycleSpectate(1);
end);
specNameBtn.MouseButton1Click:Connect(function()
	local FlatIdent_2D88C = 0;
	while true do
		if (FlatIdent_2D88C == 0) then
			if (SpectatingPlayer and SpectatingPlayer.Character and SpectatingPlayer.Character:FindFirstChild("HumanoidRootPart")) then
				if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
					LocalPlayer.Character.HumanoidRootPart.CFrame = SpectatingPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0);
				end
			end
			stopSpectate();
			break;
		end
	end
end);
stopSpecBtn.MouseButton1Click:Connect(stopSpectate);
local function IsPlayerDead(player)
	if (not player or not player.Character) then
		return true;
	end
	local hum = player.Character:FindFirstChildOfClass("Humanoid");
	if (not hum or (hum.Health <= 0)) then
		return true;
	end
	local publicStates = player:FindFirstChild("PublicStates");
	if publicStates then
		local FlatIdent_D79D = 0;
		local aliveVal;
		while true do
			if (0 == FlatIdent_D79D) then
				aliveVal = publicStates:FindFirstChild("Alive");
				if (aliveVal and aliveVal:IsA("BoolValue") and (aliveVal.Value == false)) then
					return true;
				end
				break;
			end
		end
	end
	if (player.Character.Name:lower():find("dead") or player.Character.Name:lower():find("ghost")) then
		return true;
	end
	return false;
end
local function GetLine(p)
	local FlatIdent_14716 = 0;
	while true do
		if (0 == FlatIdent_14716) then
			if not TraceLines[p] then
				local FlatIdent_40B41 = 0;
				local line;
				while true do
					if (1 == FlatIdent_40B41) then
						line.Transparency = 1;
						TraceLines[p] = line;
						break;
					end
					if (FlatIdent_40B41 == 0) then
						line = Drawing.new("Line");
						line.Thickness = 1.5;
						FlatIdent_40B41 = 1;
					end
				end
			end
			return TraceLines[p];
		end
	end
end
local function GetPlayerESPColor(p)
	local FlatIdent_8A742 = 0;
	local roleData;
	while true do
		if (0 == FlatIdent_8A742) then
			if IsPlayerDead(p) then
				return ESP_COLORS.GRAY;
			end
			roleData = DetectedRoles[p.Name];
			FlatIdent_8A742 = 1;
		end
		if (FlatIdent_8A742 == 1) then
			if roleData then
				local role = roleData.Role;
				if (string.find(role, "IMPOSTOR") or string.find(role, "Killer")) then
					return ESP_COLORS.RED;
				elseif (string.find(role, "VENT") or string.find(role, "TELEPORT")) then
					return ESP_COLORS.CYAN;
				elseif string.find(role, "SUSPECT") then
					return ESP_COLORS.ORANGE;
				end
			end
			return ESP_COLORS.WHITE;
		end
	end
end
RunService.RenderStepped:Connect(function()
	for _, p in ipairs(Players:GetPlayers()) do
		if ((p ~= LocalPlayer) and p.Character) then
			local targetRoot = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Head");
			if targetRoot then
				local displayColor = GetPlayerESPColor(p);
				local espTag = targetRoot:FindFirstChild("ToanESP");
				if not espTag then
					local FlatIdent_206F8 = 0;
					local bill;
					local lbl;
					while true do
						if (FlatIdent_206F8 == 1) then
							bill.AlwaysOnTop = true;
							bill.Adornee = targetRoot;
							lbl = Instance.new("TextLabel");
							lbl.Name = "Txt";
							FlatIdent_206F8 = 2;
						end
						if (FlatIdent_206F8 == 2) then
							lbl.Size = UDim2.new(1, 0, 1, 0);
							lbl.BackgroundTransparency = 1;
							lbl.TextSize = 11;
							lbl.Font = Enum.Font.SourceSansBold;
							FlatIdent_206F8 = 3;
						end
						if (FlatIdent_206F8 == 3) then
							lbl.Parent = bill;
							bill.Parent = targetRoot;
							break;
						end
						if (FlatIdent_206F8 == 0) then
							bill = Instance.new("BillboardGui");
							bill.Name = "ToanESP";
							bill.Size = UDim2.new(0, 120, 0, 20);
							bill.StudsOffset = Vector3.new(0, 3, 0);
							FlatIdent_206F8 = 1;
						end
					end
				end
				targetRoot.ToanESP.Txt.TextColor3 = displayColor;
				targetRoot.ToanESP.Txt.Text = p.Name;
				local hb = targetRoot:FindFirstChild("ToanHitboxAdorn");
				if not IsPlayerDead(p) then
					local FlatIdent_75224 = 0;
					while true do
						if (FlatIdent_75224 == 0) then
							if not hb then
								hb = Instance.new("BoxHandleAdornment");
								hb.Name = "ToanHitboxAdorn";
								hb.Size = Vector3.new(4, 5, 4);
								hb.AlwaysOnTop = true;
								hb.ZIndex = 10;
								hb.Transparency = 0.5;
								hb.Adornee = targetRoot;
								hb.Parent = targetRoot;
							end
							hb.Color3 = displayColor;
							break;
						end
					end
				elseif hb then
					hb:Destroy();
				end
				local line = GetLine(p);
				local screenPos, onScreen = Camera:WorldToViewportPoint(targetRoot.Position);
				if onScreen then
					local FlatIdent_22216 = 0;
					while true do
						if (0 == FlatIdent_22216) then
							line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y);
							line.To = Vector2.new(screenPos.X, screenPos.Y);
							FlatIdent_22216 = 1;
						end
						if (FlatIdent_22216 == 1) then
							line.Color = displayColor;
							line.Visible = true;
							break;
						end
					end
				else
					line.Visible = false;
				end
			end
		elseif TraceLines[p] then
			TraceLines[p].Visible = false;
		end
	end
end);
Players.PlayerRemoving:Connect(function(player)
	if TraceLines[player] then
		local FlatIdent_7C57C = 0;
		while true do
			if (FlatIdent_7C57C == 0) then
				pcall(function()
					TraceLines[player]:Remove();
				end);
				TraceLines[player] = nil;
				break;
			end
		end
	end
end);
local function resetGameData()
	local FlatIdent_23B66 = 0;
	while true do
		if (FlatIdent_23B66 == 1) then
			table.clear(LastPositions);
			stopSpectate();
			break;
		end
		if (FlatIdent_23B66 == 0) then
			table.clear(DetectedRoles);
			table.clear(IsAliveCache);
			FlatIdent_23B66 = 1;
		end
	end
end
local function isMeetingActive()
	local FlatIdent_30B1F = 0;
	local rep;
	local meetingVal;
	while true do
		if (1 == FlatIdent_30B1F) then
			return meetingVal and meetingVal:IsA("BoolValue") and meetingVal.Value;
		end
		if (FlatIdent_30B1F == 0) then
			rep = game:GetService("ReplicatedStorage");
			meetingVal = rep:FindFirstChild("InMeeting") or rep:FindFirstChild("MeetingActive") or workspace:FindFirstChild("InMeeting");
			FlatIdent_30B1F = 1;
		end
	end
end
local function getPlayerRoleData(player)
	if IsPlayerDead(player) then
		return "DEAD 💀", "Deceased";
	end
	if DetectedRoles[player.Name] then
		return DetectedRoles[player.Name].Role, DetectedRoles[player.Name].SubRole;
	end
	local mainRole = "Crewmate";
	local subRole = "Innocent";
	local containers = {player,player:FindFirstChild("States"),player:FindFirstChild("PublicStates")};
	for _, c in ipairs(containers) do
		if c then
			local FlatIdent_23521 = 0;
			local r;
			local sr;
			while true do
				if (1 == FlatIdent_23521) then
					sr = c:FindFirstChild("SubRole");
					if (sr and sr:IsA("StringValue") and (sr.Value ~= "")) then
						subRole = sr.Value;
					end
					break;
				end
				if (FlatIdent_23521 == 0) then
					r = c:FindFirstChild("Role");
					if (r and r:IsA("StringValue") and (r.Value ~= "")) then
						mainRole = r.Value;
					end
					FlatIdent_23521 = 1;
				end
			end
		end
	end
	return mainRole, subRole;
end
local function updateUI()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy();
		end
	end
	local totalY = 0;
	local allPlayers = Players:GetPlayers();
	for _, player in ipairs(allPlayers) do
		local mainRole, subRole = getPlayerRoleData(player);
		local formattedText = string.format("%s: [%s] - %s", player.Name, mainRole, subRole);
		local baseWidth = math.max(180, frame.Size.X.Offset - 60);
		local lineCount = math.ceil(#formattedText / (baseWidth / 6));
		local itemHeight = math.max(26, (lineCount * 14) + 8);
		local itemFrame = Instance.new("Frame");
		itemFrame.Size = UDim2.new(1, -6, 0, itemHeight);
		itemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30);
		itemFrame.BorderSizePixel = 0;
		itemFrame.ZIndex = 12;
		itemFrame.Parent = scroll;
		local eyeBtn = Instance.new("TextButton");
		eyeBtn.Size = UDim2.new(0, 20, 0, 20);
		eyeBtn.Position = UDim2.new(0, 2, 0, 3);
		eyeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45);
		eyeBtn.Text = "👁️";
		eyeBtn.TextSize = 10;
		eyeBtn.ZIndex = 13;
		eyeBtn.Parent = itemFrame;
		eyeBtn.MouseButton1Click:Connect(function()
			startSpectate(player);
		end);
		local colorSquare = Instance.new("Frame");
		colorSquare.Size = UDim2.new(0, 20, 0, 20);
		colorSquare.Position = UDim2.new(0, 24, 0, 3);
		colorSquare.BorderSizePixel = 1;
		colorSquare.BorderColor3 = Color3.fromRGB(0, 0, 0);
		colorSquare.ZIndex = 13;
		colorSquare.Parent = itemFrame;
		local function bindColorSquareHold(btn, targetPlayer)
			local FlatIdent_272FB = 0;
			local holding;
			while true do
				if (FlatIdent_272FB == 0) then
					holding = false;
					btn.InputBegan:Connect(function(input)
						if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
							local FlatIdent_628E3 = 0;
							while true do
								if (FlatIdent_628E3 == 0) then
									holding = true;
									task.delay(0.2, function()
										if holding then
											local FlatIdent_2E34E = 0;
											local _;
											local colorName;
											while true do
												if (FlatIdent_2E34E == 0) then
													_, colorName = GetPlayerColorData(targetPlayer);
													tooltip.Text = "Color: " .. colorName;
													FlatIdent_2E34E = 1;
												end
												if (FlatIdent_2E34E == 1) then
													tooltip.Position = UDim2.new(0, input.Position.X + 10, 0, input.Position.Y - 25);
													tooltip.Visible = true;
													break;
												end
											end
										end
									end);
									break;
								end
							end
						end
					end);
					FlatIdent_272FB = 1;
				end
				if (1 == FlatIdent_272FB) then
					btn.InputEnded:Connect(function(input)
						if ((input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch)) then
							local FlatIdent_4223E = 0;
							while true do
								if (FlatIdent_4223E == 0) then
									holding = false;
									tooltip.Visible = false;
									break;
								end
							end
						end
					end);
					break;
				end
			end
		end
		bindColorSquareHold(colorSquare, player);
		RunService.Heartbeat:Connect(function()
			if (colorSquare and colorSquare.Parent) then
				local FlatIdent_15354 = 0;
				local c3;
				local _;
				while true do
					if (FlatIdent_15354 == 0) then
						c3, _ = GetPlayerColorData(player);
						colorSquare.BackgroundColor3 = c3;
						break;
					end
				end
			end
		end);
		local txt = Instance.new("TextLabel");
		txt.Size = UDim2.new(1, -50, 1, 0);
		txt.Position = UDim2.new(0, 48, 0, 0);
		txt.BackgroundTransparency = 1;
		txt.TextXAlignment = Enum.TextXAlignment.Left;
		txt.TextYAlignment = Enum.TextYAlignment.Center;
		txt.TextSize = 11;
		txt.Font = Enum.Font.SourceSans;
		txt.TextWrapped = true;
		txt.ClipsDescendants = true;
		txt.ZIndex = 13;
		if IsPlayerDead(player) then
			txt.TextColor3 = ESP_COLORS.GRAY;
		elseif (string.find(mainRole, "VENT") or string.find(mainRole, "TELEPORT")) then
			txt.TextColor3 = ESP_COLORS.CYAN;
		elseif (string.find(mainRole, "IMPOSTOR") or string.find(mainRole, "Killer")) then
			txt.TextColor3 = ESP_COLORS.RED;
		elseif string.find(mainRole, "SUSPECT") then
			txt.TextColor3 = ESP_COLORS.ORANGE;
		else
			txt.TextColor3 = Color3.fromRGB(120, 255, 120);
		end
		txt.Text = formattedText;
		txt.Parent = itemFrame;
		totalY = totalY + itemHeight + 4;
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, totalY);
	if not isMinimized then
		local FlatIdent_1B5ED = 0;
		local targetContentHeight;
		while true do
			if (FlatIdent_1B5ED == 0) then
				targetContentHeight = math.clamp(totalY + 40, 70, 380);
				frame.Size = UDim2.new(0, frame.Size.X.Offset, 0, targetContentHeight + 26);
				FlatIdent_1B5ED = 1;
			end
			if (FlatIdent_1B5ED == 1) then
				originalHeight = frame.Size.Y.Offset;
				break;
			end
		end
	end
end
task.spawn(function()
	while task.wait(0.2) do
		if not isMeetingActive() then
			for _, p in ipairs(Players:GetPlayers()) do
				if (p.Character and p.Character:FindFirstChild("HumanoidRootPart")) then
					local FlatIdent_6AEED = 0;
					local currentPos;
					local deadStatus;
					while true do
						if (FlatIdent_6AEED == 0) then
							currentPos = p.Character.HumanoidRootPart.Position;
							deadStatus = IsPlayerDead(p);
							FlatIdent_6AEED = 1;
						end
						if (FlatIdent_6AEED == 1) then
							if (IsAliveCache[p.Name] == nil) then
								IsAliveCache[p.Name] = deadStatus;
								LastPositions[p.Name] = currentPos;
							else
								local FlatIdent_44265 = 0;
								while true do
									if (FlatIdent_44265 == 1) then
										if ((IsAliveCache[p.Name] == false) and (deadStatus == true)) then
											local FlatIdent_44603 = 0;
											local victimPos;
											local teleportDistance;
											while true do
												if (FlatIdent_44603 == 0) then
													victimPos = currentPos;
													teleportDistance = (victimPos - (LastPositions[p.Name] or victimPos)).Magnitude;
													FlatIdent_44603 = 1;
												end
												if (FlatIdent_44603 == 1) then
													if (teleportDistance < 150) then
														local closestSuspect = nil;
														local minDistance = math.huge;
														for _, suspect in ipairs(Players:GetPlayers()) do
															if ((suspect ~= p) and not IsPlayerDead(suspect) and suspect.Character and suspect.Character:FindFirstChild("HumanoidRootPart")) then
																local FlatIdent_5013F = 0;
																local dist;
																while true do
																	if (0 == FlatIdent_5013F) then
																		dist = (victimPos - suspect.Character.HumanoidRootPart.Position).Magnitude;
																		if (dist < minDistance) then
																			local FlatIdent_19FC0 = 0;
																			while true do
																				if (0 == FlatIdent_19FC0) then
																					minDistance = dist;
																					closestSuspect = suspect;
																					break;
																				end
																			end
																		end
																		break;
																	end
																end
															end
														end
														if (closestSuspect and (minDistance > 1.5)) then
															if (minDistance <= 12) then
																local FlatIdent_5D802 = 0;
																while true do
																	if (FlatIdent_5D802 == 0) then
																		DetectedRoles[closestSuspect.Name] = {Role="IMPOSTOR 🔪",SubRole=("Killed " .. p.Name .. " (" .. math.floor(minDistance) .. "m)")};
																		updateUI();
																		break;
																	end
																end
															elseif ((minDistance > 12) and (minDistance <= 50)) then
																local FlatIdent_5962D = 0;
																while true do
																	if (0 == FlatIdent_5962D) then
																		DetectedRoles[closestSuspect.Name] = {Role="SUSPECT 🎯",SubRole=("Suspected kill on " .. p.Name .. " (" .. math.floor(minDistance) .. "m)")};
																		updateUI();
																		break;
																	end
																end
															end
														end
													end
													break;
												end
											end
										end
										IsAliveCache[p.Name] = deadStatus;
										break;
									end
									if (0 == FlatIdent_44265) then
										if (not deadStatus and LastPositions[p.Name]) then
											local FlatIdent_53124 = 0;
											local moveDist;
											while true do
												if (FlatIdent_53124 == 0) then
													moveDist = (currentPos - LastPositions[p.Name]).Magnitude;
													if ((moveDist >= 35) and (moveDist <= 350)) then
														DetectedRoles[p.Name] = {Role="VENT / TELEPORT 🌀",SubRole=("Teleported " .. math.floor(moveDist) .. "m")};
														updateUI();
													end
													break;
												end
											end
										end
										LastPositions[p.Name] = currentPos;
										FlatIdent_44265 = 1;
									end
								end
							end
							break;
						end
					end
				end
			end
		end
	end
end);
clearBtn.MouseButton1Click:Connect(function()
	local FlatIdent_2593F = 0;
	while true do
		if (FlatIdent_2593F == 0) then
			resetGameData();
			updateUI();
			break;
		end
	end
end);
refreshBtn.MouseButton1Click:Connect(updateUI);
Players.PlayerAdded:Connect(updateUI);
Players.PlayerRemoving:Connect(updateUI);
if LocalPlayer then
	LocalPlayer.CharacterAdded:Connect(function()
		local FlatIdent_3B08E = 0;
		while true do
			if (FlatIdent_3B08E == 0) then
				resetGameData();
				updateUI();
				break;
			end
		end
	end);
end
updateUI();