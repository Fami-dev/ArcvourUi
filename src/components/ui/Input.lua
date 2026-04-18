local Input = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween


function Input.New(Placeholder, Icon, Parent, Type, Callback, OnChange, Radius, ClearTextOnFocus, Validation)
    Type = Type or "Input"
    local Radius = Radius or 10
    local IconInputFrame
    if Icon and Icon ~= "" then
        IconInputFrame = New("ImageLabel", {
            Image = Creator.Icon(Icon)[1],
            ImageRectSize = Creator.Icon(Icon)[2].ImageRectSize,
            ImageRectOffset = Creator.Icon(Icon)[2].ImageRectPosition,
            Size = UDim2.new(0,24-3,0,24-3),
            BackgroundTransparency = 1,
            ThemeTag = {
                ImageColor3 = "Icon",
            }
        })
    end
    
    local isMulti = Type ~= "Input"
    
    local TextBox = New("TextBox", {
        BackgroundTransparency = 1,
        TextSize = 17,
        FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
        Size = UDim2.new(1,IconInputFrame and -29 or 0,1,0),
        PlaceholderText = Placeholder,
        ClearTextOnFocus = ClearTextOnFocus or false,
        ClipsDescendants = true,
        TextWrapped = isMulti,
        MultiLine = isMulti,
        TextXAlignment = "Left",
        TextYAlignment = Type == "Input" and "Center" or "Top",
        --AutomaticSize = "XY",
        ThemeTag = {
            PlaceholderColor3 = "PlaceholderText",
            TextColor3 = "Text",
        },
    })
    
    local BorderFrame
    BorderFrame = Creator.NewRoundFrame(Radius, "Glass-1", {
        ThemeTag = {
            ImageColor3 = "Outline",
        },
        Size = UDim2.new(1,0,1,0),
        ImageTransparency = .75,
    })

    -- Background merah untuk error state
    local ErrorBg = Creator.NewRoundFrame(Radius, "Squircle", {
        ImageColor3 = Color3.fromRGB(255, 60, 60),
        Size = UDim2.new(1,0,1,0),
        ImageTransparency = 1, -- hidden by default
        Name = "ErrorBg",
        ZIndex = 0,
    })

    local InputFrame = New("Frame", {
        Size = UDim2.new(1,0,0,42),
        Parent = Parent,
        BackgroundTransparency = 1
    }, {
        New("Frame", {
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
        }, {
            Creator.NewRoundFrame(Radius, "Squircle", {
                ThemeTag = {
                    ImageColor3 = "Accent",
                },
                Size = UDim2.new(1,0,1,0),
                ImageTransparency = .97,
            }),
            ErrorBg,
            BorderFrame,
            Creator.NewRoundFrame(Radius, "Squircle", {
                Size = UDim2.new(1,0,1,0),
                Name = "Frame",
                ImageColor3 = Color3.new(1,1,1),
                ImageTransparency = .95
            }, {
                New("UIPadding", {
                    PaddingTop = UDim.new(0,Type == "Input" and 0 or 12),
                    PaddingLeft = UDim.new(0,12),
                    PaddingRight = UDim.new(0,12),
                    PaddingBottom = UDim.new(0,Type == "Input" and 0 or 12),
                }),
                New("UIListLayout", {
                    FillDirection = "Horizontal",
                    Padding = UDim.new(0,8),
                    VerticalAlignment = Type == "Input" and "Center" or "Top",
                    HorizontalAlignment = "Left",
                }),
                IconInputFrame,
                TextBox,
            })
        })
    })

    -- Terapkan MaxLength via Roblox native property (hard limit, tidak bisa diketik lebih)
    if Validation and Validation.MaxLength then
        TextBox.MaxVisibleGraphemes = Validation.MaxLength
        -- Roblox tidak punya MaxLength native, kita pakai pendekatan lain:
        -- MaxVisibleGraphemes hanya visual, jadi kita tetap perlu guard di signal
        TextBox.MaxVisibleGraphemes = -1 -- reset, kita handle manual
    end

    local function SetError(isError)
        if isError then
            -- Border merah
            Tween(BorderFrame, 0.15, {
                ImageColor3 = Color3.fromRGB(255, 70, 70),
                ImageTransparency = 0
            }):Play()
            -- Background merah transparan
            Tween(ErrorBg, 0.15, {ImageTransparency = 0.88}):Play()
            -- Teks merah
            Tween(TextBox, 0.15, {TextColor3 = Color3.fromRGB(255, 110, 110)}):Play()
        else
            -- Kembalikan border normal
            Creator.SetThemeTag(BorderFrame, {ImageColor3 = "Outline"})
            Tween(BorderFrame, 0.2, {ImageTransparency = 0.75}):Play()
            -- Sembunyikan background merah
            Tween(ErrorBg, 0.2, {ImageTransparency = 1}):Play()
            -- Kembalikan warna teks normal
            Creator.SetThemeTag(TextBox, {TextColor3 = "Text"})
        end
    end

    local isChangingText = false
    Creator.AddSignal(TextBox:GetPropertyChangedSignal("Text"), function()
        if isChangingText then return end
        local text = TextBox.Text

        -- 1. Numeric Only: buang karakter non-angka secara langsung
        if Validation and Validation.Numeric then
            local numericText = text:gsub("[^%d.-]", "")
            if text ~= numericText then
                isChangingText = true
                TextBox.Text = numericText
                isChangingText = false
                text = numericText
                SetError(true)
                task.delay(0.4, function() SetError(false) end)
            end
        end

        -- 2. MaxLength: potong teks jika melebihi batas
        if Validation and Validation.MaxLength and #text > Validation.MaxLength then
            isChangingText = true
            TextBox.Text = text:sub(1, Validation.MaxLength)
            isChangingText = false
            text = TextBox.Text
            SetError(true)
            task.delay(0.4, function() SetError(false) end)
        end

        -- 3. Custom Validator: jalan real-time saat mengetik
        if Validation and Validation.Validator then
            local isValid = Validation.Validator(text)
            SetError(not isValid)
            -- Hanya trigger callback jika valid
            if isValid and OnChange and Callback then
                Creator.SafeCallback(Callback, text)
            end
            return
        end

        -- Jika tidak ada Validator, trigger callback normal
        if OnChange and Callback then
            Creator.SafeCallback(Callback, text)
        end
    end)

    if not OnChange then
        Creator.AddSignal(TextBox.FocusLost, function()
            local text = TextBox.Text
            local isValid = true
            if Validation and Validation.Validator then
                isValid = Validation.Validator(text)
                SetError(not isValid)
            end
            if isValid and Callback then
                Creator.SafeCallback(Callback, text)
            end
        end)
    end

    return InputFrame
end


return Input