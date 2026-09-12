local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

--// Window
local Window = WindUI:CreateWindow({
    Title = "Murder Mystery 2",
    Icon = "rbxassetid://70820218321157",
    Author = "赤👻",
    Folder = "MM2WindUI",
    Size = UDim2.fromOffset(580,430),
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 200,
    MinimizeKey = Enum.KeyCode.RightControl
})

-- APLICAÇÃO DO WALLPAPER DENTRO DO MENU
pcall(function()
    local mainFrame = Window.UIElements and Window.UIElements.Main or Window.Frame or Window.Container
    
    if not mainFrame and Window.Root then
        mainFrame = Window.Root:FindFirstChildOfClass("Frame")
    end
    
    if mainFrame then
        mainFrame.BackgroundTransparency = 0.4
        
        local bgImage = Instance.new("ImageLabel")
        bgImage.Name = "MenuWallpaper"
        bgImage.Size = UDim2.fromScale(1, 1)
        bgImage.Position = UDim2.fromScale(0, 0)
        bgImage.Image = "rbxassetid://140088303441183" 
        bgImage.BackgroundTransparency = 1
        bgImage.ImageTransparency = 0 
        bgImage.ScaleType = Enum.ScaleType.Crop
        bgImage.ZIndex = 1
        bgImage.Parent = mainFrame
    end
end)

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "rbxassetid://70820218321157",
    CornerRadius = UDim.new(0.5, 0),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("000000"),
        Color3.fromHex("#282828")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variáveis de Role
local roles = {}
local Murder, Sheriff

-- Variáveis Gerais
local AimbotEnabled = false
local FovVisible = false
local FovSize = 100

-- Variáveis Kill Aura
local KillAuraEnabled = false
local KillAuraDistance = math.huge
local ThrowKnifeEnabled = false

-- CONFIGURAÇÕES DO AUTO COIN
local AutoCoinEnabled = false
local AutoCoinSpeed = 25
local TempoNaMoeda = 0.2
local AutoPrestigeEnabled = false
local AutoSafeEnabled = false

local EspEnabled = false
local GunEspEnabled = false
local AntiFlingEnabled = false
local LowGraphicsEnabled = false
local AutoCollectGunEnabled = false

local Speed = 16
local Jump = 50
local InfiniteJump = false
local NoclipEnabled = false
local FlyEnabled = false
local FlySpeed = 30 

local bodyVelocity
local bodyGyro
local flyConnection
local moveVector = Vector3.zero

local SelectedPlayerToTp = ""
local PlayerDropdown = nil

-- VARIÁVEIS DO SISTEMA DE FLING
local SelectedPlayerToFling = ""
local FlingActive = false
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- VARIÁVEIS DO SHOOT BUTTON / SILENT AIM
local activeSilentAim = false
local cachedTargetCFrame = nil
local ShootButtonGui = nil

-- FOV Seguro
local FOVCircle = nil
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.NumSides = 100
    FOVCircle.Color = Color3.fromRGB(0,0,0)
    FOVCircle.Thickness = 6 
    FOVCircle.Transparency = 1
    FOVCircle.Filled = false
    FOVCircle.Visible = false
end)

local Coletadas = {}
LocalPlayer.CharacterAdded:Connect(function()
    Coletadas = {}
end)

WindUI:SetTheme("Dark")

-- TABS
local InfoTab = Window:Tab({Title = "Info", Icon = "house"})
local CombatTab = Window:Tab({Title = "Combate", Icon = "sword"})
local FlingTab = Window:Tab({Title = "Fling", Icon = "wind"})
local EspTab = Window:Tab({Title = "ESP", Icon = "eye"})
local TeleportTab = Window:Tab({Title = "Teleportes", Icon = "map-pinned"})
local FarmTab = Window:Tab({Title = "Farm", Icon = "coins"})
local PlayerTab = Window:Tab({Title = "Player", Icon = "user"})
local PerformanceTab = Window:Tab({Title = "Desempenho", Icon = "cpu"})

local RoleParagraph = InfoTab:Paragraph({Title = "Time", Desc = "Carregando..."})
local PingParagraph = InfoTab:Paragraph({Title = "Ping", Desc = "0 ms"})
local FPSParagraph = InfoTab:Paragraph({Title = "FPS", Desc = "0 FPS"})
local ServerParagraph = InfoTab:Paragraph({Title = "Servidor", Desc = "0/0"})

---------------------------------------------------------------------------
-- [SISTEMA DE ROLE DETECTOR OTIMIZADO]
---------------------------------------------------------------------------
task.spawn(function()
    while true do
        local getPlayerData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        if getPlayerData then
            pcall(function()
                roles = getPlayerData:InvokeServer() or {}
                Murder, Sheriff = nil, nil
                
                local tempSheriff = nil
                local sheriffDeadOrKilled = false

                for name, data in pairs(roles) do
                    if data.Role == "Murderer" then
                        Murder = name
                    elseif data.Role == "Sheriff" then
                        tempSheriff = name
                        if data.Killed or data.Dead then
                            sheriffDeadOrKilled = true
                        end
                    elseif data.Role == "Hero" then
                        tempSheriff = name
                    end
                end

                if sheriffDeadOrKilled then
                    tempSheriff = nil
                end

                if not tempSheriff then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character and (p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun")) then
                            if p.Name ~= Murder then
                                tempSheriff = p.Name
                                break
                            end
                        end
                    end
                end

                Sheriff = tempSheriff
            end)
        end
        task.wait(0.5)
    end
end)

local function IsParticipatingAndAlive(player)
    if not roles or not roles[player.Name] then return false end
    local data = roles[player.Name]
    return not data.Killed and not data.Dead
end

local function GetPlayerRole(player)
    if not player then return "Innocent" end
    local isParticipating = false
    if roles then
        for nome, _ in pairs(roles) do
            if nome == player.Name then
                isParticipating = true
                break
            end
        end
    end
    if roles and next(roles) ~= nil and not isParticipating then
        return "Innocent"
    end
    if player.Name == Murder then return "Murderer" end
    if player.Name == Sheriff then return "Sheriff" end
    return "Innocent"
end

local function GetMurdererPlayer()
    if Murder then
        return Players:FindFirstChild(Murder)
    end
    return nil
end

---------------------------------------------------------------------------
-- [ LOOP DA KILL AURA (Mecanismo Original) ]
---------------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.05) do
        -- Só executa se a Kill Aura estiver ativada, jogador existir e a classe for Murderer
        if KillAuraEnabled and GetPlayerRole(LocalPlayer) == "Murderer" and LocalPlayer.Character then
            
            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local equippedTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            local handle = equippedTool and equippedTool:FindFirstChild("Handle")

            if equippedTool and handle and myHRP then
                
                -- Varre todos os jogadores do servidor
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and IsParticipatingAndAlive(p) then
                        local pChar = p.Character
                        
                        if pChar and pChar:FindFirstChild("HumanoidRootPart") and pChar:FindFirstChild("Humanoid") then
                            local targetHRP = pChar.HumanoidRootPart
                            local targetHum = pChar.Humanoid
                            
                            -- Se o alvo estiver vivo
                            if targetHum.Health > 0 then
                                
                                local distance = (myHRP.Position - targetHRP.Position).Magnitude
                                
                                if distance <= KillAuraDistance then
                                    pcall(function()
                                        -- Simula o toque da faca no jogador
                                        firetouchinterest(handle, targetHRP, 0)
                                        firetouchinterest(handle, targetHRP, 1)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

---------------------------------------------------------------------------
-- [ PREDIÇÃO 3D APENAS HORIZONTAL (EIXO Y ZERADO) ]
---------------------------------------------------------------------------
local function GetPredictedCFrame(targetChar)
    if not targetChar then return nil end
    
    local targetPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("LowerTorso") or targetChar:FindFirstChild("Torso")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    
    if not targetPart or not humanoid then return nil end

    local pos = targetPart.Position
    local moveDir = humanoid.MoveDirection
    local vel = targetPart.AssemblyLinearVelocity

    local currentPing = 80
    pcall(function()
        currentPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)

    local pingInSeconds = currentPing / 1000
    local totalLatency = pingInSeconds + 0.05

    -- Zera o eixo Y da velocidade para calcular apenas X e Z
    local predictedVelocity = Vector3.new(vel.X, 0, vel.Z)
    if moveDir.Magnitude > 0 then
        local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        if horizSpeed < 1 then horizSpeed = humanoid.WalkSpeed end
        local horizVel = moveDir * horizSpeed
        predictedVelocity = Vector3.new(horizVel.X, 0, horizVel.Z)
    end

    local finalPos = pos + (predictedVelocity * totalLatency)

    return CFrame.new(finalPos)
end

task.spawn(function()
    while true do
        local murderer = GetMurdererPlayer()
        if murderer and murderer.Character and murderer.Character:FindFirstChildOfClass("Humanoid") and murderer.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            cachedTargetCFrame = GetPredictedCFrame(murderer.Character)
        else
            cachedTargetCFrame = nil
        end
        task.wait()
    end
end)

---------------------------------------------------------------------------
-- [ SILENT AIM (METATABLE HOOK) ]
---------------------------------------------------------------------------
pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if activeSilentAim and cachedTargetCFrame and not checkcaller() then
            local targetPos = cachedTargetCFrame.Position
            if method == "Raycast" and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                local origin = args[1]
                args[2] = (targetPos - origin).Unit * 1000
                return oldNamecall(self, unpack(args))
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                if typeof(args[1]) == "Ray" then
                    local origin = args[1].Origin
                    args[1] = Ray.new(origin, (targetPos - origin).Unit * 1000)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    mt.__index = newcclosure(function(t, k)
        if activeSilentAim and cachedTargetCFrame and not checkcaller() then
            if k == "Hit" or k == "Target" then
                if typeof(t) == "Instance" and t:IsA("Mouse") then
                    if k == "Hit" then return cachedTargetCFrame end
                end
            end
        end
        return oldIndex(t, k)
    end)
    setreadonly(mt, true)
end)

local ThrowButtonGui = nil

-- Função auxiliar para encontrar o jogador vivo mais próximo
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

local function ToggleThrowButtonGui(enable)
    if enable then
        if ThrowButtonGui then ThrowButtonGui:Destroy() end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "ThrowButtonGui"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local ThrowButton = Instance.new("TextButton")
        ThrowButton.Name = "ThrowButton"
        ThrowButton.Size = UDim2.new(0, 150, 0, 70)
        ThrowButton.Position = UDim2.new(0.75, 0, 0.35, -20)
        ThrowButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ThrowButton.BackgroundTransparency = 0.5
        ThrowButton.Text = "THROW KNIFE"
        ThrowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ThrowButton.TextSize = 18
        ThrowButton.Font = Enum.Font.SourceSans
        ThrowButton.Active = true
        ThrowButton.Draggable = false
        ThrowButton.Parent = ScreenGui

        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = ThrowButton

        local UIStroke = Instance.new("UIStroke")
        UIStroke.Thickness = 3
        UIStroke.Color = Color3.fromRGB(255, 255, 255)
        UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        UIStroke.Parent = ThrowButton

        local StrokeGradient = Instance.new("UIGradient")
        StrokeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
        })
        StrokeGradient.Parent = UIStroke

        task.spawn(function()
            local runService = game:GetService("RunService")
            local rot = 0
            while ThrowButton.Parent do
                rot = (rot + 3) % 360
                if StrokeGradient.Parent then
                    StrokeGradient.Rotation = rot
                end
                runService.Heartbeat:Wait()
            end
        end)

        ThrowButton.MouseButton1Down:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end

        -- Garante que a faca existe
        local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if not knife then return end

        -- Equipa a faca (o servidor rejeita o RemoteEvent se ela estiver na mochila)
        if knife.Parent == LocalPlayer.Backpack then
            knife.Parent = char
            task.wait(0.05)
        end

        local events = knife:FindFirstChild("Events")
        local knifeThrown = events and events:FindFirstChild("KnifeThrown")
        if not knifeThrown then return end

        -- Busca o jogador mais próximo
        local targetPlayer = GetClosestPlayer()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = targetPlayer.Character.HumanoidRootPart.Position
            local handle = knife:FindFirstChild("Handle")
            local originPos = handle and handle.Position or char.HumanoidRootPart.Position

            -- Argumento 1: Origem olhando para o alvo
            local throwCFrame = CFrame.lookAt(originPos, targetPos)
            -- Argumento 2: Posição do alvo
            local targetCFrame = CFrame.new(targetPos)

            -- Disparo direto do RemoteEvent
            knifeThrown:FireServer(throwCFrame, targetCFrame)
        end
    end)
end)

        ThrowButtonGui = ScreenGui
    else
        if ThrowButtonGui then
            ThrowButtonGui:Destroy()
            ThrowButtonGui = nil
        end
    end
end

---------------------------------------------------------------------------
-- [ CRIANDO / DESTRUINDO O BOTÃO SHOOT ]
---------------------------------------------------------------------------
local function ToggleShootButtonGui(enable)
    if enable then
        if ShootButtonGui then ShootButtonGui:Destroy() end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "ShootButtonGui"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local ShootButton = Instance.new("TextButton")
        ShootButton.Name = "ShootButton"
        ShootButton.Size = UDim2.new(0, 150, 0, 70)
        ShootButton.Position = UDim2.new(0.75, 0, 0.5, 5)
        ShootButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ShootButton.BackgroundTransparency = 0.5
        ShootButton.Text = "SHOOT"
        ShootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ShootButton.TextSize = 18
        ShootButton.Font = Enum.Font.SourceSans
        ShootButton.Active = true
        ShootButton.Draggable = false
        ShootButton.Parent = ScreenGui

        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = ShootButton

        local UIStroke = Instance.new("UIStroke")
        UIStroke.Thickness = 3
        UIStroke.Color = Color3.fromRGB(255, 255, 255)
        UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        UIStroke.Parent = ShootButton

        local StrokeGradient = Instance.new("UIGradient")
        StrokeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 150)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
        })
        StrokeGradient.Parent = UIStroke

        task.spawn(function()
            local runService = game:GetService("RunService")
            local rot = 0
            while ShootButton.Parent do
                rot = (rot + 3) % 360
                if StrokeGradient.Parent then
                    StrokeGradient.Rotation = rot
                end
                runService.Heartbeat:Wait()
            end
        end)

 ShootButton.MouseButton1Down:Connect(function()
            local Character = LocalPlayer.Character
            local Backpack = LocalPlayer:FindFirstChild("Backpack")
            
            if Character and Backpack and cachedTargetCFrame then
                local gunInBackpack = Backpack:FindFirstChild("Gun")
                local gunInChar = Character:FindFirstChild("Gun")
                
                -- 1. Equipa a arma se ela estiver na mochila
                if gunInBackpack and not gunInChar then
                    gunInBackpack.Parent = Character
                    gunInChar = gunInBackpack
                end

                -- 3. Dispara o RemoteEvent direto para o Murderer
                if gunInChar then
                    local shootEvent = gunInChar:FindFirstChild("Shoot")
                    local handle = gunInChar:FindFirstChild("Handle")
                    local myHRP = Character:FindFirstChild("HumanoidRootPart")
                    
                    if shootEvent and shootEvent:IsA("RemoteEvent") then
                        -- Arg 1: Origem (Posição da sua arma ou corpo)
                        local originPos = handle and handle.CFrame or (myHRP and myHRP.CFrame) or CFrame.new()
                        -- Arg 2: Destino (A mira preditiva que vai em direção ao Murderer)
                        local targetPos = cachedTargetCFrame
                        
                        -- Fogo direto no servidor, sem precisar clicar
                        shootEvent:FireServer(originPos, targetPos)
                    end
                end
                
                -- 4. Guarda a arma rapidamente após o tiro
                task.delay(0.05, function()
                    local currentGun = Character:FindFirstChild("Gun")
                    if currentGun then
                        currentGun.Parent = Backpack
                    end
                end)
            end
        end)

        ShootButtonGui = ScreenGui
    else
        if ShootButtonGui then
            ShootButtonGui:Destroy()
            ShootButtonGui = nil
        end
    end
end

local FPS = 0
local Last = tick()

RunService.RenderStepped:Connect(function()
    FPS += 1
    if tick() - Last >= 1 then
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        PingParagraph:SetDesc(ping .. " ms")
        FPSParagraph:SetDesc(FPS .. " FPS")
        ServerParagraph:SetDesc(#Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        
        local role = GetPlayerRole(LocalPlayer)
        local roleDesc = '<font color="#00FF00">Innocent</font>'
        if role == "Murderer" then
            roleDesc = '<font color="#FF0000">Murderer</font>'
        elseif role == "Sheriff" then
            roleDesc = '<font color="#0055FF">Sheriff</font>'
        end
        RoleParagraph:SetDesc(roleDesc)

        FPS = 0
        Last = tick()
    end
end)

local function TeleportToCFrame(targetCFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetCFrame.Position)
    end
end

local function GetPlayerNamesList()
    local list = {}
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

local function GetPlayerByRole(roleName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetPlayerRole(p) == roleName then
            return p
        end
    end
    return nil
end

local SafePart = Instance.new("Part")
SafePart.Name = "SafeArea"
SafePart.Size = Vector3.new(20,1,20)
SafePart.Position = Vector3.new(10000,500,10000)
SafePart.Anchored = true
SafePart.CanCollide = true
SafePart.Color = Color3.fromRGB(0,255,0)
SafePart.Material = Enum.Material.Neon
SafePart.Transparency = 0
SafePart.Parent = workspace

local function TeleportToSafeArea()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = SafePart.CFrame + Vector3.new(0,3,0)
    end
end

local function FindDroppedGun()
    local gun = workspace:FindFirstChild("GunDrop")
    if gun then return gun end
    for _,obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "GunDrop" or (obj:IsA("Model") and obj:FindFirstChild("GunDrop")) then
            return obj:FindFirstChild("GunDrop") or obj
        end
    end
    return nil
end

RunService.Stepped:Connect(function()
    if AntiFlingEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

---------------------------------------------------------------------------
-- [ AUTO COIN COM RADAR E ROTA FIXA ]
---------------------------------------------------------------------------
local function IsCoinValid(coin)
    return coin 
        and coin.Parent 
        and not Coletadas[coin] 
        and coin.Transparency < 1 
        and coin:IsDescendantOf(workspace)
end

local function GetClosestCoin(centerPos, maxRadius)
    local menorDistancia = maxRadius or math.huge
    local moedaAlvo = nil

    local areaDeBusca = workspace:FindFirstChild("NormalMaps") or workspace:FindFirstChild("Map") or workspace

    for _, obj in ipairs(areaDeBusca:GetDescendants()) do
        if obj:IsA("BasePart") and IsCoinValid(obj) and obj.CanCollide == false then
            local nome = string.lower(obj.Name)
            if nome:find("coin") or nome:find("gold") or nome:find("token") then
                if obj.Size.X <= 6 and obj.Size.Y <= 6 and obj.Size.Z <= 6 then
                    local model = obj:FindFirstAncestorOfClass("Model")
                    if model and not model:FindFirstChild("Lobby") then
                        local dist = (centerPos - obj.Position).Magnitude
                        if dist <= menorDistancia then
                            menorDistancia = dist
                            moedaAlvo = obj
                        end
                    end
                end
            end
        end
    end
    return moedaAlvo
end

local currentCoinTween = nil

task.spawn(function()
    while true do
        task.wait(0.2)
        
        while AutoCoinEnabled do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 and IsParticipatingAndAlive(LocalPlayer) then
                
                local alvo = GetClosestCoin(hrp.Position, 100)
                
                if not alvo then
                    alvo = GetClosestCoin(hrp.Position, math.huge)
                end
                
                if alvo then
                    local noclipConnection = RunService.Stepped:Connect(function()
                        if char then
                            for _, part in ipairs(char:GetChildren()) do
                                if part:IsA("BasePart") then part.CanCollide = false end
                            end
                        end
                    end)
                    
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                    bv.Velocity = Vector3.zero
                    bv.Parent = hrp

                    local spawnDestino = alvo.Position
                    if alvo.Parent and alvo.Parent:IsA("Model") and alvo.Parent.PrimaryPart then
                        spawnDestino = alvo.Parent.PrimaryPart.Position
                    elseif alvo.Name == "Coin_Sub" and alvo.Parent and alvo.Parent:FindFirstChild("Coin") then
                        spawnDestino = alvo.Parent.Coin.Position
                    end
                    
                    local destinoFinal = Vector3.new(spawnDestino.X, spawnDestino.Y + 1.2, spawnDestino.Z)
                    
                    local atualPos = hrp.Position
                    local distancia = (atualPos - destinoFinal).Magnitude
                    local tempoViagem = math.max(0.05, distancia / AutoCoinSpeed)
                    
                    if currentCoinTween then
                        currentCoinTween:Cancel()
                    end
                    
                    local tweenInfo = TweenInfo.new(tempoViagem, Enum.EasingStyle.Linear)
                    currentCoinTween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(destinoFinal)})
                    currentCoinTween:Play()
                    
                    local tempoEsperado = tick() + tempoViagem
                    
                    while AutoCoinEnabled do
                        local currentPos = hrp.Position
                        local distToTarget = (currentPos - destinoFinal).Magnitude
                        
                        if distToTarget <= 0.8 or tick() >= tempoEsperado then 
                            break
                        end
                        RunService.Heartbeat:Wait()
                    end

                    if currentCoinTween then
                        currentCoinTween:Cancel()
                        currentCoinTween = nil
                    end
                    
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if bv then 
                        bv.Velocity = Vector3.zero 
                    end
                    
                    if alvo and alvo.Parent then
                        Coletadas[alvo] = true
                    end
                    
                    task.wait(TempoNaMoeda)

                    if noclipConnection then noclipConnection:Disconnect() end
                    if bv then bv:Destroy() end

                    if not AutoCoinEnabled then break end
                else
                    task.wait(1)
                end
            else
                task.wait(0.5)
            end
        end
    end
end)

local function GetClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = FovSize
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myRole = GetPlayerRole(LocalPlayer)

    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local role = GetPlayerRole(p)
            local canTarget = false

            if myRole == "Murderer" then
                canTarget = true
            else
                if role == "Murderer" then
                    canTarget = true
                end
            end

            if canTarget then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = p.Character.Head
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function IsPlayerAlive(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if roles and roles[player.Name] then
        local playerData = roles[player.Name]
        return not playerData.Killed and not playerData.Dead
    end
    return true
end

local function UpdateESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local highlight = char:FindFirstChild("ESPHighlight")

            if EspEnabled then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ESPHighlight"
                    highlight.Parent = char
                end

                local color = Color3.fromRGB(0, 255, 0) 
                if IsPlayerAlive(p) then
                    local role = GetPlayerRole(p)
                    if role == "Murderer" then
                        color = Color3.fromRGB(255, 0, 0) 
                    elseif role == "Sheriff" then
                        color = Color3.fromRGB(0, 0, 255) 
                    end
                end

                highlight.FillColor = color
                highlight.OutlineColor = color
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
            else
                if highlight then highlight:Destroy() end
            end
        elseif p == LocalPlayer then
            local highlight = p.Character and p.Character:FindFirstChild("ESPHighlight")
            if highlight then highlight:Destroy() end
        end
    end
end

---------------------------------------------------------------------------
-- [ MODO LEVE ]
---------------------------------------------------------------------------
local function IsPlayerCharacter(instance)
    local current = instance
    while current and current ~= workspace do
        if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
            return true
        end
        current = current.Parent
    end
    return false
end

local function OptimizeTextures()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not IsPlayerCharacter(obj) then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        elseif (obj:IsA("Texture") or obj:IsA("Decal")) and not IsPlayerCharacter(obj) then
            obj.Transparency = 1
        end
    end

    local colorCorrection = Lighting:FindFirstChild("OptimizationColorCorrection")
    if not colorCorrection then
        colorCorrection = Instance.new("ColorCorrectionEffect")
        colorCorrection.Name = "OptimizationColorCorrection"
        colorCorrection.Parent = Lighting
    end
    colorCorrection.Saturation = 1
end

workspace.DescendantAdded:Connect(function(obj)
    if LowGraphicsEnabled then
        if obj:IsA("BasePart") and not IsPlayerCharacter(obj) then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        elseif (obj:IsA("Texture") or obj:IsA("Decal")) and not IsPlayerCharacter(obj) then
            obj.Transparency = 1
        end
    end
end)

-- FLY SYSTEM
local Character, Humanoid, HumanoidRootPart

local function StartFly(isRespawn)
    if FlyEnabled and not isRespawn then return end
    FlyEnabled = true

    if not Humanoid or not HumanoidRootPart then return end
    Humanoid.PlatformStand = true

    if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end
    if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy() end
    if flyConnection then flyConnection:Disconnect() end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = HumanoidRootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 100000
    bodyGyro.CFrame = Camera.CFrame
    bodyGyro.Parent = HumanoidRootPart

    flyConnection = RunService.RenderStepped:Connect(function()
        if not HumanoidRootPart then return end
        local camCF = Camera.CFrame
        local forward = camCF.LookVector
        local right = camCF.RightVector
        local direction = Vector3.zero

        direction += forward * moveVector.Z
        direction += right * (moveVector.X * 0.45)

        if direction.Magnitude > 0 then
            bodyVelocity.Velocity = direction.Unit * FlySpeed
        else
            bodyVelocity.Velocity = Vector3.zero
        end

        bodyGyro.CFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + Camera.CFrame.LookVector)
    end)
end

local function StopFly()
    FlyEnabled = false
    if Humanoid then Humanoid.PlatformStand = false end
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

local function SetupCharacter(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid", 5)
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 5)
    
    if FlyEnabled then
        task.wait(0.2)
        StartFly(true)
    end
end
LocalPlayer.CharacterAdded:Connect(SetupCharacter)
if LocalPlayer.Character then SetupCharacter(LocalPlayer.Character) end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then moveVector = Vector3.new(moveVector.X, 0, -1)
    elseif input.KeyCode == Enum.KeyCode.S then moveVector = Vector3.new(moveVector.X, 0, 1)
    elseif input.KeyCode == Enum.KeyCode.A then moveVector = Vector3.new(-1, 0, moveVector.Z)
    elseif input.KeyCode == Enum.KeyCode.D then moveVector = Vector3.new(1, 0, moveVector.Z) end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then moveVector = Vector3.new(moveVector.X, 0, 0)
    elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then moveVector = Vector3.new(0, 0, moveVector.Z) end
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then 
        moveVector = Vector3.zero
        return 
    end
    
    local moveDir = hum.MoveDirection
    if moveDir.Magnitude > 0 then
        local relative = Camera.CFrame:VectorToObjectSpace(moveDir)
        moveVector = Vector3.new(relative.X, 0, -relative.Z)
    else
        moveVector = Vector3.zero
    end
end)

UserInputService.JumpRequest:Connect(function()
    if InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

local function ExecutarMecanismoFling(TargetPlayer)
    if not TargetPlayer then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    
    local tChar = TargetPlayer.Character
    if not tChar then return end
    
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tHum and tHum.RootPart
    local tHead = tChar:FindFirstChild("Head")
    local acc = tChar:FindFirstChildOfClass("Accessory")
    local handle = acc and acc:FindFirstChild("Handle")
    
    if char and hum and root then
        if root.Velocity.Magnitude < 50 then
            getgenv().OldPos = root.CFrame
        end
        if tHum and tHum.Sit then return end
        
        if tHead then workspace.CurrentCamera.CameraSubject = tHead
        elseif handle then workspace.CurrentCamera.CameraSubject = handle
        elseif tHum and tRoot then workspace.CurrentCamera.CameraSubject = tHum end
        
        if not tChar:FindFirstChildWhichIsA("BasePart") then return end
        
        local animScript = char:FindFirstChild("Animate")
        if animScript then animScript.Disabled = true end
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop() end
        end
        
                local FPos = function(BasePart, Pos, Ang)
            -- Adiciona 2 studs no eixo Y (para cima) da posição do alvo
            local posicaoAcima = BasePart.Position + Vector3.new(0, 2, 0)
            
            root.CFrame = CFrame.new(posicaoAcima) * Pos * Ang
            char:SetPrimaryPartCFrame(CFrame.new(posicaoAcima) * Pos * Ang)
            
            root.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 5
            local Time = tick()
            local Angle = 0
            local distance = 10
            local speed = 200
            local progress = 0
            local movingForward = true
            
            repeat
                if root and tHum and tRoot then
                    if tRoot.AssemblyLinearVelocity.Magnitude > 150 then break end
                    Angle = (Angle + 45) % 360
                    local dt = task.wait()
                    
                    local moveDir = tHum.MoveDirection
                    local offsetCFrame = CFrame.new(0, 0, 0)
                    
                    if moveDir.Magnitude < 0.1 then
                        offsetCFrame = CFrame.new(0, 0, 0)
                    else
                        local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
                        local localDir = tRoot.CFrame:VectorToObjectSpace(flatDir)
                        
                        if movingForward then
                            progress = progress + (speed * dt)
                            if progress >= distance then
                                progress = distance
                                movingForward = false
                            end
                        else
                            progress = progress - (speed * dt)
                            if progress <= -distance then
                                progress = -distance
                                movingForward = true
                            end
                        end
                        
                        local sideOffset = math.sin(tick() * 10) * 10
                        offsetCFrame = CFrame.new(localDir * progress) * CFrame.new(sideOffset, 0, 0)
                    end
                    
                    FPos(BasePart, offsetCFrame, CFrame.Angles(math.rad(Angle), 0, 0))
                else
                    break
                end
            until Time + TimeToWait < tick() or not FlingActive
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Parent = root
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if tRoot then SFBasePart(tRoot)
        elseif tHead then SFBasePart(tHead)
        elseif handle then SFBasePart(handle) end
        
        BV:Destroy()
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = hum
        if animScript then animScript.Disabled = false end
        
        if getgenv().OldPos then
            local t = 0
            repeat
                root.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                char:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                hum:ChangeState("GettingUp")
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then part.Velocity, part.RotVelocity = Vector3.zero, Vector3.zero end
                end
                task.wait()
                t = t + 1
            until (root.Position - getgenv().OldPos.p).Magnitude < 25 or t > 10
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    end
end

RunService.RenderStepped:Connect(function()
    if FOVCircle then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = FovSize * 2.5
        FOVCircle.Visible = FovVisible
    end

    if AimbotEnabled then
        local target = GetClosestPlayerToCenter()
        if target then Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position) end
    end

    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            hum.WalkSpeed = Speed
            hum.UseJumpPower = true
            hum.JumpPower = Jump
        end
    end

    UpdateESP()

    local gun = FindDroppedGun()
    if gun and GunEspEnabled then
        local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
        if part then
            local highlight = gun:FindFirstChild("GunHighlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "GunHighlight"
                highlight.Parent = gun
            end
            highlight.FillColor = Color3.fromRGB(255, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0

            local gui = gun:FindFirstChild("GunGui")
            if not gui then
                gui = Instance.new("BillboardGui")
                gui.Name = "GunGui"
                gui.Adornee = part
                gui.Size = UDim2.new(0, 100, 0, 30)
                gui.StudsOffset = Vector3.new(0, 2, 0)
                gui.AlwaysOnTop = true
                gui.Parent = gun

                local label = Instance.new("TextLabel")
                label.Name = "GunLabel"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = "GUN"
                label.TextColor3 = Color3.fromRGB(255, 255, 0)
                label.TextSize = 14
                label.Font = Enum.Font.SourceSansBold
                label.TextStrokeTransparency = 0
                label.Parent = gui
            end
        end
    end
end)

---------------------------------------------------------------------------
-- [ TABS E INTERFACES ]
---------------------------------------------------------------------------
CombatTab:Toggle({
    Title = "Aimbot", 
    Default = false, 
    Callback = function(v) 
        AimbotEnabled = v 
    end
})

CombatTab:Toggle({
    Title = "Mostrar FOV", 
    Default = false, 
    Callback = function(v) 
        FovVisible = v 
    end
})

CombatTab:Slider({
    Title = "FOV", 
    Min = 50, 
    Max = 500, 
    Default = 100, 
    Step = 1, 
    Callback = function(v) 
        FovSize = v 
    end
})

CombatTab:Toggle({
    Title = "Anti Fling", 
    Default = false, 
    Callback = function(v) 
        AntiFlingEnabled = v 
    end
})

CombatTab:Toggle({
    Title = "Knife aura", 
    Default = false, 
    Callback = function(v)
        KillAuraEnabled = v
    end
})

CombatTab:Toggle({
    Title = "Throw Knife Button", 
    Default = false, 
    Callback = function(v) 
        ToggleThrowButtonGui(v) 
    end
})

CombatTab:Toggle({
    Title = "Shoot button", 
    Default = false, 
    Callback = function(v) 
        ToggleShootButtonGui(v) 
    end
})

FlingTab:Button({
    Title = "Fling murderer",
    Callback = function()
        if FlingActive then return end
        local target = GetPlayerByRole("Murderer")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            FlingActive = true
            task.spawn(function() ExecutarMecanismoFling(target); FlingActive = false end)
        end
    end
})

FlingTab:Button({
    Title = "Fling sherife",
    Callback = function()
        if FlingActive then return end
        local target = GetPlayerByRole("Sheriff")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            FlingActive = true
            task.spawn(function() ExecutarMecanismoFling(target); FlingActive = false end)
        end
    end
})

local FlingDropdown = FlingTab:Dropdown({
    Title = "Lista de Jogadores",
    Values = GetPlayerNamesList(),
    Value = "",
    Callback = function(v) SelectedPlayerToFling = v end
})

FlingTab:Button({
    Title = "Fling player",
    Callback = function()
        if FlingActive then return end
        if SelectedPlayerToFling ~= "" then
            local target = Players:FindFirstChild(SelectedPlayerToFling)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                FlingActive = true
                task.spawn(function() ExecutarMecanismoFling(target); FlingActive = false end)
            end
        end
    end
})

-- ADICIONE O BOTÃO DE ATUALIZAR AQUI:
FlingTab:Button({
    Title = "Atualizar Lista", 
    Callback = function() 
        AtualizarTodasAsListas() 
    end
})

local function AtualizarTodasAsListas()
    local novaLista = GetPlayerNamesList()
    FlingDropdown:Refresh(novaLista)
    if PlayerDropdown then PlayerDropdown:Refresh(novaLista) end
end

-- Mantém apenas a limpeza das variáveis se o jogador escolhido sair do jogo, 
-- mas NÃO atualiza o Dropdown sozinho.
Players.PlayerRemoving:Connect(function(p)
    if SelectedPlayerToFling == p.Name then SelectedPlayerToFling = "" end
    if SelectedPlayerToTp == p.Name then SelectedPlayerToTp = "" end
end)

EspTab:Toggle({Title = "ESP Jogadores", Default = false, Callback = function(v) EspEnabled = v end})
EspTab:Toggle({Title = "ESP Arma", Default = false, Callback = function(v) GunEspEnabled = v end})

TeleportTab:Button({
    Title = "TP Murderer",
    Callback = function()
        local target = GetPlayerByRole("Murderer")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0))
        end
    end
})

TeleportTab:Button({
    Title = "TP Sheriff",
    Callback = function()
        local target = GetPlayerByRole("Sheriff")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0))
        end
    end
})

PlayerDropdown = TeleportTab:Dropdown({
    Title = "Escolher Jogador",
    Values = GetPlayerNamesList(),
    Value = "",
    Callback = function(v) SelectedPlayerToTp = v end
})

TeleportTab:Button({
    Title = "TP Jogador",
    Callback = function()
        if SelectedPlayerToTp ~= "" then
            local target = Players:FindFirstChild(SelectedPlayerToTp)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0))
            end
        end
    end
})

TeleportTab:Button({Title = "Atualizar Lista", Callback = function() AtualizarTodasAsListas() end})
TeleportTab:Button({Title = "TP Área Segura", Callback = function() TeleportToSafeArea() end})
-- Função necessária para o teleporte funcionar
local function TeleportToCFrame(targetCFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetCFrame.Position)
    end
end

-- Botão TP Lobby (Teleporta para a posição exata solicitada)
TeleportTab:Button({
    Title = "TP Lobby",
    Callback = function()
        TeleportToCFrame(CFrame.new(14, 504, -4))
    end
})

TeleportTab:Button({
    Title = "TP Arena de Jogo",
    Callback = function()
        local lobbyPos = Vector3.new(14, 504, -12)
        local validSpawns = {}
        
        -- 1. Varre o workspace procurando por modelos de mapas válidos
        for _, obj in ipairs(workspace:GetChildren()) do
            -- Ignora tudo que for jogador ou lobby
            if obj:IsA("Model") and obj.Name ~= "Lobby" and obj.Name ~= "LobbyWorkspace" and obj.Name ~= "SafeArea" and not Players:GetPlayerFromCharacter(obj) then
                
                -- Procura estritamente pela pasta de Spawns da arena do MM2
                local spawnsFolder = obj:FindFirstChild("Spawns")
                if spawnsFolder then
                    for _, spawnPart in ipairs(spawnsFolder:GetChildren()) do
                        if spawnPart:IsA("BasePart") then
                            -- Verifica se o spawn está longe do lobby para confirmar que é o mapa do jogo
                            if (spawnPart.Position - lobbyPos).Magnitude >= 500 then
                                table.insert(validSpawns, spawnPart)
                            end
                        end
                    end
                end
            end
        end

        -- 2. Sistema de backup caso o mapa esteja dentro da pasta "NormalMaps"
        if #validSpawns == 0 then
            local normalMaps = workspace:FindFirstChild("NormalMaps")
            if normalMaps then
                for _, map in ipairs(normalMaps:GetChildren()) do
                    local spawnsFolder = map:FindFirstChild("Spawns")
                    if spawnsFolder then
                        for _, spawnPart in ipairs(spawnsFolder:GetChildren()) do
                            if spawnPart:IsA("BasePart") then
                                if (spawnPart.Position - lobbyPos).Magnitude >= 500 then
                                    table.insert(validSpawns, spawnPart)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- 3. Teleporta para um dos spawns válidos encontrados
        if #validSpawns > 0 then 
            local randomSpawn = validSpawns[math.random(1, #validSpawns)]
            -- O "+ CFrame.new(0, 5, 0)" garante que você caia em cima do bloco, e não dentro do chão
            TeleportToCFrame(randomSpawn.CFrame * CFrame.new(0, 5, 0)) 
        else
            -- Se imprimir isso no F9, significa que a partida ainda não começou ou o mapa ainda não carregou
            print("Nenhum spawn de arena encontrado! A partida já começou?")
        end
    end
})

TeleportTab:Button({
    Title = "TP Arma Dropada",
    Callback = function()
        local gun = FindDroppedGun()
        if gun then
            local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
            if part then TeleportToCFrame(part.CFrame) end
        end
    end
})

FarmTab:Toggle({
    Title = "Auto collect Coin",
    Default = false,
    Callback = function(v)
        AutoCoinEnabled = v
        if not v then
            if currentCoinTween then
                currentCoinTween:Cancel()
                currentCoinTween = nil
            end
            Coletadas = {} 
        end
    end
})

FarmTab:Toggle({
    Title = "Auto TP Área Segura",
    Default = false,
    Callback = function(v)
        AutoSafeEnabled = v
        if v then
            task.spawn(function()
                while AutoSafeEnabled do
                    task.wait(0)
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then TeleportToSafeArea() end
                end
            end)
        end
    end
})

FarmTab:Toggle({
    Title = "Auto Get Gun",
    Default = false,
    Callback = function(v)
        AutoCollectGunEnabled = v
        task.spawn(function()
            while AutoCollectGunEnabled do
                local myRole = GetPlayerRole(LocalPlayer)
                local isAliveAndParticipating = IsParticipatingAndAlive(LocalPlayer)
                
                if myRole == "Innocent" and isAliveAndParticipating then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local gun = FindDroppedGun()
                    
                    if hrp and gun then
                        local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
                        if part then
                            -- Salva a posição original
                            local posicaoOriginalArma = part.CFrame
                            
                            -- Puxa a arma para o jogador
                            part.CFrame = hrp.CFrame
                            
                            -- Espera 0.05 segundos (fração rápida)
                            task.wait(0.05)
                            
                            -- Verifica se a arma ainda existe e devolve ela
                            if part then 
                                part.CFrame = posicaoOriginalArma 
                            end
                            
                            -- Tempo de recarga: espera 5 segundos para puxar de novo
                            task.wait(5)
                        end
                    end
                end
                -- Evita o travamento do jogo se as condições não forem atingidas
                task.wait()
            end
        end)
    end
})

-- Variável de controle do Lock Trade
local LockTradeEnabled = false

FarmTab:Toggle({
    Title = "Lock Trade",
    Default = false,
    Callback = function(v)
        LockTradeEnabled = v
        local rs = game:GetService("ReplicatedStorage")
        
        if v then
            -- Inicia um loop para manter as trocas trancadas enquanto estiver ativado
            task.spawn(function()
                while LockTradeEnabled do
                    pcall(function()
                        -- Desativa os pedidos de troca
                        rs.Trade.SetRequestsEnabled:FireServer(false)
                        -- Recusa instantaneamente qualquer troca pendente
                        rs.Trade.DeclineRequest:FireServer()
                    end)
                    task.wait(1) -- Checa a cada 1 segundo
                end
            end)
        else
            -- Quando desativar o toggle, ele libera as trocas de novo
            pcall(function()
                rs.Trade.SetRequestsEnabled:FireServer(true)
            end)
        end
    end
})

FarmTab:Toggle({
    Title = "Auto prestígio",
    Default = false,
    Callback = function(v)
        AutoPrestigeEnabled = v
        if v then
            task.spawn(function()
                while AutoPrestigeEnabled do
                    pcall(function()
                        local isLevel100 = false
                        local dataLevel = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level")
                        local leaderstatsLevel = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Level")
                        
                        if dataLevel and tonumber(dataLevel.Value) >= 100 then
                            isLevel100 = true
                        elseif leaderstatsLevel and tonumber(leaderstatsLevel.Value) >= 100 then
                            isLevel100 = true
                        end
                        
                        if not dataLevel and not leaderstatsLevel then
                            isLevel100 = true 
                        end
                        
                        if isLevel100 then
                            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                                if obj.Name == "Prestige" and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                                    if obj:IsA("RemoteEvent") then
                                        obj:FireServer()
                                    elseif obj:IsA("RemoteFunction") then
                                        obj:InvokeServer()
                                    end
                                    break
                                end
                            end
                        end
                    end)
                    task.wait(2)
                end
            end)
        end
    end
})

PlayerTab:Input({
    Title = "Velocidade",
    Placeholder = "16",
    Callback = function(text)
        local num = tonumber(text)
        if num then Speed = num end  
    end
})

PlayerTab:Input({
    Title = "Pulo",
    Placeholder = "50",
    Callback = function(text)
        local num = tonumber(text)
        if num then Jump = num end  
    end
})

PlayerTab:Toggle({Title = "Pulo Infinito", Default = false, Callback = function(v) InfiniteJump = v end})
PlayerTab:Toggle({Title = "NoClip", Default = false, Callback = function(v) NoclipEnabled = v end})
PlayerTab:Toggle({Title = "Fly", Default = false, Callback = function(v) if v then StartFly() else StopFly() end end})
PlayerTab:Slider({Title = "Fly Speed", Step = 5, Value = {Min = 10, Max = 200, Default = 30}, Callback = function(v) FlySpeed = v end})

PerformanceTab:Toggle({
    Title = "Modo Leve",
    Default = false,
    Callback = function(v)
        LowGraphicsEnabled = v
        if v then OptimizeTextures() end
    end
}) 

-- ==========================================
-- GHOST MODE (INVISIBILIDADE) - DESEMPENHO TAB
-- ==========================================
local GhostModeActive = false
local GhostLoopConnection = nil
local GhostCameraConnection = nil
local GhostCharAddedConnection = nil
local GhostClone = nil
local GhostSkyFolder = nil
local GhostClonedParts = {}
local GhostOffset = Vector3.new()

local function prepareGhostClone(model)
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 1
            v.CanCollide = false
            v.Anchored = true
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
            v.Enabled = false
        elseif v:IsA("Script") or v:IsA("LocalScript") then
            v:Destroy()
        end
    end
end

PerformanceTab:Toggle({
    Title = "Ghost Mode",
    Default = false,
    Callback = function(v)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end

        GhostModeActive = v

        if GhostModeActive then
            -- [ ATIVAR INVISIBILIDADE ]
            local hrp = char.HumanoidRootPart
            local originalPos = hrp.Position
            local targetPos = Vector3.new(0, 100000, 0)
            
            GhostOffset = targetPos - originalPos

            -- 1. Cria o Clone
            char.Archivable = true
            GhostClone = char:Clone()
            
            local cloneHRP = GhostClone:FindFirstChild("HumanoidRootPart")
            if cloneHRP then
                GhostClone.PrimaryPart = cloneHRP
            end

            prepareGhostClone(GhostClone)
            GhostClone.Parent = workspace
            
            -- 2. Cria a pasta dos blocos clonados no céu
            GhostSkyFolder = Instance.new("Folder")
            GhostSkyFolder.Name = "SkyCollisionMap"
            GhostSkyFolder.Parent = workspace

            -- 3. Teleporta o Personagem Real para o céu
            hrp.CFrame = hrp.CFrame + GhostOffset
            
            -- 4. Trava a Câmera no Clone
            local cloneHumanoid = GhostClone:FindFirstChildOfClass("Humanoid")
            if cloneHumanoid then
                workspace.CurrentCamera.CameraSubject = cloneHumanoid
            end

            -- Monitora alterações na câmera
            GhostCameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
                if GhostModeActive and GhostClone and GhostClone:FindFirstChildOfClass("Humanoid") then
                    local targetSubject = GhostClone:FindFirstChildOfClass("Humanoid")
                    if workspace.CurrentCamera.CameraSubject ~= targetSubject then
                        workspace.CurrentCamera.CameraSubject = targetSubject
                    end
                end
            end)

            -- Se renascer enquanto ativo
            GhostCharAddedConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
                if GhostModeActive then
                    task.wait(0.2)
                    local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)
                    if newHRP then
                        newHRP.CFrame = newHRP.CFrame + GhostOffset
                    end
                end
            end)

            local overlapParams = OverlapParams.new()
            overlapParams.FilterType = Enum.RaycastFilterType.Exclude
            overlapParams.FilterDescendantsInstances = {char, GhostClone, GhostSkyFolder}

            -- 5. Loop principal (RenderStepped)
            GhostLoopConnection = RunService.RenderStepped:Connect(function()
                local currentChar = LocalPlayer.Character
                if not GhostClone or not GhostClone.PrimaryPart or not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
                
                local realHRP = currentChar.HumanoidRootPart

                -- INTERCEPTA TELEPORTES DO JOGO:
                if realHRP.Position.Y < 50000 then
                    realHRP.CFrame = realHRP.CFrame + GhostOffset
                end
                
                -- Sincroniza o Clone na posição real no chão
                GhostClone:PivotTo(realHRP.CFrame - GhostOffset)

                -- Scan de 20 studs do clone
                local groundPos = realHRP.Position - GhostOffset
                local partsNear = workspace:GetPartBoundsInRadius(groundPos, 20, overlapParams)
                local neededParts = {}

                for _, part in ipairs(partsNear) do
                    if part.CanCollide then
                        neededParts[part] = true
                        
                        local proxy = GhostClonedParts[part]
                        if not proxy then
                            local oldArch = part.Archivable
                            part.Archivable = true
                            proxy = part:Clone()
                            part.Archivable = oldArch

                            if proxy then
                                proxy:ClearAllChildren()
                                proxy.CFrame = part.CFrame + GhostOffset
                                proxy.Anchored = true
                                proxy.CanCollide = true
                                proxy.Transparency = 1
                                proxy.Parent = GhostSkyFolder
                                GhostClonedParts[part] = proxy
                            end
                        else
                            if proxy.CFrame ~= part.CFrame + GhostOffset then
                                proxy.CFrame = part.CFrame + GhostOffset
                            end
                        end
                    end
                end

                -- Limpeza de blocos distantes
                for origPart, proxyPart in pairs(GhostClonedParts) do
                    if not neededParts[origPart] then
                        proxyPart:Destroy()
                        GhostClonedParts[origPart] = nil
                    end
                end
            end)

        else
            -- [ DESATIVAR INVISIBILIDADE ]
            if GhostLoopConnection then 
                GhostLoopConnection:Disconnect() 
                GhostLoopConnection = nil
            end
            if GhostCameraConnection then
                GhostCameraConnection:Disconnect()
                GhostCameraConnection = nil
            end
            if GhostCharAddedConnection then
                GhostCharAddedConnection:Disconnect()
                GhostCharAddedConnection = nil
            end
            
            local currentChar = LocalPlayer.Character
            if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
                currentChar.HumanoidRootPart.CFrame = currentChar.HumanoidRootPart.CFrame - GhostOffset
                local realHumanoid = currentChar:FindFirstChildOfClass("Humanoid")
                if realHumanoid then
                    workspace.CurrentCamera.CameraSubject = realHumanoid
                end
            end

            if GhostClone then GhostClone:Destroy() end
            if GhostSkyFolder then GhostSkyFolder:Destroy() end
            table.clear(GhostClonedParts)
        end
    end
})

