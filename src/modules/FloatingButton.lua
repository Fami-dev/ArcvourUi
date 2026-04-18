local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local FloatingButton = {}
FloatingButton.__index = FloatingButton

function FloatingButton.new(Config)
    local self = setmetatable({}, FloatingButton)
    
    self.Config = Config or {}
    self.Window = Config.Window
    self.Icon = Config.Icon or "rbxassetid://90566677928169"
    self.Size = Config.Size or UDim2.new(0, 40, 0, 40)
    self.Position = Config.Position or UDim2.new(0, 70, 0, 70)
    self.PrimaryColor = Config.PrimaryColor or Color3.fromHex("#8C46FF")
    self.SecondaryColor = Config.SecondaryColor or Color3.fromHex("#BE78FF")
    self.BackgroundColor = Config.BackgroundColor or Color3.fromHex("#1E142D")
    
    self.Gui = nil
    self.Button = nil
    self.Signals = {}
    
    self:Init()
    
    return self
end

function FloatingButton:Init()
    local floatingButtonGui = Instance.new("ScreenGui")
    floatingButtonGui.Name = "WindUI_FloatingButton"
    floatingButtonGui.IgnoreGuiInset = true
    floatingButtonGui.ResetOnSpawn = false
    -- Try to parent to CoreGui for security/persistence, fallback to PlayerGui
    local success, _ = pcall(function() floatingButtonGui.Parent = CoreGui end)
    if not success then
        floatingButtonGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    floatingButtonGui.Enabled = false -- Helper starts hidden
    
    self.Gui = floatingButtonGui

    local floatingButton = Instance.new("ImageButton")
    floatingButton.Size = self.Size
    floatingButton.Position = self.Position
    floatingButton.BackgroundColor3 = self.BackgroundColor
    floatingButton.Image = self.Icon
    floatingButton.Name = "Toggle"
    floatingButton.AutoButtonColor = true
    floatingButton.ClipsDescendants = true
    floatingButton.Parent = floatingButtonGui
    
    self.Button = floatingButton

    local corner = Instance.new("UICorner", floatingButton)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = self.SecondaryColor
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = floatingButton

    local gradientStroke = Instance.new("UIGradient")
    gradientStroke.Color = ColorSequence.new { 
        ColorSequenceKeypoint.new(0, self.PrimaryColor), 
        ColorSequenceKeypoint.new(0.5, self.SecondaryColor),
        ColorSequenceKeypoint.new(1, self.PrimaryColor)
    }
    gradientStroke.Rotation = 0
    gradientStroke.Parent = stroke
    
    -- Rotation Animation
    task.spawn(function()
        while floatingButtonGui and floatingButtonGui.Parent do
            for i = 0, 360, 2 do
                if not floatingButtonGui or not floatingButtonGui.Parent then break end
                gradientStroke.Rotation = i
                task.wait(0.01)
            end
        end
    end)
    
    -- Shimmer Effect
    local shimmerFrame = Instance.new("Frame")
    shimmerFrame.Name = "Shimmer"
    shimmerFrame.Size = UDim2.new(0, 15, 1, 0)
    shimmerFrame.Position = UDim2.new(-0.5, 0, 0, 0)
    shimmerFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    shimmerFrame.BackgroundTransparency = 0.7
    shimmerFrame.BorderSizePixel = 0
    shimmerFrame.ZIndex = 10
    shimmerFrame.Parent = floatingButton

    local shimmerGradient = Instance.new("UIGradient")
    shimmerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.3, 0.5),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.7, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    shimmerGradient.Rotation = 25
    shimmerGradient.Parent = shimmerFrame

    local shimmerCorner = Instance.new("UICorner", shimmerFrame)
    shimmerCorner.CornerRadius = UDim.new(0, 4)

    task.spawn(function()
        while floatingButtonGui and floatingButtonGui.Parent do
            shimmerFrame.Position = UDim2.new(-0.5, 0, 0, 0)
            local tween = TweenService:Create(shimmerFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1.5, 0, 0, 0)
            })
            tween:Play()
            tween.Completed:Wait()
            task.wait(2)
        end
    end)
    
    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    local wasDragged = false
    local dragThreshold = 5
    local originalSize = self.Size

    floatingButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            wasDragged = false
            dragStart = input.Position
            startPos = floatingButton.Position
            
            TweenService:Create(floatingButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 8, originalSize.Y.Scale, originalSize.Y.Offset + 8)
            }):Play()

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    TweenService:Create(floatingButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = originalSize
                    }):Play()
                end
            end)
        end
    end)

    floatingButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > dragThreshold or math.abs(delta.Y) > dragThreshold then
                wasDragged = true
            end
            floatingButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    floatingButton.MouseButton1Click:Connect(function()
        if not wasDragged then
            self:Hide()
            if self.Window then
                -- Try to access Window Open/Close methods if they exist, or just toggle property
                 -- Check if Window is a wrapper or the raw Instance
                 -- Assuming standard WindUI Window object structure
                 if self.Window.Open then
                     self.Window:Open()
                 end
            end
        end
    end)
end

function FloatingButton:Show()
    if self.Gui then
        self.Gui.Enabled = true
        self.Button.Visible = true
    end
end

function FloatingButton:Hide()
    if self.Gui then
        self.Gui.Enabled = false
    end
end

function FloatingButton:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
    for _, signal in ipairs(self.Signals) do
        signal:Disconnect()
    end
end

return FloatingButton
