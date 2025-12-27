--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║             ARISE RAGNAROK - COMPLETE SCRIPT                  ║
    ║             Based on Game Export Data                         ║
    ║             All Features Working                              ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- Anti-reload
if getgenv().__ARISE_SCRIPT then
    warn("Script already running!")
    return
end
getgenv().__ARISE_SCRIPT = true

print("🔄 Loading Arise Ragnarok Script...")

-- ═══════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Update on respawn
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- ═══════════════════════════════════════════════════════════════
--  LOAD ORIONLIB
-- ═══════════════════════════════════════════════════════════════

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

-- ═══════════════════════════════════════════════════════════════
--  GET REMOTES (From Export Data)
-- ═══════════════════════════════════════════════════════════════

local Events = ReplicatedStorage:WaitForChild("Events", 10)

-- Quest Remotes
local QuestEvents = {}
pcall(function() QuestEvents.Redeem = Events.Quest.Redeem end)
pcall(function() QuestEvents.Dialog = Events.Quest.Dialog end)
pcall(function() QuestEvents.Cancel = Events.Quest.Cancel end)
pcall(function() QuestEvents.Setup = Events.Quest.Setup end)

-- Combat Remotes
local CombatEvents = {}
pcall(function() CombatEvents.Attack = Events.Combat.Attack end)
pcall(function() CombatEvents.UseSkill = Events.Combat.UseSkill end)
pcall(function() CombatEvents.UseUtil = Events.Combat.UseUtil end)
pcall(function() CombatEvents.Sprint = Events.Combat.Sprint end)
pcall(function() CombatEvents.Dash = Events.Combat.Dash end)
pcall(function() CombatEvents.ToggleWeapon = Events.Combat["Toggle Weapon"] end)
pcall(function() CombatEvents.EquipShadow = Events.Combat["Equip Shadow"] end)

-- Shadow/Arise Remotes
local ShadowEvents = {}
pcall(function() ShadowEvents.Arise = Events.Inventory.Shadow.Arise end)
pcall(function() ShadowEvents.TryArise = Events.Inventory.Shadow.TryArise end)
pcall(function() ShadowEvents.Equip = Events.Inventory.Shadow.Equip end)
pcall(function() ShadowEvents.EquipBest = Events.Inventory.Shadow.EquipBest end)
pcall(function() ShadowEvents.UnequipAll = Events.Inventory.Shadow.UnequipAll end)
pcall(function() ShadowEvents.Sell = Events.Inventory.Shadow.Sell end)
pcall(function() ShadowEvents.Lock = Events.Inventory.Shadow.Lock end)

-- Inventory Remotes
local InventoryEvents = {}
pcall(function() InventoryEvents.WeaponEquip = Events.Inventory.Weapon.Equip end)
pcall(function() InventoryEvents.WeaponUnequip = Events.Inventory.Weapon.Unequip end)
pcall(function() InventoryEvents.WeaponSell = Events.Inventory.Weapon.Sell end)
pcall(function() InventoryEvents.ArmorEquip = Events.Inventory.Armor.Equip end)
pcall(function() InventoryEvents.ArmorUnequip = Events.Inventory.Armor.Unequip end)
pcall(function() InventoryEvents.ArmorSell = Events.Inventory.Armor.Sell end)
pcall(function() InventoryEvents.SkillEquip = Events.Inventory.Skill.Equip end)
pcall(function() InventoryEvents.SkillUnequip = Events.Inventory.Skill.Unequip end)
pcall(function() InventoryEvents.ChestOpen = Events.Inventory.Chest.Open end)
pcall(function() InventoryEvents.Merge = Events.Inventory.Merge end)
pcall(function() InventoryEvents.UseKey = Events.Inventory.UseKey end)
pcall(function() InventoryEvents.ResetStats = Events.Inventory.ResetStats end)
pcall(function() InventoryEvents.Class = Events.Inventory.Class end)

-- Dungeon Remotes
local DungeonEvents = {}
pcall(function() DungeonEvents.Start = Events.Dungeon.Start end)
pcall(function() DungeonEvents.Lobby = Events.Dungeon.Lobby end)
pcall(function() DungeonEvents.RankUp = Events.Dungeon.RankUp end)

-- Timed Dungeon Remotes
local TimedDungeonEvents = {}
pcall(function() TimedDungeonEvents.Open = Events["Timed Dungeon"].Open end)
pcall(function() TimedDungeonEvents.Create = Events["Timed Dungeon"].Create end)
pcall(function() TimedDungeonEvents.Start = Events["Timed Dungeon"].Start end)
pcall(function() TimedDungeonEvents.Leave = Events["Timed Dungeon"].Leave end)
pcall(function() TimedDungeonEvents.Join = Events["Timed Dungeon"].Join end)

-- Other Remotes
local StatsEvent = nil
local CodeRedeem = nil
local PartyEvents = {}
local GuildStoreEvents = {}

pcall(function() StatsEvent = Events.Stats end)
pcall(function() CodeRedeem = Events.Code.Redeem end)
pcall(function() PartyEvents.Create = Events.Party.Create end)
pcall(function() PartyEvents.Leave = Events.Party.Leave end)
pcall(function() PartyEvents.Request = Events.Party.Request end)
pcall(function() GuildStoreEvents.Buy = Events["Guild Store"].Buy end)
pcall(function() GuildStoreEvents.CurrencyConvert = Events["Guild Store"].CurrencyConvert end)

-- ═══════════════════════════════════════════════════════════════
--  SETTINGS
-- ═══════════════════════════════════════════════════════════════

local Settings = {
    -- Auto Farm
    AutoFarm = false,
    AutoSkills = false,
    AutoDash = false,
    AutoSprint = false,
    TeleportToEnemy = true,
    BringEnemies = false,
    FarmDistance = 10,
    AttackSpeed = 0.1,
    
    -- Auto Arise/Shadow
    AutoArise = false,
    AutoEquipBest = false,
    AutoSellCommon = false,
    AutoSellUncommon = false,
    
    -- Quest
    AutoQuest = false,
    AutoAcceptQuest = false,
    AutoRedeemQuest = false,
    
    -- Dungeon
    AutoDungeon = false,
    SelectedDungeon = "1",
    DungeonDifficulty = "Easy",
    
    -- Stats
    AutoStats = false,
    StatToUpgrade = "DMG",
    
    -- Collect
    AutoCollect = false,
    AutoOpenChest = false,
    
    -- Player
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    NoClip = false
}

-- ═══════════════════════════════════════════════════════════════
--  ANTI-AFK
-- ═══════════════════════════════════════════════════════════════

Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ═══════════════════════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function Notify(title, content, duration)
    OrionLib:MakeNotification({
        Name = title,
        Content = content,
        Time = duration or 3
    })
end

local function FireRemote(remote, ...)
    if remote then
        pcall(function()
            remote:FireServer(...)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  BUTTON CLICKER
-- ═══════════════════════════════════════════════════════════════

local function ClickButtonByPath(path)
    local parts = string.split(path, ".")
    local current = game
    
    for _, part in pairs(parts) do
        if current then
            current = current:FindFirstChild(part)
        end
    end
    
    if current and (current:IsA("TextButton") or current:IsA("ImageButton")) then
        pcall(function()
            -- Method 1: Fire connections
            if getconnections then
                for _, conn in pairs(getconnections(current.MouseButton1Click)) do
                    conn:Fire()
                end
            end
            -- Method 2: Direct fire
            current.MouseButton1Click:Fire()
        end)
        return true
    end
    
    return false
end

local function FindAndClickButton(searchText)
    searchText = searchText:lower()
    
    for _, obj in pairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local text = obj:IsA("TextButton") and obj.Text:lower() or ""
            local name = obj.Name:lower()
            
            if (text:find(searchText) or name:find(searchText)) and obj.Visible then
                pcall(function()
                    if getconnections then
                        for _, conn in pairs(getconnections(obj.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end
                    obj.MouseButton1Click:Fire()
                end)
                return true
            end
        end
    end
    
    return false
end

-- Click specific buttons from export
local function ClickAriseButton()
    -- Try multiple arise-related buttons
    FindAndClickButton("arise")
    
    -- Specific path from export
    pcall(function()
        local ariseBtn = PlayerGui:FindFirstChild("Static 3D Screen")
        if ariseBtn then
            ariseBtn = ariseBtn:FindFirstChild("Screen5")
            if ariseBtn then
                ariseBtn = ariseBtn.Content.ScreenInsets.Bottom.BottomRight.Hotkey.arise
                if ariseBtn and ariseBtn:FindFirstChild("LowKey") then
                    local btn = ariseBtn.LowKey:FindFirstChild("Content")
                    if btn then
                        pcall(function()
                            if getconnections then
                                for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                                    conn:Fire()
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
end

local function ClickCollectButton()
    FindAndClickButton("collect")
    
    pcall(function()
        local collectBtn = PlayerGui:FindFirstChild("Static 3D Screen")
        if collectBtn then
            collectBtn = collectBtn:FindFirstChild("Screen5")
            if collectBtn then
                collectBtn = collectBtn.Content.ScreenInsets.Bottom.BottomRight.Hotkey.collect
                if collectBtn and collectBtn:FindFirstChild("LowKey") then
                    local btn = collectBtn.LowKey:FindFirstChild("Content")
                    if btn then
                        pcall(function()
                            if getconnections then
                                for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                                    conn:Fire()
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
end

local function ClickSummonButton()
    FindAndClickButton("summon")
    
    pcall(function()
        local summonBtn = PlayerGui:FindFirstChild("Static 3D Screen")
        if summonBtn then
            summonBtn = summonBtn:FindFirstChild("Screen5")
            if summonBtn then
                local mobileBtn = summonBtn.Content.ScreenInsets.Right:FindFirstChild("Mobile Buttons")
                if mobileBtn then
                    local summon = mobileBtn:FindFirstChild("Summon")
                    if summon and summon:FindFirstChild("Content") then
                        pcall(function()
                            if getconnections then
                                for _, conn in pairs(getconnections(summon.Content.MouseButton1Click)) do
                                    conn:Fire()
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
end

local function ClickQuestAccept()
    FindAndClickButton("accept")
    
    pcall(function()
        local questDialog = PlayerGui:FindFirstChild("3D Screen")
        if questDialog then
            questDialog = questDialog:FindFirstChild("Screen1")
            if questDialog then
                local dialog = questDialog.Content.Center:FindFirstChild("Quest Dialog")
                if dialog then
                    local acceptBtn = dialog.Background.Down:FindFirstChild("Accept")
                    if acceptBtn and acceptBtn:FindFirstChild("Content") then
                        pcall(function()
                            if getconnections then
                                for _, conn in pairs(getconnections(acceptBtn.Content.MouseButton1Click)) do
                                    conn:Fire()
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
end

local function ClickEquipBest()
    FindAndClickButton("equip best")
    
    pcall(function()
        local screen = PlayerGui:FindFirstChild("3D Screen")
        if screen then
            screen = screen:FindFirstChild("Screen3")
            if screen then
                local shadow = screen.Content.Center:FindFirstChild("Shadow")
                if shadow then
                    local equipBest = shadow.Background.Content:FindFirstChild("Down Bar")
                    if equipBest then
                        equipBest = equipBest:FindFirstChild("EquipBest")
                        if equipBest and equipBest:FindFirstChild("Content") then
                            pcall(function()
                                if getconnections then
                                    for _, conn in pairs(getconnections(equipBest.Content.MouseButton1Click)) do
                                        conn:Fire()
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  ENTITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function GetEnemies()
    local enemies = {}
    local entityFolder = Workspace:FindFirstChild("EntityFolder")
    
    if entityFolder then
        for _, entity in pairs(entityFolder:GetChildren()) do
            pcall(function()
                local humanoid = entity:FindFirstChildOfClass("Humanoid")
                local hrp = entity:FindFirstChild("HumanoidRootPart")
                local isPlayer = Players:GetPlayerFromCharacter(entity)
                
                if humanoid and hrp and not isPlayer and humanoid.Health > 0 then
                    table.insert(enemies, {
                        Model = entity,
                        Humanoid = humanoid,
                        HRP = hrp,
                        Health = humanoid.Health,
                        MaxHealth = humanoid.MaxHealth
                    })
                end
            end)
        end
    end
    
    return enemies
end

local function GetDeadEnemies()
    local dead = {}
    local entityFolder = Workspace:FindFirstChild("EntityFolder")
    
    if entityFolder then
        for _, entity in pairs(entityFolder:GetChildren()) do
            pcall(function()
                local humanoid = entity:FindFirstChildOfClass("Humanoid")
                local hrp = entity:FindFirstChild("HumanoidRootPart")
                local isPlayer = Players:GetPlayerFromCharacter(entity)
                
                if humanoid and hrp and not isPlayer and humanoid.Health <= 0 then
                    table.insert(dead, {
                        Model = entity,
                        HRP = hrp
                    })
                end
            end)
        end
    end
    
    return dead
end

local function GetNearestEnemy()
    local enemies = GetEnemies()
    local nearest = nil
    local nearestDist = math.huge
    
    for _, enemy in pairs(enemies) do
        local dist = (HumanoidRootPart.Position - enemy.HRP.Position).Magnitude
        if dist < nearestDist then
            nearestDist = dist
            nearest = enemy
        end
    end
    
    return nearest, nearestDist
end

local function TeleportToEnemy(enemy)
    if enemy and enemy.HRP then
        HumanoidRootPart.CFrame = enemy.HRP.CFrame * CFrame.new(0, 0, Settings.FarmDistance)
    end
end

local function BringEnemy(enemy)
    if enemy and enemy.HRP then
        pcall(function()
            enemy.HRP.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -Settings.FarmDistance)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  COMBAT FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function Attack()
    FireRemote(CombatEvents.Attack)
end

local function UseSkill(skillNumber)
    FireRemote(CombatEvents.UseSkill, skillNumber)
end

local function UseAllSkills()
    for i = 1, 4 do
        UseSkill(i)
        task.wait(0.05)
    end
end

local function Dash()
    FireRemote(CombatEvents.Dash)
end

local function Sprint(enabled)
    FireRemote(CombatEvents.Sprint, enabled)
end

-- ═══════════════════════════════════════════════════════════════
--  SHADOW/ARISE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function TryArise()
    FireRemote(ShadowEvents.TryArise)
    ClickAriseButton()
end

local function AriseAll()
    FireRemote(ShadowEvents.Arise)
    ClickAriseButton()
end

local function EquipBestShadows()
    FireRemote(ShadowEvents.EquipBest)
    ClickEquipBest()
end

local function UnequipAllShadows()
    FireRemote(ShadowEvents.UnequipAll)
end

local function SellShadows(rarity)
    FireRemote(ShadowEvents.Sell, rarity)
end

-- ═══════════════════════════════════════════════════════════════
--  QUEST FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function AcceptQuest()
    FireRemote(QuestEvents.Setup)
    ClickQuestAccept()
end

local function RedeemQuest()
    FireRemote(QuestEvents.Redeem)
end

local function CancelQuest()
    FireRemote(QuestEvents.Cancel)
end

-- ═══════════════════════════════════════════════════════════════
--  DUNGEON FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function StartDungeon(dungeonId)
    FireRemote(DungeonEvents.Start, dungeonId or Settings.SelectedDungeon)
end

local function GoToLobby()
    FireRemote(DungeonEvents.Lobby)
end

local function RankUp()
    FireRemote(DungeonEvents.RankUp)
end

-- ═══════════════════════════════════════════════════════════════
--  STAT FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local StatMap = {
    DMG = 1,
    VIT = 2,
    AGI = 3,
    MNA = 4
}

local function UpgradeStat(statName, amount)
    amount = amount or 1
    local statId = StatMap[statName] or 1
    
    for i = 1, amount do
        FireRemote(StatsEvent, statId)
        task.wait(0.1)
    end
end

local function ResetStats()
    FireRemote(InventoryEvents.ResetStats)
end

-- ═══════════════════════════════════════════════════════════════
--  INVENTORY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function OpenChests()
    FireRemote(InventoryEvents.ChestOpen)
end

local function Collect()
    ClickCollectButton()
end

-- ═══════════════════════════════════════════════════════════════
--  CODE REDEMPTION
-- ═══════════════════════════════════════════════════════════════

local KnownCodes = {
    "RELEASE", "UPDATE1", "UPDATE2", "UPDATE3", "UPDATE4",
    "LIKES1K", "LIKES5K", "LIKES10K", "LIKES25K", "LIKES50K", "LIKES100K",
    "FREEGEMS", "SHADOW", "ARISE", "RAGNAROK",
    "HALLOWEEN", "THANKSGIVING", "CHRISTMAS", "NEWYEAR",
    "100KVISITS", "500KVISITS", "1MVISITS",
    "CLGAMES", "DISCORD", "TWITTER", "YOUTUBE",
    "SORRYFORBUGS", "BUGFIX", "MAINTENANCE",
    "VIP", "GEMS", "GOLD", "LUCKY"
}

local function RedeemCode(code)
    FireRemote(CodeRedeem, code)
end

local function RedeemAllCodes()
    for _, code in pairs(KnownCodes) do
        RedeemCode(code)
        task.wait(0.5)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  MAIN LOOPS
-- ═══════════════════════════════════════════════════════════════

-- Auto Farm Loop
spawn(function()
    while task.wait(Settings.AttackSpeed) do
        if Settings.AutoFarm then
            pcall(function()
                local enemy, dist = GetNearestEnemy()
                
                if enemy then
                    -- Teleport or bring
                    if Settings.TeleportToEnemy and dist > Settings.FarmDistance then
                        TeleportToEnemy(enemy)
                    elseif Settings.BringEnemies then
                        BringEnemy(enemy)
                    end
                    
                    -- Attack
                    Attack()
                    
                    -- Skills
                    if Settings.AutoSkills then
                        UseAllSkills()
                    end
                    
                    -- Dash
                    if Settings.AutoDash then
                        Dash()
                    end
                end
            end)
        end
    end
end)

-- Auto Sprint Loop
spawn(function()
    while task.wait(0.5) do
        if Settings.AutoSprint then
            Sprint(true)
        end
    end
end)

-- Auto Arise Loop
spawn(function()
    while task.wait(1) do
        if Settings.AutoArise then
            pcall(function()
                local dead = GetDeadEnemies()
                if #dead > 0 then
                    TryArise()
                    ClickAriseButton()
                    ClickCollectButton()
                end
            end)
        end
    end
end)

-- Auto Equip Best Loop
spawn(function()
    while task.wait(5) do
        if Settings.AutoEquipBest then
            EquipBestShadows()
        end
    end
end)

-- Auto Sell Loop
spawn(function()
    while task.wait(10) do
        if Settings.AutoSellCommon then
            SellShadows("Common")
        end
        if Settings.AutoSellUncommon then
            SellShadows("Uncommon")
        end
    end
end)

-- Auto Quest Loop
spawn(function()
    while task.wait(3) do
        if Settings.AutoQuest then
            if Settings.AutoRedeemQuest then
                RedeemQuest()
            end
            task.wait(0.5)
            if Settings.AutoAcceptQuest then
                AcceptQuest()
            end
        end
    end
end)

-- Auto Stats Loop
spawn(function()
    while task.wait(1) do
        if Settings.AutoStats then
            UpgradeStat(Settings.StatToUpgrade, 1)
        end
    end
end)

-- Auto Collect Loop
spawn(function()
    while task.wait(0.5) do
        if Settings.AutoCollect then
            Collect()
            ClickCollectButton()
        end
    end
end)

-- Auto Open Chest Loop
spawn(function()
    while task.wait(5) do
        if Settings.AutoOpenChest then
            OpenChests()
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- No Clip Loop
spawn(function()
    while task.wait() do
        if Settings.NoClip and Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Speed Maintenance
spawn(function()
    while task.wait(1) do
        pcall(function()
            if Humanoid then
                if Settings.WalkSpeed > 16 then
                    Humanoid.WalkSpeed = Settings.WalkSpeed
                end
                if Settings.JumpPower > 50 then
                    Humanoid.JumpPower = Settings.JumpPower
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  CREATE UI
-- ═══════════════════════════════════════════════════════════════

local Window = OrionLib:MakeWindow({
    Name = "⚔️ Arise Ragnarok | Full Script",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "AriseRagnarokFull",
    IntroEnabled = true,
    IntroText = "⚔️ Arise Ragnarok Script"
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 1: AUTO FARM
-- ═══════════════════════════════════════════════════════════════

local FarmTab = Window:MakeTab({
    Name = "⚔️ Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

FarmTab:AddSection({Name = "🎯 Auto Farm"})

FarmTab:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(val)
        Settings.AutoFarm = val
        Notify("Auto Farm", val and "Enabled" or "Disabled")
    end
})

FarmTab:AddToggle({
    Name = "Auto Skills (1-4)",
    Default = false,
    Callback = function(val)
        Settings.AutoSkills = val
    end
})

FarmTab:AddToggle({
    Name = "Auto Dash",
    Default = false,
    Callback = function(val)
        Settings.AutoDash = val
    end
})

FarmTab:AddToggle({
    Name = "Auto Sprint",
    Default = false,
    Callback = function(val)
        Settings.AutoSprint = val
    end
})

FarmTab:AddSection({Name = "📍 Movement"})

FarmTab:AddToggle({
    Name = "Teleport to Enemy",
    Default = true,
    Callback = function(val)
        Settings.TeleportToEnemy = val
        if val then Settings.BringEnemies = false end
    end
})

FarmTab:AddToggle({
    Name = "Bring Enemies to You",
    Default = false,
    Callback = function(val)
        Settings.BringEnemies = val
        if val then Settings.TeleportToEnemy = false end
    end
})

FarmTab:AddSlider({
    Name = "Farm Distance",
    Min = 5,
    Max = 50,
    Default = 10,
    Increment = 1,
    ValueName = "studs",
    Callback = function(val)
        Settings.FarmDistance = val
    end
})

FarmTab:AddSlider({
    Name = "Attack Speed",
    Min = 0.05,
    Max = 1,
    Default = 0.1,
    Increment = 0.05,
    ValueName = "sec",
    Callback = function(val)
        Settings.AttackSpeed = val
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 2: SHADOW/ARISE
-- ═══════════════════════════════════════════════════════════════

local ShadowTab = Window:MakeTab({
    Name = "👻 Shadow",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ShadowTab:AddSection({Name = "👻 Auto Shadow"})

ShadowTab:AddToggle({
    Name = "Auto Arise (Dead Enemies)",
    Default = false,
    Callback = function(val)
        Settings.AutoArise = val
        Notify("Auto Arise", val and "Enabled" or "Disabled")
    end
})

ShadowTab:AddToggle({
    Name = "Auto Equip Best",
    Default = false,
    Callback = function(val)
        Settings.AutoEquipBest = val
    end
})

ShadowTab:AddToggle({
    Name = "Auto Collect Loot",
    Default = false,
    Callback = function(val)
        Settings.AutoCollect = val
    end
})

ShadowTab:AddSection({Name = "🗑️ Auto Sell"})

ShadowTab:AddToggle({
    Name = "Auto Sell Common",
    Default = false,
    Callback = function(val)
        Settings.AutoSellCommon = val
    end
})

ShadowTab:AddToggle({
    Name = "Auto Sell Uncommon",
    Default = false,
    Callback = function(val)
        Settings.AutoSellUncommon = val
    end
})

ShadowTab:AddSection({Name = "🖱️ Manual Actions"})

ShadowTab:AddButton({
    Name = "Try Arise Now",
    Callback = function()
        TryArise()
        Notify("Arise", "Attempting to arise!")
    end
})

ShadowTab:AddButton({
    Name = "Equip Best Shadows",
    Callback = function()
        EquipBestShadows()
        Notify("Shadows", "Equipped best shadows!")
    end
})

ShadowTab:AddButton({
    Name = "Unequip All Shadows",
    Callback = function()
        UnequipAllShadows()
        Notify("Shadows", "Unequipped all!")
    end
})

ShadowTab:AddButton({
    Name = "Collect Loot",
    Callback = function()
        Collect()
        Notify("Collect", "Collecting loot!")
    end
})

ShadowTab:AddButton({
    Name = "Sell Common Shadows",
    Callback = function()
        SellShadows("Common")
        Notify("Sell", "Sold common shadows!")
    end
})

ShadowTab:AddButton({
    Name = "Sell Uncommon Shadows",
    Callback = function()
        SellShadows("Uncommon")
        Notify("Sell", "Sold uncommon shadows!")
    end
})

ShadowTab:AddButton({
    Name = "Sell Rare Shadows",
    Callback = function()
        SellShadows("Rare")
        Notify("Sell", "Sold rare shadows!")
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 3: QUEST
-- ═══════════════════════════════════════════════════════════════

local QuestTab = Window:MakeTab({
    Name = "📋 Quest",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

QuestTab:AddSection({Name = "📋 Auto Quest"})

QuestTab:AddToggle({
    Name = "Auto Quest",
    Default = false,
    Callback = function(val)
        Settings.AutoQuest = val
        Settings.AutoAcceptQuest = val
        Settings.AutoRedeemQuest = val
    end
})

QuestTab:AddToggle({
    Name = "Auto Accept Quest",
    Default = false,
    Callback = function(val)
        Settings.AutoAcceptQuest = val
    end
})

QuestTab:AddToggle({
    Name = "Auto Redeem Quest",
    Default = false,
    Callback = function(val)
        Settings.AutoRedeemQuest = val
    end
})

QuestTab:AddSection({Name = "🖱️ Manual Actions"})

QuestTab:AddButton({
    Name = "Accept Quest",
    Callback = function()
        AcceptQuest()
        Notify("Quest", "Quest accepted!")
    end
})

QuestTab:AddButton({
    Name = "Redeem Quest Reward",
    Callback = function()
        RedeemQuest()
        Notify("Quest", "Reward redeemed!")
    end
})

QuestTab:AddButton({
    Name = "Cancel Quest",
    Callback = function()
        CancelQuest()
        Notify("Quest", "Quest cancelled!")
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 4: DUNGEON
-- ═══════════════════════════════════════════════════════════════

local DungeonTab = Window:MakeTab({
    Name = "🏰 Dungeon",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

DungeonTab:AddSection({Name = "🏰 Dungeon Controls"})

DungeonTab:AddDropdown({
    Name = "Select Dungeon",
    Default = "1",
    Options = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "Tutorial"},
    Callback = function(val)
        Settings.SelectedDungeon = val
    end
})

DungeonTab:AddDropdown({
    Name = "Difficulty",
    Default = "Easy",
    Options = {"Easy", "Normal", "Hard"},
    Callback = function(val)
        Settings.DungeonDifficulty = val
    end
})

DungeonTab:AddButton({
    Name = "Start Dungeon",
    Callback = function()
        StartDungeon(Settings.SelectedDungeon)
        Notify("Dungeon", "Starting dungeon " .. Settings.SelectedDungeon)
    end
})

DungeonTab:AddButton({
    Name = "Go to Lobby",
    Callback = function()
        GoToLobby()
        Notify("Dungeon", "Returning to lobby!")
    end
})

DungeonTab:AddButton({
    Name = "Rank Up",
    Callback = function()
        RankUp()
        Notify("Rank", "Attempting rank up!")
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 5: STATS
-- ═══════════════════════════════════════════════════════════════

local StatsTab = Window:MakeTab({
    Name = "📊 Stats",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

StatsTab:AddSection({Name = "📊 Auto Stats"})

StatsTab:AddToggle({
    Name = "Auto Upgrade Stats",
    Default = false,
    Callback = function(val)
        Settings.AutoStats = val
    end
})

StatsTab:AddDropdown({
    Name = "Stat to Upgrade",
    Default = "DMG",
    Options = {"DMG", "VIT", "AGI", "MNA"},
    Callback = function(val)
        Settings.StatToUpgrade = val
    end
})

StatsTab:AddSection({Name = "🖱️ Manual Upgrade"})

StatsTab:AddButton({
    Name = "Upgrade DMG (x10)",
    Callback = function()
        UpgradeStat("DMG", 10)
        Notify("Stats", "DMG upgraded!")
    end
})

StatsTab:AddButton({
    Name = "Upgrade VIT (x10)",
    Callback = function()
        UpgradeStat("VIT", 10)
        Notify("Stats", "VIT upgraded!")
    end
})

StatsTab:AddButton({
    Name = "Upgrade AGI (x10)",
    Callback = function()
        UpgradeStat("AGI", 10)
        Notify("Stats", "AGI upgraded!")
    end
})

StatsTab:AddButton({
    Name = "Upgrade MNA (x10)",
    Callback = function()
        UpgradeStat("MNA", 10)
        Notify("Stats", "MNA upgraded!")
    end
})

StatsTab:AddButton({
    Name = "Reset Stats",
    Callback = function()
        ResetStats()
        Notify("Stats", "Stats reset!")
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 6: INVENTORY
-- ═══════════════════════════════════════════════════════════════

local InvTab = Window:MakeTab({
    Name = "🎒 Inventory",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

InvTab:AddSection({Name = "📦 Chests"})

InvTab:AddToggle({
    Name = "Auto Open Chests",
    Default = false,
    Callback = function(val)
        Settings.AutoOpenChest = val
    end
})

InvTab:AddButton({
    Name = "Open All Chests",
    Callback = function()
        OpenChests()
        Notify("Chests", "Opening chests!")
    end
})

InvTab:AddSection({Name = "⚔️ Equipment"})

InvTab:AddButton({
    Name = "Equip Best Weapon",
    Callback = function()
        FireRemote(InventoryEvents.WeaponEquip)
        Notify("Weapon", "Equipped!")
    end
})

InvTab:AddButton({
    Name = "Equip Best Armor",
    Callback = function()
        FireRemote(InventoryEvents.ArmorEquip)
        Notify("Armor", "Equipped!")
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 7: CODES
-- ═══════════════════════════════════════════════════════════════

local CodesTab = Window:MakeTab({
    Name = "🎁 Codes",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

CodesTab:AddSection({Name = "🎁 Redeem Codes"})

CodesTab:AddButton({
    Name = "Redeem ALL Codes",
    Callback = function()
        Notify("Codes", "Redeeming all codes...")
        RedeemAllCodes()
        Notify("Codes", "All codes redeemed!")
    end
})

CodesTab:AddTextbox({
    Name = "Custom Code",
    Default = "",
    TextDisappear = false,
    Callback = function(val)
        if val and val ~= "" then
            RedeemCode(val)
            Notify("Code", "Redeemed: " .. val)
        end
    end
})

CodesTab:AddParagraph("Known Codes", table.concat(KnownCodes, ", "))

-- ═══════════════════════════════════════════════════════════════
--  TAB 8: PLAYER
-- ═══════════════════════════════════════════════════════════════

local PlayerTab = Window:MakeTab({
    Name = "🧑 Player",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

PlayerTab:AddSection({Name = "🏃 Movement"})

PlayerTab:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 500,
    Default = 16,
    Increment = 1,
    Callback = function(val)
        Settings.WalkSpeed = val
        if Humanoid then Humanoid.WalkSpeed = val end
    end
})

PlayerTab:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 500,
    Default = 50,
    Increment = 1,
    Callback = function(val)
        Settings.JumpPower = val
        if Humanoid then Humanoid.JumpPower = val end
    end
})

PlayerTab:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(val)
        Settings.InfiniteJump = val
    end
})

PlayerTab:AddToggle({
    Name = "No Clip",
    Default = false,
    Callback = function(val)
        Settings.NoClip = val
    end
})

PlayerTab:AddSection({Name = "📍 Teleport"})

PlayerTab:AddButton({
    Name = "TP to Nearest Enemy",
    Callback = function()
        local enemy = GetNearestEnemy()
        if enemy then
            TeleportToEnemy(enemy)
            Notify("Teleport", "Teleported to " .. enemy.Model.Name)
        else
            Notify("Teleport", "No enemies found!")
        end
    end
})

PlayerTab:AddButton({
    Name = "Reset Character",
    Callback = function()
        if Humanoid then Humanoid.Health = 0 end
    end
})

-- ═══════════════════════════════════════════════════════════════
--  TAB 9: SETTINGS
-- ═══════════════════════════════════════════════════════════════

local SettingsTab = Window:MakeTab({
    Name = "⚙️ Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSection({Name = "🎨 UI"})

SettingsTab:AddBind({
    Name = "Toggle UI",
    Default = Enum.KeyCode.RightShift,
    Hold = false,
    Callback = function()
        OrionLib:ToggleUI()
    end
})

SettingsTab:AddButton({
    Name = "Destroy Script",
    Callback = function()
        OrionLib:Destroy()
        getgenv().__ARISE_SCRIPT = nil
    end
})

SettingsTab:AddSection({Name = "📖 Info"})

SettingsTab:AddLabel("Game: Arise Ragnarok")
SettingsTab:AddLabel("Place ID: 137700422270232")
SettingsTab:AddLabel("Player: " .. Player.Name)
SettingsTab:AddLabel("Rank: " .. (Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Rank") and Player.leaderstats.Rank.Value or "Unknown"))

-- ═══════════════════════════════════════════════════════════════
--  GLOBAL COMMANDS
-- ═══════════════════════════════════════════════════════════════

getgenv().Arise = {
    Farm = function() Settings.AutoFarm = not Settings.AutoFarm end,
    Arise = TryArise,
    Collect = Collect,
    EquipBest = EquipBestShadows,
    Quest = AcceptQuest,
    Redeem = RedeemQuest,
    RedeemCodes = RedeemAllCodes,
    Settings = Settings
}

-- ═══════════════════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════════════════

OrionLib:Init()

print("")
print("╔═══════════════════════════════════════════════════════════════╗")
print("║     ⚔️ ARISE RAGNAROK SCRIPT LOADED!                         ║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  Features:                                                    ║")
print("║  • Auto Farm with Skills & Dash                               ║")
print("║  • Auto Arise Dead Enemies                                    ║")
print("║  • Auto Collect Loot                                          ║")
print("║  • Auto Quest Accept/Redeem                                   ║")
print("║  • Auto Stats Upgrade                                         ║")
print("║  • Auto Equip Best Shadows                                    ║")
print("║  • Auto Sell Shadows                                          ║")
print("║  • Dungeon Controls                                           ║")
print("║  • Code Redemption                                            ║")
print("║  • Speed/Jump/NoClip                                          ║")
print("║                                                               ║")
print("║  Press RightShift to toggle UI                                ║")
print("╚═══════════════════════════════════════════════════════════════╝")
print("")

Notify("✅ Script Loaded!", "Arise Ragnarok - Full Script Ready!", 5)
