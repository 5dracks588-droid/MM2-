local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

--// Window
local Window = WindUI:CreateWindow({
    Title = "Murder Mystery 2",
    Icon = "crown",
    Author = "THE RED",
    Folder = "MM2WindUI",
    Size = UDim2.fromOffset(580,430),
    Transparent = true,
    Theme = "Crimson",
    SideBarWidth = 200,
    MinimizeKey = Enum.KeyCode.RightControl
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "crown",
    CornerRadius = UDim.new(0.5, 0),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("8B0000"),
        Color3.fromHex("FFFFFF")
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

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variáveis de Role
local roles = {}
local Murder, Sheriff

-- Variáveis Gerais
local AimbotEnabled = false
local FovVisible = false
local FovSize = 100
local AutoCoinEnabled = false
local AutoCoinSpeed = 30
local StopDuration = 0.25
local AutoSafeEnabled = false
local KnifeAuraEnabled = false
local KnifeAuraDistance = 3
local SavedPositions = {}

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

-- FOV Seguro
local FOVCircle = nil
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Color = Color3.fromRGB(139,0,0)
    FOVCircle.Thickness = 2
    FOVCircle.Transparency = 1
    FOVCircle.Filled = false
    FOVCircle.Visible = false
end)

local Coletadas = {}
LocalPlayer.CharacterAdded:Connect(function()
    Coletadas = {}
end)

WindUI:SetTheme("Crimson")

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
                        -- Se houver Hero cadastrado pelo jogo, vira Sheriff se o original morreu
                        tempSheriff = name
                    end
                end

                -- Lógica: Se o Sheriff original morreu/foi eliminado, ele vira Inocente e quem pegar a arma vira Sheriff
                if sheriffDeadOrKilled then
                    tempSheriff = nil
                end

                -- Checa se há alguém com a arma equipada caso o Sheriff tenha morrido
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
end)

---------------------------------------------------------------------------
-- [ AUTO COIN COM TWEEN SPEED E PARADA SE NENHUMA MOEDA FOR ENCONTRADA ]
---------------------------------------------------------------------------
local function GetClosestCoin()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local menorDistancia = math.huge
    local moedaAlvo = nil

    local areaDeBusca = workspace:FindFirstChild("NormalMaps") or workspace:FindFirstChild("Map") or workspace

    for _, obj in ipairs(areaDeBusca:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent and not Coletadas[obj] and obj.Transparency < 1 and obj.CanCollide == false then
            local nome = string.lower(obj.Name)
            if nome:find("coin") or nome:find("gold") or nome:find("token") then
                if obj.Size.X <= 6 and obj.Size.Y <= 6 and obj.Size.Z <= 6 then
                    local model = obj:FindFirstAncestorOfClass("Model")
                    if model and not model:FindFirstChild("Lobby") then
                        local dist = (hrp.Position - obj.Position).Magnitude
                        if dist < menorDistancia then
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
        task.wait(0.1)
        while AutoCoinEnabled do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 and IsParticipatingAndAlive(LocalPlayer) then
                local alvo = GetClosestCoin()
                
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

                    local ultimoScan = 0

                    while AutoCoinEnabled do
                        if not alvo or not alvo.Parent or Coletadas[alvo] or (tick() - ultimoScan > 0.5) then
                            alvo = GetClosestCoin()
                            ultimoScan = tick()
                        end
                        
                        -- Se não perceber nenhuma moeda no mapa, a função para até encontrar moeda de novo
                        if not alvo then 
                            break 
                        end

                        local spawnDestino = alvo.Position
                        if alvo.Parent and alvo.Parent:IsA("Model") and alvo.Parent.PrimaryPart then
                            spawnDestino = alvo.Parent.PrimaryPart.Position
                        elseif alvo.Name == "Coin_Sub" and alvo.Parent and alvo.Parent:FindFirstChild("Coin") then
                            spawnDestino = alvo.Parent.Coin.Position
                        end
                        
                        local destinoFinal = Vector3.new(spawnDestino.X, spawnDestino.Y + 1.2, spawnDestino.Z)
                        local atualPos = hrp.Position
                        local distancia = (atualPos - destinoFinal).Magnitude
                        
                        if distancia <= 0.8 then 
                            if currentCoinTween then
                                currentCoinTween:Cancel()
                                currentCoinTween = nil
                            end
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            
                            Coletadas[alvo] = true
                            alvo = nil 
                            
                            task.wait(0.2)
                        else
                            local tempoViagem = math.max(0.05, distancia / AutoCoinSpeed)
                            
                            if currentCoinTween then
                                currentCoinTween:Cancel()
                            end
                            
                            local tweenInfo = TweenInfo.new(tempoViagem, Enum.EasingStyle.Linear)
                            currentCoinTween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(destinoFinal)})
                            currentCoinTween:Play()
                            
                            local tempoEsperado = tick() + tempoViagem
                            while AutoCoinEnabled and currentCoinTween and currentCoinTween.PlaybackState == Enum.PlaybackState.Playing and tick() < tempoEsperado do
                                RunService.Heartbeat:Wait()
                                if not alvo or not alvo.Parent or Coletadas[alvo] then break end
                            end
                        end
                        
                        RunService.Heartbeat:Wait()
                    end

                    if currentCoinTween then
                        currentCoinTween:Cancel()
                        currentCoinTween = nil
                    end
                    hrp.AssemblyLinearVelocity = Vector3.zero

                    if noclipConnection then noclipConnection:Disconnect() end
                    if bv then bv:Destroy() end

                    if not AutoCoinEnabled then break end
                    task.wait(StopDuration)
                else
                    -- Aguarda e checa novamente se há moedas disponíveis
                    task.wait(1)
                end
            else
                task.wait(0.5)
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
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
            root.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            char:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
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
        FOVCircle.Radius = FovSize
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

    if KnifeAuraEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHRP = LocalPlayer.Character.HumanoidRootPart
        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                local targetHRP = plr.Character.HumanoidRootPart
                if (targetHRP.Position - SafePart.Position).Magnitude > 50 then
                    if not SavedPositions[plr] then SavedPositions[plr] = targetHRP.CFrame end
                    targetHRP.CFrame = CFrame.new(myHRP.Position + (myHRP.CFrame.LookVector * KnifeAuraDistance))
                    targetHRP.AssemblyLinearVelocity = Vector3.zero
                    targetHRP.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    else
        for plr, savedCFrame in pairs(SavedPositions) do
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.CFrame = savedCFrame
                plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                plr.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end
        SavedPositions = {}
    end
end)

---------------------------------------------------------------------------
-- [ TABS E INTERFACES ]
---------------------------------------------------------------------------
CombatTab:Toggle({Title = "Aimbot", Default = false, Callback = function(v) AimbotEnabled = v end})
CombatTab:Toggle({Title = "Mostrar FOV", Default = false, Callback = function(v) FovVisible = v end})
CombatTab:Slider({Title = "FOV", Step = 1, Value = { Min = 50, Max = 500, Default = 100 }, Callback = function(v) FovSize = v end})
CombatTab:Toggle({Title = "Anti Fling", Default = false, Callback = function(v) AntiFlingEnabled = v end})
CombatTab:Toggle({Title = "Knife Aura", Default = false, Callback = function(v) KnifeAuraEnabled = v end})
CombatTab:Slider({Title = "Distância Aura", Step = 1, Value = {Min = 0, Max = 10, Default = 3}, Callback = function(v) KnifeAuraDistance = v end})

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

local function AtualizarTodasAsListas()
    local novaLista = GetPlayerNamesList()
    FlingDropdown:Refresh(novaLista)
    if PlayerDropdown then PlayerDropdown:Refresh(novaLista) end
end

Players.PlayerAdded:Connect(function() task.wait(0.5); AtualizarTodasAsListas() end)
Players.PlayerRemoving:Connect(function(p)
    if SelectedPlayerToFling == p.Name then SelectedPlayerToFling = "" end
    if SelectedPlayerToTp == p.Name then SelectedPlayerToTp = "" end
    task.wait(0.1)
    AtualizarTodasAsListas()
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
TeleportTab:Button({
    Title = "TP Lobby",
    Callback = function()
        local lobby = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("LobbyWorkspace")
        if lobby then
            local spawnLocation = lobby:FindFirstChildWhichIsA("SpawnLocation", true)
            if spawnLocation then TeleportToCFrame(spawnLocation.CFrame * CFrame.new(0, 5, 0)); return end
        end
        TeleportToCFrame(CFrame.new(-108, 145, 12))
    end
})

TeleportTab:Button({
    Title = "TP Arena de Jogo",
    Callback = function()
        local foundSpawn = nil
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name ~= "Lobby" and obj.Name ~= "LobbyWorkspace" and obj.Name ~= "Camera" and obj.Name ~= "Terrain" then
                local spawns = obj:FindFirstChild("Spawns") or obj:FindFirstChild("PlayerSpawns") or obj:FindFirstChild("SpawnLocations")
                if spawns and #spawns:GetChildren() > 0 then
                    local spawnList = spawns:GetChildren()
                    local randomSpawn = spawnList[math.random(1, #spawnList)]
                    if randomSpawn:IsA("BasePart") then
                        foundSpawn = randomSpawn.CFrame
                        break
                    end
                end
            end
        end
        if not foundSpawn then
            local activeMapFolder = workspace:FindFirstChild("NormalMaps") or workspace:FindFirstChild("Map")
            if activeMapFolder then
                for _, mapModel in ipairs(activeMapFolder:GetChildren()) do
                    if mapModel.Name ~= "Lobby" then
                        local spawns = mapModel:FindFirstChild("Spawns") or mapModel:FindFirstChild("PlayerSpawns")
                        if spawns and #spawns:GetChildren() > 0 then
                            local spawnList = spawns:GetChildren()
                            local randomSpawn = spawnList[math.random(1, #spawnList)]
                            if randomSpawn:IsA("BasePart") then
                                foundSpawn = randomSpawn.CFrame
                                break
                            end
                        end
                    end
                end
            end
        end
        if foundSpawn then TeleportToCFrame(foundSpawn + Vector3.new(0, 3, 0)) end
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
                -- Só funciona se eu for inocente, estiver participando da partida e não tiver morrido nela
                local myRole = GetPlayerRole(LocalPlayer)
                local isAliveAndParticipating = IsParticipatingAndAlive(LocalPlayer)
                
                if myRole == "Innocent" and isAliveAndParticipating then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local gun = FindDroppedGun()
                    
                    if hrp and gun then
                        local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local posicaoOriginalArma = part.CFrame
                            part.CFrame = hrp.CFrame
                            task.wait()
                            if part then part.CFrame = posicaoOriginalArma end
                        end
                    end
                end
                task.wait()
            end
        end)
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

