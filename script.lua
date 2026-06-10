-- WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Window
local Window = WindUI:CreateWindow({
Title = "Murder Mystery 2",
Icon = "zap",
Author = "zxred",
Folder = "MM2WindUI",
Size = UDim2.fromOffset(580,430),
Transparent = true,
Theme = "Dark",
SideBarWidth = 200,
MinimizeKey = Enum.KeyCode.RightControl
})

-- AGORA VAI: Chamando a função direto da sua Window criada
Window:EditOpenButton({
Title = "Open Menu",
Icon = "zap",
CornerRadius = UDim.new(0, 16),
StrokeThickness = 2,
Color = ColorSequence.new(
Color3.fromHex("000000"), -- Preto
Color3.fromHex("000000")  -- Preto
),
OnlyMobile = false,
Enabled = true,
Draggable = true,
})

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variáveis
local AimbotEnabled = false
local FovVisible = false
local FovSize = 100
local TargetType = "Murderer"
local AutoCoinEnabled = false
local SelectedTheme = "Dark"
local AutoSafeEnabled = false
local safeTpCount = 0
local KnifeAuraEnabled = false
local KnifeAuraDistance = 5
local SavedPositions = {}

local EspEnabled = false
local GunEspEnabled = false
local AntiFlingEnabled = false
local LowGraphicsEnabled = false

local Speed = 16
local Jump = 50

local InfiniteJump = false
local NoclipEnabled = false

local FlyEnabled = false
local FlySpeed = 70

local bodyVelocity
local bodyGyro
local flyConnection
local moveVector = Vector3.zero

local SelectedPlayerToTp = ""

-- FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0,0,0)
FOVCircle.Thickness = 2
FOVCircle.Transparency = 1
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Tabs
local InfoTab = Window:Tab({
Title = "Info",
Icon = "house"
})

local CombatTab = Window:Tab({
Title = "Combate",
Icon = "sword"
})

local EspTab = Window:Tab({
Title = "ESP",
Icon = "eye"
})

local TeleportTab = Window:Tab({
Title = "Teleportes",
Icon = "map-pinned"
})

local FarmTab = Window:Tab({
Title = "Farm",
Icon = "coins"
})

local PlayerTab = Window:Tab({
Title = "Player",
Icon = "user"
})

local PerformanceTab = Window:Tab({
Title = "Desempenho",
Icon = "cpu"
})

WindUI:SetTheme("Dark")

-- SERVIÇOS
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- VARIÁVEIS
local AutoCoinEnabled = false
local AutoCoinSpeed = 5
local CurrentTheme = "Dark"

-- LABELS
local PingParagraph = InfoTab:Paragraph({
Title = "Ping",
Desc = "0 ms"
})

local FPSParagraph = InfoTab:Paragraph({
Title = "FPS",
Desc = "0 FPS"
})

local ServerParagraph = InfoTab:Paragraph({
Title = "Servidor",
Desc = "0/0"
})

-- FPS
local FPS = 0
local Last = tick()

RunService.RenderStepped:Connect(function()
FPS += 1

if tick() - Last >= 1 then

local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())

PingParagraph:SetDesc(ping .. " ms")

FPSParagraph:SetDesc(FPS .. " FPS")

ServerParagraph:SetDesc(
#Players:GetPlayers() .. "/" .. Players.MaxPlayers
)

FPS = 0
Last = tick()

end
end)

-- ROLE
local function GetPlayerRole(player)
if not player then return "Innocent" end

if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("Role") then
return player.PlayerData.Role.Value
end

local backpack = player:FindFirstChild("Backpack")
local char = player.Character

if (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
return "Murderer"
end

if (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
return "Sheriff"
end

return "Innocent"

end

-- PLAYER ROLE
local function GetPlayerByRole(roleName)
for _,p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer and GetPlayerRole(p) == roleName then
return p
end
end
return nil
end

-- TELEPORT
local function TeleportToCFrame(targetCFrame)
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetCFrame.Position)
end
end

-- PLAYER LIST
local function GetPlayerNamesList()
local list = {}
for _,p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
table.insert(list,p.Name)
end
end
return list
end

-- SAFE AREA
local SafePart = Instance.new("Part")
SafePart.Name = "SafeArea"
SafePart.Size = Vector3.new(20,1,20)
SafePart.Position = Vector3.new(10000,500,10000)

SafePart.Anchored = true
SafePart.CanCollide = true

-- COR VERDE
SafePart.Color = Color3.fromRGB(0,255,0)

-- REMOVE TEXTURA QUADRICULADA
SafePart.Material = Enum.Material.Neon

-- TRANSPARÊNCIA
SafePart.Transparency = 0

SafePart.Parent = workspace

local function TeleportToSafeArea()
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = SafePart.CFrame + Vector3.new(0,3,0)
end
end

-- GUN
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

-- COINS
local function GetClosestCoin()
    local closestCoin = nil
    local shortestDistance = math.huge

    if not LocalPlayer.Character
    or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local hrp = LocalPlayer.Character.HumanoidRootPart

    for _, obj in ipairs(workspace:GetDescendants()) do

        if obj:IsA("BasePart")
        and obj.Parent
        and obj.Transparency < 1
        and obj.CanCollide == false then

            local name = string.lower(obj.Name)

            if name:find("coin")
            or name:find("gold")
            or name:find("token") then

                -- evita peças grandes do mapa
                if obj.Size.X <= 6 and obj.Size.Y <= 6 and obj.Size.Z <= 6 then

                    -- evita coisas no lobby/spawn
                    local model = obj:FindFirstAncestorOfClass("Model")
                    if model and not model:FindFirstChild("Lobby") then

                        local distance = (hrp.Position - obj.Position).Magnitude

                        if distance > 0 and distance < shortestDistance then
                            shortestDistance = distance
                            closestCoin = obj
                        end

                    end
                end
            end
        end
    end

    return closestCoin
end

-- NOCLIP
local NoclipEnabled = false

RunService.Stepped:Connect(function()
if NoclipEnabled and LocalPlayer.Character then
for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end
end)

-- FLUTUAR ATÉ A COIN
local function FlyToPosition(target, speed)

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not target then return end

    NoclipEnabled = true

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    while AutoCoinEnabled do

        -- verifica se a coin ainda existe
        if not target
        or not target.Parent
        or target.Transparency >= 1 then
            break
        end

        local position = target.Position + Vector3.new(0, 2, 0)

        local distance = (hrp.Position - position).Magnitude

        -- chegou na coin
        if distance <= 2 then
            break
        end

        local direction = (position - hrp.Position).Unit

        bv.Velocity = direction * math.clamp(distance * 5, 5, speed)

        task.wait(0.03)
    end

    bv:Destroy()

    NoclipEnabled = false
end

-- AIMBOT
local function GetClosestPlayerToCenter()

local closestPlayer = nil
local shortestDistance = FovSize

local screenCenter = Vector2.new(
Camera.ViewportSize.X / 2,
Camera.ViewportSize.Y / 2
)

-- sua role
local myRole = GetPlayerRole(LocalPlayer)

for _,p in pairs(Players:GetPlayers()) do

if p ~= LocalPlayer
and p.Character
and p.Character:FindFirstChild("Head")
and p.Character:FindFirstChild("Humanoid")
and p.Character.Humanoid.Health > 0 then

local role = GetPlayerRole(p)

local canTarget = false

-- se você for murderer -> mira em TODOS
if myRole == "Murderer" then
canTarget = true
else
-- inocente/sheriff -> mira só no murderer
if role == "Murderer" then
canTarget = true
end
end

if canTarget then

local pos,onScreen = Camera:WorldToViewportPoint(
p.Character.Head.Position
)

if onScreen then

local distance = (
Vector2.new(pos.X,pos.Y) - screenCenter
).Magnitude

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

-- ESP
local function UpdateESP()
for _,p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character then
local char = p.Character

if EspEnabled and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
local role = GetPlayerRole(p)
local color = Color3.fromRGB(0,255,0)

if role == "Murderer" then
color = Color3.fromRGB(255,0,0)
elseif role == "Sheriff" then
color = Color3.fromRGB(0,0,255)
end

-- Highlight
local highlight = char:FindFirstChild("ESPHighlight")
if not highlight then
highlight = Instance.new("Highlight")
highlight.Name = "ESPHighlight"
highlight.Parent = char
end
highlight.FillColor = color
highlight.OutlineColor = color
highlight.FillTransparency = 0.5
highlight.OutlineTransparency = 1

-- Billboard
local gui = char:FindFirstChild("ESPGui")
if not gui then
gui = Instance.new("BillboardGui")
gui.Name = "ESPGui"
gui.Size = UDim2.new(0,200,0,60)
gui.AlwaysOnTop = true
gui.ExtentsOffset = Vector3.new(0,3,0)
gui.Parent = char
end
gui.Adornee = char.Head

local label = gui:FindFirstChild("TextLabel")
if not label then
label = Instance.new("TextLabel")
label.Size = UDim2.new(1,0,1,0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.SourceSansBold
label.TextSize = 14
label.Parent = gui
end
label.TextColor3 = color

local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude)
label.Text = p.Name .. "\n" .. role .. "\n" .. distance .. " m"

else
if char:FindFirstChild("ESPHighlight") then char.ESPHighlight:Destroy() end
if char:FindFirstChild("ESPGui") then char.ESPGui:Destroy() end
end

end

end

end

-- FPS BOOSTER
local function CleanObject(obj)
if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
obj.Material = Enum.Material.SmoothPlastic
obj.Reflectance = 0
elseif obj:IsA("Texture") or obj:IsA("Decal") then
obj:Destroy()
elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
obj.Enabled = false
elseif obj:IsA("Atmosphere") or obj:IsA("Sky") then
obj:Destroy()
end
end

local function OptimizeTextures()
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

for _,obj in ipairs(workspace:GetDescendants()) do
CleanObject(obj)
end

end

workspace.DescendantAdded:Connect(function(descendant)
if LowGraphicsEnabled then
task.wait(0.1)
if descendant and descendant.Parent then
CleanObject(descendant)
end
end
end)

-- FLY
local FlyEnabled = false
local FlySpeed = 70

local bodyVelocity
local bodyGyro
local flyConnection

local moveVector = Vector3.zero

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local function SetupCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(SetupCharacter)

local function StartFly()
    if FlyEnabled then return end
    FlyEnabled = true

    Humanoid.PlatformStand = true

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

        bodyGyro.CFrame = CFrame.new(
            HumanoidRootPart.Position,
            HumanoidRootPart.Position + Camera.CFrame.LookVector
        )
    end)
end

local function StopFly()
    FlyEnabled = false

    Humanoid.PlatformStand = false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
end

-- TECLADO
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.W then
        moveVector = Vector3.new(moveVector.X, 0, -1)

    elseif input.KeyCode == Enum.KeyCode.S then
        moveVector = Vector3.new(moveVector.X, 0, 1)

    elseif input.KeyCode == Enum.KeyCode.A then
        moveVector = Vector3.new(-1, 0, moveVector.Z)

    elseif input.KeyCode == Enum.KeyCode.D then
        moveVector = Vector3.new(1, 0, moveVector.Z)
    end
end)

UserInputService.InputEnded:Connect(function(input)

    if input.KeyCode == Enum.KeyCode.W
    or input.KeyCode == Enum.KeyCode.S then

        moveVector = Vector3.new(moveVector.X, 0, 0)

    elseif input.KeyCode == Enum.KeyCode.A
    or input.KeyCode == Enum.KeyCode.D then

        moveVector = Vector3.new(0, 0, moveVector.Z)
    end
end)

-- MOBILE ANALÓGICO
RunService.RenderStepped:Connect(function()

    if not Character or not Humanoid then
        return
    end

    local moveDir = Humanoid.MoveDirection

    if moveDir.Magnitude > 0 then

        local relative = Camera.CFrame:VectorToObjectSpace(moveDir)

        moveVector = Vector3.new(
            relative.X,
            0,
            -relative.Z
        )

    else
        moveVector = Vector3.zero
    end
end)

-- PULO INFINITO
UserInputService.JumpRequest:Connect(function()

    if InfiniteJump then

        local hum = Character and Character:FindFirstChild("Humanoid")

        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- LOOP
RunService.RenderStepped:Connect(function()
-- FOV
local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Position = screenCenter
FOVCircle.Radius = FovSize
FOVCircle.Visible = FovVisible

-- AIMBOT
if AimbotEnabled then
local target = GetClosestPlayerToCenter()
if target then
Camera.CFrame = CFrame.new(Camera.CFrame.Position,target.Position)
end
end

-- ANTIFLING
if AntiFlingEnabled and LocalPlayer.Character then
for _,p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character then
for _,part in pairs(p.Character:GetChildren()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end
end
end

-- SPEED
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
LocalPlayer.Character.Humanoid.WalkSpeed = Speed
LocalPlayer.Character.Humanoid.JumpPower = Jump
end

UpdateESP()

-- ESP GUN
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
highlight.FillColor = Color3.fromRGB(255,255,0)
highlight.OutlineColor = Color3.fromRGB(255,255,255)
highlight.FillTransparency = 0.5
highlight.OutlineTransparency = 0

local gui = gun:FindFirstChild("GunGui")
if not gui then
gui = Instance.new("BillboardGui")
gui.Name = "GunGui"
gui.Size = UDim2.new(0,200,0,50)
gui.AlwaysOnTop = true
gui.ExtentsOffset = Vector3.new(0,2,0)
gui.Parent = gun
end
gui.Adornee = part

local label = gui:FindFirstChild("TextLabel")
if not label then
label = Instance.new("TextLabel")
label.Size = UDim2.new(1,0,1,0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.SourceSansBold
label.TextSize = 16
label.Parent = gui
end
label.TextColor3 = Color3.fromRGB(255,255,0)

local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - part.Position).Magnitude)
label.Text = "Arma Dropada\n" .. distance .. " m"

end

else
for _, obj in ipairs(workspace:GetChildren()) do
if obj.Name == "GunDrop" or (obj:IsA("Model") and obj.Name == "GunDrop") then
if obj:FindFirstChild("GunHighlight") then obj.GunHighlight:Destroy() end
if obj:FindFirstChild("GunGui") then obj.GunGui:Destroy() end
end
end
end

-- KNIFE AURA
        
if KnifeAuraEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    local myHRP = LocalPlayer.Character.HumanoidRootPart

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer
        and plr.Character
        and plr.Character:FindFirstChild("HumanoidRootPart")
        and plr.Character:FindFirstChild("Humanoid")
        and plr.Character.Humanoid.Health > 0 then

            local role = GetPlayerRole(plr)

            if role == "Murderer" or role == "Sheriff" or role == "Innocent" then

                local targetHRP = plr.Character.HumanoidRootPart

                local distanceFromSafe = (targetHRP.Position - SafePart.Position).Magnitude

                if distanceFromSafe > 50 then

                    -- salva posição original
                    if not SavedPositions[plr] then
                        SavedPositions[plr] = targetHRP.CFrame
                    end

                    local frontPos = myHRP.Position + (myHRP.CFrame.LookVector * KnifeAuraDistance)

                    targetHRP.CFrame = CFrame.new(frontPos)

                    targetHRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    targetHRP.AssemblyAngularVelocity = Vector3.new(0,0,0)

                end
            end
        end
    end

else
    -- restaura posição quando desativar
    for plr, savedCFrame in pairs(SavedPositions) do
        if plr
        and plr.Character
        and plr.Character:FindFirstChild("HumanoidRootPart") then

            plr.Character.HumanoidRootPart.CFrame = savedCFrame

            plr.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            plr.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end

SavedPositions = {}
end

end)

-- COMBATE
CombatTab:Toggle({
Title = "Aimbot",
Default = false,
Callback = function(v) AimbotEnabled = v end
})

CombatTab:Toggle({
Title = "Mostrar FOV",
Default = false,
Callback = function(v) FovVisible = v end
})

CombatTab:Slider({
Title = "FOV",
Step = 1,
Value = { Min = 50, Max = 500, Default = 100 },
Callback = function(v) FovSize = v end
})

CombatTab:Toggle({
Title = "Anti Fling",
Default = false,
Callback = function(v) AntiFlingEnabled = v end
})

CombatTab:Toggle({
Title = "Knife Aura",
Default = false,
Callback = function(v)
KnifeAuraEnabled = v
end
})

CombatTab:Slider({
Title = "Distância Aura",
Step = 1,
Value = {
Min = 3,
Max = 10,
Default = 5
},
Callback = function(v)
KnifeAuraDistance = v
end
})

-- ESP
EspTab:Toggle({
Title = "ESP Jogadores",
Default = false,
Callback = function(v) EspEnabled = v end
})

EspTab:Toggle({
Title = "ESP Arma",
Default = false,
Callback = function(v) GunEspEnabled = v end
})

-- ====================================================================
-- TELEPORTES
-- ====================================================================

-- 1. Murderer
TeleportTab:Button({
Title = "TP Murderer",
Callback = function()
local target = GetPlayerByRole("Murderer")
if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0))
end
end
})

-- 2. Sheriff
TeleportTab:Button({
Title = "TP Sheriff",
Callback = function()
local target = GetPlayerByRole("Sheriff")
if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0,3,0))
end
end
})

-- 3. Lista de jogadores
local PlayerDropdown = TeleportTab:Dropdown({
Title = "Escolher Jogador",
Values = GetPlayerNamesList(),
Value = "",
Callback = function(v) SelectedPlayerToTp = v end
})

-- 4. Teleportar para o jogador
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

-- 5. Atualizar lista
TeleportTab:Button({
Title = "Atualizar Lista",
Callback = function()
PlayerDropdown:Refresh(GetPlayerNamesList())
end
})

TeleportTab:Button({
Title = "TP Área Segura",
Callback = function()
TeleportToSafeArea()
end
})

-- 6. Teleportar para o lobby
TeleportTab:Button({
Title = "TP Lobby",
Callback = function()
local lobby = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("LobbyWorkspace")
if lobby then
local spawnLocation = lobby:FindFirstChildWhichIsA("SpawnLocation", true)
if spawnLocation then
TeleportToCFrame(spawnLocation.CFrame * CFrame.new(0, 4, 0))
return
end
end
local globalSpawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
if globalSpawn then
TeleportToCFrame(globalSpawn.CFrame * CFrame.new(0, 4, 0))
return
end
TeleportToCFrame(CFrame.new(-108, 145, 12))
end
})

-- 7. Teleportar para game arena
TeleportTab:Button({
Title = "TP Arena de Jogo",
Callback = function()
local activeMapFolder = workspace:FindFirstChild("NormalMaps") or workspace:FindFirstChild("Map")

if activeMapFolder then
for _, mapModel in ipairs(activeMapFolder:GetChildren()) do
if mapModel.Name ~= "Lobby" and mapModel.Name ~= "LobbyWorkspace" then

local spawns = mapModel:FindFirstChild("Spawns") or mapModel:FindFirstChild("PlayerSpawns") or mapModel:FindFirstChild("SpawnPoints")
if spawns and #spawns:GetChildren() > 0 then
local spawnPointsList = spawns:GetChildren()
local randomSpawn = spawnPointsList[math.random(1, #spawnPointsList)]
if randomSpawn:IsA("BasePart") then
TeleportToCFrame(CFrame.new(randomSpawn.Position + Vector3.new(0, 3, 0)))
return
end
end

local floor = mapModel:FindFirstChild("Floor") or mapModel:FindFirstChild("Geometry") or mapModel:FindFirstChildWhichIsA("BasePart", true)
if floor then
TeleportToCFrame(CFrame.new(floor.Position + Vector3.new(0, 6, 0)))
return
end
end
end

end

for _, obj in ipairs(workspace:GetChildren()) do
if obj:IsA("Model") and obj.Name ~= "Lobby" and obj.Name ~= "LobbyWorkspace" then
if obj:FindFirstChild("CoinContainer") then
local spawns = obj:FindFirstChild("Spawns") or obj:FindFirstChild("PlayerSpawns")
if spawns and #spawns:GetChildren() > 0 then
local randomSpawn = spawns:GetChildren()[math.random(1, #spawns:GetChildren())]
if randomSpawn:IsA("BasePart") then
TeleportToCFrame(CFrame.new(randomSpawn.Position + Vector3.new(0, 3, 0)))
return
end
end
end
end
end

end

})

-- 8. Teleportar para arma
TeleportTab:Button({
Title = "TP Arma Dropada",
Callback = function()
local gun = FindDroppedGun()
if gun then
local part = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
if part then
TeleportToCFrame(part.CFrame * CFrame.new(0,2,0))
end
end
end
})

local CoinCooldown = false

-- AUTO TP COIN
FarmTab:Toggle({
Title = "Auto collect Coin",
Default = false,
Callback = function(v)

AutoCoinEnabled = v

if v then
task.spawn(function()

while AutoCoinEnabled do
task.wait(0.5)

local coin = GetClosestCoin()

if coin then
FlyToPosition(coin, AutoCoinSpeed)
end

end

end)
end

end
})

FarmTab:Slider({
Title = "Velocidade Auto Coin",
Step = 1,
Value = {
Min = 10,
Max = 100,
Default = 50
},
Callback = function(v)
AutoCoinSpeed = v
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
task.wait(0.00)

local char = LocalPlayer.Character
if not char then continue end

if GetPlayerRole(LocalPlayer) == "Innocent" then
TeleportToSafeArea()
end

end
end)
end
end
})

LocalPlayer.CharacterAdded:Connect(function()
safeTpCount = 0
end)

-- ====================================================================

-- PLAYER
PlayerTab:Input({
Title = "Velocidade",
Placeholder = "16",
Callback = function(text)
local num = tonumber(text)

if num then  
        Speed = num  
    end  
end

})

PlayerTab:Input({
Title = "Pulo",
Placeholder = "50",
Callback = function(text)
local num = tonumber(text)

if num then  
        Jump = num  
    end  
end

})

PlayerTab:Toggle({
Title = "Pulo Infinito",
Default = false,
Callback = function(v)
InfiniteJump = v
end
})

PlayerTab:Toggle({
Title = "NoClip",
Default = false,
Callback = function(v)
NoclipEnabled = v
end
})

PlayerTab:Toggle({
Title = "Fly",
Default = false,
Callback = function(v)

if v then  
        StartFly()  
    else  
        StopFly()  
    end  
end

})

PlayerTab:Slider({
Title = "Fly Speed",
Step = 5,
Value = {
Min = 10,
Max = 200,
Default = 70
},
Callback = function(v)
FlySpeed = v
end
})

-- PERFORMANCE
PerformanceTab:Toggle({
Title = "Modo Leve",
Default = false,
Callback = function(v)
LowGraphicsEnabled = v
if v then
OptimizeTextures()
end
end
})
