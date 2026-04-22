local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Intro = {}

function Intro.Play(Config)
    Config = Config or {}
    local Title = Config.Title or "WindUI"
    local Icon = Config.Icon or "rbxassetid://90566677928169"
    local PrimaryColor = Config.PrimaryColor or Color3.fromHex("#8C46FF")
    local SecondaryColor = Config.SecondaryColor or Color3.fromHex("#BE78FF")
    local BackgroundColor = Config.BackgroundColor or Color3.fromHex("#1E142D")

    local introScreenGui, introBlur, introFrame, introBg, introGlowFrame, introLogo, introLetters = nil, nil, nil, nil, nil, nil, {}
    
    -- Blur Effect
    introBlur = Instance.new("BlurEffect", Lighting)
    introBlur.Size = 0
    TweenService:Create(introBlur, TweenInfo.new(0.5), {Size = 24}):Play()

    -- GUI Setup
    introScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    introScreenGui.Name = "WindUI_Intro"
    introScreenGui.ResetOnSpawn = false
    introScreenGui.IgnoreGuiInset = true
    introScreenGui.DisplayOrder = 10000 -- Ensure it's on top

    introFrame = Instance.new("Frame", introScreenGui)
    introFrame.Size = UDim2.new(1, 0, 1, 0)
    introFrame.BackgroundTransparency = 1

    -- Background
    introBg = Instance.new("Frame", introFrame)
    introBg.Size = UDim2.new(1, 0, 1, 0)
    introBg.BackgroundColor3 = BackgroundColor
    introBg.BackgroundTransparency = 1
    introBg.ZIndex = 0
    TweenService:Create(introBg, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
    
    -- Glow Effects
    introGlowFrame = Instance.new("Frame", introFrame)
    introGlowFrame.Size = UDim2.new(1, 0, 1, 0)
    introGlowFrame.BackgroundTransparency = 1
    introGlowFrame.ZIndex = 1

    local glowAsset = "rbxassetid://5036224375" 
    
    local glowParts = {
        Top = { Size = UDim2.new(1, 40, 0, 100), Position = UDim2.new(0.5, 0, 0, 0) },
        Bottom = { Size = UDim2.new(1, 40, 0, 100), Position = UDim2.new(0.5, 0, 1, 0) },
        Left = { Size = UDim2.new(0, 100, 1, 40), Position = UDim2.new(0, 0, 0.5, 0) },
        Right = { Size = UDim2.new(0, 100, 1, 40), Position = UDim2.new(1, 0, 0.5, 0) }
    }

    for _, props in pairs(glowParts) do
        local glow = Instance.new("ImageLabel", introGlowFrame)
        glow.Image = glowAsset
        glow.ImageColor3 = PrimaryColor
        glow.ImageTransparency = 1
        glow.Size = props.Size
        glow.Position = props.Position
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        TweenService:Create(glow, TweenInfo.new(1), {ImageTransparency = 0.5}):Play()
    end

    -- Logo Animation
    introLogo = Instance.new("ImageLabel", introFrame)
    introLogo.Image = Icon
    introLogo.Size = UDim2.new(0, 150, 0, 150)
    introLogo.Position = UDim2.new(0.5, 0, 0.3, 0)
    introLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    introLogo.BackgroundTransparency = 1
    introLogo.ImageTransparency = 1
    introLogo.Rotation = 0
    introLogo.ZIndex = 2

    TweenService:Create(introLogo, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0, Size = UDim2.new(0, 200, 0, 200), Rotation = 15 }):Play()
    
    task.delay(0.5, function()
        TweenService:Create(introLogo, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 150, 0, 150), Rotation = 0 }):Play()
    end)

    -- Text Animation
    local word = Title
    local introLetters = {}
    
    task.wait(1)

    -- Calculate total width to center properly
    local letterWidth = 45
    -- Simple centering logic
    local startXOffset = 0 
    
    for i = 1, #word do
        local char = word:sub(i, i)
        -- Only animate visible characters
        if char:match("%S") then 
            local label = Instance.new("TextLabel")
            label.Text = char
            label.Font = Enum.Font.GothamBlack
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 1
            label.TextTransparency = 1
            label.TextScaled = false
            label.TextSize = 30
            label.Size = UDim2.new(0, 60, 0, 60)
            label.AnchorPoint = Vector2.new(0.5, 0.5)
            
            -- Estimate position based on character index relative to center
            local offset = (i - (#word / 2 + 0.5)) * letterWidth
            label.Position = UDim2.new(0.5, offset, 0.6, 0)
            
            label.BackgroundTransparency = 1
            label.Parent = introFrame
            label.ZIndex = 2
            
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({ 
                ColorSequenceKeypoint.new(0, PrimaryColor), 
                ColorSequenceKeypoint.new(1, SecondaryColor) 
            })
            gradient.Rotation = 90
            gradient.Parent = label
            
            TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 0, TextSize = 60}):Play()
            table.insert(introLetters, label)
            task.wait(0.15)
        end
    end
    
    task.wait(1.5)

    -- Exit Animation
    for _, label in ipairs(introLetters) do
        TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1, TextSize = 20}):Play()
    end
    for _, glow in ipairs(introGlowFrame:GetChildren()) do
        if glow:IsA("ImageLabel") then
            TweenService:Create(glow, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
        end
    end
    TweenService:Create(introBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(introBlur, TweenInfo.new(0.5), {Size = 0}):Play()
    TweenService:Create(introLogo, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
    
    task.wait(0.6)
    pcall(function() introScreenGui:Destroy() end)
    pcall(function() introBlur:Destroy() end)
end

return Intro
