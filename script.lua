--[[
    ╔══════════════════════════════════════════════════╗
    ║  ARISE RAGNAROK - ALL-IN-ONE AUTOMATION          ║
    ║  FIXED VERSION - Multiple OrionLib URLs          ║
    ╚══════════════════════════════════════════════════╝
--]]

-- Anti-reload
if getgenv().__ARISE_LOADED then return end
getgenv().__ARISE_LOADED = true

print("🔄 Loading Arise Ragnarok Automation...")

-- ============================================
-- LOAD ORIONLIB (Multiple URLs)
-- ============================================
local OrionLib = nil
local OrionLoaded = false

local OrionURLs = {
    "https://raw.githubusercontent.com/jensonhirst/Orion/main/source",
    "https://raw.githubusercontent.com/shlexware/Orion/main/source",
    "https://raw.githubusercontent.com/ionlyusegithubformcmods/1-Line-Scripts/main/Orion%20Library",
    "https://pastefy.app/zSv6F2rR/raw"
}

print("📥 Loading OrionLib...")

for i, url in pairs(OrionURLs) do
    print("  Trying URL " .. i .. "...")
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success and result then
        OrionLib = result
        OrionLoaded = true
        print("✅ OrionLib loaded from URL " .. i)
        break
    else
        print("  ❌ URL " .. i .. " failed")
    end
end

if not OrionLoaded then
    print("❌ All OrionLib URLs failed!")
    print("⚠️ Using fallback UI...")
    
    -- Will use native UI instead
end

-- ============================================
-- SERVICES & SETUP
-- ============================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Update on respawn
Player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    print("🔄 Character respawned!")
end)

-- ============================================
-- GAME REMOTES & FOLDERS
-- ============================================
local Remotes = {}
local Folders = {}

-- Safe remote loading
local function SafeGetRemote(path)
    local success, result = pcall(function()
        local parts = string.split(path, ".")
        local current = ReplicatedStorage
        
        for _, part in pairs(parts) do
            current = current:FindFirstChild(part)
            if not current then return nil end
        end
        
        return current
    end)
    
    return success and result or nil
end

-- Load remotes safely
print("📡 Loading remotes...")

Remotes.Attack = SafeGetRemote("Events.Combat.Attack")
Remotes.UseSkill = SafeGetRemote("Events.Combat.UseSkill")
Remotes.Sprint = SafeGetRemote("Events.Combat.Sprint")
Remotes.Dash = SafeGetRemote("Events.Combat.Dash")
Remotes.QuestDialog = SafeGetRemote("Events.Quest.Dialog")
Remotes.QuestRedeem = SafeGetRemote("Events.Quest.Redeem")
Remotes.ShadowArise = SafeGetRemote("Events.Inventory.Shadow.Arise")
Remotes.ShadowEquipBest = SafeGetRemote("Events.Inventory.Shadow.EquipBest")
Remotes.DungeonStart = SafeGetRemote("Events.Dungeon.Start")
Remotes.DungeonRankUp = SafeGetRemote("Events.Dungeon.RankUp")
Remotes.InventorySell = SafeGetRemote("Events.Inventory.Shadow.Sell")
Remotes.InventoryMerge = SafeGetRemote("Events.Inventory.Merge")
Remotes.ChestOpen = SafeGetRemote("Events.Inventory.Chest.Open")
Remotes.CodeRedeem = SafeGetRemote("Events.Code.Redeem")
Remotes.Stats = SafeGetRemote("Events.Stats")

-- Load folders safely
Folders.Entities = Workspace:FindFirstChild("EntityFolder")
Folders.EntityData = Workspace:FindFirstChild("EntityDataFolder")

print("✅ Remotes loaded!")

-- ============================================
-- SETTINGS
-- ============================================
local Settings = {
    AutoFarm = false,
    FarmRange = 100,
    FastAttack = false,
    AttackSpeed = 0.1,
    AutoQuest = false,
    AutoDungeon = false,
    AutoShadow = false,
    AutoEquipBestShadow = false,
    AutoSell = false,
    AutoMerge = false,
    ESPEnabled = false,
    AutoSprint = false,
    AutoDash = false,
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function GetDistance(part1, part2)
    if not part1 or not part2 then return math.huge end
    return (part1.Position - part2.Position).Magnitude
end

local function Teleport(position)
    if HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(position) + Vector3.new(0, 3, 0)
    end
end

local function SafeFireServer(remote, ...)
    if remote then
        pcall(function()
            remote:FireServer(...)
        end)
    end
end

-- ============================================
-- ENEMY FUNCTIONS
-- ============================================
local function GetEnemies()
    local enemies = {}
    
    if not Folders.Entities then return enemies end
    
    for _, entity in pairs(Folders.Entities:GetChildren()) do
        if entity ~= Character and entity:FindFirstChild("Humanoid") then
            local humanoid = entity.Humanoid
            local root = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("Head")
            
            if humanoid.Health > 0 and root then
                local distance = GetDistance(HumanoidRootPart, root)
                if distance <= Settings.FarmRange then
                    table.insert(enemies, {
                        Model = entity,
                        Humanoid = humanoid,
                        Root = root,
                        Distance = distance,
                        Name = entity.Name
                    })
                end
            end
        end
    end
    
    table.sort(enemies, function(a, b) return a.Distance < b.Distance end)
    return enemies
end

local function GetClosestEnemy()
    local enemies = GetEnemies()
    return enemies[1]
end

-- ============================================
-- FAST ATTACK SYSTEM
-- ============================================
local FastAttackConnection = nil

local function StartFastAttack()
    if FastAttackConnection then return end
    
    FastAttackConnection = RunService.Heartbeat:Connect(function()
        if not Settings.FastAttack then return end
        
        local enemy = GetClosestEnemy()
        if enemy then
            if Settings.AutoFarm then
                Teleport(enemy.Root.Position)
            end
            
            SafeFireServer(Remotes.Attack)
        end
        
        task.wait(Settings.AttackSpeed)
    end)
end

local function StopFastAttack()
    if FastAttackConnection then
        FastAttackConnection:Disconnect()
        FastAttackConnection = nil
    end
end

-- ============================================
-- AUTO FARM LOOP
-- ============================================
local function AutoFarmLoop()
    while Settings.AutoFarm do
        local enemy = GetClosestEnemy()
        
        if enemy then
            Teleport(enemy.Root.Position)
            
            if not Settings.FastAttack then
                SafeFireServer(Remotes.Attack)
            end
            
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end

-- ============================================
-- AUTO QUEST LOOP
-- ============================================
local function AutoQuestLoop()
    while Settings.AutoQuest do
        SafeFireServer(Remotes.QuestRedeem)
        task.wait(5)
    end
end

-- ============================================
-- AUTO DUNGEON LOOP
-- ============================================
local function AutoDungeonLoop()
    while Settings.AutoDungeon do
        SafeFireServer(Remotes.DungeonStart)
        
        local enemy = GetClosestEnemy()
        if enemy then
            Teleport(enemy.Root.Position)
            if not Settings.FastAttack then
                SafeFireServer(Remotes.Attack)
            end
        end
        
        SafeFireServer(Remotes.DungeonRankUp)
        task.wait(1)
    end
end

-- ============================================
-- AUTO SHADOW LOOP
-- ============================================
local function AutoShadowLoop()
    while Settings.AutoShadow do
        local enemy = GetClosestEnemy()
        if enemy and enemy.Humanoid.Health <= 0 then
            SafeFireServer(Remotes.ShadowArise, enemy.Model)
        end
        task.wait(2)
    end
end

local function AutoEquipBestLoop()
    while Settings.AutoEquipBestShadow do
        SafeFireServer(Remotes.ShadowEquipBest)
        task.wait(10)
    end
end

-- ============================================
-- AUTO SELL/MERGE LOOP
-- ============================================
local function AutoSellLoop()
    while Settings.AutoSell do
        SafeFireServer(Remotes.InventorySell, "Common")
        SafeFireServer(Remotes.InventorySell, "Uncommon")
        task.wait(5)
    end
end

local function AutoMergeLoop()
    while Settings.AutoMerge do
        SafeFireServer(Remotes.InventoryMerge)
        task.wait(10)
    end
end

-- ============================================
-- AUTO MOVEMENT LOOP
-- ============================================
local function AutoMovementLoop()
    while Settings.AutoSprint or Settings.AutoDash do
        if Settings.AutoSprint then
            SafeFireServer(Remotes.Sprint, true)
        end
        if Settings.AutoDash then
            SafeFireServer(Remotes.Dash)
            task.wait(1)
        end
        task.wait(0.5)
    end
end

-- ============================================
-- ESP SYSTEM
-- ============================================
local ESPObjects = {}

local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        if esp then esp:Destroy() end
    end
    ESPObjects = {}
end

local function CreateESP(target, name, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Parent = target
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = name
    text.TextColor3 = color
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard
    
    table.insert(ESPObjects, billboard)
end

local function UpdateESP()
    ClearESP()
    if not Settings.ESPEnabled or not Folders.Entities then return end
    
    for _, entity in pairs(Folders.Entities:GetChildren()) do
        if entity ~= Character and entity:FindFirstChild("HumanoidRootPart") then
            CreateESP(entity.HumanoidRootPart, entity.Name, Color3.fromRGB(255, 0, 0))
        end
    end
end

task.spawn(function()
    while true do
        UpdateESP()
        task.wait(2)
    end
end)

-- ============================================
-- CODE REDEMPTION
-- ============================================
local Codes = {"RELEASE", "UPDATE1", "FREEREWARDS", "SHADOW", "ARISE"}

local function RedeemAllCodes()
    for _, code in pairs(Codes) do
        SafeFireServer(Remotes.CodeRedeem, code)
        task.wait(0.5)
    end
    print("✅ All codes redeemed!")
end

-- ============================================
-- CREATE UI (OrionLib or Native)
-- ============================================

if OrionLoaded and OrionLib then
    -- ========================================
    -- ORIONLIB UI
    -- ========================================
    local Window = OrionLib:MakeWindow({
        Name = "⚔️ Arise Ragnarok",
        HidePremium = false,
        SaveConfig = true,
        ConfigFolder = "AriseRagnarok",
        IntroEnabled = false
    })

    -- Combat Tab
    local CombatTab = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://4483345998"})
    
    CombatTab:AddSection({Name = "⚔️ Fast Attack"})
    
    CombatTab:AddToggle({
        Name = "🔥 Fast Attack (Spam)",
        Default = false,
        Callback = function(val)
            Settings.FastAttack = val
            if val then StartFastAttack() else StopFastAttack() end
        end
    })
    
    CombatTab:AddSlider({
        Name = "Attack Speed",
        Min = 0,
        Max = 1,
        Default = 0.1,
        Increment = 0.05,
        Callback = function(val) Settings.AttackSpeed = val end
    })
    
    CombatTab:AddSection({Name = "🎯 Auto Farm"})
    
    CombatTab:AddToggle({
        Name = "Auto Farm Enemies",
        Default = false,
        Callback = function(val)
            Settings.AutoFarm = val
            if val then task.spawn(AutoFarmLoop) end
        end
    })
    
    CombatTab:AddSlider({
        Name = "Farm Range",
        Min = 20,
        Max = 300,
        Default = 100,
        Increment = 10,
        Callback = function(val) Settings.FarmRange = val end
    })
    
    CombatTab:AddSection({Name = "🏃 Movement"})
    
    CombatTab:AddToggle({
        Name = "Auto Sprint",
        Default = false,
        Callback = function(val)
            Settings.AutoSprint = val
            if val then task.spawn(AutoMovementLoop) end
        end
    })
    
    CombatTab:AddToggle({
        Name = "Auto Dash",
        Default = false,
        Callback = function(val)
            Settings.AutoDash = val
            if val then task.spawn(AutoMovementLoop) end
        end
    })

    -- Quest/Dungeon Tab
    local QuestTab = Window:MakeTab({Name = "Quest/Dungeon", Icon = "rbxassetid://4483345998"})
    
    QuestTab:AddSection({Name = "📜 Quest"})
    
    QuestTab:AddToggle({
        Name = "Auto Complete Quests",
        Default = false,
        Callback = function(val)
            Settings.AutoQuest = val
            if val then task.spawn(AutoQuestLoop) end
        end
    })
    
    QuestTab:AddSection({Name = "🏰 Dungeon"})
    
    QuestTab:AddToggle({
        Name = "Auto Dungeon",
        Default = false,
        Callback = function(val)
            Settings.AutoDungeon = val
            if val then task.spawn(AutoDungeonLoop) end
        end
    })
    
    QuestTab:AddButton({
        Name = "Force Start Dungeon",
        Callback = function() SafeFireServer(Remotes.DungeonStart) end
    })
    
    QuestTab:AddButton({
        Name = "Rank Up",
        Callback = function() SafeFireServer(Remotes.DungeonRankUp) end
    })

    -- Shadow Tab
    local ShadowTab = Window:MakeTab({Name = "Shadows", Icon = "rbxassetid://4483345998"})
    
    ShadowTab:AddSection({Name = "👥 Shadows"})
    
    ShadowTab:AddToggle({
        Name = "Auto Arise Shadows",
        Default = false,
        Callback = function(val)
            Settings.AutoShadow = val
            if val then task.spawn(AutoShadowLoop) end
        end
    })
    
    ShadowTab:AddToggle({
        Name = "Auto Equip Best",
        Default = false,
        Callback = function(val)
            Settings.AutoEquipBestShadow = val
            if val then task.spawn(AutoEquipBestLoop) end
        end
    })
    
    ShadowTab:AddButton({
        Name = "Equip Best Now",
        Callback = function() SafeFireServer(Remotes.ShadowEquipBest) end
    })

    -- Inventory Tab
    local InvTab = Window:MakeTab({Name = "Inventory", Icon = "rbxassetid://4483345998"})
    
    InvTab:AddSection({Name = "💰 Auto Sell/Merge"})
    
    InvTab:AddToggle({
        Name = "Auto Sell Junk",
        Default = false,
        Callback = function(val)
            Settings.AutoSell = val
            if val then task.spawn(AutoSellLoop) end
        end
    })
    
    InvTab:AddToggle({
        Name = "Auto Merge",
        Default = false,
        Callback = function(val)
            Settings.AutoMerge = val
            if val then task.spawn(AutoMergeLoop) end
        end
    })
    
    InvTab:AddButton({
        Name = "Open All Chests",
        Callback = function() SafeFireServer(Remotes.ChestOpen) end
    })

    -- ESP Tab
    local ESPTab = Window:MakeTab({Name = "ESP", Icon = "rbxassetid://4483345998"})
    
    ESPTab:AddToggle({
        Name = "Enable ESP",
        Default = false,
        Callback = function(val)
            Settings.ESPEnabled = val
            if not val then ClearESP() end
        end
    })

    -- Misc Tab
    local MiscTab = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998"})
    
    MiscTab:AddButton({
        Name = "Redeem All Codes",
        Callback = RedeemAllCodes
    })
    
    MiscTab:AddButton({
        Name = "Destroy UI",
        Callback = function()
            OrionLib:Destroy()
            getgenv().__ARISE_LOADED = nil
            StopFastAttack()
        end
    })

    OrionLib:Init()
    
    OrionLib:MakeNotification({
        Name = "✅ Loaded!",
        Content = "Arise Ragnarok Automation Ready!",
        Time = 5
    })

else
    -- ========================================
    -- NATIVE UI (Fallback)
    -- ========================================
    print("⚠️ Using Native UI...")
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AriseUI"
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
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 200, 0, 350)
    Main.Position = UDim2.new(0, 10, 0.3, 0)
    Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Main
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Title.Text = "⚔️ Arise Ragnarok"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Main
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = Title
    
    local yPos = 45
    
    local function CreateToggle(name, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -16, 0, 30)
        btn.Position = UDim2.new(0, 8, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        btn.Text = "❌ " .. name
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.Parent = Main
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        local enabled = false
        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = (enabled and "✅ " or "❌ ") .. name
            btn.BackgroundColor3 = enabled and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 70)
            callback(enabled)
        end)
        
        yPos = yPos + 35
        return btn
    end
    
    CreateToggle("Fast Attack", function(val)
        Settings.FastAttack = val
        if val then StartFastAttack() else StopFastAttack() end
    end)
    
    CreateToggle("Auto Farm", function(val)
        Settings.AutoFarm = val
        if val then task.spawn(AutoFarmLoop) end
    end)
    
    CreateToggle("Auto Quest", function(val)
        Settings.AutoQuest = val
        if val then task.spawn(AutoQuestLoop) end
    end)
    
    CreateToggle("Auto Dungeon", function(val)
        Settings.AutoDungeon = val
        if val then task.spawn(AutoDungeonLoop) end
    end)
    
    CreateToggle("Auto Shadow", function(val)
        Settings.AutoShadow = val
        if val then task.spawn(AutoShadowLoop) end
    end)
    
    CreateToggle("Auto Equip Best", function(val)
        Settings.AutoEquipBestShadow = val
        if val then task.spawn(AutoEquipBestLoop) end
    end)
    
    CreateToggle("ESP", function(val)
        Settings.ESPEnabled = val
        if not val then ClearESP() end
    end)
    
    CreateToggle("Auto Sprint", function(val)
        Settings.AutoSprint = val
        if val then task.spawn(AutoMovementLoop) end
    end)
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, -16, 0, 30)
    closeBtn.Position = UDim2.new(0, 8, 0, yPos)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.Text = "❌ Close"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = Main
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        getgenv().__ARISE_LOADED = nil
        StopFastAttack()
    end)
end

-- ============================================
-- DONE!
-- ============================================
print("")
print("╔════════════════════════════════════════════════╗")
print("║  ✅ ARISE RAGNAROK AUTOMATION LOADED!          ║")
print("╠════════════════════════════════════════════════╣")
print("║  Features:                                     ║")
print("║  - Fast Attack                                 ║")
print("║  - Auto Farm                                   ║")
print("║  - Auto Quest/Dungeon                          ║")
print("║  - Auto Shadow                                 ║")
print("║  - ESP                                         ║")
print("╚════════════════════════════════════════════════╝")
print("")
