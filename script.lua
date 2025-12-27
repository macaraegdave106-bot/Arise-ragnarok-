--[[
    ╔══════════════════════════════════════════════════╗
    ║  ARISE RAGNAROK - ALL-IN-ONE AUTOMATION          ║
    ║  Features: Farm, Quest, Dungeon, Shadows, ESP    ║
    ║  + FAST ATTACK                                   ║
    ╚══════════════════════════════════════════════════╝
--]]

-- Anti-reload
if getgenv().__ARISE_LOADED then return end
getgenv().__ARISE_LOADED = true

print("🔄 Loading Arise Ragnarok Automation...")

-- ============================================
-- LOAD ORIONLIB
-- ============================================
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- ============================================
-- SERVICES & SETUP
-- ============================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Update on respawn
Player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- ============================================
-- GAME REMOTES & FOLDERS
-- ============================================
local Remotes = {
    -- Combat
    Attack = ReplicatedStorage.Events.Combat.Attack,
    UseSkill = ReplicatedStorage.Events.Combat.UseSkill,
    Sprint = ReplicatedStorage.Events.Combat.Sprint,
    Dash = ReplicatedStorage.Events.Combat.Dash,
    
    -- Quest
    QuestDialog = ReplicatedStorage.Events.Quest.Dialog,
    QuestRedeem = ReplicatedStorage.Events.Quest.Redeem,
    QuestSetup = ReplicatedStorage.Events.Quest.Setup,
    
    -- Shadow
    ShadowArise = ReplicatedStorage.Events.Inventory.Shadow.Arise,
    ShadowEquipBest = ReplicatedStorage.Events.Inventory.Shadow.EquipBest,
    ShadowEquip = ReplicatedStorage.Events.Inventory.Shadow.Equip,
    
    -- Dungeon
    DungeonStart = ReplicatedStorage.Events.Dungeon.Start,
    DungeonRankUp = ReplicatedStorage.Events.Dungeon.RankUp,
    DungeonLobby = ReplicatedStorage.Events.Dungeon.Lobby,
    
    -- Inventory
    InventorySell = ReplicatedStorage.Events.Inventory.Shadow.Sell,
    InventoryMerge = ReplicatedStorage.Events.Inventory.Merge,
    ChestOpen = ReplicatedStorage.Events.Inventory.Chest.Open,
    
    -- Stats & Misc
    Stats = ReplicatedStorage.Events.Stats,
    CodeRedeem = ReplicatedStorage.Events.Code.Redeem,
}

local Folders = {
    Entities = Workspace.EntityFolder,
    EntityData = Workspace.EntityDataFolder,
}

-- ============================================
-- SETTINGS
-- ============================================
local Settings = {
    -- Auto Farm
    AutoFarm = false,
    FarmRange = 100,
    
    -- Fast Attack
    FastAttack = false,
    AttackSpeed = 0.1, -- Delay between attacks
    
    -- Auto Quest
    AutoQuest = false,
    
    -- Auto Dungeon
    AutoDungeon = false,
    
    -- Auto Shadow
    AutoShadow = false,
    AutoEquipBestShadow = false,
    
    -- Auto Sell/Merge
    AutoSell = false,
    AutoMerge = false,
    
    -- ESP
    ESPEnabled = false,
    ESPEnemies = true,
    ESPChests = true,
    
    -- Misc
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
        HumanoidRootPart.CFrame = CFrame.new(position)
    end
end

local function Notify(title, text)
    OrionLib:MakeNotification({
        Name = title,
        Content = text,
        Time = 3
    })
end

-- ============================================
-- ENEMY FUNCTIONS
-- ============================================
local function GetEnemies()
    local enemies = {}
    
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
    
    -- Sort by distance
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
            -- Teleport to enemy
            if Settings.AutoFarm then
                Teleport(enemy.Root.Position + Vector3.new(0, 3, 0))
            end
            
            -- Spam attack
            pcall(function()
                Remotes.Attack:FireServer()
            end)
            
            task.wait(Settings.AttackSpeed)
        end
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
            -- Teleport to enemy
            Teleport(enemy.Root.Position + Vector3.new(0, 3, 0))
            
            -- Attack if fast attack is disabled
            if not Settings.FastAttack then
                pcall(function()
                    Remotes.Attack:FireServer()
                end)
            end
            
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end

-- ============================================
-- AUTO QUEST SYSTEM
-- ============================================
local function AutoQuestLoop()
    while Settings.AutoQuest do
        pcall(function()
            -- Try to talk to quest NPCs
            for _, npc in pairs(Workspace:GetDescendants()) do
                if npc.Name:find("Quest") or npc.Name:find("NPC") then
                    if npc:FindFirstChild("ProximityPrompt") then
                        Teleport(npc.Position)
                        task.wait(0.5)
                        
                        -- Fire quest dialog
                        Remotes.QuestDialog:FireServer(npc)
                        task.wait(1)
                        
                        -- Try to redeem
                        Remotes.QuestRedeem:FireServer()
                        break
                    end
                end
            end
        end)
        
        task.wait(5)
    end
end

-- ============================================
-- AUTO DUNGEON SYSTEM
-- ============================================
local function AutoDungeonLoop()
    while Settings.AutoDungeon do
        pcall(function()
            -- Start dungeon
            Remotes.DungeonStart:FireServer()
            task.wait(2)
            
            -- Auto farm in dungeon
            local enemy = GetClosestEnemy()
            if enemy then
                Teleport(enemy.Root.Position)
                
                if not Settings.FastAttack then
                    Remotes.Attack:FireServer()
                end
            end
            
            -- Try to rank up
            Remotes.DungeonRankUp:FireServer()
        end)
        
        task.wait(1)
    end
end

-- ============================================
-- AUTO SHADOW SYSTEM
-- ============================================
local function AutoShadowLoop()
    while Settings.AutoShadow do
        pcall(function()
            local enemy = GetClosestEnemy()
            if enemy and enemy.Humanoid.Health <= 0 then
                -- Try to arise shadow
                Remotes.ShadowArise:FireServer(enemy.Model)
            end
        end)
        
        task.wait(2)
    end
end

local function AutoEquipBestShadows()
    while Settings.AutoEquipBestShadow do
        pcall(function()
            Remotes.ShadowEquipBest:FireServer()
        end)
        
        task.wait(10)
    end
end

-- ============================================
-- AUTO SELL/MERGE SYSTEM
-- ============================================
local function AutoSellLoop()
    while Settings.AutoSell do
        pcall(function()
            -- Sell common/uncommon items
            Remotes.InventorySell:FireServer("Common")
            Remotes.InventorySell:FireServer("Uncommon")
        end)
        
        task.wait(5)
    end
end

local function AutoMergeLoop()
    while Settings.AutoMerge do
        pcall(function()
            Remotes.InventoryMerge:FireServer()
        end)
        
        task.wait(10)
    end
end

-- ============================================
-- ESP SYSTEM
-- ============================================
local ESPObjects = {}

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
    return billboard
end

local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        if esp then esp:Destroy() end
    end
    ESPObjects = {}
end

local function UpdateESP()
    ClearESP()
    
    if not Settings.ESPEnabled then return end
    
    -- ESP Enemies
    if Settings.ESPEnemies then
        for _, entity in pairs(Folders.Entities:GetChildren()) do
            if entity ~= Character and entity:FindFirstChild("HumanoidRootPart") then
                CreateESP(entity.HumanoidRootPart, entity.Name, Color3.fromRGB(255, 0, 0))
            end
        end
    end
    
    -- ESP Chests
    if Settings.ESPChests then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:find("Chest") and obj:IsA("Model") then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if root then
                    CreateESP(root, "Chest", Color3.fromRGB(255, 215, 0))
                end
            end
        end
    end
end

-- Update ESP every 2 seconds
task.spawn(function()
    while true do
        UpdateESP()
        task.wait(2)
    end
end)

-- ============================================
-- AUTO MOVEMENT
-- ============================================
local function AutoMovementLoop()
    while Settings.AutoSprint or Settings.AutoDash do
        if Settings.AutoSprint then
            pcall(function()
                Remotes.Sprint:FireServer(true)
            end)
        end
        
        if Settings.AutoDash then
            pcall(function()
                Remotes.Dash:FireServer()
            end)
            task.wait(1)
        end
        
        task.wait(0.5)
    end
end

-- ============================================
-- AUTO REDEEM CODES
-- ============================================
local Codes = {
    "RELEASE",
    "UPDATE1",
    "FREEREWARDS",
    "SHADOW",
    "ARISE",
}

local function RedeemAllCodes()
    for _, code in pairs(Codes) do
        pcall(function()
            Remotes.CodeRedeem:FireServer(code)
        end)
        task.wait(0.5)
    end
    
    Notify("Codes", "All codes redeemed!")
end

-- ============================================
-- CREATE UI
-- ============================================
local Window = OrionLib:MakeWindow({
    Name = "⚔️ Arise Ragnarok Automation",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "AriseRagnarok",
    IntroEnabled = true,
    IntroText = "Arise Ragnarok v1.0"
})

-- ============================================
-- TAB 1: COMBAT
-- ============================================
local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

CombatTab:AddSection({Name = "⚔️ Fast Attack"})

CombatTab:AddToggle({
    Name = "🔥 Fast Attack (Spam)",
    Default = false,
    Callback = function(val)
        Settings.FastAttack = val
        if val then
            StartFastAttack()
            Notify("Fast Attack", "Enabled! Spamming attacks...")
        else
            StopFastAttack()
            Notify("Fast Attack", "Disabled")
        end
    end
})

CombatTab:AddSlider({
    Name = "Attack Speed",
    Min = 0,
    Max = 1,
    Default = 0.1,
    Increment = 0.05,
    Callback = function(val)
        Settings.AttackSpeed = val
    end
})

CombatTab:AddSection({Name = "🎯 Auto Farm"})

CombatTab:AddToggle({
    Name = "Auto Farm Enemies",
    Default = false,
    Callback = function(val)
        Settings.AutoFarm = val
        if val then
            task.spawn(AutoFarmLoop)
            Notify("Auto Farm", "Started!")
        else
            Notify("Auto Farm", "Stopped")
        end
    end
})

CombatTab:AddSlider({
    Name = "Farm Range",
    Min = 20,
    Max = 300,
    Default = 100,
    Increment = 10,
    Callback = function(val)
        Settings.FarmRange = val
    end
})

CombatTab:AddSection({Name = "🏃 Movement"})

CombatTab:AddToggle({
    Name = "Auto Sprint",
    Default = false,
    Callback = function(val)
        Settings.AutoSprint = val
        if val then
            task.spawn(AutoMovementLoop)
        end
    end
})

CombatTab:AddToggle({
    Name = "Auto Dash",
    Default = false,
    Callback = function(val)
        Settings.AutoDash = val
        if val then
            task.spawn(AutoMovementLoop)
        end
    end
})

-- ============================================
-- TAB 2: QUEST & DUNGEON
-- ============================================
local QuestTab = Window:MakeTab({
    Name = "Quest/Dungeon",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

QuestTab:AddSection({Name = "📜 Auto Quest"})

QuestTab:AddToggle({
    Name = "Auto Complete Quests",
    Default = false,
    Callback = function(val)
        Settings.AutoQuest = val
        if val then
            task.spawn(AutoQuestLoop)
            Notify("Auto Quest", "Started!")
        end
    end
})

QuestTab:AddSection({Name = "🏰 Auto Dungeon"})

QuestTab:AddToggle({
    Name = "Auto Start & Farm Dungeon",
    Default = false,
    Callback = function(val)
        Settings.AutoDungeon = val
        if val then
            task.spawn(AutoDungeonLoop)
            Notify("Auto Dungeon", "Started!")
        end
    end
})

QuestTab:AddButton({
    Name = "Force Start Dungeon",
    Callback = function()
        pcall(function()
            Remotes.DungeonStart:FireServer()
            Notify("Dungeon", "Started!")
        end)
    end
})

QuestTab:AddButton({
    Name = "Rank Up",
    Callback = function()
        pcall(function()
            Remotes.DungeonRankUp:FireServer()
            Notify("Dungeon", "Rank up attempted!")
        end)
    end
})

-- ============================================
-- TAB 3: SHADOWS
-- ============================================
local ShadowTab = Window:MakeTab({
    Name = "Shadows",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ShadowTab:AddSection({Name = "👥 Auto Shadow"})

ShadowTab:AddToggle({
    Name = "Auto Arise Shadows",
    Default = false,
    Callback = function(val)
        Settings.AutoShadow = val
        if val then
            task.spawn(AutoShadowLoop)
            Notify("Auto Shadow", "Will auto-arise defeated enemies!")
        end
    end
})

ShadowTab:AddToggle({
    Name = "Auto Equip Best Shadows",
    Default = false,
    Callback = function(val)
        Settings.AutoEquipBestShadow = val
        if val then
            task.spawn(AutoEquipBestShadows)
            Notify("Auto Equip", "Auto equipping best shadows!")
        end
    end
})

ShadowTab:AddButton({
    Name = "Equip Best Now",
    Callback = function()
        pcall(function()
            Remotes.ShadowEquipBest:FireServer()
            Notify("Shadows", "Equipped best shadows!")
        end)
    end
})

-- ============================================
-- TAB 4: INVENTORY
-- ============================================
local InvTab = Window:MakeTab({
    Name = "Inventory",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

InvTab:AddSection({Name = "💰 Auto Sell/Merge"})

InvTab:AddToggle({
    Name = "Auto Sell Common/Uncommon",
    Default = false,
    Callback = function(val)
        Settings.AutoSell = val
        if val then
            task.spawn(AutoSellLoop)
            Notify("Auto Sell", "Selling junk items!")
        end
    end
})

InvTab:AddToggle({
    Name = "Auto Merge Items",
    Default = false,
    Callback = function(val)
        Settings.AutoMerge = val
        if val then
            task.spawn(AutoMergeLoop)
            Notify("Auto Merge", "Auto merging items!")
        end
    end
})

InvTab:AddButton({
    Name = "Open All Chests",
    Callback = function()
        pcall(function()
            Remotes.ChestOpen:FireServer()
            Notify("Chests", "Opened all chests!")
        end)
    end
})

-- ============================================
-- TAB 5: ESP & VISUALS
-- ============================================
local ESPTab = Window:MakeTab({
    Name = "ESP",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ESPTab:AddSection({Name = "👁️ ESP Settings"})

ESPTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(val)
        Settings.ESPEnabled = val
        if not val then
            ClearESP()
        end
    end
})

ESPTab:AddToggle({
    Name = "ESP Enemies",
    Default = true,
    Callback = function(val)
        Settings.ESPEnemies = val
    end
})

ESPTab:AddToggle({
    Name = "ESP Chests",
    Default = true,
    Callback = function(val)
        Settings.ESPChests = val
    end
})

-- ============================================
-- TAB 6: MISC
-- ============================================
local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MiscTab:AddSection({Name = "🎁 Codes"})

MiscTab:AddButton({
    Name = "Redeem All Codes",
    Callback = function()
        RedeemAllCodes()
    end
})

MiscTab:AddSection({Name = "📊 Stats"})

MiscTab:AddButton({
    Name = "Max Stats (Strength)",
    Callback = function()
        pcall(function()
            Remotes.Stats:FireServer("Strength", 999)
            Notify("Stats", "Upgraded Strength!")
        end)
    end
})

MiscTab:AddButton({
    Name = "Max Stats (Agility)",
    Callback = function()
        pcall(function()
            Remotes.Stats:FireServer("Agility", 999)
            Notify("Stats", "Upgraded Agility!")
        end)
    end
})

MiscTab:AddSection({Name = "⚙️ Settings"})

MiscTab:AddButton({
    Name = "Destroy UI",
    Callback = function()
        OrionLib:Destroy()
        getgenv().__ARISE_LOADED = nil
        StopFastAttack()
    end
})

-- ============================================
-- INIT
-- ============================================
OrionLib:Init()

print("")
print("╔════════════════════════════════════════════════╗")
print("║  ✅ ARISE RAGNAROK AUTOMATION LOADED!          ║")
print("╠════════════════════════════════════════════════╣")
print("║  Combat Tab: Fast Attack + Auto Farm          ║")
print("║  Quest Tab: Auto Quest + Dungeon              ║")
print("║  Shadows Tab: Auto Arise + Equip              ║")
print("║  Inventory Tab: Auto Sell/Merge               ║")
print("║  ESP Tab: See enemies & chests                ║")
print("║  Misc Tab: Codes + Stats                      ║")
print("╚════════════════════════════════════════════════╝")
print("")

Notify("✅ Loaded!", "Arise Ragnarok Automation Ready!")
