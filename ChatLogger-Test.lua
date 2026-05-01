-- Chat Logger v4 Fixed
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- ══════════════════════════════════
--  CLEANUP OLD INSTANCE
-- ══════════════════════════════════
if CoreGui:FindFirstChild("ChatLogger") then
    CoreGui:FindFirstChild("ChatLogger"):Destroy()
end

-- ══════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChatLogger"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ══════════════════════════════════
--  STATE VARIABLES (declared first)
-- ══════════════════════════════════
local windowOpen = false
local unread = 0
local msgCount = 0
local autoScroll = true
local activeTab = "All"
local sessionStart = os.time()

-- forward declarations
local ChatScroll
local SearchBarFrame
local PlayersPanel
local SearchBox

-- ══════════════════════════════════
--  COLORS
-- ══════════════════════════════════
local typeColors = {
    CHAT   = Color3.fromRGB(105, 172, 255),
    SENT   = Color3.fromRGB(80,  212, 140),
    SYSTEM = Color3.fromRGB(242, 192, 70),
    JOIN   = Color3.fromRGB(80,  240, 150),
    LEAVE  = Color3.fromRGB(240, 95,  95),
}

-- ══════════════════════════════════
--  TOGGLE BUTTON
-- ══════════════════════════════════
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(1, -65, 0, 20)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = ""
ToggleBtn.ZIndex = 50
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local ToggleIcon = Instance.new("ImageLabel")
ToggleIcon.Size = UDim2.new(1, 0, 1, 0)
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.Image = "rbxassetid://14895333462"
ToggleIcon.ScaleType = Enum.ScaleType.Fit
ToggleIcon.ZIndex = 51
ToggleIcon.Parent = ToggleBtn

local Badge = Instance.new("TextLabel")
Badge.Size = UDim2.new(0, 18, 0, 18)
Badge.Position = UDim2.new(1, -18, 0, -2)
Badge.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
Badge.TextColor3 = Color3.fromRGB(255, 255, 255)
Badge.Font = Enum.Font.GothamBold
Badge.TextSize = 9
Badge.Text = "0"
Badge.Visible = false
Badge.ZIndex = 55
Badge.Parent = ToggleBtn
Instance.new("UICorner", Badge).CornerRadius = UDim.new(1, 0)

-- ══════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 430, 0, 390)
Main.Position = UDim2.new(0.5, -215, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(13, 16, 26)
Main.BorderSizePixel = 0
Main.Visible = false
Main.ZIndex = 10
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local MS = Instance.new("UIStroke", Main)
MS.Color = Color3.fromRGB(50, 70, 190)
MS.Thickness = 1.2

-- ══════════════════════════════════
--  TITLE BAR
-- ══════════════════════════════════
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(17, 21, 34)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 11
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

-- fixes the rounded bottom corners of TitleBar bleeding through
local TFix = Instance.new("Frame")
TFix.Size = UDim2.new(1, 0, 0, 14)
TFix.Position = UDim2.new(0, 0, 1, -14)
TFix.BackgroundColor3 = Color3.fromRGB(17, 21, 34)
TFix.BorderSizePixel = 0
TFix.ZIndex = 11
TFix.Parent = TitleBar

local MyAv = Instance.new("ImageLabel")
MyAv.Size = UDim2.new(0, 30, 0, 30)
MyAv.Position = UDim2.new(0, 9, 0, 7)
MyAv.BackgroundColor3 = Color3.fromRGB(32, 38, 58)
MyAv.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="
    .. player.UserId .. "&width=48&height=48&format=png"
MyAv.ZIndex = 12
MyAv.Parent = TitleBar
Instance.new("UICorner", MyAv).CornerRadius = UDim.new(1, 0)

local AvS = Instance.new("UIStroke", MyAv)
AvS.Color = Color3.fromRGB(70, 100, 220)
AvS.Thickness = 1.5

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -50, 0, 18)
TitleLbl.Position = UDim2.new(0, 46, 0, 5)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "ChatLogger by DevillX"
TitleLbl.TextColor3 = Color3.fromRGB(195, 208, 255)
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 13
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 12
TitleLbl.Parent = TitleBar

-- safe game name fetch
local gameName = "Unknown Game"
pcall(function()
    gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

local GameLbl = Instance.new("TextLabel")
GameLbl.Size = UDim2.new(1, -50, 0, 12)
GameLbl.Position = UDim2.new(0, 46, 0, 26)
GameLbl.BackgroundTransparency = 1
GameLbl.Text = "📍 " .. gameName
GameLbl.TextColor3 = Color3.fromRGB(100, 118, 185)
GameLbl.Font = Enum.Font.Gotham
GameLbl.TextSize = 9
GameLbl.TextXAlignment = Enum.TextXAlignment.Left
GameLbl.ZIndex = 12
GameLbl.Parent = TitleBar

local OnlineDot = Instance.new("Frame")
OnlineDot.Size = UDim2.new(0, 8, 0, 8)
OnlineDot.Position = UDim2.new(0, 33, 0, 29)
OnlineDot.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
OnlineDot.BorderSizePixel = 0
OnlineDot.ZIndex = 14
OnlineDot.Parent = TitleBar
Instance.new("UICorner", OnlineDot).CornerRadius = UDim.new(1, 0)

-- ══════════════════════════════════
--  TAB BAR
-- ══════════════════════════════════
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 30)
TabBar.Position = UDim2.new(0, 8, 0, 48)
TabBar.BackgroundColor3 = Color3.fromRGB(17, 21, 34)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 11
TabBar.Parent = Main
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 3)

local TabPad = Instance.new("UIPadding", TabBar)
TabPad.PaddingLeft   = UDim.new(0, 4)
TabPad.PaddingTop    = UDim.new(0, 4)
TabPad.PaddingBottom = UDim.new(0, 4)

local tabs = {"All", "Chat", "System", "Search", "Players"}
local tabBtns = {}

-- ══════════════════════════════════
--  SEARCH BAR
-- ══════════════════════════════════
SearchBarFrame = Instance.new("Frame")
SearchBarFrame.Size = UDim2.new(1, -16, 0, 26)
SearchBarFrame.Position = UDim2.new(0, 8, 0, 82)
SearchBarFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
SearchBarFrame.BorderSizePixel = 0
SearchBarFrame.Visible = false
SearchBarFrame.ZIndex = 11
SearchBarFrame.Parent = Main
Instance.new("UICorner", SearchBarFrame).CornerRadius = UDim.new(0, 7)
Instance.new("UIStroke", SearchBarFrame).Color = Color3.fromRGB(45, 60, 155)

SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -12, 1, -4)
SearchBox.Position = UDim2.new(0, 6, 0, 2)
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "🔍  type to search..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(80, 95, 140)
SearchBox.TextColor3 = Color3.fromRGB(205, 215, 255)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 12
SearchBox.Parent = SearchBarFrame

-- ══════════════════════════════════
--  CHAT SCROLL
-- ══════════════════════════════════
ChatScroll = Instance.new("ScrollingFrame")
ChatScroll.Size = UDim2.new(1, -16, 1, -124)
ChatScroll.Position = UDim2.new(0, 8, 0, 82)
ChatScroll.BackgroundTransparency = 1
ChatScroll.BorderSizePixel = 0
ChatScroll.ScrollBarThickness = 3
ChatScroll.ScrollBarImageColor3 = Color3.fromRGB(65, 88, 200)
ChatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ChatScroll.ZIndex = 11
ChatScroll.Parent = Main

local ListLayout = Instance.new("UIListLayout", ChatScroll)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 4)

local SP = Instance.new("UIPadding", ChatScroll)
SP.PaddingTop    = UDim.new(0, 3)
SP.PaddingBottom = UDim.new(0, 3)
SP.PaddingLeft   = UDim.new(0, 2)
SP.PaddingRight  = UDim.new(0, 2)

-- ══════════════════════════════════
--  PLAYERS PANEL
-- ══════════════════════════════════
PlayersPanel = Instance.new("ScrollingFrame")
PlayersPanel.Size = UDim2.new(1, -16, 1, -124)
PlayersPanel.Position = UDim2.new(0, 8, 0, 82)
PlayersPanel.BackgroundTransparency = 1
PlayersPanel.BorderSizePixel = 0
PlayersPanel.ScrollBarThickness = 3
PlayersPanel.ScrollBarImageColor3 = Color3.fromRGB(65, 88, 200)
PlayersPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayersPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayersPanel.Visible = false
PlayersPanel.ZIndex = 11
PlayersPanel.Parent = Main

local PPLayout = Instance.new("UIListLayout", PlayersPanel)
PPLayout.SortOrder = Enum.SortOrder.LayoutOrder
PPLayout.Padding = UDim.new(0, 5)

local PPPad = Instance.new("UIPadding", PlayersPanel)
PPPad.PaddingTop   = UDim.new(0, 4)
PPPad.PaddingLeft  = UDim.new(0, 2)
PPPad.PaddingRight = UDim.new(0, 2)

-- ══════════════════════════════════
--  BOTTOM BAR
-- ══════════════════════════════════
local BotBar = Instance.new("Frame")
BotBar.Size = UDim2.new(1, -16, 0, 34)
BotBar.Position = UDim2.new(0, 8, 1, -40)
BotBar.BackgroundColor3 = Color3.fromRGB(17, 21, 34)
BotBar.BorderSizePixel = 0
BotBar.ZIndex = 11
BotBar.Parent = Main
Instance.new("UICorner", BotBar).CornerRadius = UDim.new(0, 9)

-- FIX: InfoLbl was positioned outside Main — now inside BotBar
local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size = UDim2.new(1, -16, 1, 0)
InfoLbl.Position = UDim2.new(0, 8, 0, 0)
InfoLbl.BackgroundTransparency = 1
InfoLbl.TextColor3 = Color3.fromRGB(80, 98, 150)
InfoLbl.Font = Enum.Font.Gotham
InfoLbl.TextSize = 9
InfoLbl.TextXAlignment = Enum.TextXAlignment.Right
InfoLbl.ZIndex = 12
InfoLbl.Parent = BotBar

local MsgCountLbl = Instance.new("TextLabel")
MsgCountLbl.Size = UDim2.new(0.35, 0, 1, 0)
MsgCountLbl.Position = UDim2.new(0, 10, 0, 0)
MsgCountLbl.BackgroundTransparency = 1
MsgCountLbl.Text = "0 msgs"
MsgCountLbl.TextColor3 = Color3.fromRGB(100, 118, 185)
MsgCountLbl.Font = Enum.Font.Gotham
MsgCountLbl.TextSize = 11
MsgCountLbl.TextXAlignment = Enum.TextXAlignment.Left
MsgCountLbl.ZIndex = 12
MsgCountLbl.Parent = BotBar

local PlayerCountLbl = Instance.new("TextLabel")
PlayerCountLbl.Size = UDim2.new(0.3, 0, 1, 0)
PlayerCountLbl.Position = UDim2.new(0.35, 0, 0, 0)
PlayerCountLbl.BackgroundTransparency = 1
PlayerCountLbl.Text = "👥 " .. #Players:GetPlayers()
PlayerCountLbl.TextColor3 = Color3.fromRGB(100, 118, 185)
PlayerCountLbl.Font = Enum.Font.Gotham
PlayerCountLbl.TextSize = 11
PlayerCountLbl.TextXAlignment = Enum.TextXAlignment.Center
PlayerCountLbl.ZIndex = 12
PlayerCountLbl.Parent = BotBar

-- FIX: AutoScrollDot repositioned so it doesn't overlap ClearBtn
local AutoScrollDot = Instance.new("Frame")
AutoScrollDot.Size = UDim2.new(0, 7, 0, 7)
AutoScrollDot.Position = UDim2.new(1, -72, 0.5, -3)
AutoScrollDot.BackgroundColor3 = Color3.fromRGB(75, 210, 125)
AutoScrollDot.ZIndex = 12
AutoScrollDot.Parent = BotBar
Instance.new("UICorner", AutoScrollDot).CornerRadius = UDim.new(1, 0)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 52, 0, 22)
ClearBtn.Position = UDim2.new(1, -58, 0.5, -11)
ClearBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 62)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(155, 170, 225)
ClearBtn.Font = Enum.Font.GothamSemibold
ClearBtn.TextSize = 11
ClearBtn.AutoButtonColor = false
ClearBtn.ZIndex = 12
ClearBtn.Parent = BotBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

ClearBtn.MouseEnter:Connect(function()
    TweenService:Create(ClearBtn, TweenInfo.new(0.12), {
        BackgroundColor3 = Color3.fromRGB(50, 60, 95)
    }):Play()
end)
ClearBtn.MouseLeave:Connect(function()
    TweenService:Create(ClearBtn, TweenInfo.new(0.12), {
        BackgroundColor3 = Color3.fromRGB(34, 40, 62)
    }):Play()
end)

-- ══════════════════════════════════
--  TAB LOGIC (after all panels exist)
-- ══════════════════════════════════
local function applyTabFilter()
    if not ChatScroll then return end
    local q = ""
    if activeTab == "Search" and SearchBox then
        q = SearchBox.Text:lower()
    end
    for _, row in ipairs(ChatScroll:GetChildren()) do
        if row:IsA("Frame") then
            local t  = row:GetAttribute("msgType") or "CHAT"
            local tx = (row:GetAttribute("msgText") or ""):lower()
            local sp = (row:GetAttribute("speaker") or ""):lower()
            if activeTab == "All" then
                row.Visible = true
            elseif activeTab == "Chat" then
                row.Visible = (t == "CHAT" or t == "SENT")
            elseif activeTab == "System" then
                row.Visible = (t == "SYSTEM" or t == "JOIN" or t == "LEAVE")
            elseif activeTab == "Search" then
                row.Visible = (q == "")
                    or (tx:find(q, 1, true) ~= nil)
                    or (sp:find(q, 1, true) ~= nil)
            else
                row.Visible = true
            end
        end
    end
end

local function setTab(name)
    activeTab = name
    for tname, btn in pairs(tabBtns) do
        local on = (tname == name)
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on
                and Color3.fromRGB(55, 78, 195)
                or  Color3.fromRGB(26, 32, 50)
        }):Play()
        btn.TextColor3 = on
            and Color3.fromRGB(235, 240, 255)
            or  Color3.fromRGB(115, 132, 185)
    end

    SearchBarFrame.Visible = (name == "Search")
    PlayersPanel.Visible   = (name == "Players")
    ChatScroll.Visible     = (name ~= "Players")

    -- shift ChatScroll down if search bar is showing
    if name == "Search" then
        ChatScroll.Position = UDim2.new(0, 8, 0, 114)
        ChatScroll.Size     = UDim2.new(1, -16, 1, -156)
    else
        ChatScroll.Position = UDim2.new(0, 8, 0, 82)
        ChatScroll.Size     = UDim2.new(1, -16, 1, -124)
    end

    applyTabFilter()
end

-- build tab buttons
for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 64, 1, 0)
    btn.BackgroundColor3 = (name == "All")
        and Color3.fromRGB(55, 78, 195)
        or  Color3.fromRGB(26, 32, 50)
    btn.Text = name
    btn.TextColor3 = (name == "All")
        and Color3.fromRGB(235, 240, 255)
        or  Color3.fromRGB(115, 132, 185)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.LayoutOrder = i
    btn.ZIndex = 12
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    tabBtns[name] = btn
    btn.MouseButton1Click:Connect(function()
        setTab(name)
    end)
end

-- hook search box after tabBtns exist
SearchBox:GetPropertyChangedSignal("Text"):Connect(applyTabFilter)

-- ══════════════════════════════════
--  HELPER: OPEN / CLOSE WINDOW
-- ══════════════════════════════════
local function openWindow()
    windowOpen = true
    Main.Visible = true
    Main.Position = UDim2.new(0.5, -215, 0.5, -195)
    unread = 0
    Badge.Visible = false
    Badge.Text = "0"
end

local function closeWindow()
    windowOpen = false
    Main.Visible = false
end

local function toggleWindow()
    if windowOpen then
        closeWindow()
    else
        openWindow()
    end
end

-- ══════════════════════════════════
--  UNREAD BADGE
-- ══════════════════════════════════
local function addUnread()
    if not windowOpen then
        unread += 1
        Badge.Text = unread > 99 and "99+" or tostring(unread)
        Badge.Visible = true
    end
end

-- ══════════════════════════════════
--  MESSAGE BUILDER
-- ══════════════════════════════════
local function formatMsg(msg)
    -- detect fully filtered/blocked messages
    if msg:match("^[%s▪]+$") or msg == "" then
        return "🔒 Filtered"
    end
    return msg
end

local function addMessage(speaker, userId, message, msgType)
    msgType = msgType or "CHAT"
    msgCount += 1
    MsgCountLbl.Text = msgCount .. " msgs"
    addUnread()

    local isSelf     = (userId ~= nil and userId == player.UserId)
    local ts         = os.date("%H:%M")
    local displayMsg = formatMsg(message)
    local isFiltered = (displayMsg == "🔒 Filtered")

    local Row = Instance.new("Frame")
    Row.BackgroundColor3 = isSelf
        and Color3.fromRGB(21, 34, 56)
        or  Color3.fromRGB(19, 23, 37)
    Row.BorderSizePixel = 0
    Row.LayoutOrder = msgCount
    Row.AutomaticSize = Enum.AutomaticSize.Y
    Row.Size = UDim2.new(1, -4, 0, 0)
    Row.ZIndex = 12
    -- FIX: slide in from right properly
    Row.Position = UDim2.new(1, 10, 0, 0)
    Row.Parent = ChatScroll

    Row:SetAttribute("msgType", msgType)
    Row:SetAttribute("msgText", displayMsg)
    Row:SetAttribute("speaker", speaker)

    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 9)

    -- slide-in tween
    TweenService:Create(Row, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    if isSelf then
        local st = Instance.new("UIStroke", Row)
        st.Color = Color3.fromRGB(45, 80, 175)
        st.Thickness = 1
    end

    local RP = Instance.new("UIPadding", Row)
    RP.PaddingLeft   = UDim.new(0, 8)
    RP.PaddingRight  = UDim.new(0, 8)
    RP.PaddingTop    = UDim.new(0, 6)
    RP.PaddingBottom = UDim.new(0, 6)

    -- avatar
    local Av = Instance.new("ImageLabel")
    Av.Size = UDim2.new(0, 28, 0, 28)
    Av.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
    Av.ZIndex = 13
    Av.Parent = Row
    Av.Image = (userId and userId > 0)
        and ("https://www.roblox.com/headshot-thumbnail/image?userId="
            .. userId .. "&width=48&height=48&format=png")
        or "rbxassetid://14895333462"
    Instance.new("UICorner", Av).CornerRadius = UDim.new(1, 0)

    -- speaker name
    local NameLbl = Instance.new("TextLabel")
    NameLbl.Size = UDim2.new(1, -85, 0, 14)
    NameLbl.Position = UDim2.new(0, 36, 0, 0)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Text = (isSelf and "⭐ " or "") .. speaker
    NameLbl.TextColor3 = isSelf
        and Color3.fromRGB(90, 180, 255)
        or  Color3.fromRGB(160, 182, 248)
    NameLbl.Font = Enum.Font.GothamBold
    NameLbl.TextSize = 11
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left
    NameLbl.ZIndex = 13
    NameLbl.Parent = Row

    -- timestamp + type
    local MetaLbl = Instance.new("TextLabel")
    MetaLbl.Size = UDim2.new(0, 78, 0, 14)
    MetaLbl.Position = UDim2.new(1, -78, 0, 0)
    MetaLbl.BackgroundTransparency = 1
    MetaLbl.Text = ts .. " [" .. msgType .. "]"
    MetaLbl.TextColor3 = typeColors[msgType] or Color3.fromRGB(140, 140, 170)
    MetaLbl.Font = Enum.Font.Gotham
    MetaLbl.TextSize = 9
    MetaLbl.TextXAlignment = Enum.TextXAlignment.Right
    MetaLbl.ZIndex = 13
    MetaLbl.Parent = Row

    -- message body
    local MsgLbl = Instance.new("TextLabel")
    MsgLbl.Size = UDim2.new(1, -70, 0, 0)
    MsgLbl.Position = UDim2.new(0, 36, 0, 16)
    MsgLbl.BackgroundTransparency = 1
    MsgLbl.Text = displayMsg
    MsgLbl.TextColor3 = isFiltered
        and Color3.fromRGB(105, 108, 138)
        or  Color3.fromRGB(200, 212, 245)
    MsgLbl.Font = isFiltered
        and Enum.Font.GothamItalic
        or  Enum.Font.Gotham
    MsgLbl.TextSize = 12
    MsgLbl.TextXAlignment = Enum.TextXAlignment.Left
    MsgLbl.TextWrapped = true
    MsgLbl.AutomaticSize = Enum.AutomaticSize.Y
    MsgLbl.ZIndex = 13
    MsgLbl.Parent = Row

    -- copy button (only for real chat messages)
    if not isFiltered
    and msgType ~= "SYSTEM"
    and msgType ~= "JOIN"
    and msgType ~= "LEAVE" then

        local CopyBtn = Instance.new("TextButton")
        CopyBtn.Size = UDim2.new(0, 28, 0, 16)
        CopyBtn.Position = UDim2.new(1, -28, 0, 16)
        CopyBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 75)
        CopyBtn.Text = "⎘"
        CopyBtn.TextColor3 = Color3.fromRGB(130, 155, 230)
        CopyBtn.Font = Enum.Font.GothamBold
        CopyBtn.TextSize = 11
        CopyBtn.AutoButtonColor = false
        CopyBtn.ZIndex = 14
        CopyBtn.Parent = Row
        Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 5)

        CopyBtn.MouseButton1Click:Connect(function()
            -- try both clipboard APIs (executor-dependent)
            local ok = pcall(function() setclipboard(message) end)
            if not ok then
                pcall(function() toclipboard(message) end)
            end
            -- visual feedback
            CopyBtn.Text = "✓"
            CopyBtn.TextColor3 = Color3.fromRGB(80, 220, 130)
            TweenService:Create(CopyBtn, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(30, 75, 50)
            }):Play()
            task.delay(1.2, function()
                if CopyBtn and CopyBtn.Parent then
                    CopyBtn.Text = "⎘"
                    CopyBtn.TextColor3 = Color3.fromRGB(130, 155, 230)
                    TweenService:Create(CopyBtn, TweenInfo.new(0.1), {
                        BackgroundColor3 = Color3.fromRGB(35, 45, 75)
                    }):Play()
                end
            end)
        end)

        CopyBtn.MouseEnter:Connect(function()
            TweenService:Create(CopyBtn, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(50, 65, 110)
            }):Play()
        end)
        CopyBtn.MouseLeave:Connect(function()
            TweenService:Create(CopyBtn, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(35, 45, 75)
            }):Play()
        end)
    end

    -- apply active tab filter to newly added row
    if activeTab == "Chat" then
        Row.Visible = (msgType == "CHAT" or msgType == "SENT")
    elseif activeTab == "System" then
        Row.Visible = (msgType == "SYSTEM" or msgType == "JOIN" or msgType == "LEAVE")
    elseif activeTab == "Search" then
        local q = SearchBox.Text:lower()
        Row.Visible = (q == "") or (displayMsg:lower():find(q, 1, true) ~= nil)
    else
        Row.Visible = true
    end

    -- auto scroll to bottom
    if autoScroll then
        task.defer(function()
            ChatScroll.CanvasPosition = Vector2.new(0, math.huge)
        end)
    end
end

-- ══════════════════════════════════
--  PLAYERS PANEL BUILDER
-- ══════════════════════════════════
local function getAgeGroup(plr)
    local ok, age = pcall(function() return plr.AccountAge end)
    if ok and age then
        if age < 365       then return "New"
        elseif age < 730   then return "1yr+"
        elseif age < 1825  then return "2yr+"
        else                    return "5yr+"
        end
    end
    return "?"
end

local function refreshPlayers()
    -- clear old rows
    for _, v in ipairs(PlayersPanel:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end

    local sorted = Players:GetPlayers()
    table.sort(sorted, function(a, b) return a.Name < b.Name end)

    for idx, plr in ipairs(sorted) do
        local isSelf   = (plr == player)
        local ageGroup = getAgeGroup(plr)

        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, -4, 0, 50)
        Row.BackgroundColor3 = isSelf
            and Color3.fromRGB(22, 36, 58)
            or  Color3.fromRGB(20, 24, 38)
        Row.BorderSizePixel = 0
        Row.LayoutOrder = idx
        Row.ZIndex = 12
        Row.Parent = PlayersPanel
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 9)

        local RP = Instance.new("UIPadding", Row)
        RP.PaddingLeft = UDim.new(0, 8)
        RP.PaddingTop  = UDim.new(0, 7)

        local Av = Instance.new("ImageLabel")
        Av.Size = UDim2.new(0, 32, 0, 32)
        Av.BackgroundColor3 = Color3.fromRGB(32, 38, 58)
        Av.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="
            .. plr.UserId .. "&width=48&height=48&format=png"
        Av.ZIndex = 13
        Av.Parent = Row
        Instance.new("UICorner", Av).CornerRadius = UDim.new(1, 0)

        local NLbl = Instance.new("TextLabel")
        NLbl.Size = UDim2.new(1, -90, 0, 15)
        NLbl.Position = UDim2.new(0, 40, 0, 0)
        NLbl.BackgroundTransparency = 1
        NLbl.Text = (isSelf and "⭐ " or "") .. plr.Name
        NLbl.TextColor3 = isSelf
            and Color3.fromRGB(95, 185, 255)
            or  Color3.fromRGB(170, 188, 250)
        NLbl.Font = Enum.Font.GothamBold
        NLbl.TextSize = 12
        NLbl.TextXAlignment = Enum.TextXAlignment.Left
        NLbl.ZIndex = 13
        NLbl.Parent = Row

        -- FIX: age pill position adjusted so it doesn't clip
        local AgePill = Instance.new("TextLabel")
        AgePill.Size = UDim2.new(0, 38, 0, 14)
        AgePill.Position = UDim2.new(0, 40, 0, 18)
        AgePill.BackgroundColor3 = Color3.fromRGB(35, 45, 75)
        AgePill.TextColor3 = Color3.fromRGB(130, 160, 240)
        AgePill.Font = Enum.Font.GothamBold
        AgePill.TextSize = 9
        AgePill.Text = "⏳ " .. ageGroup
        AgePill.ZIndex = 13
        AgePill.Parent = Row
        Instance.new("UICorner", AgePill).CornerRadius = UDim.new(0, 4)

        -- FIX: SubLbl (ID) moved right of AgePill, not on top of it
        local SubLbl = Instance.new("TextLabel")
        SubLbl.Size = UDim2.new(1, -100, 0, 13)
        SubLbl.Position = UDim2.new(0, 84, 0, 20)
        SubLbl.BackgroundTransparency = 1
        SubLbl.Text = "ID: " .. plr.UserId
        SubLbl.TextColor3 = Color3.fromRGB(80, 98, 150)
        SubLbl.Font = Enum.Font.Gotham
        SubLbl.TextSize = 9
        SubLbl.TextXAlignment = Enum.TextXAlignment.Left
        SubLbl.ZIndex = 13
        SubLbl.Parent = Row
    end
end

refreshPlayers()

Players.PlayerAdded:Connect(function()
    task.wait(0.1)
    refreshPlayers()
    PlayerCountLbl.Text = "👥 " .. #Players:GetPlayers()
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    refreshPlayers()
    PlayerCountLbl.Text = "👥 " .. #Players:GetPlayers()
end)

-- ══════════════════════════════════
--  CHAT CAPTURE
-- ══════════════════════════════════
local function hookPlayer(plr)
    plr.Chatted:Connect(function(msg)
        local mType = (plr == player) and "SENT" or "CHAT"
        addMessage(plr.Name, plr.UserId, msg, mType)
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    hookPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
    addMessage(plr.Name, plr.UserId, "joined the server", "JOIN")
    hookPlayer(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    addMessage(plr.Name, plr.UserId, "left the server", "LEAVE")
end)

-- TextChatService (new chat system) hook
pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.MessageReceived:Connect(function(msg)
            local speaker = msg.TextSource and msg.TextSource.Name or "System"
            local plr = Players:FindFirstChild(speaker)
            -- only log if we didn't already catch via Chatted
            if not plr then
                addMessage(speaker, 0, msg.Text or "", "SYSTEM")
            end
        end)
    end
end)

-- startup message
addMessage("System", 0,
    "Chat Logger active — click ⎘ to copy  |  RightShift to toggle",
    "SYSTEM")

-- ══════════════════════════════════
--  WINDOW DRAG
-- ══════════════════════════════════
local isDragging = false
local dragStart  = nil
local winStart   = nil

TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart  = inp.Position
        winStart   = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if isDragging and dragStart
    and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        Main.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + d.X,
            winStart.Y.Scale, winStart.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        dragStart  = nil
    end
end)

-- ══════════════════════════════════
--  TOGGLE BUTTON DRAG + CLICK
-- ══════════════════════════════════
local togDragging = false
local togDragStart = nil
local togStartPos = nil

ToggleBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        togDragging  = false
        togDragStart = inp.Position
        togStartPos  = ToggleBtn.Position
    end
end)

ToggleBtn.InputChanged:Connect(function(inp)
    if togDragStart == nil then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local delta = inp.Position - togDragStart
        if delta.Magnitude > 8 then
            togDragging = true
        end
        if togDragging then
            ToggleBtn.Position = UDim2.new(
                togStartPos.X.Scale, togStartPos.X.Offset + delta.X,
                togStartPos.Y.Scale, togStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

ToggleBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        local wasDrag = togDragging
        -- FIX: always reset drag state
        togDragging  = false
        togDragStart = nil
        togStartPos  = nil
        if not wasDrag then
            toggleWindow()
        end
    end
end)

-- ══════════════════════════════════
--  AUTO SCROLL DETECTION
-- ══════════════════════════════════
ChatScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    local atBottom = ChatScroll.CanvasPosition.Y
        >= (ChatScroll.AbsoluteCanvasSize.Y - ChatScroll.AbsoluteSize.Y - 12)
    autoScroll = atBottom
    TweenService:Create(AutoScrollDot, TweenInfo.new(0.2), {
        BackgroundColor3 = autoScroll
            and Color3.fromRGB(75, 210, 125)
            or  Color3.fromRGB(240, 150, 50)
    }):Play()
end)

-- ══════════════════════════════════
--  CLEAR BUTTON
-- ══════════════════════════════════
ClearBtn.MouseButton1Click:Connect(function()
    for _, v in ipairs(ChatScroll:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    msgCount = 0
    MsgCountLbl.Text = "0 msgs"
    addMessage("System", 0, "Log cleared", "SYSTEM")
end)

-- ══════════════════════════════════
--  KEYBOARD SHORTCUT
-- ══════════════════════════════════
UserInputService.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == Enum.KeyCode.RightShift then
        toggleWindow()
    end
end)

-- ══════════════════════════════════
--  SESSION TIMER + FPS + PING
-- ══════════════════════════════════
-- FIX: use lastFps updated each heartbeat instead of yielding inside loop
local lastFps = 0
local fpsAccum = 0
local fpsFrames = 0

RunService.Heartbeat:Connect(function(dt)
    fpsAccum  += dt
    fpsFrames += 1
    if fpsAccum >= 0.5 then
        lastFps   = math.round(fpsFrames / fpsAccum)
        fpsAccum  = 0
        fpsFrames = 0
    end
end)

task.spawn(function()
    while task.wait(1) do
        local secs   = os.time() - sessionStart
        local mins   = math.floor(secs / 60)
        local hrs    = math.floor(mins / 60)
        local timeStr = string.format("%02d:%02d:%02d", hrs, mins % 60, secs % 60)

        local ping = 0
        pcall(function()
            ping = math.floor(
                Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            )
        end)

        InfoLbl.Text = "⏱ " .. timeStr
            .. "   FPS " .. lastFps
            .. "   🌐 " .. ping .. "ms"
    end
end)

print("✅ Chat Logger v4 Fixed — RightShift or click icon to open")