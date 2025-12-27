--[[
    Delta Executor - Wave Defense Tycoon Automation
    Version: 2.0 (Clean Build)
    Game: 110483372589393
--]]

-- Anti-reload protection
if getgenv().DeltaWaveAutomation then
    return
end
getgenv().DeltaWaveAutomation = true

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

-- Player setup
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Game detection
local GAME_ID = 110483372589393
if game.PlaceId ~= GAME_ID then
    warn("❌ This script is designed for Wave Defense Tycoon only!")
    return
end

-- Configuration
local Config = {
    WebhookUrl = "YOUR_WEBHOOK_URL",
    FarmDistance = 2000,
    TeleportDelay = 0.1,
    WaveCheckDelay = 30,
    AutoWave = false,
    AutoFarm = false,
    TeleportFarm = false,
    TargetItems = {},
    TargetWaves = {},
    SaveFile = "wave_defense_config.json"
}

-- State management
local isRunning = false
local isTeleporting = false
local currentWave = 0
local farmedItems = {}
local enemyTargets = {}

-- Load Orion UI Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
local Window = OrionLib:MakeWindow({
    Name = "🌊 Delta Wave Automation",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "DeltaConfigs",
    IntroEnabled = true,
    IntroText = "Wave Defense Tycoon"
})

-- Main Tab
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Helper Functions
function getDistance(target)
    if HumanoidRootPart and target and target:IsA("BasePart") then
        return (HumanoidRootPart.Position - target.Position).Magnitude
    end
    return math.huge
end

function getValidItems()
    local items = {}
    local itemFolder = Workspace:FindFirstChild("ItemDrops") or Workspace:FindFirstChild("Items")
    
    if not itemFolder then
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Folder") and (obj.Name:lower():find("item") or obj.Name:lower():find("drop")) then
                itemFolder = obj
                break
            end
        end
    end
    
    if itemFolder then
        for _, item in pairs(itemFolder:GetChildren()) do
            if item:IsA("BasePart") then
                local distance = getDistance(item)
                if distance <= Config.FarmDistance then
                    table.insert(items, {
                        part = item,
                        distance = distance
                    })
                end
            end
        end
    end
    
    table.sort(items, function(a, b) return a.distance < b.distance end)
    return items
end

function getEnemies()
    local enemies = {}
    local enemyFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("NPCs")
    
    if enemyFolder then
        for _, enemy in pairs(enemyFolder:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") then
                table.insert(enemies, enemy)
            end
        end
    end
    
    return enemies
end

function teleportTo(position)
    if HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(position) + Vector3.new(0, 5, 0)
    end
end

function collectItem(item)
    if item and item:FindFirstChild("ProximityPrompt") then
        local prompt = item.ProximityPrompt
        
        -- Use synapse function if available
        if syn and syn.fireproximityprompt then
            syn.fireproximityprompt(prompt)
        else
            -- Fallback method
            local oldHold = prompt.HoldDuration
            prompt.HoldDuration = 0
            prompt:InputHoldBegin()
            wait(0.1)
            prompt:InputHoldEnd()
            prompt.HoldDuration = oldHold
        end
        
        table.insert(farmedItems, item.Name)
        return true
    end
    return false
end

function attackEnemy(enemy)
    if enemy and enemy:FindFirstChild("Humanoid") then
        local remote = ReplicatedStorage:FindFirstChild("DamageRemote")
        if not remote then
            for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                if obj:IsA("RemoteEvent") and obj.Name:lower():find("damage") then
                    remote = obj
                    break
                end
            end
        end
        
        if remote then
            remote:FireServer(enemy, enemy.Humanoid.MaxHealth / 5)
            return true
        end
    end
    return false
end

function startWave(waveNumber)
    local remote = ReplicatedStorage:FindFirstChild("StartWave")
    if not remote then
        for _, obj in pairs(ReplicatedStorage:GetChildren()) do
            if obj:IsA("RemoteEvent") and obj.Name:lower():find("wave") then
                remote = obj
                break
            end
        end
    end
    
    if remote then
        remote:FireServer(waveNumber)
        currentWave = waveNumber
        sendNotification("🌊 Starting Wave " .. waveNumber)
        return true
    end
    return false
end

function sendNotification(message)
    if Config.WebhookUrl and Config.WebhookUrl ~= "YOUR_WEBHOOK_URL" then
        local data = {
            content = nil,
            embeds = {{
                title = "🌊 Delta Wave Automation",
                description = message,
                color = 3447003,
                timestamp = DateTime.now():ToIsoDate(),
                footer = {
                    text = "Delta Executor | Game: Wave Defense Tycoon",
                    icon_url = "https://tr.rbxcdn.com/9a8e5a4e3e5e5e5e5e5e5e5e5e5e5e5e5e5e5e"
                }
            }}
        }
        
        local success, response = pcall(function()
            return request({
                Url = Config.WebhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        if not success then
            warn("❌ Webhook failed: " .. tostring(response))
        end
    end
end

function saveConfiguration()
    local configData = {
        WebhookUrl = Config.WebhookUrl,
        FarmDistance = Config.FarmDistance,
        WaveCheckDelay = Config.WaveCheckDelay,
        TargetItems = Config.TargetItems
    }
    
    local jsonData = HttpService:JSONEncode(configData)
    if writefile then
        writefile(Config.SaveFile, jsonData)
        OrionLib:MakeNotification({
            Name = "✅ Success",
            Content = "Configuration saved!",
            Time = 3
        })
    end
end

function loadConfiguration()
    if readfile and isfile and isfile(Config.SaveFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(Config.SaveFile))
        end)
        
        if success and data then
            Config.WebhookUrl = data.WebhookUrl or Config.WebhookUrl
            Config.FarmDistance = data.FarmDistance or Config.FarmDistance
            Config.WaveCheckDelay = data.WaveCheckDelay or Config.WaveCheckDelay
            Config.TargetItems = data.TargetItems or Config.TargetItems
            
            OrionLib:MakeNotification({
                Name = "✅ Success",
                Content = "Configuration loaded!",
                Time = 3
            })
        end
    end
end

-- Auto Farm Toggle
MainTab:AddToggle({
    Name = "Auto Farm (Walk)",
    Default = false,
    Callback = function(Value)
        Config.AutoFarm = Value
        if Value then
            spawn(function()
                while Config.AutoFarm do
                    local items = getValidItems()
                    for _, itemData in pairs(items) do
                        if not Config.AutoFarm then break end
                        
                        -- Walk to item
                        local targetPos = itemData.part.Position
                        HumanoidRootPart.CFrame = CFrame.new(targetPos) + Vector3.new(0, 5, 0)
                        
                        wait(0.5)
                        collectItem(itemData.part)
                        wait(0.5)
                        
                        -- Attack nearby enemies
                        local enemies = getEnemies()
                        for _, enemy in pairs(enemies) do
                            if getDistance(enemy) < 50 then
                                attackEnemy(enemy)
                                wait(0.2)
                            end
                        end
                    end
                    wait(1)
                end
            end)
        end
    end
})

-- Teleport Farm Toggle
MainTab:AddToggle({
    Name = "Teleport Farm (Fast)",
    Default = false,
    Callback = function(Value)
        Config.TeleportFarm = Value
        isTeleporting = Value
        
        if Value then
            spawn(function()
                while isTeleporting do
                    local items = getValidItems()
                    for _, itemData in pairs(items) do
                        if not isTeleporting then break end
                        
                        teleportTo(itemData.part.Position)
                        wait(Config.TeleportDelay)
                        collectItem(itemData.part)
                        wait(Config.TeleportDelay)
                        
                        -- Clear enemies instantly
                        local enemies = getEnemies()
                        for _, enemy in pairs(enemies) do
                            if getDistance(enemy) < 30 then
                                attackEnemy(enemy)
                            end
                        end
                    end
                    wait()
                end
            end)
        end
    end
})

-- Farm Distance Slider
MainTab:AddSlider({
    Name = "Farm Distance",
    Min = 100,
    Max = 5000,
    Default = 2000,
    Color = Color3.fromRGB(0, 170, 255),
    Increment = 100,
    ValueName = " studs",
    Callback = function(Value)
        Config.FarmDistance = Value
    end
})

-- Auto Wave Toggle
MainTab:AddToggle({
    Name = "Auto Start Waves",
    Default = false,
    Callback = function(Value)
        Config.AutoWave = Value
        
        if Value then
            spawn(function()
                while Config.AutoWave do
                    -- Check current wave
                    local waveController = ReplicatedStorage:FindFirstChild("WaveController")
                    if waveController then
                        local current = waveController:GetAttribute("CurrentWave") or 0
                        local max = waveController:GetAttribute("MaxWaves") or 5
                        
                        if current < max then
                            startWave(current + 1)
                        end
                    end
                    
                    wait(Config.WaveCheckDelay)
                end
            end)
        end
    end
})

-- Wave Delay Slider
MainTab:AddSlider({
    Name = "Wave Check Delay",
    Min = 10,
    Max = 120,
    Default = 30,
    Color = Color3.fromRGB(255, 170, 0),
    Increment = 5,
    ValueName = " seconds",
    Callback = function(Value)
        Config.WaveCheckDelay = Value
    end
})

-- Item Targeting Section
local ItemSection = MainTab:AddSection({
    Name = "Item Targeting"
})

-- Dynamic item dropdown
local itemOptions = {}
for _, obj in pairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and obj:FindFirstChild("ProximityPrompt") then
        if not table.find(itemOptions, obj.Name) then
            table.insert(itemOptions, obj.Name)
        end
    end
end

local ItemDropdown = MainTab:AddDropdown({
    Name = "Select Items (Optional)",
    Default = {},
    Options = itemOptions,
    Multiple = true,
    Callback = function(Value)
        Config.TargetItems = Value
    end
})

MainTab:AddButton({
    Name = "Refresh Item List",
    Callback = function()
        local newOptions = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj:FindFirstChild("ProximityPrompt") then
                if not table.find(newOptions, obj.Name) then
                    table.insert(newOptions, obj.Name)
                end
            end
        end
        ItemDropdown:Refresh(newOptions, true)
    end
})

-- Player Tab
local PlayerTab = Window:MakeTab({
    Name = "Player",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

PlayerTab:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Color = Color3.fromRGB(0, 255, 0),
    Increment = 1,
    ValueName = " speed",
    Callback = function(Value)
        if Character:FindFirstChild("Humanoid") then
            Character.Humanoid.WalkSpeed = Value
        end
    end
})

PlayerTab:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 200,
    Default = 50,
    Color = Color3.fromRGB(255, 170, 0),
    Increment = 5,
    ValueName = " power",
    Callback = function(Value)
        if Character:FindFirstChild("Humanoid") then
            Character.Humanoid.JumpPower = Value
        end
    end
})

-- Settings Tab
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddTextbox({
    Name = "Discord Webhook URL",
    Default = Config.WebhookUrl,
    TextDisappear = false,
    Callback = function(Value)
        Config.WebhookUrl = Value
    end
})

SettingsTab:AddButton({
    Name = "Save Configuration",
    Callback = function()
        saveConfiguration()
    end
})

SettingsTab:AddButton({
    Name = "Load Configuration",
    Callback = function()
        loadConfiguration()
    end
})

SettingsTab:AddButton({
    Name = "Test Webhook",
    Callback = function()
        sendNotification("🧪 Test notification from Delta Automation!")
    end
})

-- Auto-save on close
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name:find("Orion") then
        saveConfiguration()
        sendNotification("👋 Automation disabled! Configuration saved.")
    end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    -- Reapply player settings
    wait(1)
    if Character:FindFirstChild("Humanoid") then
        -- Speed will be reapplied by slider if needed
    end
    
    sendNotification("🔄 Character respawned! Reinitializing...")
end)

-- Anti-AFK
spawn(function()
    while true do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        wait(1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        wait(120) -- Every 2 minutes
    end
end)

-- Initialize
loadConfiguration()
OrionLib:Init()

-- Welcome notification
OrionLib:MakeNotification({
    Name = "✅ Script Loaded",
    Content = "Delta Automation v2.0 is ready!\nUse the UI to configure settings.",
    Time = 5
})

sendNotification("🌊 Delta Automation initialized!\nGame: Wave Defense Tycoon")

-- Status loop
spawn(function()
    while true do
        local status = string.format(
            "Status: %s | Wave: %d | Items Farmed: %d",
            (Config.AutoFarm or isTeleporting) and "🟢 Active" or "🔴 Idle",
            currentWave,
            #farmedItems
        )
        
        -- Update window title if possible
        pcall(function()
            Window:SetName("🌊 Delta Wave Automation - " .. status)
        end)
        
        wait(5)
    end
end)
