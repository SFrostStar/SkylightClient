local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    TweenService = game:GetService("TweenService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    HttpService = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

local Settings = {
    Aura = false,
    AuraRange = 25,
    AuraTarget = nil,
    TeamCheck = false,
    AimLock = false,
    AimLockActive = false,
    AimLockTarget = nil,
    AimLockRange = 200,
    Speed = false,
    SpeedMultiplier = 2.5,
    VClipDistance = 10,
    Velocity = false,
    ClickTP = false,
    Tracers = false,
    TracerColor = Color3.fromRGB(108, 92, 231),
    ESP = false,
    ESPFill = Color3.fromRGB(108, 92, 231),
    ESPOutline = Color3.fromRGB(255, 255, 255),
    ESPFillTrans = 0.5,
    Box3D = false,
    BoxColor = Color3.fromRGB(0, 255, 170),
    AimLockFOV = false,
    AimLockFOVRadius = 150,
    TargetESP = false,
    PurpleAmbiance = false,
    CustomFog = false,
    FogDensity = 250,
    PurpleSky = false,
    InfJump = false,
    FOV = 70,
    ToggleKey = Enum.KeyCode.RightShift,
    ShowHotkeysHUD = true,
    ShowTargetHUD = true,
    AccentColor = Color3.fromRGB(108, 92, 231)
}

local DefaultLighting = {
    Ambient = Services.Lighting.Ambient,
    OutdoorAmbient = Services.Lighting.OutdoorAmbient,
    FogColor = Services.Lighting.FogColor,
    FogStart = Services.Lighting.FogStart,
    FogEnd = Services.Lighting.FogEnd,
    ClockTime = Services.Lighting.ClockTime
}

local ColorCorrection = nil
local CustomSkyObj = nil

local function UpdateAmbiance()
    if Settings.PurpleAmbiance then
        if not ColorCorrection then
            ColorCorrection = Instance.new("ColorCorrectionEffect")
            ColorCorrection.Name = "MineBat_Ambiance"
            ColorCorrection.Parent = Services.Lighting
        end
        ColorCorrection.Enabled = true
        ColorCorrection.TintColor = Color3.fromRGB(185, 140, 255)
        ColorCorrection.Contrast = 0.15
        ColorCorrection.Saturation = 0.25
        Services.Lighting.Ambient = Color3.fromRGB(110, 80, 220)
        Services.Lighting.OutdoorAmbient = Color3.fromRGB(140, 100, 255)
    else
        if ColorCorrection then
            ColorCorrection.Enabled = false
        end
        Services.Lighting.Ambient = DefaultLighting.Ambient
        Services.Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
    end
end

local function UpdateFog()
    if Settings.CustomFog then
        Services.Lighting.FogColor = Color3.fromRGB(120, 85, 230)
        Services.Lighting.FogStart = 0
        Services.Lighting.FogEnd = Settings.FogDensity
    else
        Services.Lighting.FogColor = DefaultLighting.FogColor
        Services.Lighting.FogStart = DefaultLighting.FogStart
        Services.Lighting.FogEnd = DefaultLighting.FogEnd
    end
end

local function UpdateSky()
    if Settings.PurpleSky then
        if not CustomSkyObj then
            CustomSkyObj = Instance.new("Sky")
            CustomSkyObj.Name = "MineBat_Sky"
            CustomSkyObj.SkyboxBk = "rbxassetid://159454299"
            CustomSkyObj.SkyboxDn = "rbxassetid://159454296"
            CustomSkyObj.SkyboxFt = "rbxassetid://159454293"
            CustomSkyObj.SkyboxLf = "rbxassetid://159454298"
            CustomSkyObj.SkyboxRt = "rbxassetid://159454300"
            CustomSkyObj.SkyboxUp = "rbxassetid://159454288"
        end
        CustomSkyObj.Parent = Services.Lighting
        Services.Lighting.ClockTime = 0
    else
        if CustomSkyObj then
            CustomSkyObj.Parent = nil
        end
        Services.Lighting.ClockTime = DefaultLighting.ClockTime
    end
end

local Binds = {}

local Connections = {}
local Highlights = {}
local TracerDrawings = {}
local BoxDrawings = {}
local FOVCircleDrawing = nil
local TargetESPDrawings = {}
local TargetESPCircle = nil

local function GetInputName(input)
    if not input then return "NONE" end
    if typeof(input) == "EnumItem" then
        if input.EnumType == Enum.KeyCode then
            if input == Enum.KeyCode.LeftShift then return "LShift" end
            if input == Enum.KeyCode.RightShift then return "RShift" end
            if input == Enum.KeyCode.LeftControl then return "LCtrl" end
            if input == Enum.KeyCode.RightControl then return "RCtrl" end
            return input.Name
        elseif input.EnumType == Enum.UserInputType then
            if input == Enum.UserInputType.MouseButton2 then return "ПКМ" end
            if input == Enum.UserInputType.MouseButton1 then return "ЛКМ" end
            if input == Enum.UserInputType.MouseButton3 then return "СКМ" end
            return input.Name
        end
    end
    return "NONE"
end

local function CheckInputMatch(bindKey, input)
    if not bindKey or not input then return false end
    if bindKey == input.KeyCode then return true end
    if bindKey == input.UserInputType then return true end
    return false
end

local function CleanupVisuals()
    for player, hl in pairs(Highlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table.clear(Highlights)

    for player, line in pairs(TracerDrawings) do
        if line then pcall(function() line:Remove() end) end
    end
    table.clear(TracerDrawings)

    for player, lines in pairs(BoxDrawings) do
        for _, l in ipairs(lines) do
            if l then pcall(function() l:Remove() end) end
        end
    end
    table.clear(BoxDrawings)

    if FOVCircleDrawing then
        pcall(function() FOVCircleDrawing:Remove() end)
        FOVCircleDrawing = nil
    end

    for _, line in ipairs(TargetESPDrawings) do
        if line then pcall(function() line:Remove() end) end
    end
    table.clear(TargetESPDrawings)

    if TargetESPCircle then
        pcall(function() TargetESPCircle:Remove() end)
        TargetESPCircle = nil
    end

    if ColorCorrection then
        pcall(function() ColorCorrection:Destroy() end)
        ColorCorrection = nil
    end

    if CustomSkyObj then
        pcall(function() CustomSkyObj:Destroy() end)
        CustomSkyObj = nil
    end

    pcall(function()
        Services.Lighting.Ambient = DefaultLighting.Ambient
        Services.Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
        Services.Lighting.FogColor = DefaultLighting.FogColor
        Services.Lighting.FogStart = DefaultLighting.FogStart
        Services.Lighting.FogEnd = DefaultLighting.FogEnd
        Services.Lighting.ClockTime = DefaultLighting.ClockTime
    end)
end

local function IsAlive(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild("HumanoidRootPart")
end

local function GetTargetTorso(character)
    if not character then return nil end
    return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MineBatCSGUI_" .. math.random(10000, 99999)
ScreenGui.ResetOnSpawn = false

pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    elseif Services.CoreGui:FindFirstChild("RobloxGui") then
        ScreenGui.Parent = Services.CoreGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)

local Watermark = Instance.new("Frame")
Watermark.Name = "SkylightWatermark"
Watermark.AutomaticSize = Enum.AutomaticSize.X
Watermark.Size = UDim2.new(0, 0, 0, 28)
Watermark.Position = UDim2.new(0, 15, 0, 15)
Watermark.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
Watermark.BorderSizePixel = 0
Watermark.ClipsDescendants = true
Watermark.Parent = ScreenGui

local WPadding = Instance.new("UIPadding")
WPadding.PaddingLeft = UDim.new(0, 12)
WPadding.PaddingRight = UDim.new(0, 12)
WPadding.Parent = Watermark

local WCorner = Instance.new("UICorner")
WCorner.CornerRadius = UDim.new(0, 6)
WCorner.Parent = Watermark

local WStroke = Instance.new("UIStroke")
WStroke.Color = Settings.AccentColor
WStroke.Thickness = 1.2
WStroke.Transparency = 0.4
WStroke.Parent = Watermark

local WText = Instance.new("TextLabel")
WText.AutomaticSize = Enum.AutomaticSize.X
WText.Size = UDim2.new(0, 0, 1, 0)
WText.BackgroundTransparency = 1
WText.Text = "<font color=\"#6C5CE7\"><b>Skylight Client</b></font>  |  By A1wertykss  |  Discord: xsynapse  |  v3.0"
WText.RichText = true
WText.TextColor3 = Color3.fromRGB(240, 240, 245)
WText.Font = Enum.Font.GothamBold
WText.TextSize = 12
WText.TextXAlignment = Enum.TextXAlignment.Center
WText.Parent = Watermark

local HotkeysHUD = Instance.new("Frame")
HotkeysHUD.Name = "HotkeysHUD"
HotkeysHUD.Size = UDim2.new(0, 200, 0, 40)
HotkeysHUD.Position = UDim2.new(0, 20, 0.4, 0)
HotkeysHUD.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
HotkeysHUD.BorderSizePixel = 0
HotkeysHUD.ClipsDescendants = true
HotkeysHUD.Parent = ScreenGui

local HUDCorner = Instance.new("UICorner")
HUDCorner.CornerRadius = UDim.new(0, 6)
HUDCorner.Parent = HotkeysHUD

local HUDStroke = Instance.new("UIStroke")
HUDStroke.Color = Settings.AccentColor
HUDStroke.Thickness = 1.2
HUDStroke.Transparency = 0.4
HUDStroke.Parent = HotkeysHUD

local HUDHeader = Instance.new("Frame")
HUDHeader.Name = "HUDHeader"
HUDHeader.Size = UDim2.new(1, 0, 0, 28)
HUDHeader.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
HUDHeader.BorderSizePixel = 0
HUDHeader.Parent = HotkeysHUD

local HUDHeaderCorner = Instance.new("UICorner")
HUDHeaderCorner.CornerRadius = UDim.new(0, 6)
HUDHeaderCorner.Parent = HUDHeader

local HUDTitle = Instance.new("TextLabel")
HUDTitle.Size = UDim2.new(1, -10, 1, 0)
HUDTitle.Position = UDim2.new(0, 10, 0, 0)
HUDTitle.BackgroundTransparency = 1
HUDTitle.Text = "⌨️ <b>HOTKEYS</b>"
HUDTitle.RichText = true
HUDTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
HUDTitle.Font = Enum.Font.GothamBold
HUDTitle.TextSize = 12
HUDTitle.TextXAlignment = Enum.TextXAlignment.Left
HUDTitle.Parent = HUDHeader

local HUDList = Instance.new("Frame")
HUDList.Name = "HUDList"
HUDList.Size = UDim2.new(1, -12, 1, -32)
HUDList.Position = UDim2.new(0, 6, 0, 32)
HUDList.BackgroundTransparency = 1
HUDList.Parent = HotkeysHUD

local HUDLayout = Instance.new("UIListLayout")
HUDLayout.SortOrder = Enum.SortOrder.LayoutOrder
HUDLayout.Padding = UDim.new(0, 4)
HUDLayout.Parent = HUDList

local HUDDragging, HUDDragInput, HUDDragStart, HUDStartPos
HUDHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        HUDDragging = true
        HUDDragStart = input.Position
        HUDStartPos = HotkeysHUD.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                HUDDragging = false
            end
        end)
    end
end)

HUDHeader.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        HUDDragInput = input
    end
end)

Services.UserInputService.InputChanged:Connect(function(input)
    if input == HUDDragInput and HUDDragging then
        local Delta = input.Position - HUDDragStart
        HotkeysHUD.Position = UDim2.new(HUDStartPos.X.Scale, HUDStartPos.X.Offset + Delta.X, HUDStartPos.Y.Scale, HUDStartPos.Y.Offset + Delta.Y)
    end
end)

local function UpdateHotkeysHUD()
    if not Settings.ShowHotkeysHUD then
        HotkeysHUD.Visible = false
        return
    end
    HotkeysHUD.Visible = true

    for _, child in ipairs(HUDList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local count = 0
    for id, bindData in pairs(Binds) do
        if bindData.Key and GetInputName(bindData.Key) ~= "NONE" then
            count = count + 1
            local ItemFrame = Instance.new("Frame")
            ItemFrame.Size = UDim2.new(1, 0, 0, 22)
            ItemFrame.BackgroundTransparency = 1
            ItemFrame.Parent = HUDList

            local NameLabel = Instance.new("TextLabel")
            NameLabel.Size = UDim2.new(0.52, 0, 1, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text = bindData.Name
            NameLabel.TextColor3 = Color3.fromRGB(200, 205, 220)
            NameLabel.Font = Enum.Font.GothamMedium
            NameLabel.TextSize = 11
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Parent = ItemFrame

            local KeyLabel = Instance.new("TextLabel")
            KeyLabel.Size = UDim2.new(0.28, 0, 1, 0)
            KeyLabel.Position = UDim2.new(0.52, 0, 0, 0)
            KeyLabel.BackgroundTransparency = 1
            KeyLabel.Text = "[" .. GetInputName(bindData.Key) .. "]"
            KeyLabel.TextColor3 = Color3.fromRGB(150, 155, 175)
            KeyLabel.Font = Enum.Font.GothamBold
            KeyLabel.TextSize = 11
            KeyLabel.TextXAlignment = Enum.TextXAlignment.Center
            KeyLabel.Parent = ItemFrame

            local StatusLabel = Instance.new("TextLabel")
            StatusLabel.Size = UDim2.new(0.2, 0, 1, 0)
            StatusLabel.Position = UDim2.new(0.8, 0, 0, 0)
            StatusLabel.BackgroundTransparency = 1
            if bindData.Type == "Toggle" then
                local active = bindData.GetState and bindData.GetState()
                StatusLabel.Text = active and "ON" or "OFF"
                StatusLabel.TextColor3 = active and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(120, 125, 140)
            elseif bindData.Type == "Hold" then
                local active = bindData.GetState and bindData.GetState()
                StatusLabel.Text = active and "HOLD" or "OFF"
                StatusLabel.TextColor3 = active and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(120, 125, 140)
            else
                StatusLabel.Text = "TRIG"
                StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
            end
            StatusLabel.Font = Enum.Font.GothamBold
            StatusLabel.TextSize = 11
            StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
            StatusLabel.Parent = ItemFrame
        end
    end

    local newHeight = 32 + (count * 26)
    if count == 0 then
        newHeight = 55
        local EmptyLabel = Instance.new("TextLabel")
        EmptyLabel.Size = UDim2.new(1, 0, 0, 20)
        EmptyLabel.BackgroundTransparency = 1
        EmptyLabel.Text = "No active hotkeys"
        EmptyLabel.TextColor3 = Color3.fromRGB(100, 105, 120)
        EmptyLabel.Font = Enum.Font.Gotham
        EmptyLabel.TextSize = 11
        EmptyLabel.Parent = HUDList
    end
    HotkeysHUD.Size = UDim2.new(0, 200, 0, newHeight)
end

local TargetHUD = Instance.new("Frame")
TargetHUD.Name = "TargetHUD"
TargetHUD.Size = UDim2.new(0, 250, 0, 75)
TargetHUD.Position = UDim2.new(0.5, -125, 0.72, 0)
TargetHUD.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
TargetHUD.BorderSizePixel = 0
TargetHUD.ClipsDescendants = true
TargetHUD.Parent = ScreenGui

local TargetHUDCorner = Instance.new("UICorner")
TargetHUDCorner.CornerRadius = UDim.new(0, 8)
TargetHUDCorner.Parent = TargetHUD

local TargetHUDStroke = Instance.new("UIStroke")
TargetHUDStroke.Color = Settings.AccentColor
TargetHUDStroke.Thickness = 1.2
TargetHUDStroke.Transparency = 0.4
TargetHUDStroke.Parent = TargetHUD

local TargetAvatar = Instance.new("ImageLabel")
TargetAvatar.Name = "TargetAvatar"
TargetAvatar.Size = UDim2.new(0, 52, 0, 52)
TargetAvatar.Position = UDim2.new(0, 10, 0.5, -26)
TargetAvatar.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
TargetAvatar.BorderSizePixel = 0
TargetAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=150&h=150"
TargetAvatar.Parent = TargetHUD

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(0, 6)
AvatarCorner.Parent = TargetAvatar

local TargetName = Instance.new("TextLabel")
TargetName.Name = "TargetName"
TargetName.Size = UDim2.new(1, -78, 0, 22)
TargetName.Position = UDim2.new(0, 70, 0, 10)
TargetName.BackgroundTransparency = 1
TargetName.Text = "Target Player"
TargetName.TextColor3 = Color3.fromRGB(245, 245, 250)
TargetName.Font = Enum.Font.GothamBold
TargetName.TextSize = 13
TargetName.TextXAlignment = Enum.TextXAlignment.Left
TargetName.Parent = TargetHUD

local TargetHPText = Instance.new("TextLabel")
TargetHPText.Name = "TargetHPText"
TargetHPText.Size = UDim2.new(1, -78, 0, 18)
TargetHPText.Position = UDim2.new(0, 70, 0, 30)
TargetHPText.BackgroundTransparency = 1
TargetHPText.Text = "100 / 100 HP (100%)"
TargetHPText.TextColor3 = Color3.fromRGB(0, 255, 150)
TargetHPText.Font = Enum.Font.GothamBold
TargetHPText.TextSize = 11
TargetHPText.TextXAlignment = Enum.TextXAlignment.Left
TargetHPText.Parent = TargetHUD

local HPBarBack = Instance.new("Frame")
HPBarBack.Name = "HPBarBack"
HPBarBack.Size = UDim2.new(1, -78, 0, 8)
HPBarBack.Position = UDim2.new(0, 70, 1, -18)
HPBarBack.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
HPBarBack.BorderSizePixel = 0
HPBarBack.Parent = TargetHUD

local HPBarCorner = Instance.new("UICorner")
HPBarCorner.CornerRadius = UDim.new(1, 0)
HPBarCorner.Parent = HPBarBack

local HPBarFill = Instance.new("Frame")
HPBarFill.Name = "HPBarFill"
HPBarFill.Size = UDim2.new(1, 0, 1, 0)
HPBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
HPBarFill.BorderSizePixel = 0
HPBarFill.Parent = HPBarBack

local HPFillCorner = Instance.new("UICorner")
HPFillCorner.CornerRadius = UDim.new(1, 0)
HPFillCorner.Parent = HPBarFill

local THDragging, THDragInput, THDragStart, THStartPos
TargetHUD.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        THDragging = true
        THDragStart = input.Position
        THStartPos = TargetHUD.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                THDragging = false
            end
        end)
    end
end)

TargetHUD.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        THDragInput = input
    end
end)

Services.UserInputService.InputChanged:Connect(function(input)
    if input == THDragInput and THDragging then
        local Delta = input.Position - THDragStart
        TargetHUD.Position = UDim2.new(THStartPos.X.Scale, THStartPos.X.Offset + Delta.X, THStartPos.Y.Scale, THStartPos.Y.Offset + Delta.Y)
    end
end)

local currentTargetUserId = nil
local function UpdateTargetHUD(character)
    if not Settings.ShowTargetHUD then
        TargetHUD.Visible = false
        return
    end

    if not character then
        if MainFrame and MainFrame.Visible then
            TargetHUD.Visible = true
            TargetName.Text = "Target Preview"
            TargetHPText.Text = "100 / 100 HP (100%)"
            TargetHPText.TextColor3 = Color3.fromRGB(0, 255, 150)
            Services.TweenService:Create(HPBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(0, 255, 150)
            }):Play()
            if currentTargetUserId ~= 1 then
                currentTargetUserId = 1
                TargetAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=150&h=150"
            end
        else
            TargetHUD.Visible = false
        end
        return
    end

    local plr = Services.Players:GetPlayerFromCharacter(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then
        TargetHUD.Visible = false
        return
    end

    TargetHUD.Visible = true
    local pName = plr and plr.DisplayName or character.Name
    TargetName.Text = pName

    if plr then
        if currentTargetUserId ~= plr.UserId then
            currentTargetUserId = plr.UserId
            TargetAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=150&h=150"
        end
    end

    local hp = math.max(0, math.floor(hum.Health))
    local maxHp = math.max(1, math.floor(hum.MaxHealth))
    local pct = math.clamp(hp / maxHp, 0, 1)

    TargetHPText.Text = string.format("%d / %d HP (%d%%)", hp, maxHp, math.floor(pct * 100))

    local barColor
    if pct > 0.5 then
        barColor = Color3.fromRGB(255, 200, 50):Lerp(Color3.fromRGB(0, 255, 150), (pct - 0.5) * 2)
    else
        barColor = Color3.fromRGB(255, 50, 60):Lerp(Color3.fromRGB(255, 200, 50), pct * 2)
    end
    TargetHPText.TextColor3 = barColor

    Services.TweenService:Create(HPBarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = barColor
    }):Play()
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 640, 0, 420)
MainFrame.Position = UDim2.new(0.5, -320, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainUICorner = Instance.new("UICorner")
MainUICorner.CornerRadius = UDim.new(0, 8)
MainUICorner.Parent = MainFrame

local MainUIStroke = Instance.new("UIStroke")
MainUIStroke.Color = Settings.AccentColor
MainUIStroke.Thickness = 1.5
MainUIStroke.Transparency = 0.3
MainUIStroke.Parent = MainFrame

local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 40)
Topbar.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local TopbarCorner = Instance.new("UICorner")
TopbarCorner.CornerRadius = UDim.new(0, 8)
TopbarCorner.Parent = Topbar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0, 250, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "<font color=\"#6C5CE7\"><b>SKYLIGHT CLIENT</b></font> | CS-GUI"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Topbar

local StatusBadge = Instance.new("TextLabel")
StatusBadge.Size = UDim2.new(0, 80, 0, 22)
StatusBadge.Position = UDim2.new(1, -95, 0.5, -11)
StatusBadge.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
StatusBadge.Text = "ACTIVE"
StatusBadge.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusBadge.Font = Enum.Font.GothamBold
StatusBadge.TextSize = 11
StatusBadge.Parent = Topbar

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 4)
StatusCorner.Parent = StatusBadge

local Dragging, DragInput, DragStart, StartPos
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

Topbar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        DragInput = input
    end
end)

Services.UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        local Delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
    end
end)

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 150, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -160, 1, -50)
ContentContainer.Position = UDim2.new(0, 155, 0, 45)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local Categories = {
    { Name = "Combat", Icon = "⚔️" },
    { Name = "Movement", Icon = "⚡" },
    { Name = "Visuals", Icon = "👁️" },
    { Name = "Player", Icon = "👤" },
    { Name = "Settings", Icon = "⚙️" }
}

local TabButtons = {}
local TabPages = {}

local function SelectTab(selectedName)
    for name, page in pairs(TabPages) do
        page.Visible = (name == selectedName)
    end
    for name, btn in pairs(TabButtons) do
        if name == selectedName then
            btn.BackgroundColor3 = Settings.AccentColor
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
            btn.TextColor3 = Color3.fromRGB(160, 165, 180)
        end
    end
end

local function CreateTabPage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Settings.AccentColor
    Page.Visible = false
    Page.Parent = ContentContainer

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.Parent = Page

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingRight = UDim.new(0, 8)
    PagePadding.Parent = Page

    TabPages[name] = Page
    return Page
end

local function CreateToggle(parent, id, title, defaultState, callback, defaultKey, isHoldType, desc)
    local Frame = Instance.new("Frame")
    local frameH = desc and 52 or 36
    Frame.Size = UDim2.new(1, 0, 0, frameH)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = defaultState and Settings.AccentColor or Color3.fromRGB(38, 42, 58)
    Stroke.Thickness = 1
    Stroke.Transparency = defaultState and 0.4 or 0.6
    Stroke.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = desc and UDim2.new(1, -145, 0, 22) or UDim2.new(1, -145, 1, 0)
    Label.Position = desc and UDim2.new(0, 12, 0, 5) or UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(240, 245, 255)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    if desc then
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -145, 0, 18)
        DescLabel.Position = UDim2.new(0, 12, 0, 27)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = desc
        DescLabel.TextColor3 = Color3.fromRGB(140, 145, 165)
        DescLabel.Font = Enum.Font.GothamMedium
        DescLabel.TextSize = 10
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.Parent = Frame
    end

    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Size = UDim2.new(0, 70, 0, 22)
    KeyBtn.Position = UDim2.new(1, -130, 0.5, -11)
    KeyBtn.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
    KeyBtn.Text = defaultKey and ("[" .. GetInputName(defaultKey) .. "]") or "[ NONE ]"
    KeyBtn.TextColor3 = Color3.fromRGB(170, 175, 195)
    KeyBtn.Font = Enum.Font.GothamBold
    KeyBtn.TextSize = 11
    KeyBtn.Parent = Frame

    local KeyCorner = Instance.new("UICorner")
    KeyCorner.CornerRadius = UDim.new(0, 4)
    KeyCorner.Parent = KeyBtn

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 44, 0, 22)
    Switch.Position = UDim2.new(1, -52, 0.5, -11)
    Switch.BackgroundColor3 = defaultState and Settings.AccentColor or Color3.fromRGB(40, 45, 60)
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = Frame

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent = Switch

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local state = defaultState
    local function UpdateVisuals(newState)
        state = newState
        Switch.BackgroundColor3 = state and Settings.AccentColor or Color3.fromRGB(40, 45, 60)
        Knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        Stroke.Color = state and Settings.AccentColor or Color3.fromRGB(38, 42, 58)
        Stroke.Transparency = state and 0.4 or 0.6
        callback(state)
        UpdateHotkeysHUD()
    end

    Switch.MouseButton1Click:Connect(function()
        UpdateVisuals(not state)
    end)

    local bindObj = {
        Key = defaultKey,
        Type = isHoldType and "Hold" or "Toggle",
        Name = title,
        GetState = function() return state end,
        SetState = function(s) UpdateVisuals(s) end,
        Toggle = function()
            UpdateVisuals(not state)
        end
    }
    Binds[id] = bindObj

    local isListening = false
    KeyBtn.MouseButton1Click:Connect(function()
        if isListening then return end
        isListening = true
        KeyBtn.Text = "[ ... ]"
        KeyBtn.TextColor3 = Settings.AccentColor

        local bindConn
        bindConn = Services.UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                    bindObj.Key = nil
                else
                    bindObj.Key = input.KeyCode
                end
                isListening = false
                KeyBtn.Text = "[" .. GetInputName(bindObj.Key) .. "]"
                KeyBtn.TextColor3 = Color3.fromRGB(170, 175, 195)
                UpdateHotkeysHUD()
                bindConn:Disconnect()
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                bindObj.Key = input.UserInputType
                isListening = false
                KeyBtn.Text = "[" .. GetInputName(bindObj.Key) .. "]"
                KeyBtn.TextColor3 = Color3.fromRGB(170, 175, 195)
                UpdateHotkeysHUD()
                bindConn:Disconnect()
            end
        end)
    end)

    return Frame
end

local function CreateButton(parent, id, title, callback, defaultKey)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Btn = Instance.new("TextButton")
    Btn.Size = defaultKey and UDim2.new(1, -90, 1, 0) or UDim2.new(1, 0, 1, 0)
    Btn.Position = UDim2.new(0, 0, 0, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = defaultKey and ("   " .. title) or title
    Btn.TextColor3 = Color3.fromRGB(240, 240, 245)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextXAlignment = defaultKey and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
    Btn.Parent = Frame

    Btn.MouseButton1Click:Connect(callback)

    if defaultKey then
        local KeyBtn = Instance.new("TextButton")
        KeyBtn.Size = UDim2.new(0, 75, 0, 22)
        KeyBtn.Position = UDim2.new(1, -83, 0.5, -11)
        KeyBtn.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
        KeyBtn.Text = "[" .. GetInputName(defaultKey) .. "]"
        KeyBtn.TextColor3 = Color3.fromRGB(170, 175, 195)
        KeyBtn.Font = Enum.Font.GothamBold
        KeyBtn.TextSize = 11
        KeyBtn.Parent = Frame

        local KeyCorner = Instance.new("UICorner")
        KeyCorner.CornerRadius = UDim.new(0, 4)
        KeyCorner.Parent = KeyBtn

        local bindObj = {
            Key = defaultKey,
            Type = "Action",
            Name = title,
            Action = callback
        }
        Binds[id] = bindObj

        local isListening = false
        KeyBtn.MouseButton1Click:Connect(function()
            if isListening then return end
            isListening = true
            KeyBtn.Text = "[ ... ]"
            KeyBtn.TextColor3 = Settings.AccentColor

            local bindConn
            bindConn = Services.UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                        bindObj.Key = nil
                    else
                        bindObj.Key = input.KeyCode
                    end
                    isListening = false
                    KeyBtn.Text = "[" .. GetInputName(bindObj.Key) .. "]"
                    KeyBtn.TextColor3 = Color3.fromRGB(170, 175, 195)
                    UpdateHotkeysHUD()
                    bindConn:Disconnect()
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    bindObj.Key = input.UserInputType
                    isListening = false
                    KeyBtn.Text = "[" .. GetInputName(bindObj.Key) .. "]"
                    KeyBtn.TextColor3 = Color3.fromRGB(170, 175, 195)
                    UpdateHotkeysHUD()
                    bindConn:Disconnect()
                end
            end)
        end)
    end

    return Frame
end

local function CreateSlider(parent, title, minVal, maxVal, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 50)
    Frame.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 0, 24)
    Label.Position = UDim2.new(0, 12, 0, 2)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(220, 225, 240)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0, 50, 0, 24)
    ValLabel.Position = UDim2.new(1, -62, 0, 2)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = tostring(defaultVal)
    ValLabel.TextColor3 = Settings.AccentColor
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextSize = 13
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Parent = Frame

    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -24, 0, 6)
    SliderBar.Position = UDim2.new(0, 12, 1, -14)
    SliderBar.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = Frame

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBar

    local FillBar = Instance.new("Frame")
    local pct = (defaultVal - minVal) / (maxVal - minVal)
    FillBar.Size = UDim2.new(pct, 0, 1, 0)
    FillBar.BackgroundColor3 = Settings.AccentColor
    FillBar.BorderSizePixel = 0
    FillBar.Parent = SliderBar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = FillBar

    local sliding = false
    local function UpdateSlide(input)
        local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * pos)
        FillBar.Size = UDim2.new(pos, 0, 1, 0)
        ValLabel.Text = tostring(val)
        callback(val)
    end

    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            UpdateSlide(input)
        end
    end)

    Services.UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlide(input)
        end
    end)

    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)
    return Frame
end

local function CreateTextBox(parent, title, placeholder, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.45, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(220, 225, 240)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local BoxFrame = Instance.new("Frame")
    BoxFrame.Size = UDim2.new(0.5, 0, 0, 24)
    BoxFrame.Position = UDim2.new(0.47, 0, 0.5, -12)
    BoxFrame.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
    BoxFrame.BorderSizePixel = 0
    BoxFrame.Parent = Frame

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 4)
    BoxCorner.Parent = BoxFrame

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1, -10, 1, 0)
    Box.Position = UDim2.new(0, 5, 0, 0)
    Box.BackgroundTransparency = 1
    Box.PlaceholderText = placeholder
    Box.Text = defaultVal or placeholder
    Box.TextColor3 = Color3.fromRGB(250, 250, 255)
    Box.PlaceholderColor3 = Color3.fromRGB(120, 125, 140)
    Box.Font = Enum.Font.GothamBold
    Box.TextSize = 12
    Box.ClearTextOnFocus = false
    Box.Parent = BoxFrame

    Box.FocusLost:Connect(function()
        callback(Box.Text)
    end)

    return Frame, Box
end

for i, cat in ipairs(Categories) do
    local Btn = Instance.new("TextButton")
    Btn.Name = cat.Name .. "Tab"
    Btn.Size = UDim2.new(1, 0, 0, 38)
    Btn.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
    Btn.Text = "  " .. cat.Icon .. "  " .. cat.Name
    Btn.TextColor3 = Color3.fromRGB(160, 165, 180)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Btn

    TabButtons[cat.Name] = Btn
    CreateTabPage(cat.Name)

    Btn.MouseButton1Click:Connect(function()
        SelectTab(cat.Name)
    end)
end

SelectTab("Combat")

local CombatPage = TabPages["Combat"]

CreateToggle(CombatPage, "aura", "TriggerBot", Settings.Aura, function(state)
    Settings.Aura = state
    if not state then Settings.AuraTarget = nil end
end, Enum.KeyCode.R)

CreateSlider(CombatPage, "TriggerBot Distance (Studs)", 5, 50, Settings.AuraRange, function(val)
    Settings.AuraRange = val
end)

CreateToggle(CombatPage, "aimlock", "AimLock", Settings.AimLock, function(state)
    Settings.AimLock = state
    if not state then
        Settings.AimLockActive = false
        Settings.AimLockTarget = nil
    end
end, Enum.KeyCode.C, true)

CreateSlider(CombatPage, "AimLock FOV Radius", 30, 400, Settings.AimLockFOVRadius, function(val)
    Settings.AimLockFOVRadius = val
end)

CreateToggle(CombatPage, "teamcheck", "Team Check", Settings.TeamCheck, function(state)
    Settings.TeamCheck = state
end)

local MovementPage = TabPages["Movement"]

CreateToggle(MovementPage, "speed", "Speed", Settings.Speed, function(state)
    Settings.Speed = state
end, Enum.KeyCode.LeftShift, true)

CreateSlider(MovementPage, "Speed Multiplier", 1, 10, math.floor(Settings.SpeedMultiplier), function(val)
    Settings.SpeedMultiplier = val
end)

CreateToggle(MovementPage, "velocity", "Velocity (No Knockback)", Settings.Velocity, function(state)
    Settings.Velocity = state
end, nil)

CreateToggle(MovementPage, "clicktp", "Click Teleport", Settings.ClickTP, function(state)
    Settings.ClickTP = state
end, nil, false, "💡 Зажмите Ctrl и нажмите ЛКМ для телепортации")

CreateSlider(MovementPage, "VClip Distance", 2, 50, Settings.VClipDistance, function(val)
    Settings.VClipDistance = val
end)

local function PerformVClip(offset)
    if IsAlive(LocalPlayer) then
        local char = LocalPlayer.Character
        local root = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        local moveDir = hum and hum.MoveDirection or Vector3.new()
        local currentVel = root.AssemblyLinearVelocity
        local horizVelX = currentVel.X
        local horizVelZ = currentVel.Z

        root.CFrame = root.CFrame * CFrame.new(0, offset, 0)
        root.AssemblyLinearVelocity = Vector3.new(horizVelX, 0, horizVelZ)
        pcall(function()
            root.Velocity = Vector3.new(horizVelX, 0, horizVelZ)
        end)

        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            if moveDir.Magnitude > 0 then
                hum:Move(moveDir, false)
            end
        end
    end
end

CreateButton(MovementPage, "vclip_up", "🔼 VClip UP", function()
    PerformVClip(Settings.VClipDistance)
end, Enum.KeyCode.Up)

CreateButton(MovementPage, "vclip_down", "🔽 VClip DOWN", function()
    PerformVClip(-Settings.VClipDistance)
end, Enum.KeyCode.Down)

local VisualsPage = TabPages["Visuals"]

CreateToggle(VisualsPage, "tracers", "Tracers", Settings.Tracers, function(state)
    Settings.Tracers = state
    if not state then
        for _, line in pairs(TracerDrawings) do
            pcall(function() line.Visible = false end)
        end
    end
end, nil)

CreateToggle(VisualsPage, "esp", "ESP", Settings.ESP, function(state)
    Settings.ESP = state
    if not state then
        for _, hl in pairs(Highlights) do
            pcall(function() hl.Enabled = false end)
        end
    end
end, nil)

CreateToggle(VisualsPage, "box_3d", "3D Box", Settings.Box3D, function(state)
    Settings.Box3D = state
    if not state then
        for _, box in pairs(BoxDrawings) do
            for _, l in ipairs(box) do
                pcall(function() l.Visible = false end)
            end
        end
    end
end, nil)

CreateToggle(VisualsPage, "aimlock_fov", "AimLock FOV", Settings.AimLockFOV, function(state)
    Settings.AimLockFOV = state
    if not state and FOVCircleDrawing then
        pcall(function() FOVCircleDrawing.Visible = false end)
    end
end, nil)

CreateToggle(VisualsPage, "target_esp", "TargetESP", Settings.TargetESP, function(state)
    Settings.TargetESP = state
    if not state then
        for _, l in ipairs(TargetESPDrawings) do
            pcall(function() l.Visible = false end)
        end
        if TargetESPCircle then pcall(function() TargetESPCircle.Visible = false end) end
    end
end, nil)

CreateToggle(VisualsPage, "purple_ambiance", "Purple Ambiance (Screen Tint)", Settings.PurpleAmbiance, function(state)
    Settings.PurpleAmbiance = state
    UpdateAmbiance()
end, nil)

CreateToggle(VisualsPage, "custom_fog", "Custom Purple Fog", Settings.CustomFog, function(state)
    Settings.CustomFog = state
    UpdateFog()
end, nil)

CreateSlider(VisualsPage, "Fog Distance (Studs)", 50, 1000, Settings.FogDensity, function(val)
    Settings.FogDensity = val
    if Settings.CustomFog then UpdateFog() end
end)

CreateToggle(VisualsPage, "purple_sky", "Night / Galaxy Sky", Settings.PurpleSky, function(state)
    Settings.PurpleSky = state
    UpdateSky()
end, nil)

local PlayerPage = TabPages["Player"]

CreateToggle(PlayerPage, "infjump", "Infinite Jump", Settings.InfJump, function(state)
    Settings.InfJump = state
end, nil)

CreateSlider(PlayerPage, "Camera FOV", 70, 120, Settings.FOV, function(val)
    Settings.FOV = val
    Camera.FieldOfView = val
end)

CreateButton(PlayerPage, "reset_stats", "Reset Speed & FOV", function()
    Camera.FieldOfView = 70
    Settings.FOV = 70
    if IsAlive(LocalPlayer) then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

local SettingsPage = TabPages["Settings"]

CreateToggle(SettingsPage, "hotkeys_hud", "Hotkeys HUD Widget", Settings.ShowHotkeysHUD, function(state)
    Settings.ShowHotkeysHUD = state
    UpdateHotkeysHUD()
end)

CreateToggle(SettingsPage, "target_hud", "Target HUD Widget", Settings.ShowTargetHUD, function(state)
    Settings.ShowTargetHUD = state
    UpdateTargetHUD(nil)
end)

local MenuKeyBtnFrame = Instance.new("Frame")
MenuKeyBtnFrame.Size = UDim2.new(1, 0, 0, 36)
MenuKeyBtnFrame.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
MenuKeyBtnFrame.BorderSizePixel = 0
MenuKeyBtnFrame.Parent = SettingsPage

local MenuKeyCorner = Instance.new("UICorner")
MenuKeyCorner.CornerRadius = UDim.new(0, 6)
MenuKeyCorner.Parent = MenuKeyBtnFrame

local MenuKeyLabel = Instance.new("TextLabel")
MenuKeyLabel.Size = UDim2.new(1, -110, 1, 0)
MenuKeyLabel.Position = UDim2.new(0, 12, 0, 0)
MenuKeyLabel.BackgroundTransparency = 1
MenuKeyLabel.Text = "Menu Toggle Keybind"
MenuKeyLabel.TextColor3 = Color3.fromRGB(220, 225, 240)
MenuKeyLabel.Font = Enum.Font.GothamMedium
MenuKeyLabel.TextSize = 13
MenuKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
MenuKeyLabel.Parent = MenuKeyBtnFrame

local MenuKeySelector = Instance.new("TextButton")
MenuKeySelector.Size = UDim2.new(0, 90, 0, 22)
MenuKeySelector.Position = UDim2.new(1, -98, 0.5, -11)
MenuKeySelector.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
MenuKeySelector.Text = "[" .. GetInputName(Settings.ToggleKey) .. "]"
MenuKeySelector.TextColor3 = Settings.AccentColor
MenuKeySelector.Font = Enum.Font.GothamBold
MenuKeySelector.TextSize = 11
MenuKeySelector.Parent = MenuKeyBtnFrame

local MenuKeySelCorner = Instance.new("UICorner")
MenuKeySelCorner.CornerRadius = UDim.new(0, 4)
MenuKeySelCorner.Parent = MenuKeySelector

CreateButton(SettingsPage, "unload_script", "❌ Unload Script", function()
    CleanupVisuals()
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    ScreenGui:Destroy()
end)

UpdateHotkeysHUD()
UpdateTargetHUD(nil)

Connections.GlobalHotkeysBegan = Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if Services.UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Settings.ToggleKey then
        if MainFrame then
            MainFrame.Visible = not MainFrame.Visible
            UpdateTargetHUD(Settings.AimLockTarget or Settings.AuraTarget)
        end
        return
    end

    for id, bindObj in pairs(Binds) do
        if CheckInputMatch(bindObj.Key, input) then
            if bindObj.Type == "Toggle" and bindObj.Toggle then
                bindObj.Toggle()
            elseif bindObj.Type == "Hold" then
                if bindObj.SetState then bindObj.SetState(true) end
                if id == "aimlock" then Settings.AimLockActive = true end
            elseif bindObj.Type == "Action" and bindObj.Action then
                bindObj.Action()
                UpdateHotkeysHUD()
            end
        end
    end
end)

Connections.GlobalHotkeysEnded = Services.UserInputService.InputEnded:Connect(function(input, gpe)
    for id, bindObj in pairs(Binds) do
        if CheckInputMatch(bindObj.Key, input) then
            if bindObj.Type == "Hold" then
                if bindObj.SetState then bindObj.SetState(false) end
                if id == "aimlock" then
                    Settings.AimLockActive = false
                    Settings.AimLockTarget = nil
                end
            end
        end
    end
end)

Connections.ClickTPInput = Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not Settings.ClickTP then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local uis = Services.UserInputService
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.RightControl) then
            if IsAlive(LocalPlayer) then
                local mousePos = uis:GetMouseLocation()
                local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                if LocalPlayer.Character then
                    params.FilterDescendantsInstances = {LocalPlayer.Character}
                end
                local result = Services.Workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, params)
                if result then
                    local targetPos = result.Position + Vector3.new(0, 3.5, 0)
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos)
                end
            end
        end
    end
end)

local function GetClosestTargetToCursor()
    if not IsAlive(LocalPlayer) then return nil end
    local mousePos = Services.UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local shortestDist = Settings.AimLockFOVRadius

    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            if not (Settings.TeamCheck and plr.Team == LocalPlayer.Team) then
                local torso = GetTargetTorso(plr.Character)
                if torso then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                    if onScreen then
                        local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if distToMouse < shortestDist then
                            shortestDist = distToMouse
                            closestPlayer = plr.Character
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

Connections.AimLockLoop = Services.RunService.RenderStepped:Connect(function()
    if not Settings.AimLock or not Settings.AimLockActive then
        Settings.AimLockTarget = nil
        return
    end

    if not Settings.AimLockTarget or not IsAlive(Services.Players:GetPlayerFromCharacter(Settings.AimLockTarget)) then
        Settings.AimLockTarget = GetClosestTargetToCursor()
    end

    if Settings.AimLockTarget then
        local torso = GetTargetTorso(Settings.AimLockTarget)
        if torso then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, torso.Position)
        end
    end
end)

local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = (pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager")) or nil
local hasHitThisJump = true
local wasOnGround = true
local leftGroundTime = 0

Connections.InfJumpConn = Services.UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump and IsAlive(LocalPlayer) then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Connections.AuraLoop = Services.RunService.Heartbeat:Connect(function()
    if not Settings.Aura or not IsAlive(LocalPlayer) then
        Settings.AuraTarget = nil
        return
    end
    local char = LocalPlayer.Character
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not hum then return end

    local closestTarget = nil
    local closestDist = Settings.AuraRange

    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            if not (Settings.TeamCheck and plr.Team == LocalPlayer.Team) then
                local dist = (plr.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if dist <= closestDist then
                    closestDist = dist
                    closestTarget = plr.Character
                end
            end
        end
    end

    Settings.AuraTarget = closestTarget

    if closestTarget then
        local state = hum:GetState()
        local isOnGround = (hum.FloorMaterial ~= Enum.Material.Air and state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall)
        if isOnGround then
            wasOnGround = true
            return
        end

        if wasOnGround then
            wasOnGround = false
            hasHitThisJump = false
            leftGroundTime = tick()
        end

        if hasHitThisJump then
            return
        end

        if tick() - leftGroundTime < 0.1 then
            return
        end

        hasHitThisJump = true
        if VirtualInputManager then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        else
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
            else
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                end)
            end
        end
    end
end)

Connections.TargetHUDLoop = Services.RunService.RenderStepped:Connect(function()
    local currentTarget = Settings.AimLockTarget or Settings.AuraTarget
    UpdateTargetHUD(currentTarget)
end)

Connections.SpeedLoop = Services.RunService.RenderStepped:Connect(function(delta)
    if not Settings.Speed or not IsAlive(LocalPlayer) then return end
    local hum = LocalPlayer.Character.Humanoid
    local root = LocalPlayer.Character.HumanoidRootPart
    if hum.MoveDirection.Magnitude > 0 then
        root.CFrame = root.CFrame + (hum.MoveDirection * (Settings.SpeedMultiplier * delta * 50))
    end
end)

local KnockbackClasses = {"BodyVelocity", "LinearVelocity", "VectorForce", "BodyPosition", "BodyThrust", "BodyAngularVelocity", "LineForce"}

local function HandleVelocity()
    if not Settings.Velocity or not IsAlive(LocalPlayer) then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if root then
        for _, child in ipairs(root:GetChildren()) do
            for _, className in ipairs(KnockbackClasses) do
                if child:IsA(className) then
                    pcall(function() child:Destroy() end)
                end
            end
        end
        for _, child in ipairs(char:GetChildren()) do
            for _, className in ipairs(KnockbackClasses) do
                if child:IsA(className) then
                    pcall(function() child:Destroy() end)
                end
            end
        end

        local currentVel = root.AssemblyLinearVelocity
        local targetVelX, targetVelZ = 0, 0

        if hum and hum.MoveDirection.Magnitude > 0 then
            local speed = (Settings.Speed and (16 * Settings.SpeedMultiplier)) or hum.WalkSpeed
            local moveVel = hum.MoveDirection * speed
            targetVelX = moveVel.X
            targetVelZ = moveVel.Z
        end

        root.AssemblyLinearVelocity = Vector3.new(targetVelX, currentVel.Y, targetVelZ)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        pcall(function()
            root.Velocity = Vector3.new(targetVelX, root.Velocity.Y, targetVelZ)
            root.RotVelocity = Vector3.new(0, 0, 0)
        end)
    end
end

Connections.VelocityHeartbeat = Services.RunService.Heartbeat:Connect(HandleVelocity)
Connections.VelocityRender = Services.RunService.RenderStepped:Connect(HandleVelocity)
Connections.VelocityStepped = Services.RunService.Stepped:Connect(HandleVelocity)

local function GetBoxVertices(cf, size)
    local sx, sy, sz = size.X / 2, size.Y / 2, size.Z / 2
    return {
        cf * Vector3.new(-sx, -sy, -sz),
        cf * Vector3.new(sx, -sy, -sz),
        cf * Vector3.new(sx, sy, -sz),
        cf * Vector3.new(-sx, sy, -sz),
        cf * Vector3.new(-sx, -sy, sz),
        cf * Vector3.new(sx, -sy, sz),
        cf * Vector3.new(sx, sy, sz),
        cf * Vector3.new(-sx, sy, sz),
    }
end

local BoxEdges = {
    {1,2},{2,3},{3,4},{4,1},
    {5,6},{6,7},{7,8},{8,5},
    {1,5},{2,6},{3,7},{4,8}
}

Connections.VisualsLoop = Services.RunService.RenderStepped:Connect(function()
    if Drawing then
        if not FOVCircleDrawing then
            FOVCircleDrawing = Drawing.new("Circle")
            FOVCircleDrawing.Thickness = 1.5
            FOVCircleDrawing.Transparency = 0.8
            FOVCircleDrawing.NumSides = 64
            FOVCircleDrawing.Filled = false
        end

        if Settings.AimLockFOV then
            local mousePos = Services.UserInputService:GetMouseLocation()
            FOVCircleDrawing.Position = mousePos
            FOVCircleDrawing.Radius = Settings.AimLockFOVRadius
            FOVCircleDrawing.Color = Settings.AccentColor
            FOVCircleDrawing.Visible = true
        else
            FOVCircleDrawing.Visible = false
        end
    end

    local currentTarget = Settings.AimLockTarget or Settings.AuraTarget
    if Settings.TargetESP and currentTarget and IsAlive(Services.Players:GetPlayerFromCharacter(currentTarget)) and Drawing then
        local torso = GetTargetTorso(currentTarget)
        if torso then
            local screenPos, onScreen = Camera:WorldToViewportPoint(torso.Position)
            if onScreen then
                if #TargetESPDrawings == 0 then
                    for i = 1, 12 do
                        local l = Drawing.new("Line")
                        l.Thickness = 2
                        l.Transparency = 1
                        table.insert(TargetESPDrawings, l)
                    end
                end
                if not TargetESPCircle then
                    TargetESPCircle = Drawing.new("Circle")
                    TargetESPCircle.Thickness = 1.5
                    TargetESPCircle.Transparency = 0.9
                    TargetESPCircle.NumSides = 32
                    TargetESPCircle.Filled = false
                end

                local center = Vector2.new(screenPos.X, screenPos.Y)
                local a1 = tick() * 3.5
                local r1 = 20
                local verts1 = {}
                for i = 1, 4 do
                    local ang = a1 + (i - 1) * (math.pi / 2)
                    table.insert(verts1, center + Vector2.new(math.cos(ang), math.sin(ang)) * r1)
                end
                for i = 1, 4 do
                    local nextIdx = (i % 4) + 1
                    local l = TargetESPDrawings[i]
                    l.From = verts1[i]
                    l.To = verts1[nextIdx]
                    l.Color = Color3.fromRGB(0, 255, 230)
                    l.Visible = true
                end

                local a2 = -tick() * 2.2
                local r2 = 34
                local arm = 12
                local lineIdx = 5
                for i = 1, 4 do
                    local ang = a2 + (i - 1) * (math.pi / 2)
                    local cornerPt = center + Vector2.new(math.cos(ang), math.sin(ang)) * r2
                    local tan1 = Vector2.new(-math.sin(ang), math.cos(ang)) * arm
                    local tan2 = Vector2.new(math.sin(ang), -math.cos(ang)) * arm

                    local l1 = TargetESPDrawings[lineIdx]
                    l1.From = cornerPt
                    l1.To = cornerPt + tan1
                    l1.Color = Color3.fromRGB(140, 95, 255)
                    l1.Visible = true
                    lineIdx = lineIdx + 1

                    local l2 = TargetESPDrawings[lineIdx]
                    l2.From = cornerPt
                    l2.To = cornerPt + tan2
                    l2.Color = Color3.fromRGB(140, 95, 255)
                    l2.Visible = true
                    lineIdx = lineIdx + 1
                end

                TargetESPCircle.Position = center
                TargetESPCircle.Radius = 14 + math.sin(tick() * 6) * 3
                TargetESPCircle.Color = Color3.fromRGB(0, 255, 200)
                TargetESPCircle.Visible = true
            else
                for _, l in ipairs(TargetESPDrawings) do l.Visible = false end
                if TargetESPCircle then TargetESPCircle.Visible = false end
            end
        else
            for _, l in ipairs(TargetESPDrawings) do l.Visible = false end
            if TargetESPCircle then TargetESPCircle.Visible = false end
        end
    else
        for _, l in ipairs(TargetESPDrawings) do l.Visible = false end
        if TargetESPCircle then TargetESPCircle.Visible = false end
    end

    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local alive = IsAlive(plr)
            if Settings.ESP and alive then
                local hl = Highlights[plr]
                if not hl or hl.Parent ~= plr.Character then
                    if hl then hl:Destroy() end
                    hl = Instance.new("Highlight")
                    hl.Name = "CS_Highlight"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = plr.Character
                    Highlights[plr] = hl
                end
                hl.Enabled = true
                hl.FillColor = Settings.ESPFill
                hl.OutlineColor = Settings.ESPOutline
                hl.FillTransparency = Settings.ESPFillTrans
            else
                if Highlights[plr] then
                    Highlights[plr].Enabled = false
                end
            end

            if Settings.Tracers and alive and Drawing then
                local line = TracerDrawings[plr]
                if not line then
                    line = Drawing.new("Line")
                    line.Thickness = 1.5
                    line.Transparency = 1
                    TracerDrawings[plr] = line
                end

                local targetPos = plr.Character.HumanoidRootPart.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)

                if onScreen then
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(screenPos.X, screenPos.Y)
                    line.Color = Settings.TracerColor
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                if TracerDrawings[plr] then
                    TracerDrawings[plr].Visible = false
                end
            end

            if Settings.Box3D and alive and Drawing then
                local lines = BoxDrawings[plr]
                if not lines then
                    lines = {}
                    for i = 1, 12 do
                        local l = Drawing.new("Line")
                        l.Thickness = 1.5
                        l.Transparency = 1
                        table.insert(lines, l)
                    end
                    BoxDrawings[plr] = lines
                end

                local root = plr.Character.HumanoidRootPart
                local cf = root.CFrame
                local size = Vector3.new(3, 5, 3)
                local verts = GetBoxVertices(cf, size)

                local screenVerts = {}
                local allOnScreen = true

                for i, v in ipairs(verts) do
                    local sPos, onScr = Camera:WorldToViewportPoint(v)
                    if not onScr then allOnScreen = false end
                    screenVerts[i] = Vector2.new(sPos.X, sPos.Y)
                end

                if allOnScreen then
                    for idx, edge in ipairs(BoxEdges) do
                        local l = lines[idx]
                        l.From = screenVerts[edge[1]]
                        l.To = screenVerts[edge[2]]
                        l.Color = Settings.BoxColor
                        l.Visible = true
                    end
                else
                    for _, l in ipairs(lines) do l.Visible = false end
                end
            else
                if BoxDrawings[plr] then
                    for _, l in ipairs(BoxDrawings[plr]) do l.Visible = false end
                end
            end
        end
    end
end)

Services.Players.PlayerRemoving:Connect(function(plr)
    if Highlights[plr] then
        pcall(function() Highlights[plr]:Destroy() end)
        Highlights[plr] = nil
    end
    if TracerDrawings[plr] then
        pcall(function() TracerDrawings[plr]:Remove() end)
        TracerDrawings[plr] = nil
    end
    if BoxDrawings[plr] then
        for _, l in ipairs(BoxDrawings[plr]) do
            pcall(function() l:Remove() end)
        end
        BoxDrawings[plr] = nil
    end
end)
