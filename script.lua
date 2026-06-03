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
Theme = "Red",
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
Color3.fromHex("FF0000"), -- Vermelho Puro Hex
Color3.fromHex("FF0000")  -- Vermelho Puro Hex
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
local FovSize = 50
local TargetType = "Murderer"
local AutoCoinEnabled = false

local EspEnabled = false
local GunEspEnabled = false
local AntiFlingEnabled = false
local LowGraphicsEnabled = false

local Speed = 16
local Jump = 50

local SelectedPlayerToTp = ""

-- FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255,0,0)
FOVCircle.Thickness = 2
FOVCircle.Transparency = 1
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Tabs
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

local PlayerTab = Window:Tab({
Title = "Player",
Icon = "user"
})

local PerformanceTab = Window:Tab({
Title = "Desempenho",
Icon = "cpu"
})

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
and obj.Transparency < 1 then

local name = string.lower(obj.Name)

if name:find("coin")
or name:find("gold")
or name:find("token") then

-- evita partes falsas do mapa
if obj.Size.X <= 5
and obj.Size.Y <= 5
and obj.Size.Z <= 5 then

local distance = (hrp.Position - obj.Position).Magnitude          

-- ignora moedas muito perto (já coletadas)          
if distance > 3 then          

    if distance < shortestDistance then          
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
local function FlyToPosition(position, speed)

local char = LocalPlayer.Character
if not char or not char:FindFirstChild("HumanoidRootPart") then
return
end

local hrp = char.HumanoidRootPart

local distance = (hrp.Position - position).Magnitude
local time = distance / speed

local tween = TweenService:Create(
hrp,
TweenInfo.new(time, Enum.EasingStyle.Linear),
{
CFrame = CFrame.new(position + Vector3.new(0,2,0))
}
)

NoclipEnabled = true

tween:Play()
tween.Completed:Wait()

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
Value = { Min = 30, Max = 500, Default = 50 },
Callback = function(v) FovSize = v end
})

CombatTab:Toggle({
Title = "Anti Fling",
Default = false,
Callback = function(v) AntiFlingEnabled = v end
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
TeleportTab:Toggle({
Title = "Auto collect Coin",
Default = false,
Callback = function(v)

AutoCoinEnabled = v

if v then
task.spawn(function()

while AutoCoinEnabled do
task.wait(1)

local coin = GetClosestCoin()

if coin then
FlyToPosition(coin.Position, 45)
end

end

end)
end

end
})

-- ====================================================================

-- PLAYER
PlayerTab:Input({
Title = "Velocidade",
Placeholder = "Digite um número",
Callback = function(text)
local num = tonumber(text)
if num then Speed = num end
end
})

PlayerTab:Input({
Title = "Pulo",
Placeholder = "Digite um número",
Callback = function(text)
local num = tonumber(text)
if num then Jump = num end
end
})

-- PERFORMANCE
PerformanceTab:Toggle({
Title = "Modo Leve",
Default = false,
Callback = function(v)
LowGraphicsEnabled = v
if v then OptimizeTextures() end
end
})
