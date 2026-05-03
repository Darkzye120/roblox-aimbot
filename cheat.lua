local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- === CONFIGURAÇÕES REGULÁVEIS ===
local AIM_KEY = Enum.UserInputType.MouseButton2 
local FOV_RADIUS = 160 
local SMOOTHNESS = 1
local FOV_VISIBLE = true
local FOV_COLOR = Color3.fromRGB(0, 255, 255)
local AIM_PART = "Head" 
local MAX_AIM_DISTANCE = 250 
-- ================================

local aiming = false
local lockedTarget = nil 

-- Criar o círculo visual do FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = FOV_VISIBLE
FOVCircle.Radius = FOV_RADIUS
FOVCircle.Color = FOV_COLOR
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- Função para verificar se o alvo está perto o suficiente
local function isWithinDistance(player)
    if not player.Character or not player.Character:FindFirstChild(AIM_PART) then return false end
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    
    local dist = (player.Character[AIM_PART].Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
    return dist <= MAX_AIM_DISTANCE
end

local function isValidTarget(player)
    return player and 
           player.Character and 
           player.Character:FindFirstChild("Humanoid") and 
           player.Character.Humanoid.Health > 0 and 
           player.Character:FindFirstChild(AIM_PART) and
           isWithinDistance(player)
end

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = FOV_RADIUS 
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        -- Removido o filtro de Team Check aqui
        if player ~= localPlayer and isValidTarget(player) then
            local targetPart = player.Character[AIM_PART]
            local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)

            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == AIM_KEY then 
        aiming = true 
        lockedTarget = getClosestPlayerInFOV()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AIM_KEY then 
        aiming = false 
        lockedTarget = nil 
    end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    if aiming then
        if not isValidTarget(lockedTarget) then
            lockedTarget = getClosestPlayerInFOV()
        end

        if lockedTarget then
            local targetPart = lockedTarget.Character[AIM_PART]
            local targetCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, SMOOTHNESS)
        end
    end
end)

-- === SISTEMA DE ESP (SEM TEAM CHECK) ===
local function createESP(player)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerBox"
    billboard.Size = UDim2.new(4.5, 0, 7.5, 0)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false
    billboard.ExtentsOffset = Vector3.new(0, 1, 0)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0.8, 0)
    frame.Position = UDim2.new(0, 0, 0.2, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = billboard
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.8
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(2, 0, 0.25, 0)
    label.Position = UDim2.new(0.5, 0, 0.15, 0)
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.ZIndex = 20
    label.Parent = billboard
    
    local textStroke = Instance.new("UIStroke")
    textStroke.Thickness = 1.5
    textStroke.Parent = label

    local function update(humanoid)
        -- O Billboard permanece habilitado para todos os jogadores agora
        local health = math.floor(humanoid.Health)
        local maxHealth = math.floor(humanoid.MaxHealth)
        label.Text = player.Name .. "\n[HP: " .. health .. "]"
        
        if health > maxHealth * 0.6 then label.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif health > maxHealth * 0.3 then label.TextColor3 = Color3.fromRGB(255, 255, 0)
        else label.TextColor3 = Color3.fromRGB(255, 0, 0) end
    end

    return billboard, update
end

local function apply(player)
    local function setup(char)
        local hum = char:WaitForChild("Humanoid", 15)
        local root = char:WaitForChild("HumanoidRootPart", 15)
        
        if hum and root then
            for _, v in ipairs(char:GetChildren()) do
                if v.Name == "PlayerBox" then v:Destroy() end
            end
            
            local gui, update = createESP(player)
            gui.Adornee = root
            gui.Parent = char
            
            hum.HealthChanged:Connect(function() update(hum) end)
            update(hum)
        end
    end
    player.CharacterAdded:Connect(setup)
    if player.Character then setup(player.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do apply(p) end
Players.PlayerAdded:Connect(apply)