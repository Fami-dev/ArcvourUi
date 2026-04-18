local WindUI
if game:GetService("RunService"):IsStudio() then
    WindUI = require(game:GetService("ReplicatedStorage"):WaitForChild("WindUI"):WaitForChild("Init"))
else
    local success, localBuild = pcall(function()
        return loadstring(game:HttpGet("http://localhost:8642/dist/main.lua"))()
    end)
    if success and localBuild then
        WindUI = localBuild
    else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end

if not WindUI then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local function gradient(text, startColor, endColor)
    if not text or not startColor or not endColor then return "" end
    local result = ""
    local length = #text
    for i = 1, length do
        local t = (i - 1) / math.max(length - 1, 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * t) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * t) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * t) * 255)
        local char = text:sub(i, i)
        result = result .. "<font color=\"rgb(" .. r .. ", " .. g .. ", " .. b .. ")\">" .. char .. "</font>"
    end
    return result
end

WindUI:AddTheme({
    Name = "Arcvour",
    Accent = "#4B2D82",
    Dialog = "#1E142D",
    Outline = "#46375A",
    Text = "#E5DCEA",
    Placeholder = "#A898C2",
    Background = "#221539",
    Button = "#8C46FF",
    Icon = "#A898C2"
})

WindUI.Intro.Play({
    Title = "ArcvourHub",
    Subtitle = "Interactive User Interface",
    Icon = "rbxassetid://90566677928169",
    PrimaryColor = Color3.fromHex("#8C46FF"),
    SecondaryColor = Color3.fromHex("#BE78FF"),
})

local keyUrl = "https://arcvour.wtf/key/TEST.txt"
local fetchedKey

local success, response = pcall(function()
    return game:HttpGet(keyUrl, true)
end)

if success and response and type(response) == "string" then
    fetchedKey = response:match("^%s*(.-)%s*$")
else
    warn("ArcvourHUB: Failed to fetch key.", response)
    fetchedKey = "FAILED_TO_FETCH_KEY_" .. math.random(1000, 9999)
end

local Window = WindUI:CreateWindow({
    Title = gradient("ArcvourHUB", Color3.fromHex("#8C46FF"), Color3.fromHex("#BE78FF")),
    Icon = "rbxassetid://90566677928169",
    Author = "Script Name",
    Size = UDim2.fromOffset(580, 400),
    Folder = "ArcvourHUB_Config",
    Transparent = false,
    Theme = "Arcvour",
    ToggleKey = Enum.KeyCode.K,
    SideBarWidth = 180,
    KeySystem = {
        Key = fetchedKey,
        URL = "https://t.me/arcvourscript",
        Note = "Enter the key provided to access the script.",
        SaveKey = false
    }
})

if not Window then return end

Window:SetFloatingButton({
    Icon = "rbxassetid://90566677928169",
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(1, -70, 0, 20)
})

do
    Window:Tag({
        Title = "ArcvourHub Temp",
        Icon = "github",
        Color = Color3.fromHex("#1c1c1c"),
        Border = true,
    })
end

local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Green  = Color3.fromHex("#10C550")
local Grey   = Color3.fromHex("#83889E")
local Blue   = Color3.fromHex("#257AF7")
local Red    = Color3.fromHex("#EF4F1D")

local function parseJSON(luau_table, indent, level, visited)
    indent = indent or 2
    level = level or 0
    visited = visited or {}

    local currentIndent = string.rep(" ", level * indent)
    local nextIndent = string.rep(" ", (level + 1) * indent)

    if luau_table == nil then return "null" end

    local dataType = type(luau_table)

    if dataType == "table" then
        if visited[luau_table] then return "\"[Circular Reference]\"" end
        visited[luau_table] = true

        local isArray = true
        local maxIndex = 0

        for k, _ in pairs(luau_table) do
            if type(k) == "number" and k > maxIndex then maxIndex = k end
            if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                isArray = false
                break
            end
        end

        local count = 0
        for _ in pairs(luau_table) do count = count + 1 end
        if count ~= maxIndex and isArray then isArray = false end
        if count == 0 then return "{}" end

        if isArray then
            local result = "[\n"
            for i = 1, maxIndex do
                result = result .. nextIndent .. parseJSON(luau_table[i], indent, level + 1, visited)
                if i < maxIndex then result = result .. "," end
                result = result .. "\n"
            end
            result = result .. currentIndent .. "]"
            return result
        else
            local result = "{\n"
            local first = true
            local keys = {}
            for k in pairs(luau_table) do table.insert(keys, k) end
            table.sort(keys, function(a, b)
                if type(a) == type(b) then return tostring(a) < tostring(b) end
                return type(a) < type(b)
            end)
            for _, k in ipairs(keys) do
                local v = luau_table[k]
                if not first then result = result .. ",\n" else first = false end
                local key = type(k) == "string" and k or tostring(k)
                result = result .. nextIndent .. "\"" .. key .. "\": " .. parseJSON(v, indent, level + 1, visited)
            end
            result = result .. "\n" .. currentIndent .. "}"
            return result
        end
    elseif dataType == "string" then
        local escaped = luau_table:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
        return "\"" .. escaped .. "\""
    elseif dataType == "number" then
        return tostring(luau_table)
    elseif dataType == "boolean" then
        return luau_table and "true" or "false"
    elseif dataType == "function" then
        return "\"function\""
    else
        return "\"" .. dataType .. "\""
    end
end

local function tableToClipboard(luau_table, indent)
    indent = indent or 4
    local jsonString = parseJSON(luau_table, indent)
    setclipboard(jsonString)
    return jsonString
end


do
    local AboutTab = Window:Tab({
        Title = "About WindUI",
        Desc = "Library information",
        Icon = "solar:info-square-bold",
        IconColor = Grey,
        IconShape = "Square",
        Border = true,
    })

    local AboutSection = AboutTab:Section({ Title = "About WindUI" })

    AboutSection:Image({
        Image = "https://repository-images.githubusercontent.com/880118829/22c020eb-d1b1-4b34-ac4d-e33fd88db38d",
        AspectRatio = "16:9",
        Radius = 9,
    })

    AboutSection:Space({ Columns = 3 })

    AboutSection:Section({
        Title = "What is WindUI?",
        TextSize = 24,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    AboutSection:Space()

    AboutSection:Section({
        Title = "WindUI is a stylish, open-source UI library designed for Roblox Script Hubs.\nDeveloped by Footagesus (.ftgs, Footages).\nIt provides developers with a modern, customizable, and easy-to-use toolkit for creating visually appealing interfaces within Roblox.\nPrimarily written in Lua (Luau).",
        TextSize = 18,
        TextTransparency = .35,
        FontWeight = Enum.FontWeight.Medium,
    })

    AboutTab:Space({ Columns = 4 })

    AboutTab:Button({
        Title = "Export WindUI JSON (copy)",
        Color = Color3.fromHex("#a2ff30"),
        Justify = "Center",
        IconAlign = "Left",
        Icon = "",
        Callback = function()
            tableToClipboard(WindUI)
            WindUI:Notify({
                Title = "WindUI JSON",
                Content = "Copied to Clipboard!"
            })
        end
    })

    AboutTab:Space({ Columns = 1 })

    AboutTab:Button({
        Title = "Destroy Window",
        Color = Color3.fromHex("#ff4830"),
        Justify = "Center",
        Icon = "shredder",
        IconAlign = "Left",
        Callback = function()
            Window:Destroy()
        end
    })
end


local ElementsSection   = Window:Section({ Title = "Elements" })
local ConfigUsageSection = Window:Section({ Title = "Config Usage" })
local OtherSection      = Window:Section({ Title = "Other" })


do
    ElementsSection:Tab({
        Title = "Locked Tab",
        Icon = "solar:lock-bold",
        IconColor = Red,
        IconShape = "Square",
        Border = true,
        Locked = true,
    })

    ElementsSection:Tab({
        Title = "Locked (no icon)",
        Border = true,
        Locked = true,
    })
end


do
    local OverviewTab = ElementsSection:Tab({
        Title = "Overview",
        Icon = "solar:home-2-bold",
        IconColor = Grey,
        IconShape = "Square",
        Border = true,
    })

    OverviewTab:Section({ Title = "Group Examples" })

    local OverviewGroup1 = OverviewTab:Group({})
    OverviewGroup1:Button({ Title = "Button 1", Justify = "Center", Icon = "", Callback = function() print("clicked button 1") end })
    OverviewGroup1:Space()
    OverviewGroup1:Button({ Title = "Button 2", Justify = "Center", Icon = "", Callback = function() print("clicked button 2") end })

    OverviewTab:Space()

    local OverviewGroup2 = OverviewTab:Group({})
    OverviewGroup2:Button({ Title = "Button 1", Justify = "Center", Icon = "", Callback = function() print("clicked button 1") end })
    OverviewGroup2:Space()
    OverviewGroup2:Toggle({ Title = "Toggle 2", Callback = function(v) print("toggle 2:", v) end })
    OverviewGroup2:Space()
    OverviewGroup2:Colorpicker({ Title = "Colorpicker 3", Default = Color3.fromHex("#30ff6a"), Callback = function(color) print(color) end })

    OverviewTab:Space()

    local OverviewGroup3 = OverviewTab:Group({})

    local BoxSection1 = OverviewGroup3:Section({
        Title = "Section 1",
        Desc = "Collapsible box section",
        Box = true,
        BoxBorder = true,
        Opened = true,
    })
    BoxSection1:Button({ Title = "Button 1", Justify = "Center", Icon = "", Callback = function() print("clicked button 1") end })
    BoxSection1:Space()
    BoxSection1:Toggle({ Title = "Toggle 2", Callback = function(v) print("toggle 2:", v) end })

    OverviewGroup3:Space()

    local BoxSection2 = OverviewGroup3:Section({
        Title = "Section 2",
        Box = true,
        BoxBorder = true,
        Opened = true,
    })
    BoxSection2:Button({ Title = "Button 1", Justify = "Center", Icon = "", Callback = function() print("clicked button 1") end })
    BoxSection2:Space()
    BoxSection2:Button({ Title = "Button 2", Justify = "Center", Icon = "", Callback = function() print("clicked button 2") end })
end


do
    local ToggleTab = ElementsSection:Tab({
        Title = "Toggle",
        Icon = "solar:check-square-bold",
        IconColor = Green,
        IconShape = "Square",
        Border = true,
    })

    ToggleTab:Toggle({ Title = "Toggle" })
    ToggleTab:Space()
    ToggleTab:Toggle({ Title = "Toggle", Desc = "Toggle with description" })
    ToggleTab:Space()

    local ToggleGroup1 = ToggleTab:Group()
    ToggleGroup1:Toggle({})
    ToggleGroup1:Space()
    ToggleGroup1:Toggle({})

    ToggleTab:Space()
    ToggleTab:Toggle({ Title = "Checkbox", Type = "Checkbox" })
    ToggleTab:Space()
    ToggleTab:Toggle({ Title = "Checkbox", Desc = "Checkbox with description", Type = "Checkbox" })
    ToggleTab:Space()
    ToggleTab:Toggle({ Title = "Locked Toggle", Locked = true, LockedTitle = "This element is locked" })
    ToggleTab:Toggle({ Title = "Locked Toggle", Desc = "With description", Locked = true, LockedTitle = "This element is locked" })
end


do
    local ButtonTab = ElementsSection:Tab({
        Title = "Button",
        Icon = "solar:cursor-square-bold",
        IconColor = Blue,
        IconShape = "Square",
        Border = true,
    })

    local HighlightButton
    HighlightButton = ButtonTab:Button({
        Title = "Highlight Button",
        Icon = "mouse",
        Callback = function()
            print("clicked highlight")
            HighlightButton:Highlight()
        end
    })

    ButtonTab:Space()

    ButtonTab:Button({
        Title = "Blue Button",
        Color = Color3.fromHex("#305dff"),
        Icon = "",
        Callback = function() end
    })

    ButtonTab:Space()

    ButtonTab:Button({
        Title = "Blue Button",
        Desc = "With description",
        Color = Color3.fromHex("#305dff"),
        Icon = "",
        Callback = function() end
    })

    ButtonTab:Space()

    ButtonTab:Button({
        Title = "Notify Button",
        Callback = function()
            WindUI:Notify({
                Title = "Hello",
                Content = "Welcome to the WindUI Example!",
                Icon = "solar:bell-bold",
                Duration = 5,
                CanClose = false,
            })
        end
    })

    ButtonTab:Button({
        Title = "Notify Button (no icon)",
        Callback = function()
            WindUI:Notify({
                Title = "Hello",
                Content = "Welcome to the WindUI Example!",
                Duration = 5,
                CanClose = false,
            })
        end
    })

    ButtonTab:Space()

    ButtonTab:Button({ Title = "Locked Button", Locked = true, LockedTitle = "This element is locked" })
    ButtonTab:Button({ Title = "Locked Button", Desc = "With description", Locked = true, LockedTitle = "This element is locked" })
end


do
    local InputTab = ElementsSection:Tab({
        Title = "Input",
        Icon = "solar:password-minimalistic-input-bold",
        IconColor = Purple,
        IconShape = "Square",
        Border = true,
    })

    InputTab:Input({ Title = "Input", Icon = "mouse" })
    InputTab:Space()
    InputTab:Input({ Title = "Input with Description", Desc = "Input description", Icon = "mouse" })
    InputTab:Space()
    InputTab:Input({ Title = "Input Textarea", Type = "Textarea", Icon = "mouse" })
    InputTab:Space()
    InputTab:Input({ Title = "Input Textarea (no icon)", Type = "Textarea" })
    InputTab:Space()
    InputTab:Input({ Title = "Locked Input", Locked = true, LockedTitle = "This element is locked" })
    InputTab:Input({ Title = "Locked Input", Desc = "With description", Locked = true, LockedTitle = "This element is locked" })

    InputTab:Space()

    InputTab:Section({ Title = "Input Validation", TextSize = 14 })

    InputTab:Input({
        Title = "Numeric Only",
        Desc = "Only accepts numbers (e.g. Speed)",
        Numeric = true,
        Icon = "hash",
        Placeholder = "Enter number...",
        Callback = function(text)
            print("Numeric Input: " .. text)
        end
    })

    InputTab:Input({
        Title = "Max Length (4 chars)",
        Desc = "Useful for PIN codes",
        MaxLength = 4,
        Numeric = true,
        Icon = "shield-check",
        Placeholder = "1234",
        Callback = function(text)
            print("PIN Input: " .. text)
        end
    })

    InputTab:Input({
        Title = "Custom Validator (min 6 chars)",
        Desc = "Border turns red if less than 6 characters",
        Icon = "key",
        Placeholder = "Password...",
        Validator = function(text)
            return #text >= 6
        end,
        Callback = function(text)
            print("Valid password: " .. text)
        end
    })
end


do
    local SliderTab = ElementsSection:Tab({
        Title = "Slider",
        Icon = "solar:square-transfer-horizontal-bold",
        IconColor = Green,
        IconShape = "Square",
        Border = true,
    })

    SliderTab:Section({ Title = "Slider with Tooltip (no textbox)", TextSize = 14 })
    SliderTab:Slider({
        Title = "Slider Example",
        Desc = "With tooltip enabled",
        IsTooltip = true,
        IsTextbox = false,
        Width = 200,
        Step = 1,
        Value = { Min = 0, Max = 200, Default = 100 },
        Callback = function(value) print(value) end
    })

    SliderTab:Space()

    SliderTab:Section({ Title = "Slider without description", TextSize = 14 })
    SliderTab:Slider({
        Title = "Slider Example",
        Step = 1,
        Width = 200,
        Value = { Min = 0, Max = 200, Default = 100 },
        Callback = function(value) print(value) end
    })

    SliderTab:Space()

    SliderTab:Section({ Title = "Slider with Suffix property", TextSize = 14 })
    SliderTab:Slider({
        Title = "Volume",
        Desc = "Suffix: %",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = 50 },
        Suffix = "%",
        Callback = function(value) print("Volume: " .. tostring(value) .. "%") end
    })

    SliderTab:Space()

    SliderTab:Slider({
        Title = "Walk Speed",
        Desc = "Suffix: studs/s",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = 16 },
        Suffix = " studs/s",
        Callback = function(value) print("Walk Speed: " .. tostring(value) .. " studs/s") end
    })

    SliderTab:Space()

    SliderTab:Slider({
        Title = "Delay",
        Desc = "Suffix: ms",
        Step = 10,
        Value = { Min = 0, Max = 1000, Default = 200 },
        Suffix = "ms",
        Callback = function(value) print("Delay: " .. tostring(value) .. "ms") end
    })

    SliderTab:Space()

    SliderTab:Section({ Title = "Slider without title", TextSize = 14 })
    SliderTab:Slider({
        IsTooltip = true,
        Step = 1,
        Value = { Min = 0, Max = 200, Default = 100 },
        Callback = function(value) print(value) end
    })

    SliderTab:Space()

    SliderTab:Section({ Title = "Slider with icon (From only)", TextSize = 14 })
    SliderTab:Slider({
        IsTooltip = true,
        Step = 1,
        Value = { Min = 0, Max = 200, Default = 100 },
        Icons = { From = "sfsymbols:sunMinFill" },
        Callback = function(value) print(value) end
    })

    SliderTab:Space()

    SliderTab:Section({ Title = "Slider with icons (From & To)", TextSize = 14 })
    SliderTab:Slider({
        IsTooltip = true,
        Step = 1,
        Value = { Min = 0, Max = 100, Default = 50 },
        Icons = { From = "sfsymbols:sunMinFill", To = "sfsymbols:sunMaxFill" },
        Callback = function(value) print(value) end
    })
end


do
    local DropdownTab = ElementsSection:Tab({
        Title = "Dropdown",
        Icon = "solar:hamburger-menu-bold",
        IconColor = Yellow,
        IconShape = "Square",
        Border = true,
    })

    DropdownTab:Dropdown({
        Title = "Advanced Dropdown",
        Values = {
            { Title = "New file",   Desc = "Create a new file",          Icon = "file-plus", Callback = function() print("New File") end },
            { Title = "Copy link",  Desc = "Copy the file link",         Icon = "copy",      Callback = function() print("Copy link") end },
            { Title = "Edit file",  Desc = "Allows you to edit the file",Icon = "file-pen",  Callback = function() print("Edit file") end },
            { Type = "Divider" },
            { Title = "Delete file",Desc = "Permanently delete the file",Icon = "trash",     Callback = function() print("Delete file") end },
        }
    })

    DropdownTab:Space()

    DropdownTab:Dropdown({
        Title = "Multi Dropdown",
        Values = { "Hello", "Bonjour", "Hola", "Ciao" },
        Value = nil,
        AllowNone = true,
        Multi = true,
        Callback = function(selectedValues)
            if type(selectedValues) == "table" then
                local names = {}
                for _, v in ipairs(selectedValues) do
                    table.insert(names, type(v) == "table" and v.Title or tostring(v))
                end
                print("Selected: " .. table.concat(names, ", "))
            else
                print("Selected: " .. tostring(selectedValues))
            end
        end
    })

    DropdownTab:Space()

    DropdownTab:Dropdown({
        Title = "Single Dropdown",
        Values = { "Hello", "Bonjour", "Hola", "Ciao" },
        Value = 1,
        Callback = function(selectedValue)
            print("Selected: " .. selectedValue)
        end
    })

    DropdownTab:Space()

    DropdownTab:Section({ Title = "Dropdown with Search Bar", TextSize = 14 })

    DropdownTab:Dropdown({
        Title = "Single Dropdown + Search",
        Desc = "Search items using the search bar",
        SearchBarEnabled = true,
        Values = {
            "JavaScript", "TypeScript", "Lua", "Luau",
            "Python", "Rust", "Go", "C++", "C#",
            "Java", "Kotlin", "Swift", "Ruby", "PHP",
            "Dart", "Scala", "Haskell", "Elixir", "Clojure",
        },
        Value = 1,
        AllowNone = true,
        Callback = function(selectedValue)
            print("Selected language: " .. tostring(selectedValue))
        end
    })

    DropdownTab:Space()

    DropdownTab:Dropdown({
        Title = "Multi Dropdown + Search",
        Desc = "Select multiple items using the search bar",
        SearchBarEnabled = true,
        Multi = true,
        AllowNone = true,
        Values = {
            { Title = "JavaScript", Icon = "code",     Desc = "Web scripting language" },
            { Title = "TypeScript", Icon = "code-2",   Desc = "Typed superset of JavaScript" },
            { Title = "Lua",        Icon = "moon",     Desc = "Lightweight scripting language" },
            { Title = "Luau",       Icon = "star",     Desc = "Roblox's Lua dialect" },
            { Title = "Python",     Icon = "terminal", Desc = "General-purpose language" },
            { Title = "Rust",       Icon = "shield",   Desc = "Systems programming language" },
            { Title = "Go",         Icon = "zap",      Desc = "Google's compiled language" },
            { Title = "C++",        Icon = "cpu",      Desc = "High-performance language" },
            { Title = "C#",         Icon = "hash",     Desc = "Microsoft's managed language" },
            { Title = "Java",       Icon = "coffee",   Desc = "Write once, run anywhere" },
            { Title = "Kotlin",     Icon = "layers",   Desc = "Modern JVM language" },
            { Title = "Swift",      Icon = "wind",     Desc = "Apple's programming language" },
        },
        Value = nil,
        Callback = function(selectedValues)
            if type(selectedValues) == "table" then
                local titles = {}
                for _, v in ipairs(selectedValues) do
                    table.insert(titles, type(v) == "table" and v.Title or v)
                end
                print("Selected languages: " .. table.concat(titles, ", "))
            else
                print("Selected: " .. tostring(selectedValues))
            end
        end
    })

    DropdownTab:Space()

    DropdownTab:Section({ Title = "SetValue — Update value without rebuilding list", TextSize = 14 })

    local WeaponDropdown = DropdownTab:Dropdown({
        Title = "Select Weapon",
        Desc = "Callback prints 'Equipping weapon...'",
        Values = { "Rifle", "Sniper", "Pistol", "Knife" },
        Value = "Rifle",
        Callback = function(v)
            print("[ACTION] Equipping " .. tostring(v) .. "!")
        end
    })

    local ConfigGroup = DropdownTab:Group({})

    ConfigGroup:Button({
        Title = "Load Config: Sniper (ignoreCallback = true)",
        Desc = "Updates UI only — callback is ignored",
        Justify = "Center",
        Callback = function()
            WeaponDropdown:SetValue("Sniper", true)
            print("Config loaded. UI updated to Sniper. No equip action.")
        end
    })
    ConfigGroup:Space()
    ConfigGroup:Button({
        Title = "Reset to Default (ignoreCallback = false)",
        Desc = "Updates UI and runs the callback",
        Justify = "Center",
        Callback = function()
            WeaponDropdown:SetValue("Rifle", false)
        end
    })

    DropdownTab:Space()

    DropdownTab:Section({ Title = "SetValues — Replace the list dynamically", TextSize = 14 })

    local PlayerDropdown = DropdownTab:Dropdown({
        Title = "Select Target Player",
        Values = { "Budi", "Ani", "Joko" },
        Value = "Budi",
        Callback = function(v)
            print("Target locked: " .. tostring(v))
        end
    })

    local PlayerGroup = DropdownTab:Group({})

    PlayerGroup:Button({
        Title = "Refresh List (keepValue = true)",
        Desc = "New player joined — current target stays selected",
        Justify = "Center",
        Callback = function()
            local newList = { "Budi", "Ani", "Joko", "Siti" }
            PlayerDropdown:SetValues(newList, true)
            print("List updated. Budi is still selected!")
        end
    })
    PlayerGroup:Space()
    PlayerGroup:Button({
        Title = "Change Server (keepValue = false)",
        Desc = "Different server — reset target selection",
        Justify = "Center",
        Callback = function()
            local newList = { "Michael", "John", "Sarah" }
            PlayerDropdown:SetValues(newList, false)
            print("Server changed. Target reset.")
        end
    })

    DropdownTab:Space()
end


if not RunService:IsStudio() and writefile and printidentity() then
    do
        local ConfigElementsTab = ConfigUsageSection:Tab({
            Title = "Config Elements",
            Icon = "solar:file-text-bold",
            IconColor = Blue,
            IconShape = nil,
            Border = true,
        })

        ConfigElementsTab:Colorpicker({
            Flag = "ColorpickerTest",
            Title = "Colorpicker",
            Desc = "Colorpicker description",
            Default = Color3.fromRGB(0, 255, 0),
            Transparency = 0,
            Locked = false,
            Callback = function(color)
                print("Background color: " .. tostring(color))
            end
        })

        ConfigElementsTab:Space()

        ConfigElementsTab:Dropdown({
            Flag = "DropdownTest",
            Title = "Advanced Dropdown",
            Values = {
                { Title = "Category A", Icon = "bird" },
                { Title = "Category B", Icon = "house" },
                { Title = "Category C", Icon = "droplet" },
            },
            Value = "Category A",
            Callback = function(option)
                print("Category selected: " .. option.Title .. " with icon " .. option.Icon)
            end
        })

        ConfigElementsTab:Dropdown({
            Flag = "DropdownTest2",
            Title = "Advanced Multi Dropdown",
            Values = {
                { Title = "Category A", Icon = "bird" },
                { Title = "Category B", Icon = "house" },
                { Title = "Category C", Icon = "droplet", Locked = true },
            },
            Value = "Category A",
            Multi = true,
            Callback = function(options)
                local titles = {}
                for _, v in ipairs(options) do table.insert(titles, v.Title) end
                print("Selected: " .. table.concat(titles, ", "))
            end
        })

        ConfigElementsTab:Space()

        ConfigElementsTab:Input({
            Flag = "InputTest",
            Title = "Input",
            Desc = "Input description",
            Value = "Default value",
            InputIcon = "bird",
            Type = "Input",
            Placeholder = "Enter text...",
            Callback = function(input)
                print("Text entered: " .. input)
            end
        })

        ConfigElementsTab:Space()

        ConfigElementsTab:Keybind({
            Flag = "KeybindTest",
            Title = "Keybind",
            Desc = "Keybind to toggle UI",
            Value = "G",
            Callback = function(v)
                Window:SetToggleKey(Enum.KeyCode[v])
            end
        })

        ConfigElementsTab:Space()

        ConfigElementsTab:Slider({
            Flag = "SliderTest",
            Title = "Slider",
            Step = 1,
            Value = { Min = 20, Max = 120, Default = 70 },
            Callback = function(value) print(value) end
        })

        ConfigElementsTab:Slider({
            Flag = "SliderTest2",
            Icons = { From = "sfsymbols:sunMinFill", To = "sfsymbols:sunMaxFill" },
            Step = 1,
            IsTooltip = true,
            Value = { Min = 0, Max = 100, Default = 50 },
            Callback = function(value) print(value) end
        })

        ConfigElementsTab:Space()

        ConfigElementsTab:Toggle({
            Flag = "TogglePanelBg",
            Title = "Toggle Panel Background",
            Value = not Window.HidePanelBackground,
            Callback = function(state)
                Window:SetPanelBackground(state)
            end
        })

        ConfigElementsTab:Toggle({
            Flag = "ToggleTest",
            Title = "Toggle",
            Desc = "Toggle description",
            Value = false,
            Callback = function(state)
                print("Toggle activated: " .. tostring(state))
            end
        })
    end

    do
        local ConfigTab = ConfigUsageSection:Tab({
            Title = "Config Usage",
            Icon = "solar:folder-with-files-bold",
            IconColor = Purple,
            IconShape = nil,
            Border = true,
        })

        local ConfigManager = Window.ConfigManager
        local ConfigName = "default"

        local ConfigNameInput = ConfigTab:Input({
            Title = "Config Name",
            Icon = "file-cog",
            Callback = function(value)
                ConfigName = value
            end
        })

        ConfigTab:Space()

        local AllConfigs = ConfigManager:AllConfigs()
        local DefaultValue = table.find(AllConfigs, ConfigName) and ConfigName or nil

        local AllConfigsDropdown = ConfigTab:Dropdown({
            Title = "All Configs",
            Desc = "Select an existing config",
            Values = AllConfigs,
            Value = DefaultValue,
            Callback = function(value)
                ConfigName = value
                ConfigNameInput:Set(value)
            end
        })

        ConfigTab:Space()

        ConfigTab:Button({
            Title = "Save Config",
            Icon = "",
            Justify = "Center",
            Callback = function()
                Window.CurrentConfig = ConfigManager:Config(ConfigName)
                if Window.CurrentConfig:Save() then
                    WindUI:Notify({
                        Title = "Config Saved",
                        Desc = "Config '" .. ConfigName .. "' saved",
                        Icon = "check",
                    })
                end
                AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
            end
        })

        ConfigTab:Space()

        ConfigTab:Button({
            Title = "Load Config",
            Icon = "",
            Justify = "Center",
            Callback = function()
                Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
                if Window.CurrentConfig:Load() then
                    WindUI:Notify({
                        Title = "Config Loaded",
                        Desc = "Config '" .. ConfigName .. "' loaded",
                        Icon = "refresh-cw",
                    })
                end
            end
        })

        ConfigTab:Space()

        ConfigTab:Button({
            Title = "Print AutoLoad Configs",
            Icon = "",
            Justify = "Center",
            Callback = function()
                print(HttpService:JSONDecode(ConfigManager:GetAutoLoadConfigs()))
            end
        })
    end
end


do
    local InviteCode = "ftgs-development-hub-1300692552005189632"
    local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

    local Response = WindUI.cloneref(game:GetService("HttpService")):JSONDecode(WindUI.Creator.Request and WindUI.Creator.Request({
        Url = DiscordAPI,
        Method = "GET",
        Headers = {
            ["User-Agent"] = "WindUI/Example",
            ["Accept"] = "application/json"
        }
    }).Body or "{}")

    local DiscordTab = OtherSection:Tab({
        Title = "Discord",
        Border = true,
    })

    if Response and Response.guild then
        DiscordTab:Section({ Title = "Join our Discord server!", TextSize = 20 })
        DiscordTab:Paragraph({
            Title = tostring(Response.guild.name),
            Desc = tostring(Response.guild.description),
            Image = "https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024",
            Thumbnail = "https://cdn.discordapp.com/banners/1300692552005189632/35981388401406a4b7dffd6f447a64c4.png?size=512",
            ImageSize = 48,
            Buttons = {
                {
                    Title = "Copy link",
                    Icon = "link",
                    Callback = function()
                        setclipboard("https://discord.gg/" .. InviteCode)
                    end
                }
            }
        })
    elseif RunService:IsStudio() or not writefile then
        DiscordTab:Paragraph({
            Title = "Discord API is not available in Studio mode.",
            TextSize = 20,
            Justify = "Center",
            Image = "solar:info-circle-bold",
            Color = "Red",
            Buttons = {
                {
                    Title = "Get Invite Link",
                    Icon = "link",
                    Callback = function()
                        if setclipboard then
                            setclipboard("https://discord.gg/" .. InviteCode)
                        else
                            WindUI:Notify({
                                Title = "Discord Invite Link",
                                Content = "https://discord.gg/" .. InviteCode,
                            })
                        end
                    end
                }
            }
        })
    else
        DiscordTab:Paragraph({
            Title = "Failed to fetch Discord server info.",
            TextSize = 20,
            Justify = "Center",
            Image = "solar:info-circle-bold",
            Color = "Red",
        })
    end
end


do
    local ExampleTab = Window:Tab({
        Title = "Example Tab",
        Icon = "bird",
    })

    local dropdownA

    local LargeListA = {
        "All",      "Item A2",  "Item A3",  "Item A4",  "Item A5",
        "Item A6",  "Item A7",  "Item A8",  "Item A9",  "Item A10",
        "Item A11", "Item A12", "Item A13", "Item A14", "Item A15",
        "Item A16", "Item A17", "Item A18", "Item A19", "Item A20",
        "Item A21", "Item A22", "Item A23", "Item A24", "Item A25",
        "Item A26", "Item A27", "Item A28", "Item A29", "Item A30",
        "Item A31", "Item A32", "Item A33", "Item A34", "Item A35",
        "Item A36", "Item A37", "Item A38", "Item A39", "Item A40",
        "Item A41", "Item A42", "Item A43", "Item A44", "Item A45",
        "Item A46", "Item A47", "Item A48", "Item A49", "Item A50",
        "Item A51", "Item A52", "Item A53", "Item A54", "Item A55",
        "Item A56", "Item A57", "Item A58", "Item A59", "Item A60",
        "Item A61", "Item A62", "Item A63", "Item A64", "Item A65",
        "Item A66", "Item A67", "Item A68", "Item A69", "Item A70",
        "Item A71", "Item A72", "Item A73", "Item A74", "Item A75",
        "Item A76", "Item A77", "Item A78", "Item A79", "Item A80",
        "Item A81", "Item A82", "Item A83", "Item A84", "Item A85",
        "Item A86", "Item A87", "Item A88", "Item A89", "Item A90",
        "Item A91", "Item A92", "Item A93", "Item A94", "Item A95",
        "Item A96", "Item A97", "Item A98", "Item A99", "Item A100"
    }

    local LargeListB = {
        "Data B1", "Data B2", "Data B3", "Data B4", "Data B5",
        "Data B6", "Data B7", "Data B8", "Data B9", "Data B10",
    }

    ExampleTab:Dropdown({
        Title = "Main Category",
        Values = { "All", "Other Option" },
        Value = "All",
        Callback = function(option)
            if dropdownA then
                task.spawn(function()
                    if option == "All" then
                        dropdownA:Refresh(LargeListA)
                    else
                        dropdownA:Refresh(LargeListB)
                    end
                    dropdownA:Select({ "All" })
                end)
            end
        end,
    })

    dropdownA = ExampleTab:Dropdown({
        Title = "Target",
        Values = LargeListA,
        Multi = true,
        Value = { "All" },
        Callback = function(option) end,
    })
end
