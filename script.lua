-- ========== PART 1 of 7 ==========
-- Solo Leveling FULL AUTO + DUNGEON + AUTO SAVE CONFIG
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Config System
local ConfigFileName = "SoloLevelingConfig.json"
local Config = {
    AutoKill = false,
    KillAura = false,
    AutoAttack = false,
    AutoQuest = false,
    AutoArise = false,
    AutoCollect = false,
    AutoTPDead = false,
    AutoRespawn = false,
    AutoDungeon = false,
    AutoDungeonKill = false,
    AutoDungeonStart = false,
    AutoDungeonCollect = false,
    DungeonDifficulty = "Easy",
    ArisePriority = "Arise First",
    AttackSpeed = 10,
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    Noclip = false
}

local function SaveConfig()
    local success, err = pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(Config))
    end)
    if success then
        OrionLib:MakeNotification({Name = "Config", Content = "Settings Saved! ✅", Time = 2})
    end
end

local function LoadConfig()
    local success, data = pcall(function()
        if isfile(ConfigFileName) then
            return HttpService:JSONDecode(readfile(ConfigFileName))
        end
        return nil
    end)
    if success and data then
        for key, value in pairs(data) do
            Config[key] = value
        end
        OrionLib:MakeNotification({Name = "Config", Content = "Settings Loaded! ✅", Time = 2})
        return true
    end
    return false
end

local function DeleteConfig()
    local success = pcall(function()
        if isfile(ConfigFileName) then
            delfile(ConfigFileName)
        end
    end)
    if success then
        OrionLib:MakeNotification({Name = "Config", Content = "Config Deleted! 🗑️", Time = 2})
    end
end

-- Load saved config
LoadConfig()

local AutoKillEnabled = Config.AutoKill
local KillAuraEnabled = Config.KillAura
local AutoAttackEnabled = Config.AutoAttack
local AutoQuestEnabled = Config.AutoQuest
local AutoAriseEnabled = Config.AutoArise
local AutoCollectEnabled = Config.AutoCollect
local AutoTPDeadEnabled = Config.AutoTPDead
local AutoRespawnEnabled = Config.AutoRespawn
local AutoDungeonEnabled = Config.AutoDungeon
local AutoDungeonKill = Config.AutoDungeonKill
local AutoDungeonStart = Config.AutoDungeonStart
local AutoDungeonCollect = Config.AutoDungeonCollect
local DungeonDifficulty = Config.DungeonDifficulty
local ArisePriority = Config.ArisePriority == "Arise First"
local AttackSpeed = Config.AttackSpeed
local QuestState = "IDLE"
local DungeonState = "IDLE"
local LastQuestPointPosition = nil
local AriseCount = 0
local CollectCount = 0
local SkippedEnemies = {}

local Window = OrionLib:MakeWindow({Name = "Solo Leveling", HidePremium = true, IntroEnabled = false})
OrionLib:MakeNotification({Name = "Loaded", Content = "Full Auto Ready!", Time = 3})

local Events = ReplicatedStorage:WaitForChild("Events")
local QuestEvents = Events:WaitForChild("Quest")
local DialogRemote = QuestEvents:FindFirstChild("Dialog")
local Combat = Events:WaitForChild("Combat")
local AttackEvent = Combat:WaitForChild("Attack")
-- ========== END PART 1 ==========
-- ========== PART 2 of 7 ==========
local function GetCharacter() return Player.Character end
local function GetHumanoid() local char = GetCharacter() if char then return char:FindFirstChild("Humanoid") end return nil end
local function GetRootPart() local char = GetCharacter() if char then return char:FindFirstChild("HumanoidRootPart") end return nil end
local function IsAlive() local hum = GetHumanoid() if hum and hum.Health > 0 then return true end return false end
local function TeleportTo(cframe) local root = GetRootPart() if root and IsAlive() then root.CFrame = cframe end end
local function IsPlayer(name) for _, plr in pairs(Players:GetPlayers()) do if plr.Name == name then return true end end return false end
local function IsQuestEnemy(name) if name:match("%d+_E_%d+") then return true end return false end

local function GetQuestPoint()
    local instanced = Workspace:FindFirstChild("Instanced")
    if instanced then
        local vfxFolder = instanced:FindFirstChild("VFX")
        if vfxFolder then
            local questPoint = vfxFolder:FindFirstChild("Quest Point")
            if questPoint and questPoint:IsA("Part") then return questPoint end
        end
    end
    return nil
end

local function GetDungeonPortal()
    local instanced = Workspace:FindFirstChild("Instanced")
    if instanced then
        local portal = instanced:FindFirstChild("Portal")
        if portal then
            for _, child in pairs(portal:GetDescendants()) do
                if child:IsA("BasePart") then return child end
            end
        end
    end
    return nil
end

local function GetDungeonSpot()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local city = map:FindFirstChild("City 1")
        if city then
            local spot = city:FindFirstChild("Dungeon Spot")
            if spot then
                for _, child in pairs(spot:GetDescendants()) do
                    if child:IsA("BasePart") then return child end
                end
            end
        end
    end
    return nil
end

local function GetQuestEnemies()
    local enemies = {}
    local searchPosition = nil
    local questPoint = GetQuestPoint()
    if questPoint then searchPosition = questPoint.Position LastQuestPointPosition = searchPosition
    elseif LastQuestPointPosition then searchPosition = LastQuestPointPosition end
    if not searchPosition then return enemies end
    local folders = {Workspace:FindFirstChild("EntityFolder"), Workspace:FindFirstChild("EntityFolder_Hitted1"), Workspace:FindFirstChild("EntityFolder_Hitted2")}
    for _, folder in pairs(folders) do
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local name = child.Name
                    if IsPlayer(name) then continue end
                    if IsQuestEnemy(name) then
                        local hum = child:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
                            if root and (root.Position - searchPosition).Magnitude < 150 then
                                table.insert(enemies, {Model = child, Root = root, Humanoid = hum, Name = name})
                            end
                        end
                    end
                end
            end
        end
    end
    return enemies
end

local function GetDungeonEnemies()
    local enemies = {}
    local folders = {Workspace:FindFirstChild("EntityFolder"), Workspace:FindFirstChild("EntityFolder_Hitted1"), Workspace:FindFirstChild("EntityFolder_Hitted2")}
    for _, folder in pairs(folders) do
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local name = child.Name
                    if IsPlayer(name) then continue end
                    local hum = child:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
                        if root then table.insert(enemies, {Model = child, Root = root, Humanoid = hum, Name = name}) end
                    end
                end
            end
        end
    end
    return enemies
end
-- ========== END PART 2 ==========
-- ========== PART 3 of 7 ==========
local function GetDeadEnemies()
    local enemies = {}
    local searchPosition = nil
    local questPoint = GetQuestPoint()
    if questPoint then searchPosition = questPoint.Position
    elseif LastQuestPointPosition then searchPosition = LastQuestPointPosition end
    if not searchPosition then return enemies end
    local folders = {Workspace:FindFirstChild("EntityFolder"), Workspace:FindFirstChild("EntityFolder_Hitted1"), Workspace:FindFirstChild("EntityFolder_Hitted2")}
    for _, folder in pairs(folders) do
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local name = child.Name
                    if IsPlayer(name) then continue end
                    if IsQuestEnemy(name) then
                        local hum = child:FindFirstChild("Humanoid")
                        if hum and hum.Health <= 0 then
                            local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
                            if root and (root.Position - searchPosition).Magnitude < 150 then
                                if not SkippedEnemies[name] then
                                    table.insert(enemies, {Model = child, Root = root, Humanoid = hum, Name = name})
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return enemies
end

local function GetClosestDeadEnemy()
    local root = GetRootPart() if not root then return nil end
    local closest, closestDist = nil, 9999
    for _, enemy in pairs(GetDeadEnemies()) do
        if enemy.Root then
            local dist = (root.Position - enemy.Root.Position).Magnitude
            if dist < closestDist then closest = enemy closestDist = dist end
        end
    end
    return closest
end

local function GetClosestQuestEnemy()
    local root = GetRootPart() if not root then return nil end
    local closest, closestDist = nil, 9999
    for _, enemy in pairs(GetQuestEnemies()) do
        if enemy.Root then
            local dist = (root.Position - enemy.Root.Position).Magnitude
            if dist < closestDist then closest = enemy closestDist = dist end
        end
    end
    return closest
end

local function GetClosestDungeonEnemy()
    local root = GetRootPart() if not root then return nil end
    local closest, closestDist = nil, 9999
    for _, enemy in pairs(GetDungeonEnemies()) do
        if enemy.Root then
            local dist = (root.Position - enemy.Root.Position).Magnitude
            if dist < closestDist then closest = enemy closestDist = dist end
        end
    end
    return closest
end

local function HasQuest(npc)
    local head = npc:FindFirstChild("Head")
    if head and head:FindFirstChild("Quest Simbol") then return true end
    return false
end

local function GetQuestNPCs()
    local npcs = {}
    local instanced = Workspace:FindFirstChild("Instanced")
    if instanced then
        local civilianFolder = instanced:FindFirstChild("Civilian")
        if civilianFolder then
            for _, npc in pairs(civilianFolder:GetChildren()) do
                if npc:IsA("Model") and npc.Name:match("C_%d+") and HasQuest(npc) then
                    local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") or npc:FindFirstChildWhichIsA("BasePart")
                    if root then table.insert(npcs, {Model = npc, Root = root, Name = npc.Name}) end
                end
            end
        end
    end
    return npcs
end

local function GetClosestQuestNPC()
    local root = GetRootPart() if not root then return nil end
    local closest, closestDist = nil, 9999
    for _, npc in pairs(GetQuestNPCs()) do
        if npc.Root then
            local dist = (root.Position - npc.Root.Position).Magnitude
            if dist < closestDist then closest = npc closestDist = dist end
        end
    end
    return closest
end

local function AcceptQuest(npcName)
    if DialogRemote then
        pcall(function() DialogRemote:FireServer(npcName, true, true) task.wait(0.3) DialogRemote:FireServer(npcName, false, true) end)
    end
end
-- ========== END PART 3 ==========
-- ========== PART 4 of 7 ==========
local function FindAriseButton()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("ImageButton") and gui.Name == "Content" then
            if gui.Parent and gui.Parent.Name == "Arise" and gui.Parent.Parent and gui.Parent.Parent.Name == "Mobile Buttons" then
                if gui.Visible then return gui end
            end
        end
    end
    return nil
end

local function FindCollectButton()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("ImageButton") and gui.Name == "Content" then
            if gui.Parent and gui.Parent.Name == "Collect" and gui.Parent.Parent and gui.Parent.Parent.Name == "Mobile Buttons" then
                if gui.Visible then return gui end
            end
        end
    end
    return nil
end

local function FindButtonByName(buttonName)
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
            if gui.Name == buttonName or (gui.Parent and gui.Parent.Name == buttonName) then return gui end
            if gui:IsA("TextButton") and gui.Text == buttonName then return gui end
        end
    end
    return nil
end

local function FindDungeonButton(name)
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == name and gui.Visible then
            for _, child in pairs(gui:GetDescendants()) do
                if child:IsA("TextButton") or child:IsA("ImageButton") then return child end
            end
        end
    end
    return nil
end

local function ClickButton(btn)
    if not btn then return false end
    pcall(function() firesignal(btn.MouseButton1Click) end)
    pcall(function() firesignal(btn.MouseButton1Down) task.wait(0.05) firesignal(btn.MouseButton1Up) end)
    pcall(function() for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end end)
    pcall(function() fireclick(btn) end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
    end)
    return true
end

local function HasAriseOrCollect() return FindAriseButton() ~= nil or FindCollectButton() ~= nil end

local function ClickAllAriseCollect()
    local clicked = false
    if ArisePriority then
        if AutoAriseEnabled then local btn = FindAriseButton() if btn then ClickButton(btn) AriseCount = AriseCount + 1 clicked = true task.wait(0.3) end end
        if AutoCollectEnabled then local btn = FindCollectButton() if btn then ClickButton(btn) CollectCount = CollectCount + 1 clicked = true task.wait(0.3) end end
    else
        if AutoCollectEnabled then local btn = FindCollectButton() if btn then ClickButton(btn) CollectCount = CollectCount + 1 clicked = true task.wait(0.3) end end
        if AutoAriseEnabled then local btn = FindAriseButton() if btn then ClickButton(btn) AriseCount = AriseCount + 1 clicked = true task.wait(0.3) end end
    end
    return clicked
end

local function FastAttack() if not IsAlive() then return end for i = 1, AttackSpeed do pcall(function() AttackEvent:FireServer() end) end end
local function ClearSkippedEnemies() SkippedEnemies = {} end

local function IsInDungeon()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Boss Health" and gui.Visible then return true end
    end
    return false
end

local function IsDungeonFinished()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Dungeon Finish" and gui.Visible then return true end
    end
    return false
end
-- ========== END PART 4 ==========
-- ========== PART 5 of 7 ==========
local KillTab = Window:MakeTab({Name = "Auto Kill", Icon = "rbxassetid://4483345998", PremiumOnly = false})
KillTab:AddSection({Name = "⚔️ Auto Kill"})
KillTab:AddToggle({Name = "Auto Kill", Default = Config.AutoKill, Callback = function(Value) AutoKillEnabled = Value Config.AutoKill = Value if Value then spawn(function() while AutoKillEnabled do if IsAlive() then local enemy = GetClosestQuestEnemy() if enemy and enemy.Root then TeleportTo(enemy.Root.CFrame * CFrame.new(0, 0, 3)) end end task.wait(0.1) end end) end end})
KillTab:AddToggle({Name = "Kill Aura", Default = Config.KillAura, Callback = function(Value) KillAuraEnabled = Value Config.KillAura = Value end})
RunService.Heartbeat:Connect(function() if KillAuraEnabled and IsAlive() then local root = GetRootPart() if root then for _, enemy in pairs(GetQuestEnemies()) do if enemy.Root then enemy.Root.CFrame = root.CFrame * CFrame.new(0, 0, 3) end end end end end)
KillTab:AddSection({Name = "⚡ Auto Attack"})
KillTab:AddToggle({Name = "Auto Attack", Default = Config.AutoAttack, Callback = function(Value) AutoAttackEnabled = Value Config.AutoAttack = Value if Value then spawn(function() while AutoAttackEnabled do if IsAlive() and (#GetQuestEnemies() > 0 or #GetDungeonEnemies() > 0) then FastAttack() end task.wait(0.05) end end) end end})
KillTab:AddSlider({Name = "Attack Speed", Min = 1, Max = 50, Default = Config.AttackSpeed, Increment = 1, Callback = function(Value) AttackSpeed = Value Config.AttackSpeed = Value end})
local EnemyLabel = KillTab:AddLabel("Enemies: 0")
local DeadEnemyLabel = KillTab:AddLabel("Dead: 0")
local AliveLabel = KillTab:AddLabel("Player: ✅")
local SkippedLabel = KillTab:AddLabel("Skipped: 0")

local AriseTab = Window:MakeTab({Name = "Arise", Icon = "rbxassetid://4483345998", PremiumOnly = false})
AriseTab:AddSection({Name = "👻 Auto Arise & Collect"})
local AriseCountLabel = AriseTab:AddLabel("Arise: 0")
local CollectCountLabel = AriseTab:AddLabel("Collect: 0")
local ButtonFoundLabel = AriseTab:AddLabel("Buttons: ---")
AriseTab:AddToggle({Name = "Auto Arise", Default = Config.AutoArise, Callback = function(Value) AutoAriseEnabled = Value Config.AutoArise = Value end})
AriseTab:AddToggle({Name = "Auto Collect", Default = Config.AutoCollect, Callback = function(Value) AutoCollectEnabled = Value Config.AutoCollect = Value end})
AriseTab:AddDropdown({Name = "Priority", Default = Config.ArisePriority, Options = {"Arise First", "Collect First"}, Callback = function(Value) ArisePriority = (Value == "Arise First") Config.ArisePriority = Value end})
AriseTab:AddSection({Name = "📍 Auto TP"})
AriseTab:AddToggle({Name = "Auto TP to Dead", Default = Config.AutoTPDead, Callback = function(Value) AutoTPDeadEnabled = Value Config.AutoTPDead = Value end})
AriseTab:AddSection({Name = "🔧 Manual"})
AriseTab:AddButton({Name = "Click Arise", Callback = function() ClickButton(FindAriseButton()) end})
AriseTab:AddButton({Name = "Click Collect", Callback = function() ClickButton(FindCollectButton()) end})
AriseTab:AddButton({Name = "Clear Skipped", Callback = function() ClearSkippedEnemies() end})
-- ========== END PART 5 ==========
-- ========== PART 6 of 7 ==========
local DungeonTab = Window:MakeTab({Name = "Dungeon", Icon = "rbxassetid://4483345998", PremiumOnly = false})
DungeonTab:AddSection({Name = "🏰 Auto Dungeon"})
local DungeonStatusLabel = DungeonTab:AddLabel("Status: Idle")
local InDungeonLabel = DungeonTab:AddLabel("In Dungeon: ❌")
local DungeonEnemyLabel = DungeonTab:AddLabel("Dungeon Enemies: 0")

DungeonTab:AddDropdown({Name = "Difficulty", Default = Config.DungeonDifficulty, Options = {"Easy", "Normal", "Hard"}, Callback = function(Value) DungeonDifficulty = Value Config.DungeonDifficulty = Value end})

DungeonTab:AddToggle({Name = "Auto Dungeon Kill", Default = Config.AutoDungeonKill, Callback = function(Value) AutoDungeonKill = Value Config.AutoDungeonKill = Value if Value then spawn(function() while AutoDungeonKill do if IsAlive() and IsInDungeon() then local enemy = GetClosestDungeonEnemy() if enemy and enemy.Root then TeleportTo(enemy.Root.CFrame * CFrame.new(0, 0, 3)) end end task.wait(0.1) end end) end end})

DungeonTab:AddToggle({Name = "Auto Start Dungeon", Default = Config.AutoDungeonStart, Callback = function(Value) AutoDungeonStart = Value Config.AutoDungeonStart = Value if Value then spawn(function() while AutoDungeonStart do if IsAlive() then local startBtn = FindButtonByName("Start") if startBtn then ClickButton(startBtn) end local startDungeon = FindDungeonButton("Start Dungeon") if startDungeon then ClickButton(startDungeon) end end task.wait(1) end end) end end})

DungeonTab:AddToggle({Name = "Auto Collect Items", Default = Config.AutoDungeonCollect, Callback = function(Value) AutoDungeonCollect = Value Config.AutoDungeonCollect = Value if Value then spawn(function() while AutoDungeonCollect do if IsAlive() then local instanced = Workspace:FindFirstChild("Instanced") if instanced then for _, item in pairs(instanced:GetDescendants()) do if item:IsA("BasePart") and (item.Name:lower():find("item") or item.Name:lower():find("drop") or item.Name:lower():find("loot") or item.Name:lower():find("chest")) then TeleportTo(item.CFrame) task.wait(0.2) end end end end task.wait(0.5) end end) end end})

DungeonTab:AddToggle({Name = "Auto Dungeon (Full)", Default = Config.AutoDungeon, Callback = function(Value) AutoDungeonEnabled = Value Config.AutoDungeon = Value DungeonState = "IDLE" if Value then spawn(function() while AutoDungeonEnabled do if not IsAlive() then task.wait(1) continue end if DungeonState == "IDLE" then if IsInDungeon() then DungeonState = "KILLING" else DungeonState = "GO_TO_PORTAL" end elseif DungeonState == "GO_TO_PORTAL" then DungeonStatusLabel:Set("Status: Going to Portal 🚶") local portal = GetDungeonPortal() if portal then TeleportTo(portal.CFrame * CFrame.new(0, 5, 0)) task.wait(1) DungeonState = "SELECT_DIFFICULTY" end elseif DungeonState == "SELECT_DIFFICULTY" then DungeonStatusLabel:Set("Status: Selecting " .. DungeonDifficulty) task.wait(0.5) local diffBtn = FindButtonByName(DungeonDifficulty) if diffBtn then ClickButton(diffBtn) task.wait(0.5) end local soloBtn = FindButtonByName("Solo") if soloBtn then ClickButton(soloBtn) task.wait(0.5) end DungeonState = "CREATE_DUNGEON" elseif DungeonState == "CREATE_DUNGEON" then DungeonStatusLabel:Set("Status: Creating 🔨") local createBtn = FindButtonByName("Create") if createBtn then ClickButton(createBtn) task.wait(1) end DungeonState = "START_DUNGEON" elseif DungeonState == "START_DUNGEON" then DungeonStatusLabel:Set("Status: Starting ▶️") local startBtn = FindButtonByName("Start") if startBtn then ClickButton(startBtn) task.wait(1) end DungeonState = "WAIT_ENTER" elseif DungeonState == "WAIT_ENTER" then DungeonStatusLabel:Set("Status: Waiting ⏳") for i = 1, 20 do if IsInDungeon() then DungeonState = "KILLING" break end local startBtn = FindButtonByName("Start") if startBtn then ClickButton(startBtn) end task.wait(0.5) end if DungeonState ~= "KILLING" then DungeonState = "IDLE" end elseif DungeonState == "KILLING" then DungeonStatusLabel:Set("Status: Killing 🔥") local enemies = GetDungeonEnemies() if #enemies > 0 then local enemy = GetClosestDungeonEnemy() if enemy and enemy.Root then TeleportTo(enemy.Root.CFrame * CFrame.new(0, 0, 3)) end else DungeonState = "COLLECT" end elseif DungeonState == "COLLECT" then DungeonStatusLabel:Set("Status: Collecting 💎") local instanced = Workspace:FindFirstChild("Instanced") if instanced then for _, item in pairs(instanced:GetDescendants()) do if item:IsA("BasePart") and (item.Name:lower():find("item") or item.Name:lower():find("drop") or item.Name:lower():find("loot")) then TeleportTo(item.CFrame) task.wait(0.2) end end end task.wait(1) if IsDungeonFinished() or not IsInDungeon() then DungeonState = "IDLE" elseif #GetDungeonEnemies() > 0 then DungeonState = "KILLING" end end task.wait(0.3) end end) end end})

DungeonTab:AddSection({Name = "🔧 Manual"})
DungeonTab:AddButton({Name = "TP to Portal", Callback = function() local portal = GetDungeonPortal() if portal then TeleportTo(portal.CFrame * CFrame.new(0, 5, 0)) end end})
DungeonTab:AddButton({Name = "Click Start", Callback = function() local startBtn = FindButtonByName("Start") if startBtn then ClickButton(startBtn) end end})
DungeonTab:AddButton({Name = "Collect Items Now", Callback = function() local instanced = Workspace:FindFirstChild("Instanced") if instanced then for _, item in pairs(instanced:GetDescendants()) do if item:IsA("BasePart") and (item.Name:lower():find("item") or item.Name:lower():find("drop") or item.Name:lower():find("loot")) then TeleportTo(item.CFrame) task.wait(0.2) end end end end})
-- ========== END PART 6 ==========
-- ========== PART 7 of 7 ==========
local QuestTab = Window:MakeTab({Name = "Quest", Icon = "rbxassetid://4483345998", PremiumOnly = false})
QuestTab:AddSection({Name = "📜 Auto Quest"})
QuestTab:AddToggle({Name = "Auto Respawn", Default = Config.AutoRespawn, Callback = function(Value) AutoRespawnEnabled = Value Config.AutoRespawn = Value end})
QuestTab:AddToggle({Name = "Auto Quest", Default = Config.AutoQuest, Callback = function(Value) AutoQuestEnabled = Value Config.AutoQuest = Value QuestState = "IDLE" ClearSkippedEnemies() if Value then spawn(function() while AutoQuestEnabled do if not IsAlive() then task.wait(1) continue end local questPoint = GetQuestPoint() local enemies = GetQuestEnemies() if QuestState == "IDLE" then local npc = GetClosestQuestNPC() if npc then local root = GetRootPart() local distance = root and (root.Position - npc.Root.Position).Magnitude or 9999 if distance > 50 then TeleportTo(npc.Root.CFrame * CFrame.new(0, 50, 0)) task.wait(0.3) TeleportTo(npc.Root.CFrame * CFrame.new(0, 20, 0)) task.wait(0.3) TeleportTo(npc.Root.CFrame * CFrame.new(0, 0, -5)) task.wait(0.5) else TeleportTo(npc.Root.CFrame * CFrame.new(0, 0, -5)) task.wait(0.5) end AcceptQuest(npc.Name) local accepted = false for i = 1, 10 do task.wait(0.5) if GetQuestPoint() then accepted = true break end end if accepted then QuestState = "WAITING_QUEST_POINT" else AcceptQuest(npc.Name) task.wait(0.5) if GetQuestPoint() then QuestState = "WAITING_QUEST_POINT" end end end elseif QuestState == "WAITING_QUEST_POINT" then if questPoint then LastQuestPointPosition = questPoint.Position local root = GetRootPart() local distance = root and (root.Position - questPoint.Position).Magnitude or 9999 if distance > 50 then TeleportTo(questPoint.CFrame * CFrame.new(0, 100, 0)) task.wait(0.3) TeleportTo(questPoint.CFrame * CFrame.new(0, 50, 0)) task.wait(0.3) TeleportTo(questPoint.CFrame * CFrame.new(0, 5, 0)) task.wait(0.5) else TeleportTo(questPoint.CFrame * CFrame.new(0, 5, 0)) task.wait(0.5) end QuestState = "WAITING_SPAWN" end elseif QuestState == "WAITING_SPAWN" then for i = 15, 1, -1 do if not AutoQuestEnabled or #GetQuestEnemies() > 0 then break end task.wait(1) end QuestState = "KILLING" ClearSkippedEnemies() elseif QuestState == "KILLING" then if #enemies == 0 and not questPoint then QuestState = "ARISE_COLLECT" end elseif QuestState == "ARISE_COLLECT" then local deadList = GetDeadEnemies() if #deadList > 0 then for _, dead in pairs(deadList) do if not AutoQuestEnabled or SkippedEnemies[dead.Name] then continue end if AutoTPDeadEnabled and dead.Root then TeleportTo(dead.Root.CFrame * CFrame.new(0, 0, 3)) end local found = false for i = 1, 8 do if HasAriseOrCollect() then found = true break end task.wait(0.25) end if found then while HasAriseOrCollect() and AutoQuestEnabled do ClickAllAriseCollect() task.wait(0.3) end else SkippedEnemies[dead.Name] = true end task.wait(0.3) end end if #GetDeadEnemies() == 0 then QuestState = "IDLE" LastQuestPointPosition = nil ClearSkippedEnemies() end end task.wait(0.5) end end) end end})
QuestTab:AddSection({Name = "🔘 Manual"})
QuestTab:AddButton({Name = "TP to NPC", Callback = function() local npc = GetClosestQuestNPC() if npc then TeleportTo(npc.Root.CFrame * CFrame.new(0, 50, 0)) task.wait(0.3) TeleportTo(npc.Root.CFrame * CFrame.new(0, 0, -5)) end end})
QuestTab:AddButton({Name = "Accept Quest", Callback = function() local npc = GetClosestQuestNPC() if npc then AcceptQuest(npc.Name) end end})
QuestTab:AddButton({Name = "Go to Quest", Callback = function() local qp = GetQuestPoint() if qp then TeleportTo(qp.CFrame * CFrame.new(0, 50, 0)) task.wait(0.3) TeleportTo(qp.CFrame * CFrame.new(0, 5, 0)) end end})
local NPCLabel = QuestTab:AddLabel("NPCs: 0")
local QuestPointLabel = QuestTab:AddLabel("Quest: ❌")
local StatusLabel = QuestTab:AddLabel("Status: Idle")

local PlayerTab = Window:MakeTab({Name = "Player", Icon = "rbxassetid://4483345998", PremiumOnly = false})
PlayerTab:AddSlider({Name = "Walk Speed", Min = 16, Max = 300, Default = Config.WalkSpeed, Increment = 5, Callback = function(v) local c = GetCharacter() if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = v end Config.WalkSpeed = v end})
PlayerTab:AddSlider({Name = "Jump Power", Min = 50, Max = 300, Default = Config.JumpPower, Increment = 5, Callback = function(v) local c = GetCharacter() if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = v end Config.JumpPower = v end})
local InfJump = Config.InfJump
PlayerTab:AddToggle({Name = "Infinite Jump", Default = Config.InfJump, Callback = function(v) InfJump = v Config.InfJump = v end})
game:GetService("UserInputService").JumpRequest:Connect(function() if InfJump then local c = GetCharacter() if c and c:FindFirstChild("Humanoid") then c.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end end)
local Noclip = Config.Noclip
PlayerTab:AddToggle({Name = "Noclip", Default = Config.Noclip, Callback = function(v) Noclip = v Config.Noclip = v end})
RunService.Stepped:Connect(function() if Noclip then local c = GetCharacter() if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end end)

local SettingsTab = Window:MakeTab({Name = "Settings", Icon = "rbxassetid://4483345998", PremiumOnly = false})
SettingsTab:AddSection({Name = "💾 Config"})
SettingsTab:AddButton({Name = "💾 Save Config", Callback = function() SaveConfig() end})
SettingsTab:AddButton({Name = "📂 Load Config", Callback = function() LoadConfig() OrionLib:MakeNotification({Name = "Config", Content = "Restart script to apply!", Time = 3}) end})
SettingsTab:AddButton({Name = "🗑️ Delete Config", Callback = function() DeleteConfig() end})
SettingsTab:AddSection({Name = "⚙️ Settings"})
SettingsTab:AddButton({Name = "Hide/Show", Callback = function() OrionLib:ToggleUI() end})
SettingsTab:AddButton({Name = "Destroy", Callback = function() AutoKillEnabled = false AutoAttackEnabled = false AutoQuestEnabled = false AutoDungeonEnabled = false OrionLib:Destroy() end})

Player.CharacterAdded:Connect(function(char) if AutoRespawnEnabled and LastQuestPointPosition then task.wait(1.5) local root = char:WaitForChild("HumanoidRootPart", 5) if root then root.CFrame = CFrame.new(LastQuestPointPosition) * CFrame.new(0, 5, 0) end end end)

spawn(function() while task.wait(0.5) do EnemyLabel:Set("Enemies: " .. #GetQuestEnemies()) DeadEnemyLabel:Set("Dead: " .. #GetDeadEnemies()) AliveLabel:Set(IsAlive() and "Player: ✅" or "Player: ☠️") local skip = 0 for _ in pairs(SkippedEnemies) do skip = skip + 1 end SkippedLabel:Set("Skipped: " .. skip) NPCLabel:Set("NPCs: " .. #GetQuestNPCs()) local qp = GetQuestPoint() QuestPointLabel:Set(qp and "Quest: ✅" or "Quest: ❌") AriseCountLabel:Set("Arise: " .. AriseCount) CollectCountLabel:Set("Collect: " .. CollectCount) local a, c = FindAriseButton(), FindCollectButton() ButtonFoundLabel:Set((a and "Arise ✅ " or "Arise ❌ ") .. (c and "Collect ✅" or "Collect ❌")) InDungeonLabel:Set(IsInDungeon() and "In Dungeon: ✅" or "In Dungeon: ❌") DungeonEnemyLabel:Set("Dungeon Enemies: " .. #GetDungeonEnemies()) if AutoQuestEnabled then if QuestState == "IDLE" then StatusLabel:Set("Finding 🔍") elseif QuestState == "WAITING_QUEST_POINT" then StatusLabel:Set("Going ⏳") elseif QuestState == "WAITING_SPAWN" then StatusLabel:Set("Waiting ⏳") elseif QuestState == "KILLING" then StatusLabel:Set("Killing 🔥") elseif QuestState == "ARISE_COLLECT" then StatusLabel:Set("Arise 👻") end else StatusLabel:Set("Idle 💤") end end end)

spawn(function() while task.wait(0.15) do if not AutoQuestEnabled and IsAlive() and HasAriseOrCollect() then if AutoTPDeadEnabled then local d = GetClosestDeadEnemy() if d and d.Root then TeleportTo(d.Root.CFrame * CFrame.new(0, 0, 3)) end end if AutoAriseEnabled or AutoCollectEnabled then ClickAllAriseCollect() end end end end)

OrionLib:Init()
-- ========== END PART 7 ==========
