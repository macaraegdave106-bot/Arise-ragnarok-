--[[
    ╔═══════════════════════════════════════════════╗
    ║  GAME EXPLORER - ORION UI VERSION             ║
    ║  Scans everything in any Roblox game          ║
    ║  Version: 4.0                                 ║
    ╚═══════════════════════════════════════════════╝
--]]

-- Anti-reload
if getgenv().__EXPLORER_ORION then 
    return 
end
getgenv().__EXPLORER_ORION = true

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
-- OUTPUT STORAGE
-- ============================================
local OutputText = ""
local ScanResults = {
    GameInfo = {},
    Remotes = {},
    Prompts = {},
    NPCs = {},
    Items = {},
    Tools = {},
    Folders = {},
    Values = {},
    Players = {},
    Attributes = {}
}

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
    
    local info = {}
    
    pcall(function()
        local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        info.GameName = productInfo.Name or "Unknown"
        info.Creator = productInfo.Creator.Name or "Unknown"
        info.Description = string.sub(productInfo.Description or "", 1, 100)
    end)
    
    info.PlaceId = game.PlaceId
    info.GameId = game.GameId
    info.JobId = game.JobId
    info.PlayerCount = #Players:GetPlayers()
    info.YourName = Player.Name
    
    Log("  Game Name: " .. info.GameName)
    Log("  Creator: " .. info.Creator)
    Log("  Place ID: " .. info.PlaceId)
    Log("  Game ID: " .. info.GameId)
    Log("  Players: " .. info.PlayerCount)
    Log("  Your Name: " .. info.YourName)
    
    ScanResults.GameInfo = info
    return info
end

local function ScanRemotes()
    LogHeader("📡 ALL REMOTES")
    
    local remotes = {}
    local services = {ReplicatedStorage, ReplicatedFirst, Workspace, Lighting}
    
    for _, service in pairs(services) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                    local data = {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Path = obj:GetFullName(),
                        Parent = obj.Parent.Name
                    }
                    
                    table.insert(remotes, data)
                    
                    Log("  [" .. data.Type .. "] " .. data.Name)
                    Log("    Path: " .. data.Path)
                    Log("")
                end
            end
        end)
    end
    
    Log("  TOTAL REMOTES: " .. #remotes)
    ScanResults.Remotes = remotes
    return remotes
end

local function ScanPrompts()
    LogHeader("🎯 PROXIMITY PROMPTS")
    
    local prompts = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ProximityPrompt") then
                local data = {
                    Parent = obj.Parent.Name,
                    ActionText = obj.ActionText ~= "" and obj.ActionText or "Interact",
                    ObjectText = obj.ObjectText,
                    HoldDuration = obj.HoldDuration,
                    Path = obj:GetFullName()
                }
                
                table.insert(prompts, data)
                
                Log("  " .. data.Parent)
                Log("    Action: " .. data.ActionText)
                Log("    Hold: " .. data.HoldDuration .. "s")
                Log("    Path: " .. data.Path)
                Log("")
            end
        end)
    end
    
    Log("  TOTAL PROMPTS: " .. #prompts)
    ScanResults.Prompts = prompts
    return prompts
end

local function ScanNPCs()
    LogHeader("👤 NPCs & HUMANOIDS")
    
    local npcs = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Humanoid") and obj.Parent ~= Player.Character then
                local model = obj.Parent
                local hrp = model:FindFirstChild("HumanoidRootPart")
                
                local data = {
                    Name = model.Name,
                    Health = math.floor(obj.Health),
                    MaxHealth = math.floor(obj.MaxHealth),
                    WalkSpeed = obj.WalkSpeed,
                    HasRoot = hrp and true or false,
                    Path = model:GetFullName()
                }
                
                table.insert(npcs, data)
                
                Log("  " .. data.Name)
                Log("    HP: " .. data.Health .. "/" .. data.MaxHealth)
                Log("    Speed: " .. data.WalkSpeed)
                Log("    Path: " .. data.Path)
                Log("")
            end
        end)
    end
    
    Log("  TOTAL NPCs: " .. #npcs)
    ScanResults.NPCs = npcs
    return npcs
end

local function ScanItems()
    LogHeader("💎 COLLECTIBLE ITEMS")
    
    local items = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            local hasPrompt = obj:FindFirstChild("ProximityPrompt")
            local hasClick = obj:FindFirstChild("ClickDetector")
            local hasTouch = obj:FindFirstChild("TouchInterest")
            
            if obj:IsA("BasePart") and (hasPrompt or hasClick or hasTouch) then
                local interactType = hasPrompt and "ProximityPrompt" or (hasClick and "ClickDetector" or "TouchInterest")
                
                local data = {
                    Name = obj.Name,
                    Class = obj.ClassName,
                    InteractType = interactType,
                    Position = tostring(obj.Position),
                    Path = obj:GetFullName()
                }
                
                table.insert(items, data)
                
                Log("  " .. data.Name .. " [" .. data.Class .. "]")
                Log("    Interact: " .. data.InteractType)
                Log("    Path: " .. data.Path)
                Log("")
            end
        end)
    end
    
    Log("  TOTAL ITEMS: " .. #items)
    ScanResults.Items = items
    return items
end

local function ScanTools()
    LogHeader("🔧 TOOLS & WEAPONS")
    
    local tools = {}
    
    -- StarterPack
    pcall(function()
        for _, obj in pairs(StarterPack:GetChildren()) do
            if obj:IsA("Tool") then
                local data = {
                    Name = obj.Name,
                    Location = "StarterPack",
                    Path = obj:GetFullName()
                }
                table.insert(tools, data)
                Log("  " .. data.Name .. " (StarterPack)")
            end
        end
    end)
    
    -- Backpack
    pcall(function()
        for _, obj in pairs(Player.Backpack:GetChildren()) do
            if obj:IsA("Tool") then
                local data = {
                    Name = obj.Name,
                    Location = "Backpack",
                    Path = obj:GetFullName()
                }
                table.insert(tools, data)
                Log("  " .. data.Name .. " (Backpack)")
            end
        end
    end)
    
    -- Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Tool") then
                local data = {
                    Name = obj.Name,
                    Location = "Workspace",
                    Path = obj:GetFullName()
                }
                table.insert(tools, data)
                Log("  " .. data.Name .. " (Workspace)")
            end
        end)
    end
    
    Log("  TOTAL TOOLS: " .. #tools)
    ScanResults.Tools = tools
    return tools
end

local function ScanFolders()
    LogHeader("📁 ALL FOLDERS")
    
    local folders = {}
    local services = {
        {Name = "Workspace", Service = Workspace},
        {Name = "ReplicatedStorage", Service = ReplicatedStorage},
        {Name = "ReplicatedFirst", Service = ReplicatedFirst},
        {Name = "Lighting", Service = Lighting}
    }
    
    for _, serviceData in pairs(services) do
        pcall(function()
            for _, obj in pairs(serviceData.Service:GetDescendants()) do
                if obj:IsA("Folder") then
                    local data = {
                        Name = obj.Name,
                        Service = serviceData.Name,
                        ChildCount = #obj:GetChildren(),
                        Path = obj:GetFullName()
                    }
                    
                    table.insert(folders, data)
                    
                    Log("  " .. data.Name .. " [" .. data.Service .. "]")
                    Log("    Children: " .. data.ChildCount)
                    Log("    Path: " .. data.Path)
                    Log("")
                end
            end
        end)
    end
    
    Log("  TOTAL FOLDERS: " .. #folders)
    ScanResults.Folders = folders
    return folders
end

local function ScanValues()
    LogHeader("📊 ALL VALUES")
    
    local values = {}
    local services = {ReplicatedStorage, Player, Workspace, Lighting}
    
    for _, service in pairs(services) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") then
                    local data = {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Value = tostring(obj.Value),
                        Path = obj:GetFullName()
                    }
                    
                    table.insert(values, data)
                    
                    Log("  " .. data.Name .. " = " .. data.Value)
                    Log("    Type: " .. data.Type)
                    Log("    Path: " .. data.Path)
                    Log("")
                end
            end
        end)
    end
    
    Log("  TOTAL VALUES: " .. #values)
    ScanResults.Values = values
    return values
end

local function ScanPlayers()
    LogHeader("👥 ALL PLAYERS")
    
    local playerList = {}
    
    for i, plr in pairs(Players:GetPlayers()) do
        pcall(function()
            local data = {
                Name = plr.Name,
                DisplayName = plr.DisplayName,
                UserId = plr.UserId,
                Team = plr.Team and plr.Team.Name or "None",
                IsLocal = plr == Player,
                Values = {}
            }
            
            -- Scan player values
            for _, obj in pairs(plr:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("NumberValue") then
                    data.Values[obj.Name] = tostring(obj.Value)
                end
            end
            
            table.insert(playerList, data)
            
            Log("  " .. i .. ". " .. data.Name .. (data.IsLocal and " (YOU)" or ""))
            Log("    Display: " .. data.DisplayName)
            Log("    Team: " .. data.Team)
            
            for name, val in pairs(data.Values) do
                Log("    " .. name .. " = " .. val)
            end
            Log("")
        end)
    end
    
    Log("  TOTAL PLAYERS: " .. #playerList)
    ScanResults.Players = playerList
    return playerList
end

local function ScanAttributes()
    LogHeader("🏷️ ALL ATTRIBUTES")
    
    local attributes = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            local attrs = obj:GetAttributes()
            if next(attrs) then
                local data = {
                    Object = obj.Name,
                    Path = obj:GetFullName(),
                    Attributes = attrs
                }
                
                table.insert(attributes, data)
                
                Log("  " .. data.Object)
                for name, val in pairs(attrs) do
                    Log("    " .. name .. " = " .. tostring(val))
                end
                Log("")
            end
        end)
    end
    
    Log("  TOTAL: " .. #attributes)
    ScanResults.Attributes = attributes
    return attributes
end

local function ScanWorkspaceStructure()
    LogHeader("🌍 WORKSPACE STRUCTURE")
    
    local count = 0
    
    for _, obj in pairs(Workspace:GetChildren()) do
        count = count + 1
        local childCount = 0
        pcall(function() childCount = #obj:GetDescendants() end)
        
        Log("  " .. obj.Name .. " [" .. obj.ClassName .. "]")
        Log("    Descendants: " .. childCount)
        Log("")
    end
    
    Log("  TOTAL: " .. count)
end

local function ScanReplicatedStructure()
    LogHeader("📦 REPLICATED STORAGE STRUCTURE")
    
    local count = 0
    
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        count = count + 1
        local childCount = 0
        pcall(function() childCount = #obj:GetDescendants() end)
        
        Log("  " .. obj.Name .. " [" .. obj.ClassName .. "]")
        Log("    Descendants: " .. childCount)
        Log("")
    end
    
    Log("  TOTAL: " .. count)
end

-- ============================================
-- FULL SCAN
-- ============================================
local function FullScan()
    OutputText = ""
    
    Log("")
    Log("╔═══════════════════════════════════════════════════════╗")
    Log("║           FULL GAME SCAN - STARTED                    ║")
    Log("║           " .. os.date("%Y-%m-%d %H:%M:%S") .. "                          ║")
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
    
    FullScan()
    
    local gameName = "Game"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name:gsub("[^%w]", "_")
    end)
    
    local filename = "Scan_" .. gameName .. "_" .. game.PlaceId .. ".txt"
    
    pcall(function()
        writefile(filename, OutputText)
    end)
    
    return true, filename
end

local function SaveToJSON()
    if not writefile then
        return false, "writefile not available"
    end
    
    FullScan()
    
    local gameName = "Game"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name:gsub("[^%w]", "_")
    end)
    
    local filename = "Scan_" .. gameName .. "_" .. game.PlaceId .. ".json"
    local json = HttpService:JSONEncode(ScanResults)
    
    pcall(function()
        writefile(filename, json)
    end)
    
    return true, filename
end

local function CopyToClipboard()
    if not setclipboard then
        return false, "setclipboard not available"
    end
    
    if OutputText == "" then
        FullScan()
    end
    
    setclipboard(OutputText)
    return true, "Copied to clipboard"
end

-- ============================================
-- ORION UI SETUP
-- ============================================
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "🔍 Game Explorer",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "GameExplorer",
    IntroEnabled = true,
    IntroText = "Game Explorer v4.0"
})

-- ============================================
-- TABS
-- ============================================

-- Info Tab
local InfoTab = Window:MakeTab({
    Name = "Info",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

InfoTab:AddParagraph("Welcome!", "Scan any Roblox game to find remotes, items, NPCs, and more!")

InfoTab:AddButton({
    Name = "📱 Scan Game Info",
    Callback = function()
        OutputText = ""
        ScanGameInfo()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Game info scanned! Check console.",
            Time = 3
        })
    end
})

InfoTab:AddButton({
    Name = "🌍 Scan Workspace Structure",
    Callback = function()
        OutputText = ""
        ScanWorkspaceStructure()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Workspace scanned! Check console.",
            Time = 3
        })
    end
})

InfoTab:AddButton({
    Name = "📦 Scan ReplicatedStorage",
    Callback = function()
        OutputText = ""
        ScanReplicatedStructure()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "ReplicatedStorage scanned!",
            Time = 3
        })
    end
})

-- Game Objects Tab
local ObjectsTab = Window:MakeTab({
    Name = "Objects",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ObjectsTab:AddButton({
    Name = "📡 Scan All Remotes",
    Callback = function()
        OutputText = ""
        ScanRemotes()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.Remotes .. " remotes!",
            Time = 3
        })
    end
})

ObjectsTab:AddButton({
    Name = "🎯 Scan Proximity Prompts",
    Callback = function()
        OutputText = ""
        ScanPrompts()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.Prompts .. " prompts!",
            Time = 3
        })
    end
})

ObjectsTab:AddButton({
    Name = "💎 Scan Collectible Items",
    Callback = function()
        OutputText = ""
        ScanItems()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.Items .. " items!",
            Time = 3
        })
    end
})

ObjectsTab:AddButton({
    Name = "🔧 Scan All Tools",
    Callback = function()
        OutputText = ""
        ScanTools()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.Tools .. " tools!",
            Time = 3
        })
    end
})

ObjectsTab:AddButton({
    Name = "📁 Scan All Folders",
    Callback = function()
        OutputText = ""
        ScanFolders()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.Folders .. " folders!",
            Time = 3
        })
    end
})

-- NPCs & Players Tab
local EntitiesTab = Window:MakeTab({
    Name = "Entities",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

EntitiesTab:AddButton({
    Name = "👤 Scan All NPCs",
    Callback = function()
        OutputText = ""
        ScanNPCs()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.NPCs .. " NPCs!",
            Time = 3
        })
    end
})

EntitiesTab:AddButton({
    Name = "👥 Scan All Players",
    Callback = function()
        OutputText = ""
        ScanPlayers()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.Players .. " players!",
            Time = 3
        })
    end
})

-- Data Tab
local DataTab = Window:MakeTab({
    Name = "Data",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

DataTab:AddButton({
    Name = "📊 Scan All Values",
    Callback = function()
        OutputText = ""
        ScanValues()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.Values .. " values!",
            Time = 3
        })
    end
})

DataTab:AddButton({
    Name = "🏷️ Scan All Attributes",
    Callback = function()
        OutputText = ""
        ScanAttributes()
        OrionLib:MakeNotification({
            Name = "✅ Complete",
            Content = "Found " .. #ScanResults.Attributes .. " attributes!",
            Time = 3
        })
    end
})

-- Full Scan Tab
local ScanTab = Window:MakeTab({
    Name = "Full Scan",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ScanTab:AddParagraph("Full Scan", "Scan EVERYTHING at once and save the results!")

ScanTab:AddButton({
    Name = "🔄 RUN FULL SCAN",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "⏳ Scanning...",
            Content = "This may take a few seconds",
            Time = 3
        })
        
        task.wait(0.5)
        FullScan()
        
        OrionLib:MakeNotification({
            Name = "✅ Scan Complete!",
            Content = "Check console for results",
            Time = 5
        })
    end
})

ScanTab:AddButton({
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

ScanTab:AddButton({
    Name = "💾 Save to JSON File",
    Callback = function()
        local success, result = SaveToJSON()
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

ScanTab:AddButton({
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

-- Settings Tab
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddParagraph("How to Use", [[
1. Click any scan button
2. Check F9 console for results
3. Use FULL SCAN for everything
4. Save or copy results to share
]])

SettingsTab:AddLabel("Saved files location:")
SettingsTab:AddLabel("Delta: workspace/ folder")

SettingsTab:AddButton({
    Name = "📖 Open F9 Console",
    Callback = function()
        game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
    end
})

-- ============================================
-- INIT
-- ============================================
OrionLib:Init()

OrionLib:MakeNotification({
    Name = "✅ Game Explorer Loaded!",
    Content = "Ready to scan! Use the tabs to explore.",
    Time = 5
})

print("")
print("╔═══════════════════════════════════════════════╗")
print("║      GAME EXPLORER LOADED!                    ║")
print("╠═══════════════════════════════════════════════╣")
print("║  OrionLib UI Version                          ║")
print("║  Use tabs to scan different categories        ║")
print("║  Check F9 console for detailed results        ║")
print("╚═══════════════════════════════════════════════╝")
print("")
