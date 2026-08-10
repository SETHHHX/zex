getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}

local SelectedLanguage = GG.Language

function convertStringToTable(inputString)
    local result = {}
    if type(inputString) ~= "string" or inputString == "" then
        return result
    end
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        if trimmedValue and trimmedValue ~= "" then
            table.insert(result, trimmedValue)
        end
    end

    return result
end

function convertTableToString(inputTable)
    if type(inputTable) ~= "table" then
        return tostring(inputTable or "")
    end
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_click = CoreGui:FindFirstChild('ZexHub')

if old_click then
    Debris:AddItem(old_click, 0)
end

if not isfolder("ZexHub") then
    makefolder("ZexHub")
end

if not isfolder("ZexHub/Configs") then
    makefolder("ZexHub/Configs")
end


local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
    
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end
    
            value:Disconnect()
        end
    end
}, Connections)


local Util = setmetatable({
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)

        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self: any)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y

        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)


local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur


function AcrylicBlur.new(object: GuiObject)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _frame = nil,
        _root = nil
    }, AcrylicBlur)

    self:setup()

    return self
end


function AcrylicBlur:create_folder()
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')

    if old_folder then
        Debris:AddItem(old_folder, 0)
    end

    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera

    self._folder = folder
end


function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting

    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then
            continue
        end

        if object == depth_of_fields then
            continue
        end

        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)

        object.FarIntensity = 0
    end
end


function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object

    self._frame = frame
end


function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0) 
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder


    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick  
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)  
    specialMesh.Parent = part

    self._root = part 
end


function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    
    self:create_frame()
    self:render(0.001)

    self:check_quality_level()
end


function AcrylicBlur:render(distance: number)
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function update_positions(size: any, position: any)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function update()
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right

        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then
            return
        end

        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

        update_positions(size, position)
        task.spawn(update)
    end

    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)

    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    
    task.spawn(update)
end


function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then
        self:change_visiblity(false)
    end

    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value

        self:change_visiblity(quality_level >= 8)
    end)
end


function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end


local function sanitize_config_name(name: string): string
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[^%w%-%_ ]", "")
    if name == "" then
        return "default"
    end
    return name
end

local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local ok, err = pcall(function()
            writefile("ZexHub/" .. tostring(file_name) .. ".json", HttpService:JSONEncode(config))
        end)
        if not ok then
            warn("failed to save config", err)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfile("ZexHub/" .. file_name .. ".json") then
                self:save(file_name, config)
                return
            end

            local flags = readfile("ZexHub/" .. file_name .. ".json")
            if not flags then
                self:save(file_name, config)
                return
            end

            return HttpService:JSONDecode(flags)
        end)

        if not success_load then
            warn("failed to load config", result)
        end

        if not result then
            result = {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end

        return result
    end,
    save_named = function(self: any, name: string, config: any)
        name = sanitize_config_name(name)
        local ok, err = pcall(function()
            if not isfolder("ZexHub/Configs") then
                makefolder("ZexHub/Configs")
            end
            writefile("ZexHub/Configs/" .. name .. ".json", HttpService:JSONEncode(config))
        end)
        if not ok then
            warn("failed to save named config", err)
            return false
        end
        return true
    end,
    load_named = function(self: any, name: string)
        name = sanitize_config_name(name)
        local path = "ZexHub/Configs/" .. name .. ".json"
        local ok, result = pcall(function()
            if not isfile(path) then
                return nil
            end
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok then
            warn("failed to load named config", result)
            return nil
        end
        return result
    end,
    delete_named = function(self: any, name: string)
        name = sanitize_config_name(name)
        local path = "ZexHub/Configs/" .. name .. ".json"
        local ok, err = pcall(function()
            if isfile(path) then
                delfile(path)
            end
        end)
        if not ok then
            warn("failed to delete config", err)
            return false
        end
        return true
    end,
    list_named = function(self: any)
        local list = {}
        local ok, files = pcall(function()
            if not isfolder("ZexHub/Configs") then
                makefolder("ZexHub/Configs")
                return {}
            end
            return listfiles("ZexHub/Configs")
        end)
        if not ok or type(files) ~= "table" then
            return list
        end
        for _, path in files do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name then
                table.insert(list, name)
            end
        end
        table.sort(list)
        return list
    end
}, Config)


local Library = {
    _config = {
        _flags = {},
        _keybinds = {},
        _library = {}
    },

    _elements = {}, -- flag -> { type, set, get }

    _choosing_keybind = false,
    _device = nil,

    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,

    _dragging = false,
    _drag_start = nil,
    _container_position = nil
}
Library.__index = Library

function Library:RegisterElement(flag: string, elementType: string, setFn: any, getFn: any)
    if not flag or flag == "" then
        return
    end
    self._elements[flag] = {
        type = elementType,
        set = setFn,
        get = getFn
    }
end

function Library:GetConfigs()
    return Config:list_named()
end

local META_FLAGS = {
    ConfigNameInput = true,
    SelectedConfig = true,
}

function Library:SaveConfig(name: string)
    name = sanitize_config_name(name)
    -- Snapshot current flags from live elements when possible
    for flag, el in pairs(self._elements) do
        if el.get and not META_FLAGS[flag] then
            local ok, val = pcall(el.get)
            if ok then
                self._config._flags[flag] = val
            end
        end
    end

    local flagsCopy = {}
    for k, v in pairs(self._config._flags) do
        if not META_FLAGS[k] then
            flagsCopy[k] = v
        end
    end

    local payload = {
        _flags = flagsCopy,
        _keybinds = self._config._keybinds,
        _library = self._config._library or {},
        _name = name,
        _savedAt = os.time()
    }
    local ok = Config:save_named(name, payload)
    return ok, name
end

function Library:LoadConfig(name: string)
    name = sanitize_config_name(name)
    local data = Config:load_named(name)
    if not data then
        return false, "Config not found"
    end

    if type(data._flags) == "table" then
        for k, v in pairs(data._flags) do
            if not META_FLAGS[k] then
                self._config._flags[k] = v
            end
        end
    end
    if type(data._keybinds) == "table" then
        self._config._keybinds = data._keybinds
    end
    if type(data._library) == "table" then
        self._config._library = data._library
    end

    -- Apply to live UI elements (skip config UI meta flags)
    for flag, value in pairs(self._config._flags) do
        if not META_FLAGS[flag] then
            local el = self._elements[flag]
            if el and el.set then
                pcall(el.set, value)
            end
        end
    end

    return true, name
end

function Library:DeleteConfig(name: string)
    name = sanitize_config_name(name)
    local current = self:GetAutoLoad()
    local ok = Config:delete_named(name)
    if ok and current and sanitize_config_name(current) == name then
        self:ClearAutoLoad()
    end
    return ok
end

function Library:SetAutoLoad(name: string)
    name = sanitize_config_name(name)
    local ok, err = pcall(function()
        writefile("ZexHub/autoload.txt", name)
    end)
    if not ok then
        warn("failed to set autoload", err)
        return false
    end
    return true, name
end

function Library:GetAutoLoad()
    local ok, result = pcall(function()
        if not isfile("ZexHub/autoload.txt") then
            return nil
        end
        local name = readfile("ZexHub/autoload.txt")
        if type(name) ~= "string" or name == "" then
            return nil
        end
        return name:gsub("^%s+", ""):gsub("%s+$", "")
    end)
    if not ok then
        return nil
    end
    return result
end

function Library:ClearAutoLoad()
    local ok = pcall(function()
        if isfile("ZexHub/autoload.txt") then
            delfile("ZexHub/autoload.txt")
        end
    end)
    return ok and true or false
end

function Library:TryAutoLoad()
    local name = self:GetAutoLoad()
    if not name or name == "" then
        return false, nil
    end
    return self:LoadConfig(name)
end


function Library.new(settings)
    settings = settings or {}
    local self = setmetatable({
        _loaded = false,
        _tab = 0,
        _settings = {
            Title = settings.Title or "Zex Hub",
            Subtitle = settings.Subtitle or "",
            Icon = settings.Icon or "rbxassetid://130655920174103",
            Keybind = settings.Keybind or Enum.KeyCode.RightControl,
            ToggleIcon = settings.ToggleIcon == true,
            ToggleIconImage = settings.ToggleIconImage or settings.Icon or "rbxassetid://130655920174103",
            ToggleIconSize = settings.ToggleIconSize or 60,
        },
    }, Library)
    
    self:create_ui()

    return self
end


local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "ZexHubNotifications"
NotificationGui.ResetOnSpawn = false
NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotificationGui.DisplayOrder = 999999998
NotificationGui.IgnoreGuiInset = true
pcall(function()
    NotificationGui.Parent = CoreGui
end)
if not NotificationGui.Parent then
    NotificationGui.Parent = game:GetService("CoreGui")
end

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "Container"
NotificationContainer.Size = UDim2.new(0, 320, 0, 0)
NotificationContainer.AnchorPoint = Vector2.new(1, 1)
NotificationContainer.Position = UDim2.new(1, -20, 1, -20)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.Parent = NotificationGui
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y


local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = NotificationContainer


function Library.SendNotification(settings)
    settings = settings or {}

    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 0)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer
    Notification.AutomaticSize = Enum.AutomaticSize.Y

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 56)
    InnerFrame.Position = UDim2.new(1, 24, 0, 0)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(22, 18, 32)
    InnerFrame.BackgroundTransparency = 0.05
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.ClipsDescendants = true
    InnerFrame.Parent = Notification

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 10)
    InnerUICorner.Parent = InnerFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(140, 90, 220)
    Stroke.Transparency = 0.35
    Stroke.Thickness = 1.2
    Stroke.Parent = InnerFrame

    -- Accent bar on the far left edge (does not share layout with text)
    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(0, 4, 1, 0)
    Accent.Position = UDim2.new(0, 0, 0, 0)
    Accent.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
    Accent.BorderSizePixel = 0
    Accent.ZIndex = 1
    Accent.Parent = InnerFrame

    local AccentCorner = Instance.new("UICorner")
    AccentCorner.CornerRadius = UDim.new(0, 2)
    AccentCorner.Parent = Accent

    -- Text content starts AFTER the accent (left = 14px)
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.BackgroundTransparency = 1
    Content.Position = UDim2.new(0, 14, 0, 0)
    Content.Size = UDim2.new(1, -28, 1, 0)
    Content.ZIndex = 2
    Content.Parent = InnerFrame

    local Title = Instance.new("TextLabel")
    Title.Text = tostring(settings.title or "Notification")
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 14
    Title.Size = UDim2.new(1, 0, 0, 18)
    Title.Position = UDim2.new(0, 0, 0, 10)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true
    Title.ZIndex = 3
    Title.Parent = Content

    local Body = Instance.new("TextLabel")
    Body.Text = tostring(settings.text or "")
    Body.TextColor3 = Color3.fromRGB(190, 180, 210)
    Body.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    Body.TextSize = 12
    Body.Size = UDim2.new(1, 0, 0, 0)
    Body.Position = UDim2.new(0, 0, 0, 30)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y
    Body.ZIndex = 3
    Body.Parent = Content

    task.spawn(function()
        task.wait()
        local h = math.max(52, 10 + Title.TextBounds.Y + 4 + Body.TextBounds.Y + 12)
        InnerFrame.Size = UDim2.new(1, 0, 0, h)
        Notification.Size = UDim2.new(1, 0, 0, h)

        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tweenIn:Play()

        task.wait(settings.duration or 4)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 40, 0, 0),
            BackgroundTransparency = 1
        })
        TweenService:Create(Stroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
        TweenService:Create(Title, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        TweenService:Create(Body, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
    end)
end

-- Convert any flag value to safe display / storage string
local function value_to_display(value)
    if value == nil then
        return ""
    end
    local t = typeof(value)
    if t == "string" then
        return value
    end
    if t == "number" or t == "boolean" then
        return tostring(value)
    end
    if t == "table" then
        if value.Name then
            return tostring(value.Name)
        end
        -- array of strings
        local parts = {}
        local isArray = true
        for k, v in pairs(value) do
            if type(k) ~= "number" then
                isArray = false
                break
            end
            local s = value_to_display(v)
            if s ~= "" then
                table.insert(parts, s)
            end
        end
        if isArray and #parts > 0 then
            return table.concat(parts, ", ")
        end
        return ""
    end
    return tostring(value)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X

    self._ui_scale = viewport_size_x / 1400
end


function Library:get_device()
    local device = 'Unknown'

    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end

    self._device = device
end


function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end


function Library:flag_type(flag: any, flag_type: any)
    if not Library._config._flags[flag] then
        return
    end

    return typeof(Library._config._flags[flag]) == flag_type
end


function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end

        table.remove(__table, index)
    end
end


function Library:create_ui()
    local old_click = CoreGui:FindFirstChild('ZexHub')

    if old_click then
        Debris:AddItem(old_click, 0)
    end

    local click = Instance.new('ScreenGui')
    click.ResetOnSpawn = false
    click.Name = 'ZexHub'
    click.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    click.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(35, 35, 35)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05
    Container.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = click
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(120, 60, 200)
    UIStroke.Transparency = 0.45
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(90, 50, 140)
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 380)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026, 0, 0.13, 0)
    Tabs.BorderColor3 = Color3.fromRGB(90, 50, 140)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    -- Title (supports RichText)
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextTransparency = 0
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 420, 0, 18)
    ClientName.AnchorPoint = Vector2.new(0, 0)
    ClientName.Position = UDim2.new(0.056, 0, 0.018, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.TextYAlignment = Enum.TextYAlignment.Center
    ClientName.BorderSizePixel = 0
    ClientName.TextSize = 15
    ClientName.RichText = true
    ClientName.Text = self._settings.Title or "Zex Hub"
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler

    -- Subtitle (supports RichText) — game name / extra info
    local SubtitleLabel = Instance.new('TextLabel')
    SubtitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    SubtitleLabel.TextColor3 = Color3.fromRGB(180, 170, 210)
    SubtitleLabel.TextTransparency = 0.15
    SubtitleLabel.Name = 'Subtitle'
    SubtitleLabel.Size = UDim2.new(0, 420, 0, 14)
    SubtitleLabel.AnchorPoint = Vector2.new(0, 0)
    SubtitleLabel.Position = UDim2.new(0.056, 0, 0.055, 0)
    SubtitleLabel.BackgroundTransparency = 1
    SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
    SubtitleLabel.BorderSizePixel = 0
    SubtitleLabel.TextSize = 11
    SubtitleLabel.RichText = true
    SubtitleLabel.Text = self._settings.Subtitle or ""
    SubtitleLabel.Visible = (self._settings.Subtitle ~= nil and self._settings.Subtitle ~= "")
    SubtitleLabel.Parent = Handler

    self._titleLabel = ClientName
    self._subtitleLabel = SubtitleLabel

    function self:SetTitle(text)
        if self._titleLabel then
            self._titleLabel.Text = tostring(text or "")
            self._settings.Title = tostring(text or "")
        end
    end

    function self:SetSubtitle(text)
        if self._subtitleLabel then
            local t = tostring(text or "")
            self._subtitleLabel.Text = t
            self._subtitleLabel.Visible = (t ~= "")
            self._settings.Subtitle = t
        end
    end

    function self:SetState(state)
        self:change_visiblity(state and true or false)
    end

    function self:SetIcon(image)
        local img = tostring(image or "")
        if img == "" then return end
        self._settings.Icon = img
        if self._logoIcon then
            self._logoIcon.Image = img
        end
        -- Also update floating toggle icon if present
        if self._toggleGui then
            local btn = self._toggleGui:FindFirstChild("ToggleButton")
            if btn and btn:IsA("ImageButton") then
                btn.Image = img
            end
        end
    end
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026000000536441803, 0, 0.13600000739097595, 0)
    Pin.BorderColor3 = Color3.fromRGB(90, 50, 140)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Color3.fromRGB(150, 80, 255)
    Pin.Parent = Handler
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Color3.fromRGB(220, 220, 220)
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(90, 50, 140)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = self._settings.Icon or 'rbxassetid://130655920174103'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.021, 0,0.053, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 27,0, 26)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon.Parent = Handler
    self._logoIcon = Icon
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.4
    Divider.Position = UDim2.new(0.235, 0, 0, 42)
    Divider.BorderColor3 = Color3.fromRGB(90, 50, 140)
    Divider.Size = UDim2.new(0, 1, 0, 437)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(60, 40, 90)
    Divider.Parent = Handler
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(90, 50, 140)
    Minimize.BorderColor3 = Color3.fromRGB(90, 50, 140)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    -- Top bar strip (space for logo area + close button, keeps X out of content)
    local TopBar = Instance.new('Frame')
    TopBar.Name = 'TopBar'
    TopBar.BackgroundTransparency = 1
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.ZIndex = 40
    TopBar.Parent = Container

    -- Minimize button (hides UI completely)
    local MinBtn = Instance.new('TextButton')
    MinBtn.Name = 'MinimizeBtn'
    MinBtn.Text = '–'
    MinBtn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    MinBtn.TextSize = 18
    MinBtn.TextColor3 = Color3.fromRGB(200, 190, 220)
    MinBtn.AutoButtonColor = false
    MinBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
    MinBtn.BackgroundTransparency = 0.15
    MinBtn.BorderSizePixel = 0
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -48, 0.5, 0)
    MinBtn.AnchorPoint = Vector2.new(1, 0.5)
    MinBtn.ZIndex = 50
    MinBtn.Parent = TopBar

    local MinCorner = Instance.new('UICorner')
    MinCorner.CornerRadius = UDim.new(0, 7)
    MinCorner.Parent = MinBtn

    local MinStroke = Instance.new('UIStroke')
    MinStroke.Color = Color3.fromRGB(130, 80, 200)
    MinStroke.Transparency = 0.55
    MinStroke.Thickness = 1
    MinStroke.Parent = MinBtn

    MinBtn.MouseEnter:Connect(function()
        TweenService:Create(MinBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(70, 55, 100),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0
        }):Play()
    end)
    MinBtn.MouseLeave:Connect(function()
        TweenService:Create(MinBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 30, 55),
            TextColor3 = Color3.fromRGB(200, 190, 220),
            BackgroundTransparency = 0.15
        }):Play()
    end)

    -- Close button (X) inside top bar, far right
    local CloseBtn = Instance.new('TextButton')
    CloseBtn.Name = 'Close'
    CloseBtn.Text = '×'
    CloseBtn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    CloseBtn.TextSize = 18
    CloseBtn.TextColor3 = Color3.fromRGB(200, 190, 220)
    CloseBtn.AutoButtonColor = false
    CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
    CloseBtn.BackgroundTransparency = 0.15
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -12, 0.5, 0)
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.ZIndex = 50
    CloseBtn.Parent = TopBar

    local CloseCorner = Instance.new('UICorner')
    CloseCorner.CornerRadius = UDim.new(0, 7)
    CloseCorner.Parent = CloseBtn

    local CloseStroke = Instance.new('UIStroke')
    CloseStroke.Color = Color3.fromRGB(130, 80, 200)
    CloseStroke.Transparency = 0.55
    CloseStroke.Thickness = 1
    CloseStroke.Parent = CloseBtn

    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(160, 50, 80),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(CloseStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(220, 80, 120),
            Transparency = 0.15
        }):Play()
    end)

    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 30, 55),
            TextColor3 = Color3.fromRGB(200, 190, 220),
            BackgroundTransparency = 0.15
        }):Play()
        TweenService:Create(CloseStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(130, 80, 200),
            Transparency = 0.55
        }):Play()
    end)
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = click

    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.4;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    function self:UIVisiblity()
        click.Enabled = not click.Enabled;
    end;

    function self:change_visiblity(state: boolean)
        -- Full hide / show (used by RightControl + Minimize button)
        self._ui_open = state
        if state then
            click.Enabled = true
            Container.Visible = true
            TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479),
                BackgroundTransparency = 0.05
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.26, function()
                if not self._ui_open then
                    click.Enabled = false
                end
            end)
        end
    end

    function self:shrink_to_bar(state: boolean)
        -- Compact bar mode (only via logo/icon click)
        self._ui_open = state
        click.Enabled = true
        Container.Visible = true
        if state then
            TweenService:Create(Container, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479),
                BackgroundTransparency = 0.05
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(158, 52),
                BackgroundTransparency = 0.05
            }):Play()
        end
    end
    

    function self:load()
        -- Fast open: no blocking PreloadAsync
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
    
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
    
        -- Faster open animation
        TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()

        -- Acrylic blur deferred so UI shows instantly
        task.defer(function()
            pcall(function()
                AcrylicBlur.new(Container)
            end)
        end)

        self._ui_loaded = true
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3)

                    TweenService:Create(Pin, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.135 + offset)
                    }):Play()    

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.55
                    }):Play()

-- Dentro de update_tabs, busca el bloque del "if object == tab then"
TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    TextTransparency = 0,
    TextColor3 = Color3.fromRGB(255, 255, 255) -- Texto activo en blanco
}):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

TweenService:Create(object.Icon, TweenInfo.new(3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    ImageTransparency = 0,
    ImageColor3 = Color3.fromRGB(255, 255, 255) -- Icono activo en blanco
}):Play()
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end
        end
    end

    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true

                continue
            end

            object.Visible = false
        end
    end

    function self:create_tab(title: string, icon: string)
    local TabManager = {}
    local LayoutOrder = 0;

    local font_params = Instance.new('GetTextBoundsParams')
    font_params.Text = title
    font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    font_params.Size = 13
    font_params.Width = 10000

    local font_size = TextService:GetTextBoundsAsync(font_params)
    local first_tab = not Tabs:FindFirstChild('Tab')

    local Tab = Instance.new('TextButton')
    Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    
    -- CAMBIO: Color de borde y fondo del botón (Gris oscuro/transparente)
    Tab.TextColor3 = Color3.fromRGB(255, 255, 255) 
    Tab.BorderColor3 = Color3.fromRGB(40, 40, 40) -- Antes 8, 51, 8
    Tab.Text = ''
    Tab.AutoButtonColor = false
    Tab.BackgroundTransparency = 1
    Tab.Name = 'Tab'
    Tab.Size = UDim2.new(0, 129, 0, 38)
    Tab.BorderSizePixel = 0
    Tab.TextSize = 14
    Tab.BackgroundColor3 = Color3.fromRGB(35, 25, 50)
    Tab.Parent = Tabs
    Tab.LayoutOrder = self._tab
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 5)
    UICorner.Parent = Tab
    
    local TextLabel = Instance.new('TextLabel')
    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- BLANCO
    TextLabel.TextTransparency = 0.4 -- Ajustado para que no sea tan invisible (estaba en 0.7)
    TextLabel.Text = title
    TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
    TextLabel.AnchorPoint = Vector2.new(0, 0.5)
    TextLabel.Position = UDim2.new(0.24, 0, 0.5, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.BorderSizePixel = 0
    TextLabel.BorderColor3 = Color3.fromRGB(40, 40, 40) -- Antes 8, 51, 8
    TextLabel.TextSize = 14
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Parent = Tab
    
    -- CAMBIO IMPORTANTE: Quitamos el degradado verde
    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), -- Blanco puro
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))  -- Gris claro
    }
    UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.800000011920929
        Icon.BorderColor3 = Color3.fromRGB(90, 50, 140)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.Parent = Tab

        local function setup_section_scroll(section: ScrollingFrame)
            section.AutomaticCanvasSize = Enum.AutomaticSize.None
            -- Invisible scrollbar (wheel / touch still work)
            section.ScrollBarThickness = 0
            section.ScrollBarImageTransparency = 1
            section.ScrollingDirection = Enum.ScrollingDirection.Y
            section.ClipsDescendants = true
            section.CanvasSize = UDim2.new(0, 0, 0, 0)

            local layout = section:FindFirstChildOfClass("UIListLayout")
            local function refresh_canvas()
                if not layout then return end
                local contentY = layout.AbsoluteContentSize.Y
                section.CanvasSize = UDim2.new(0, 0, 0, contentY + 56)
            end

            if layout then
                layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh_canvas)
                task.defer(refresh_canvas)
            end

            section.ChildAdded:Connect(function()
                task.defer(refresh_canvas)
            end)
            section.ChildRemoved:Connect(function()
                task.defer(refresh_canvas)
            end)
        end

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.Size = UDim2.new(0, 252, 0, 420)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.252, 0, 0.53, 0)
        LeftSection.BorderSizePixel = 0
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local LeftList = Instance.new('UIListLayout')
        LeftList.Padding = UDim.new(0, 12)
        LeftList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        LeftList.SortOrder = Enum.SortOrder.LayoutOrder
        LeftList.Parent = LeftSection
        
        -- Padding so module border/stroke is visible on all sides
        local LeftPad = Instance.new('UIPadding')
        LeftPad.PaddingTop = UDim.new(0, 6)
        LeftPad.PaddingBottom = UDim.new(0, 40)
        LeftPad.PaddingLeft = UDim.new(0, 5)
        LeftPad.PaddingRight = UDim.new(0, 5)
        LeftPad.Parent = LeftSection

        setup_section_scroll(LeftSection)

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.Size = UDim2.new(0, 252, 0, 420)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.622, 0, 0.53, 0)
        RightSection.BorderSizePixel = 0
        RightSection.Visible = false
        RightSection.Parent = Sections
        
        local RightList = Instance.new('UIListLayout')
        RightList.Padding = UDim.new(0, 12)
        RightList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        RightList.SortOrder = Enum.SortOrder.LayoutOrder
        RightList.Parent = RightSection
        
        local RightPad = Instance.new('UIPadding')
        RightPad.PaddingTop = UDim.new(0, 6)
        RightPad.PaddingBottom = UDim.new(0, 40)
        RightPad.PaddingLeft = UDim.new(0, 5)
        RightPad.PaddingRight = UDim.new(0, 5)
        RightPad.Parent = RightSection

        setup_section_scroll(RightSection)

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = true,  -- always show options by default
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            -- Pure section by default (no master toggle). Use showToggle = true to enable it.
            local showModuleToggle = settings.showToggle == true

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = false -- don't cut off options / paragraph text
            Module.Name = 'Module'
            Module.Parent = settings.section
            Module.BackgroundColor3 = Color3.fromRGB(20, 16, 28)
            Module.BackgroundTransparency = 0.1
            Module.BorderColor3 = Color3.fromRGB(40, 40, 40)
            Module.BorderSizePixel = 0
            Module.Position = UDim2.new(0.004, 0, 0, 0)
            Module.Size = UDim2.new(0, 241, 0, showModuleToggle and 100 or 56)

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = Module
            
            -- Single clean border (visible on all sides including left)
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(110, 70, 180)
            UIStroke.Transparency = 0.4
            UIStroke.Thickness = 1.2
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.LineJoinMode = Enum.LineJoinMode.Round
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(200, 200, 200)
            Header.BorderColor3 = Color3.fromRGB(40, 40, 40)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, showModuleToggle and 93 or 52)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Color3.fromRGB(150, 90, 255)
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.699999988079071
            Icon.BorderColor3 = Color3.fromRGB(90, 50, 140)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Icon.Visible = showModuleToggle
            Icon.Parent = Header
            
local ModuleName = Instance.new('TextLabel')
ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

-- CAMBIA EL VERDE POR BLANCO:
ModuleName.TextColor3 = Color3.fromRGB(255, 255, 255) 
ModuleName.TextTransparency = 0 -- Menos transparencia para que resalte más

if not settings.rich then
    ModuleName.Text = settings.title or "Module" -- (Cambié el skibidi por algo genérico jeje)
else
    ModuleName.RichText = true
    -- Si usas RichText, aquí puedes poner un color gris claro o dejar el rojo que tenías
    ModuleName.Text = settings.richtext or "<font color='rgb(200,200,200)'>Zex Hub</font> user"
end

ModuleName.Name = 'ModuleName'
ModuleName.Size = UDim2.new(0, 205, 0, 16)
ModuleName.AnchorPoint = Vector2.new(0, 0.5)
ModuleName.Position = showModuleToggle and UDim2.new(0.073, 0, 0.22, 0) or UDim2.new(0.05, 0, 0.35, 0)
ModuleName.BackgroundTransparency = 1
ModuleName.TextXAlignment = Enum.TextXAlignment.Left
ModuleName.BorderSizePixel = 0
ModuleName.BorderColor3 = Color3.fromRGB(40, 40, 40) 
ModuleName.TextSize = 15
ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ModuleName.Parent = Header
            
local Description = Instance.new('TextLabel')
Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
Description.TextColor3 = Color3.fromRGB(150, 150, 150) -- GRIS SUAVE
Description.TextTransparency = 0.5 -- Un poco más visible que antes
Description.Text = settings.description
Description.Name = 'Description'
Description.Size = UDim2.new(0, 205, 0, 14)
Description.AnchorPoint = Vector2.new(0, 0.5)
Description.Position = showModuleToggle and UDim2.new(0.073, 0, 0.42, 0) or UDim2.new(0.05, 0, 0.68, 0)
Description.BackgroundTransparency = 1
Description.TextXAlignment = Enum.TextXAlignment.Left
Description.BorderSizePixel = 0
Description.BorderColor3 = Color3.fromRGB(40, 40, 40)
Description.TextSize = 12
Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.2
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(90, 50, 140)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            Toggle.Visible = showModuleToggle
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(90, 50, 140)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
local Keybind = Instance.new('Frame')
Keybind.Name = 'Keybind'
Keybind.BackgroundTransparency = 0.2
Keybind.Position = UDim2.new(0.15, 0, 0.735, 0)
Keybind.Size = UDim2.new(0, 40, 0, 18)
Keybind.BorderSizePixel = 0
Keybind.BackgroundColor3 = Color3.fromRGB(50, 35, 75)
Keybind.Visible = showModuleToggle
Keybind.Parent = Header
Keybind.Active = showModuleToggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind
            
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.BorderColor3 = Color3.fromRGB(90, 50, 140)
            TextLabel.Text = 'None'
            TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            TextLabel.Size = UDim2.new(0, 25, 0, 13)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 11
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.Parent = Keybind
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(30, 30, 30)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.55
            Divider.Position = UDim2.new(0.5, 0, showModuleToggle and 0.62 or 0.95, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Divider.Parent = Header
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(30, 30, 30)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.55
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(90, 50, 140)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.AutomaticSize = Enum.AutomaticSize.Y
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.PaddingBottom = UDim.new(0, 14)
            UIPadding.Parent = Options

            local OptionsList = Instance.new('UIListLayout')
            OptionsList.Padding = UDim.new(0, 7)
            OptionsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            OptionsList.SortOrder = Enum.SortOrder.LayoutOrder
            OptionsList.Parent = Options

            -- Keep module + parent section canvas tall enough for all content
            local function refresh_module_height()
                local headerH = showModuleToggle and 93 or 52
                local optionsH = math.max(OptionsList.AbsoluteContentSize.Y, 0) + 22
                local total = headerH + optionsH + ModuleManager._multiplier
                if total < headerH + 8 then
                    total = headerH + 8
                end
                Module.Size = UDim2.fromOffset(241, total)
                Options.Size = UDim2.fromOffset(241, optionsH)

                -- nudge parent section canvas
                local section = settings.section
                if section and section:IsA("ScrollingFrame") then
                    local layout = section:FindFirstChildOfClass("UIListLayout")
                    if layout then
                        task.defer(function()
                            section.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 56)
                        end)
                    end
                end
            end

            OptionsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                task.defer(refresh_module_height)
            end)
            task.defer(refresh_module_height)

            function ModuleManager:change_state(state: boolean)
    self._state = state

    -- Options always stay visible. Only the master toggle visual changes.
    -- Keep module expanded with all options
    local headerBase = showModuleToggle and 102 or 56
    local targetSize = headerBase + self._size + self._multiplier
    if targetSize < headerBase then targetSize = headerBase end
    TweenService:Create(Module, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(241, targetSize)
    }):Play()

    if self._state then
        TweenService:Create(Toggle, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(130, 70, 220)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.fromScale(0.53, 0.5)
        }):Play()
    else
        TweenService:Create(Toggle, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(35, 28, 50)
        }):Play()
        TweenService:Create(Circle, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(140, 130, 160),
            Position = UDim2.fromScale(0, 0.5)
        }):Play()
    end

    Library._config._flags[settings.flag] = self._state
    Config:save(game.GameId, Library._config)
    settings.callback(self._state)
end
            
            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end

                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end
                    
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty: boolean)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')

                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    font_params.Size = 10
                    font_params.Width = 10000
            
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    
                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    TextLabel.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    TextLabel.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = true
                settings.callback(ModuleManager._state)

                Toggle.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
                Circle.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
                Circle.Position = UDim2.fromScale(0.53, 0.5)
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string

                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            local function start_keybind_listen()
                if Library._choosing_keybind then
                    return
                end

                Library._choosing_keybind = true
                TextLabel.Text = "..."

                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end

                    -- Only accept keyboard keys
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                        ModuleManager:scale_keybind(true)
                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)
                        TextLabel.Text = 'None'

                        if Connections[settings.flag..'_keybind'] then
                            Connections[settings.flag..'_keybind']:Disconnect()
                            Connections[settings.flag..'_keybind'] = nil
                        end

                        if Connections['keybind_choose_start'] then
                            Connections['keybind_choose_start']:Disconnect()
                            Connections['keybind_choose_start'] = nil
                        end

                        Library._choosing_keybind = false
                        return
                    end

                    if Connections['keybind_choose_start'] then
                        Connections['keybind_choose_start']:Disconnect()
                        Connections['keybind_choose_start'] = nil
                    end

                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                    Config:save(game.GameId, Library._config)

                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end

                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                    Library._choosing_keybind = false

                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                end)
            end

            -- Left click on the keybind box to set key
            Keybind.InputBegan:Connect(function(input: InputObject)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    start_keybind_listen()
                end
            end)

            -- Also still support middle click on header (legacy)
            Connections[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input: InputObject)
                if input.UserInputType == Enum.UserInputType.MouseButton3 then
                    start_keybind_listen()
                end
            end)

            if showModuleToggle then
                Header.MouseButton1Click:Connect(function()
                    ModuleManager:change_state(not ModuleManager._state)
                end)
            end

            function ModuleManager:create_paragraph(settings: any)
                settings = settings or {}
                -- Support both APIs: title/text and Header/Body
                local headerText = settings.Header or settings.title or settings.header or "Info"
                local bodyText = settings.Body or settings.text or settings.body or ""
                settings.callback = settings.callback or function() end

                LayoutOrderModule = LayoutOrderModule + 1

                local ParagraphManager = {
                    Settings = settings
                }

                if self._size == 0 then
                    self._size = 11
                end

                self._size += settings.customScale or 62

                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)
                Options.Size = UDim2.fromOffset(241, self._size + 8)

                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
                Paragraph.BackgroundTransparency = 0.15
                Paragraph.Size = UDim2.new(0, 207, 0, 0)
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 6)
                UICorner.Parent = Paragraph

                local UIStroke = Instance.new('UIStroke')
                UIStroke.Color = Color3.fromRGB(100, 60, 170)
                UIStroke.Transparency = 0.65
                UIStroke.Thickness = 1
                UIStroke.Parent = Paragraph

                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, 8)
                UIPadding.PaddingBottom = UDim.new(0, 8)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.PaddingRight = UDim.new(0, 10)
                UIPadding.Parent = Paragraph

                local Title = Instance.new('TextLabel')
                Title.Name = "Header"
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(230, 220, 255)
                Title.Text = headerText
                Title.Size = UDim2.new(1, 0, 0, 16)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 13
                Title.TextWrapped = true
                Title.AutomaticSize = Enum.AutomaticSize.Y
                Title.Parent = Paragraph

                local Body = Instance.new('TextLabel')
                Body.Name = "Body"
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(160, 145, 190)
                Body.Text = bodyText
                Body.Size = UDim2.new(1, 0, 0, 14)
                Body.Position = UDim2.new(0, 0, 0, 20)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 12
                Body.TextWrapped = true
                Body.RichText = settings.rich == true
                Body.AutomaticSize = Enum.AutomaticSize.Y
                Body.Parent = Paragraph

                function ParagraphManager:UpdateHeader(text)
                    Title.Text = tostring(text or "")
                    settings.Header = Title.Text
                    settings.title = Title.Text
                end

                function ParagraphManager:UpdateBody(text)
                    Body.Text = tostring(text or "")
                    settings.Body = Body.Text
                    settings.text = Body.Text
                end

                function ParagraphManager:SetVisibility(visible)
                    Paragraph.Visible = visible and true or false
                end
                -- alias with original spelling from user request
                ParagraphManager.SetVisiblity = ParagraphManager.SetVisibility

                function ParagraphManager:Destroy()
                    Paragraph:Destroy()
                end

                return ParagraphManager
            end

            function ModuleManager:create_text(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextManager = {}
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 56 
            
                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)
            
                Options.Size = UDim2.fromOffset(241, self._size + 8)
            
              
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Color3.fromRGB(90, 50, 140)
                TextFrame.BackgroundTransparency = 0.3
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize)
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y 
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame
            
                
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(150, 90, 255)
            
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi" 
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>Zex Hub</font> user" 
                end
            
                Body.Size = UDim2.new(1, -10, 1, 0)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 12
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame
            
               
                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(90, 50, 140)
                    }):Play()
                end)
            
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(90, 50, 140)
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Skibidi"
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(255,0,0)'>Zex Hub</font> user"
                    end
                end;
            
                return TextManager
            end
            function ModuleManager:create_textbox(settings: any)
                settings = settings or {}
                settings.callback = settings.callback or function() end
                settings.title = settings.title or "Input"
                settings.placeholder = settings.placeholder or "..."
                settings.flag = settings.flag or ("Textbox_" .. tostring(math.random(10000, 99999)))

                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextboxManager = {
                    _text = ""
                }
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 32
            
                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)
                Options.Size = UDim2.fromOffset(241, self._size + 8)

                -- Row container (label left + input right)
                local Row = Instance.new("Frame")
                Row.Name = "TextboxRow"
                Row.Size = UDim2.new(0, 207, 0, 28)
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0
                Row.Parent = Options
                Row.LayoutOrder = LayoutOrderModule

                local Label = Instance.new("TextLabel")
                Label.Name = "Title"
                Label.BackgroundTransparency = 1
                Label.Size = UDim2.new(0, 95, 1, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextSize = 12
                Label.TextColor3 = Color3.fromRGB(235, 230, 245)
                Label.TextTransparency = 0.05
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextYAlignment = Enum.TextYAlignment.Center
                Label.Text = settings.title
                Label.Parent = Row

                local Textbox = Instance.new("TextBox")
                Textbox.Name = "Textbox"
                Textbox.Size = UDim2.new(0, 100, 0, 24)
                Textbox.Position = UDim2.new(1, 0, 0.5, 0)
                Textbox.AnchorPoint = Vector2.new(1, 0.5)
                Textbox.BackgroundColor3 = Color3.fromRGB(32, 28, 42)
                Textbox.BackgroundTransparency = 0.15
                Textbox.BorderSizePixel = 0
                Textbox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                Textbox.TextSize = 12
                Textbox.TextColor3 = Color3.fromRGB(230, 225, 240)
                Textbox.PlaceholderColor3 = Color3.fromRGB(120, 110, 140)
                Textbox.PlaceholderText = settings.placeholder
                Textbox.Text = value_to_display(Library._config._flags[settings.flag])
                Textbox.ClearTextOnFocus = false
                Textbox.TextXAlignment = Enum.TextXAlignment.Center
                Textbox.Parent = Row

                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 8)
                BoxCorner.Parent = Textbox

                local BoxStroke = Instance.new("UIStroke")
                BoxStroke.Color = Color3.fromRGB(90, 70, 130)
                BoxStroke.Transparency = 0.55
                BoxStroke.Thickness = 1
                BoxStroke.Parent = Textbox

                Textbox.Focused:Connect(function()
                    TweenService:Create(BoxStroke, TweenInfo.new(0.18), {
                        Color = Color3.fromRGB(150, 100, 255),
                        Transparency = 0.25
                    }):Play()
                    TweenService:Create(Textbox, TweenInfo.new(0.18), {
                        BackgroundColor3 = Color3.fromRGB(42, 34, 58)
                    }):Play()
                end)

                Textbox.FocusLost:Connect(function()
                    TweenService:Create(BoxStroke, TweenInfo.new(0.18), {
                        Color = Color3.fromRGB(90, 70, 130),
                        Transparency = 0.55
                    }):Play()
                    TweenService:Create(Textbox, TweenInfo.new(0.18), {
                        BackgroundColor3 = Color3.fromRGB(32, 28, 42)
                    }):Play()
                    TextboxManager:update_text(Textbox.Text)
                end)
            
                function TextboxManager:update_text(text: string)
                    local safe = value_to_display(text)
                    self._text = safe
                    Textbox.Text = safe
                    Library._config._flags[settings.flag] = safe
                    Config:save(game.GameId, Library._config)
                    settings.callback(safe)
                end

                function TextboxManager:Get()
                    return self._text or ""
                end

                function TextboxManager:Set(text)
                    self:update_text(value_to_display(text))
                end

                Library:RegisterElement(settings.flag, "textbox", function(v)
                    TextboxManager:Set(v)
                end, function()
                    return TextboxManager:Get()
                end)
            
                if Library:flag_type(settings.flag, "string") then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end
            
                return TextboxManager
            end   

            function ModuleManager:create_checkbox(settings: any)
                settings.callback = settings.callback or function() end
                settings.flag = settings.flag or ("Checkbox_" .. tostring(math.random(10000, 99999)))

                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 34
            
                -- Always show options (modules stay expanded)
                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)
                Options.Size = UDim2.fromOffset(241, self._size + 8)
            
                local Checkbox = Instance.new("TextButton")
Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
Checkbox.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gris claro para el texto
Checkbox.BorderColor3 = Color3.fromRGB(60, 60, 60)   -- Borde gris oscuro
Checkbox.Text = ""
Checkbox.AutoButtonColor = false
Checkbox.BackgroundTransparency = 1
Checkbox.Name = "Checkbox"
Checkbox.Size = UDim2.new(0, 207, 0, 18)
Checkbox.BorderSizePixel = 0
Checkbox.TextSize = 14
Checkbox.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Fondo gris oscuro (coincide con tus otros elementos)
Checkbox.Parent = Options
Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                if SelectedLanguage == "th" then
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 14
                else
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 13
                end
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Skibidi"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox

                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 16, 0, 16)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
                Box.Parent = Checkbox
            
                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Parent = Box
            
                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.4
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.55
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._state)
                end
            
                function CheckboxManager:Get()
                    return self._state
                end

                function CheckboxManager:Set(state)
                    self:change_state(state and true or false)
                end

                Library:RegisterElement(settings.flag, "checkbox", function(v)
                    CheckboxManager:Set(v)
                end, function()
                    return CheckboxManager:Get()
                end)

                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end
            
                Checkbox.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)

                -- Optional keybind: only appears if you call :AddKeybind() or pass keybind = true
                function CheckboxManager:AddKeybind()
                    if self._keybindAdded then return self end
                    self._keybindAdded = true

                    -- Move the toggle box left a bit to make room
                    Box.Position = UDim2.new(1, 0, 0.5, 0)

                    local KeybindBox = Instance.new("TextButton")
                    KeybindBox.Name = "KeybindBox"
                    KeybindBox.Size = UDim2.fromOffset(32, 16)
                    KeybindBox.Position = UDim2.new(1, -38, 0.5, 0)
                    KeybindBox.AnchorPoint = Vector2.new(1, 0.5)
                    KeybindBox.BackgroundColor3 = Color3.fromRGB(45, 32, 70)
                    KeybindBox.BackgroundTransparency = 0.1
                    KeybindBox.BorderSizePixel = 0
                    KeybindBox.Text = ""
                    KeybindBox.AutoButtonColor = false
                    KeybindBox.ZIndex = 5
                    KeybindBox.Parent = Checkbox

                    -- shift checkbox indicator to the right edge still
                    Box.Position = UDim2.new(1, 0, 0.5, 0)
                    KeybindBox.Position = UDim2.new(1, -22, 0.5, 0)
                    Box.Position = UDim2.new(1, 0, 0.5, 0)
                    -- Layout: [Title ........] [Key] [Box]
                    KeybindBox.Position = UDim2.new(1, -40, 0.5, 0)
                    KeybindBox.AnchorPoint = Vector2.new(1, 0.5)

                    local KeybindCorner = Instance.new("UICorner")
                    KeybindCorner.CornerRadius = UDim.new(0, 4)
                    KeybindCorner.Parent = KeybindBox

                    local KeybindStroke = Instance.new("UIStroke")
                    KeybindStroke.Color = Color3.fromRGB(120, 70, 200)
                    KeybindStroke.Transparency = 0.45
                    KeybindStroke.Thickness = 1
                    KeybindStroke.Parent = KeybindBox

                    local KeybindLabel = Instance.new("TextLabel")
                    KeybindLabel.Name = "KeybindLabel"
                    KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                    KeybindLabel.BackgroundTransparency = 1
                    KeybindLabel.TextColor3 = Color3.fromRGB(200, 185, 230)
                    KeybindLabel.TextSize = 9
                    KeybindLabel.Font = Enum.Font.Gotham
                    KeybindLabel.Text = Library._config._keybinds[settings.flag]
                        and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        or "Key"
                    KeybindLabel.Parent = KeybindBox

                    local function bind_key_listener()
                        if Connections[settings.flag .. "_keypress"] then
                            Connections[settings.flag .. "_keypress"]:Disconnect()
                            Connections[settings.flag .. "_keypress"] = nil
                        end
                        local stored = Library._config._keybinds[settings.flag]
                        if not stored then return end
                        Connections[settings.flag .. "_keypress"] = UserInputService.InputBegan:Connect(function(input, process)
                            if process then return end
                            if tostring(input.KeyCode) == stored then
                                CheckboxManager:change_state(not CheckboxManager._state)
                            end
                        end)
                    end

                    -- Restore existing bind if any
                    bind_key_listener()

                    KeybindBox.MouseButton1Click:Connect(function()
                        if Library._choosing_keybind then return end
                        Library._choosing_keybind = true
                        KeybindLabel.Text = "..."

                        local chooseConnection
                        chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                            if processed then return end
                            if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                            if keyInput.KeyCode == Enum.KeyCode.Unknown then return end

                            if keyInput.KeyCode == Enum.KeyCode.Backspace or keyInput.KeyCode == Enum.KeyCode.Escape then
                                Library._config._keybinds[settings.flag] = nil
                                Config:save(game.GameId, Library._config)
                                KeybindLabel.Text = "Key"
                                if Connections[settings.flag .. "_keypress"] then
                                    Connections[settings.flag .. "_keypress"]:Disconnect()
                                    Connections[settings.flag .. "_keypress"] = nil
                                end
                                if chooseConnection then chooseConnection:Disconnect() end
                                Library._choosing_keybind = false
                                return
                            end

                            Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                            Config:save(game.GameId, Library._config)

                            local keyStr = string.gsub(tostring(keyInput.KeyCode), "Enum.KeyCode.", "")
                            KeybindLabel.Text = keyStr
                            bind_key_listener()

                            if chooseConnection then chooseConnection:Disconnect() end
                            Library._choosing_keybind = false
                        end)
                    end)

                    return self
                end

                -- Auto-add if settings.keybind == true
                if settings.keybind then
                    CheckboxManager:AddKeybind()
                end

                return CheckboxManager
            end


            function ModuleManager:create_toggle(settings: any)
                settings = settings or {}
                settings.callback = settings.callback or function() end
                settings.flag = settings.flag or ("Toggle_" .. tostring(math.random(10000, 99999)))

                LayoutOrderModule = LayoutOrderModule + 1
                local ToggleManager = { _state = false }

                if self._size == 0 then
                    self._size = 11
                end
                self._size += 28

                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)
                Options.Size = UDim2.fromOffset(241, self._size + 8)

                local Row = Instance.new("TextButton")
                Row.Name = "Toggle"
                Row.Size = UDim2.new(0, 207, 0, 22)
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0
                Row.Text = ""
                Row.AutoButtonColor = false
                Row.Parent = Options
                Row.LayoutOrder = LayoutOrderModule

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "Title"
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Size = UDim2.new(1, -55, 1, 0)
                TitleLabel.Position = UDim2.new(0, 0, 0, 0)
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 13
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLabel.TextTransparency = 0.05
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Text = settings.title or "Toggle"
                TitleLabel.Parent = Row

                -- Switch track
                local Track = Instance.new("Frame")
                Track.Name = "Track"
                Track.Size = UDim2.fromOffset(40, 20)
                Track.Position = UDim2.new(1, 0, 0.5, 0)
                Track.AnchorPoint = Vector2.new(1, 0.5)
                Track.BackgroundColor3 = Color3.fromRGB(35, 28, 50)
                Track.BorderSizePixel = 0
                Track.Parent = Row

                local TrackCorner = Instance.new("UICorner")
                TrackCorner.CornerRadius = UDim.new(1, 0)
                TrackCorner.Parent = Track

                local TrackStroke = Instance.new("UIStroke")
                TrackStroke.Color = Color3.fromRGB(90, 55, 150)
                TrackStroke.Transparency = 0.55
                TrackStroke.Thickness = 1
                TrackStroke.Parent = Track

                -- Circle knob
                local Knob = Instance.new("Frame")
                Knob.Name = "Knob"
                Knob.Size = UDim2.fromOffset(16, 16)
                Knob.Position = UDim2.new(0, 2, 0.5, 0)
                Knob.AnchorPoint = Vector2.new(0, 0.5)
                Knob.BackgroundColor3 = Color3.fromRGB(180, 170, 200)
                Knob.BorderSizePixel = 0
                Knob.Parent = Track

                local KnobCorner = Instance.new("UICorner")
                KnobCorner.CornerRadius = UDim.new(1, 0)
                KnobCorner.Parent = Knob

                function ToggleManager:change_state(state: boolean)
                    self._state = state and true or false
                    if self._state then
                        TweenService:Create(Track, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundColor3 = Color3.fromRGB(130, 70, 220)
                        }):Play()
                        TweenService:Create(Knob, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Position = UDim2.new(1, -18, 0.5, 0),
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        }):Play()
                        TweenService:Create(TrackStroke, TweenInfo.new(0.25), {
                            Color = Color3.fromRGB(160, 100, 255),
                            Transparency = 0.25
                        }):Play()
                    else
                        TweenService:Create(Track, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundColor3 = Color3.fromRGB(35, 28, 50)
                        }):Play()
                        TweenService:Create(Knob, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, 2, 0.5, 0),
                            BackgroundColor3 = Color3.fromRGB(180, 170, 200)
                        }):Play()
                        TweenService:Create(TrackStroke, TweenInfo.new(0.25), {
                            Color = Color3.fromRGB(90, 55, 150),
                            Transparency = 0.55
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._state)
                end

                function ToggleManager:Get()
                    return self._state
                end

                function ToggleManager:Set(state)
                    self:change_state(state and true or false)
                end

                Library:RegisterElement(settings.flag, "toggle", function(v)
                    ToggleManager:Set(v)
                end, function()
                    return ToggleManager:Get()
                end)

                -- Optional keybind (same API as checkbox)
                function ToggleManager:AddKeybind()
                    if self._keybindAdded then return self end
                    self._keybindAdded = true

                    Track.Position = UDim2.new(1, 0, 0.5, 0)

                    local KeybindBox = Instance.new("TextButton")
                    KeybindBox.Name = "KeybindBox"
                    KeybindBox.Size = UDim2.fromOffset(32, 16)
                    KeybindBox.Position = UDim2.new(1, -48, 0.5, 0)
                    KeybindBox.AnchorPoint = Vector2.new(1, 0.5)
                    KeybindBox.BackgroundColor3 = Color3.fromRGB(45, 32, 70)
                    KeybindBox.BackgroundTransparency = 0.1
                    KeybindBox.BorderSizePixel = 0
                    KeybindBox.Text = ""
                    KeybindBox.AutoButtonColor = false
                    KeybindBox.ZIndex = 5
                    KeybindBox.Parent = Row

                    local KeybindCorner = Instance.new("UICorner")
                    KeybindCorner.CornerRadius = UDim.new(0, 4)
                    KeybindCorner.Parent = KeybindBox

                    local KeybindStroke = Instance.new("UIStroke")
                    KeybindStroke.Color = Color3.fromRGB(120, 70, 200)
                    KeybindStroke.Transparency = 0.45
                    KeybindStroke.Thickness = 1
                    KeybindStroke.Parent = KeybindBox

                    local KeybindLabel = Instance.new("TextLabel")
                    KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                    KeybindLabel.BackgroundTransparency = 1
                    KeybindLabel.TextColor3 = Color3.fromRGB(200, 185, 230)
                    KeybindLabel.TextSize = 9
                    KeybindLabel.Font = Enum.Font.Gotham
                    KeybindLabel.Text = Library._config._keybinds[settings.flag]
                        and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        or "Key"
                    KeybindLabel.Parent = KeybindBox

                    local function bind_key_listener()
                        if Connections[settings.flag .. "_keypress"] then
                            Connections[settings.flag .. "_keypress"]:Disconnect()
                            Connections[settings.flag .. "_keypress"] = nil
                        end
                        local stored = Library._config._keybinds[settings.flag]
                        if not stored then return end
                        Connections[settings.flag .. "_keypress"] = UserInputService.InputBegan:Connect(function(input, process)
                            if process then return end
                            if tostring(input.KeyCode) == stored then
                                ToggleManager:change_state(not ToggleManager._state)
                            end
                        end)
                    end
                    bind_key_listener()

                    KeybindBox.MouseButton1Click:Connect(function()
                        if Library._choosing_keybind then return end
                        Library._choosing_keybind = true
                        KeybindLabel.Text = "..."
                        local chooseConnection
                        chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                            if processed then return end
                            if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                            if keyInput.KeyCode == Enum.KeyCode.Unknown then return end
                            if keyInput.KeyCode == Enum.KeyCode.Backspace or keyInput.KeyCode == Enum.KeyCode.Escape then
                                Library._config._keybinds[settings.flag] = nil
                                Config:save(game.GameId, Library._config)
                                KeybindLabel.Text = "Key"
                                if Connections[settings.flag .. "_keypress"] then
                                    Connections[settings.flag .. "_keypress"]:Disconnect()
                                    Connections[settings.flag .. "_keypress"] = nil
                                end
                                if chooseConnection then chooseConnection:Disconnect() end
                                Library._choosing_keybind = false
                                return
                            end
                            Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                            Config:save(game.GameId, Library._config)
                            KeybindLabel.Text = string.gsub(tostring(keyInput.KeyCode), "Enum.KeyCode.", "")
                            bind_key_listener()
                            if chooseConnection then chooseConnection:Disconnect() end
                            Library._choosing_keybind = false
                        end)
                    end)

                    return self
                end

                if Library:flag_type(settings.flag, "boolean") then
                    ToggleManager:change_state(Library._config._flags[settings.flag])
                elseif settings.default ~= nil then
                    ToggleManager:change_state(settings.default)
                end

                Row.MouseButton1Click:Connect(function()
                    ToggleManager:change_state(not ToggleManager._state)
                end)

                if settings.keybind then
                    ToggleManager:AddKeybind()
                end

                return ToggleManager
            end

            function ModuleManager:create_divider(settings: any)
                
                LayoutOrderModule = LayoutOrderModule + 1;
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 34
            
                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)

                local dividerHeight = 1
                local dividerWidth = 207 
            
               
                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, dividerWidth, 0, 20) 
                OuterFrame.BackgroundTransparency = 1 
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
                    TextLabel.TextTransparency = 0
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                    TextLabel.BorderColor3 = Color3.fromRGB(90, 50, 140)
                    TextLabel.TextSize = 11
                    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;
                
-- Busca esta parte dentro de la función que crea los separadores
if not settings or settings and not settings.disableline then
    local Divider = Instance.new('Frame')
    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
    Divider.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- GRIS MEDIO (Antes era verde)
    Divider.BorderSizePixel = 0
    Divider.Name = 'Divider'
    Divider.Parent = OuterFrame
    Divider.ZIndex = 2
    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2)

    local Gradient = Instance.new('UIGradient')
    Gradient.Parent = Divider
    -- El gradiente ahora va de blanco a transparente de forma suave
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    Gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.4), -- Un poco de transparencia al centro
        NumberSequenceKeypoint.new(1, 1)
    })
                    Gradient.Rotation = 0 
                
                   
                    local UICorner = Instance.new('UICorner')
                    UICorner.CornerRadius = UDim.new(0, 2) 
                    UICorner.Parent = Divider

                end;
            
                return true;
            end
            
            function ModuleManager:create_slider(settings: any)
                -- Defaults
                settings.minimum_value = settings.minimum_value or 0
                settings.maximum_value = settings.maximum_value or 100
                settings.value = settings.value or settings.minimum_value
                settings.round_number = settings.round_number ~= false
                settings.callback = settings.callback or function() end

                LayoutOrderModule = LayoutOrderModule + 1

                local SliderManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 34

                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)

                Options.Size = UDim2.fromOffset(241, self._size + 8)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal);
                Slider.TextSize = 14;
                Slider.TextColor3 = Color3.fromRGB(90, 50, 140)
                Slider.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 24)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(90, 50, 140)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule
                
                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 12;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 12;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05000000074505806, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(90, 50, 140)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Slider
                
                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.8999999761581421
                Drag.Position = UDim2.new(0.5, 0, 0.949999988079071, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Drag.Parent = Slider
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag
                
                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.Parent = Drag
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill
                
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
                }
                UIGradient.Parent = Fill
                
                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.Parent = Fill
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.TextTransparency = 0.20000000298023224
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Value.TextSize = 12
                Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Value.Parent = Slider

                function SliderManager:set_percentage(percentage: number)
                    local rounded_number = 0

                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end

                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)
                    
                    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)
    
                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = number_threshold
    
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()
    
                    settings.callback(number_threshold)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()
    
                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)
                    
                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input: InputObject, process: boolean)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
    
                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)

                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config);
                        end;
                    end)
                end


                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag]);
                    else
                        SliderManager:set_percentage(settings.value);
                    end;
                else
                    SliderManager:set_percentage(settings.value);
                end;
    
                Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                function SliderManager:Set(value)
                    self:set_percentage(tonumber(value) or settings.minimum_value or 0)
                end

                function SliderManager:Get()
                    return Library._config._flags[settings.flag]
                end

                Library:RegisterElement(settings.flag, "slider", function(v)
                    SliderManager:Set(v)
                end, function()
                    return SliderManager:Get()
                end)

                return SliderManager
            end

            function ModuleManager:create_dropdown(settings: any)
                -- Defaults to avoid nil comparison errors
                settings.options = settings.options or {}
                settings.maximum_options = settings.maximum_options or 999
                settings.multi_dropdown = settings.multi_dropdown or false
                settings.callback = settings.callback or function() end

                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1;
                end;

                local DropdownManager = {
                    _state = false,
                    _size = 0
                }

                if not settings.Order then
                    if self._size == 0 then
                        self._size = 11
                    end

                    self._size += 50
                end;

                if not settings.Order then
                    Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)
                    Options.Size = UDim2.fromOffset(241, self._size + 8)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(200, 200, 200)
                Dropdown.BorderColor3 = Color3.fromRGB(40, 40, 40)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 40)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(90, 50, 140)
                Dropdown.Parent = Options

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule;
                else
                    Dropdown.LayoutOrder = settings.OrderValue;
                end;

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {};
                end;
                
                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 12;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                    TextLabel.TextSize = 12;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(90, 50, 140)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Dropdown
                
                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(60, 60, 60)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.8999999761581421
                Box.Position = UDim2.new(0.5, 0, 1.2000000476837158, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                Box.Parent = TextLabel
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Box
                
                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.BorderSizePixel = 0
                Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Header.Parent = Box
                
                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.TextTransparency = 0.20000000298023224
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Text = ""
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.04999988153576851, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(90, 50, 140)
                CurrentOption.TextSize = 12
                CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.Parent = Header
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.704, 0),
                    NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                    NumberSequenceKeypoint.new(1, 1)
                }
                UIGradient.Parent = CurrentOption
                
                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.9100000262260437, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Arrow.Parent = Header
                
                local Options = Instance.new('ScrollingFrame')
                Options.ScrollBarImageColor3 = Color3.fromRGB(140, 80, 220)
                Options.Active = true
                Options.ScrollBarImageTransparency = 1
                Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
                Options.ScrollBarThickness = 0
                Options.Name = 'Options'
                Options.Size = UDim2.new(0, 207, 0, 0)
                Options.BackgroundTransparency = 1
                Options.Position = UDim2.new(0, 0, 1, 0)
                Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Options.BorderColor3 = Color3.fromRGB(90, 50, 140)
                Options.BorderSizePixel = 0
                Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                Options.Parent = Box
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Options
                
                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = Options
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Box

                function DropdownManager:update(option: string)
                    
                    if settings.multi_dropdown then
                     

                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {};
                        end;

                        local CurrentTargetValue = nil;
                        
                        if #Library._config._flags[settings.flag] > 0 then

                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag]);

                        end;

                        local selected = {}

                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do
                               
                                local trimmedValue = value:match("^%s*(.-)%s*$")  
                                
                              
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do
                             
                                local trimmedValue = value:match("^%s*(.-)%s*$") 
                                
                                
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        end;
                
                        local CurrentTextGet = convertStringToTable(CurrentOption.Text);

                        local optionSkibidi = "nil"
                        if typeof(option) == "string" then
                            optionSkibidi = option
                        elseif typeof(option) == "table" and option.Name then
                            optionSkibidi = tostring(option.Name)
                        elseif option ~= nil then
                            optionSkibidi = tostring(option)
                        end

                        local found = false
                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i);
                                break;
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}
                       
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        CurrentTargetValue = convertStringToTable(CurrentOption.Text);

                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end;
                        end;

                        CurrentOption.Text = table.concat(selected, ", ");
                
                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text);
                    else
                        local textValue = value_to_display(option)
                        if textValue == "" and settings.options and settings.options[1] then
                            option = settings.options[1]
                            textValue = value_to_display(option)
                        end
                        if textValue == "" then
                            textValue = "None"
                        end

                        CurrentOption.Text = textValue
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                if object.Text == CurrentOption.Text then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        -- Always store a string for single dropdowns (never a table ref)
                        Library._config._flags[settings.flag] = textValue
                    end
                
                   
                    Config:save(game.GameId, Library._config)
                
                  
                    settings.callback(option)
                end
                
                local CurrentDropSizeState = 0;

                function DropdownManager:unfold_settings()
                    self._state = not self._state

                    if self._state then
                        ModuleManager._multiplier += self._size

                        CurrentDropSizeState = self._size;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39 + self._size)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22 + self._size)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180
                        }):Play()
                    else
                        ModuleManager._multiplier -= self._size

                        CurrentDropSizeState = 0;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0
                        }):Play()
                    end
                end

                if #settings.options > 0 then
                    DropdownManager._size = 3

                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6000000238418579
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 12
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.BorderColor3 = Color3.fromRGB(90, 50, 140)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Parent = Options
                        
                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {};
                            end;

                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end

                            DropdownManager:update(value)
                        end)
    
                        if index > settings.maximum_options then
                            continue
                        end
    
                        DropdownManager._size += 16
                        Options.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                end

                function DropdownManager:New(value)
                    local oldOrder = Dropdown.LayoutOrder
                    Dropdown:Destroy()
                    value.Order = true
                    value.OrderValue = oldOrder
                    ModuleManager._multiplier -= CurrentDropSizeState
                    return ModuleManager:create_dropdown(value)
                end;

                function DropdownManager:Set(value)
                    if settings.multi_dropdown then
                        local selected = {}
                        if type(value) == "table" then
                            for _, v in pairs(value) do
                                local s = value_to_display(v)
                                if s ~= "" then
                                    table.insert(selected, s)
                                end
                            end
                        elseif type(value) == "string" and value ~= "" then
                            selected = convertStringToTable(value)
                        end
                        Library._config._flags[settings.flag] = selected
                        local display = table.concat(selected, ", ")
                        CurrentOption.Text = (display ~= "" and display) or "None"
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        settings.callback(selected)
                    else
                        local textValue = value_to_display(value)
                        if textValue == "" then
                            value = settings.options and settings.options[1]
                            textValue = value_to_display(value)
                        end
                        if textValue ~= "" then
                            self:update(textValue)
                        else
                            CurrentOption.Text = "None"
                            Library._config._flags[settings.flag] = nil
                        end
                    end
                end

                function DropdownManager:Get()
                    local v = Library._config._flags[settings.flag]
                    if settings.multi_dropdown then
                        return type(v) == "table" and v or {}
                    end
                    return value_to_display(v)
                end

                Library:RegisterElement(settings.flag, "dropdown", function(v)
                    DropdownManager:Set(v)
                end, function()
                    return DropdownManager:Get()
                end)

                local initialValue = nil
                if Library:flag_type(settings.flag, "string") or Library:flag_type(settings.flag, "table") then
                    initialValue = Library._config._flags[settings.flag]
                end
                if initialValue == nil or initialValue == "" then
                    if settings.default ~= nil then
                        initialValue = settings.default
                    elseif settings.multi_dropdown then
                        initialValue = {}
                    else
                        initialValue = settings.options and settings.options[1]
                    end
                end
                if initialValue ~= nil then
                    DropdownManager:Set(initialValue)
                else
                    CurrentOption.Text = "None"
                end
    
                Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)

                return DropdownManager
            end

            function ModuleManager:create_button(settings: any)
                settings = settings or {}
                settings.callback = settings.callback or settings.button_callback or function() end
                settings.title = settings.title or "Button"

                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then
                    self._size = 11
                end
                self._size += 32

                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)
                Options.Size = UDim2.fromOffset(241, self._size + 8)

                -- Row-style button (title left + chevron right)
                local Button = Instance.new("TextButton")
                Button.Name = "Button"
                Button.Size = UDim2.new(0, 207, 0, 30)
                Button.BackgroundColor3 = Color3.fromRGB(28, 24, 36)
                Button.BackgroundTransparency = 0.25
                Button.BorderSizePixel = 0
                Button.AutoButtonColor = false
                Button.Text = ""
                Button.Parent = Options
                Button.LayoutOrder = LayoutOrderModule

                local Corner = Instance.new("UICorner")
                Corner.CornerRadius = UDim.new(0, 8)
                Corner.Parent = Button

                local Stroke = Instance.new("UIStroke")
                Stroke.Color = Color3.fromRGB(70, 55, 95)
                Stroke.Transparency = 0.55
                Stroke.Thickness = 1
                Stroke.Parent = Button

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "Title"
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Size = UDim2.new(1, -36, 1, 0)
                TitleLabel.Position = UDim2.new(0, 12, 0, 0)
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 13
                TitleLabel.TextColor3 = Color3.fromRGB(235, 230, 245)
                TitleLabel.TextTransparency = 0.05
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
                TitleLabel.Text = settings.title
                TitleLabel.Parent = Button

                local Chevron = Instance.new("TextLabel")
                Chevron.Name = "Chevron"
                Chevron.BackgroundTransparency = 1
                Chevron.Size = UDim2.new(0, 20, 1, 0)
                Chevron.Position = UDim2.new(1, -24, 0, 0)
                Chevron.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                Chevron.TextSize = 16
                Chevron.TextColor3 = Color3.fromRGB(160, 150, 180)
                Chevron.TextTransparency = 0.15
                Chevron.Text = "›"
                Chevron.TextXAlignment = Enum.TextXAlignment.Center
                Chevron.TextYAlignment = Enum.TextYAlignment.Center
                Chevron.Parent = Button

                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.18), {
                        BackgroundColor3 = Color3.fromRGB(42, 34, 58),
                        BackgroundTransparency = 0.05
                    }):Play()
                    TweenService:Create(Stroke, TweenInfo.new(0.18), {
                        Color = Color3.fromRGB(130, 90, 200),
                        Transparency = 0.3
                    }):Play()
                    TweenService:Create(Chevron, TweenInfo.new(0.18), {
                        TextColor3 = Color3.fromRGB(210, 190, 255),
                        TextTransparency = 0
                    }):Play()
                    TweenService:Create(TitleLabel, TweenInfo.new(0.18), {
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                end)

                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.18), {
                        BackgroundColor3 = Color3.fromRGB(28, 24, 36),
                        BackgroundTransparency = 0.25
                    }):Play()
                    TweenService:Create(Stroke, TweenInfo.new(0.18), {
                        Color = Color3.fromRGB(70, 55, 95),
                        Transparency = 0.55
                    }):Play()
                    TweenService:Create(Chevron, TweenInfo.new(0.18), {
                        TextColor3 = Color3.fromRGB(160, 150, 180),
                        TextTransparency = 0.15
                    }):Play()
                    TweenService:Create(TitleLabel, TweenInfo.new(0.18), {
                        TextColor3 = Color3.fromRGB(235, 230, 245)
                    }):Play()
                end)

                Button.MouseButton1Click:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.06), {
                        BackgroundTransparency = 0
                    }):Play()
                    task.delay(0.07, function()
                        TweenService:Create(Button, TweenInfo.new(0.12), {
                            BackgroundTransparency = 0.05
                        }):Play()
                    end)
                    settings.callback()
                end)

                return {
                    Button = Button,
                    SetText = function(_, text)
                        TitleLabel.Text = tostring(text or "")
                    end
                }
            end

            function ModuleManager:create_feature(settings)
                settings = settings or {}
                settings.title = settings.title or "Feature"
                settings.callback = settings.callback or function() end
                settings.button_callback = settings.button_callback or function() end

                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then
                    self._size = 11
                end
                self._size += 32

                Module.Size = UDim2.fromOffset(241, (showModuleToggle and 102 or 56) + self._size)
                Options.Size = UDim2.fromOffset(241, self._size + 8)

                -- Same row style as create_button
                local FeatureButton = Instance.new("TextButton")
                FeatureButton.Name = "FeatureButton"
                FeatureButton.Size = UDim2.new(0, 207, 0, 30)
                FeatureButton.BackgroundColor3 = Color3.fromRGB(28, 24, 36)
                FeatureButton.BackgroundTransparency = 0.25
                FeatureButton.BorderSizePixel = 0
                FeatureButton.AutoButtonColor = false
                FeatureButton.Text = ""
                FeatureButton.Parent = Options
                FeatureButton.LayoutOrder = LayoutOrderModule

                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UDim.new(0, 8)
                BtnCorner.Parent = FeatureButton

                local BtnStroke = Instance.new("UIStroke")
                BtnStroke.Color = Color3.fromRGB(70, 55, 95)
                BtnStroke.Transparency = 0.55
                BtnStroke.Thickness = 1
                BtnStroke.Parent = FeatureButton

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "Title"
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Size = UDim2.new(1, -36, 1, 0)
                TitleLabel.Position = UDim2.new(0, 12, 0, 0)
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 13
                TitleLabel.TextColor3 = Color3.fromRGB(235, 230, 245)
                TitleLabel.TextTransparency = 0.05
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
                TitleLabel.Text = settings.title
                TitleLabel.Parent = FeatureButton

                local Chevron = Instance.new("TextLabel")
                Chevron.Name = "Chevron"
                Chevron.BackgroundTransparency = 1
                Chevron.Size = UDim2.new(0, 20, 1, 0)
                Chevron.Position = UDim2.new(1, -24, 0, 0)
                Chevron.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                Chevron.TextSize = 16
                Chevron.TextColor3 = Color3.fromRGB(160, 150, 180)
                Chevron.TextTransparency = 0.15
                Chevron.Text = "›"
                Chevron.TextXAlignment = Enum.TextXAlignment.Center
                Chevron.TextYAlignment = Enum.TextYAlignment.Center
                Chevron.Parent = FeatureButton

                FeatureButton.MouseEnter:Connect(function()
                    TweenService:Create(FeatureButton, TweenInfo.new(0.18), {
                        BackgroundColor3 = Color3.fromRGB(42, 34, 58),
                        BackgroundTransparency = 0.05
                    }):Play()
                    TweenService:Create(BtnStroke, TweenInfo.new(0.18), {
                        Color = Color3.fromRGB(130, 90, 200),
                        Transparency = 0.3
                    }):Play()
                    TweenService:Create(Chevron, TweenInfo.new(0.18), {
                        TextColor3 = Color3.fromRGB(210, 190, 255),
                        TextTransparency = 0
                    }):Play()
                end)

                FeatureButton.MouseLeave:Connect(function()
                    TweenService:Create(FeatureButton, TweenInfo.new(0.18), {
                        BackgroundColor3 = Color3.fromRGB(28, 24, 36),
                        BackgroundTransparency = 0.25
                    }):Play()
                    TweenService:Create(BtnStroke, TweenInfo.new(0.18), {
                        Color = Color3.fromRGB(70, 55, 95),
                        Transparency = 0.55
                    }):Play()
                    TweenService:Create(Chevron, TweenInfo.new(0.18), {
                        TextColor3 = Color3.fromRGB(160, 150, 180),
                        TextTransparency = 0.15
                    }):Play()
                end)

                FeatureButton.MouseButton1Click:Connect(function()
                    TweenService:Create(FeatureButton, TweenInfo.new(0.06), {
                        BackgroundTransparency = 0
                    }):Play()
                    task.delay(0.07, function()
                        TweenService:Create(FeatureButton, TweenInfo.new(0.12), {
                            BackgroundTransparency = 0.05
                        }):Play()
                    end)
                    settings.button_callback()
                end)

                return {
                    Button = FeatureButton,
                    SetText = function(_, text)
                        TitleLabel.Text = tostring(text or "")
                    end
                }
            end

            -- Ensure module starts expanded so options are always visible
            if ModuleManager._size > 0 then
                local hb = showModuleToggle and 102 or 56
                Module.Size = UDim2.fromOffset(241, hb + ModuleManager._size + ModuleManager._multiplier)
            end

            if showModuleToggle and settings.flag then
                Library:RegisterElement(settings.flag, "module", function(v)
                    ModuleManager:change_state(v and true or false)
                end, function()
                    return ModuleManager._state
                end)
            end

            return ModuleManager
        end

        return TabManager
    end

    -- Configurable keybind = fully hide / show UI
    local toggleKey = self._settings.Keybind or Enum.KeyCode.RightControl
    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
        if process then return end
        if input.KeyCode ~= toggleKey then
            return
        end
        self:change_visiblity(not self._ui_open)
    end)

    -- TopBar MinimizeBtn = fully hide
    local minBtn = self._ui.Container:FindFirstChild('MinimizeBtn', true)
    if minBtn then
        minBtn.MouseButton1Click:Connect(function()
            self:change_visiblity(false)
        end)
    end

    -- Old Handler.Minimize stays unused / or also hide
    if self._ui.Container.Handler:FindFirstChild('Minimize') then
        self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
            self:change_visiblity(not self._ui_open)
        end)
    end

    -- Logo / Icon click = shrink to compact bar (not full hide)
    local logoIcon = self._ui.Container.Handler:FindFirstChild('Icon')
    if logoIcon then
        logoIcon.Active = true
        logoIcon.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local isFull = Container.Size.X.Offset > 200
                self:shrink_to_bar(not isFull)
            end
        end)
    end

    -- Close button: destroy the whole UI
    local closeBtn = self._ui.Container:FindFirstChild('Close', true)
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(function()
            TweenService:Create(self._ui.Container, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.35, function()
                if self._toggleGui then
                    self._toggleGui:Destroy()
                    self._toggleGui = nil
                end
                if self._ui then
                    self._ui:Destroy()
                    self._ui = nil
                end
                Connections:disconnect_all()
            end)
        end)
    end

    -- ============================================
    --  Optional floating Toggle Icon (topmost)
    -- ============================================
    if self._settings.ToggleIcon then
        local oldToggle = CoreGui:FindFirstChild("ZexHubToggle")
        if oldToggle then
            oldToggle:Destroy()
        end

        local ToggleGui = Instance.new("ScreenGui")
        ToggleGui.Name = "ZexHubToggle"
        ToggleGui.ResetOnSpawn = false
        ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        ToggleGui.DisplayOrder = 999999999
        ToggleGui.IgnoreGuiInset = true
        ToggleGui.Parent = CoreGui
        self._toggleGui = ToggleGui

        local BASE_SIZE = self._settings.ToggleIconSize or 60
        local CLICK_SIZE = math.floor(BASE_SIZE * 0.83)
        local HOVER_SIZE = math.floor(BASE_SIZE * 1.08)

        local Button = Instance.new("ImageButton")
        Button.Name = "ToggleButton"
        Button.Size = UDim2.fromOffset(BASE_SIZE, BASE_SIZE)
        Button.Position = UDim2.new(0.5, -BASE_SIZE / 2, 0, 18)
        Button.BackgroundTransparency = 0.45
        Button.BackgroundColor3 = Color3.fromRGB(28, 20, 42)
        Button.Image = self._settings.ToggleIconImage or "rbxassetid://130655920174103"
        Button.ImageColor3 = Color3.fromRGB(230, 220, 255)
        Button.ScaleType = Enum.ScaleType.Fit
        Button.Active = true
        Button.Draggable = true
        Button.ZIndex = 999999999
        Button.Parent = ToggleGui

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(1, 0)
        BtnCorner.Parent = Button

        local glow = Instance.new("UIStroke")
        glow.Parent = Button
        glow.Thickness = 2
        glow.Color = Color3.fromRGB(150, 80, 255)
        glow.Transparency = 0.45

        task.spawn(function()
            while Button and Button.Parent do
                TweenService:Create(glow, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.12
                }):Play()
                task.wait(0.65)
                TweenService:Create(glow, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.55
                }):Play()
                task.wait(0.65)
            end
        end)

        local function ClickAnimation()
            local shrink = TweenService:Create(Button, TweenInfo.new(0.05), {
                Size = UDim2.fromOffset(CLICK_SIZE, CLICK_SIZE)
            })
            local expand = TweenService:Create(Button, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
                Size = UDim2.fromOffset(BASE_SIZE, BASE_SIZE)
            })
            shrink:Play()
            shrink.Completed:Connect(function()
                expand:Play()
            end)
        end

        local function RippleEffect()
            local ripple = Instance.new("Frame")
            ripple.Parent = Button
            ripple.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
            ripple.BackgroundTransparency = 0.45
            ripple.Size = UDim2.fromOffset(0, 0)
            ripple.AnchorPoint = Vector2.new(0.5, 0.5)
            ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
            ripple.ZIndex = Button.ZIndex + 1
            local rc = Instance.new("UICorner")
            rc.CornerRadius = UDim.new(1, 0)
            rc.Parent = ripple
            local tween = TweenService:Create(ripple, TweenInfo.new(0.32), {
                Size = UDim2.fromOffset(BASE_SIZE * 2, BASE_SIZE * 2),
                BackgroundTransparency = 1
            })
            tween:Play()
            tween.Completed:Connect(function()
                ripple:Destroy()
            end)
        end

        local function FlashEffect()
            local tween = TweenService:Create(Button, TweenInfo.new(0.08), {
                BackgroundTransparency = 0.15
            })
            local back = TweenService:Create(Button, TweenInfo.new(0.18), {
                BackgroundTransparency = 0.45
            })
            tween:Play()
            tween.Completed:Connect(function()
                back:Play()
            end)
        end

        local function ColorPulse()
            local tween = TweenService:Create(Button, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(70, 40, 110)
            })
            local back = TweenService:Create(Button, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(28, 20, 42)
            })
            tween:Play()
            tween.Completed:Connect(function()
                back:Play()
            end)
        end

        Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.12), {
                Size = UDim2.fromOffset(HOVER_SIZE, HOVER_SIZE)
            }):Play()
        end)

        Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.12), {
                Size = UDim2.fromOffset(BASE_SIZE, BASE_SIZE)
            }):Play()
        end)

        Button.MouseButton1Click:Connect(function()
            task.spawn(ClickAnimation)
            task.spawn(FlashEffect)
            task.spawn(ColorPulse)
            RippleEffect()
            TweenService:Create(Button, TweenInfo.new(0.15), {
                Rotation = Button.Rotation + 18
            }):Play()
            self:change_visiblity(not self._ui_open)
        end)

        self:removed(function()
            if self._toggleGui then
                self._toggleGui:Destroy()
                self._toggleGui = nil
            end
        end)
    end

    return self
end


-- ============================================
--  ZexHub UI Library (Clean Version)
--  Solo la librería, sin scripts de juego.
--
--  Uso:
--      local Library = loadstring(game:HttpGet("RAW_GITHUB_URL"))()
--
--      local Window = Library.new({
--          Title = "ZEX HUB <font color='#FFD700'><b>PREMIUM</b></font>",
--          Subtitle = "<font color='#33ff00'><b>San Diego Border Roleplay</b></font>",
--          Icon = "rbxassetid://130655920174103",   -- logo de la UI
--          Keybind = Enum.KeyCode.RightControl,
--          ToggleIcon = true,
--          ToggleIconImage = "rbxassetid://130655920174103",
--          ToggleIconSize = 60,
--      })
--
--      Window:load()
--
--      -- Cambiar en runtime:
--      Window:SetTitle("ZEX HUB <font color='#FFD700'><b>PREMIUM</b></font>")
--      Window:SetSubtitle("<font color='#33ff00'><b>Mi Juego</b></font>")
--      Window:SetIcon("rbxassetid://123456789")
--      Window:SetState(true)   -- abrir
--      Window:SetState(false)  -- cerrar
-- ============================================

return Library
