local OrionLib = loadstring(game:HttpGet(('https://pastebin.com/raw/6y7EZZiX')))()

local Window = OrionLib:MakeWindow({
    Name = "Flow     .gg/TGUFEKrr ", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "FlowHub.json",
    IntroEnabled = true,  
    IntroText = "FlowHub Loading",  
    IntroIcon = "rbxassetid://113627638177078",  
    Icon = "rbxassetid://113627638177078",  
})

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

-- Remote Events
local EquipRemoteEvent = ReplicatedStorage["WvO"]["6f1bcb4a-5f97-40b7-9cfd-f18a2b49dc88"]
local buyRemoteEvent = ReplicatedStorage["WvO"]["64084741-be8f-4afd-8a31-b0bc1c709bee"]
local sellRemoteEvent = ReplicatedStorage["WvO"]["67993222-e592-4017-9bdb-5e29e21caa9b"]
local fireBombRemoteEvent = ReplicatedStorage["WvO"]["13b18c39-ae98-4b46-b8f3-eca379d3b7fc"]
local robRemoteEvent = ReplicatedStorage["WvO"]["7a985dd7-2744-4a3e-a4cd-7904f9a36418"]

-- Variablen
local plr = Players.LocalPlayer
local autorobToggle = false
local autoSellToggle = true
local vehicleSpeedDivider = 220
local healthAbortThreshold = 38
local policeCheckToggle = true  -- NEUER TOGGLE: Police Check

-- Tabs
local AutorobberyTab = Window:MakeTab({
    Name = "Auto Robbery",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local InformationTab = Window:MakeTab({
    Name = "Information",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local Section = InformationTab:AddSection({
    Name = "Problems with the key?"
})    

InformationTab:AddButton({
    Name = "Copy discord server",
    Callback = function()
        setclipboard("https://discord.gg/2kaABtnC")
        game:GetService("StarterGui"):SetCore("SendNotification", {Title="Copied!", Text="Discord invite copied.", Duration=3})
    end
})     

InformationTab:AddLabel("If you need help open ticket")
InformationTab:AddLabel("Its in test version many bugs!")

-- Autocollect System (Immer aktiv - Kein Toggle mehr)
local function startAutoCollect()
    -- Stoppe bestehende Loop falls vorhanden
    if getgenv().AutoCollectLoop then
        getgenv().AutoCollectLoop = false
        task.wait(0.1)
    end

    local Collected = {}
    local Range = 30
    local Robberies = {}

    -- Finde alle Robberies
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Folder") then
            local n = d.Name:lower()
            if n:find("robbery") or n:find("robberies") then
                table.insert(Robberies, d)
            end
        end
    end

    -- Neue Robberies hinzufügen
    Workspace.DescendantAdded:Connect(function(d)
        if d:IsA("Folder") then
            local n = d.Name:lower()
            if n:find("robbery") or n:find("robberies") then
                table.insert(Robberies, d)
            end
        end
    end)

    -- Loot Funktion
    local function loot(folder)
        local character = plr.Character
        if not character then return end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end

        for _, m in ipairs(folder:GetDescendants()) do
            if m:IsA("MeshPart") and m.Transparency == 0 then
                if not Collected[m] and (m.Position - humanoidRootPart.Position).Magnitude <= Range then
                    Collected[m] = true
                    task.spawn(function()
                        local a
                        if m.Parent and m.Parent.Name == "Money" then
                            a = {m, "EbZ", true}
                        else
                            a = {m, "yvo", true}
                        end
                        robRemoteEvent:FireServer(unpack(a))
                        task.wait(2.5)
                        a[3] = false
                        robRemoteEvent:FireServer(unpack(a))
                        if m and m.Parent and m.Transparency == 0 then
                            Collected[m] = nil
                        end
                    end)
                end
            end
        end
    end

    -- Starte die permanente Loop
    getgenv().AutoCollectLoop = true
    task.spawn(function()
        while getgenv().AutoCollectLoop do
            for _, r in ipairs(Robberies) do
                if r and r.Parent then
                    loot(r)
                end
            end
            task.wait(0.2)
        end
    end)
end

-- Autocollect automatisch beim Start starten (immer aktiv)
task.spawn(function()
    wait(2)
    startAutoCollect()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Autocollect",
        Text = "Always active",
        Duration = 3
    })
end)

-- Konfiguration
local configFileName = "Vortex_config5.json"

local function loadConfig()
    if isfile and isfile(configFileName) then
        local data = readfile(configFileName)
        local success, config = pcall(function()
            return game:GetService("HttpService"):JSONDecode(data)
        end)

        if success and config then
            autorobToggle = config.autorobToggle or false
            autoSellToggle = config.autoSellToggle or false
            vehicleSpeedDivider = config.vehicleSpeedDivider or 170
            healthAbortThreshold = config.healthAbortThreshold or 37
            policeCheckToggle = config.policeCheckToggle or true  -- NEU: Police Check laden
        end
    end
end

local function saveConfig()
    if writefile then
        local config = {
            autorobToggle = autorobToggle,
            autoSellToggle = autoSellToggle,
            vehicleSpeedDivider = vehicleSpeedDivider,
            healthAbortThreshold = healthAbortThreshold,
            policeCheckToggle = policeCheckToggle  -- NEU: Police Check speichern
        }
        local json = game:GetService("HttpService"):JSONEncode(config)
        writefile(configFileName, json)
    end
end

loadConfig()

-- Funktionen
local function JumpOut()
    local character = plr.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.SeatPart then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function ensurePlayerInVehicle()
    local vehicle = workspace:FindFirstChild("Vehicles") and workspace.Vehicles:FindFirstChild(plr.Name)
    local character = plr.Character

    if vehicle and character then
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        local driveSeat = vehicle:FindFirstChild("DriveSeat")

        if humanoid and driveSeat and humanoid.SeatPart ~= driveSeat then
            driveSeat:Sit(humanoid)
        end
    end
end

local function clickAtCoordinates(scaleX, scaleY, duration)
    local camera = game.Workspace.CurrentCamera
    local screenWidth = camera.ViewportSize.X
    local screenHeight = camera.ViewportSize.Y
    local absoluteX = screenWidth * scaleX
    local absoluteY = screenHeight * scaleY

    VirtualInputManager:SendMouseButtonEvent(absoluteX, absoluteY, 0, true, game, 0)  

    if duration and duration > 0 then
        task.wait(duration)  
    end

    VirtualInputManager:SendMouseButtonEvent(absoluteX, absoluteY, 0, false, game, 0) 
end

-- SCHNELLERE Tween-Funktionen
local function plrTween(destination)
    local character = plr.Character
    if not character or not character.PrimaryPart then
        return
    end

    local distance = (character.PrimaryPart.Position - destination).Magnitude
    local tweenDuration = distance / 40

    local TweenInfoToUse = TweenInfo.new(
        tweenDuration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local TweenValue = Instance.new("CFrameValue")
    TweenValue.Value = character:GetPivot()

    TweenValue.Changed:Connect(function(newCFrame)
        character:PivotTo(newCFrame)
    end)

    local targetCFrame = CFrame.new(destination)
    local tween = TweenService:Create(TweenValue, TweenInfoToUse, { Value = targetCFrame })

    tween:Play()
    tween.Completed:Wait()
    TweenValue:Destroy()
end

local function tweenTo(destination)
    local car = Workspace.Vehicles[plr.Name]
    if not car then return end
    
    car:SetAttribute("ParkingBrake", true)
    car:SetAttribute("Locked", true)
    car.PrimaryPart = car:FindFirstChild("DriveSeat",true)
    
    local character = plr.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            car.DriveSeat:Sit(humanoid)
        end
    end

    local distance = (car.PrimaryPart.Position - destination).Magnitude
    local tweenDuration = distance / vehicleSpeedDivider

    local TweenInfoToUse = TweenInfo.new(
        tweenDuration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local TweenValue = Instance.new("CFrameValue")
    TweenValue.Value = car:GetPivot()

    TweenValue.Changed:Connect(function(newCFrame)
        car:PivotTo(newCFrame)
        if car.DriveSeat then
            car.DriveSeat.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            car.DriveSeat.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end)

    local targetCFrame = CFrame.new(destination)
    local tween = TweenService:Create(TweenValue, TweenInfoToUse, { Value = targetCFrame })

    tween:Play()
    tween.Completed:Wait()
    car:SetAttribute("ParkingBrake", true)
    car:SetAttribute("Locked", true)
    TweenValue:Destroy()
end

local function MoveToDealer()
    local character = plr.Character
    local vehicle = workspace.Vehicles:FindFirstChild(plr.Name)
    if not vehicle then
        return false
    end

    local dealers = workspace:FindFirstChild("Dealers")
    if not dealers then
        return false
    end

    local closest, shortest = nil, math.huge
    for _, dealer in pairs(dealers:GetChildren()) do
        if dealer:FindFirstChild("Head") then
            local dist = (character.HumanoidRootPart.Position - dealer.Head.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = dealer.Head
            end
        end
    end

    if not closest then
        return false
    end

    local destination1 = closest.Position + Vector3.new(0, 5, 0)
    tweenTo(destination1)
    return true
end

-- SCHNELLERE Check-Funktionen
local function isClubAlreadyRobbed()
    local success, result = pcall(function()
        local clubFolder = workspace.Robberies["Club Robbery"]
        if not clubFolder then 
            return false 
        end
        
        local door = clubFolder.Club.Door
        if not door then 
            return false 
        end
        
        local accessory = door.Accessory
        if not accessory then 
            return false 
        end
        
        local blackPart = accessory:FindFirstChild("Black")
        if not blackPart then 
            return false 
        end
        
        local yRotation = math.abs(blackPart.Rotation.Y)
        return yRotation > 54.9
    end)
    
    if not success then
        return false
    end
    
    return result
end

local function isBankOpen()
    local success, result = pcall(function()
        local bankFolder = workspace.Robberies.BankRobbery
        if not bankFolder then return false end
        
        local lightGreen = bankFolder:FindFirstChild("LightGreen")
        local lightRed = bankFolder:FindFirstChild("LightRed")
        if not lightGreen or not lightRed then return false end
        
        local light1 = lightGreen:FindFirstChild("Light")
        local light2 = lightRed:FindFirstChild("Light")
        if not light1 or not light2 then return false end
        
        return light2.Enabled == false and light1.Enabled == true
    end)
    
    if not success then
        return false
    end
    
    return result
end

-- Police Check Funktion (aktualisiert auf 20 Studs)
local function isPoliceNearby()
    -- Wenn Police Check deaktiviert ist, immer false zurückgeben
    if not policeCheckToggle then
        return false
    end
    
    local success, result = pcall(function()
        local policeTeam = game:GetService("Teams"):FindFirstChild("Police")
        if not policeTeam then return false end
        
        local character = plr.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        local playerPos = character.HumanoidRootPart.Position
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Team == policeTeam and player.Character then
                local policeChar = player.Character
                if policeChar:FindFirstChild("HumanoidRootPart") then
                    local policePos = policeChar.HumanoidRootPart.Position
                    local distance = (playerPos - policePos).Magnitude
                    
                    if distance < 20 then -- GEÄNDERT: Von 50 auf 20 Studs
                        return true
                    end
                end
            end
        end
        return false
    end)
    
    if not success then
        return false
    end
    
    return result
end

local function ServerHop()
    local HttpService = game:GetService('HttpService')
    local TeleportService = game:GetService('TeleportService')
    local PlaceID = game.PlaceId 
    local AllIDs = {}
    local foundAnything = ""
    local actualHour = os.time()

    if isfile then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile("NotSameServersAutoRob.json"))
        end)

        if success and type(result) == "table" then
            AllIDs = result
        else
            AllIDs = {actualHour}
            writefile("NotSameServersVortex.json", HttpService:JSONEncode(AllIDs))
        end

        local function TPReturner()
            local Site
            if foundAnything == "" then
                Site = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end

            if Site.nextPageCursor then
                foundAnything = Site.nextPageCursor
            end

            for _, v in pairs(Site.data) do
                if tonumber(v.playing) < tonumber(v.maxPlayers) then
                    local ServerID = tostring(v.id)
                    local AlreadyVisited = false

                    for _, ExistingID in ipairs(AllIDs) do
                        if ServerID == ExistingID then
                            AlreadyVisited = true
                            break
                        end
                    end

                    if not AlreadyVisited then
                        table.insert(AllIDs, ServerID)
                        writefile("NotSameServersAutoRob.json", HttpService:JSONEncode(AllIDs))
                        TeleportService:TeleportToPlaceInstance(PlaceID, ServerID, plr)
                        wait(4)
                        return
                    end
                end
            end
        end
        
        pcall(function()
            TPReturner()
            if foundAnything ~= "" then
                TPReturner()
            end
        end)
    end
end

-- Camera Lock Funktion
local function lockCamera()
    local character = plr.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = character.HumanoidRootPart
    local heightOffset = 8
    local backOffset = 6
    
    local cameraPosition = rootPart.Position 
        - rootPart.CFrame.LookVector * backOffset 
        + Vector3.new(0, heightOffset, 0)
    
    local lookAtPosition = rootPart.Position + Vector3.new(0, 3, 0)
    
    game.Workspace.CurrentCamera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
    game.Workspace.CurrentCamera.FieldOfView = 90
end

-- Checkpoint Position
local checkpointPos = Vector3.new(-1467.31, 5.85, 3361.43)

-- Club Koordinaten
local clubCarPosition = Vector3.new(-1741.72, 11.10, 3057.55)
local clubPlayerPosition1 = Vector3.new(-1741.26, 11.10, 3013.44)
local clubWaitPosition = Vector3.new(-1743.96, 10.97, 3034.15)
local clubPlayerPosition2 = Vector3.new(-1744.37, 11.10, 3011.50)

-- Bank Koordinaten
local bankCarPosition = Vector3.new(-1199.73, 7.72, 3152.75)
local bankPlayerPosition1 = Vector3.new(-1242.96, 7.85, 3160.31)
local bankPlayerPosition2 = Vector3.new(-1242.29, 7.72, 3143.11)
local bankBombPosition = Vector3.new(-1250.10, 7.72, 3122.08)
local bankWaitPosition1 = Vector3.new(-1250.06, 7.72, 3120.45)
local bankWaitPosition2 = Vector3.new(-1231.50, 7.72, 3123.05)
local bankWaitPosition3 = Vector3.new(-1235.37, 7.72, 3102.60)
local bankWaitPosition4 = Vector3.new(-1247.26, 7.72, 3102.21)

-- ServerHop Positionen
local serverHopPos = Vector3.new(-1414.98, -23.48, 3667.48)
local altServerHopPos = Vector3.new(575.72, -25.98, 3629.79) -- Alternative Position

-- Flag um doppelte Ausführung zu verhindern
local isCurrentlyRobbing = false

-- Haupt-Loop
task.spawn(function()
    while task.wait(0.1) do
        if autorobToggle and not isCurrentlyRobbing then
            isCurrentlyRobbing = true
            
            -- Camera lock aktivieren
            local cameraConnection
            cameraConnection = RunService.RenderStepped:Connect(lockCamera)
            
            -- Checkpoint
            ensurePlayerInVehicle()
            clickAtCoordinates(0.5, 0.9, 0.05)
            tweenTo(checkpointPos)
            
            -- Check
            local clubRobbed = isClubAlreadyRobbed()
            local bankOpen = isBankOpen()
            
            -- Wenn BEIDE offen sind: Zuerst Club
            if clubRobbed == false and bankOpen == true then
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Club, Bank open ",
                    Text = "Going to rob",
                    Duration = 2
                })
                
                -- Grenade checken
                local function checkForGrenade()
                    for _, item in ipairs(plr.Backpack:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Grenade" then
                            return true
                        end
                    end
                    for _, item in ipairs(plr.Character:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Grenade" then
                            return true
                        end
                    end
                    return false
                end
                
                if not checkForGrenade() then
                    MoveToDealer()
                    task.wait(0.5)
                    buyRemoteEvent:FireServer("Grenade", "Dealer")
                    task.wait(0.5)
                end
                
                -- Club Prozess
                ensurePlayerInVehicle()
                tweenTo(clubCarPosition)
                JumpOut()
                plrTween(clubPlayerPosition1)
                EquipRemoteEvent:FireServer("Grenade")
                task.wait(0.5)
                
                local tool = plr.Character:FindFirstChild("Grenade")
                if tool then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                    task.wait(0.3)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    task.wait(0.2)
                    fireBombRemoteEvent:FireServer()
                end
                
                plrTween(clubWaitPosition)
                task.wait(2.4)
                plrTween(clubPlayerPosition2)
                task.wait(5)
                
                -- Verkaufen
                if autoSellToggle then
                    ensurePlayerInVehicle()
                    MoveToDealer()
                    task.wait(0.5)
                    for i = 1, 3 do
                        sellRemoteEvent:FireServer("Gold", "Dealer")
                        task.wait(0.1)
                    end
                    task.wait(0.5)
                end
                
                -- Bank nach Club
                ensurePlayerInVehicle()
                tweenTo(checkpointPos)
                
                -- Bomb checken
                local function checkForBomb()
                    for _, item in ipairs(plr.Backpack:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Bomb" then
                            return true
                        end
                    end
                    for _, item in ipairs(plr.Character:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Bomb" then
                            return true
                        end
                    end
                    return false
                end
                
                if not checkForBomb() then
                    MoveToDealer()
                    task.wait(0.5)
                    buyRemoteEvent:FireServer("Bomb", "Dealer")
                    task.wait(0.5)
                end
                
                -- Bank Prozess
                ensurePlayerInVehicle()
                tweenTo(bankCarPosition)
                JumpOut()
                plrTween(bankPlayerPosition1)
                plrTween(bankPlayerPosition2)
                EquipRemoteEvent:FireServer("Bomb")
                task.wait(0.5)
                
                local tool = plr.Character:FindFirstChild("Bomb")
                if tool then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                    task.wait(0.3)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    task.wait(0.2)
                end
                
                fireBombRemoteEvent:FireServer()
                plrTween(bankBombPosition)
                task.wait(1)
                plrTween(bankWaitPosition1)
                task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                plrTween(bankWaitPosition2)
                task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                plrTween(bankWaitPosition3)
                task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                plrTween(bankWaitPosition4)
                task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                
                -- Verkaufen
                if autoSellToggle then
                    ensurePlayerInVehicle()
                    MoveToDealer()
                    task.wait(0.5)
                    for i = 1, 3 do
                        sellRemoteEvent:FireServer("Gold", "Dealer")
                        task.wait(0.1)
                    end
                    task.wait(0.5)
                end
                
                -- Police Check vor ServerHop (nur wenn aktiviert)
                if policeCheckToggle and isPoliceNearby() then
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "Police nearby!",
                        Text = "Going to alternative location",
                        Duration = 3
                    })
                    ensurePlayerInVehicle()
                    tweenTo(altServerHopPos)
                else
                    ensurePlayerInVehicle()
                    tweenTo(serverHopPos)
                end
                ServerHop()
                
            -- Nur Club offen
            elseif clubRobbed == false and bankOpen == false then
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Only club open",
                    Text = "Robbing club",
                    Duration = 2
                })
                
                local function checkForGrenade()
                    for _, item in ipairs(plr.Backpack:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Grenade" then
                            return true
                        end
                    end
                    for _, item in ipairs(plr.Character:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Grenade" then
                            return true
                        end
                    end
                    return false
                end
                
                if not checkForGrenade() then
                    MoveToDealer()
                    task.wait(0.5)
                    buyRemoteEvent:FireServer("Grenade", "Dealer")
                    task.wait(0.5)
                end
                
                ensurePlayerInVehicle()
                tweenTo(clubCarPosition)
                JumpOut()
                plrTween(clubPlayerPosition1)
                EquipRemoteEvent:FireServer("Grenade")
                task.wait(0.5)
                
                local tool = plr.Character:FindFirstChild("Grenade")
                if tool then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                    task.wait(0.3)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    task.wait(0.2)
                    fireBombRemoteEvent:FireServer()
                end
                
                plrTween(clubWaitPosition)
                task.wait(2.4)
                plrTween(clubPlayerPosition2)
                task.wait(5)
                
                if autoSellToggle then
                    ensurePlayerInVehicle()
                    MoveToDealer()
                    task.wait(0.5)
                    for i = 1, 3 do
                        sellRemoteEvent:FireServer("Gold", "Dealer")
                        task.wait(0.1)
                    end
                    task.wait(0.5)
                end
                
                ensurePlayerInVehicle()
                tweenTo(checkpointPos)
                bankOpen = isBankOpen()
                
                if bankOpen then
                    local function checkForBomb()
                        for _, item in ipairs(plr.Backpack:GetChildren()) do
                            if item:IsA("Tool") and item.Name == "Bomb" then
                                return true
                            end
                        end
                        for _, item in ipairs(plr.Character:GetChildren()) do
                            if item:IsA("Tool") and item.Name == "Bomb" then
                                return true
                            end
                        end
                        return false
                    end
                    
                    if not checkForBomb() then
                        MoveToDealer()
                        task.wait(0.5)
                        buyRemoteEvent:FireServer("Bomb", "Dealer")
                        task.wait(0.5)
                    end
                    
                    ensurePlayerInVehicle()
                    tweenTo(bankCarPosition)
                    JumpOut()
                    plrTween(bankPlayerPosition1)
                    plrTween(bankPlayerPosition2)
                    EquipRemoteEvent:FireServer("Bomb")
                    task.wait(0.5)
                    
                    local tool = plr.Character:FindFirstChild("Bomb")
                    if tool then
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                        task.wait(0.3)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                        task.wait(0.2)
                    end
                    
                    fireBombRemoteEvent:FireServer()
                    plrTween(bankBombPosition)
                    task.wait(1)
                    plrTween(bankWaitPosition1)
                    task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                    plrTween(bankWaitPosition2)
                    task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                    plrTween(bankWaitPosition3)
                    task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                    plrTween(bankWaitPosition4)
                    task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                    
                    if autoSellToggle then
                        ensurePlayerInVehicle()
                        MoveToDealer()
                        task.wait(0.5)
                        for i = 1, 3 do
                            sellRemoteEvent:FireServer("Gold", "Dealer")
                            task.wait(0.1)
                        end
                        task.wait(0.5)
                    end
                    
                    -- Police Check vor ServerHop (nur wenn aktiviert)
                    if policeCheckToggle and isPoliceNearby() then
                        game.StarterGui:SetCore("SendNotification", {
                            Title = "Police nearby!",
                            Text = "Going to alternative location",
                            Duration = 3
                        })
                        ensurePlayerInVehicle()
                        tweenTo(altServerHopPos)
                    else
                        ensurePlayerInVehicle()
                        tweenTo(serverHopPos)
                    end
                    ServerHop()
                else
                    -- Police Check vor ServerHop (nur wenn aktiviert)
                    if policeCheckToggle and isPoliceNearby() then
                        game.StarterGui:SetCore("SendNotification", {
                            Title = "Police nearby!",
                            Text = "Going to alternative location",
                            Duration = 3
                        })
                        ensurePlayerInVehicle()
                        tweenTo(altServerHopPos)
                    else
                        ensurePlayerInVehicle()
                        tweenTo(serverHopPos)
                    end
                    ServerHop()
                end
                
            -- Nur Bank offen
            elseif clubRobbed == true and bankOpen == true then
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Only bank open",
                    Text = "Going to rob bank",
                    Duration = 2
                })
                
                local function checkForBomb()
                    for _, item in ipairs(plr.Backpack:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Bomb" then
                            return true
                        end
                    end
                    for _, item in ipairs(plr.Character:GetChildren()) do
                        if item:IsA("Tool") and item.Name == "Bomb" then
                            return true
                        end
                    end
                    return false
                end
                
                if not checkForBomb() then
                    MoveToDealer()
                    task.wait(0.5)
                    buyRemoteEvent:FireServer("Bomb", "Dealer")
                    task.wait(0.5)
                end
                
                ensurePlayerInVehicle()
                tweenTo(bankCarPosition)
                JumpOut()
                plrTween(bankPlayerPosition1)
                plrTween(bankPlayerPosition2)
                EquipRemoteEvent:FireServer("Bomb")
                task.wait(0.5)
                
                local tool = plr.Character:FindFirstChild("Bomb")
                if tool then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                    task.wait(0.3)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    task.wait(0.2)
                end
                
                fireBombRemoteEvent:FireServer()
                plrTween(bankBombPosition)
                task.wait(1)
                plrTween(bankWaitPosition1)
                task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                plrTween(bankWaitPosition2)
                task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                plrTween(bankWaitPosition3)
                task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                plrTween(bankWaitPosition4)
                task.wait(5) -- GEÄNDERT: 5 statt 4 Sekunden
                
                if autoSellToggle then
                    ensurePlayerInVehicle()
                    MoveToDealer()
                    task.wait(0.5)
                    for i = 1, 3 do
                        sellRemoteEvent:FireServer("Gold", "Dealer")
                        task.wait(0.1)
                    end
                    task.wait(0.5)
                end
                
                -- Police Check vor ServerHop (nur wenn aktiviert)
                if policeCheckToggle and isPoliceNearby() then
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "Police nearby!",
                        Text = "Going to alternative location",
                        Duration = 3
                    })
                    ensurePlayerInVehicle()
                    tweenTo(altServerHopPos)
                else
                    ensurePlayerInVehicle()
                    tweenTo(serverHopPos)
                end
                ServerHop()
                
            -- Nichts offen
            elseif clubRobbed == true and bankOpen == false then
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Nothing open",
                    Text = "Server hopping...",
                    Duration = 2
                })
                
                -- Police Check vor ServerHop (nur wenn aktiviert)
                if policeCheckToggle and isPoliceNearby() then
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "Police nearby!",
                        Text = "Going to alternative location",
                        Duration = 3
                    })
                    ensurePlayerInVehicle()
                    tweenTo(altServerHopPos)
                else
                    ensurePlayerInVehicle()
                    tweenTo(serverHopPos)
                end
                ServerHop()
            end
            
            -- Camera Connection trennen
            if cameraConnection then
                cameraConnection:Disconnect()
            end
            
            isCurrentlyRobbing = false
        end
    end
end)

-- Autorobbery Tab
AutorobberyTab:AddParagraph("How does it work automatically?", "You need to add this script to your auto-execute folder from your executer.")


local Section = AutorobberyTab:AddSection({
    Name = "Autorobbery Options"
})

-- Toggles
local autorobToggleBtn = AutorobberyTab:AddToggle({
    Name = "Autorob",
    Default = autorobToggle,
    Callback = function(Value)
        autorobToggle = Value
        saveConfig()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Autorob",
            Text = Value and "Enabled" or "Disabled",
            Duration = 2
        })
    end    
})

local autoSellToggleBtn = AutorobberyTab:AddToggle({
    Name = "Automatically sells stolen items",
    Default = autoSellToggle,
    Callback = function(Value)
        autoSellToggle = Value
        saveConfig()
    end    
})

-- NEUER TOGGLE: Police Check
local policeCheckToggleBtn = AutorobberyTab:AddToggle({
    Name = "Police Check (20 studs)",
    Default = policeCheckToggle,
    Callback = function(Value)
        policeCheckToggle = Value
        saveConfig()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Police Check",
            Text = Value and "Enabled (20 studs)" or "Disabled",
            Duration = 2
        })
    end    
})

local Section = AutorobberyTab:AddSection({
    Name = "Settings"
})

AutorobberyTab:AddSlider({
    Name = "Vehicle speed",
    Min = 50,
    Max = 175,
    Default = vehicleSpeedDivider,
    Increment = 5,
    Value = vehicleSpeedDivider,
    Callback = function(value)
        vehicleSpeedDivider = value
        saveConfig()
    end
})

AutorobberyTab:AddSlider({
    Name = "Life limit where it should stop farming",
    Min = 27,
    Max = 100,
    Default = healthAbortThreshold,
    Increment = 1,
    Value = healthAbortThreshold,
    Callback = function(value)
        healthAbortThreshold = value
        saveConfig()
    end
})

OrionLib:Init()
