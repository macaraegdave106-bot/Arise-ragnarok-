--[[
    Fully Decoded Moonsec V2 Script for Delta Executor
    Game: Wave Defense Tycoon (ID: 110483372589393)
    Features: Auto Farm, Teleport Farm, Wave Automation, Discord Webhooks, Save/Load Config
--]]

-- Anti-reload protection
if getgenv()._deltaAutomationLoaded then
    return
end
getgenv()._deltaAutomationLoaded = true

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

-- Player setup
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Game-specific objects
local GameMap = Workspace:FindFirstChild("Map") or Workspace
local ItemSpawns = GameMap:FindFirstChild("ItemSpawns") or GameMap
local EnemyFolder = GameMap:FindFirstChild("Enemies") or GameMap
local WaveController = ReplicatedStorage:FindFirstChild("WaveController") or ReplicatedStorage
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage

-- Configuration
local Config = {
    WebhookUrl = "YOUR_WEBHOOK_URL",
    FarmDistance = 2000,
    TeleportDelay = 0.1,
    WaveCheckDelay = 30,
    AutoWave = false,
    AutoFarm = false,
    TeleportFarm = false,
    SaveLocation = "delta_automation.json",
    TargetItems = {},
    TargetWaves = {}
}

-- State management
local isRunning = false
local isTeleporting = false
local currentWave = 0
local farmedItems = {}
local enemyTargets = {}

-- UI Library (Orion)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
local Window = OrionLib:MakeWindow({
    Name = "🌊 Delta Wave Automation",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "DeltaConfigs"
})

-- Main Tab
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Farming Section
MainTab:AddToggle({
    Name = "Auto Farm (Walk)",
    Default = false,
    Callback = function(Value)
        Config.AutoFarm = Value
        if Value then
            startAutoFarm()
        end
    end
})

MainTab:AddToggle({
    Name = "Teleport Farm",
    Default = false,
    Callback = function(Value)
        Config.TeleportFarm = Value
        isTeleporting = Value
        if Value then
            startTeleportFarm()
        end
    end
})

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

-- Wave Section
MainTab:AddToggle({
    Name = "Auto Start Waves",
    Default = false,
    Callback = function(Value)
        Config.AutoWave = Value
        if Value then
            startAutoWave()
        end
    end
})

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

-- Target Selection
local ItemSection = MainTab:AddSection({
    Name = "Target Items"
})

-- Dynamic item list
local function updateItemList()
    local items = {}
    for _, item in pairs(ItemSpawns:GetChildren()) do
        if item:IsA("BasePart") and item:FindFirstChild("ItemID") then
            table.insert(items, item.Name)
        end
    end
    return items
end

local ItemDropdown = MainTab:AddDropdown({
    Name = "Select Items",
    Default = {},
    Options = updateItemList(),
    Multiple = true,
    Callback = function(Value)
        Config.TargetItems = Value
    end
})

-- Refresh button
MainTab:AddButton({
    Name = "Refresh Item List",
    Callback = function()
        ItemDropdown:Refresh(updateItemList(), true)
    end
})

-- Utility Functions
function getValidItems()
    local items = {}
    for _, item in pairs(ItemSpawns:GetChildren()) do
        if item:IsA("BasePart") and item:FindFirstChild("ItemID") then
            local itemId = item.ItemID.Value
            if #Config.TargetItems == 0 or table.find(Config.TargetItems, item.Name) then
                if distanceTo(item) <= Config.FarmDistance then
                    table.insert(items, {
                        part = item,
                        id = itemId,
                        distance = distanceTo(item)
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
    if EnemyFolder then
        for _, enemy in pairs(EnemyFolder:GetChildren()) do
            if enemy:IsA("BasePart") and enemy:FindFirstChild("Humanoid") then
                table.insert(enemies, enemy)
            end
        end
    end
    return enemies
end

function distanceTo(target)
    if HumanoidRootPart and target and target:IsA("BasePart") then
        return (HumanoidRootPart.Position - target.Position).Magnitude
    end
    return math.huge
end

function teleportTo(position)
    if HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(position) + Vector3.new(0, 5, 0)
    end
end

function collectItem(item)
    if item and item:FindFirstChild("ProximityPrompt") then
        local prompt = item.ProximityPrompt
        if syn and syn.fireproximityprompt then
            syn.fireproximityprompt(prompt)
        else
            local oldHold = prompt.HoldDuration
            prompt.HoldDuration = 0
            prompt:InputHoldBegin()
            wait()
            prompt:InputHoldEnd()
            prompt.HoldDuration = oldHold
        end
    end
end

function attackEnemy(enemy)
    if enemy and enemy:FindFirstChild("Humanoid") then
        local remote = RemoteEvents:FindFirstChild("DamageEnemy")
        if remote then
            remote:FireServer(enemy, enemy.Humanoid.MaxHealth / 10)
        end
    end
end

-- Auto Farm Loop
function startAutoFarm()
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
                
                -- Check for enemies while farming
                local enemies = getEnemies()
                for _, enemy in pairs(enemies) do
                    if distanceTo(enemy) < 50 then
                        attackEnemy(enemy)
                        wait(0.2)
                    end
                end
            end
            wait(1)
        end
    end)
end

-- Teleport Farm Loop (faster)
function startTeleportFarm()
    spawn(function()
        while isTeleporting do
            local items = getValidItems()
            for _, itemData in pairs(items) do
                if not isTeleporting then break end
                
                teleportTo(itemData.part.Position)
                wait(Config.TeleportDelay)
                collectItem(itemData.part)
                wait(Config.TeleportDelay)
                
                -- Instant enemy clear
                local enemies = getEnemies()
                for _, enemy in pairs(enemies) do
                    if distanceTo(enemy) < 30 then
                        attackEnemy(enemy)
                    end
                end
            end
            wait()
        end
    end)
end

-- Auto Wave System
function startAutoWave()
    spawn(function()
        while Config.AutoWave do
            if WaveController then
                local waveData = WaveController:GetAttribute("WaveData")
                if waveData then
                    local current = waveData.CurrentWave or 0
                    local max = waveData.MaxWaves or 5
                    
                    if current < max then
                        local remote = RemoteEvents:FindFirstChild("StartWave")
                        if remote then
                            remote:FireServer(current + 1)
                            sendNotification("🌊 Starting Wave " .. (current + 1))
                        end
                    end
                end
            end
            wait(Config.WaveCheckDelay)
        end
    end)
end

-- Discord Webhook
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
                    text = "Delta Executor",
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

-- Configuration Management
function saveConfiguration()
    local configData = {
        AutoFarm = Config.AutoFarm,
        TeleportFarm = Config.TeleportFarm,
        FarmDistance = Config.FarmDistance,
        AutoWave = Config.AutoWave,
        WaveCheckDelay = Config.WaveCheckDelay,
        WebhookUrl = Config.WebhookUrl,
        TargetItems = Config.TargetItems
    }
    
    local jsonData = HttpService:JSONEncode(configData)
    if writefile then
        writefile(Config.SaveLocation, jsonData)
        sendNotification("✅ Configuration saved!")
    end
end

function loadConfiguration()
    if readfile and isfile(Config.SaveLocation) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(Config.SaveLocation))
        end)
        
        if success and data then
            Config.AutoFarm = data.AutoFarm or false
            Config.TeleportFarm = data.TeleportFarm or false
            Config.FarmDistance = data.FarmDistance or 2000
            Config.AutoWave = data.AutoWave or false
            Config.WaveCheckDelay = data.WaveCheckDelay or 30
            Config.WebhookUrl = data.WebhookUrl or "YOUR_WEBHOOK_URL"
            Config.TargetItems = data.TargetItems or {}
            
            sendNotification("✅ Configuration loaded!")
        end
    end
end

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

-- Player Tab
local PlayerTab = Window:MakeTab({
    Name = "Player",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local walkSpeedSlider = PlayerTab:AddSlider({
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

local jumpPowerSlider = PlayerTab:AddSlider({
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

-- ESP Section
local ESPTab = Window:MakeTab({
    Name = "ESP",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local espEnabled = false
local itemESP = {}
local enemyESP = {}

ESPTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        if not Value then
            clearESP()
        end
    end
})

function createESP(target, text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Parent = target
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboard
    
    return billboard
end

function clearESP()
    for _, esp in pairs(itemESP) do
        if esp then esp:Destroy() end
    end
    for _, esp in pairs(enemyESP) do
        if esp then esp:Destroy() end
    end
    itemESP = {}
    enemyESP = {}
end

-- ESP Update Loop
spawn(function()
    while true do
        if espEnabled then
            clearESP()
            
            -- Item ESP
            local items = getValidItems()
            for _, itemData in pairs(items) do
                local esp = createESP(itemData.part, itemData.part.Name, Color3.fromRGB(0, 255, 0))
                table.insert(itemESP, esp)
            end
            
            -- Enemy ESP
            local enemies = getEnemies()
            for _, enemy in pairs(enemies) do
                local esp = createESP(enemy, "Enemy", Color3.fromRGB(255, 0, 0))
                table.insert(enemyESP, esp)
            end
        end
        wait(1)
    end
end)

-- Auto-upgrade system
local UpgradeTab = Window:MakeTab({
    Name = "Upgrades",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local autoUpgradeToggle = UpgradeTab:AddToggle({
    Name = "Auto Upgrade",
    Default = false,
    Callback = function(Value)
        _G.autoUpgrade = Value
        if Value then
            startAutoUpgrade()
        end
    end
})

function startAutoUpgrade()
    spawn(function()
        while _G.autoUpgrade do
            local remote = RemoteEvents:FindFirstChild("Upgrade")
            if remote then
                -- Upgrade damage first, then defense
                remote:FireServer("Damage")
                wait(0.5)
                remote:FireServer("Defense")
                wait(0.5)
            end
            wait(5)
        end
    end
end

-- Anti-AFK system
spawn(function()
    while true do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        wait(1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        wait(120)
    end
end)

-- Player died detection
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    -- Reapply speed settings
    if walkSpeedSlider then
        Character:WaitForChild("Humanoid").WalkSpeed = walkSpeedSlider.Value
    end
    
    sendNotification("🔄 Character respawned! Reinitializing...")
end)

-- Game leave detection
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Orion" then
        -- Save config on UI close
        saveConfiguration()
        sendNotification("👋 Automation disabled!")
    end
end)

-- Initialize
loadConfiguration()
OrionLib:Init()
sendNotification("🌊 Delta Automation loaded successfully!\nGame: Wave Defense Tycoon\nVersion: 2.0")

-- Main loop for status updates
spawn(function()
    while true do
        local status = string.format(
            "Status: %s | Wave: %d | Items Farmed: %d | Teleport: %s",
            (isFarming or isTeleporting) and "🟢 Active" or "🔴 Idle",
            currentWave,
            #farmedItems,
            isTeleporting and "✅ On" or "❌ Off"
        )
        
        -- Update status in UI (if status element exists)
        if Window.Status then
            Window.Status:SetText(status)
        end
        
        wait(5)
    end
end)
