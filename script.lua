--[[
    ╔════════════════════════════════════════════╗
    ║  GAME EXPLORER - DELTA ANDROID             ║
    ║  Scans: Workspace, Players, Remotes, etc.  ║
    ║  Version: 3.0                              ║
    ╚════════════════════════════════════════════╝
--]]

-- Anti-reload
if getgenv().__EXPLORER then return end
getgenv().__EXPLORER = true

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- ============================================
-- DATA STORAGE
-- ============================================
local GameData = {
    GameInfo = {},
    Remotes = {},
    ProximityPrompts = {},
    NPCs = {},
    Items = {},
    Tools = {},
    Folders = {},
    Values = {},
    Players = {},
    Attributes = {}
}

-- ============================================
-- SCAN FUNCTIONS
-- ============================================

-- Get Game Info
local function ScanGameInfo()
    local info = {}
    
    pcall(function()
        local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        info.GameName = productInfo.Name
        info.GameDescription = productInfo.Description
        info.Creator = productInfo.Creator.Name
    end)
    
    info.PlaceId = game.PlaceId
    info.GameId = game.GameId
    info.JobId = game.JobId
    info.PlayerCount = #Players:GetPlayers()
    
    GameData.GameInfo = info
    return info
end

-- Scan ALL RemoteEvents and RemoteFunctions
local function ScanRemotes()
    local remotes = {}
    
    -- Scan all services
    local servicesToScan = {
        ReplicatedStorage,
        ReplicatedFirst,
        Workspace,
        Player.PlayerGui,
        Lighting,
        StarterGui,
        StarterPack
    }
    
    for _, service in pairs(servicesToScan) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    table.insert(remotes, {
                        Name = obj.Name,
                        Type = "RemoteEvent",
                        Path = obj:GetFullName(),
                        Parent = obj.Parent.Name
                    })
                elseif obj:IsA("RemoteFunction") then
                    table.insert(remotes, {
                        Name = obj.Name,
                        Type = "RemoteFunction",
                        Path = obj:GetFullName(),
                        Parent = obj.Parent.Name
                    })
                elseif obj:IsA("BindableEvent") then
                    table.insert(remotes, {
                        Name = obj.Name,
                        Type = "BindableEvent",
                        Path = obj:GetFullName(),
                        Parent = obj.Parent.Name
                    })
                elseif obj:IsA("BindableFunction") then
                    table.insert(remotes, {
                        Name = obj.Name,
                        Type = "BindableFunction",
                        Path = obj:GetFullName(),
                        Parent = obj.Parent.Name
                    })
                end
            end
        end)
    end
    
    GameData.Remotes = remotes
    return remotes
end

-- Scan ALL ProximityPrompts
local function ScanPrompts()
    local prompts = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ProximityPrompt") then
                table.insert(prompts, {
                    ActionText = obj.ActionText,
                    ObjectText = obj.ObjectText,
                    HoldDuration = obj.HoldDuration,
                    Parent = obj.Parent.Name,
                    Path = obj:GetFullName()
                })
            end
        end)
    end
    
    GameData.ProximityPrompts = prompts
    return prompts
end

-- Scan ALL NPCs/Humanoids
local function ScanNPCs()
    local npcs = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Humanoid") and obj.Parent ~= Player.Character then
                local model = obj.Parent
                local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
                
                table.insert(npcs, {
                    Name = model.Name,
                    Health = obj.Health,
                    MaxHealth = obj.MaxHealth,
                    WalkSpeed = obj.WalkSpeed,
                    HasRoot = hrp and true or false,
                    Path = model:GetFullName()
                })
            end
        end)
    end
    
    GameData.NPCs = npcs
    return npcs
end

-- Scan ALL Collectible Items
local function ScanItems()
    local items = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            -- Has ProximityPrompt = collectible
            if obj:IsA("BasePart") and obj:FindFirstChild("ProximityPrompt") then
                table.insert(items, {
                    Name = obj.Name,
                    ClassName = obj.ClassName,
                    Position = tostring(obj.Position),
                    Path = obj:GetFullName()
                })
            end
            
            -- Has ClickDetector = clickable
            if obj:IsA("BasePart") and obj:FindFirstChild("ClickDetector") then
                table.insert(items, {
                    Name = obj.Name,
                    ClassName = obj.ClassName,
                    Type = "Clickable",
                    Path = obj:GetFullName()
                })
            end
            
            -- Has TouchInterest = touchable
            if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
                table.insert(items, {
                    Name = obj.Name,
                    ClassName = obj.ClassName,
                    Type = "Touchable",
                    Path = obj:GetFullName()
                })
            end
        end)
    end
    
    GameData.Items = items
    return items
end

-- Scan ALL Tools
local function ScanTools()
    local tools = {}
    
    -- StarterPack tools
    pcall(function()
        for _, obj in pairs(StarterPack:GetChildren()) do
            if obj:IsA("Tool") then
                table.insert(tools, {
                    Name = obj.Name,
                    Location = "StarterPack",
                    Path = obj:GetFullName()
                })
            end
        end
    end)
    
    -- Player backpack
    pcall(function()
        for _, obj in pairs(Player.Backpack:GetChildren()) do
            if obj:IsA("Tool") then
                table.insert(tools, {
                    Name = obj.Name,
                    Location = "Backpack",
                    Path = obj:GetFullName()
                })
            end
        end
    end)
    
    -- Workspace tools
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Tool") then
                table.insert(tools, {
                    Name = obj.Name,
                    Location = "Workspace",
                    Path = obj:GetFullName()
                })
            end
        end)
    end
    
    GameData.Tools = tools
    return tools
end

-- Scan ALL Folders
local function ScanFolders()
    local folders = {}
    
    local servicesToScan = {
        {Name = "Workspace", Service = Workspace},
        {Name = "ReplicatedStorage", Service = ReplicatedStorage},
        {Name = "ReplicatedFirst", Service = ReplicatedFirst},
        {Name = "Lighting", Service = Lighting}
    }
    
    for _, data in pairs(servicesToScan) do
        pcall(function()
            for _, obj in pairs(data.Service:GetDescendants()) do
                if obj:IsA("Folder") then
                    table.insert(folders, {
                        Name = obj.Name,
                        Service = data.Name,
                        ChildCount = #obj:GetChildren(),
                        Path = obj:GetFullName()
                    })
                end
            end
        end)
    end
    
    GameData.Folders = folders
    return folders
end

-- Scan ALL Values (IntValue, StringValue, etc.)
local function ScanValues()
    local values = {}
    
    local servicesToScan = {ReplicatedStorage, Player, Workspace, Lighting}
    
    for _, service in pairs(servicesToScan) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") then
                    table.insert(values, {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Value = tostring(obj.Value),
                        Path = obj:GetFullName()
                    })
                end
            end
        end)
    end
    
    GameData.Values = values
    return values
end

-- Scan ALL Players
local function ScanPlayers()
    local playerList = {}
    
    for _, plr in pairs(Players:GetPlayers()) do
        pcall(function()
            local data = {
                Name = plr.Name,
                DisplayName = plr.DisplayName,
                UserId = plr.UserId,
                Team = plr.Team and plr.Team.Name or "None",
                IsLocal = plr == Player
            }
            
            -- Scan player values
            data.Values = {}
            for _, obj in pairs(plr:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("NumberValue") then
                    data.Values[obj.Name] = tostring(obj.Value)
                end
            end
            
            -- Scan player attributes
            data.Attributes = plr:GetAttributes()
            
            table.insert(playerList, data)
        end)
    end
    
    GameData.Players = playerList
    return playerList
end

-- Scan ALL Attributes in game
local function ScanAttributes()
    local attrs = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            local objAttrs = obj:GetAttributes()
            if next(objAttrs) then
                table.insert(attrs, {
                    Object = obj.Name,
                    Path = obj:GetFullName(),
                    Attributes = objAttrs
                })
            end
        end)
    end
    
    GameData.Attributes = attrs
    return attrs
end

-- ============================================
-- PRINT FUNCTIONS
-- ============================================

local function PrintLine()
    print("════════════════════════════════════════")
end

local function PrintHeader(title)
    print("")
    PrintLine()
    print("  " .. title)
    PrintLine()
end

local function PrintGameInfo()
    PrintHeader("📱 GAME INFO")
    local info = ScanGameInfo()
    print("  Game Name: " .. (info.GameName or "Unknown"))
    print("  Place ID: " .. info.PlaceId)
    print("  Game ID: " .. info.GameId)
    print("  Creator: " .. (info.Creator or "Unknown"))
    print("  Players: " .. info.PlayerCount)
end

local function PrintRemotes()
    PrintHeader("📡 REMOTES (" .. #GameData.Remotes .. " found)")
    
    local remotes = ScanRemotes()
    for i, remote in pairs(remotes) do
        if i <= 30 then
            print("  [" .. remote.Type .. "] " .. remote.Name)
            print("    └ " .. remote.Path)
        end
    end
    
    if #remotes > 30 then
        print("  ... and " .. (#remotes - 30) .. " more")
    end
end

local function PrintPrompts()
    PrintHeader("🎯 PROXIMITY PROMPTS (" .. #GameData.ProximityPrompts .. " found)")
    
    local prompts = ScanPrompts()
    for i, prompt in pairs(prompts) do
        if i <= 20 then
            print("  " .. prompt.Parent)
            print("    └ Action: " .. (prompt.ActionText or "Interact"))
        end
    end
end

local function PrintNPCs()
    PrintHeader("👤 NPCs/HUMANOIDS (" .. #GameData.NPCs .. " found)")
    
    local npcs = ScanNPCs()
    for i, npc in pairs(npcs) do
        if i <= 20 then
            print("  " .. npc.Name)
            print("    └ HP: " .. math.floor(npc.Health) .. "/" .. math.floor(npc.MaxHealth))
        end
    end
end

local function PrintItems()
    PrintHeader("💎 COLLECTIBLE ITEMS (" .. #GameData.Items .. " found)")
    
    local items = ScanItems()
    for i, item in pairs(items) do
        if i <= 20 then
            print("  " .. item.Name .. " [" .. item.ClassName .. "]")
        end
    end
end

local function PrintTools()
    PrintHeader("🔧 TOOLS (" .. #GameData.Tools .. " found)")
    
    local tools = ScanTools()
    for i, tool in pairs(tools) do
        if i <= 15 then
            print("  " .. tool.Name .. " (" .. tool.Location .. ")")
        end
    end
end

local function PrintFolders()
    PrintHeader("📁 FOLDERS (" .. #GameData.Folders .. " found)")
    
    local folders = ScanFolders()
    for i, folder in pairs(folders) do
        if i <= 20 then
            print("  " .. folder.Name .. " [" .. folder.Service .. "] (" .. folder.ChildCount .. " children)")
        end
    end
end

local function PrintValues()
    PrintHeader("📊 VALUES (" .. #GameData.Values .. " found)")
    
    local values = ScanValues()
    for i, val in pairs(values) do
        if i <= 20 then
            print("  " .. val.Name .. " = " .. val.Value .. " [" .. val.Type .. "]")
        end
    end
end

local function PrintPlayers()
    PrintHeader("👥 PLAYERS (" .. #GameData.Players .. " found)")
    
    local players = ScanPlayers()
    for i, plr in pairs(players) do
        print("  " .. plr.Name .. (plr.IsLocal and " (YOU)" or ""))
        print("    └ Team: " .. plr.Team)
        
        -- Show player values
        if next(plr.Values) then
            for name, val in pairs(plr.Values) do
                print("    └ " .. name .. ": " .. val)
            end
        end
    end
end

local function PrintAttributes()
    PrintHeader("🏷️ ATTRIBUTES (" .. #GameData.Attributes .. " found)")
    
    local attrs = ScanAttributes()
    for i, data in pairs(attrs) do
        if i <= 15 then
            print("  " .. data.Object)
            for name, val in pairs(data.Attributes) do
                print("    └ " .. name .. " = " .. tostring(val))
            end
        end
    end
end

-- FULL SCAN
local function FullScan()
    print("")
    print("╔════════════════════════════════════════╗")
    print("║        FULL GAME SCAN STARTED          ║")
    print("╚════════════════════════════════════════╝")
    
    PrintGameInfo()
    PrintRemotes()
    PrintPrompts()
    PrintNPCs()
    PrintItems()
    PrintTools()
    PrintFolders()
    PrintValues()
    PrintPlayers()
    PrintAttributes()
    
    print("")
    PrintLine()
    print("  ✅ SCAN COMPLETE!")
    PrintLine()
    print("")
end

-- ============================================
-- SAVE FUNCTION
-- ============================================
local function SaveToFile()
    if not writefile then
        print("❌ Cannot save - writefile not available")
        return
    end
    
    -- Refresh all data
    ScanGameInfo()
    ScanRemotes()
    ScanPrompts()
    ScanNPCs()
    ScanItems()
    ScanTools()
    ScanFolders()
    ScanValues()
    ScanPlayers()
    ScanAttributes()
    
    -- Create filename
    local filename = "GameScan_" .. game.PlaceId .. ".json"
    
    -- Save
    local json = HttpService:JSONEncode(GameData)
    writefile(filename, json)
    
    print("✅ Saved to: " .. filename)
end

-- ============================================
-- CREATE UI
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExplorerUI"
ScreenGui.ResetOnSpawn = false

pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game:GetService("CoreGui")
    else
        ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    end
end)

-- Main Frame
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 170, 0, 400)
Main.Position = UDim2.new(0, 10, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Title.Text = "🔍 Explorer"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Button creator
local yPos = 40
local function AddButton(name, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 28)
    btn.Position = UDim2.new(0, 8, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    yPos = yPos + 32
    return btn
end

-- Buttons
AddButton("📱 Game Info", Color3.fromRGB(60, 60, 80), PrintGameInfo)
AddButton("📡 Remotes", Color3.fromRGB(80, 60, 60), function() ScanRemotes() PrintRemotes() end)
AddButton("🎯 Prompts", Color3.fromRGB(60, 80, 60), function() ScanPrompts() PrintPrompts() end)
AddButton("👤 NPCs", Color3.fromRGB(80, 80, 60), function() ScanNPCs() PrintNPCs() end)
AddButton("💎 Items", Color3.fromRGB(60, 60, 100), function() ScanItems() PrintItems() end)
AddButton("🔧 Tools", Color3.fromRGB(100, 60, 60), function() ScanTools() PrintTools() end)
AddButton("📁 Folders", Color3.fromRGB(60, 100, 60), function() ScanFolders() PrintFolders() end)
AddButton("📊 Values", Color3.fromRGB(100, 80, 60), function() ScanValues() PrintValues() end)
AddButton("👥 Players", Color3.fromRGB(80, 60, 100), function() ScanPlayers() PrintPlayers() end)
AddButton("🏷️ Attributes", Color3.fromRGB(60, 80, 100), function() ScanAttributes() PrintAttributes() end)
AddButton("🔄 FULL SCAN", Color3.fromRGB(50, 150, 50), FullScan)
AddButton("💾 SAVE FILE", Color3.fromRGB(150, 100, 50), SaveToFile)

-- Draggable
local dragging, dragStart, startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Title.InputEnded:Connect(function()
    dragging = false
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ============================================
-- INIT
-- ============================================
print("")
print("╔════════════════════════════════════════╗")
print("║     GAME EXPLORER LOADED!              ║")
print("╠════════════════════════════════════════╣")
print("║  Use UI buttons to scan game           ║")
print("║  Check console for results             ║")
print("║  Tap FULL SCAN for everything          ║")
print("║  Tap SAVE FILE to save data            ║")
print("╚════════════════════════════════════════╝")
print("")
