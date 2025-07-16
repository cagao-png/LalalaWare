-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local FOV_RADIUS, FOV_THICKNESS = 60, 1
local aiming, showFOV, softMode, wallCheck, teamCheck, rainbowFOV = false, false, false, false, true, false
local instantAim = true
local aimPart = "Head"
local aimStrength, predictionStrength = 0.14, 0.0
local prioritizeModes = {"default", "nearest", "low hp", "high hp"}
local prioritizeIndex = 1
local fullbrightOn, infiniteDistance = false, false
local distanceValue = 1000
local customFOVColor = Color3.new(1, 1, 0)
local aimPartsList = {"Head", "Torso", "HumanoidRootPart"}

-- Extra features
local customKillSoundURL = ""
local autoJumpEnabled = false
local spinbotEnabled = false
local noRecoilEnabled = false

-- Random part switching
local randomPartSwitching = false
local partSwitchDelay, lastSwitchTime = 0.5, tick()
local currentAimPart = "Head"

-- Fullbright backup
local origLighting = {}
local fullbrightSettings = {
    Ambient = Color3.new(1,1,1),
    Brightness = 5,
    ColorShift_Bottom = Color3.new(1,1,1),
    ColorShift_Top = Color3.new(1,1,1),
    OutdoorAmbient = Color3.new(1,1,1),
    FogEnd = 100000
}

-- Play kill sound
local function playKillSound()
    if customKillSoundURL ~= "" then
        local s = Instance.new("Sound", SoundService)
        s.SoundId = customKillSoundURL
        s.Volume = 1
        s:Play()
        s.Ended:Connect(function() s:Destroy() end)
    end
end

-- Hook death sound to players
local function hookPlayer(p)
    p.CharacterAdded:Connect(function(c)
        local h = c:WaitForChild("Humanoid", 5)
        if h then
            h.Died:Connect(function()
                if aiming then playKillSound() end
            end)
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then hookPlayer(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then hookPlayer(p) end end)

-- Drawing FOV circle
local circle = Drawing.new("Circle")
circle.Thickness, circle.Filled, circle.Radius = FOV_THICKNESS, false, FOV_RADIUS
circle.Color = customFOVColor
circle.Visible = false

-- Get closest player
local function getClosest()
    local best, center = nil, Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 and (not teamCheck or p.Team ~= LocalPlayer.Team) then
            local part = p.Character:FindFirstChild(currentAimPart)
            if part then
                local dist3 = (part.Position - Camera.CFrame.Position).Magnitude
                if (infiniteDistance or dist3 <= distanceValue) then
                    local pos,ons = Camera:WorldToViewportPoint(part.Position)
                    if ons then
                        local mag = (Vector2.new(pos.X,pos.Y)-center).Magnitude
                        if mag <= FOV_RADIUS and (not wallCheck or workspace:Raycast(Camera.CFrame.Position, part.Position-Camera.CFrame.Position, RaycastParams.new{FilterDescendantsInstances={LocalPlayer.Character, Camera}, FilterType=Enum.RaycastFilterType.Blacklist})) then
                            best = best and ((mode=="nearest" and mag < best.mag) or (mode=="low hp" and p.Character:FindFirstChildOfClass("Humanoid").Health < best.hp)) and best or {p=p, mag=mag, hp=p.Character:FindFirstChildOfClass("Humanoid").Health}
                        end
                    end
                end
            end
        end
    end
    return best and best.p or nil
end

-- Debounce for noRecoil
local lastRecoil = 0

-- Single RenderStepped
RunService.RenderStepped:Connect(function(dt)
    circle.Visible = showFOV
    circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    circle.Radius, circle.Thickness = FOV_RADIUS, FOV_THICKNESS
    circle.Color = rainbowFOV and Color3.fromHSV(tick()%5/5,1,1) or customFOVColor

    -- Aimbot
    if aiming then
        local target = getClosest()
        if target and target.Character then
            if randomPartSwitching and tick()-lastSwitchTime >= partSwitchDelay then
                local list = {}
                for _, pn in ipairs(aimPartsList) do
                    if target.Character:FindFirstChild(pn) then table.insert(list,pn) end
                end
                if #list > 0 then
                    currentAimPart = list[math.random(#list)]
                    lastSwitchTime = tick()
                end
            end
            local part = target.Character:FindFirstChild(currentAimPart)
            if part then
                local root = target.Character:FindFirstChild("HumanoidRootPart")
                local pos = part.Position + (predictionStrength>0 and root and root.Velocity * predictionStrength or Vector3.zero)
                local dir = (pos - Camera.CFrame.Position).Unit
                local look = softMode and Camera.CFrame.LookVector:Lerp(dir, aimStrength).Unit or dir
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + look)
            end
        end
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if autoJumpEnabled and hum then hum.Jump = true end
        if spinbotEnabled and hrp then hrp.CFrame *= CFrame.Angles(0, math.rad(25 * dt*60), 0) end

        if noRecoilEnabled and tick()-lastRecoil >= 1 then
            lastRecoil = tick()
            for _, o in ipairs(getgc(true)) do
                if type(o)=="table" then
                    if rawget(o, "Recoil") then o.Recoil = 0 end
                    if rawget(o, "Spread") then o.Spread = 0 end
                end
            end
        end
    end
end)

-- UI
local Window = Rayfield:CreateWindow({
    Name="InstantAim PRO",
    LoadingTitle="InstantAim PRO", LoadingSubtitle="by lalala",
    ConfigurationSaving={Enabled=false},
    Discord={Enabled=true, Invite="qP7CFMFEax"},
    KeySystem=true, KeySettings={Title="InstantAim PRO", Note="discord.gg/qP7CFMFEax", Key={"aimbotex"}}
})
local MT, MST, CTab = Window:CreateTab("Main",0), Window:CreateTab("Misc",0), Window:CreateTab("Credits",0)

-- MainTab
MT:CreateToggle({Name="Aimbot",CurrentValue=false,Callback=function(v) aiming=v; end})
MT:CreateToggle({Name="Show FOV",CurrentValue=false,Callback=function(v) showFOV=v end})
MT:CreateToggle({Name="Soft Aim",CurrentValue=false,Callback=function(v) softMode=v end})
MT:CreateToggle({Name="Wall Check",CurrentValue=false,Callback=function(v) wallCheck=v end})
MT:CreateToggle({Name="Team Check",CurrentValue=true,Callback=function(v) teamCheck=v end})
MT:CreateToggle({Name="Instant Aim",CurrentValue=true,Callback=function(v) instantAim=v end})
MT:CreateToggle({Name="Rainbow FOV",CurrentValue=false,Callback=function(v) rainbowFOV=v end})
MT:CreateToggle({Name="Random Part Switching",CurrentValue=false,Callback=function(v) randomPartSwitching=v end})
MT:CreateSlider({Name="Switch Delay",Range={0.1,3},Increment=0.1,CurrentValue=partSwitchDelay,Suffix="s",Callback=function(v) partSwitchDelay=v end})
MT:CreateDropdown({Name="Aim Part",Options=aimPartsList,CurrentOption=aimPart,Callback=function(o) aimPart=o end})
MT:CreateDropdown({Name="Prioritize",Options=prioritizeModes,CurrentOption=prioritizeModes[prioritizeIndex],Callback=function(o) for i,m in ipairs(prioritizeModes) do if m==o then prioritizeIndex=i end end end})
MT:CreateSlider({Name="FOV Radius",Range={10,160},Increment=1,CurrentValue=FOV_RADIUS,Suffix="px",Callback=function(v) FOV_RADIUS=v end})
MT:CreateSlider({Name="FOV Thickness",Range={1,5},Increment=1,CurrentValue=FOV_THICKNESS,Suffix="px",Callback=function(v) FOV_THICKNESS=v end})
MT:CreateColorPicker({Name="FOV Color",Color=customFOVColor,Callback=function(c) customFOVColor=c end})
MT:CreateSlider({Name="Aim Strength",Range={0.1,1},Increment=0.01,CurrentValue=aimStrength,Callback=function(v) aimStrength=v end})
MT:CreateSlider({Name="Prediction",Range={0,0.35},Increment=0.01,CurrentValue=predictionStrength,Callback=function(v) predictionStrength=v end})
MT:CreateSlider({Name="Distance",Range={50,1000},Increment=10,CurrentValue=distanceValue,Suffix="studs",Callback=function(v) distanceValue=v end})
MT:CreateToggle({Name="Infinite Distance",CurrentValue=false,Callback=function(v) infiniteDistance=v end})

-- MiscTab
MST:CreateButton({Name="Fullbright",Callback=function()
    if not fullbrightOn then
        for k,v in pairs(fullbrightSettings) do Lighting[k]=v end
        Rayfield:Notify({Title="Fullbright",Content="Bright ON",Duration=2})
    else
        for k,v in pairs(origLighting) do Lighting[k]=v end
        Rayfield:Notify({Title="Fullbright",Content="Bright OFF",Duration=2})
    end
    fullbrightOn = not fullbrightOn
end})
MST:CreateButton({Name="Load External ESP",Callback=function()
    local success, res = pcall(function() loadstring(game:HttpGet("https://pastebin.com/raw/qBZHFF23"))() end)
    Rayfield:Notify({Title="ESP",Content= success and "Loaded!" or res,Duration=3})
end})
MST:CreateSlider({Name="Camera FOV",Range={40,120},Increment=1,CurrentValue=Camera.FieldOfView,Callback=function(v) Camera.FieldOfView=v end})
MST:CreateInput({Name="Custom KillSound",PlaceholderText="rbxassetid://...",RemoveTextAfterFocusLost=false,Callback=function(v) customKillSoundURL=v end})
MST:CreateToggle({Name="AutoJump",CurrentValue=false,Callback=function(v) autoJumpEnabled=v end})
MST:CreateToggle({Name="Spinbot",CurrentValue=false,Callback=function(v) spinbotEnabled=v end})
MST:CreateToggle({Name="No Recoil",CurrentValue=false,Callback=function(v) noRecoilEnabled=v end})

-- Credits
CTab:CreateParagraph({Title="Created by",Content="lalala (InstantAim PRO)"})
CTab:CreateButton({Name="Discord: discord.gg/qP7CFMFEax",Callback=function()
    setclipboard("https://discord.gg/qP7CFMFEax")
    Rayfield:Notify({Title="Copied!",Content="Link copied!",Duration=2})
end})
