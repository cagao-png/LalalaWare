-- InstantAim PRO - Mobile Target Lock Button (draggable, toggle to appear), DeathSound (plays when ANY player dies, toggle)

-- Load Rayfield (official via sirius.menu)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Services and Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local UIS = game:GetService("UserInputService")

-- Settings
local FOV_RADIUS = 60
local FOV_THICKNESS = 1
local aiming, showFOV, softMode, wallCheck, teamCheck, rainbowFOV = false, false, false, false, true, false
local instantAim = true
local aimPart = "Head"
local aimStrength = 0.14
local predictionStrength = 0.0
local predictionAuto = false
local prioritizeModes = {"default", "nearest", "low hp", "high hp"}
local prioritizeIndex = 1
local fullbrightOn = false
local distanceValue = 1000
local infiniteDistance = false
local customFOVColor = Color3.new(1, 1, 0)
local deathSoundEnabled = false
local customDeathSoundURL = "rbxassetid://7738210779" -- Default sound
local autoJumpEnabled = false
local noRecoilEnabled = false

-- Target Lock
local targetLockEnabled = false
local lockedTarget = nil
local targetLockKey = Enum.KeyCode.E
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local showMobileTargetLockButton = false
local mobileButtonObject = nil

-- Mobile Target Lock Button implementation (draggable, visible only when toggled in menu)
if isMobile then
    local function createMobileButton()
        if mobileButtonObject then mobileButtonObject.Enabled = true; return end
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "TargetLockMobileButton"
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = game:GetService("CoreGui")

        local button = Instance.new("TextButton")
        button.Name = "TargetLockButton"
        button.Size = UDim2.new(0, 80, 0, 80)
        button.Position = UDim2.new(0.85, 0, 0.6, 0)
        button.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        button.Text = "Lock"
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.TextColor3 = Color3.fromRGB(0,0,0)
        button.Visible = true
        button.Parent = ScreenGui

        mobileButtonObject = ScreenGui

        -- Draggable logic
        local dragging = false
        local dragStart, startPos
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = button.Position
            end
        end)
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        button.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStart
                local newX = math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - 80)
                local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - 80)
                button.Position = UDim2.new(0, newX, 0, newY)
            end
        end)

        button.MouseButton1Click:Connect(function()
            if not targetLockEnabled then
                -- Lock on player under crosshair
                local closest = nil
                local minDist = math.huge
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                        local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = player
                            end
                        end
                    end
                end
                if closest then
                    lockedTarget = closest
                    targetLockEnabled = true
                    button.Text = "Unlock"
                    button.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                end
            else
                lockedTarget = nil
                targetLockEnabled = false
                button.Text = "Lock"
                button.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            end
        end)
    end

    local function removeMobileButton()
        if mobileButtonObject then
            mobileButtonObject:Destroy()
            mobileButtonObject = nil
        end
    end

    -- Show/hide via toggle
    RunService.RenderStepped:Connect(function()
        if showMobileTargetLockButton then
            if not mobileButtonObject then
                createMobileButton()
            end
        else
            if mobileButtonObject then
                removeMobileButton()
            end
        end
    end)
end

-- Random Part Switching
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

-- Utility Functions
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
    if targetLockEnabled and lockedTarget then
        return lockedTarget
    end
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

-- DeathSound on ANY player death
local function playDeathSound()
    if deathSoundEnabled then
        local soundId = customDeathSoundURL ~= "" and customDeathSoundURL or "rbxassetid://7738210779"
        local sound = Instance.new("Sound", SoundService)
        sound.SoundId = soundId
        sound.Volume = 1
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end
end

local function setupDeathListeners(player)
    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function()
                playDeathSound()
                if lockedTarget == player then
                    lockedTarget = nil
                    targetLockEnabled = false
                    if isMobile and mobileButtonObject and mobileButtonObject:FindFirstChild("TargetLockButton") then
                        local button = mobileButtonObject.TargetLockButton
                        button.Text = "Lock"
                        button.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                    end
                end
            end)
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    setupDeathListeners(p)
end

Players.PlayerAdded:Connect(setupDeathListeners)

Players.PlayerRemoving:Connect(function(p)
    if lockedTarget == p then
        lockedTarget = nil
        targetLockEnabled = false
        if isMobile and mobileButtonObject and mobileButtonObject:FindFirstChild("TargetLockButton") then
            local button = mobileButtonObject.TargetLockButton
            button.Text = "Lock"
            button.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        end
    end
end)

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
    circle.Color = rainbowFOV and Color3.fromHSV(tick() % 5 / 5, 1, 1) or customFOVColor
end)

-- Prediction Auto Option (experimental)
local function getPredictionAuto(p)
    if not p or not p.Character then return 0 end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Velocity.Magnitude * 0.012 -- tweak this formula for your game
    end
    return 0
end

-- Aimbot handler
RunService.RenderStepped:Connect(function()
    if aiming then
        local target = getClosestPlayer()
        if target and target.Character then
            if randomPartSwitching and tick() - lastSwitchTime >= partSwitchDelay then
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
            else
                currentAimPart = aimPart
            end
            local part = target.Character:FindFirstChild(currentAimPart)
            if part then
                local predicted = part.Position
                local root = target.Character:FindFirstChild("HumanoidRootPart")
                local predStrength = predictionAuto and getPredictionAuto(target) or predictionStrength
                if predStrength > 0 and root then
                    predicted += root.Velocity * predStrength
                end
                local dir = (predicted - Camera.CFrame.Position).Unit
                local look = softMode and Camera.CFrame.LookVector:Lerp(dir, aimStrength).Unit or dir
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + look)
            end
        end
    end
end)

-- AutoJump handler
RunService.RenderStepped:Connect(function()
    if autoJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Jump = true
        end
    end
end)

-- No Recoil (dummy patch)
local function patchNoRecoil()
    -- Implement your game's no recoil patch here.
    -- Example: game:GetService("ReplicatedStorage").Recoil.Disabled = noRecoilEnabled
end

-- Target Lock - PC (keybind)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not isMobile then
        if input.KeyCode == targetLockKey then
            if not targetLockEnabled then
                -- Lock on player under crosshair
                local closest = nil
                local minDist = math.huge
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                        local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = player
                            end
                        end
                    end
                end
                if closest then
                    lockedTarget = closest
                    targetLockEnabled = true
                end
            else
                lockedTarget = nil
                targetLockEnabled = false
            end
        end
    end
end)

-- Rayfield UI
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

local MainTab = Window:CreateTab("Main", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local OtherTab = Window:CreateTab("Other Scripts", 4483362458)
local CreditTab = Window:CreateTab("Credits", 4483362458)

-- MainTab
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
MainTab:CreateToggle({Name="Prediction Auto", CurrentValue=false, Callback=function(v) predictionAuto=v end})
MainTab:CreateSlider({Name="Distance", Range={50,1000}, Increment=10, CurrentValue=distanceValue, Suffix="studs", Callback=function(v) distanceValue=v end})
MainTab:CreateToggle({Name="Infinite Distance", CurrentValue=false, Callback=function(v) infiniteDistance=v end})

-- Target Lock Section
MainTab:CreateToggle({
    Name = "Target Lock",
    CurrentValue = false,
    Callback = function(v)
        targetLockEnabled = v
        if not v then
            lockedTarget = nil
            if isMobile and mobileButtonObject and mobileButtonObject:FindFirstChild("TargetLockButton") then
                local button = mobileButtonObject.TargetLockButton
                button.Text = "Lock"
                button.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            end
        end
    end
})
MainTab:CreateInput({
    Name = "PC Target Lock Keybind",
    PlaceholderText = "E",
    RemoveTextAfterFocusLost = true,
    Callback = function(v)
        if Enum.KeyCode[v] then
            targetLockKey = Enum.KeyCode[v]
        end
    end
})
MainTab:CreateToggle({
    Name = "Mobile Target Lock Button",
    CurrentValue = false,
    Callback = function(v)
        showMobileTargetLockButton = v
    end
})
MainTab:CreateParagraph({
    Title = "Target Lock Info",
    Content = "PC: Press the selected keybind. Mobile: Toggle the simple yellow button in settings. Target Lock locks onto the player under crosshair and won't unlock until they die or leave."
})

-- MiscTab
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
            Rayfield:Notify({Title = "ESP", Content = "ESP script loaded successfully!", Duration = 3})
        else
            Rayfield:Notify({Title = "ESP Error", Content = tostring(result), Duration = 4})
        end
    end
})

MiscTab:CreateButton({
    Name = "Stretched Resolution",
    Callback = function()
        local success, result = pcall(function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-OP-STRETCHED-RESOLUTION-14202"))()
        end)
        if success then
            Rayfield:Notify({Title = "Stretched Resolution", Content = "Stretched Resolution script loaded! It may take time to take effect and is NOT reversible unless you rejoin.", Duration = 6})
        else
            Rayfield:Notify({Title = "Stretched Resolution Error", Content = tostring(result), Duration = 4})
        end
    end
})
MiscTab:CreateParagraph({
    Title = "Notice",
    Content = "Stretched Resolution may take time to take effect. It is NOT reversible except by rejoining the game."
})

MiscTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Callback = function(v)
        noRecoilEnabled = v
        patchNoRecoil()
    end
})

MiscTab:CreateSlider({
    Name = "Camera FOV",
    Range = {40, 120},
    Increment = 1,
    CurrentValue = Camera.FieldOfView,
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

MiscTab:CreateInput({
    Name = "Custom DeathSound (SoundId)",
    PlaceholderText = "rbxassetid://7738210779",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        customDeathSoundURL = v
    end
})

MiscTab:CreateToggle({
    Name = "DeathSound (Plays when any player dies)",
    CurrentValue = false,
    Callback = function(v)
        deathSoundEnabled = v
    end
})

MiscTab:CreateToggle({
    Name = "AutoJump",
    CurrentValue = false,
    Callback = function(v)
        autoJumpEnabled = v
    end
})

-- Other Scripts Tab
OtherTab:CreateButton({
    Name = "Ayka Hub",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/j1DCpbN1"))()
        Rayfield:Notify({Title = "Ayka Hub", Content = "Ayka Hub loaded!", Duration = 3})
    end
})
OtherTab:CreateButton({
    Name = "Duck Hub (RIVALS)",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/RIVALS-Duck-Hub-29794"))()
        Rayfield:Notify({Title = "Duck Hub", Content = "Duck Hub loaded!", Duration = 3})
    end
})
OtherTab:CreateButton({
    Name = "Prision Bypass UFO",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Juanko-Scripts/Roblox-scripts/main/Prision%20Bypass%20Ufo"))()
        Rayfield:Notify({Title = "Prision Bypass UFO", Content = "Prision Bypass UFO loaded!", Duration = 3})
    end
})

-- CreditTab
CreditTab:CreateParagraph({Title = "Created by", Content = "lalala (InstantAim PRO)"})
CreditTab:CreateButton({
    Name = "Discord: discord.gg/qP7CFMFEax",
    Callback = function()
        setclipboard("https://discord.gg/qP7CFMFEax")
        Rayfield:Notify({Title = "Copied!", Content = "Discord link copied to clipboard!", Duration = 3})
    end
})
CreditTab:CreateButton({
    Name = "Copy lalala's site",
    Callback = function()
        setclipboard("https://ymerch.github.io/lalala/")
        Rayfield:Notify({Title = "Copied!", Content = "lalala's site copied to clipboard!", Duration = 3})
    end
})
CreditTab:CreateButton({
    Name = "Hehe",
    Callback = function()
        local sound = Instance.new("Sound", SoundService)
        sound.SoundId = "rbxassetid://7738210779"
        sound.Volume = 1
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end
})
