local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
Name = "Murder Mystery 2",
LoadingTitle = "Carregando script",
LoadingSubtitle = "Feito por zxred",
ConfigurationSaving = {Enabled = false}
})

-- Serviços Principais
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

-- Variáveis de Controle (Aimbot)
local AimbotEnabled = false
local TargetType = "Murderer"
local FovVisible = false
local FovSize = 100

-- Variável de Controle (Anti-Fling)
local AntiFlingEnabled = false

-- Variáveis de Controle (ESP)
local EspEnabled = false
local GunEspEnabled = false

-- Variável para lembrar se o modo leve está ativo
local LowGraphicsEnabled = false

-- Variável para o jogador selecionado no teleporte
local SelectedPlayerToTp = ""

-- Criando o Círculo do FOV (Vermelho e Fixo)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 2
FOVCircle.Transparency = 1
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Função de identificação instantânea de papéis
local function GetPlayerRole(player)
if not player then return "Innocent" end

if player:FindFirstChild("PlayerData") and player.PlayerData:FindFirstChild("Role") then
return player.PlayerData.Role.Value
end

local backpack = player:FindFirstChild("Backpack")
local char = player.Character
if (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
return "Murderer"
elseif (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
return "Sheriff"
end

return "Innocent"

end

-- Função achar jogador por função (Auxiliar do Teleporte)
local function GetPlayerByRole(roleName)
for _, p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer and GetPlayerRole(p) == roleName then
return p
end
end
return nil
end

-- Função base para executar o teleporte com segurança e zerar rotação (Garante ficar de pé)
local function TeleportToCFrame(targetCFrame)
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetCFrame.Position)
end
end

-- Função para obter a lista de nomes dos jogadores do servidor
local function GetPlayerNamesList()
local list = {}
for _, p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
table.insert(list, p.Name)
end
end
return list
end

-- Função para achar o alvo do Aimbot
local function GetClosestPlayerToCenter()
local closestPlayer = nil
local shortestDistance = FovSize
local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

for _, p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
local role = GetPlayerRole(p)
if role == TargetType then
local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
if onScreen then
local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
if distance < shortestDistance then
closestPlayer = p.Character.Head
shortestDistance = distance
end
end
end
end
end
return closestPlayer

end

-- Função para localizar a arma dropada no mapa
local function FindDroppedGun()
local gun = workspace:FindFirstChild("GunDrop")
if gun then return gun end

for _, obj in ipairs(workspace:GetChildren()) do
if obj.Name == "GunDrop" or (obj:IsA("Model") and obj:FindFirstChild("GunDrop")) then
return obj:FindFirstChild("GunDrop") or obj
end
end
return nil

end

-- Função interna que aplica a otimização em um objeto específico
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

-- Função principal para otimizar texturas (Texture Remover / FPS Booster)
local function OptimizeTextures()
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

for _, obj in ipairs(workspace:GetDescendants()) do
CleanObject(obj)
end

end

-- Monitor Automático: Limpa novos mapas ou novos objetos que surgirem se o modo leve estiver ligado
workspace.DescendantAdded:Connect(function(descendant)
if LowGraphicsEnabled then
task.wait(0.1)
if descendant and descendant.Parent then
CleanObject(descendant)
end
end
end)

-- Loop de Atualização Geral (Aimbot, ESP, Arma Dropada e Anti-Fling)
RunService.RenderStepped:Connect(function()
-- Atualização do FOV
local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Position = screenCenter
FOVCircle.Radius = FovSize
FOVCircle.Visible = FovVisible

-- Lógica do Aimbot
if AimbotEnabled then
local target = GetClosestPlayerToCenter()
if target then
Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
end
end

-- Lógica do Anti-Fling / No Clip com jogadores
if AntiFlingEnabled and LocalPlayer.Character then
for _, p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character then
for _, part in pairs(p.Character:GetChildren()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end
end
end

-- Lógica do ESP de Jogadores
for _, p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
local char = p.Character

if EspEnabled and char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
local role = GetPlayerRole(p)

local teamColor = Color3.fromRGB(0, 255, 0) -- Verde (Innocent)
if role == "Murderer" then
teamColor = Color3.fromRGB(255, 0, 0) -- Vermelho
elseif role == "Sheriff" then
teamColor = Color3.fromRGB(0, 0, 255) -- Azul
end

local highlight = char:FindFirstChild("ESP_Highlight")
if not highlight then
highlight = Instance.new("Highlight")
highlight.Name = "ESP_Highlight"
highlight.Parent = char
end
highlight.FillColor = teamColor
highlight.FillTransparency = 0.5 -- Preenche totalmente a cor do jogador de forma visível
highlight.OutlineColor = teamColor -- Mudado para a cor do time para remover a borda branca
highlight.OutlineTransparency = 1 -- Define a transparência da borda para 1 (totalmente invisível)
highlight.Enabled = true

local gui = char:FindFirstChild("ESP_Gui")
if not gui then
gui = Instance.new("BillboardGui")
gui.Name = "ESP_Gui"
gui.AlwaysOnTop = true
gui.Size = UDim2.new(0, 200, 0, 60)
gui.ExtentsOffset = Vector3.new(0, 3, 0)
gui.Parent = char
end
gui.Adornee = char.Head

local label = gui:FindFirstChild("TextLabel")
if not label then
label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.new(1, 0, 1, 0)
label.Font = Enum.Font.SourceSansBold
label.TextSize = 14
label.TextStrokeTransparency = 1 -- Mudado para 1 (Sem borda)
label.Parent = gui
end
label.TextColor3 = teamColor

local distanceInStuds = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and (LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude or 0
local distanceCalculated = math.floor(distanceInStuds)

label.Text = p.Name .. "\n" .. role .. "\n" .. tostring(distanceCalculated) .. " m"

else
if char then
if char:FindFirstChild("ESP_Highlight") then char.ESP_Highlight:Destroy() end
if char:FindFirstChild("ESP_Gui") then char.ESP_Gui:Destroy() end
end
end

end

end

-- Lógica do ESP da Arma Dropada
local gunDrop = FindDroppedGun()
if gunDrop and GunEspEnabled then
local targetPart = gunDrop:IsA("BasePart") and gunDrop or gunDrop:FindFirstChildWhichIsA("BasePart")

if targetPart then
local gunHighlight = gunDrop:FindFirstChild("Gun_Highlight") or Instance.new("Highlight", gunDrop)
gunHighlight.Name = "Gun_Highlight"
gunHighlight.FillColor = Color3.fromRGB(255, 255, 0)
gunHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
gunHighlight.FillTransparency = 0.5
gunHighlight.OutlineTransparency = 0
gunHighlight.Enabled = true

local gunGui = gunDrop:FindFirstChild("Gun_Gui") or Instance.new("BillboardGui", gunDrop)
gunGui.Name = "Gun_Gui"
gunGui.AlwaysOnTop = true
gunGui.Size = UDim2.new(0, 200, 0, 40)
gunGui.Adornee = targetPart
gunGui.ExtentsOffset = Vector3.new(0, 2, 0)

local gunLabel = gunGui:FindFirstChild("TextLabel") or Instance.new("TextLabel", gunGui)
gunLabel.BackgroundTransparency = 1
gunLabel.Size = UDim2.new(1, 0, 1, 0)
gunLabel.Font = Enum.Font.SourceSansBold
gunLabel.TextSize = 16
gunLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
gunLabel.TextStrokeTransparency = 1 -- Mudado para 1 (Sem borda)

local distanceInStuds = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and (LocalPlayer.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude or 0
local distanceCalculated = math.floor(distanceInStuds)

gunLabel.Text = "Arma Dropada\n" .. tostring(distanceCalculated) .. " m"
gunLabel.Parent = gunGui
gunGui.Parent = gunDrop

end

else
for _, obj in ipairs(workspace:GetChildren()) do
if obj.Name == "GunDrop" or (obj:IsA("Model") and obj.Name == "GunDrop") then
if obj:FindFirstChild("Gun_Highlight") then obj.Gun_Highlight:Destroy() end
if obj:FindFirstChild("Gun_Gui") then obj.Gun_Gui:Destroy() end
end
end
end

end)

-- Limpeza preventiva quando jogadores saem do servidor
Players.PlayerRemoving:Connect(function(player)
if player.Character then
if player.Character:FindFirstChild("ESP_Highlight") then player.Character.ESP_Highlight:Destroy() end
if player.Character:FindFirstChild("ESP_Gui") then player.Character.ESP_Gui:Destroy() end
end
end)

-- Abas do Menu (Combate movida para primeira posição)
local CombatTab = Window:CreateTab("Combate", 4483362458)
local EspTab = Window:CreateTab("Visual (ESP)", 4483362458)
local TeleportTab = Window:CreateTab("Teleportes", 4483362458)
local PerformanceTab = Window:CreateTab("Desempenho", 4483362458)

-- Configurações da Aba Combate (Antigo Aimbot + Anti-Fling em último)
CombatTab:CreateToggle({
Name = "Ativar Aimbot",
CurrentValue = false,
Callback = function(Value) AimbotEnabled = Value end,
})

CombatTab:CreateDropdown({
Name = "Focar em:",
Options = {"Murderer", "Sheriff", "Innocent"},
CurrentOption = {"Murderer"},
MultipleOptions = false,
Callback = function(Option) TargetType = Option[1] end,
})

CombatTab:CreateToggle({
Name = "Ativar  FOV",
CurrentValue = false,
Callback = function(Value) FovVisible = Value end,
})

CombatTab:CreateSlider({
Name = "Tamanho do FOV",
Range = {50, 500},
Increment = 5,
CurrentValue = 100,
Callback = function(Value) FovSize = Value end,
})

CombatTab:CreateToggle({
Name = "Ativar Anti-Fling",
CurrentValue = false,
Callback = function(Value) AntiFlingEnabled = Value end,
})

-- Configurações da Aba ESP
EspTab:CreateToggle({
Name = "Ativar ESP Jogadores",
CurrentValue = false,
Callback = function(Value) EspEnabled = Value end,
})

EspTab:CreateToggle({
Name = "Ativar ESP Arma",
CurrentValue = false,
Callback = function(Value) GunEspEnabled = Value end,
})

-- Configurações da Aba Teleportes
TeleportTab:CreateButton({
Name = "Teleportar para o Murderer",
Callback = function()
local target = GetPlayerByRole("Murderer")
if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
else
Rayfield:Notify({Name = "Erro", Content = "Murderer não encontrado ou sem personagem.", Duration = 2})
end
end,
})

TeleportTab:CreateButton({
Name = "Teleportar para o Sheriff",
Callback = function()
local target = GetPlayerByRole("Sheriff")
if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
else
Rayfield:Notify({Name = "Erro", Content = "Sheriff não encontrado ou sem personagem.", Duration = 2})
end
end,
})

local PlayerDropdown = TeleportTab:CreateDropdown({
Name = "Escolher Jogador:",
Options = GetPlayerNamesList(),
CurrentOption = {""},
MultipleOptions = false,
Callback = function(Option)
SelectedPlayerToTp = Option[1]
end,
})

TeleportTab:CreateButton({
Name = "Teleportar para o Jogador",
Callback = function()
if SelectedPlayerToTp ~= "" then
local target = Players:FindFirstChild(SelectedPlayerToTp)
if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
TeleportToCFrame(target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
else
Rayfield:Notify({Name = "Erro", Content = "Jogador indisponível ou sem personagem.", Duration = 2})
end
else
Rayfield:Notify({Name = "Aviso", Content = "Selecione um jogador na lista acima primeiro.", Duration = 2})
end
end,
})

TeleportTab:CreateButton({
Name = "Atualizar Lista de Jogadores",
Callback = function()
PlayerDropdown:Refresh(GetPlayerNamesList(), true)
Rayfield:Notify({Name = "Lista Atualizada", Content = "A lista de jogadores foi sincronizada com o servidor.", Duration = 2})
end,
})

TeleportTab:CreateButton({
Name = "Teleportar para a Arma Dropada",
Callback = function()
local gun = FindDroppedGun()
if gun then
local targetPart = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
if targetPart then
TeleportToCFrame(targetPart.CFrame * CFrame.new(0, 2, 0))
end
else
Rayfield:Notify({Name = "Aviso", Content = "Nenhuma arma dropada encontrada no mapa atual.", Duration = 2})
end
end,
})

TeleportTab:CreateButton({
Name = "Teleportar para o Lobby",
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
Rayfield:Notify({Name = "Aviso", Content = "Spawn oficial não encontrado, usando coordenada aproximada.", Duration = 2})

end,
})

TeleportTab:CreateButton({
Name = "Teleportar para a Arena de Jogo",
Callback = function()
-- 1. Varre estritamente as pastas de mapas ativos geradas pelo MM2
local activeMapFolder = workspace:FindFirstChild("NormalMaps") or workspace:FindFirstChild("Map")

if activeMapFolder then
for _, mapModel in ipairs(activeMapFolder:GetChildren()) do
-- Ignora completamente o Lobby caso ele esteja misturado na pasta
if mapModel.Name ~= "Lobby" and mapModel.Name ~= "LobbyWorkspace" then

-- Busca a pasta interna de Spawns físicos do mapa selecionado
local spawns = mapModel:FindFirstChild("Spawns") or mapModel:FindFirstChild("PlayerSpawns") or mapModel:FindFirstChild("SpawnPoints")

if spawns and #spawns:GetChildren() > 0 then
-- Escolhe um bloco de spawn físico aleatório da arena
local spawnPointsList = spawns:GetChildren()
local randomSpawn = spawnPointsList[math.random(1, #spawnPointsList)]

if randomSpawn:IsA("BasePart") then
-- Teleporta para as coordenadas do Spawn zerando rotação + altura segura (limpa e fica de pé)
TeleportToCFrame(CFrame.new(randomSpawn.Position + Vector3.new(0, 3, 0)))
return
end
end

-- Fallback 1: Caso a pasta Spawns esteja oculta, pega a parte física do chão (Floor) da arena
local floor = mapModel:FindFirstChild("Floor") or mapModel:FindFirstChild("Geometry") or mapModel:FindFirstChildWhichIsA("BasePart", true)
if floor then
TeleportToCFrame(CFrame.new(floor.Position + Vector3.new(0, 6, 0)))
return
end

end

end

end

-- Fallback 2: Caso as estruturas padrão falhem, localiza a arena pela presença de moedas coletáveis (Exclusivas da rodada)
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

Rayfield:Notify({Name = "Aviso", Content = "Não foi possível teleportar agora, aguarde a partida começar", Duration = 2})

end,
})

-- Configurações da Aba Desempenho
PerformanceTab:CreateToggle({
Name = "Modo Leve",
CurrentValue = false,
Callback = function(Value)
LowGraphicsEnabled = Value
if LowGraphicsEnabled then
OptimizeTextures()
Rayfield:Notify({
Name = "Modo Leve Ativado",
Content = "Modo leve ativado texturas mais simples",
Duration = 2,
Image = 4483362458,
})
end
end,
})

