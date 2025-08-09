-- LalaUI - Modular Roblox UI Library
-- A simple UI library inspired by Rayfield for Roblox
-- Usage: local LalaUI = require(script.ModuleScript)
--        LalaUI:CreateWindow({Name = "My Window"})
--        LalaUI:CreateButton({Name = "Click Me", Callback = function() print("Clicked!") end})

local LalaUI = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = nil
local mainFrame = nil
local contentFrame = nil
local elementCount = 0

-- Default theme colors
local theme = {
    Background = Color3.fromRGB(25, 25, 35),
    Secondary = Color3.fromRGB(35, 35, 45),
    Accent = Color3.fromRGB(100, 150, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Success = Color3.fromRGB(100, 255, 150),
    Warning = Color3.fromRGB(255, 200, 100),
    Error = Color3.fromRGB(255, 100, 100)
}

-- Utility functions
local function createCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    return corner
end

local function createStroke(color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or theme.Secondary
    stroke.Thickness = thickness or 1
    return stroke
end

local function tweenProperty(object, property, value, duration)
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.2), {[property] = value})
    tween:Play()
    return tween
end

-- Initialize the main GUI
local function initializeGui()
    if mainGui then return end
    
    -- Create ScreenGui
    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "LalaUI"
    mainGui.ResetOnSpawn = false
    mainGui.Parent = playerGui
    
    -- Create main frame (window)
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = mainGui
    
    -- Add corner and stroke to main frame
    createCorner(8).Parent = mainFrame
    createStroke(theme.Secondary, 2).Parent = mainFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = theme.Secondary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    createCorner(8).Parent = titleBar
    
    -- Create title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "LalaUI"
    titleLabel.TextColor3 = theme.Text
    titleLabel.TextScaled = true
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleBar
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = theme.Error
    closeButton.BorderSizePixel = 0
    closeButton.Text = "×"
    closeButton.TextColor3 = theme.Text
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    createCorner(15).Parent = closeButton
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        tweenProperty(mainGui, "Enabled", false, 0.3)
    end)
    
    -- Create content frame with scrolling
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -60)
    contentContainer.Position = UDim2.new(0, 10, 0, 50)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.ScrollBarThickness = 6
    contentContainer.ScrollBarImageColor3 = theme.Accent
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentContainer.Parent = mainFrame
    
    -- Create content frame
    contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = contentContainer
    
    -- Add UIListLayout to content frame
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = contentFrame
    
    -- Update canvas size when content changes
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Make window draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Main Functions

-- CreateWindow: Initialize the main window
-- Usage: LalaUI:CreateWindow({Name = "Window Title", Icon = "rbxassetid://123456", Theme = "Dark"})
function LalaUI:CreateWindow(config)
    config = config or {}
    
    initializeGui()
    
    -- Update window title
    if config.Name then
        mainFrame.TitleBar.TitleLabel.Text = config.Name
    end
    
    -- Apply custom theme if provided
    if config.Theme then
        if config.Theme == "Light" then
            theme.Background = Color3.fromRGB(240, 240, 250)
            theme.Secondary = Color3.fromRGB(230, 230, 240)
            theme.Text = Color3.fromRGB(0, 0, 0)
            theme.TextSecondary = Color3.fromRGB(100, 100, 100)
        end
    end
    
    -- Show window with animation
    mainGui.Enabled = true
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    tweenProperty(mainFrame, "Size", UDim2.new(0, 400, 0, 500), 0.5)
    
    return self
end

-- CreateButton: Create a clickable button
-- Usage: LalaUI:CreateButton({Name = "Button Text", Icon = "rbxassetid://123456", Color = Color3.new(1,0,0), Callback = function() print("Clicked!") end})
function LalaUI:CreateButton(config)
    if not contentFrame then
        warn("LalaUI: You must create a window first using CreateWindow()")
        return
    end
    
    config = config or {}
    elementCount = elementCount + 1
    
    -- Create button frame
    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Name = "Button_" .. elementCount
    buttonFrame.Size = UDim2.new(1, -20, 0, 45)
    buttonFrame.BackgroundColor3 = config.Color or theme.Secondary
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Text = ""
    buttonFrame.LayoutOrder = elementCount
    buttonFrame.Parent = contentFrame
    
    createCorner(6).Parent = buttonFrame
    
    -- Add outline if specified
    if config.OutlineColor then
        createStroke(config.OutlineColor, 2).Parent = buttonFrame
    end
    
    -- Create button label
    local buttonLabel = Instance.new("TextLabel")
    buttonLabel.Name = "Label"
    buttonLabel.Size = UDim2.new(1, config.Icon and -40 or -20, 1, 0)
    buttonLabel.Position = UDim2.new(0, config.Icon and 35 or 10, 0, 0)
    buttonLabel.BackgroundTransparency = 1
    buttonLabel.Text = config.Name or "Button"
    buttonLabel.TextColor3 = theme.Text
    buttonLabel.TextScaled = true
    buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
    buttonLabel.Font = Enum.Font.Gotham
    buttonLabel.Parent = buttonFrame
    
    -- Add icon if specified
    if config.Icon then
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Name = "Icon"
        iconLabel.Size = UDim2.new(0, 20, 0, 20)
        iconLabel.Position = UDim2.new(0, 10, 0.5, -10)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Image = config.Icon
        iconLabel.ImageColor3 = theme.Text
        iconLabel.Parent = buttonFrame
    end
    
    -- Button animations and functionality
    buttonFrame.MouseEnter:Connect(function()
        tweenProperty(buttonFrame, "BackgroundColor3", Color3.fromRGB(
            math.min(255, (config.Color or theme.Secondary).R * 255 + 20),
            math.min(255, (config.Color or theme.Secondary).G * 255 + 20),
            math.min(255, (config.Color or theme.Secondary).B * 255 + 20)
        ), 0.2)
    end)
    
    buttonFrame.MouseLeave:Connect(function()
        tweenProperty(buttonFrame, "BackgroundColor3", config.Color or theme.Secondary, 0.2)
    end)
    
    buttonFrame.MouseButton1Click:Connect(function()
        -- Click animation
        tweenProperty(buttonFrame, "Size", UDim2.new(1, -25, 0, 40), 0.1)
        wait(0.1)
        tweenProperty(buttonFrame, "Size", UDim2.new(1, -20, 0, 45), 0.1)
        
        -- Execute callback
        if config.Callback then
            config.Callback()
        end
    end)
    
    return buttonFrame
end

-- CreateToggle: Create a toggle switch
-- Usage: LalaUI:CreateToggle({Name = "Toggle Feature", Default = false, Callback = function(state) print("Toggle:", state) end})
function LalaUI:CreateToggle(config)
    if not contentFrame then
        warn("LalaUI: You must create a window first using CreateWindow()")
        return
    end
    
    config = config or {}
    elementCount = elementCount + 1
    
    local isToggled = config.Default or false
    
    -- Create toggle frame
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "Toggle_" .. elementCount
    toggleFrame.Size = UDim2.new(1, -20, 0, 45)
    toggleFrame.BackgroundColor3 = theme.Secondary
    toggleFrame.BorderSizePixel = 0
    toggleFrame.LayoutOrder = elementCount
    toggleFrame.Parent = contentFrame
    
    createCorner(6).Parent = toggleFrame
    
    -- Create toggle label
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Name = "Label"
    toggleLabel.Size = UDim2.new(1, -60, 1, 0)
    toggleLabel.Position = UDim2.new(0, 10, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = config.Name or "Toggle"
    toggleLabel.TextColor3 = theme.Text
    toggleLabel.TextScaled = true
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.Parent = toggleFrame
    
    -- Create toggle switch
    local toggleSwitch = Instance.new("TextButton")
    toggleSwitch.Name = "Switch"
    toggleSwitch.Size = UDim2.new(0, 45, 0, 25)
    toggleSwitch.Position = UDim2.new(1, -50, 0.5, -12.5)
    toggleSwitch.BackgroundColor3 = isToggled and theme.Success or Color3.fromRGB(60, 60, 70)
    toggleSwitch.BorderSizePixel = 0
    toggleSwitch.Text = ""
    toggleSwitch.Parent = toggleFrame
    
    createCorner(12).Parent = toggleSwitch
    
    -- Create toggle knob
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Name = "Knob"
    toggleKnob.Size = UDim2.new(0, 19, 0, 19)
    toggleKnob.Position = UDim2.new(0, isToggled and 23 or 3, 0, 3)
    toggleKnob.BackgroundColor3 = theme.Text
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Parent = toggleSwitch
    
    createCorner(9).Parent = toggleKnob
    
    -- Toggle functionality
    toggleSwitch.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        
        -- Animate switch
        tweenProperty(toggleSwitch, "BackgroundColor3", isToggled and theme.Success or Color3.fromRGB(60, 60, 70), 0.2)
        tweenProperty(toggleKnob, "Position", UDim2.new(0, isToggled and 23 or 3, 0, 3), 0.2)
        
        -- Execute callback
        if config.Callback then
            config.Callback(isToggled)
        end
    end)
    
    return {Frame = toggleFrame, GetValue = function() return isToggled end}
end

-- CreateSlider: Create a value slider
-- Usage: LalaUI:CreateSlider({Name = "Volume", Min = 0, Max = 100, Default = 50, Callback = function(value) print("Value:", value) end})
function LalaUI:CreateSlider(config)
    if not contentFrame then
        warn("LalaUI: You must create a window first using CreateWindow()")
        return
    end
    
    config = config or {}
    elementCount = elementCount + 1
    
    local min = config.Min or 0
    local max = config.Max or 100
    local currentValue = config.Default or min
    local dragging = false
    
    -- Create slider frame
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "Slider_" .. elementCount
    sliderFrame.Size = UDim2.new(1, -20, 0, 55)
    sliderFrame.BackgroundColor3 = theme.Secondary
    sliderFrame.BorderSizePixel = 0
    sliderFrame.LayoutOrder = elementCount
    sliderFrame.Parent = contentFrame
    
    createCorner(6).Parent = sliderFrame
    
    -- Create slider label
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Name = "Label"
    sliderLabel.Size = UDim2.new(0.7, 0, 0, 20)
    sliderLabel.Position = UDim2.new(0, 10, 0, 5)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = config.Name or "Slider"
    sliderLabel.TextColor3 = theme.Text
    sliderLabel.TextScaled = true
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.Parent = sliderFrame
    
    -- Create value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0.3, -10, 0, 20)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(currentValue)
    valueLabel.TextColor3 = theme.Accent
    valueLabel.TextScaled = true
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = sliderFrame
    
    -- Create slider track
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Name = "Track"
    sliderTrack.Size = UDim2.new(1, -20, 0, 6)
    sliderTrack.Position = UDim2.new(0, 10, 1, -15)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = sliderFrame
    
    createCorner(3).Parent = sliderTrack
    
    -- Create slider fill
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = theme.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack
    
    createCorner(3).Parent = sliderFill
    
    -- Create slider knob
    local sliderKnob = Instance.new("TextButton")
    sliderKnob.Name = "Knob"
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new((currentValue - min) / (max - min), -8, 0, -5)
    sliderKnob.BackgroundColor3 = theme.Text
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Text = ""
    sliderKnob.Parent = sliderTrack
    
    createCorner(8).Parent = sliderKnob
    
    -- Slider functionality
    local function updateSlider(input)
        if not dragging then return end
        
        local relativeX = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(min + (max - min) * relativeX)
        
        -- Update UI
        valueLabel.Text = tostring(currentValue)
        tweenProperty(sliderFill, "Size", UDim2.new(relativeX, 0, 1, 0), 0.1)
        tweenProperty(sliderKnob, "Position", UDim2.new(relativeX, -8, 0, -5), 0.1)
        
        -- Execute callback
        if config.Callback then
            config.Callback(currentValue)
        end
    end
    
    sliderKnob.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputChanged:Connect(updateSlider)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Click on track to jump
    sliderTrack.MouseButton1Click:Connect(function(input)
        local relativeX = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(min + (max - min) * relativeX)
        
        valueLabel.Text = tostring(currentValue)
        tweenProperty(sliderFill, "Size", UDim2.new(relativeX, 0, 1, 0), 0.2)
        tweenProperty(sliderKnob, "Position", UDim2.new(relativeX, -8, 0, -5), 0.2)
        
        if config.Callback then
            config.Callback(currentValue)
        end
    end)
    
    return {Frame = sliderFrame, GetValue = function() return currentValue end, SetValue = function(value)
        currentValue = math.clamp(value, min, max)
        local relativeX = (currentValue - min) / (max - min)
        valueLabel.Text = tostring(currentValue)
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        sliderKnob.Position = UDim2.new(relativeX, -8, 0, -5)
    end}
end

-- Additional utility functions
function LalaUI:Destroy()
    if mainGui then
        mainGui:Destroy()
        mainGui = nil
        mainFrame = nil
        contentFrame = nil
        elementCount = 0
    end
end

function LalaUI:Hide()
    if mainGui then
        mainGui.Enabled = false
    end
end

function LalaUI:Show()
    if mainGui then
        mainGui.Enabled = true
    end
end

return LalaUI
