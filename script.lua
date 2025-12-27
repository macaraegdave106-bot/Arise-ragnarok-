--[[
    GAME EXPLORER - ORIONLIB VERSION
    With multiple URL fallbacks
    Saves all console output to text file
]]

-- Anti-reload
if getgenv().__EXPLORER then return end
getgenv().__EXPLORER = true

print("🔄 Loading Game Explorer...")

-- ============================================
-- LOAD ORIONLIB (Multiple URLs)
-- ============================================
local OrionLib = nil
local OrionLoaded = false

local OrionURLs = {
    "https://raw.githubusercontent.com/shlexware/Orion/main/source",
    "https://raw.githubusercontent.com/jensonhirst/Orion/main/source",
    "https://raw.githubusercontent.com/ionlyusegithubformcmods/1-Line-Scripts/main/Orion%20Library",
    "https://pastefy.app/zSv6F2rR/raw"
}

for i, url in pairs(OrionURLs) do
    print("📥 Trying OrionLib URL " .. i .. "...")
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success and result then
        OrionLib = result
        OrionLoaded = true
        print("✅ OrionLib loaded from URL " .. i)
        break
    else
        print("❌ URL " .. i .. " failed: " .. tostring(result))
    end
end

if not OrionLoaded then
    print("❌ All OrionLib URLs failed!")
    print("❌ Cannot continue without OrionLib")
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "❌ Error",
        Text = "OrionLib failed to load from all URLs",
        Duration = 10
    })
    
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

print("✅ Services loaded")

-- ============================================
-- OUTPUT STORAGE
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
    
    return 1
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
    return count
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
    return count
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
    return count
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
    return count
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
    return count
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
    return count
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
    return count
end

local function ScanPlayers()
    LogHeader("👥 ALL PLAYERS")
    
    local count = 0
    
    for i, plr in pairs(Players:GetPlayers()) do
        pcall(function()
            count = count + 1
            Log("  " .. i .. ". " .. plr.Name .. (plr == Player and " (YOU)" or ""))
            Log("    Display: " .. plr.DisplayName)
            Log("    UserId: " .. plr.UserId)
            Log("    Team: " .. (plr.Team and plr.Team.Name or "None"))
            
            -- Player values
            for _, obj in pairs(plr:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("NumberValue") then
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
    
    Log("  TOTAL PLAYERS: " .. count)
    return count
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
    return count
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
    return count
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
    return count
end

-- ============================================
-- FULL SCAN
-- ============================================
local function FullScan()
    OutputText = ""
    
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
        return false, "writefile not available"
    end
    
    if OutputText == "" then
        FullScan()
    end
    
    local gameName = "Game"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name:gsub("[^%w]", "_")
    end)
    
    local filename = "Scan_" .. gameName .. "_" .. game.PlaceId .. ".txt"
    
    local success = pcall(function()
        writefile(filename, OutputText)
    end)
    
    if success then
        return true, filename
    else
        return false, "Failed to write file"
    end
end

local function CopyToClipboard()
    if not setclipboard then
        return false, "setclipboard not available"
    end
    
    if OutputText == "" then
        FullScan()
    end
    
    setclipboard(OutputText)
    return true, "Copied!"
end

-- ============================================
-- CREATE ORIONLIB UI
-- ============================================
print("🎨 Creating OrionLib UI...")

local Window = OrionLib:MakeWindow({
    Name = "🔍 Game Explorer",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "Game Explorer v4.0"
})

-- ============================================
-- TAB 1: SCAN
-- ============================================
local ScanTab = Window:MakeTab({
    Name = "Scan",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ScanTab:AddSection({
    Name = "Quick Scans"
})

ScanTab:AddButton({
    Name = "📱 Game Info",
    Callback = function()
        OutputText = ""
        ScanGameInfo()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Game info scanned!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "📡 Scan Remotes",
    Callback = function()
        OutputText = ""
        local count = ScanRemotes()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " remotes!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "🎯 Scan Prompts",
    Callback = function()
        OutputText = ""
        local count = ScanPrompts()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " prompts!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "👤 Scan NPCs",
    Callback = function()
        OutputText = ""
        local count = ScanNPCs()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " NPCs!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "💎 Scan Items",
    Callback = function()
        OutputText = ""
        local count = ScanItems()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " items!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "🔧 Scan Tools",
    Callback = function()
        OutputText = ""
        local count = ScanTools()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " tools!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "📁 Scan Folders",
    Callback = function()
        OutputText = ""
        local count = ScanFolders()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " folders!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "📊 Scan Values",
    Callback = function()
        OutputText = ""
        local count = ScanValues()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " values!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "👥 Scan Players",
    Callback = function()
        OutputText = ""
        local count = ScanPlayers()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " players!",
            Time = 3
        })
    end
})

ScanTab:AddButton({
    Name = "🏷️ Scan Attributes",
    Callback = function()
        OutputText = ""
        local count = ScanAttributes()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " attributes!",
            Time = 3
        })
    end
})

-- ============================================
-- TAB 2: FULL SCAN & SAVE
-- ============================================
local FullTab = Window:MakeTab({
    Name = "Full Scan",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

FullTab:AddSection({
    Name = "Full Game Scan"
})

FullTab:AddParagraph("Info", "Full scan will scan EVERYTHING in the game and show results in console (F9).")

FullTab:AddButton({
    Name = "🔄 RUN FULL SCAN",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "⏳ Scanning...",
            Content = "Please wait...",
            Time = 3
        })
        
        task.spawn(function()
            FullScan()
            OrionLib:MakeNotification({
                Name = "✅ Complete!",
                Content = "Check console (F9) for results",
                Time = 5
            })
        end)
    end
})

FullTab:AddSection({
    Name = "Save Results"
})

FullTab:AddButton({
    Name = "💾 Save to Text File",
    Callback = function()
        local success, result = SaveToFile()
        if success then
            OrionLib:MakeNotification({
                Name = "✅ Saved!",
                Content = "File: " .. result,
                Time = 5
            })
        else
            OrionLib:MakeNotification({
                Name = "❌ Error",
                Content = result,
                Time = 5
            })
        end
    end
})

FullTab:AddButton({
    Name = "📋 Copy to Clipboard",
    Callback = function()
        local success, result = CopyToClipboard()
        if success then
            OrionLib:MakeNotification({
                Name = "✅ Copied!",
                Content = "Paste anywhere to view results",
                Time = 5
            })
        else
            OrionLib:MakeNotification({
                Name = "❌ Error",
                Content = result,
                Time = 5
            })
        end
    end
})

FullTab:AddButton({
    Name = "📖 Open Console (F9)",
    Callback = function()
        game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
        OrionLib:MakeNotification({
            Name = "✅ Opened",
            Content = "Console is now visible",
            Time = 3
        })
    end
})

-- ============================================
-- TAB 3: STRUCTURE
-- ============================================
local StructureTab = Window:MakeTab({
    Name = "Structure",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

StructureTab:AddSection({
    Name = "Game Structure"
})

StructureTab:AddButton({
    Name = "🌍 Workspace Structure",
    Callback = function()
        OutputText = ""
        local count = ScanWorkspaceStructure()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " top-level objects!",
            Time = 3
        })
    end
})

StructureTab:AddButton({
    Name = "📦 ReplicatedStorage Structure",
    Callback = function()
        OutputText = ""
        local count = ScanReplicatedStructure()
        OrionLib:MakeNotification({
            Name = "✅ Done",
            Content = "Found " .. count .. " objects!",
            Time = 3
        })
    end
})

-- ============================================
-- TAB 4: SETTINGS
-- ============================================
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSection({
    Name = "How to Use"
})

SettingsTab:AddParagraph("Step 1", "Click any scan button to scan that category")

SettingsTab:AddParagraph("Step 2", "Open console (F9) to see detailed results")

SettingsTab:AddParagraph("Step 3", "Use FULL SCAN to scan everything at once")

SettingsTab:AddParagraph("Step 4", "Save to file or copy to clipboard to share")

SettingsTab:AddSection({
    Name = "About"
})

SettingsTab:AddParagraph("Version", "Game Explorer v4.0 - OrionLib Edition")

SettingsTab:AddParagraph("File Location", "Saved files go to your executor's workspace folder")

SettingsTab:AddButton({
    Name = "🗑️ Destroy UI",
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
print("╔═══════════════════════════════════════════════╗")
print("║      GAME EXPLORER LOADED!                    ║")
print("╠═══════════════════════════════════════════════╣")
print("║  OrionLib UI Version                          ║")
print("║                                               ║")
print("║  HOW TO USE:                                  ║")
print("║  1. Click any scan button                     ║")
print("║  2. Check F9 console for results              ║")
print("║  3. Use FULL SCAN for everything              ║")
print("║  4. Save or copy results to share             ║")
print("╚═══════════════════════════════════════════════╝")
print("")

OrionLib:MakeNotification({
    Name = "✅ Game Explorer Loaded!",
    Content = "Ready to scan! Use the tabs.",
    Time = 5
})
