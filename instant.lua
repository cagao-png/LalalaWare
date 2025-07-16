          Duration = 3
        })
    end-- Load Rayfield (official via sirius.menu)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Main services and variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- Default settings
local FOV_RADIUS = 60
local FOV_THICKNESS = 1
local aiming, showFOV, softMode, wallCheck, teamCheck, rainbowFOV = false, false, false, false, true, false
local instantAim = true
local aimPart = "Head"
local aimStrength = 0.14
local predictionStrength = 0.0
local prioritizeModes = {"default", "nearest", "low hp", "high hp"}
local prioritizeIndex = 1
local fullbrightOn = false
local distanceValue = 1000
local infiniteDistance = false
local customFOVColor = Color3.new(1, 1, 0)

-- Random Part Switching (W.I.P)
local randomPartSwitching = false
local partSwitchDelay = 0.5
local currentAimPart = "Head"
local lastSwitchTime = tick()
local aimPartsList = {"Head", "Torso", "HumanoidRootPart"}

-- Lighting Backup
local origLighting = {}
local fullbrightSettings = {
    Ambient = Color3.new(1,1,1),
    Brightness = 5,
    ColorShift_Bottom = Color3.new(1,1,1),
    ColorShift_Top = Color3.new(1,1,1),
    OutdoorAmbient = Color3.new(1,1,1),
    FogEnd = 100000
}

-- Functions
local function isPlayerDead(player)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return not hum or hum.Health <= 0
end

local function isVisible(part)
    if not wallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local hit = workspace:Raycast(origin, dir, params)
    return not hit or hit.Instance:IsDescendantOf(part.Parent)
end

local function getClosestPlayer()
    local candidates = {}
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isPlayerDead(player) and (not teamCheck or player.Team ~= LocalPlayer.Team) then
            local root = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head"))
            if root then
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                if infiniteDistance or dist <= distanceValue then
                    local part = player.Character:FindFirstChild(currentAimPart)
                    if part then
                        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if onScreen and mag <= FOV_RADIUS and isVisible(part) then
                            table.insert(candidates, {p = player, dist = mag, hp = player.Character:FindFirstChildOfClass("Humanoid").Health or 100})
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    local mode = prioritizeModes[prioritizeIndex]
    if mode == "default" or mode == "nearest" then
        table.sort(candidates, function(a,b) return a.dist < b.dist end)
    elseif mode == "low hp" then
        table.sort(candidates, function(a,b) if a.hp == b.hp then return a.dist < b.dist end return a.hp < b.hp end)
    elseif mode == "high hp" then
        table.sort(candidates, function(a,b) if a.hp == b.hp then return a.dist < b.dist end return a.hp > b.hp end)
    end

    return candidates[1].p
end

-- FOV Drawing
local circle = Drawing.new("Circle")
circle.Thickness = FOV_THICKNESS
circle.Filled = false
circle.Radius = FOV_RADIUS
circle.Color = customFOVColor
circle.Visible = false

RunService.RenderStepped:Connect(function()
    circle.Visible = showFOV
    circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    circle.Radius = FOV_RADIUS
    circle.Thickness = FOV_THICKNESS
    if rainbowFOV then
        circle.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    else
        circle.Color = customFOVColor
    end
end)

RunService.RenderStepped:Connect(function()
    if aiming then
        local target = getClosestPlayer()
        if target and target.Character then
            if randomPartSwitching then
                if tick() - lastSwitchTime >= partSwitchDelay then
                    local availableParts = {}
                    for _, p in ipairs(aimPartsList) do
                        if target.Character:FindFirstChild(p) then
                            table.insert(availableParts, p)
                        end
                    end
                    if #availableParts > 0 then
                        currentAimPart = availableParts[math.random(1, #availableParts)]
                        lastSwitchTime = tick()
                    end
                end
            else
                currentAimPart = aimPart
            end

            local part = target.Character:FindFirstChild(currentAimPart)
            if part then
                local predicted = part.Position
                local root = target.Character:FindFirstChild("HumanoidRootPart")
                if predictionStrength > 0 and root then
                    predicted += root.Velocity * predictionStrength
                end
                local dir = (predicted - Camera.CFrame.Position).Unit
                local look = softMode and Camera.CFrame.LookVector:Lerp(dir, aimStrength).Unit or dir
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + look)
            end
        end
    end
end)

-- Rayfield UI with KeySystem
local Window = Rayfield:CreateWindow({
    Name = "InstantAim PRO",
    LoadingTitle = "InstantAim PRO",
    LoadingSubtitle = "by lalala",
    ConfigurationSaving = { Enabled = false },
    Discord = {
        Enabled = true,
        Invite = "qP7CFMFEax",
        RememberJoins = false
    },
    KeySystem = true,
    KeySettings = {
        Title = "InstantAim PRO",
        Subtitle = "Key System",
        Note = "Click to copy Discord: discord.gg/qP7CFMFEax",
        FileName = "aim_key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = { "aimbotex" }
    }
})

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local CreditTab = Window:CreateTab("Credits", 4483362458)

-- MainTab Controls
MainTab:CreateToggle({Name="Aimbot", CurrentValue=false, Callback=function(v) aiming=v end})
MainTab:CreateToggle({Name="Show FOV", CurrentValue=false, Callback=function(v) showFOV=v end})
MainTab:CreateToggle({Name="Soft Aim", CurrentValue=false, Callback=function(v) softMode=v end})
MainTab:CreateToggle({Name="Wall Check", CurrentValue=false, Callback=function(v) wallCheck=v end})
MainTab:CreateToggle({Name="Team Check", CurrentValue=true, Callback=function(v) teamCheck=v end})
MainTab:CreateToggle({Name="Instant Aim", CurrentValue=true, Callback=function(v) instantAim=v end})
MainTab:CreateToggle({Name="Rainbow FOV", CurrentValue=false, Callback=function(v) rainbowFOV=v end})
MainTab:CreateToggle({Name="Random Part Switching (W.I.P)", CurrentValue=false, Callback=function(v) randomPartSwitching=v end})
MainTab:CreateSlider({Name="Switch Delay", Range={0.1, 3}, Increment=0.1, CurrentValue=0.5, Suffix="s", Callback=function(v) partSwitchDelay=v end})
MainTab:CreateDropdown({Name="Aim Part", Options=aimPartsList, CurrentOption=aimPart, Callback=function(o) aimPart=o end})
MainTab:CreateDropdown({Name="Prioritize", Options=prioritizeModes, CurrentOption=prioritizeModes[prioritizeIndex], Callback=function(o) for i,m in ipairs(prioritizeModes) do if m==o then prioritizeIndex=i break end end end})
MainTab:CreateSlider({Name="FOV Radius", Range={10,160}, Increment=1, Suffix="px", CurrentValue=FOV_RADIUS, Callback=function(v) FOV_RADIUS=v end})
MainTab:CreateSlider({Name="FOV Thickness", Range={1,5}, Increment=1, Suffix="px", CurrentValue=FOV_THICKNESS, Callback=function(v) FOV_THICKNESS=v end})
MainTab:CreateColorPicker({Name = "FOV Color", Color = customFOVColor, Callback = function(c) customFOVColor = c end})
MainTab:CreateSlider({Name="Aim Strength", Range={0.1,1}, Increment=0.01, CurrentValue=aimStrength, Callback=function(v) aimStrength=v end})
MainTab:CreateSlider({Name="Prediction", Range={0,0.35}, Increment=0.01, CurrentValue=predictionStrength, Callback=function(v) predictionStrength=v end})
MainTab:CreateSlider({Name="Distance", Range={50,1000}, Increment=10, CurrentValue=distanceValue, Suffix="studs", Callback=function(v) distanceValue=v end})
MainTab:CreateToggle({Name="Infinite Distance", CurrentValue=false, Callback=function(v) infiniteDistance=v end})

-- MiscTab Controls
MiscTab:CreateButton({
    Name = "Fullbright",
    Callback = function()
        if not fullbrightOn then
            for k,v in pairs(fullbrightSettings) do Lighting[k]=v end
            Rayfield:Notify({Title="Fullbright",Content="Bright ON",Duration=2})
        else
            for k,v in pairs(origLighting) do Lighting[k]=v end
            Rayfield:Notify({Title="Fullbright",Content="Bright OFF",Duration=2})
        end
        fullbrightOn = not fullbrightOn
    end
})

MiscTab:CreateButton({
    Name = "Load External ESP",
    Callback = function()
        local success, result = pcall(function()
            loadstring(game:HttpGet("https://pastebin.com/raw/qBZHFF23"))()
        end)
        if success then
            Rayfield:Notify({
                Title = "ESP",
                Content = "ESP script loaded successfully!",
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "ESP Error",
                Content = tostring(result),
                Duration = 4
            })
        end
    end
})

-- CreditTab
CreditTab:CreateParagraph({Title = "Created by", Content = "lalala (InstantAim PRO)"})
CreditTab:CreateButton({
    Name = "Discord: discord.gg/qP7CFMFEax",
    Callback = function()
        setclipboard("https://discord.gg/qP7CFMFEax")
        Rayfield:Notify({
            Title = "Copied!",
            Content = "Discord link copied to clipboard!",
            Duration = 3
        })
    end
})})
