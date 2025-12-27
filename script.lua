--[[
    GAME EXPLORER - OPTIMIZED (NO FREEZE)
    Added task.wait() to prevent freezing
]]

-- Anti-reload
if getgenv().__EXPLORER then return end
getgenv().__EXPLORER = true

print("🔄 Loading Game Explorer...")

-- ============================================
-- LOAD ORIONLIB
-- ============================================
local OrionLib = nil
local OrionLoaded = false

local OrionURLs = {
    "https://raw.githubusercontent.com/shlexware/Orion/main/source",
    "https://raw.githubusercontent.com/jensonhirst/Orion/main/source",
    "https://raw.githubusercontent.com/ionlyusegithubformcmods/1-Line-Scripts/main/Orion%20Library"
}

for i, url in pairs(OrionURLs) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success and result then
        OrionLib = result
        OrionLoaded = true
        print("✅ OrionLib loaded from URL " .. i)
        break
    end
end

if not OrionLoaded then
    print("❌ OrionLib failed!")
    getgenv().__EXPLORER = nil
    return
end

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterPack = game:GetService("StarterPack")

local Player = Players.LocalPlayer

-- ============================================
-- SETTINGS
-- ============================================
local Settings = {
    MaxObjects = 500,  -- Limit objects to prevent freeze
    YieldEvery = 50,   -- Yield every X objects
    ScanDelay = 0.01   -- Small delay to prevent freeze
}

-- ============================================
-- OUTPUT STORAGE
-- ============================================
local OutputText = ""
local IsScanning = false

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
-- OPTIMIZED SCAN FUNCTIONS (NO FREEZE)
-- ============================================

local function ScanGameInfo()
    LogHeader("📱 GAME INFORMATION")
    
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        Log("  Game Name: " .. (info.Name or "Unknown"))
        Log("  Creator: " .. (info.Creator.Name or "Unknown"))
    end)
    
    Log("  Place ID: " .. game.PlaceId)
    Log("  Game ID: " .. game.GameId)
    Log("  Player Count: " .. #Players:GetPlayers())
    Log("  Your Name: " .. Player.Name)
    
    return 1
end

local function ScanRemotes()
    LogHeader("📡 ALL REMOTES")
    
    local count = 0
    local scanned = 0
    
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        scanned = scanned + 1
        
        -- Yield to prevent freeze
        if scanned % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        -- Limit max objects
        if count >= Settings.MaxObjects then
            Log("  ⚠️ Limit reached (" .. Settings.MaxObjects .. ")")
            break
        end
        
        pcall(function()
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
            end
        end)
    end
    
    Log("  TOTAL REMOTES: " .. count)
    return count
end

local function ScanPrompts()
    LogHeader("🎯 PROXIMITY PROMPTS")
    
    local count = 0
    local scanned = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        scanned = scanned + 1
        
        -- Yield to prevent freeze
        if scanned % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        -- Limit
        if count >= Settings.MaxObjects then
            Log("  ⚠️ Limit reached")
            break
        end
        
        pcall(function()
            if obj:IsA("ProximityPrompt") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Parent.Name)
                Log("    Action: " .. (obj.ActionText ~= "" and obj.ActionText or "Interact"))
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL PROMPTS: " .. count)
    return count
end

local function ScanNPCs()
    LogHeader("👤 NPCs & HUMANOIDS")
    
    local count = 0
    local scanned = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        scanned = scanned + 1
        
        -- Yield to prevent freeze
        if scanned % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        -- Limit
        if count >= Settings.MaxObjects then
            Log("  ⚠️ Limit reached")
            break
        end
        
        pcall(function()
            if obj:IsA("Humanoid") and obj.Parent ~= Player.Character then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Parent.Name)
                Log("    HP: " .. math.floor(obj.Health) .. "/" .. math.floor(obj.MaxHealth))
                Log("    Path: " .. obj.Parent:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL NPCs: " .. count)
    return count
end

local function ScanItems()
    LogHeader("💎 COLLECTIBLE ITEMS")
    
    local count = 0
    local scanned = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        scanned = scanned + 1
        
        -- Yield to prevent freeze
        if scanned % Settings.YieldEvery == 0 then
            task.wait(Settings.ScanDelay)
        end
        
        -- Limit
        if count >= Settings.MaxObjects then
            Log("  ⚠️ Limit reached")
            break
        end
        
        pcall(function()
            if obj:IsA("BasePart") and obj:FindFirstChild("ProximityPrompt") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name)
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL ITEMS: " .. count)
    return count
end

local function ScanTools()
    LogHeader("🔧 TOOLS & WEAPONS")
    
    local count = 0
    
    -- StarterPack (small, no yield needed)
    pcall(function()
        for _, obj in pairs(StarterPack:GetChildren()) do
            if obj:IsA("Tool") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name .. " (StarterPack)")
            end
        end
    end)
    
    -- Backpack (small, no yield needed)
    pcall(function()
        for _, obj in pairs(Player.Backpack:GetChildren()) do
            if obj:IsA("Tool") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name .. " (Backpack)")
            end
        end
    end)
    
    Log("  TOTAL TOOLS: " .. count)
    return count
end

local function ScanFolders()
    LogHeader("📁 FOLDERS")
    
    local count = 0
    
    -- Workspace folders (top level only - fast)
    for _, obj in pairs(Workspace:GetChildren()) do
        task.wait()
        pcall(function()
            if obj:IsA("Folder") then
                count = count + 1
                Log("  " .. count .. ". [Workspace] " .. obj.Name .. " (" .. #obj:GetChildren() .. " children)")
            end
        end)
    end
    
    -- ReplicatedStorage folders (top level only - fast)
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        task.wait()
        pcall(function()
            if obj:IsA("Folder") then
                count = count + 1
                Log("  " .. count .. ". [ReplicatedStorage] " .. obj.Name .. " (" .. #obj:GetChildren() .. " children)")
            end
        end)
    end
    
    Log("  TOTAL FOLDERS: " .. count)
    return count
end

local function ScanValues()
    LogHeader("📊 YOUR VALUES (Player Only)")
    
    local count = 0
    
    -- Only scan Player - much faster!
    for _, obj in pairs(Player:GetDescendants()) do
        task.wait()
        pcall(function()
            if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") then
                count = count + 1
                Log("  " .. count .. ". " .. obj.Name .. " = " .. tostring(obj.Value))
                Log("    Type: " .. obj.ClassName)
                Log("    Path: " .. obj:GetFullName())
                Log("")
            end
        end)
    end
    
    Log("  TOTAL VALUES: " .. count)
    return count
end

local function ScanPlayers()
    LogHeader("👥 ALL PLAYERS")
    
    local count = 0
    
    for i, plr in pairs(Players:GetPlayers()) do
        task.wait()
        pcall(function()
            count = count + 1
            Log("  " .. i .. ". " .. plr.Name .. (plr == Player and " (YOU)" or ""))
            Log("    UserId: " .. plr.UserId)
            Log("    Team: " .. (plr.Team and plr.Team.Name or "None"))
            
            -- Only show leaderstats (fast)
            local leaderstats = plr:FindFirstChild("leaderstats")
            if leaderstats then
                for _, stat in pairs(leaderstats:GetChildren()) do
                    Log("    " .. stat.Name .. " = " .. tostring(stat.Value))
                end
            end
            Log("")
        end)
    end
    
    Log("  TOTAL PLAYERS: " .. count)
    return count
end

local function ScanWorkspaceStructure()
    LogHeader("🌍 WORKSPACE STRUCTURE")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetChildren()) do
        task.wait()
        count = count + 1
        local childCount = #obj:GetChildren()
        Log("  " .. count .. ". " .. obj.Name .. " [" .. obj.ClassName .. "] (" .. childCount .. " children)")
    end
    
    Log("  TOTAL: " .. count)
    return count
end

local function ScanReplicatedStructure()
    LogHeader("📦 REPLICATED STORAGE")
    
    local count = 0
    
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        task.wait()
        count = count + 1
        local childCount = #obj:GetChildren()
        Log("  " .. count .. ". " .. obj.Name .. " [" .. obj.ClassName .. "] (" .. childCount .. " children)")
    end
    
    Log("  TOTAL: " .. count)
    return count
end

-- ============================================
-- FULL SCAN (OPTIMIZED)
-- ============================================
local function FullScan()
    if IsScanning then
        OrionLib:MakeNotification({
            Name = "⚠️ Wait",
            Content = "Already scanning...",
            Time = 3
        })
        return
    end
    
    IsScanning = true
    OutputText = ""
    
    Log("")
    Log("╔═══════════════════════════════════════════════════════╗")
    Log("║           FULL GAME SCAN                              ║")
    Log("║           " .. os.date("%Y-%m-%d %H:%M:%S") .. "                           ║")
    Log("╚═══════════════════════════════════════════════════════╝")
    
    ScanGameInfo()
    task.wait(0.1)
    
    ScanWorkspaceStructure()
    task.wait(0.1)
    
    ScanReplicatedStructure()
    task.wait(0.1)
    
    ScanRemotes()
    task.wait(0.1)
    
    ScanPrompts()
    task.wait(0.1)
    
    ScanNPCs()
    task.wait(0.1)
    
    ScanItems()
    task.wait(0.1)
    
    ScanTools()
    task.wait(0.1)
    
    ScanFolders()
    task.wait(0.1)
    
    ScanValues()
    task.wait(0.1)
    
    ScanPlayers()
    
    Log("")
    LogLine()
    Log("  ✅ FULL SCAN COMPLETE!")
    LogLine()
    Log("")
    
    IsScanning = false
    return OutputText
end

-- ============================================
-- QUICK SCAN (FASTEST - NO FREEZE)
-- ============================================
local function QuickScan()
    if IsScanning then return end
    
    IsScanning = true
    OutputText = ""
    
    Log("")
    Log("╔═══════════════════════════════════════════════════════╗")
    Log("║           QUICK SCAN (Lightweight)                    ║")
    Log("╚═══════════════════════════════════════════════════════╝")
    
    -- Game Info
    LogHeader("📱 GAME INFO")
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        Log("  Name: " .. (info.Name or "Unknown"))
    end)
    Log("  Place ID: " .. game.PlaceId)
    Log("  Players: " .. #Players:GetPlayers())
    
    task.wait(0.1)
    
    -- Quick Remote Count
    LogHeader("📡 REMOTES (Quick Count)")
    local remoteCount = 0
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            remoteCount = remoteCount + 1
            if remoteCount <= 10 then
                Log("  " .. obj.Name)
            end
        end
    end
    Log("  Total: " .. remoteCount)
    
    task.wait(0.1)
    
    -- Quick Folder List
    LogHeader("📁 MAIN FOLDERS")
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Folder") then
            Log("  [Workspace] " .. obj.Name)
        end
    end
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("Folder") then
            Log("  [ReplicatedStorage] " .. obj.Name)
        end
    end
    
    task.wait(0.1)
    
    -- Your Stats
    LogHeader("📊 YOUR STATS")
    local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            Log("  " .. stat.Name .. " = " .. tostring(stat.Value))
        end
    else
        Log("  No leaderstats found")
    end
    
    Log("")
    Log("✅ QUICK SCAN COMPLETE!")
    Log("")
    
    IsScanning = false
    return OutputText
end

-- ============================================
-- SAVE FUNCTIONS
-- ============================================
local function SaveToFile()
    if not writefile then
        return false, "writefile not available"
    end
    
    if OutputText == "" then
        QuickScan()
    end
    
    local filename = "Scan_" .. game.PlaceId .. ".txt"
    
    pcall(function()
        writefile(filename, OutputText)
    end)
    
    return true, filename
end

local function CopyToClipboard()
    if not setclipboard then
        return false, "setclipboard not available"
    end
    
    if OutputText == "" then
        QuickScan()
    end
    
    setclipboard(OutputText)
    return true, "Copied!"
end

-- ============================================
-- ORIONLIB UI
-- ============================================
local Window = OrionLib:MakeWindow({
    Name = "🔍 Game Explorer",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = false
})

-- ============================================
-- TAB 1: QUICK ACTIONS
-- ============================================
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddSection({
    Name = "⚡ Fast Scans (No Freeze)"
})

MainTab:AddButton({
    Name = "⚡ QUICK SCAN (Recommended)",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "⏳ Scanning...",
            Content = "Quick scan started",
            Time = 2
        })
        
        task.spawn(function()
            QuickScan()
            OrionLib:MakeNotification({
                Name = "✅ Done!",
                Content = "Check console (F9)",
                Time = 3
            })
        end)
    end
})

MainTab:AddButton({
    Name = "📋 Quick Scan + Copy",
    Callback = function()
        task.spawn(function()
            QuickScan()
            CopyToClipboard()
            OrionLib:MakeNotification({
                Name = "✅ Copied!",
                Content = "Paste anywhere",
                Time = 3
            })
        end)
    end
})

MainTab:AddSection({
    Name = "📁 Individual Scans"
})

MainTab:AddButton({
    Name = "📡 Remotes",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanRemotes()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " remotes",
                Time = 3
            })
        end)
    end
})

MainTab:AddButton({
    Name = "🎯 Prompts",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanPrompts()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " prompts",
                Time = 3
            })
        end)
    end
})

MainTab:AddButton({
    Name = "👤 NPCs",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanNPCs()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " NPCs",
                Time = 3
            })
        end)
    end
})

MainTab:AddButton({
    Name = "💎 Items",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanItems()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " items",
                Time = 3
            })
        end)
    end
})

MainTab:AddButton({
    Name = "📁 Folders",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanFolders()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " folders",
                Time = 3
            })
        end)
    end
})

MainTab:AddButton({
    Name = "📊 Your Values",
    Callback = function()
        task.spawn(function()
            OutputText = ""
            local c = ScanValues()
            OrionLib:MakeNotification({
                Name = "✅ Done",
                Content = "Found " .. c .. " values",
                Time = 3
            })
        end)
    end
})

-- ============================================
-- TAB 2: FULL SCAN
-- ============================================
local FullTab = Window:MakeTab({
    Name = "Full Scan",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

FullTab:AddSection({
    Name = "⚠️ Full Scan (Slower)"
})

FullTab:AddParagraph("Warning", "Full scan takes longer but won't freeze anymore!")

FullTab:AddButton({
    Name = "🔄 RUN FULL SCAN",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "⏳ Scanning...",
            Content = "This may take 10-20 seconds",
            Time = 5
        })
        
        task.spawn(function()
            FullScan()
            OrionLib:MakeNotification({
                Name = "✅ Complete!",
                Content = "Check console (F9)",
                Time = 5
            })
        end)
    end
})

FullTab:AddSection({
    Name = "💾 Save Results"
})

FullTab:AddButton({
    Name = "💾 Save to File",
    Callback = function()
        local success, result = SaveToFile()
        OrionLib:MakeNotification({
            Name = success and "✅ Saved!" or "❌ Error",
            Content = result,
            Time = 5
        })
    end
})

FullTab:AddButton({
    Name = "📋 Copy to Clipboard",
    Callback = function()
        local success, result = CopyToClipboard()
        OrionLib:MakeNotification({
            Name = success and "✅ Copied!" or "❌ Error",
            Content = result,
            Time = 5
        })
    end
})

FullTab:AddButton({
    Name = "📖 Open Console (F9)",
    Callback = function()
        game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
    end
})

-- ============================================
-- TAB 3: SETTINGS
-- ============================================
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSection({
    Name = "Scan Settings"
})

SettingsTab:AddSlider({
    Name = "Max Objects to Scan",
    Min = 100,
    Max = 1000,
    Default = 500,
    Increment = 100,
    Callback = function(val)
        Settings.MaxObjects = val
    end
})

SettingsTab:AddSlider({
    Name = "Yield Every X Objects",
    Min = 10,
    Max = 100,
    Default = 50,
    Increment = 10,
    Callback = function(val)
        Settings.YieldEvery = val
    end
})

SettingsTab:AddSection({
    Name = "UI"
})

SettingsTab:AddButton({
    Name = "🗑️ Close UI",
    Callback = function()
        OrionLib:Destroy()
        getgenv().__EXPLORER = nil
    end
})

-- ============================================
-- INIT
-- ============================================
OrionLib:Init()

print("")
print("╔════════════════════════════════════════╗")
print("║  ✅ GAME EXPLORER LOADED!              ║")
print("╠════════════════════════════════════════╣")
print("║  Use QUICK SCAN for fast results       ║")
print("║  Use FULL SCAN for everything          ║")
print("║  NO MORE FREEZING!                     ║")
print("╚════════════════════════════════════════╝")
print("")

OrionLib:MakeNotification({
    Name = "✅ Loaded!",
    Content = "Use Quick Scan for best performance",
    Time = 5
})
