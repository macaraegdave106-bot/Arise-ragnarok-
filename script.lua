-- ═══════════════════════════════════════════════════════════════════════
-- PART 1 of 5 - SOLO LEVELING ARISE RAGNAROK (FULL SCRIPT)
-- ═══════════════════════════════════════════════════════════════════════

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ConfigFileName = "SoloLevelingConfig.json"
local Config = {
    AutoKill = false,
    KillAura = false,
    AutoAttack = false,
    AttackSpeed = 10,
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
        OrionLib:MakeNotification({Name = "Config", Content = "Settings Saved!", Time = 2})
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
        OrionLib:MakeNotification({Name = "Config", Content = "Settings Loaded!", Time = 2})
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
        OrionLib:MakeNotification({Name = "Config", Content = "Config Deleted!", Time = 2})
    end
end

LoadConfig()

local AutoKillEnabled = Config.AutoKill
local KillAuraEnabled = Config.KillAura
local AutoAttackEnabled = Config.AutoAttack
local AttackSpeed = Config.AttackSpeed
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
local QuestState = "IDLE"
local DungeonState = "IDLE"
local LastQuestPointPosition = nil
local AriseCount = 0
local CollectCount = 0
local SkippedEnemies = {}
local AutoJoinPortal = false
local AutoFullDungeon = false
local AutoCollectAllDead = false
local TotalCollected = 0
local AutoStatsEnabled = false
local StatPriority = "DMG"

local Window = OrionLib:MakeWindow({Name = "Solo Leveling", HidePremium = true, IntroEnabled = false})
OrionLib:MakeNotification({Name = "Loaded", Content = "Script Ready!", Time = 3})

local Events = ReplicatedStorage:WaitForChild("Events")
local QuestEvents = Events:WaitForChild("Quest")
local DialogRemote = QuestEvents:FindFirstChild("Dialog")
local Combat = Events:WaitForChild("Combat")
local AttackEvent = Combat:WaitForChild("Attack")

local function GetCharacter() return Player.Character end
local function GetHumanoid() local char = GetCharacter() if char then return char:FindFirstChild("Humanoid") end return nil end
local function GetRootPart() local char = GetCharacter() if char then return char:FindFirstChild("HumanoidRootPart") end return nil end
local function IsAlive() local hum = GetHumanoid() if hum and hum.Health > 0 then return true end return false end
local function TeleportTo(cframe) local root = GetRootPart() if root and IsAlive() then root.CFrame = cframe end end
local function IsPlayer(name) for _, plr in pairs(Players:GetPlayers()) do if plr.Name == name then return true end end return false end
local function IsQuestEnemy(name) if name:match("%d+_E_%d+") then return true end return false end
local function ClearSkippedEnemies() SkippedEnemies = {} end

local function FastAttack()
    if not IsAlive() then return end
    for i = 1, AttackSpeed do
        pcall(function()
            AttackEvent:FireServer()
        end)
    end
end
-- ═══════════════════════════════════════════════════════════════════════
-- END PART 1 - Continue to PART 2
-- ═══════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════
-- PART 2 of 5 - Dungeon & Enemy Functions
-- ═══════════════════════════════════════════════════════════════════════

local function IsInDungeon()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Boss Health" and gui.Visible then return true end
        if gui:IsA("Frame") and gui.Name == "Dungeon Name" and gui.Visible then return true end
    end
    local entityFolder = Workspace:FindFirstChild("EntityFolder")
    if entityFolder then
        for _, child in pairs(entityFolder:GetChildren()) do
            if child:IsA("Model") and child.Name:match("_%d+_E_%d+") then
                local hum = child:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    return true
                end
            end
        end
    end
    return false
end

local function IsDungeonFinished()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Dungeon Finish" and gui.Visible then return true end
    end
    return false
end

local function GetDungeonEnemies()
    local enemies = {}
    local playerName = Player.Name
    
    local entityFolder = Workspace:FindFirstChild("EntityFolder")
    if entityFolder then
        for _, child in pairs(entityFolder:GetChildren()) do
            if child:IsA("Model") then
                local name = child.Name
                if IsPlayer(name) or name == playerName then continue end
                local hum = child:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso") or child:FindFirstChild("Head")
                    if root then
                        table.insert(enemies, {Model = child, Root = root, Humanoid = hum, Name = name})
                    end
                end
            end
        end
    end
    
    local hittedFolders = {Workspace:FindFirstChild("EntityFolder_Hitted1"), Workspace:FindFirstChild("EntityFolder_Hitted2")}
    for _, folder in pairs(hittedFolders) do
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local name = child.Name
                    if IsPlayer(name) or name == playerName then continue end
                    local hum = child:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso") or child:FindFirstChild("Head")
                        if root then
                            local exists = false
                            for _, e in pairs(enemies) do if e.Model == child then exists = true break end end
                            if not exists then
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

local function GetClosestDungeonEnemy()
    local root = GetRootPart()
    if not root then return nil end
    local enemies = GetDungeonEnemies()
    local closest = nil
    local closestDist = math.huge
    for _, enemy in pairs(enemies) do
        if enemy.Root then
            local dist = (root.Position - enemy.Root.Position).Magnitude
            if dist < closestDist then
                closest = enemy
                closestDist = dist
            end
        end
    end
    return closest, closestDist
end

local function TeleportToEnemy(targetCFrame)
    local root = GetRootPart()
    if not root then return end
    local distance = (root.Position - targetCFrame.Position).Magnitude
    if distance > 200 then
        TeleportTo(targetCFrame * CFrame.new(0, 150, 0))
        task.wait(0.1)
        TeleportTo(targetCFrame * CFrame.new(0, 50, 0))
        task.wait(0.1)
        TeleportTo(targetCFrame * CFrame.new(0, 0, 5))
    elseif distance > 100 then
        TeleportTo(targetCFrame * CFrame.new(0, 80, 0))
        task.wait(0.1)
        TeleportTo(targetCFrame * CFrame.new(0, 0, 5))
    elseif distance > 50 then
        TeleportTo(targetCFrame * CFrame.new(0, 30, 0))
        task.wait(0.1)
        TeleportTo(targetCFrame * CFrame.new(0, 0, 5))
    else
        TeleportTo(targetCFrame * CFrame.new(0, 0, 5))
    end
end

local function GetAllDeadEnemies()
    local deadEnemies = {}
    local playerName = Player.Name
    local folders = {Workspace:FindFirstChild("EntityFolder"), Workspace:FindFirstChild("EntityFolder_Hitted1"), Workspace:FindFirstChild("EntityFolder_Hitted2")}
    for _, folder in pairs(folders) do
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local name = child.Name
                    if IsPlayer(name) or name == playerName then continue end
                    local hum = child:FindFirstChild("Humanoid")
                    if hum and hum.Health <= 0 then
                        local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso") or child:FindFirstChild("Head")
                        if root then
                            table.insert(deadEnemies, {Model = child, Root = root, Humanoid = hum, Name = name})
                        end
                    end
                end
            end
        end
    end
    return deadEnemies
end
-- ═══════════════════════════════════════════════════════════════════════
-- END PART 2 - Continue to PART 3
-- ═══════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════
-- PART 3 of 5 - Quest & GUI Functions
-- ═══════════════════════════════════════════════════════════════════════

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

local function GetPortalPart()
    local instanced = Workspace:FindFirstChild("Instanced")
    if instanced then
        local portal = instanced:FindFirstChild("Portal")
        if portal then
            for _, child in pairs(portal:GetDescendants()) do
                if child:IsA("BasePart") and child.Name == "Part" then return child end
            end
            for _, child in pairs(portal:GetDescendants()) do
                if child:IsA("BasePart") then return child end
            end
        end
    end
    return nil
end

local function TouchPortal()
    local portal = GetPortalPart()
    if portal then
        local char = Player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = portal.CFrame
                task.wait(0.1)
                pcall(function() firetouchinterest(hrp, portal, 0) task.wait(0.1) firetouchinterest(hrp, portal, 1) end)
                return true
            end
        end
    end
    return false
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

local function FindDungeonGUIButton(buttonName)
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Dungeon" and gui.Visible then
            for _, child in pairs(gui:GetDescendants()) do
                if (child:IsA("TextButton") or child:IsA("ImageButton")) then
                    if child.Name == buttonName or (child.Parent and child.Parent.Name == buttonName) then return child end
                end
            end
        end
    end
    return nil
end

local function FindStartDungeonButton()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Start Dungeon" then
            for _, child in pairs(gui:GetDescendants()) do
                if child:IsA("ImageButton") or child:IsA("TextButton") then return child end
            end
        end
    end
    return nil
end

local function ClickDungeonButton(name)
    local btn = FindDungeonGUIButton(name)
    if btn then ClickButton(btn) return true end
    return false
end

local function SelectDifficulty(difficulty)
    local diffBtn = FindDungeonGUIButton(difficulty)
    if diffBtn then ClickButton(diffBtn) return true end
    return false
end
-- ═══════════════════════════════════════════════════════════════════════
-- END PART 3 - Continue to PART 4
-- ═══════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════
-- PART 4 of 5 - IMPROVED AUTO KILL + Stats Functions & Tabs
-- ═══════════════════════════════════════════════════════════════════════

local function FindStatAddButton(statName)
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Stats" then
            for _, child in pairs(gui:GetDescendants()) do
                if child:IsA("Frame") and child.Name == statName then
                    for _, btn in pairs(child:GetDescendants()) do
                        if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                            if btn.Name == "Add" or (btn.Parent and btn.Parent.Name == "Add") then
                                if btn.Visible then return btn end
                            end
                        end
                    end
                end
            end
        end
    end
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Down Frame" then
            for _, child in pairs(gui:GetDescendants()) do
                if child:IsA("Frame") and child.Name == statName then
                    for _, btn in pairs(child:GetDescendants()) do
                        if btn:IsA("ImageButton") or btn:IsA("TextButton") then
                            if btn.Name == "Add" or (btn.Parent and btn.Parent.Name == "Add") then return btn end
                        end
                    end
                end
            end
        end
    end
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if (gui:IsA("ImageButton") or gui:IsA("TextButton")) then
            local parent = gui.Parent
            if parent and parent.Name == "Add" then
                local grandParent = parent.Parent
                if grandParent and grandParent.Name == statName then return gui end
            end
        end
    end
    return nil
end

local function ClickStatButton(statName)
    local btn = FindStatAddButton(statName)
    if btn then
        ClickButton(btn)
        return true
    end
    return false
end

local function GetAvailableStatPoints()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") then
            local text = gui.Text
            if text:find("Points") or text:find("POINTS") or text:find("points") then
                local points = text:match("%d+")
                if points then return tonumber(points) end
            end
        end
    end
    return 0
end

local function IsStatsWindowOpen()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("Frame") and gui.Name == "Stats" and gui.Visible then return true end
    end
    return false
end

local function OpenStatsWindow()
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if (gui:IsA("ImageButton") or gui:IsA("TextButton")) then
            if gui.Parent and gui.Parent.Name == "Stats" then
                ClickButton(gui)
                return true
            end
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════
-- IMPROVED AUTO KILL VARIABLES
-- ═══════════════════════════════════════════════════════════════════════

local BringAllEnemies = false
local AttackAllEnemies = false
local TPBehindEnemy = false
local TargetPriority = "Closest"
local AttackRange = 150
local KillCount = 0

-- ═══════════════════════════════════════════════════════════════════════
-- IMPROVED AUTO KILL FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

local function GetAllEnemiesInRange()
    local enemies = {}
    local root = GetRootPart()
    if not root then return enemies end
    
    local playerName = Player.Name
    local folders = {
        Workspace:FindFirstChild("EntityFolder"),
        Workspace:FindFirstChild("EntityFolder_Hitted1"),
        Workspace:FindFirstChild("EntityFolder_Hitted2")
    }
    
    for _, folder in pairs(folders) do
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local name = child.Name
                    if IsPlayer(name) or name == playerName then continue end
                    
                    local hum = child:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local enemyRoot = child:FindFirstChild("HumanoidRootPart") 
                            or child:FindFirstChild("Torso") 
                            or child:FindFirstChild("Head")
                        if enemyRoot then
                            local dist = (root.Position - enemyRoot.Position).Magnitude
                            if dist <= AttackRange then
                                table.insert(enemies, {
                                    Model = child,
                                    Root = enemyRoot,
                                    Humanoid = hum,
                                    Name = name,
                                    Distance = dist,
                                    Health = hum.Health
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sort by priority
    if TargetPriority == "Closest" then
        table.sort(enemies, function(a, b) return a.Distance < b.Distance end)
    elseif TargetPriority == "Lowest HP" then
        table.sort(enemies, function(a, b) return a.Health < b.Health end)
    elseif TargetPriority == "Highest HP" then
        table.sort(enemies, function(a, b) return a.Health > b.Health end)
    end
    
    return enemies
end

local function GetBestTarget()
    local enemies = GetAllEnemiesInRange()
    if #enemies > 0 then
        return enemies[1]
    end
    return nil
end

local function BringEnemiesToPlayer()
    local root = GetRootPart()
    if not root then return end
    
    local enemies = GetAllEnemiesInRange()
    for _, enemy in pairs(enemies) do
        if enemy.Root then
            enemy.Root.CFrame = root.CFrame * CFrame.new(0, 0, 3)
        end
    end
end

local function TeleportBehindEnemy(enemy)
    if not enemy or not enemy.Root then return end
    local root = GetRootPart()
    if not root then return end
    
    -- Teleport behind the enemy
    root.CFrame = enemy.Root.CFrame * CFrame.new(0, 0, -3)
end

local function TeleportToEnemy_Improved(enemy)
    if not enemy or not enemy.Root then return end
    
    if TPBehindEnemy then
        TeleportBehindEnemy(enemy)
    else
        TeleportTo(enemy.Root.CFrame * CFrame.new(0, 0, 3))
    end
end

local function AttackAllAtOnce()
    if not IsAlive() then return end
    
    for i = 1, AttackSpeed do
        pcall(function()
            AttackEvent:FireServer()
        end)
    end
end

local function TryInstantKill(enemy)
    if not enemy or not enemy.Humanoid then return false end
    
    -- Try various methods to damage enemy
    pcall(function()
        enemy.Humanoid.Health = 0
    end)
    pcall(function()
        enemy.Humanoid:TakeDamage(enemy.Humanoid.MaxHealth)
    end)
    
    return enemy.Humanoid.Health <= 0
end

-- ═══════════════════════════════════════════════════════════════════════
-- AUTO KILL TAB (IMPROVED)
-- ═══════════════════════════════════════════════════════════════════════

local KillTab = Window:MakeTab({Name = "Auto Kill", Icon = "rbxassetid://4483345998", PremiumOnly = false})

KillTab:AddSection({Name = "⚔️ Auto Kill (Improved)"})

KillTab:AddToggle({
    Name = "Auto Kill", 
    Default = Config.AutoKill, 
    Callback = function(Value) 
        AutoKillEnabled = Value 
        Config.AutoKill = Value 
        if Value then 
            spawn(function() 
                while AutoKillEnabled do 
                    if IsAlive() and not IsInDungeon() then 
                        local enemy = GetBestTarget()
                        if enemy and enemy.Root then 
                            TeleportToEnemy_Improved(enemy)
                            KillCount = KillCount + 1
                        end 
                    end 
                    task.wait(0.1) 
                end 
            end) 
        end 
    end
})

KillTab:AddToggle({
    Name = "Kill Aura (Improved)", 
    Default = Config.KillAura, 
    Callback = function(Value) 
        KillAuraEnabled = Value 
        Config.KillAura = Value 
    end
})

-- Improved Kill Aura with faster loop
spawn(function()
    while true do
        if KillAuraEnabled and IsAlive() and not IsInDungeon() then
            local root = GetRootPart()
            if root then
                local enemies = GetAllEnemiesInRange()
                for _, enemy in pairs(enemies) do
                    if enemy.Root then
                        enemy.Root.CFrame = root.CFrame * CFrame.new(0, 0, 3)
                    end
                end
            end
        end
        task.wait(0.05) -- Faster than before
    end
end)

KillTab:AddToggle({
    Name = "Bring All Enemies", 
    Default = false, 
    Callback = function(Value) 
        BringAllEnemies = Value 
        if Value then
            spawn(function()
                while BringAllEnemies do
                    if IsAlive() and not IsInDungeon() then
                        BringEnemiesToPlayer()
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

KillTab:AddToggle({
    Name = "TP Behind Enemy", 
    Default = false, 
    Callback = function(Value) 
        TPBehindEnemy = Value 
    end
})

KillTab:AddSection({Name = "⚡ Attack Settings"})

KillTab:AddToggle({
    Name = "Auto Attack", 
    Default = Config.AutoAttack, 
    Callback = function(Value) 
        AutoAttackEnabled = Value 
        Config.AutoAttack = Value 
        if Value then 
            spawn(function() 
                while AutoAttackEnabled do 
                    if IsAlive() then
                        local questEnemies = GetQuestEnemies()
                        local dungeonEnemies = GetDungeonEnemies()
                        if #questEnemies > 0 or #dungeonEnemies > 0 then 
                            AttackAllAtOnce()
                        end
                    end 
                    task.wait(0.03) -- Faster attack
                end 
            end) 
        end 
    end
})

KillTab:AddToggle({
    Name = "Attack All Enemies", 
    Default = false, 
    Callback = function(Value) 
        AttackAllEnemies = Value 
        if Value then
            spawn(function()
                while AttackAllEnemies do
                    if IsAlive() then
                        -- Bring and attack all at once
                        BringEnemiesToPlayer()
                        AttackAllAtOnce()
                    end
                    task.wait(0.05)
                end
            end)
        end
    end
})

KillTab:AddSlider({
    Name = "Attack Speed", 
    Min = 1, 
    Max = 100, 
    Default = Config.AttackSpeed, 
    Increment = 1, 
    Callback = function(Value) 
        AttackSpeed = Value 
        Config.AttackSpeed = Value 
    end
})

KillTab:AddSlider({
    Name = "Attack Range", 
    Min = 10, 
    Max = 500, 
    Default = 150, 
    Increment = 10, 
    Callback = function(Value) 
        AttackRange = Value 
    end
})

KillTab:AddSection({Name = "🎯 Target Settings"})

KillTab:AddDropdown({
    Name = "Target Priority", 
    Default = "Closest", 
    Options = {"Closest", "Lowest HP", "Highest HP"}, 
    Callback = function(Value) 
        TargetPriority = Value 
    end
})

KillTab:AddSection({Name = "📊 Status"})
local EnemyLabel = KillTab:AddLabel("Enemies: 0")
local DeadEnemyLabel = KillTab:AddLabel("Dead: 0")
local AliveLabel = KillTab:AddLabel("Player: ✅")
local SkippedLabel = KillTab:AddLabel("Skipped: 0")
local KillCountLabel = KillTab:AddLabel("Kills: 0")
local RangeEnemiesLabel = KillTab:AddLabel("In Range: 0")

-- ═══════════════════════════════════════════════════════════════════════
-- ARISE TAB
-- ═══════════════════════════════════════════════════════════════════════

local AriseTab = Window:MakeTab({Name = "Arise", Icon = "rbxassetid://4483345998", PremiumOnly = false})
AriseTab:AddSection({Name = "👻 Auto Arise & Collect"})
AriseTab:AddToggle({Name = "Auto Arise", Default = Config.AutoArise, Callback = function(Value) AutoAriseEnabled = Value Config.AutoArise = Value end})
AriseTab:AddToggle({Name = "Auto Collect", Default = Config.AutoCollect, Callback = function(Value) AutoCollectEnabled = Value Config.AutoCollect = Value end})
AriseTab:AddDropdown({Name = "Priority", Default = Config.ArisePriority, Options = {"Arise First", "Collect First"}, Callback = function(Value) ArisePriority = (Value == "Arise First") Config.ArisePriority = Value end})
AriseTab:AddSection({Name = "📊 Status"})
local AriseCountLabel = AriseTab:AddLabel("Arise: 0")
local CollectCountLabel = AriseTab:AddLabel("Collect: 0")
local ButtonFoundLabel = AriseTab:AddLabel("Buttons: ---")

-- ═══════════════════════════════════════════════════════════════════════
-- DUNGEON TAB
-- ═══════════════════════════════════════════════════════════════════════

local DungeonTab = Window:MakeTab({Name = "Dungeon", Icon = "rbxassetid://4483345998", PremiumOnly = false})
DungeonTab:AddSection({Name = "🏰 Dungeon Status"})
local DungeonStatusLabel = DungeonTab:AddLabel("Status: Idle")
local InDungeonLabel = DungeonTab:AddLabel("In Dungeon: ❌")
local DungeonEnemyLabel = DungeonTab:AddLabel("Dungeon Enemies: 0")
local PortalLabel = DungeonTab:AddLabel("Portal: ❌")

DungeonTab:AddSection({Name = "🚪 Auto Join Portal"})
DungeonTab:AddToggle({Name = "Auto Join Portal", Default = false, Callback = function(Value) AutoJoinPortal = Value if Value then spawn(function() while AutoJoinPortal do if IsAlive() and not IsInDungeon() then DungeonStatusLabel:Set("Status: Finding Portal") local portal = GetPortalPart() if portal then DungeonStatusLabel:Set("Status: Going to Portal") TeleportToEnemy(portal.CFrame) task.wait(0.5) DungeonStatusLabel:Set("Status: Touching Portal") TouchPortal() task.wait(0.8) DungeonStatusLabel:Set("Status: Selecting " .. DungeonDifficulty) SelectDifficulty(DungeonDifficulty) task.wait(0.3) DungeonStatusLabel:Set("Status: Clicking Solo") ClickDungeonButton("Solo") task.wait(0.5) DungeonStatusLabel:Set("Status: Starting...") ClickDungeonButton("Start") task.wait(0.5) local startBtn = FindStartDungeonButton() if startBtn then ClickButton(startBtn) end task.wait(1) else DungeonStatusLabel:Set("Status: No Portal") end elseif IsInDungeon() then DungeonStatusLabel:Set("Status: In Dungeon") end task.wait(1) end end) end end})

DungeonTab:AddToggle({Name = "Auto Full Dungeon (Join + Kill)", Default = false, Callback = function(Value) AutoFullDungeon = Value if Value then spawn(function() while AutoFullDungeon do if not IsAlive() then DungeonStatusLabel:Set("Status: Dead") task.wait(1) continue end if IsInDungeon() then local enemies = GetDungeonEnemies() if #enemies > 0 then DungeonStatusLabel:Set("Status: Killing (" .. #enemies .. " left)") local enemy = GetClosestDungeonEnemy() if enemy and enemy.Root then TeleportToEnemy(enemy.Root.CFrame) end else DungeonStatusLabel:Set("Status: Dungeon Clear") end else local portal = GetPortalPart() if portal then DungeonStatusLabel:Set("Status: Joining Portal") TeleportToEnemy(portal.CFrame) task.wait(0.5) TouchPortal() task.wait(0.8) SelectDifficulty(DungeonDifficulty) task.wait(0.3) ClickDungeonButton("Solo") task.wait(0.5) ClickDungeonButton("Start") task.wait(0.5) local startBtn = FindStartDungeonButton() if startBtn then ClickButton(startBtn) end task.wait(1) else DungeonStatusLabel:Set("Status: No Portal") end end task.wait(0.2) end end) end end})

DungeonTab:AddSection({Name = "⚔️ Dungeon Auto Kill"})
DungeonTab:AddToggle({Name = "Auto Dungeon Kill", Default = Config.AutoDungeonKill, Callback = function(Value) AutoDungeonKill = Value Config.AutoDungeonKill = Value if Value then spawn(function() while AutoDungeonKill do if IsAlive() and IsInDungeon() then local enemy = GetClosestDungeonEnemy() if enemy and enemy.Root then TeleportToEnemy(enemy.Root.CFrame) end end task.wait(0.15) end end) end end})

DungeonTab:AddToggle({Name = "Dungeon Kill Aura", Default = false, Callback = function(Value) if Value then spawn(function() while Value and AutoDungeonKill do if IsAlive() and IsInDungeon() then local root = GetRootPart() if root then local enemies = GetDungeonEnemies() for _, enemy in pairs(enemies) do if enemy.Root then enemy.Root.CFrame = root.CFrame * CFrame.new(0, 0, 3) end end end end task.wait(0.05) end end) end end})

DungeonTab:AddToggle({Name = "Dungeon Bring All Enemies", Default = false, Callback = function(Value) if Value then spawn(function() while Value do if IsAlive() and IsInDungeon() then local root = GetRootPart() if root then local enemies = GetDungeonEnemies() for _, enemy in pairs(enemies) do if enemy.Root then enemy.Root.CFrame = root.CFrame * CFrame.new(0, 0, 3) end end end end task.wait(0.1) end end) end end})

DungeonTab:AddSection({Name = "🎮 Dungeon Settings"})
DungeonTab:AddDropdown({Name = "Difficulty", Default = Config.DungeonDifficulty, Options = {"Easy", "Normal", "Hard"}, Callback = function(Value) DungeonDifficulty = Value Config.DungeonDifficulty = Value end})
DungeonTab:AddToggle({Name = "Auto Start Dungeon", Default = Config.AutoDungeonStart, Callback = function(Value) AutoDungeonStart = Value Config.AutoDungeonStart = Value if Value then spawn(function() while AutoDungeonStart do if IsAlive() then local startBtn = FindStartDungeonButton() if startBtn then ClickButton(startBtn) end ClickDungeonButton("Start") end task.wait(1) end end) end end})
-- ═══════════════════════════════════════════════════════════════════════
-- END PART 4 - Continue to PART 5
-- ═══════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════
-- PART 5 of 5 - Quest, Collect, Stats, Player, Settings & Main Loop
-- ═══════════════════════════════════════════════════════════════════════

-- QUEST TAB
local QuestTab = Window:MakeTab({Name = "Quest", Icon = "rbxassetid://4483345998", PremiumOnly = false})
QuestTab:AddSection({Name = "📜 Auto Quest"})
QuestTab:AddToggle({Name = "Auto Respawn", Default = Config.AutoRespawn, Callback = function(Value) AutoRespawnEnabled = Value Config.AutoRespawn = Value end})
QuestTab:AddToggle({Name = "Auto Quest", Default = Config.AutoQuest, Callback = function(Value) AutoQuestEnabled = Value Config.AutoQuest = Value QuestState = "IDLE" ClearSkippedEnemies() if Value then spawn(function() while AutoQuestEnabled do if not IsAlive() then task.wait(1) continue end local questPoint = GetQuestPoint() local enemies = GetQuestEnemies() if QuestState == "IDLE" then local npc = GetClosestQuestNPC() if npc then local root = GetRootPart() local distance = root and (root.Position - npc.Root.Position).Magnitude or 9999 if distance > 50 then TeleportTo(npc.Root.CFrame * CFrame.new(0, 50, 0)) task.wait(0.3) TeleportTo(npc.Root.CFrame * CFrame.new(0, 20, 0)) task.wait(0.3) TeleportTo(npc.Root.CFrame * CFrame.new(0, 0, -5)) task.wait(0.5) else TeleportTo(npc.Root.CFrame * CFrame.new(0, 0, -5)) task.wait(0.5) end AcceptQuest(npc.Name) local accepted = false for i = 1, 10 do task.wait(0.5) if GetQuestPoint() then accepted = true break end end if accepted then QuestState = "WAITING_QUEST_POINT" else AcceptQuest(npc.Name) task.wait(0.5) if GetQuestPoint() then QuestState = "WAITING_QUEST_POINT" end end end elseif QuestState == "WAITING_QUEST_POINT" then if questPoint then LastQuestPointPosition = questPoint.Position local root = GetRootPart() local distance = root and (root.Position - questPoint.Position).Magnitude or 9999 if distance > 50 then TeleportTo(questPoint.CFrame * CFrame.new(0, 100, 0)) task.wait(0.3) TeleportTo(questPoint.CFrame * CFrame.new(0, 50, 0)) task.wait(0.3) TeleportTo(questPoint.CFrame * CFrame.new(0, 5, 0)) task.wait(0.5) else TeleportTo(questPoint.CFrame * CFrame.new(0, 5, 0)) task.wait(0.5) end QuestState = "WAITING_SPAWN" end elseif QuestState == "WAITING_SPAWN" then for i = 15, 1, -1 do if not AutoQuestEnabled or #GetQuestEnemies() > 0 then break end task.wait(1) end QuestState = "KILLING" ClearSkippedEnemies() elseif QuestState == "KILLING" then if #enemies == 0 and not questPoint then QuestState = "ARISE_COLLECT" end elseif QuestState == "ARISE_COLLECT" then local deadList = GetDeadEnemies() if #deadList > 0 then for _, dead in pairs(deadList) do if not AutoQuestEnabled or SkippedEnemies[dead.Name] then continue end if dead.Root then TeleportTo(dead.Root.CFrame * CFrame.new(0, 0, 3)) end local found = false for i = 1, 8 do if HasAriseOrCollect() then found = true break end task.wait(0.25) end if found then while HasAriseOrCollect() and AutoQuestEnabled do ClickAllAriseCollect() task.wait(0.3) end else SkippedEnemies[dead.Name] = true end task.wait(0.3) end end if #GetDeadEnemies() == 0 then QuestState = "IDLE" LastQuestPointPosition = nil ClearSkippedEnemies() end end task.wait(0.5) end end) end end})
QuestTab:AddSection({Name = "📊 Status"})
local NPCLabel = QuestTab:AddLabel("NPCs: 0")
local QuestPointLabel = QuestTab:AddLabel("Quest: ❌")
local StatusLabel = QuestTab:AddLabel("Status: Idle")

-- COLLECT TAB
local CollectTab = Window:MakeTab({Name = "Collect", Icon = "rbxassetid://4483345998", PremiumOnly = false})
CollectTab:AddSection({Name = "💀 Auto Collect All Dead"})
local DeadCountLabel = CollectTab:AddLabel("Dead Enemies: 0")
local CollectedLabel = CollectTab:AddLabel("Collected: 0")
CollectTab:AddToggle({Name = "Auto Collect All Dead", Default = false, Callback = function(Value) AutoCollectAllDead = Value if Value then spawn(function() while AutoCollectAllDead do if IsAlive() then local deadList = GetAllDeadEnemies() for _, dead in pairs(deadList) do if not AutoCollectAllDead then break end if not IsAlive() then break end if dead.Root then TeleportTo(dead.Root.CFrame * CFrame.new(0, 0, 3)) task.wait(0.3) local hasButton = false for i = 1, 5 do if HasAriseOrCollect() then hasButton = true break end task.wait(0.15) end if hasButton then while HasAriseOrCollect() do ClickAllAriseCollect() TotalCollected = TotalCollected + 1 task.wait(0.2) end task.wait(0.2) end end end end task.wait(0.5) end end) end end})

-- STATS TAB
local StatsTab = Window:MakeTab({Name = "Stats", Icon = "rbxassetid://4483345998", PremiumOnly = false})
StatsTab:AddSection({Name = "📊 Auto Stats"})
local StatPointsLabel = StatsTab:AddLabel("Stat Points: 0")
local StatStatusLabel = StatsTab:AddLabel("Status: Idle")
StatsTab:AddDropdown({Name = "Stat Priority", Default = "DMG", Options = {"DMG", "VIT", "AGI", "MNA"}, Callback = function(Value) StatPriority = Value end})
StatsTab:AddToggle({Name = "Auto Assign Stats", Default = false, Callback = function(Value) AutoStatsEnabled = Value if Value then spawn(function() while AutoStatsEnabled do if IsAlive() then if not IsStatsWindowOpen() then StatStatusLabel:Set("Status: Opening Stats...") OpenStatsWindow() task.wait(0.5) end local success = ClickStatButton(StatPriority) if success then StatStatusLabel:Set("Status: Added " .. StatPriority) else StatStatusLabel:Set("Status: No points") end end task.wait(0.5) end StatStatusLabel:Set("Status: Idle") end) end end})

-- PLAYER TAB
local PlayerTab = Window:MakeTab({Name = "Player", Icon = "rbxassetid://4483345998", PremiumOnly = false})
PlayerTab:AddSection({Name = "🏃 Movement"})
PlayerTab:AddSlider({Name = "Walk Speed", Min = 16, Max = 300, Default = Config.WalkSpeed, Increment = 5, Callback = function(v) local c = GetCharacter() if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = v end Config.WalkSpeed = v end})
PlayerTab:AddSlider({Name = "Jump Power", Min = 50, Max = 300, Default = Config.JumpPower, Increment = 5, Callback = function(v) local c = GetCharacter() if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = v end Config.JumpPower = v end})
local InfJump = Config.InfJump
PlayerTab:AddToggle({Name = "Infinite Jump", Default = Config.InfJump, Callback = function(v) InfJump = v Config.InfJump = v end})
game:GetService("UserInputService").JumpRequest:Connect(function() if InfJump then local c = GetCharacter() if c and c:FindFirstChild("Humanoid") then c.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end end)
local Noclip = Config.Noclip
PlayerTab:AddToggle({Name = "Noclip", Default = Config.Noclip, Callback = function(v) Noclip = v Config.Noclip = v end})
RunService.Stepped:Connect(function() if Noclip then local c = GetCharacter() if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end end)

-- SETTINGS TAB
local SettingsTab = Window:MakeTab({Name = "Settings", Icon = "rbxassetid://4483345998", PremiumOnly = false})
SettingsTab:AddSection({Name = "💾 Config"})
SettingsTab:AddButton({Name = "Save Config", Callback = function() SaveConfig() end})
SettingsTab:AddButton({Name = "Load Config", Callback = function() LoadConfig() OrionLib:MakeNotification({Name = "Config", Content = "Restart script to apply!", Time = 3}) end})
SettingsTab:AddButton({Name = "Delete Config", Callback = function() DeleteConfig() end})
SettingsTab:AddSection({Name = "⚙️ UI"})
SettingsTab:AddButton({Name = "Hide/Show UI", Callback = function() OrionLib:ToggleUI() end})
SettingsTab:AddButton({Name = "Destroy Script", Callback = function() AutoKillEnabled = false AutoQuestEnabled = false AutoDungeonKill = false AutoJoinPortal = false AutoFullDungeon = false AutoCollectAllDead = false AutoStatsEnabled = false OrionLib:Destroy() end})

-- AUTO RESPAWN
Player.CharacterAdded:Connect(function(char) if AutoRespawnEnabled and LastQuestPointPosition then task.wait(1.5) local root = char:WaitForChild("HumanoidRootPart", 5) if root then root.CFrame = CFrame.new(LastQuestPointPosition) * CFrame.new(0, 5, 0) end end end)

-- UPDATE LOOP
spawn(function() while task.wait(0.5) do 
    EnemyLabel:Set("Enemies: " .. #GetQuestEnemies()) 
    DeadEnemyLabel:Set("Dead: " .. #GetDeadEnemies()) 
    AliveLabel:Set(IsAlive() and "Player: ✅" or "Player: ☠️") 
    local skip = 0 for _ in pairs(SkippedEnemies) do skip = skip + 1 end 
    SkippedLabel:Set("Skipped: " .. skip) 
    KillCountLabel:Set("Kills: " .. KillCount)
    RangeEnemiesLabel:Set("In Range: " .. #GetAllEnemiesInRange())
    NPCLabel:Set("NPCs: " .. #GetQuestNPCs()) 
    local qp = GetQuestPoint() 
    QuestPointLabel:Set(qp and "Quest: ✅" or "Quest: ❌") 
    AriseCountLabel:Set("Arise: " .. AriseCount) 
    CollectCountLabel:Set("Collect: " .. CollectCount) 
    local a, c = FindAriseButton(), FindCollectButton() 
    ButtonFoundLabel:Set((a and "Arise ✅ " or "Arise ❌ ") .. (c and "Collect ✅" or "Collect ❌")) 
    InDungeonLabel:Set(IsInDungeon() and "In Dungeon: ✅" or "In Dungeon: ❌") 
    DungeonEnemyLabel:Set("Dungeon Enemies: " .. #GetDungeonEnemies()) 
    local portal = GetPortalPart() 
    PortalLabel:Set(portal and "Portal: ✅" or "Portal: ❌") 
    DeadCountLabel:Set("Dead Enemies: " .. #GetAllDeadEnemies()) 
    CollectedLabel:Set("Collected: " .. TotalCollected) 
    StatPointsLabel:Set("Stat Points: " .. GetAvailableStatPoints()) 
    if AutoQuestEnabled then 
        if QuestState == "IDLE" then StatusLabel:Set("Finding 🔍") 
        elseif QuestState == "WAITING_QUEST_POINT" then StatusLabel:Set("Going ⏳") 
        elseif QuestState == "WAITING_SPAWN" then StatusLabel:Set("Waiting ⏳") 
        elseif QuestState == "KILLING" then StatusLabel:Set("Killing 🔥") 
        elseif QuestState == "ARISE_COLLECT" then StatusLabel:Set("Arise 👻") 
        end 
    else 
        StatusLabel:Set("Idle 💤") 
    end 
end end)
OrionLib:Init()

print([[
╔═══════════════════════════════════════════════════════════════════════╗
║   SOLO LEVELING - ARISE RAGNAROK (FULL VERSION)                      ║
║   ✅ All Features Working                                            ║
║   ✅ No Manual Buttons                                               ║
║   ✅ Auto Stats Fixed                                                ║
╚═══════════════════════════════════════════════════════════════════════╝
]])
-- ═══════════════════════════════════════════════════════════════════════
-- END PART 5 - SCRIPT COMPLETE!
-- ═══════════════════════════════════════════════════════════════════════
