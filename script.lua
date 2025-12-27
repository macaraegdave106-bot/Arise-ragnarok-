--[[
    GAME EXPLORER + AUTO SAVE TO FILE
    Saves all console output to text file
]]

-- Anti-reload
if getgenv().__EXPLORER then return end
getgenv().__EXPLORER = true

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local StarterPack = game:GetService("StarterPack")

local Player = Players.LocalPlayer

-- ============================================
-- OUTPUT STORAGE (This saves everything)
-- ============================================
local OutputText = ""

local function Log(text)
    text = text or ""
    print(text)
    OutputText = OutputText .. text .. "\n"
end

local function LogLine()
    Log("════════════════════════════════════════════════════════")
end

local function LogHeader(title)
    Log("")
    LogLine()
    Log("  " .. title)
    LogLine()
end

-- ============================================
-- SCAN FUNCTIONS
-- ============================================

local function ScanGameInfo()
    LogHeader("📱 GAME INFORMATION")
    
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        Log("  Game Name: " .. (info.Name or "Unknown"))
        Log("  Creator: " .. (info.Creator.Name or "Unknown"))
        Log("  Description: " .. string.sub(info.Description or "", 1, 100))
    end)
    
    Log("  Place ID: " .. game.PlaceId)
    Log("  Game ID: " .. game.GameId)
    Log("  Job ID: " .. game.JobId)
    Log("  Player Count: " .. #Players:GetPlayers())
    Log("  Your Name: " .. Player.Name)
end

local function ScanRemotes()
    LogHeader("📡 ALL REMOTES (RemoteEvents & RemoteFunctions)")
    
    local count = 0
    local services = {ReplicatedStorage, ReplicatedFirst, Workspace, Lighting}
    
    for _, service in pairs(services) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    count = count + 1
                    Log("  [RemoteEvent] " .. obj.Name)
                    Log("    Path: " .. obj:GetFullName())
                    Log("")
                elseif obj:IsA("RemoteFunction") then
                    count = count + 1
                    Log("  [RemoteFunction] " .. obj.Name)
                    Log("    Path: " .. obj:GetFullName())
                    Log("")
                elseif obj:IsA("BindableEvent") then
                    count = count + 1
                    Log("  [BindableEvent] " .. obj.Name)
                    Log("    Path: " .. obj:GetFullName())
                    Log("")
                elseif obj:IsA("BindableFunction") then
                    count = count + 1
                    Log("  [BindableFunction] " .. obj.Name)
                    Log("    Path: " .. obj:GetFullName())
                    Log("")
                end
            end
        end)
    end
    
    Log("  TOTAL REMOTES: " .. count)
end

local function ScanPrompts()
    LogHeader("🎯 ALL PROXIMITY PROMPTS (Collectibles)")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ProximityPrompt") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Parent.Name)
                Log("    Action: " .. (obj.ActionText ~= "" and obj.ActionText or "Interact"))
                Log("    Object: " .. (obj.ObjectText ~= "" and obj.ObjectText or "None"))
                Log("    Hold: " .. obj.HoldDuration .. " seconds")
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL PROMPTS: " .. count)
end

local function ScanNPCs()
    LogHeader("👤 ALL NPCs & HUMANOIDS")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Humanoid") and obj.Parent ~= Player.Character then
                count = count + 1
                local model = obj.Parent
                local hrp = model:FindFirstChild("HumanoidRootPart")
                
                Log("  " .. count .. ". " .. model.Name)
                Log("    Health: " .. math.floor(obj.Health) .. "/" .. math.floor(obj.MaxHealth))
                Log("    WalkSpeed: " .. obj.WalkSpeed)
                Log("    Has Root: " .. (hrp and "Yes" or "No"))
                Log("    Path: " .. model:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL NPCs: " .. count)
end

local function ScanItems()
    LogHeader("💎 ALL COLLECTIBLE ITEMS")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            local hasPrompt = obj:FindFirstChild("ProximityPrompt")
            local hasClick = obj:FindFirstChild("ClickDetector")
            local hasTouch = obj:FindFirstChild("TouchInterest")
            
            if obj:IsA("BasePart") and (hasPrompt or hasClick or hasTouch) then
                count = count + 1
                local interactType = hasPrompt and "ProximityPrompt" or (hasClick and "ClickDetector" or "TouchInterest")
                
                Log("  " .. count .. ". " .. obj.Name)
                Log("    Class: " .. obj.ClassName)
                Log("    Interact: " .. interactType)
                Log("    Position: " .. tostring(obj.Position))
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL ITEMS: " .. count)
end

local function ScanTools()
    LogHeader("🔧 ALL TOOLS & WEAPONS")
    
    local count = 0
    
    -- StarterPack
    pcall(function()
        for _, obj in pairs(StarterPack:GetChildren()) do
            if obj:IsA("Tool") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name)
                Log("    Location: StarterPack")
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end
    end)
    
    -- Backpack
    pcall(function()
        for _, obj in pairs(Player.Backpack:GetChildren()) do
            if obj:IsA("Tool") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name)
                Log("    Location: Backpack")
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end
    end)
    
    -- Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Tool") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name)
                Log("    Location: Workspace")
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL TOOLS: " .. count)
end

local function ScanFolders()
    LogHeader("📁 ALL FOLDERS")
    
    local count = 0
    local services = {
        {Name = "Workspace", Service = Workspace},
        {Name = "ReplicatedStorage", Service = ReplicatedStorage},
        {Name = "ReplicatedFirst", Service = ReplicatedFirst},
        {Name = "Lighting", Service = Lighting}
    }
    
    for _, data in pairs(services) do
        pcall(function()
            for _, obj in pairs(data.Service:GetDescendants()) do
                if obj:IsA("Folder") then
                    count = count + 1
                    Log("  " .. count .. ". " .. obj.Name)
                    Log("    Service: " .. data.Name)
                    Log("    Children: " .. #obj:GetChildren())
                    Log("    Path: " .. obj:GetFullName())
                    Log("")
                end
            end
        end)
    end
    
    Log("  TOTAL FOLDERS: " .. count)
end

local function ScanValues()
    LogHeader("📊 ALL VALUES (IntValue, StringValue, etc.)")
    
    local count = 0
    local services = {ReplicatedStorage, Player, Workspace, Lighting}
    
    for _, service in pairs(services) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") then
                    count = count + 1
                    Log("  " .. count .. ". " .. obj.Name)
                    Log("    Type: " .. obj.ClassName)
                    Log("    Value: " .. tostring(obj.Value))
                    Log("    Path: " .. obj:GetFullName())
                    Log("")
                end
            end
        end)
    end
    
    Log("  TOTAL VALUES: " .. count)
end

local function ScanPlayers()
    LogHeader("👥 ALL PLAYERS")
    
    for i, plr in pairs(Players:GetPlayers()) do
        pcall(function()
            Log("  " .. i .. ". " .. plr.Name .. (plr == Player and " (YOU)" or ""))
            Log("    Display: " .. plr.DisplayName)
            Log("    UserId: " .. plr.UserId)
            Log("    Team: " .. (plr.Team and plr.Team.Name or "None"))
            
            -- Player values
            local valCount = 0
            for _, obj in pairs(plr:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("NumberValue") then
                    valCount = valCount + 1
                    Log("    [" .. obj.ClassName .. "] " .. obj.Name .. " = " .. tostring(obj.Value))
                end
            end
            
            -- Player attributes
            local attrs = plr:GetAttributes()
            for name, val in pairs(attrs) do
                Log("    [Attribute] " .. name .. " = " .. tostring(val))
            end
            
            Log("")
        end)
    end
end

local function ScanAttributes()
    LogHeader("🏷️ ALL ATTRIBUTES")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            local attrs = obj:GetAttributes()
            if next(attrs) then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name)
                Log("    Path: " .. obj:GetFullName())
                for name, val in pairs(attrs) do
                    Log("    " .. name .. " = " .. tostring(val))
                end
                Log("")
            end
        end)
    end
    
    Log("  TOTAL OBJECTS WITH ATTRIBUTES: " .. count)
end

local function ScanWorkspaceStructure()
    LogHeader("🌍 WORKSPACE STRUCTURE (Top Level)")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetChildren()) do
        count = count + 1
        local childCount = 0
        pcall(function() childCount = #obj:GetDescendants() end)
        
        Log("  " .. count .. ". " .. obj.Name)
        Log("    Class: " .. obj.ClassName)
        Log("    Descendants: " .. childCount)
        Log("")
    end
    
    Log("  TOTAL TOP-LEVEL OBJECTS: " .. count)
end

local function ScanReplicatedStructure()
    LogHeader("📦 REPLICATED STORAGE STRUCTURE")
    
    local count = 0
    
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        count = count + 1
        local childCount = 0
        pcall(function() childCount = #obj:GetDescendants() end)
        
        Log("  " .. count .. ". " .. obj.Name)
        Log("    Class: " .. obj.ClassName)
        Log("    Descendants: " .. childCount)
        Log("")
    end
    
    Log("  TOTAL: " .. count)
end

-- ============================================
-- FULL SCAN
-- ============================================
local function FullScan()
    OutputText = "" -- Reset
    
    Log("")
    Log("╔═══════════════════════════════════════════════════════╗")
    Log("║           FULL GAME SCAN - DELTA EXPLORER             ║")
    Log("║           Scan Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "            ║")
    Log("╚═══════════════════════════════════════════════════════╝")
    
    ScanGameInfo()
    ScanWorkspaceStructure()
    ScanReplicatedStructure()
    ScanRemotes()
    ScanPrompts()
    ScanNPCs()
    ScanItems()
    ScanTools()
    ScanFolders()
    ScanValues()
    ScanPlayers()
    ScanAttributes()
    
    Log("")
    LogLine()
    Log("  ✅ FULL SCAN COMPLETE!")
    Log("  Total Output Lines: " .. #OutputText:split("\n"))
    LogLine()
    Log("")
    
    return OutputText
end

-- ============================================
-- SAVE FUNCTIONS
-- ============================================
local function SaveToFile()
    if not writefile then
        Log("❌ ERROR: writefile not available on this executor")
        Log("Use COPY TO CLIPBOARD instead")
        return false
    end
    
    -- Create filename
    local gameName = "Game"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name:gsub("[^%w]", "_")
    end)
    
    local filename = "Scan_" .. gameName .. "_" .. game.PlaceId .. ".txt"
    
    -- Save
    pcall(function()
        writefile(filename, OutputText)
    end)
    
    Log("")
    Log("════════════════════════════════════════════════════════")
    Log("  ✅ SAVED TO FILE: " .. filename)
    Log("════════════════════════════════════════════════════════")
    Log("")
    
    return true
end

local function CopyToClipboard()
    if setclipboard then
        setclipboard(OutputText)
        Log("")
        Log("════════════════════════════════════════════════════════")
        Log("  ✅ COPIED TO CLIPBOARD!")
        Log("  Open any notes app and PASTE")
        Log("════════════════════════════════════════════════════════")
        Log("")
        return true
    else
        Log("❌ ERROR: setclipboard not available")
        return false
    end
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
Main.Size = UDim2.new(0, 180, 0, 440)
Main.Position = UDim2.new(0, 10, 0.15, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
Title.Text = "🔍 Game Explorer"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Status
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -10, 0, 20)
Status.Position = UDim2.new(0, 5, 0, 38)
Status.BackgroundTransparency = 1
Status.Text = "Ready to scan"
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.TextSize = 10
Status.Font = Enum.Font.Gotham
Status.Parent = Main

-- Button creator
local yPos = 60
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
    
    btn.MouseButton1Click:Connect(function()
        Status.Text = "Working..."
        task.wait(0.1)
        callback()
        Status.Text = "Done!"
    end)
    
    yPos = yPos + 31
    return btn
end

-- Scan Buttons
AddButton("📱 Game Info", Color3.fromRGB(60, 60, 80), function() OutputText = "" ScanGameInfo() end)
AddButton("📡 Remotes", Color3.fromRGB(80, 50, 50), function() OutputText = "" ScanRemotes() end)
AddButton("🎯 Prompts", Color3.fromRGB(50, 80, 50), function() OutputText = "" ScanPrompts() end)
AddButton("👤 NPCs", Color3.fromRGB(80, 70, 50), function() OutputText = "" ScanNPCs() end)
AddButton("💎 Items", Color3.fromRGB(50, 50, 90), function() OutputText = "" ScanItems() end)
AddButton("📁 Folders", Color3.fromRGB(50, 70, 70), function() OutputText = "" ScanFolders() end)
AddButton("📊 Values", Color3.fromRGB(70, 60, 80), function() OutputText = "" ScanValues() end)
AddButton("👥 Players", Color3.fromRGB(70, 50, 80), function() OutputText = "" ScanPlayers() end)

-- Main Actions
AddButton("🔄 FULL SCAN", Color3.fromRGB(50, 120, 50), FullScan)
AddButton("💾 SAVE FILE", Color3.fromRGB(120, 80, 40), SaveToFile)
AddButton("📋 COPY ALL", Color3.fromRGB(40, 80, 120), CopyToClipboard)

-- Close
AddButton("❌ Close", Color3.fromRGB(100, 40, 40), function()
    ScreenGui:Destroy()
    getgenv().__EXPLORER = nil
end)

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
print("╔═══════════════════════════════════════════════╗")
print("║      GAME EXPLORER LOADED!                    ║")
print("╠═══════════════════════════════════════════════╣")
print("║  1. Tap FULL SCAN to scan everything          ║")
print("║  2. Tap SAVE FILE to save to text file        ║")
print("║  3. Tap COPY ALL to copy to clipboard         ║")
print("║  4. Paste in Notes app to view/share          ║")
print("╚═══════════════════════════════════════════════╝")
print("")
