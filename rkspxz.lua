
-- Interface nativa rkspxz. Este arquivo e incorporado na entrega completa.
local function createRKInterface()
    local Players = game:GetService("Players")
    local Input = game:GetService("UserInputService")
    local Tween = game:GetService("TweenService")
    local palette = {
        background = Color3.fromRGB(15, 16, 23),
        sidebar = Color3.fromRGB(20, 21, 30),
        card = Color3.fromRGB(27, 29, 41),
        text = Color3.fromRGB(242, 241, 250),
        muted = Color3.fromRGB(151, 154, 175),
        accent = Color3.fromRGB(154, 119, 255),
        line = Color3.fromRGB(49, 51, 69),
    }
    local accentTargets, listeners = {}, {}
    local api = {}
    local screen, window, notifyHost
    local selectedTab
    local themeCallbacks = {}
    local destroyCallbacks = {}
    local key = Enum.KeyCode.Zero
    local bindings = {}
    local bindingCapture
    local alive = true

    local function make(class, props, parent)
        local object = Instance.new(class)
        for property, value in pairs(props or {}) do object[property] = value end
        object.Parent = parent
        return object
    end
    local function corner(object, radius)
        make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, object)
    end
    local function connect(event, callback)
        local connection = event:Connect(callback)
        table.insert(listeners, connection)
        return connection
    end
    local function text(parent, value, size, color)
        return make("TextLabel", {
            BackgroundTransparency = 1, Text = value or "", TextSize = size or 14,
            Font = Enum.Font.Gotham, TextColor3 = color or palette.text,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        }, parent)
    end
    local function accent(object, property)
        table.insert(accentTargets, {object, property})
        object[property] = palette.accent
    end
    local function clickable(parent, caption)
        local object = make("TextButton", {
            BackgroundColor3 = palette.card, Text = caption or "", TextSize = 13,
            TextColor3 = palette.text, Font = Enum.Font.GothamBold,
            BorderSizePixel = 0, AutoButtonColor = true,
        }, parent)
        corner(object, 8)
        return object
    end
    local function call(callback, ...)
        if type(callback) ~= "function" then return end
        local args = table.pack(...)
        task.spawn(function()
            if not alive then return end
            local ok, err = pcall(callback, table.unpack(args, 1, args.n))
            if not ok then
                warn("rkspxz: " .. tostring(err))
                api:Notify({Title = "Erro na funcao", Desc = tostring(err), Duration = 6})
            end
        end)
    end

    function api:SetTheme(name)
        if not screen then return end
        local themes = {
            Rose = "#F472B6", Easter = "#C084FC", CottonCandy = "#E879F9",
            Dark = "#A1A1AA", Light = "#D4D4D8", Midnight = "#60A5FA",
            Crimson = "#FB7185", Violet = "#9A77FF", Indigo = "#818CF8",
            Sky = "#22D3EE", Plant = "#86EFAC", Red = "#F87171",
            Emerald = "#34D399", Amber = "#FBBF24", MonokaiPro = "#FC9867",
            Mellowsi = "#C9B79C", Rainbow = "#A78BFA",
        }
        palette.accent = Color3.fromHex(themes[name] or "#9A77FF")
        for _, item in ipairs(accentTargets) do
            if item[1].Parent then item[1][item[2]] = palette.accent end
        end
        if selectedTab then selectedTab.nav.TextColor3 = palette.accent end
        for _, callback in ipairs(themeCallbacks) do call(callback, name) end
    end
    function api:SetFont() end
    function api:OnThemeChange(callback) table.insert(themeCallbacks, callback) end
    function api:IsAlive() return alive end
    function api:OnInterfaceDestroyed(callback)
        if alive then table.insert(destroyCallbacks, callback) else pcall(callback) end
    end
    -- Chamadas mantidas para compatibilidade; sem notificacoes na tela.
    function api:Notify() end

    function api:CreateWindow(config)
        local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
        local old = pg:FindFirstChild("RKSPXZ_NewInterface")
        if old then old:Destroy() end
        screen = make("ScreenGui", {Name = "RKSPXZ_NewInterface", ResetOnSpawn = false,
            IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
        connect(screen.Destroying, function()
            alive = false
            for _, callback in ipairs(destroyCallbacks) do pcall(callback) end
            for _, connection in ipairs(listeners) do connection:Disconnect() end
        end)
        window = make("Frame", {
            Size = UDim2.fromOffset(780, 530), Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = palette.background,
            BorderSizePixel = 0, ClipsDescendants = true,
        }, screen)
        corner(window, 14)
        local stroke = make("UIStroke", {Thickness = 1, Color = palette.line, Transparency = 0.2}, window)
        local borderGradient = make("UIGradient", {}, stroke)
        local scale = make("UIScale", {Scale = 1}, window)
        local function fit()
            local camera = workspace.CurrentCamera
            if camera then
                local viewport = camera.ViewportSize
                scale.Scale = math.min(1, (viewport.X - 24) / 780, (viewport.Y - 70) / 530)
            end
        end
        fit()
        if workspace.CurrentCamera then connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fit) end

        local header = make("Frame", {Size = UDim2.new(1, 0, 0, 68), BackgroundColor3 = palette.sidebar,
            BorderSizePixel = 0, Active = true}, window)
        local brand = text(header, "rkspxz", 25)
        brand.Position = UDim2.fromOffset(22, 9)
        brand.Size = UDim2.fromOffset(160, 30)
        brand.Font = Enum.Font.GothamBold
        local subtitle = text(header, "MURDER MYSTERY 2", 9, palette.muted)
        subtitle.Position = UDim2.fromOffset(23, 40)
        subtitle.Size = UDim2.fromOffset(210, 16)
        local badge = text(header, "CONTROL PANEL", 10)
        badge.Position = UDim2.new(1, -250, 0, 23)
        badge.Size = UDim2.fromOffset(135, 22)
        accent(badge, "TextColor3")
        local hide = clickable(header, "−")
        hide.Size = UDim2.fromOffset(36, 32)
        hide.Position = UDim2.new(1, -94, 0, 18)
        local close = clickable(header, "×")
        close.Size = UDim2.fromOffset(36, 32)
        close.Position = UDim2.new(1, -50, 0, 18)

        local opener = clickable(screen, "rkspxz  /  ABRIR")
        opener.Size = UDim2.fromOffset(164, 40)
        opener.Position = UDim2.new(0, 18, 1, -58)
        local openGradient = make("UIGradient", {}, opener)
        local function visible(value) window.Visible = value end
        connect(hide.Activated, function() visible(false) end)
        connect(close.Activated, function() screen:Destroy() end)
        connect(opener.Activated, function() visible(not window.Visible) end)
        connect(Input.InputBegan, function(input, processed)
            if input.UserInputType ~= Enum.UserInputType.Keyboard or Input:GetFocusedTextBox() then return end
            if bindingCapture then
                local binding = bindingCapture
                if input.KeyCode == Enum.KeyCode.Escape then
                    bindingCapture = nil
                    binding.render()
                    return
                end
                if input.KeyCode == key then binding.render("0 reservado ao menu / escolha outra tecla"); return end
                if input.KeyCode == Enum.KeyCode.Unknown then return end
                local chosen = input.KeyCode ~= Enum.KeyCode.Backspace and input.KeyCode or nil
                for _, other in ipairs(bindings) do
                    if other ~= binding and chosen and other.key == chosen then
                        binding.render("Tecla ja usada / escolha outra")
                        return
                    end
                end
                binding.key = chosen
                bindingCapture = nil
                binding.render()
                call(binding.changed, chosen)
                return
            end
            if input.KeyCode == key then
                if not processed then visible(not window.Visible) end
                return
            end
            for _, binding in ipairs(bindings) do
                if binding.key and input.KeyCode == binding.key and (not processed or binding.allowProcessed) then call(binding.callback) end
            end
        end)
        local dragging, dragOrigin, originalPosition, dragTouch
        connect(header.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragOrigin, originalPosition = true, input.Position, window.Position
                dragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
            end
        end)
        connect(Input.InputChanged, function(input)
            if dragging and (input == dragTouch or input.UserInputType == Enum.UserInputType.MouseMovement and not dragTouch) then
                local delta = input.Position - dragOrigin
                window.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset + delta.X,
                    originalPosition.Y.Scale, originalPosition.Y.Offset + delta.Y)
            end
        end)
        connect(Input.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input == dragTouch then dragging = false end
        end)

        local sidebar = make("ScrollingFrame", {Position = UDim2.fromOffset(0, 68),
            Size = UDim2.new(0, 184, 1, -100), BackgroundColor3 = palette.sidebar,
            BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y}, window)
        make("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, sidebar)
        make("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
        local content = make("Frame", {Position = UDim2.fromOffset(184, 68),
            Size = UDim2.new(1, -184, 1, -100), BackgroundTransparency = 1}, window)
        local footer = text(window, "0  /  MOSTRAR E MINIMIZAR       X  /  ENCERRAR       rkspxz", 9, palette.muted)
        footer.Position = UDim2.new(0, 20, 1, -28)
        footer.Size = UDim2.new(1, -40, 0, 20)
        notifyHost = make("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(290, 390)}, screen)
        make("UIListLayout", {Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right}, notifyHost)

        local methods = {}
        local navOrder = 0
        local function add(container, object)
            container.order = container.order + 1
            object.LayoutOrder = container.order
            object.Parent = container.holder
            return object
        end
        local function card(container, title, description, height)
            local frame = add(container, make("Frame", {Size = UDim2.new(1, -4, 0, height or 66),
                BackgroundColor3 = palette.card, BorderSizePixel = 0}))
            corner(frame, 10)
            local label = text(frame, title, 13)
            label.Font = Enum.Font.GothamBold
            label.Position = UDim2.fromOffset(14, description and 10 or 0)
            label.Size = UDim2.new(1, -28, 0, description and 22 or (height or 66))
            local desc
            if description then
                desc = text(frame, description, 10, palette.muted)
                desc.Position = UDim2.fromOffset(14, 33)
                desc.Size = UDim2.new(1, -28, 0, math.max(20, (height or 66) - 39))
                desc.TextWrapped = true
            end
            return frame, label, desc
        end
        local function container(holder)
            return setmetatable({holder = holder, order = 0}, {__index = methods})
        end
        function methods:Space()
            return add(self, make("Frame", {Size = UDim2.new(1, 0, 0, 5), BackgroundTransparency = 1}))
        end
        function methods:Section(options)
            local frame = add(self, make("Frame", {Size = UDim2.new(1, -4, 0, options.Desc and 53 or 33), BackgroundTransparency = 1}))
            local label = text(frame, string.upper(options.Title or ""), 10, palette.muted)
            label.Position = UDim2.fromOffset(2, 8)
            label.Size = UDim2.new(1, -4, 0, 22)
            if options.Desc then
                local desc = text(frame, options.Desc, 10, palette.muted)
                desc.Position = UDim2.fromOffset(2, 30)
                desc.Size = UDim2.new(1, -4, 0, 20)
                desc.TextWrapped = true
            end
            -- Seccoes organizam os mesmos controles sem caixas aninhadas.
            return self
        end
        function methods:Group() return self end
        function methods:Paragraph(options)
            local size = math.clamp(60 + math.ceil(#(options.Desc or "") / 65) * 15, 75, 200)
            return card(self, options.Title or "", options.Desc, size)
        end
        function methods:Code(options)
            return card(self, options.Title or "", options.Code or "", 320)
        end
        function methods:Button(options)
            local b = add(self, clickable(nil, (options.Title or "Executar") .. "    →"))
            b.Size = UDim2.new(1, -4, 0, 43)
            connect(b.Activated, function() call(options.Callback) end)
            local control = {}
            function control:SetText(value)
                if b.Parent then b.Text = tostring(value) .. "    →" end
            end
            function control:Highlight()
                if b.Parent then
                    b.BackgroundColor3 = palette.accent
                    Tween:Create(b, TweenInfo.new(0.3), {BackgroundColor3 = palette.card}):Play()
                end
            end
            return control
        end
        function methods:Keybind(options)
            local binding = {key = options.Default, callback = options.Callback, changed = options.Changed,
                allowProcessed = options.AllowProcessed == true}
            local button
            binding.render = function(message)
                button:SetText((options.Title or "Tecla") .. "  /  " .. (message or (binding.key and binding.key.Name or "Sem tecla")))
            end
            button = self:Button({
                Title = options.Title or "Tecla",
                Callback = function()
                    if bindingCapture and bindingCapture ~= binding then bindingCapture.render() end
                    bindingCapture = binding
                    binding.render("Pressione uma tecla / Esc cancela")
                end,
            })
            table.insert(bindings, binding)
            binding.render()
            return binding
        end
        function methods:Toggle(options)
            local frame, label, description = card(self, options.Title or "", options.Desc, options.Desc and 82 or 52)
            label.Size = UDim2.new(1, -95, 0, options.Desc and 22 or 52)
            local hit = make("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 3}, frame)
            local track = make("Frame", {Size = UDim2.fromOffset(42, 23), Position = UDim2.new(1, -57, 0, 15),
                BackgroundColor3 = palette.line, BorderSizePixel = 0}, frame)
            corner(track, 12)
            local knob = make("Frame", {Size = UDim2.fromOffset(17, 17), Position = UDim2.fromOffset(3, 3),
                BackgroundColor3 = palette.text, BorderSizePixel = 0}, track)
            corner(knob, 10)
            local state = options.Default == true
            local function render()
                track.BackgroundColor3 = state and palette.accent or palette.line
                knob.Position = UDim2.fromOffset(state and 22 or 3, 3)
            end
            local control = {}
            function control:SetDescription(value)
                if description and description.Parent then description.Text = tostring(value) end
            end
            function control:Set(value)
                state = value == true
                render()
                call(options.Callback, state)
            end
            function control:Toggle() control:Set(not state) end
            connect(hit.Activated, function() control:Set(not state) end)
            table.insert(themeCallbacks, function() if frame.Parent then render() end end)
            render()
            return control
        end
        function methods:Slider(options)
            local bounds = options.Value or {}
            local minimum, maximum = tonumber(bounds.Min) or 0, tonumber(bounds.Max) or 100
            local value = tonumber(bounds.Default) or minimum
            local step = tonumber(options.Step) or 1
            local frame, label = card(self, options.Title or "", nil, 82)
            label.Size = UDim2.new(1, -110, 0, 35)
            local valueBox = make("TextBox", {Size = UDim2.fromOffset(68, 26), Position = UDim2.new(1, -82, 0, 8),
                BackgroundColor3 = palette.background, TextColor3 = palette.text, Font = Enum.Font.GothamBold,
                TextSize = 12, Text = tostring(value), ClearTextOnFocus = false, BorderSizePixel = 0}, frame)
            corner(valueBox, 6)
            local track = make("Frame", {Position = UDim2.fromOffset(14, 53), Size = UDim2.new(1, -28, 0, 5),
                BackgroundColor3 = palette.line, BorderSizePixel = 0}, frame)
            corner(track, 3)
            local fill = make("Frame", {Size = UDim2.new(), BorderSizePixel = 0}, track)
            accent(fill, "BackgroundColor3")
            corner(fill, 3)
            local knob = make("Frame", {Size = UDim2.fromOffset(13, 13), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = palette.text, BorderSizePixel = 0}, track)
            corner(knob, 7)
            local hit = make("TextButton", {Position = UDim2.fromOffset(0, -12), Size = UDim2.new(1, 0, 0, 29),
                BackgroundTransparency = 1, Text = ""}, track)
            local function render()
                local fraction = (value - minimum) / math.max(maximum - minimum, 0.00001)
                fill.Size = UDim2.new(fraction, 0, 1, 0)
                knob.Position = UDim2.new(fraction, 0, 0.5, 0)
                valueBox.Text = tostring(value)
            end
            local control = {}
            function control:Set(newValue)
                newValue = tonumber(newValue)
                if not newValue or newValue ~= newValue then render(); return end
                value = math.clamp(math.floor(newValue / step + 0.5) * step, minimum, maximum)
                value = math.floor(value * 10000 + 0.5) / 10000
                render()
                call(options.Callback, value)
            end
            local draggingSlider, sliderTouch
            local function fromX(x)
                if track.AbsoluteSize.X > 0 then
                    control:Set(minimum + math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1) * (maximum - minimum))
                end
            end
            connect(hit.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    sliderTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
                    fromX(input.Position.X)
                end
            end)
            connect(Input.InputChanged, function(input)
                if draggingSlider and (input == sliderTouch or input.UserInputType == Enum.UserInputType.MouseMovement and not sliderTouch) then
                    fromX(input.Position.X)
                end
            end)
            connect(Input.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input == sliderTouch then draggingSlider = false end
            end)
            connect(valueBox.FocusLost, function() control:Set(valueBox.Text) end)
            render()
            return control
        end
        function methods:Input(options)
            local frame, label = card(self, options.Title or "", nil, 82)
            label.Size = UDim2.new(1, -28, 0, 30)
            local box = make("TextBox", {Position = UDim2.fromOffset(14, 36), Size = UDim2.new(1, -28, 0, 32),
                BackgroundColor3 = palette.background, TextColor3 = palette.text, TextSize = 12,
                Font = Enum.Font.Gotham, Text = options.Value or options.Default or "",
                PlaceholderText = options.PlaceholderText or "", ClearTextOnFocus = false, BorderSizePixel = 0}, frame)
            corner(box, 6)
            connect(box.FocusLost, function() call(options.Callback, box.Text) end)
            return {Set = function(_, value) box.Text = tostring(value); call(options.Callback, box.Text) end}
        end
        function methods:Dropdown(options)
            local frame, label = card(self, options.Title or "", nil, 78)
            label.Size = UDim2.new(1, -28, 0, 31)
            local trigger = clickable(frame, "")
            trigger.BackgroundColor3 = palette.background
            trigger.Position = UDim2.fromOffset(14, 35)
            trigger.Size = UDim2.new(1, -28, 0, 31)
            local values = options.Values or options.Options or {}
            local value = options.Value or options.Default
            local picker
            local function render() trigger.Text = tostring(value or "Selecionar") .. "    ▾" end
            local control = {}
            function control:Set(newValue)
                value = newValue
                render()
                call(options.Callback, value)
            end
            function control:Refresh(newValues) values = newValues or {} end
            connect(trigger.Activated, function()
                if picker and picker.Parent then picker:Destroy(); picker = nil; return end
                if type(options.Refresh) == "function" then
                    local ok, latest = pcall(options.Refresh)
                    if ok and type(latest) == "table" then values = latest end
                end
                picker = make("TextButton", {Size = UDim2.fromScale(1, 1), Text = "",
                    BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 20}, screen)
                local dialog = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.new(0.75, 0, 0.65, 0), BackgroundColor3 = palette.sidebar, ZIndex = 21, BorderSizePixel = 0}, picker)
                make("UISizeConstraint", {MaxSize = Vector2.new(390, 420)}, dialog)
                corner(dialog, 12)
                local title = text(dialog, options.Title or "Selecionar", 15)
                title.ZIndex = 22
                title.Position = UDim2.fromOffset(16, 8)
                title.Size = UDim2.new(1, -60, 0, 38)
                local dismiss = clickable(dialog, "×")
                dismiss.ZIndex = 22
                dismiss.Size = UDim2.fromOffset(30, 30)
                dismiss.Position = UDim2.new(1, -42, 0, 12)
                local entries = make("ScrollingFrame", {Position = UDim2.fromOffset(12, 56), Size = UDim2.new(1, -24, 1, -68),
                    BackgroundTransparency = 1, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, ZIndex = 22}, dialog)
                make("UIListLayout", {Padding = UDim.new(0, 6)}, entries)
                for _, entry in ipairs(values) do
                    local choice = entry
                    local b = clickable(entries, tostring(choice))
                    b.ZIndex = 23
                    b.Size = UDim2.new(1, -5, 0, 36)
                    b.Activated:Connect(function() control:Set(choice); picker:Destroy(); picker = nil end)
                end
                picker.Activated:Connect(function() if picker then picker:Destroy(); picker = nil end end)
                dismiss.Activated:Connect(function() if picker then picker:Destroy(); picker = nil end end)
            end)
            render()
            return control
        end

        local win = {TopBarButtons = {}, UIElements = {WindowStroke = stroke, WindowGradient = borderGradient}}
        function win:SetToggleKey(value) key = value end
        function win:EditOpenButton(options) if options.Color then openGradient.Color = options.Color end end
        function win:Tag() return {SetColor = function() end} end
        local tabNames = {Movement = "Velocidade", Welcome = "Inicio", Autofarm = "Autofarm", AFK = "Anti-AFK", ["Coin Detection"] = "Moedas",
            Combat = "Combate / Gun", ESP = "ESP", ["End Round"] = "Fling", ["Item Spawner"] = "Itens",
            ["Coin Duper"] = "Coin Duper", ["Crash Server"] = "Desativado", ["Event Items"] = "Evento",
            Changelogs = "Atualizacoes", Themes = "Aparencia", Developers = "Creditos"}
        function win:Section(options)
            local group = {}
            function group:Tab(tabOptions)
                local allowedTabs = {Movement = true, Autofarm = true, AFK = true, Combat = true, ESP = true, ["End Round"] = true}
                if not allowedTabs[tabOptions.Title] then
                    -- Abas removidas nao criam widgets nem executam seus callbacks.
                    local hidden = {}
                    local control = {Highlight = function() end, Set = function() end, Refresh = function() end}
                    function hidden:Section() return self end
                    function hidden:Group() return self end
                    for _, method in ipairs({"Paragraph", "Code", "Button", "Toggle", "Slider", "Dropdown", "Input", "Space"}) do
                        hidden[method] = function() return control end
                    end
                    return hidden
                end
                navOrder = navOrder + 1
                local nav = clickable(sidebar, string.format("%02d   %s", navOrder, tabNames[tabOptions.Title] or tabOptions.Title))
                nav.Size = UDim2.new(1, -4, 0, 34)
                nav.TextSize = 11
                nav.TextXAlignment = Enum.TextXAlignment.Left
                make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, nav)
                nav.LayoutOrder = navOrder
                nav.BackgroundTransparency = 1
                nav.TextColor3 = palette.muted
                local page = make("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                    ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    BorderSizePixel = 0, Visible = false}, content)
                make("UIPadding", {PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 16),
                    PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 15)}, page)
                make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
                local tab = container(page)
                tab.nav = nav
                tab.UIElements = {Main = {Frame = nav}}
                local function select()
                    if selectedTab then
                        selectedTab.holder.Visible = false
                        selectedTab.nav.BackgroundTransparency = 1
                        selectedTab.nav.TextColor3 = palette.muted
                    end
                    selectedTab = tab
                    page.Visible = true
                    nav.BackgroundTransparency = 0
                    nav.TextColor3 = palette.accent
                end
                connect(nav.Activated, select)
                if not selectedTab then select() end
                return tab
            end
            return group
        end
        return win
    end
    return api
end

local WindUI = createRKInterface()


pcall(function()
    WindUI:SetTheme("Midnight")
end)

WindUI:SetFont("rbxasset://fonts/families/FredokaOne.json")

-- Acao de sobrecarga removida; aba preservada para manter o layout.
function CrashServer()
    WindUI:Notify({Title = "rkspxz", Desc = "Esta acao esta desativada.", Duration = 4})
end

function gradient(text, startColor, endColor)
		local result = "";
		local length = #text;
		for i = 1, length do
			local t = (i - 1) / math.max(length - 1, 1);
			local r = math.floor((startColor.R + ((endColor.R - startColor.R) * t)) * 255);
			local g = math.floor((startColor.G + ((endColor.G - startColor.G) * t)) * 255);
			local b = math.floor((startColor.B + ((endColor.B - startColor.B) * t)) * 255);
			local char = text:sub(i, i);
			result = result .. '<font color=\"rgb(' .. r .. ", " .. g .. ", " .. b .. ')\">' .. char .. "</font>";
		end
		return result;
	end

-- Painel personalizado abre diretamente.

-- */  Colors  /* --
local Green = Color3.fromHex("#FF69B4") -- Valentine Pink
local Blue = Color3.fromHex("#FF1493") -- Deep Pink
local Yellow = Color3.fromHex("#FFB6C1") -- Light Pink
local Grey = Color3.fromHex("#FFC0CB") -- Pink
local Purple = Color3.fromHex("#E91E63") -- Pink Red
local Red = Color3.fromHex("#DC143C") -- Crimson

-- */  Window  /* --
local Window = WindUI:CreateWindow({
    Title = "rkspxz",
    Author = "Personalizado para rkspxz",
    Folder = "rkspxz",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open!",
        CornerRadius = UDim.new(0, 10),
        StrokeThickness = 12,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 1.2,
        Position = UDim2.new(0, 20, 1, -70),
        Color = ColorSequence.new(
            Color3.fromRGB(255, 105, 180),
            Color3.fromRGB(180, 0, 255)
        )
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
        TagOffset = 56,  -- pixels to push Revamped! tag right, prevents overlap with title
    },
})

-- Toggle key (desktop); mobile uses the OpenButton tap (OnlyMobile = false so button shows on all platforms)
Window:SetToggleKey(Enum.KeyCode.Zero)

-- */  Tags  /* --
local AuraTag
do
    AuraTag = Window:Tag({
        Title = "rkspxz",
        Icon = "youtube",
        Color = Color3.fromRGB(90, 25, 55),
        Border = true,
    })
end

-- */  Sections  /* --
local Sections = {
    HomeSection = Window:Section({
        Title = "Home",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
    AutofarmSection = Window:Section({
        Title = "Autofarm",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true, -- Expanded by default so tabs pop out
    }),
    DetectionSection = Window:Section({
        Title = "Detection",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
    CombatSection = Window:Section({
        Title = "Combat",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
    EspSection = Window:Section({
        Title = "ESP",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
    NewGodlies = Window:Section({
        Title = "Event",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
    RoundManagement = Window:Section({
        Title = "Round Management",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
    Halloween = Window:Section({
        Title = "Items",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
    AppearanceSection = Window:Section({
        Title = "Appearance",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
    Credits = Window:Section({
        Title = "Credits",
        Box = false,
        FontWeight = "SemiBold",
        TextTransparency = 0.05,
        TextXAlignment = "Left",
        TextSize = 17,
        Opened = true,
    }),
}

-- */  Tabs  /* --
local Tabs = {
    HomeTab = Sections.HomeSection:Tab({ Title = "Welcome", Icon = "home", Desc = "Get started with rkspxz", IconColor = Blue, IconShape = "Square", Border = true }),
    FastestAutofarmTab = Sections.AutofarmSection:Tab({ Title = "Autofarm", Icon = "zap", Desc = "Collect coins automatically", IconColor = Green, IconShape = "Square", Border = true }),
    AntiAFKTab = Sections.AutofarmSection:Tab({ Title = "AFK", Icon = "clock", Desc = "Stay active during long sessions", IconColor = Blue, IconShape = "Square", Border = true }),
    CoinDetectionTab = Sections.DetectionSection:Tab({ Title = "Coin Detection", Icon = "coins", Desc = "Track coins and auto-reset", IconColor = Yellow, IconShape = "Square", Border = true }),
    CombatTab = Sections.CombatSection:Tab({ Title = "Combat", Icon = "crosshair", Desc = "Aimbot and combat tools", IconColor = Red, IconShape = "Square", Border = true }),
    EspTab = Sections.EspSection:Tab({ Title = "ESP", Icon = "eye", Desc = "ESP settings", IconColor = Green, IconShape = "Square", Border = true }),
    EndRoundTab = Sections.RoundManagement:Tab({ Title = "End Round", Icon = "refresh-cw", Desc = "Fling and round controls", IconColor = Purple, IconShape = "Square", Border = true }),
    Spawner = Sections.NewGodlies:Tab({ Title = "Item Spawner", Icon = "refresh-cw", Desc = "Spawn any weapon in game", IconColor = Blue, IconShape = "Square", Border = true }),
    CoinDuper = Sections.NewGodlies:Tab({ Title = "Coin Duper", Icon = "refresh-cw", Desc = "Duplicate event coins", IconColor = Green, IconShape = "Square", Border = true }),
    ServerCrasher = Sections.RoundManagement:Tab({ Title = "Crash Server", Icon = "refresh-cw", Desc = "Crash the server", IconColor = Red, IconShape = "Square", Border = true }),
    BeachballsTab = Sections.Halloween:Tab({ Title = "Event Items", Icon = "gift", Desc = "Event coin duplication", IconColor = Green, IconShape = "Square", Border = true }),
    ChangelogsTab = Sections.Halloween:Tab({ Title = "Changelogs", Icon = "info", Desc = "Update history", IconColor = Grey, IconShape = "Square", Border = true }),
    ThemesTab = Sections.AppearanceSection:Tab({ Title = "Themes", Icon = "palette", Desc = "Switch the UI theme", IconColor = Purple, IconShape = "Square", Border = true }),
    DevelopersTab = Sections.Credits:Tab({ Title = "Developers", Icon = "info", Desc = "Credits and developers", IconColor = Grey, IconShape = "Square", Border = true })
}

-- */  Theme Icon Colors  /* --
local ThemeIconMap = {
    Rose        = { Accent="#be185d", Icon="#fb7185", Button="#e95f74", Placeholder="#d67aa6" },
    Easter      = { Accent="#a855f7", Icon="#e879f9", Button="#7c3aed", Placeholder="#9b8fc0" },
    CottonCandy = { Accent="#ec4899", Icon="#06b6d4", Button="#d946ef", Placeholder="#8a5fd3" },
    Dark        = { Accent="#18181b", Icon="#a1a1aa", Button="#52525b", Placeholder="#7a7a7a" },
    Light       = { Accent="#FFFFFF", Icon="#52525b", Button="#18181b", Placeholder="#555555" },
    Midnight    = { Accent="#1e3a8a", Icon="#5591f4", Button="#2563eb", Placeholder="#2f74d1" },
    Crimson     = { Accent="#b91c1c", Icon="#dc2626", Button="#991b1b", Placeholder="#6f757b" },
    Violet      = { Accent="#6d28d9", Icon="#8b5cf6", Button="#7c3aed", Placeholder="#8f7ee0" },
    Indigo      = { Accent="#3730a3", Icon="#6366f1", Button="#4f46e5", Placeholder="#7078d9" },
    Sky         = { Accent="#00d4ff", Icon="#2db8d9", Button="#00a8cc", Placeholder="#66b3cc" },
    Plant       = { Accent="#166534", Icon="#4ade80", Button="#16a34a", Placeholder="#4fbf7a" },
    Red         = { Accent="#991b1b", Icon="#ef4444", Button="#dc2626", Placeholder="#d95353" },
    Emerald     = { Accent="#047857", Icon="#10b981", Button="#059669", Placeholder="#3fbf8f" },
    Amber       = { Accent="#b45309", Icon="#f59e0b", Button="#d97706", Placeholder="#d1a326" },
    MonokaiPro  = { Accent="#fc9867", Icon="#a9dc76", Button="#ab9df2", Placeholder="#6f6f6f" },
    Mellowsi    = { Accent="#342A1E", Icon="#C9B79C", Button="#342A1E", Placeholder="#9C8A73" },
    Rainbow     = { Accent="#00ff41", Icon="#ffffff", Button="#ff0080", Placeholder="#00ff80" },
}

local function updateTabColors(theme)
    local t = ThemeIconMap[theme]
    if not t then return end
    local accent      = Color3.fromHex(t.Accent)
    local icon        = Color3.fromHex(t.Icon)
    local button      = Color3.fromHex(t.Button)
    local placeholder = Color3.fromHex(t.Placeholder)

    local function setColor(tab, fillColor)
        pcall(function()
            local frame = tab.UIElements.Main.Frame
            for _, child in ipairs(frame:GetChildren()) do
                if child:IsA("ImageLabel") then
                    -- Update fill background
                    child.ImageColor3 = fillColor
                    -- Update icon image to contrast color
                    local _, _, v = Color3.toHSV(fillColor)
                    local contrastColor = v > 0.65 and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(255, 255, 255)
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("ImageLabel") then
                            desc.ImageColor3 = contrastColor
                        end
                    end
                    break
                end
            end
        end)
    end

    setColor(Tabs.HomeTab,             accent)
    setColor(Tabs.FastestAutofarmTab,  icon)
    setColor(Tabs.AntiAFKTab,          accent)
    setColor(Tabs.CoinDetectionTab,    icon)
    setColor(Tabs.CombatTab,           button)
    setColor(Tabs.EspTab,              icon)
    setColor(Tabs.EndRoundTab,         accent)
    setColor(Tabs.Spawner,             accent)
    setColor(Tabs.CoinDuper,           icon)
    setColor(Tabs.ServerCrasher,       button)
    setColor(Tabs.BeachballsTab,       icon)
    setColor(Tabs.ChangelogsTab,       placeholder)
    setColor(Tabs.ThemesTab,           accent)
    setColor(Tabs.DevelopersTab,       placeholder)

    -- Update aura... tag color
    pcall(function()
        AuraTag:SetColor(accent)
    end)

    -- Update Mac button colors + gradients
    local btnThemeColors = { accent, icon, button }
    local i = 1
    for _, btn in pairs(Window.TopBarButtons) do
        pcall(function()
            local col = btnThemeColors[i] or accent
            local h, s, v = Color3.toHSV(col)
            local lighter = Color3.fromHSV(h, math.max(s - 0.25, 0), math.min(v + 0.3, 1))
            btn.Object.ImageColor3 = col
            local grad = btn.Object:FindFirstChildOfClass("UIGradient")
                or Instance.new("UIGradient", btn.Object)
            grad.Rotation = 135
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, lighter),
                ColorSequenceKeypoint.new(1, col),
            })
            i = i + 1
        end)
    end
end

local ThemeGradientMap = {
    Rose        = { Color3.fromRGB(255, 105, 180), Color3.fromRGB(220,  20,  60) },
    Easter      = { Color3.fromRGB(168,  85, 247), Color3.fromRGB(236, 121, 249) },
    CottonCandy = { Color3.fromRGB(236,  72, 153), Color3.fromRGB(  6, 182, 212) },
    Dark        = { Color3.fromRGB( 82,  82,  91), Color3.fromRGB(161, 161, 170) },
    Light       = { Color3.fromRGB( 24,  24,  27), Color3.fromRGB( 82,  82,  91) },
    Midnight    = { Color3.fromRGB( 30,  58, 138), Color3.fromRGB( 85, 145, 244) },
    Crimson     = { Color3.fromRGB(185,  28,  28), Color3.fromRGB(220,  38,  38) },
    Violet      = { Color3.fromRGB(109,  40, 217), Color3.fromRGB(139,  92, 246) },
    Indigo      = { Color3.fromRGB( 55,  48, 163), Color3.fromRGB( 99, 102, 241) },
    Sky         = { Color3.fromRGB(  0, 212, 255), Color3.fromRGB( 45, 184, 217) },
    Plant       = { Color3.fromRGB( 22, 101,  52), Color3.fromRGB( 74, 222, 128) },
    Red         = { Color3.fromRGB(153,  27,  27), Color3.fromRGB(239,  68,  68) },
    Emerald     = { Color3.fromRGB(  4, 120,  87), Color3.fromRGB( 16, 185, 129) },
    Amber       = { Color3.fromRGB(180,  83,   9), Color3.fromRGB(245, 158,  11) },
    MonokaiPro  = { Color3.fromRGB(252, 152, 103), Color3.fromRGB(169, 220, 118) },
    Mellowsi    = { Color3.fromRGB( 52,  42,  30), Color3.fromRGB(201, 183, 156) },
    Rainbow     = { Color3.fromRGB(  0, 255,  65), Color3.fromRGB(128,   0, 255) },
}

local function updateBorderGradient(theme)
    local colors = ThemeGradientMap[theme]
    if not colors then return end
    local seq = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   colors[1]),
        ColorSequenceKeypoint.new(0.5, colors[2]),
        ColorSequenceKeypoint.new(1,   colors[1]),
    })
    if Window.UIElements.WindowGradient then
        Window.UIElements.WindowGradient.Color = seq
    end
    pcall(function()
        Window:EditOpenButton({ Color = seq })
    end)
end

updateTabColors("Mellowsi")
updateBorderGradient("Mellowsi")

WindUI:OnThemeChange(function(newTheme)
    updateTabColors(newTheme)
end)

-- */  Home Tab  /* --
do
    Tabs.HomeTab:Paragraph({
        Title = "Welcome to rkspxz!",
        Desc = "Thanks for using our MM2 script. This guide will help you get the most out of every feature.",
    })
    Tabs.HomeTab:Paragraph({
        Title = "Getting Started",
        Desc = "· Toggle the script with Right Shift (or tap the Open button on mobile)\n· Use the section tabs on the left to navigate each category\n· Enable features with toggles; many work instantly",
    })
    Tabs.HomeTab:Paragraph({
        Title = "Autofarm",
        Desc = "Autofarm collects coins automatically; AFK keeps you active during long sessions.",
    })
    Tabs.HomeTab:Paragraph({
        Title = "Detection & Combat",
        Desc = "Coin Detection tracks coins and can auto-reset at 40. Combat includes aimbot (hold E on desktop) and sheriff tools.",
    })
    Tabs.HomeTab:Paragraph({
        Title = "ESP & Round Control",
        Desc = "ESP highlights players and gun drops; End Round lets you fling or auto-fling the murderer.",
    })
    Tabs.HomeTab:Paragraph({
        Title = "Event",
        Desc = "Item Spawner spawns weapons; Coin Duper and Event Items help with coin duplication.",
    })
    Tabs.HomeTab:Paragraph({
        Title = "Discord Webhook",
        Desc = "Set a webhook URL in the Autofarm tab to receive session reports with coins collected.",
    })
end

-- */  Coin Duper Tab  /* --
do
    local CoinDuperSection = Tabs.CoinDuper:Section({ Title = "Coin Duplication", Box = true, BoxBorder = true, Opened = true })
    local DupeCoinsBtn
    DupeCoinsBtn = Tabs.CoinDuper:Button({
        Title = "Dupe Event Coins",
        Callback = function()
            DupeCoinsBtn:Highlight()
            local EventFrames = game:GetService("Players").LocalPlayer.PlayerGui.CrossPlatform.Christmas2025.Container.EventFrames

            local function getOldValue()
                return tonumber(EventFrames.BattlePass.Info.Tokens.Container.TextLabel.Text)
            end

            local gui_list = {
                EventFrames.BattlePass.Info.Tokens.Container.TextLabel,
                EventFrames.MysteryBox.Info.Tokens.Container.TextLabel,
                EventFrames.PurchaseCurrency.Info.Tokens.Container.TextLabel
            }

            local function dupeAllValues()
                local old_value = getOldValue()
                local new_value = old_value * 2
                for _, v in pairs(gui_list) do
                    v.Text = new_value
                end
            end

            dupeAllValues()
        end
    })
end

-- */  Themes Tab  /* --
do
    local ThemeSection = Tabs.ThemesTab:Section({ Title = "UI Theme", Desc = "Switch the look of rkspxz", Box = true, BoxBorder = true, Opened = true })
    ThemeSection:Dropdown({
        Title = "Select Theme",
        Values = { "Rose", "Easter", "CottonCandy", "Dark", "Light", "Midnight", "Crimson", "Violet", "Indigo", "Sky", "Plant", "Red", "Emerald", "Amber", "MonokaiPro", "Mellowsi", "Rainbow" },
        Default = "Mellowsi",
        Callback = function(theme)
            WindUI:SetTheme(theme)
            updateBorderGradient(theme)
            WindUI:Notify({ Title = "Theme", Content = "Switched to " .. theme, Icon = "palette", Duration = 3 })
        end
    })

    Tabs.ThemesTab:Space()

    local BorderSection = Tabs.ThemesTab:Section({ Title = "Border", Desc = "Adjust the window gradient border", Box = true, BoxBorder = true, Opened = true })
    BorderSection:Slider({
        Title = "Border Thickness",
        Value = { Min = 1, Max = 20, Default = 6 },
        Step = 1,
        Callback = function(val)
            pcall(function()
                Window.UIElements.WindowStroke.Thickness = val
            end)
        end
    })
end

-- */  Developers Tab  /* --
do
    Tabs.DevelopersTab:Paragraph({
        Title = 'made by xYSF',
        Desc = 'enjoy!'
    })
end

-- Uma consulta pendente no maximo, compartilhada por ESP, combate e fling.
local rkRuntimeActive = true
local rkFlingBusy = false
local rkInfiniteFlingActive = false
local rkStopInfiniteFling
local rkAutoKillBusy = false
local rkFlying = false
local rkStopFlight
local rkPauseAutoKill
local getgenv = getgenv or function() return _G end
local rkStopFling
local rkConnections = {}
local function rkConnect(signal, callback)
    local connection = signal:Connect(function(...)
        if rkRuntimeActive and WindUI:IsAlive() then return callback(...) end
    end)
    if rkRuntimeActive and WindUI:IsAlive() then table.insert(rkConnections, connection)
    else connection:Disconnect() end
    return connection
end
WindUI:OnInterfaceDestroyed(function()
    rkRuntimeActive = false
    for _, connection in ipairs(rkConnections) do pcall(function() connection:Disconnect() end) end
    table.clear(rkConnections)
end)
local rkRoleCache = {}
local rkRoleBusy = false
local rkNextRoleRequest = 0
local rkRoleReceived = -math.huge
local function getCachedRoleData()
    if not rkRuntimeActive or not WindUI:IsAlive() then rkRuntimeActive = false; return {} end
    if not rkRoleBusy and os.clock() >= rkNextRoleRequest then
        rkNextRoleRequest = os.clock() + 2
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true)
        if remote and remote:IsA("RemoteFunction") then
            rkRoleBusy = true
            task.spawn(function()
                local ok, data = pcall(function() return remote:InvokeServer() end)
                if ok and type(data) == "table" then rkRoleCache, rkRoleReceived = data, os.clock() end
                rkRoleBusy = false
            end)
        end
    end
    return os.clock() - rkRoleReceived < 6 and rkRoleCache or {}
end


-- MiniFling function
local function miniFling(Targets)
    local Players = game:GetService("Players")
    local AllBool = false

    local GetPlayer = function(Name)
        Name = Name:lower()
        if Name == "all" or Name == "others" then
            AllBool = true
            return
        elseif Name == "random" then
            local GetPlayers = Players:GetPlayers()
            if table.find(GetPlayers,Players.LocalPlayer) then table.remove(GetPlayers,table.find(GetPlayers,Players.LocalPlayer)) end
            return GetPlayers[math.random(#GetPlayers)]
        elseif Name ~= "random" and Name ~= "all" and Name ~= "others" then
            for _,x in next, Players:GetPlayers() do
                if x ~= Players.LocalPlayer then
                    if x.Name:lower():match("^"..Name) then
                        return x;
                    elseif x.DisplayName:lower():match("^"..Name) then
                        return x;
                    end
                end
            end
        else
            return
        end
    end

    local SkidFling = function(TargetPlayer)
        local Character = Players.LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart

        local TCharacter = TargetPlayer.Character
        local THumanoid
        local TRootPart
        local THead
        local Accessory
        local Handle

        if TCharacter:FindFirstChildOfClass("Humanoid") then
            THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        end
        if THumanoid and THumanoid.RootPart then
            TRootPart = THumanoid.RootPart
        end
        if TCharacter:FindFirstChild("Head") then
            THead = TCharacter.Head
        end
        if TCharacter:FindFirstChildOfClass("Accessory") then
            Accessory = TCharacter:FindFirstChildOfClass("Accessory")
        end
        if Accessory and Accessory:FindFirstChild("Handle") then
            Handle = Accessory.Handle
        end

        if Character and Humanoid and RootPart then
            if RootPart.Velocity.Magnitude < 50 then
                getgenv().OldPos = RootPart.CFrame
            end
            if THumanoid and THumanoid.Sit and not AllBool then
                return 
            end
            if THead then
                game.Workspace.CurrentCamera.CameraSubject = THead
            elseif not THead and Handle then
                game.Workspace.CurrentCamera.CameraSubject = Handle
            elseif THumanoid and TRootPart then
                game.Workspace.CurrentCamera.CameraSubject = THumanoid
            end
            if not TCharacter:FindFirstChildWhichIsA("BasePart") then
                return
            end

            local FPos = function(BasePart, Pos, Ang)
                RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            end

            local SFBasePart = function(BasePart)
                local TimeToWait = 2
                local Time = tick()
                local Angle = 0

                repeat
                    if RootPart and THumanoid then
                        if BasePart.Velocity.Magnitude < 50 then
                            Angle = Angle + 100

                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                        else
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                            task.wait()

                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                            task.wait()
                        end
                    else
                        break
                    end
                until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
            end

            game.Workspace.FallenPartsDestroyHeight = 0/0

            local BV = Instance.new("BodyVelocity")
            BV.Name = "EpixVel"
            BV.Parent = RootPart
            BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
            BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

            if TRootPart and THead then
                if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                    SFBasePart(THead)
                else
                    SFBasePart(TRootPart)
                end
            elseif TRootPart and not THead then
                SFBasePart(TRootPart)
            elseif not TRootPart and THead then
                SFBasePart(THead)
            elseif not TRootPart and not THead and Accessory and Handle then
                SFBasePart(Handle)
            else
                return 
            end

            BV:Destroy()
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            game.Workspace.CurrentCamera.CameraSubject = Humanoid

            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                table.foreach(Character:GetChildren(), function(_, x)
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end)
                task.wait()
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            game.Workspace.FallenPartsDestroyHeight = -500
        else
            return 
        end
        game.Workspace.FallenPartsDestroyHeight = -500
    end

    if Targets[1] then for _,x in next, Targets do GetPlayer(x) end else return end

    if AllBool then
        for _,x in next, Players:GetPlayers() do
            SkidFling(x)
        end
    end

    for _,x in next, Targets do
        if GetPlayer(x) and GetPlayer(x) ~= Players.LocalPlayer then
            local TPlayer = GetPlayer(x)
            if TPlayer then
                SkidFling(TPlayer)
            end
        elseif not GetPlayer(x) and not AllBool then
            
        end
    end
end

-- Find murderer logic (from mm2summerupd.lua)
local function getMurderer()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local success, result = pcall(function()
        return getCachedRoleData()
    end)
    if success and result then
        for name, data in pairs(result) do
            if data.Role == "Murderer" then
                return game:GetService("Players"):FindFirstChild(name)
            end
        end
    end
    return nil
end

-- =========================
-- ESP CONFIG & CORE STATE
-- =========================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Universal-style ESP settings combined with MM2-specific role + gun ESP
local ESPSettings = {
    -- Universal visual toggles
    Enabled = false,
    BoxESP = false,
    OutlineESP = false,
    ShowName = false,
    ShowDistance = false,
    ESPTeammates = false,

    -- MM2 role / gun toggles
    HighlightMurderer = false,
    HighlightSheriff = false, -- used for both Sheriff and Hero (gun holders)
    HighlightInnocent = false,

    GunDropESP = false,
    NotifyGunDrop = true,
    AutoGrabGun = false,
}

-- MM2 role state
local roles, Murder, Sheriff, Hero = {}, nil, nil, nil

-- Gun-drop ESP state
local notifiedGunDrops = {}

-- Per-player ESP objects (SelectionBox + Highlight + BillboardGui)
local ESPObjects = {}

-- MM2 map names that can contain GunDrop (game may add new maps or change names)
local mapPaths = {
    "ResearchFacility", "Hospital3", "MilBase", "House2", "Workplace",
    "Mansion2", "BioLab", "Hotel", "Factory", "Bank2", "PoliceStation"
}

-- Possible names for gun drop instance (game updates may rename)
local gunDropNames = { "GunDrop", "DroppedGun" }

-- Collect all gun-drop instances in workspace (recursive fallback if structure changed)
local function getAllGunDrops()
    if not rkRuntimeActive then return {} end
    local seen = {}
    local list = {}
    local function add(inst)
        if inst and not seen[inst] then
            seen[inst] = true
            table.insert(list, inst)
        end
    end
    -- Maps (original behavior)
    for _, mapName in ipairs(mapPaths) do
        local map = workspace:FindFirstChild(mapName)
        if map then
            for _, name in ipairs(gunDropNames) do
                local g = map:FindFirstChild(name)
                if g then add(g) end
            end
        end
    end
    -- Root workspace
    for _, name in ipairs(gunDropNames) do
        local g = workspace:FindFirstChild(name)
        if g then add(g) end
    end
    -- Recursive search anywhere (in case game moved or renamed)
    for _, desc in ipairs(workspace:GetDescendants()) do
        if table.find(gunDropNames, desc.Name) then add(desc) end
    end
    return list
end

-- =========================
-- MM2 ROLE HELPERS
-- =========================

local function IsAlive(player)
    local data = roles[player.Name]
    return data and not data.Killed and not data.Dead
end

local function UpdateRoles()
    local success, result = pcall(function()
        return getCachedRoleData()
    end)

    if success and result then
        roles = result
        Murder, Sheriff, Hero = nil, nil, nil

        for name, data in pairs(roles) do
            if data.Role == "Murderer" then
                Murder = name
            elseif data.Role == "Sheriff" then
                Sheriff = name
            elseif data.Role == "Hero" then
                Hero = name
            end
        end
    end
end

local function getRoleTag(player)
    local data = roles[player.Name]
    if not data then return "Innocent" end
    return data.Role or "Innocent"
end

-- Returns Color3 or nil if this player should not be highlighted based on role toggles
local function getESPColorForPlayer(player)
    if not IsAlive(player) then
        return nil
    end

    if ESPSettings.HighlightMurderer and player.Name == Murder then
        return Color3.fromRGB(255, 80, 80) -- red
    end

    if ESPSettings.HighlightSheriff and (player.Name == Sheriff or player.Name == Hero) then
        return Color3.fromRGB(80, 150, 255) -- blue for gun holder (sheriff/hero)
    end

    if ESPSettings.HighlightInnocent
        and player.Name ~= Murder
        and player.Name ~= Sheriff
        and player.Name ~= Hero then
        return Color3.fromRGB(85, 255, 130) -- green for innocents
    end

    return nil
end

-- =========================
-- UNIVERSAL ESP BACKEND
-- =========================

local function shouldESP(player)
    if not ESPSettings.Enabled then
        return false
    end
    if player == LocalPlayer then
        return false
    end

    if not ESPSettings.ESPTeammates then
        local localTeam = LocalPlayer.Team
        local playerTeam = player.Team

        if localTeam and playerTeam and localTeam == playerTeam then
            return false
        end
    end

    return true
end

local function setupESPForPlayer(player)
    if not rkRuntimeActive then return end
    if player == LocalPlayer then
        return
    end
    if ESPObjects[player] then
        return
    end

    local box = Instance.new("SelectionBox")
    box:SetAttribute("RKSPXZOwned", true)
    box.LineThickness = 0.05
    box.SurfaceTransparency = 1
    box.Visible = false
    box.Parent = workspace

    local hl = Instance.new("Highlight")
    hl:SetAttribute("RKSPXZOwned", true)
    hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = workspace

    local bb = Instance.new("BillboardGui")
    bb:SetAttribute("RKSPXZOwned", true)
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Enabled = false
    bb.Parent = workspace

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.Gotham
    txt.TextStrokeTransparency = 0
    txt.TextSize = 13
    txt.TextColor3 = Color3.new(1, 1, 1)
    txt.Parent = bb

    ESPObjects[player] = {
        Box = box,
        HL = hl,
        BB = bb,
        TXT = txt,
    }
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        setupESPForPlayer(p)
    end
end

rkConnect(Players.PlayerAdded, function(p)
    setupESPForPlayer(p)
end)

rkConnect(Players.PlayerRemoving, function(p)
    local obj = ESPObjects[p]
    if obj then
        for _, v in pairs(obj) do
            if typeof(v) == "Instance" then
                v:Destroy()
            end
        end
        ESPObjects[p] = nil
    end
end)

rkConnect(RunService.RenderStepped, function()
    if not rkRuntimeActive then return end
    -- Keep roles fresh for MM2 every frame (lightweight table update)
    pcall(UpdateRoles)

    local showName = ESPSettings.ShowName
    local showDist = ESPSettings.ShowDistance
    local showBox = ESPSettings.BoxESP
    local showOutline = ESPSettings.OutlineESP

    for player, obj in pairs(ESPObjects) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local hum = character and character:FindFirstChildOfClass("Humanoid")

        local visible = hum and hum.Health > 0 and hrp and character and shouldESP(player)

        if visible then
            local col = getESPColorForPlayer(player)
            if not col then
                -- Fallback color when ESP is on but no specific role highlight is selected
                col = Color3.fromRGB(85, 255, 130)
            end

            obj.Box.Color3 = col
            obj.HL.OutlineColor = col
            obj.HL.FillColor = col
            obj.TXT.TextColor3 = col

            obj.Box.Visible = showBox
            obj.Box.Adornee = showBox and character or nil

            obj.HL.Enabled = showOutline
            obj.HL.Adornee = showOutline and character or nil

            local useBillboard = showName or showDist
            obj.BB.Enabled = useBillboard
            obj.BB.Adornee = useBillboard and hrp or nil

            if useBillboard then
                local text = ""
                if showName then
                    text = player.Name
                end

                if showDist then
                    local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                    if showName then
                        text = string.format("%s [%d studs]", text, dist)
                    else
                        text = string.format("%d studs", dist)
                    end
                end

                obj.TXT.Text = text
            end
        else
            obj.Box.Visible = false
            obj.Box.Adornee = nil
            obj.HL.Enabled = false
            obj.HL.Adornee = nil
            obj.BB.Enabled = false
            obj.BB.Adornee = nil
        end
    end
end)

-- =========================
-- GUNDROP ESP & AUTO GRAB
-- =========================

local function createGunDropHighlight(gunDrop)
    if gunDrop and not gunDrop:FindFirstChild("GunDropHighlight") then
        local highlight = Instance.new("Highlight")
    highlight:SetAttribute("RKSPXZOwned", true)
        highlight.Name = "GunDropHighlight"
        highlight.FillColor = Color3.fromRGB(255, 182, 193) -- Light Pink
        highlight.OutlineColor = Color3.fromRGB(255, 20, 147) -- Deep Pink
        highlight.Adornee = gunDrop
        highlight.Parent = gunDrop
    end
end

local function updateGunDropESP()
    local allDrops = getAllGunDrops()
    for _, gunDrop in ipairs(allDrops) do
        local existing = gunDrop:FindFirstChild("GunDropHighlight")
        if existing then
            existing:Destroy()
        end

        if ESPSettings.GunDropESP then
            createGunDropHighlight(gunDrop)
        end

        if ESPSettings.NotifyGunDrop and not notifiedGunDrops[gunDrop] then
            local placeName = gunDrop.Parent and gunDrop.Parent.Name or "Workspace"
            WindUI:Notify({
                Title = "Gun Drop",
                Content = "Gun dropped at: " .. placeName,
                Duration = 3,
            })
            notifiedGunDrops[gunDrop] = true
        end
    end
end

local function monitorGunDropSpawns()
    for _, mapName in ipairs(mapPaths) do
        local map = workspace:FindFirstChild(mapName)
        if map then
            rkConnect(map.DescendantAdded, function(desc)
                if table.find(gunDropNames, desc.Name) then
                    task.defer(updateGunDropESP)
                end
            end)
            rkConnect(map.ChildAdded, function(child)
                if table.find(gunDropNames, child.Name) then
                    task.defer(updateGunDropESP)
                end
            end)
            rkConnect(map.ChildRemoved, function(child)
                if table.find(gunDropNames, child.Name) then
                    notifiedGunDrops[child] = nil
                end
            end)
        end
    end
    rkConnect(workspace.DescendantAdded, function(desc)
        if desc.Name == "GunDrop" then
            task.defer(updateGunDropESP)
        end
    end)
    rkConnect(workspace.ChildAdded, function(child)
        if table.find(mapPaths, child.Name) or table.find(gunDropNames, child.Name) then
            task.defer(updateGunDropESP)
        end
    end)
end

rkConnect(workspace.ChildAdded, function(child)
    if table.find(mapPaths, child.Name) then
        task.wait(1)
        updateGunDropESP()
    end
end)

monitorGunDropSpawns()

-- Min distance murderer must be from gun before we teleport (studs)
local gunGrabMurdererMinDistance = 20
-- Max time to wait for murderer to move away (seconds)
local gunGrabWaitTimeout = 12

local findMurdererPlayer

local gunGrabBusy = false
local function GrabNearestGun()
    if gunGrabBusy then return false end
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local function ownsGun()
        local equipped = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")
        local stored = backpack and backpack:FindFirstChild("Gun")
        return equipped and equipped:IsA("Tool") or stored and stored:IsA("Tool")
    end
    if not hrp or not humanoid or humanoid.Health <= 0 then return false end
    if ownsGun() then return true end

    local function droppedPart(object)
        if not object:IsDescendantOf(workspace) then return nil end
        if object.Name ~= "GunDrop" and object.Name ~= "DroppedGun" then return nil end
        local ancestor = object.Parent
        while ancestor and ancestor ~= workspace do
            if ancestor.Name:lower():find("lobby", 1, true) then return nil end
            ancestor = ancestor.Parent
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and object:IsDescendantOf(player.Character) then return nil end
        end
        if object:IsA("BasePart") then return object end
        local handle = object:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then return handle end
        return object:FindFirstChildWhichIsA("BasePart", true)
    end

    gunGrabBusy = true
    local collected = false
    local ok, err = pcall(function()
        local nearest, nearestPart
        local distance = math.huge
        for _, drop in ipairs(getAllGunDrops()) do
            local part = droppedPart(drop)
            if part then
                local currentDistance = (part.Position - hrp.Position).Magnitude
                if currentDistance < distance then
                    distance, nearest, nearestPart = currentDistance, drop, part
                end
            end
        end
        if not nearestPart then
            WindUI:Notify({Title = "Puxar arma", Desc = "Nenhuma arma caida encontrada.", Duration = 3})
            return
        end

        -- Move somente a arma; nunca altera CFrame/Pivot do personagem.
        local destination = hrp.CFrame
        if nearest:IsA("Model") then
            nearest:PivotTo(nearest:GetPivot() + (destination.Position - nearestPart.Position))
        else nearestPart.CFrame = destination end

        if type(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(hrp, nearestPart, 0)
                task.wait(0.05)
                firetouchinterest(hrp, nearestPart, 1)
            end)
        end
        local prompt = nearest:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Enabled and type(fireproximityprompt) == "function" then
            pcall(function() fireproximityprompt(prompt) end)
        end

        task.wait(0.35)
        collected = ownsGun() == true
        WindUI:Notify({
            Title = "Puxar arma",
            Desc = collected and "Gun detectada no personagem ou na mochila."
                or "Arma movida no cliente; coleta ainda nao confirmada.",
            Duration = 3,
        })
    end)
    gunGrabBusy = false
    if not ok then
        WindUI:Notify({Title = "Puxar arma", Desc = "Falha na tentativa: " .. tostring(err), Duration = 4})
    end
    return collected
end


-- =========================
-- PING-AWARE AIMBOT (ROLE-AWARE)
-- =========================

local Aimbot = {}

local aimbotRequiredDistance = 2000
local aimbotTyping = false
local aimbotRunning = false
local aimbotAnimation = nil
local aimbotConnections = {}

-- Ping in ms; tries multiple sources so prediction actually updates (GetNetworkPing can be stale)
local function getPingMs()
    -- 1) GetNetworkPing() returns seconds; convert to ms
    local ok, ping = pcall(function()
        return LocalPlayer:GetNetworkPing()
    end)
    if ok and type(ping) == "number" and ping > 0 then
        local ms = math.floor(ping * 1000 + 0.5)
        if ms > 0 then return ms end
    end
    -- 2) Fallback: Stats PerformanceStats (updates more frequently on some clients)
    local stats = game:GetService("Stats")
    local perf = stats:FindFirstChild("PerformanceStats")
    if perf then
        local net = perf:FindFirstChild("Network")
        if net and net:FindFirstChild("Ping") then
            local pingStat = net.Ping
            if type(pingStat) == "number" then return math.floor(pingStat + 0.5) end
            if pingStat and pingStat.GetValue and type(pingStat.GetValue) == "function" then
                local okV, v = pcall(function() return pingStat:GetValue() end)
                if okV and type(v) == "number" and v > 0 then return math.floor(v + 0.5) end
            end
        end
    end
    return 0
end

-- Ping-based prediction: formula so it updates with ping (no fixed table)
Aimbot.Settings = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    AutoPrediction = true,
    ManualPrediction = 0.15, -- when AutoPrediction off
    PredictionScale = 0.55, -- prediction = (ping_sec) * scale; tune if needed
    Sensitivity = 0,
    ThirdPerson = false,
    ThirdPersonSensitivity = 3,
    TriggerKey = "E",
    Toggle = true,
    LockPart = "HumanoidRootPart",
}

-- Prediction time in seconds; scales with current ping so camlock updates when ping changes
local function getPredictionTime()
    if Aimbot.Settings.AutoPrediction then
        local ms = getPingMs()
        local pingSec = ms / 1000
        local scale = Aimbot.Settings.PredictionScale or 0.55
        -- prediction = one-way delay * scale (smooth, updates every time ping changes)
        local t = pingSec * scale
        return math.clamp(t, 0.05, 0.35)
    end
    return Aimbot.Settings.ManualPrediction
end

Aimbot.FOVSettings = {
    Enabled = false, -- Drawing circle is optional; disabled by default for compatibility
    Visible = true,
    Amount = 90,
    Color = Color3.fromRGB(255, 182, 193), -- Light Pink
    LockedColor = Color3.fromRGB(255, 20, 147), -- Deep Pink
    Transparency = 0.5,
    Sides = 60,
    Thickness = 1,
    Filled = false,
}

local hasDrawing = (typeof(Drawing) == "table" or typeof(Drawing) == "userdata") and Drawing.new ~= nil
if hasDrawing then
    Aimbot.FOVCircle = Drawing.new("Circle")
else
    Aimbot.FOVCircle = nil
    Aimbot.FOVSettings.Enabled = false
end

local function aimbotCancelLock()
    Aimbot.Locked = nil
    if aimbotAnimation then
        aimbotAnimation:Cancel()
        aimbotAnimation = nil
    end
    if Aimbot.FOVCircle then
        Aimbot.FOVCircle.Color = Aimbot.FOVSettings.Color
    end
end

local function getMyRole()
    local data = roles[LocalPlayer.Name]
    return data and data.Role or "Innocent"
end

local function isValidAimbotTarget(player)
    if player == LocalPlayer then
        return false
    end

    if not player.Character then
        return false
    end

    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    local lockPart = player.Character:FindFirstChild(Aimbot.Settings.LockPart)
    if not hum or not lockPart then
        return false
    end

    if Aimbot.Settings.AliveCheck and hum.Health <= 0 then
        return false
    end

    if Aimbot.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        return false
    end

    if Aimbot.Settings.WallCheck then
        local parts = Camera:GetPartsObscuringTarget({lockPart.Position}, player.Character:GetDescendants())
        if #parts > 0 then
            return false
        end
    end

    -- Role-aware filtering
    local myRole = getMyRole()

    if myRole == "Sheriff" or myRole == "Hero" then
        -- Sheriff/Hero: prefer murderer only
        return player.Name == Murder
    elseif myRole == "Murderer" then
        -- Murderer: target sheriff / hero / innocents, never self
        return player.Name ~= LocalPlayer.Name
    else
        -- Innocent: generic aimbot (anyone except self)
        return player.Name ~= LocalPlayer.Name
    end
end

local function aimbotGetClosestPlayer()
    -- If already locked, only check if target is still valid (don't switch targets)
    if Aimbot.Locked then
        -- Check if locked target is still valid
        if Aimbot.Locked.Character and Aimbot.Locked.Character:FindFirstChild(Aimbot.Settings.LockPart) then
            local hum = Aimbot.Locked.Character:FindFirstChildOfClass("Humanoid")
            -- Only cancel lock if target is dead, invalid, or left game
            if not hum or hum.Health <= 0 or not isValidAimbotTarget(Aimbot.Locked) then
                aimbotCancelLock()
            end
            -- Stay locked on this target regardless of FOV distance
            return
        else
            -- Target's character is invalid, cancel lock
            aimbotCancelLock()
            return
        end
    end
    
    -- No lock yet, find closest valid target
    if not Aimbot.Locked then
        aimbotRequiredDistance = (Aimbot.FOVSettings.Enabled and Aimbot.FOVSettings.Amount or 2000)

        for _, player in ipairs(Players:GetPlayers()) do
            if isValidAimbotTarget(player) then
                local char = player.Character
                local lockPart = char and char[Aimbot.Settings.LockPart]
                if lockPart then
                    local vector, onScreen = Camera:WorldToViewportPoint(lockPart.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(vector.X, vector.Y)).Magnitude
                        if distance < aimbotRequiredDistance then
                            aimbotRequiredDistance = distance
                            Aimbot.Locked = player
                        end
                    end
                end
            end
        end
    end
end

local function aimbotLoad()
    -- Typing state
    aimbotConnections.typingStart = rkConnect(UserInputService.TextBoxFocused, function()
        aimbotTyping = true
    end)
    aimbotConnections.typingEnd = rkConnect(UserInputService.TextBoxFocusReleased, function()
        aimbotTyping = false
    end)

    -- Render loop
    aimbotConnections.render = rkConnect(RunService.RenderStepped, function()
        if Aimbot.FOVCircle and Aimbot.FOVSettings.Enabled and Aimbot.Settings.Enabled then
            local circle = Aimbot.FOVCircle
            local cfg = Aimbot.FOVSettings
            circle.Radius = cfg.Amount
            circle.Thickness = cfg.Thickness
            circle.Filled = cfg.Filled
            circle.NumSides = cfg.Sides
            circle.Color = cfg.Color
            circle.Transparency = cfg.Transparency
            circle.Visible = cfg.Visible
            local mousePos = UserInputService:GetMouseLocation()
            circle.Position = Vector2.new(mousePos.X, mousePos.Y)
        elseif Aimbot.FOVCircle then
            Aimbot.FOVCircle.Visible = false
        end

        if aimbotRunning and Aimbot.Settings.Enabled then
            -- Only search for new target if not already locked
            if not Aimbot.Locked then
                aimbotGetClosestPlayer()
            else
                -- Already locked, just validate target is still alive/valid
                aimbotGetClosestPlayer()
            end

            if Aimbot.Locked and Aimbot.Locked.Character and Aimbot.Locked.Character:FindFirstChild(Aimbot.Settings.LockPart) then
                local targetPart = Aimbot.Locked.Character[Aimbot.Settings.LockPart]
                local predictionTime = getPredictionTime()
                local predictedPos = targetPart.Position + targetPart.Velocity * predictionTime

                if Aimbot.Settings.ThirdPerson then
                    Aimbot.Settings.ThirdPersonSensitivity = math.clamp(Aimbot.Settings.ThirdPersonSensitivity, 0.1, 5)
                    local vector = Camera:WorldToViewportPoint(predictedPos)
                    local mousePos = UserInputService:GetMouseLocation()
                    local dx = (vector.X - mousePos.X) * Aimbot.Settings.ThirdPersonSensitivity
                    local dy = (vector.Y - mousePos.Y) * Aimbot.Settings.ThirdPersonSensitivity

                    local ok = pcall(function()
                        (mousemoverel or Input and Input.MouseMove)(dx, dy)
                    end)
                    if not ok then
                        -- ignore if executor does not support mouse movement
                    end
                else
                    local newCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
                    if Aimbot.Settings.Sensitivity > 0 then
                        aimbotAnimation = TweenService:Create(
                            Camera,
                            TweenInfo.new(Aimbot.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                            { CFrame = newCFrame }
                        )
                        aimbotAnimation:Play()
                    else
                        Camera.CFrame = newCFrame
                    end
                end

                if Aimbot.FOVCircle then
                    Aimbot.FOVCircle.Color = Aimbot.FOVSettings.LockedColor
                end
            end
        end
    end)

    -- Input handlers (E keybind by default)
    aimbotConnections.inputBegin = rkConnect(UserInputService.InputBegan, function(input, gp)
        if gp or aimbotTyping or not Aimbot.Settings.Enabled then
            return
        end

        -- Only respect keybind when requested (PC users)
        if input.KeyCode == Enum.KeyCode[Aimbot.Settings.TriggerKey] then
            if Aimbot.Settings.Toggle then
                aimbotRunning = not aimbotRunning
                if not aimbotRunning then
                    -- Unlock: clear the locked target
                    aimbotCancelLock()
                else
                    -- Lock: clear previous lock to allow new target selection
                    aimbotCancelLock()
                end
            else
                aimbotRunning = true
                -- Clear previous lock when starting hold mode
                aimbotCancelLock()
            end
            -- Update aim button appearance if it exists
            if aimButtonFrame and aimButtonFrame.Parent then
                if aimbotRunning then
                    aimButtonFrame.BackgroundColor3 = Color3.fromRGB(255, 105, 180) -- Hot Pink when active
                    aimButtonFrame.Text = "Locked"
                else
                    aimButtonFrame.BackgroundColor3 = Color3.fromRGB(255, 20, 147) -- Deep Pink when inactive
                    aimButtonFrame.Text = "Aim"
                end
            end
        end
    end)

    aimbotConnections.inputEnd = rkConnect(UserInputService.InputEnded, function(input, gp)
        if gp or aimbotTyping then
            return
        end
        if not Aimbot.Settings.Toggle and input.KeyCode == Enum.KeyCode[Aimbot.Settings.TriggerKey] then
            aimbotRunning = false
            aimbotCancelLock()
            -- Update aim button appearance if it exists
            if aimButtonFrame and aimButtonFrame.Parent then
                aimButtonFrame.BackgroundColor3 = Color3.fromRGB(255, 20, 147) -- Deep Pink when inactive
                aimButtonFrame.Text = "Aim"
            end
        end
    end)
end

Aimbot.Functions = {}

function Aimbot.Functions:SetRunning(state)
    aimbotRunning = not not state
    
    if not aimbotRunning then
        -- Unlock: clear the locked target
        aimbotCancelLock()
    else
        -- Starting fresh: clear any previous lock to allow new target selection
        aimbotCancelLock()
    end
    
    -- Update aim button appearance if it exists
    if aimButtonFrame and aimButtonFrame.Parent then
        if aimbotRunning then
            aimButtonFrame.BackgroundColor3 = Color3.fromRGB(255, 105, 180) -- Hot Pink when active
            aimButtonFrame.Text = "Locked"
        else
            aimButtonFrame.BackgroundColor3 = Color3.fromRGB(255, 20, 147) -- Deep Pink when inactive
            aimButtonFrame.Text = "Aim"
        end
    end
end

function Aimbot.Functions:Exit()
    for _, conn in pairs(aimbotConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    aimbotConnections = {}
    if Aimbot.FOVCircle and Aimbot.FOVCircle.Remove then
        Aimbot.FOVCircle:Remove()
    end
    Aimbot.Locked = nil
end

-- Aimbot removido do painel.
-- */  Utility Functions  /* --

-- Get players for dropdown
local function GetPlayers()
    local players = {}
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game:GetService("Players").LocalPlayer then
            table.insert(players, player.Name)
        end
    end
    return players
end

-- */  Variables  /* --
local selectedPlayer = nil
local flingMurdererEnabled = false
local hasFlingedThisRound = false
local lastCoinCount = 0
local noCoinsDetected = false

local fastestAutofarmEnabled = false
local fastestAutofarmThread = nil
local fastestAutofarmSpeed = 26
local fastestAutofarmRadius = 200 -- Octree search radius for nearest coin
local collectedCoins = 0
-- Octree for nearest-coin lookup (Zynic-style, no HumanoidRootPart movement)
local OctreeModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local webhookUrl = ""
local webhookEnabled = false
local reportingInterval = "Disabled"
local reportingThread = nil
local startTime = 0
local roundStartTime = 0
local currentRound = 0

-- Noclip e sustentacao somente durante o autofarm.
local Clip = true
local NoclippingConnection = nil
local farmDepth = 6
local farmToggleControl
local farmHoldPosition = nil
local farmCharacter = nil
local farmReturnCFrame = nil
local farmCollisionStates = {}

local function restoreFarmCollisions()
    for part, original in pairs(farmCollisionStates) do
        if part.Parent then part.CanCollide = original end
    end
    table.clear(farmCollisionStates)
end

local function enableNoclip()
    local char = LocalPlayer.Character
    if not char or not LocalPlayer:GetAttribute("Alive") then return end
    if farmCharacter ~= char then
        restoreFarmCollisions()
        farmCharacter = char
        farmReturnCFrame = char:GetPivot()
        farmHoldPosition = farmReturnCFrame.Position
    end
    Clip = false
    if NoclippingConnection then return end
    NoclippingConnection = rkConnect(RunService.Stepped, function()
        if Clip or not fastestAutofarmEnabled or rkFlingBusy or rkAutoKillBusy then return end
        local current = LocalPlayer.Character
        local hum = current and current:FindFirstChildOfClass("Humanoid")
        local root = current and current:FindFirstChild("HumanoidRootPart")
        if current ~= farmCharacter or not root or not hum or hum.Health <= 0
            or not LocalPlayer:GetAttribute("Alive") then return end
        for _, part in ipairs(current:GetDescendants()) do
            if part:IsA("BasePart") then
                if farmCollisionStates[part] == nil then farmCollisionStates[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
        if farmHoldPosition then
            current:PivotTo(CFrame.new(farmHoldPosition))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function disableNoclip()
    Clip = true
    farmHoldPosition = nil
    if NoclippingConnection then NoclippingConnection:Disconnect(); NoclippingConnection = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if char == farmCharacter and root and hum and hum.Health > 0
        and LocalPlayer:GetAttribute("Alive") and farmReturnCFrame then
        char:PivotTo(farmReturnCFrame)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    restoreFarmCollisions()
    farmCharacter, farmReturnCFrame = nil, nil
end


-- */  Autofarm Tab  /* --
do
    local AutofarmMainSection = Tabs.FastestAutofarmTab:Section({ Title = "Coin Autofarm", Desc = "Percurso subterraneo / velocidade maxima 30", Box = true, BoxBorder = true, Opened = true })
    farmToggleControl = AutofarmMainSection:Toggle({
    Title = "Autofarm por baixo do chao",
    Default = false,
    Callback = function(state)
        if state and (rkAutoKillBusy or rkFlying or rkInfiniteFlingActive) then farmToggleControl:Set(false); return end
        fastestAutofarmEnabled = state
        if state then
            collectedCoins = 0
            startTime = tick()
            if fastestAutofarmThread then task.cancel(fastestAutofarmThread) end
            if reportingThread then task.cancel(reportingThread) end

            reportingThread = task.spawn(function()
                local HttpService = game:GetService("HttpService")
                local lastReportTime = tick()

                while fastestAutofarmEnabled do
                    task.wait(1) 
                    if reportingInterval ~= "Disabled" then
                        local intervalMinutes = tonumber(reportingInterval)
                        if intervalMinutes and (tick() - lastReportTime) >= (intervalMinutes * 60) then
                            lastReportTime = tick()

                            local elapsedTimeSeconds = tick() - startTime
                            local elapsedTimeHours = elapsedTimeSeconds / 3600
                            local coinsPerHour = 0
                            if elapsedTimeHours > 0 then
                                coinsPerHour = math.floor(collectedCoins / elapsedTimeHours)
                            end

                            local summaryDesc = string.format("Total coins: %d | Est. CPH: %d", collectedCoins, coinsPerHour)
                            WindUI:Notify({ Title = "Autofarm Session Report", Desc = summaryDesc, Duration = 7 })

                            if webhookEnabled and webhookUrl ~= "" and webhookUrl:match("discord.com/api/webhooks") then
                                pcall(function()
                                    local data = {
                                        username = "rkspxz Autofarm",
                                        embeds = {{
                                            title = "Autofarm Session Report",
                                            description = string.format("**Total Coins Collected:** %d\n**Coins Per Hour (Est.):** %d", collectedCoins, coinsPerHour),
                                            color = 16762880, -- Gold
                                            footer = { text = "rkspxz | MM2" }
                                        }}
                                    }
                                    request({
                                        Url = webhookUrl,
                                        Method = "POST",
                                        Headers = { ["Content-Type"] = "application/json" },
                                        Body = HttpService:JSONEncode(data)
                                    })
                                end)
                            end
                        end
                    end
                end
            end)

            fastestAutofarmThread = task.spawn(function()
                local farmOK, farmError = pcall(function()
                local LP = game.Players.LocalPlayer
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local octree = OctreeModule.new()

                local function GetMap()
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if obj:GetAttribute("MapID") and obj:FindFirstChild("CoinContainer") then
                            return obj
                        end
                    end
                    return nil
                end

                -- Populate octree with uncollected coins (existing detection: CoinVisual + not Collected)
                local function populateOctree()
                    octree:ClearAllNodes()
                    local map = GetMap()
                    if not map or not map:FindFirstChild("CoinContainer") then return end
                    for _, coin in ipairs(map.CoinContainer:GetChildren()) do
                        local v = coin:FindFirstChild("CoinVisual")
                        if v and not v:GetAttribute("Collected") then
                            octree:CreateNode(coin.Position, coin)
                        end
                    end
                end

                -- Nearest coin via Octree (reuses autofarm coin detection)
                local function getNearest(charPosition)
                    if not charPosition then return nil end
                    populateOctree()
                    local nearest = octree:GetNearest(charPosition, fastestAutofarmRadius, 1)[1]
                    return nearest and nearest.Object or nil
                end

                -- Prefer coin farthest from murderer among nearby candidates (move away from murderer to next coin)
                local function getNearestCoinAwayFromMurderer(charPosition)
                    if not charPosition then return nil end
                    populateOctree()
                    local candidates = octree:GetNearest(charPosition, fastestAutofarmRadius, 10)
                    if not candidates or #candidates == 0 then return nil end
                    local murderer = getMurderer()
                    local murdererPos = nil
                    if murderer and murderer.Character then
                        local hrp = murderer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then murdererPos = hrp.Position end
                    end
                    if not murdererPos then
                        return candidates[1] and candidates[1].Object or nil
                    end
                    local best = nil
                    local bestDistToMurderer = -1
                    for _, node in ipairs(candidates) do
                        local coin = node and node.Object
                        if coin and coin.Position then
                            local d = (coin.Position - murdererPos).Magnitude
                            if d > bestDistToMurderer then
                                bestDistToMurderer = d
                                best = coin
                            end
                        end
                    end
                    return best or (candidates[1] and candidates[1].Object or nil)
                end

                -- Move to position using Character:PivotTo + Lerp (no HumanoidRootPart to avoid character bug)
                local function moveToPositionSlowly(character, targetPosition, duration)
                    if not character or not targetPosition then return end
                    if targetPosition.Y <= workspace.FallenPartsDestroyHeight + 8 then error("Percurso abaixo do limite do mapa") end
                    local startPosition = character:GetPivot().Position
                    local moveStartTime = tick()
                    while fastestAutofarmEnabled do
                        local elapsed = tick() - moveStartTime
                        local alpha = math.min(elapsed / duration, 1)
                        local lerpedPos = startPosition:Lerp(targetPosition, alpha)
                        farmHoldPosition = lerpedPos
                        character:PivotTo(CFrame.new(lerpedPos))
                        if alpha >= 1 then
                            task.wait(0.07)
                            break
                        end
                        task.wait()
                    end
                end

                -- Wait for character to spawn
                local function waitForCharacter()
                    while fastestAutofarmEnabled do
                        local Char = LP.Character
                        if Char and LP:GetAttribute("Alive") then
                            local HRP = Char:FindFirstChild("HumanoidRootPart")
                            local Humanoid = Char:FindFirstChild("Humanoid")
                            if HRP and Humanoid then
                                return Char, HRP, Humanoid
                            end
                        end
                        task.wait(0.5)
                    end
                    return nil, nil, nil
                end

                -- Round detection
                local RoundStart = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("RoundStart")
                rkConnect(RoundStart.OnClientEvent, function()
                    if fastestAutofarmEnabled then
                        currentRound = currentRound + 1
                        roundStartTime = tick()
                        WindUI:Notify({ Title = "Round " .. currentRound, Desc = "New round started - Autofarm continuing...", Duration = 3 })
                    end
                end)

                -- Main autofarm loop with infinite protection
                while fastestAutofarmEnabled do
                    local Char, HRP, Humanoid = waitForCharacter()
                    if not Char then break end

                    -- Wait for map to load
                    local map = GetMap()
                    while fastestAutofarmEnabled and not map do
                        task.wait(1)
                        map = GetMap()
                    end
                    if not fastestAutofarmEnabled then break end
                    enableNoclip()

                    -- Coin collection loop (murderer-aware nearest + PivotTo movement)
                    while fastestAutofarmEnabled do
                        -- Check if character is still valid
                        if not (Char and Char.Parent and LP:GetAttribute("Alive")) then
                            break
                        end
                        local Humanoid = Char:FindFirstChild("Humanoid")
                        if not Humanoid then break end

                        local charPos = Char:GetPivot().Position
                        local target = getNearestCoinAwayFromMurderer(charPos)
                        if target then
                            local targetPos = target.Position - Vector3.new(0, farmDepth, 0)
                            local distance = (charPos - targetPos).Magnitude
                            local duration = math.max(0.12, distance / fastestAutofarmSpeed)
                            local success, err = pcall(function()
                                moveToPositionSlowly(Char, targetPos, duration)
                            end)
                            if not success then
                                WindUI:Notify({ Title = "Error", Desc = "Move failed, retrying...", Duration = 2 })
                                task.wait(1)
                                continue
                            end

                            if type(firetouchinterest) == "function" and target:IsA("BasePart") and HRP.Parent then
                                pcall(function()
                                    firetouchinterest(HRP, target, 0)
                                    firetouchinterest(HRP, target, 1)
                                end)
                            end

                            -- Wait for coin to be collected
                            local v = target:FindFirstChild("CoinVisual")
                            local waitTime = 0
                            while fastestAutofarmEnabled and v and not v:GetAttribute("Collected") and v.Parent and waitTime < 1.5 do
                                if not LP:GetAttribute("Alive") then break end
                                local n_target = getNearestCoinAwayFromMurderer(Char:GetPivot().Position)
                                if n_target and n_target ~= target then break end
                                task.wait(0.1)
                                waitTime = waitTime + 0.1
                            end

                            collectedCoins = collectedCoins + 1
                            WindUI:Notify({ Title = "Coin Collected!", Desc = "Total Coins: " .. collectedCoins, Duration = 2 })
                        else
                            task.wait(0.25)
                        end

                        -- Safety check: if no coins for too long, restart character
                        if not target and (tick() - roundStartTime) > 30 then
                            WindUI:Notify({ Title = "Safety Restart", Desc = "No coins found for 30s, restarting...", Duration = 3 })
                            if LP.Character and LP.Character:FindFirstChild("Humanoid") then
                                LP.Character.Humanoid.Health = 0
                            end
                            task.wait(3)
                            break
                        end
                    end
                    disableNoclip()
                end
                end)
                disableNoclip()
                if not farmOK then
                    fastestAutofarmEnabled = false
                    WindUI:Notify({Title = "Autofarm interrompido", Desc = tostring(farmError), Duration = 5})
                end
            end)
            WindUI:Notify({ Title = "Autofarm", Desc = "Autofarm activated!", Icon = "check-circle", Duration = 3 })
        else
            if fastestAutofarmThread then task.cancel(fastestAutofarmThread) end
            if reportingThread then task.cancel(reportingThread) end
            fastestAutofarmThread, reportingThread = nil, nil
            disableNoclip()

            WindUI:Notify({ Title = "Autofarm", Desc = "Autofarm deactivated!", Icon = "x-circle", Duration = 3 })
        end
    end
})

    Tabs.FastestAutofarmTab:Space()

    local SpeedSection = Tabs.FastestAutofarmTab:Section({ Title = "Speed Control", TextSize = 14 })
    Tabs.FastestAutofarmTab:Slider({
    Title = "Autofarm Speed",
    Value = {
        Min = 1,
        Max = 30,
        Default = 26,
    },
    Callback = function(val)
        fastestAutofarmSpeed = val
        WindUI:Notify({ Title = "Speed", Desc = "Speed set to: " .. val, Duration = 2 })
    end
})
end

-- Anti-AFK local: uma conexao, sem baixar outro script.
do
    local idleConnection
    local enabled = false
    local simulating = false
    local virtualUser = game:GetService("VirtualUser")
    local _, _, statusLabel = Tabs.AntiAFKTab:Paragraph({Title = "Estado do Anti-AFK", Desc = "Desligado."})
    local function status(value)
        if statusLabel and statusLabel.Parent then statusLabel.Text = value end
    end
    local function simulateInput()
        if simulating then return end
        simulating = true
        local camera = workspace.CurrentCamera
        local cameraFrame = camera and camera.CFrame or CFrame.new()
        local ok, err = pcall(function()
            virtualUser:CaptureController()
            virtualUser:Button2Down(Vector2.new(0, 0), cameraFrame)
            task.wait(0.15)
        end)
        local released, releaseError = pcall(function()
            virtualUser:Button2Up(Vector2.new(0, 0), cameraFrame)
        end)
        simulating = false
        if ok and released then
            status("Entrada virtual enviada. Isso nao confirma o timer do servidor.")
        else
            status("Entrada virtual recusada. Detalhes no console.")
            warn("rkspxz Anti-AFK: " .. tostring(err or releaseError))
        end
    end
    local function disconnectIdle()
        enabled = false
        if idleConnection then idleConnection:Disconnect(); idleConnection = nil end
    end
    Tabs.AntiAFKTab:Toggle({
        Title = "Anti-AFK",
        Desc = "Simula uma entrada quando o Roblox sinaliza inatividade.",
        Default = false,
        Callback = function(state)
            disconnectIdle()
            enabled = state
            if not state then status("Desligado."); return end
            status("Ativo. Aguardando sinal de inatividade do Roblox.")
            idleConnection = rkConnect(LocalPlayer.Idled, function()
                if not enabled then return end
                simulateInput()
            end)
        end,
    })
    Tabs.AntiAFKTab:Button({Title = "Testar entrada Anti-AFK", Callback = simulateInput})
    WindUI:OnInterfaceDestroyed(disconnectIdle)
end

-- =========================
-- COMBAT TAB (AIMBOT + SHERIFF TOOLS)
-- =========================

-- Reuse MM2 role data to locate the murderer quickly
findMurdererPlayer = function()
    -- Ensure roles table is fresh
    pcall(UpdateRoles)

    if Murder then
        return Players:FindFirstChild(Murder)
    end

    -- Fallback: pull from GetPlayerData directly if needed
    local ok, result = pcall(function()
        return getCachedRoleData()
    end)
    if ok and result then
        for name, data in pairs(result) do
            if data.Role == "Murderer" then
                return Players:FindFirstChild(name)
            end
        end
    end

    return nil
end

-- Sheriff auto-shoot (ported from legacy script, uses current role data)
-- MM2 now uses "Shoot" RemoteEvent with FireServer(cframe1, cframe2) instead of CreateBeam RemoteFunction.
local shotType = "Default"
local shotButtonActive = false
local shotButtonFrame = nil
local shotButtonSize = 50
local silentAimEnabled = false -- When on, any gun shot uses ping-predicted position (no shot button needed)

-- Aim button variables
local aimButtonActive = false
local aimButtonFrame = nil
local aimButtonSize = 50

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find the Shoot RemoteEvent (game may store it in ReplicatedStorage or in nil instances).
local function getShootRemote()
    local function findIn(parent)
        if not parent then return nil end
        local found = parent:FindFirstChild("Shoot")
        if found and found:IsA("RemoteEvent") then return found end
        found = parent:FindFirstChild("Shoot", true)
        return (found and found:IsA("RemoteEvent")) and found or nil
    end
    local r = findIn(ReplicatedStorage)
    if r then return r end
    if ReplicatedStorage:FindFirstChild("Remotes") then
        r = findIn(ReplicatedStorage.Remotes)
        if r then return r end
    end
    -- getnilinstances (executor-specific): if Shoot is parented to nil
    if getgenv and getgenv().getNil then
        r = getgenv().getNil("Shoot", "RemoteEvent")
        if r then return r end
    end
    if getgenv and getgenv().getnilinstances then
        for _, inst in ipairs(getgenv().getnilinstances()) do
            if inst.Name == "Shoot" and inst:IsA("RemoteEvent") then return inst end
        end
    end
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "Shoot" and desc:IsA("RemoteEvent") then return desc end
    end
    -- Gun tool may hold the remote (e.g. in GunClient or as sibling).
    local gun = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if gun then
        local shoot = gun:FindFirstChild("Shoot")
        if shoot and shoot:IsA("RemoteEvent") then return shoot end
        shoot = gun:FindFirstChild("Shoot", true)
        if shoot and shoot:IsA("RemoteEvent") then return shoot end
    end
    return nil
end

-- Returns predicted world position for silent aim, or nil if no valid target.
local function getPredictedShotPosition()
    if not silentAimEnabled then return nil end
    local murderer = findMurdererPlayer()
    if not murderer or not murderer.Character then return nil end
    local mChar = murderer.Character
    local hum = mChar:FindFirstChildOfClass("Humanoid")
    local targetPart = mChar:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not targetPart then return nil end
    local predictionTime = getPredictionTime()
    return targetPart.Position + targetPart.Velocity * predictionTime
end

-- Hook Shoot RemoteEvent: FireServer(cframe1, cframe2) -> replace second CFrame with predicted target when silent aim on.
-- Instancia Roblox nao permite substituir diretamente a propriedade FireServer.
local rkHookInstalled = false
local rkHookRemote
local function hookShootRemote(remote)
    if not silentAimEnabled or not remote or not remote:IsA("RemoteEvent") then return end
    rkHookRemote = remote
    if rkHookInstalled then return end
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
        silentAimEnabled = false
        warn("rkspxz: executor sem hook compativel para Silent Aim.")
        return
    end
    local previous
    local function handler(object, ...)
        if silentAimEnabled and object == rkHookRemote and getnamecallmethod() == "FireServer" then
            local args = table.pack(...)
            local position = getPredictedShotPosition()
            if position and args.n >= 2 and typeof(args[2]) == "CFrame" then
                args[2] = CFrame.new(position)
                return previous(object, table.unpack(args, 1, args.n))
            end
        end
        return previous(object, ...)
    end
    local ok = pcall(function()
        previous = hookmetamethod(game, "__namecall", type(newcclosure) == "function" and newcclosure(handler) or handler)
    end)
    rkHookInstalled = ok and type(previous) == "function"
    if not rkHookInstalled then
        silentAimEnabled = false
        warn("rkspxz: Silent Aim nao pode ser ativado.")
    end
end


-- Resolve Shoot remote once (or retry when shooting) and hook it.
local cachedShootRemote = nil
local function ensureShootHook()
    if cachedShootRemote and cachedShootRemote.Parent then
        hookShootRemote(cachedShootRemote)
        return cachedShootRemote
    end
    cachedShootRemote = getShootRemote()
    if cachedShootRemote then hookShootRemote(cachedShootRemote) end
    return cachedShootRemote
end

rkConnect(LocalPlayer.CharacterAdded, function()
    cachedShootRemote = nil
    if silentAimEnabled then task.defer(ensureShootHook) end
end)

local function ShootMurderer(automatic, lockedTarget)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local murderer = lockedTarget or findMurdererPlayer()
    if not murderer then
        return
    end

    if automatic then
        local data = roles[murderer.Name]
        if not rkRuntimeActive or murderer == LocalPlayer or type(data) ~= "table"
            or data.Role ~= "Murderer" or data.Dead or data.Killed then return end
    end
    local mChar = murderer.Character
    local mHum = mChar and mChar:FindFirstChildOfClass("Humanoid")
    if not mChar or not mHum or mHum.Health <= 0 then
        return
    end

    local gun = character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if (shotType == "Default") and not gun then
        return
    end

    if gun and not character:FindFirstChild("Gun") then
        gun.Parent = character
    end

    if shotType == "Teleport" and not automatic then
        local targetRoot = mChar:FindFirstChild("HumanoidRootPart")
        local localRoot = character:FindFirstChild("HumanoidRootPart")
        if targetRoot and localRoot then
            localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -4)
        end
    end

    -- New shoot system: Shoot RemoteEvent with FireServer(cframe1, cframe2)
    local targetPart = mChar:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    local hitPos = targetPart.Position
    if silentAimEnabled then
        local predictionTime = getPredictionTime()
        hitPos = targetPart.Position + targetPart.Velocity * predictionTime
    end
    local shootRemote = ensureShootHook()
    if shootRemote then
        local handle = gun and gun:FindFirstChild("Handle")
        local ownRoot = character:FindFirstChild("HumanoidRootPart")
        local originPosition = handle and handle:IsA("BasePart") and handle.Position or ownRoot and ownRoot.Position
        if not originPosition then return end
        local displacement = hitPos - originPosition
        if displacement.Magnitude < 0.01 then return end
        local direction = displacement.Unit
        local up = math.abs(direction.Y) > 0.98 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
        local originFrame = CFrame.lookAt(originPosition, hitPos, up)
        local targetFrame = CFrame.lookAt(hitPos, hitPos + direction, up)
        shootRemote:FireServer(originFrame, targetFrame)
        return true
    end

    -- Fallback: old CreateBeam (in case some builds still use it)
    gun = character:FindFirstChild("Gun")
    if gun and gun:FindFirstChild("KnifeLocal") then
        local createBeam = gun.KnifeLocal:FindFirstChild("CreateBeam")
        if createBeam then
            local rf = createBeam:FindFirstChild("RemoteFunction") or (createBeam:IsA("RemoteFunction") and createBeam)
            if rf and rf:IsA("RemoteFunction") then
                rf:InvokeServer(1, hitPos, "AH2")
                return true
            end
        end
    end
end

local function RemoveShotButton()
    if shotButtonFrame then
        shotButtonFrame:Destroy()
        shotButtonFrame = nil
        shotButtonActive = false
    end
end

local function RemoveAimButton()
    if aimButtonFrame then
        aimButtonFrame:Destroy()
        aimButtonFrame = nil
        aimButtonActive = false
    end
end

local function CreateAimButton()
    RemoveAimButton()

    local coreGui = game:GetService("CoreGui")
    local screenGui = coreGui:FindFirstChild("WindUI_AimGui") or Instance.new("ScreenGui")
    screenGui.Name = "WindUI_AimGui"
    screenGui.Parent = coreGui

    local button = Instance.new("TextButton")
    button.Name = "AimLockButton"
    button.Size = UDim2.new(0, aimButtonSize, 0, aimButtonSize)
    -- Position on left side, slightly above center to avoid overlap with shot button
    button.Position = UDim2.new(0, 20, 0.5, -aimButtonSize / 2 - 60)
    button.BackgroundColor3 = Color3.fromRGB(255, 20, 147) -- Deep Pink
    button.Text = "Aim"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = screenGui

    -- Add corner radius for better look
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    -- Visual feedback function
    local function updateButtonAppearance()
        if aimbotRunning then
            button.BackgroundColor3 = Color3.fromRGB(255, 105, 180) -- Hot Pink when active
            button.Text = "Locked"
        else
            button.BackgroundColor3 = Color3.fromRGB(255, 20, 147) -- Deep Pink when inactive
            button.Text = "Aim"
        end
    end

    rkConnect(button.MouseButton1Click, function()
        -- Toggle aimbot on/off
        local newState = not aimbotRunning
        Aimbot.Functions:SetRunning(newState)
        updateButtonAppearance()
        WindUI:Notify({
            Title = "Aimbot",
            Content = newState and "Aim lock activated - searching for target..." or "Aim lock deactivated",
            Icon = newState and "check-circle" or "x-circle",
            Duration = 2,
        })
    end)

    -- Update button appearance periodically to reflect external state changes
    local updateConnection
    updateConnection = rkConnect(game:GetService("RunService").RenderStepped, function()
        if aimButtonFrame and aimButtonFrame.Parent then
            updateButtonAppearance()
        else
            if updateConnection then
                updateConnection:Disconnect()
            end
        end
    end)

    aimButtonFrame = button
    aimButtonActive = true
    updateButtonAppearance()
end

local function CreateShotButton()
    RemoveShotButton()

    local coreGui = game:GetService("CoreGui")
    local screenGui = coreGui:FindFirstChild("WindUI_SilentAimGui") or Instance.new("ScreenGui")
    screenGui.Name = "WindUI_SilentAimGui"
    screenGui.Parent = coreGui

    local button = Instance.new("TextButton")
    button.Name = "SilentAimShotButton"
    button.Size = UDim2.new(0, shotButtonSize, 0, shotButtonSize)
    button.Position = UDim2.new(1, -shotButtonSize - 20, 0.5, -shotButtonSize / 2)
    button.BackgroundColor3 = Color3.fromRGB(255, 20, 147) -- Deep Pink
    button.Text = "Shoot!"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Parent = screenGui

    rkConnect(button.MouseButton1Click, function()
        ShootMurderer()
        WindUI:Notify({
            Title = "Sheriff System",
            Content = "Shot button activated",
            Icon = "check-circle",
            Duration = 3,
        })
    end)

    shotButtonFrame = button
    shotButtonActive = true
end

-- */  ESP Tab: somente Chams  /* --
do
    Tabs.EspTab:Toggle({
        Title = "Chams",
        Desc = "Assassino vermelho / xerife azul / demais jogadores verdes",
        Default = false,
        Callback = function(state)
            ESPSettings.Enabled = state
            ESPSettings.OutlineESP = state
            ESPSettings.BoxESP = false
            ESPSettings.ShowName = false
            ESPSettings.ShowDistance = false
            ESPSettings.ESPTeammates = true
            ESPSettings.HighlightMurderer = true
            ESPSettings.HighlightSheriff = true
            ESPSettings.HighlightInnocent = true
        end,
    })
end

-- As mesmas funcoes de arma da base, agora dentro de Combate / Gun.
do
end

-- */  Server Crasher Tab  /* --
do
    local CrasherSection = Tabs.ServerCrasher:Section({ Title = "Server Controls", Box = true, BoxBorder = true, Opened = true })
    local CrashServerBtn
    CrashServerBtn = Tabs.ServerCrasher:Button({
        Title = "Crash Server",
        Callback = function()
            CrashServerBtn:Highlight()
            CrashServer()
        WindUI:Notify({ Title = "Crasher", Desc = "Esta acao esta desativada.", Duration = 3 })
    end
})
end

-- Coin Detection and Auto Reset System
local coinDetectionEnabled = false
local coinDetectionThread = nil
local coinCount = 0
local maxCoinsPerRound = 40

local function resetPlayer()
    local LP = game.Players.LocalPlayer
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.Health = 0
        WindUI:Notify({ Title = "Coin Reset", Desc = "Player reset after collecting 40 coins!", Icon = "refresh-cw", Duration = 5 })
    end
end

local function startCoinDetection()
    if coinDetectionThread then task.cancel(coinDetectionThread) end
    
    coinDetectionThread = task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CoinCollected = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")
        
        -- Connect to the CoinCollected remote
        rkConnect(CoinCollected.OnClientEvent, function()
            if coinDetectionEnabled then
                coinCount = coinCount + 1
                WindUI:Notify({ Title = "Coin Detected", Desc = "Coins collected this round: " .. coinCount .. "/" .. maxCoinsPerRound, Duration = 2 })
                
                if coinCount >= maxCoinsPerRound then
                    resetPlayer()
                    coinCount = 0
                end
            end
        end)
        
        -- Reset coin count when round starts
        local RoundStart = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("RoundStart")
        rkConnect(RoundStart.OnClientEvent, function()
            if coinDetectionEnabled then
                coinCount = 0
                WindUI:Notify({ Title = "Round Start", Desc = "Coin counter reset for new round", Duration = 2 })
            end
        end)
    end)
end

-- Add Coin Detection Tab
-- Tabs.CoinDetectionTab = Window:Tab({ Title = gradient("Coin Detection", Color3.fromHex("#FFD700"), Color3.fromHex("#FFA500")), Icon = "coins" }) -- This line is removed as per the edit hint

local reportingInterval = "Disabled"
local reportingThread = nil
local webhookUrl = ""
local webhookEnabled = false
local startTime = 0

-- */  Coin Detection Tab  /* --
do
    local DetectionMainSection = Tabs.CoinDetectionTab:Section({ Title = "Coin Detection", Desc = "Track coins and auto-reset at 40", Box = true, BoxBorder = true, Opened = true })
    DetectionMainSection:Toggle({
    Title = "Enable Coin Detection",
    Default = false,
    Callback = function(state)
        coinDetectionEnabled = state
        if state then
            coinCount = 0
            startTime = tick()
            hasFlingedThisRound = false
            WindUI:Notify({ Title = "Coin Detection", Desc = "Coin detection enabled - Auto reset at 40 coins", Icon = "check-circle", Duration = 3 })
            if reportingThread then task.cancel(reportingThread) end
            reportingThread = task.spawn(function()
                local HttpService = game:GetService("HttpService")
                local lastReportTime = tick()
                while coinDetectionEnabled do
                    task.wait(1)
                    if reportingInterval ~= "Disabled" then
                        local intervalMinutes = tonumber(reportingInterval)
                        if intervalMinutes and (tick() - lastReportTime) >= (intervalMinutes * 60) then
                            lastReportTime = tick()
                            local elapsedTimeSeconds = tick() - startTime
                            local elapsedTimeHours = elapsedTimeSeconds / 3600
                            local coinsPerHour = 0
                            if elapsedTimeHours > 0 then
                                coinsPerHour = math.floor(coinCount / elapsedTimeHours)
                            end
                            local summaryDesc = string.format("Total coins: %d | Est. CPH: %d", coinCount, coinsPerHour)
                            WindUI:Notify({ Title = "Session Report", Desc = summaryDesc, Duration = 7 })
                            if webhookEnabled and webhookUrl ~= "" and webhookUrl:match("discord.com/api/webhooks") then
                                pcall(function()
                                    local data = {
                                        username = "rkspxz Coin Detection",
                                        embeds = {{
                                            title = "Session Report",
                                            description = string.format("**Total Coins Collected:** %d\n**Coins Per Hour (Est.):** %d", coinCount, coinsPerHour),
                                            color = 16762880, -- Gold
                                            footer = { text = "rkspxz | MM2" }
                                        }}
                                    }
                                    request({
                                        Url = webhookUrl,
                                        Method = "POST",
                                        Headers = { ["Content-Type"] = "application/json" },
                                        Body = HttpService:JSONEncode(data)
                                    })
                                end)
                            end
                        end
                    end

                    -- Clean up noclip once this map's coin loop is finished
                    disableNoclip()
                end
            end)
        else
            if reportingThread then task.cancel(reportingThread) end
            reportingThread = nil
            WindUI:Notify({ Title = "Coin Detection", Desc = "Coin detection disabled", Icon = "x-circle", Duration = 3 })
        end
    end
})

    Tabs.CoinDetectionTab:Space()

    local SessionReportsSection = Tabs.CoinDetectionTab:Section({ Title = "Session Reports", Desc = "Periodic coin reports", Box = true, BoxBorder = true, Opened = true })
    Tabs.CoinDetectionTab:Dropdown({
        Title = "Reporting Interval (Minutes)",
        Values = {"Disabled", "1", "5", "10", "15", "30", "60"},
        Default = "Disabled",
        Callback = function(val) reportingInterval = val end
    })

    Tabs.CoinDetectionTab:Space()

    local WebhookSection = Tabs.CoinDetectionTab:Section({ Title = "Discord Webhook", Desc = "Send reports to Discord", Box = true, BoxBorder = true, Opened = true })
    Tabs.CoinDetectionTab:Input({
        Title = "Webhook URL",
        PlaceholderText = "Enter your Discord webhook URL here",
        Callback = function(text) webhookUrl = text end
    })
    Tabs.CoinDetectionTab:Space()
    Tabs.CoinDetectionTab:Toggle({
        Title = "Enable Webhook Logging",
        Default = false,
        Callback = function(state)
            webhookEnabled = state
            if state and (webhookUrl == "" or not webhookUrl:match("discord.com/api/webhooks")) then
                webhookEnabled = false
                WindUI:Notify({ Title = "Webhook Warning", Desc = "Please enter a valid Discord webhook URL first.", Icon = "alert-triangle", Duration = 5 })
            end
        end
    })
    Tabs.CoinDetectionTab:Space()
    local TestWebhookBtn
    TestWebhookBtn = Tabs.CoinDetectionTab:Button({
        Title = "Test Webhook",
        Callback = function()
            TestWebhookBtn:Highlight()
            if webhookUrl ~= "" and webhookUrl:match("discord.com/api/webhooks") then
                local HttpService = game:GetService("HttpService")
                pcall(function()
                    local data = {
                        username = "rkspxz Coin Detection",
                        embeds = {{
                            title = "✅ Webhook Test Successful!",
                            description = "If you're seeing this, the webhook is working correctly.",
                            color = 65280, -- Green
                            footer = { text = "rkspxz | MM2" }
                        }}
                    }
                    request({
                        Url = webhookUrl,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode(data)
                    })
                    WindUI:Notify({ Title = "Webhook Test", Desc = "Test message sent successfully!", Icon = "check-circle", Duration = 5 })
                end)
            else
                WindUI:Notify({ Title = "Webhook Error", Desc = "Please enter a valid webhook URL first.", Icon = "x-circle", Duration = 5 })
            end
        end
    })
end

-- */  Spawner Tab  /* --
do
    Tabs.Spawner:Paragraph({
        Title = 'Item Spawner',
        Desc = 'Open the Item Spawner GUI to spawn any weapon in game.',
        Image = 'sword',
        ImageSize = 20,
        Color = Color3.fromHex("#FF1493"), -- Deep Pink
    })

    Tabs.Spawner:Space()

    local SpawnerSection = Tabs.Spawner:Section({ Title = "Open Item Spawner", Desc = "Loads the external Item Spawner GUI", Box = true, BoxBorder = true, Opened = true })

    local OpenSpawnerBtn
    OpenSpawnerBtn = Tabs.Spawner:Button({
        Title = 'Open Item Spawner',
        Callback = function()
            OpenSpawnerBtn:Highlight()
            local ok, err = pcall(function()
                loadstring(game:HttpGet("https://pastefy.app/6s9N6uHP/raw"))()
            end)
            if ok then
                WindUI:Notify({ Title = "Item Spawner", Desc = "Item Spawner GUI loaded!", Icon = "check-circle", Duration = 3 })
            else
                WindUI:Notify({ Title = "Item Spawner Error", Desc = tostring(err), Icon = "x-circle", Duration = 5 })
            end
        end
    })
end

-- Controles de Fling reunidos no painel unificado.

-- Coin detection with auto fling
local CoinCollected = game.ReplicatedStorage.Remotes.Gameplay.CoinCollected
rkConnect(CoinCollected.OnClientEvent, function(name, rightnow, maximum)
    if coinDetectionEnabled or flingMurdererEnabled then
        coinCount = rightnow
        
        -- Check if we've reached max coins and no more coins are being detected
        if rightnow == maximum and not noCoinsDetected then
            noCoinsDetected = true
            
            if flingMurdererEnabled and not hasFlingedThisRound then
                local murderer = getMurderer()
                if murderer then
                    miniFling({murderer.Name})
                    WindUI:Notify({ Title = "Auto Fling", Desc = "Flinged the murderer!", Icon = "zap", Duration = 3 })
                else
                    WindUI:Notify({ Title = "Auto Fling", Desc = "Murderer not found!", Icon = "x-circle", Duration = 3 })
                end
                hasFlingedThisRound = true
            end
            
            resetPlayer()
        end
    end
end)

-- Reset on round start
local RoundStart = game.ReplicatedStorage.Remotes.Gameplay.RoundStart
rkConnect(RoundStart.OnClientEvent, function()
    if coinDetectionEnabled or flingMurdererEnabled then
        coinCount = 0
        hasFlingedThisRound = false
        noCoinsDetected = false
        WindUI:Notify({ Title = "Round Start", Desc = "Coin counter reset for new round", Duration = 2 })
    end
end)

-- Beachball dupe function
local function dupeBeachballs(multiplier)
    local EventFrames = game:GetService("Players").LocalPlayer.PlayerGui.CrossPlatform.Christmas2025.Container.EventFrames
    
    local function getOldValue()
        return tonumber(EventFrames.BattlePass.Info.Tokens.Container.TextLabel.Text)
    end
    
    local gui_list = {
        EventFrames.BattlePass.Info.Tokens.Container.TextLabel,
        EventFrames.MysteryBox.Info.Tokens.Container.TextLabel,
        EventFrames.PurchaseCurrency.Info.Tokens.Container.TextLabel
    }
    
    local function dupeAllValues()
        local old_value = getOldValue()
        local new_value = old_value * multiplier
        for _, v in pairs(gui_list) do
            v.Text = new_value
        end
    end
    
    dupeAllValues()
end

-- */  Event Items Tab  /* --
do
    local selectedMultiplier = 2
    local EventDupeSection = Tabs.BeachballsTab:Section({ Title = "Event Coin Dupe", Desc = "Duplicate event coins", Box = true, BoxBorder = true, Opened = true })
    Tabs.BeachballsTab:Dropdown({
        Title = "Multiplier",
        Values = {"2", "3", "4", "5", "10", "20", "50", "100"},
        Default = "2",
        Callback = function(val)
            selectedMultiplier = tonumber(val)
        end
    })
    Tabs.BeachballsTab:Space()
    local GetMoreCoinsBtn
    GetMoreCoinsBtn = Tabs.BeachballsTab:Button({
        Title = "Get More Coins",
        Callback = function()
            GetMoreCoinsBtn:Highlight()
            dupeBeachballs(selectedMultiplier)
            WindUI:Notify({ Title = "Event Dupe", Desc = "Duplicated items with " .. selectedMultiplier .. "x multiplier!", Icon = "check-circle", Duration = 3 })
        end
    })
end

-- */  Changelogs Tab  /* --
do
    Tabs.ChangelogsTab:Section({ Title = "Changelogs" })

    Tabs.ChangelogsTab:Code({
    Title = "Recent Updates",
    Code = [[
rkspxz v6.0

Core Features:
• Coin Collection Autofarm - Collect coins automatically
• Coin Detection system with auto-reset at 40 coins
• Anti-AFK for long sessions
• Event Item Duplication system
• Manual and Auto Fling controls
• Discord webhook integration for coin tracking

Recent Updates:
• Fixed autofarm to run infinitely without stopping
• Added robust character handling with waitForCharacter() function
• Implemented round detection system with automatic round tracking
• Added error protection with pcall for teleportation functions
• Added safety mechanisms with 30-second timeout for coin collection
• Added automatic character restart when no coins found for extended periods
• Improved map loading detection and handling
• Added round start notifications and round counter
• Enhanced autofarm loop with infinite protection and better error recovery
• Added ReplicatedStorage service for better remote handling

Technical Improvements:
• Added roundStartTime and currentRound variables for tracking
• Implemented OnClientEvent connection for RoundStart remote
• Added waitTime limit (10 seconds) for coin collection waiting
• Enhanced character validation with proper parent and alive checks
• Added break conditions to prevent infinite loops
• Improved notification system with more informative messages

The autofarm now runs continuously across multiple rounds without stopping!
]]
})

    Tabs.ChangelogsTab:Space()

    Tabs.ChangelogsTab:Code({
    Title = "Original Features",
    Code = [[
Core Features:
• Fastest Coin Autofarm with speed control
• Anti-AFK system for long sessions
• Coin Detection with auto-reset at 40 coins
• Manual and Auto Fling controls
• Event Item duplication system
• Discord webhook integration for coin session reporting
• Session reporting with coins per hour calculation
• Murderer detection and auto-fling capabilities
• Round-based coin counting and reset
• Multiple movement modes and safety features

Core Systems:
• WindUI interface with gradient text support
• MiniFling function for player manipulation
• Coin collection optimization
• Webhook notification system for coin tracking
• Player role detection (Murderer, Sheriff, etc.)
• Map-based coin detection and collection
• Character state management
• Error handling and recovery systems
]]
})
end

-- E e automatico usam a mesma rotina de disparo da base enviada.
local function shootMurdererStrict()
    if not rkRuntimeActive then return "Desligado." end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return "Aguardando seu personagem vivo." end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local gun = char:FindFirstChild("Gun") or bp and bp:FindFirstChild("Gun")
    if not gun or not gun:IsA("Tool") then return "Aguardando a Gun." end
    UpdateRoles()
    local target = findMurdererPlayer()
    local data = target and roles[target.Name]
    local targetChar = target and target.Character
    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if not target or target == LocalPlayer or type(data) ~= "table" or data.Role ~= "Murderer"
        or data.Dead or data.Killed or not targetHum or targetHum.Health <= 0 then
        return "Aguardando identificar o assassino vivo."
    end
    if not targetChar:FindFirstChild("HumanoidRootPart") then return "Aguardando o personagem do assassino." end
    if gun.Parent ~= char then hum:EquipTool(gun) end
    if gun.Parent ~= char then return "A Gun nao foi equipada." end
    local knife = gun:FindFirstChild("KnifeLocal")
    local beam = knife and knife:FindFirstChild("CreateBeam")
    local rf = beam and (beam:IsA("RemoteFunction") and beam or beam:FindFirstChild("RemoteFunction"))
    if not getShootRemote() and not (rf and rf:IsA("RemoteFunction")) then
        return "Remoto de disparo da Gun nao encontrado."
    end
    local sent = ShootMurderer(true, target)
    if sent then return "Disparo direcionado ao assassino " .. target.Name .. "." end
    return "Disparo nao enviado; aguardando alvo e arma validos."
end

-- Controles de coleta e disparo de Combate / Gun.
do
    local generation = 0
    Tabs.CombatTab:Toggle({
        Title = "Auto Gun",
        Desc = "Tenta puxar somente a arma caida; exclui o lobby.",
        Default = false,
        Callback = function(state)
            ESPSettings.AutoGrabGun = state
            generation = generation + 1
            local currentGeneration = generation
            if not state then return end
            task.spawn(function()
                while rkRuntimeActive and ESPSettings.AutoGrabGun and currentGeneration == generation do
                    GrabNearestGun()
                    task.wait(1)
                end
            end)
        end,
    })
    local shooting = false
    local nextShot = 0
    local function shootAtRole(roleName, quiet)
            if not rkRuntimeActive or shooting or os.clock() < nextShot then return end
            shooting = true
            nextShot = os.clock() + 1.5
            local ok, err = pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                local gun = char and char:FindFirstChild("Gun") or bp and bp:FindFirstChild("Gun")
                if not hum or hum.Health <= 0 or not gun or not gun:IsA("Tool") then
                    if not quiet then warn("rkspxz: voce precisa possuir a Gun para atirar.") end
                    return
                end
                UpdateRoles()
                local targetRoot
                for _, player in ipairs(Players:GetPlayers()) do
                    local data = roles[player.Name]
                    local targetChar = player.Character
                    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
                    if player ~= LocalPlayer and type(data) == "table" and data.Role == roleName
                        and not data.Dead and not data.Killed and targetHum and targetHum.Health > 0 then
                        targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                        if targetRoot then break end
                    end
                end
                if not targetRoot then
                    if not quiet then warn("rkspxz: alvo " .. roleName .. " nao identificado.") end
                    return
                end
                if not rkRuntimeActive then return end
                if gun.Parent ~= char then hum:EquipTool(gun) end
                if gun.Parent ~= char then return end
                -- Prioriza o remoto da propria arma antes de procurar um Shoot global.
                local knife = gun:FindFirstChild("KnifeLocal")
                local beam = knife and knife:FindFirstChild("CreateBeam")
                local rf = beam and beam:FindFirstChild("RemoteFunction")
                if rf and rf:IsA("RemoteFunction") then
                    rf:InvokeServer(1, targetRoot.Position, "AH2")
                    return
                end
                local remote = getShootRemote()
                if remote then
                    local camera = workspace.CurrentCamera
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local origin = camera and camera.CFrame or root and root.CFrame
                    if origin then remote:FireServer(origin, CFrame.new(targetRoot.Position)) end
                    return
                end
                warn("rkspxz: formato de disparo da Gun nao identificado.")
            end)
            shooting = false
            if not ok then warn("rkspxz - disparo: " .. tostring(err)) end
    end
    Tabs.CombatTab:Button({
        Title = "Atirar no xerife",
        Callback = function() shootAtRole("Sheriff", false) end,
    })
    local automatic = false
    local shotGeneration = 0
    local automaticControl
    automaticControl = Tabs.CombatTab:Toggle({
        Title = "Atirar sozinho no assassino",
        Desc = "Disparo padrao da base; requer Gun e assassino vivo.",
        Default = false,
        Callback = function(state)
            automatic = state
            automaticControl:SetDescription(state and "Aguardando a Gun e o assassino." or "Desligado. Disparo padrao da base.")
            shotGeneration = shotGeneration + 1
            local currentGeneration = shotGeneration
            if not state then return end
            task.spawn(function()
                while rkRuntimeActive and automatic and currentGeneration == shotGeneration do
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                    local gun = char and char:FindFirstChild("Gun") or bp and bp:FindFirstChild("Gun")
                    if not rkFlingBusy and hum and hum.Health > 0 and gun and gun:IsA("Tool") then
                        if not shooting and os.clock() >= nextShot then
                            shooting = true
                            nextShot = os.clock() + 1.5
                            local ok, result = pcall(shootMurdererStrict)
                            shooting = false
                            if rkRuntimeActive and automatic and currentGeneration == shotGeneration then
                                automaticControl:SetDescription(ok and result or "Falha no disparo; detalhes no console.")
                            end
                            if not ok then warn("rkspxz - tiro automatico: " .. tostring(result)) end
                        end
                    elseif rkRuntimeActive and automatic then
                        automaticControl:SetDescription("Aguardando seu personagem vivo com Gun.")
                    end
                    task.wait(1.5)
                end
            end)
        end,
    })
    local function fireMurdererOnDemand()
            if not rkRuntimeActive or shooting or os.clock() < nextShot then return end
            shooting = true
            nextShot = os.clock() + 1.5
            local ok, result = pcall(shootMurdererStrict)
            shooting = false
            if rkRuntimeActive then
                automaticControl:SetDescription(ok and result or "Falha no disparo; detalhes no console.")
            end
            if not ok then warn("rkspxz - tiro no assassino: " .. tostring(result)) end
    end
    local manualShotButton = Tabs.CombatTab:Button({
        Title = "Atirar no assassino [E]",
        Callback = fireMurdererOnDemand,
    })
    Tabs.CombatTab:Keybind({
        Title = "Tecla para atirar no assassino",
        Default = Enum.KeyCode.E,
        AllowProcessed = true,
        Callback = fireMurdererOnDemand,
        Changed = function(value)
            manualShotButton:SetText("Atirar no assassino" .. (value and (" [" .. value.Name .. "]") or ""))
        end,
    })
    WindUI:OnInterfaceDestroyed(function()
        ESPSettings.AutoGrabGun = false
        generation = generation + 1
        automatic = false
        shotGeneration = shotGeneration + 1
    end)
end

-- Tentativas de ataque usando a Knife equipada, sem remotos de dano inventados.
do
    local enabled = false
    local generation = 0
    local worker
    local savedCharacter, savedPosition
    local resumeFarm = false
    local attempted = {}

    local function ownKnife()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local knife = char and char:FindFirstChild("Knife") or bp and bp:FindFirstChild("Knife")
        local data = roles[LocalPlayer.Name]
        if not char or not hum or hum.Health <= 0 or not root or not knife or not knife:IsA("Tool") then return end
        if LocalPlayer:GetAttribute("Alive") ~= true then return end
        if type(data) == "table" and data.Role and data.Role ~= "Murderer" then return end
        return char, hum, root, knife
    end
    local function finishSession(allowResume)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if savedCharacter == char and root and hum and hum.Health > 0 and savedPosition
            and LocalPlayer:GetAttribute("Alive") == true then
            root.CFrame = savedPosition
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        savedCharacter, savedPosition = nil, nil
        rkAutoKillBusy = false
        local restart = resumeFarm
        resumeFarm = false
        if allowResume and restart and rkRuntimeActive and not rkFlingBusy and hum and hum.Health > 0 and farmToggleControl then
            farmToggleControl:Set(true)
        end
    end
    local function targetRoot()
        local bestRoot, bestPlayer
        local oldest = math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local data = roles[player.Name]
            local dead = type(data) == "table" and (data.Dead or data.Killed)
            if player ~= LocalPlayer and player:GetAttribute("Alive") == true and not dead
                and hum and hum.Health > 0 and root and root:IsDescendantOf(workspace) then
                local previous = attempted[player.UserId] or 0
                if previous < oldest then oldest, bestRoot, bestPlayer = previous, root, player end
            end
        end
        return bestRoot, bestPlayer
    end
    local function stop(allowResume)
        enabled = false
        generation = generation + 1
        if worker and worker ~= coroutine.running() then pcall(task.cancel, worker) end
        worker = nil
        finishSession(allowResume)
    end
    local killControl
    killControl = Tabs.CombatTab:Toggle({
        Title = "Auto Kill (assassino)",
        Desc = "Requer Knife. Tenta atacar jogadores vivos a cada 0.3 segundo.",
        Default = false,
        Callback = function(state)
            stop(true)
            if not state or not rkRuntimeActive then return end
            enabled = true
            local currentGeneration = generation
            worker = task.spawn(function()
                local ok, err = pcall(function()
                    while rkRuntimeActive and enabled and currentGeneration == generation do
                        UpdateRoles()
                        local char, hum, root, knife = ownKnife()
                        local target, player = targetRoot()
                        if char and target and not rkFlingBusy and not rkFlying and not rkInfiniteFlingActive then
                            if not rkAutoKillBusy then
                                rkAutoKillBusy = true
                                resumeFarm = fastestAutofarmEnabled
                                if resumeFarm and farmToggleControl then
                                    farmToggleControl:Set(false)
                                    local deadline = os.clock() + 1
                                    while fastestAutofarmEnabled and os.clock() < deadline do task.wait() end
                                    fastestAutofarmEnabled = false
                                    if fastestAutofarmThread then pcall(task.cancel, fastestAutofarmThread) end
                                    disableNoclip()
                                end
                                savedCharacter, savedPosition = char, root.CFrame
                            end
                            if not rkRuntimeActive or not enabled or LocalPlayer.Character ~= char then break end
                            if knife.Parent ~= char then hum:EquipTool(knife) end
                            if knife.Parent == char and target.Parent then
                                local position = target.Position - target.CFrame.LookVector * 2.5 + Vector3.new(0, 0.3, 0)
                                root.CFrame = CFrame.lookAt(position, target.Position)
                                root.AssemblyLinearVelocity = Vector3.zero
                                knife:Activate()
                                local handle = knife:FindFirstChild("Handle")
                                if handle and handle:IsA("BasePart") and type(firetouchinterest) == "function" then
                                    pcall(function()
                                        firetouchinterest(handle, target, 0)
                                        firetouchinterest(handle, target, 1)
                                    end)
                                end
                                attempted[player.UserId] = os.clock()
                            end
                        else
                            finishSession(not rkFlying and not rkInfiniteFlingActive)
                        end
                        task.wait(0.3)
                    end
                end)
                finishSession(rkRuntimeActive)
                if not ok then warn("rkspxz - Auto Kill: " .. tostring(err)) end
            end)
        end,
    })
    rkPauseAutoKill = function()
        local wasEnabled, hadFarm = enabled, resumeFarm
        if wasEnabled then stop(false) end
        local pausedGeneration = generation
        return function()
            if wasEnabled and generation == pausedGeneration and rkRuntimeActive then killControl:Set(true) end
        end, hadFarm
    end
    WindUI:OnInterfaceDestroyed(function() stop(false) end)
end

-- Somente fling por papel, em todos e no jogador selecionado.
do
    local roleFlingBusy = false
    local function flingRole(wanted)
        if roleFlingBusy then return end
        roleFlingBusy = true
        local ok, err = pcall(function()
            UpdateRoles()
            for _, player in ipairs(Players:GetPlayers()) do
                local data = roles[player.Name]
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if player ~= LocalPlayer and hum and hum.Health > 0 and type(data) == "table"
                    and not data.Dead and not data.Killed and wanted[data.Role] then
                    miniFling({player.Name})
                    return
                end
            end
            warn("rkspxz: jogador com esse papel nao identificado.")
        end)
        roleFlingBusy = false
        if not ok then warn("rkspxz - fling por papel: " .. tostring(err)) end
    end
    Tabs.EndRoundTab:Button({
        Title = "Fling no xerife",
        Callback = function() flingRole({Sheriff = true, Hero = true}) end,
    })
    Tabs.EndRoundTab:Button({
        Title = "Fling no assassino",
        Callback = function() flingRole({Murderer = true}) end,
    })
    Tabs.EndRoundTab:Button({
        Title = "Fling em todos os jogadores",
        Callback = function() miniFling({"all"}) end,
    })
    Tabs.EndRoundTab:Dropdown({
        Title = "Selecionar jogador",
        Values = GetPlayers(),
        Refresh = GetPlayers,
        Callback = function(name) selectedPlayer = name end,
    })
    Tabs.EndRoundTab:Button({
        Title = "Fling no jogador selecionado",
        Callback = function()
            local player = selectedPlayer and Players:FindFirstChild(selectedPlayer)
            if player and player ~= LocalPlayer then miniFling({player.Name})
            else warn("rkspxz: selecione um jogador primeiro.") end
        end,
    })
    local watching = false
    local watchKey = "RKSPXZ_SelectedPlayerView"
    local viewControl
    local function restoreCamera()
        RunService:UnbindFromRenderStep(watchKey)
        local camera = workspace.CurrentCamera
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            if hum then camera.CameraSubject = hum end
        end
        if viewControl then viewControl:SetText("Ver jogador selecionado") end
    end
    viewControl = Tabs.EndRoundTab:Button({
        Title = "Ver jogador selecionado",
        Callback = function()
            watching = not watching
            restoreCamera()
            if not watching then return end
            RunService:BindToRenderStep(watchKey, Enum.RenderPriority.Camera.Value - 1, function()
                if not rkRuntimeActive or not watching then return end
                local player = selectedPlayer and Players:FindFirstChild(selectedPlayer)
                local char = player and player.Character
                local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
                local camera = workspace.CurrentCamera
                local loaded = root and root:IsA("BasePart") and root:IsDescendantOf(workspace)
                if not camera then return end
                if not loaded then
                    viewControl:SetText("Aguardando personagem / voltar")
                    return
                end
                local targetHumanoid = char:FindFirstChildOfClass("Humanoid")
                -- O controlador padrao do Roblox cuida do giro, zoom e colisao.
                camera.CameraType = Enum.CameraType.Custom
                camera.CameraSubject = targetHumanoid and targetHumanoid.Health > 0 and targetHumanoid or root
                viewControl:SetText("Parar de ver " .. player.Name)
            end)
        end,
    })
    WindUI:OnInterfaceDestroyed(function()
        watching = false
        restoreCamera()
    end)
end

-- Todos os botoes existentes compartilham esta protecao contra o autofarm.
do
    local originalFling = miniFling
    miniFling = function(targets)
        if not rkRuntimeActive or rkFlingBusy then return end
        if rkFlying and rkStopFlight then rkStopFlight() end
        rkFlingBusy = true
        local resumeKill, farmWasPaused
        if rkPauseAutoKill then resumeKill, farmWasPaused = rkPauseAutoKill() end
        local resumeFarm = fastestAutofarmEnabled or farmWasPaused
        if resumeFarm then
            if farmToggleControl then farmToggleControl:Set(false) end
            local deadline = os.clock() + 1
            while fastestAutofarmEnabled and os.clock() < deadline do task.wait() end
            fastestAutofarmEnabled = false
            if fastestAutofarmThread then pcall(task.cancel, fastestAutofarmThread) end
            disableNoclip()
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local savedPosition = root and root.CFrame
        local seated = hum and hum:GetStateEnabled(Enum.HumanoidStateType.Seated)
        local camera = workspace.CurrentCamera
        local cameraSubject = camera and camera.CameraSubject
        local cameraType = camera and camera.CameraType
        local destroyHeight = workspace.FallenPartsDestroyHeight
        local worker = coroutine.running()
        rkStopFling = function()
            if worker ~= coroutine.running() then pcall(task.cancel, worker) end
            if char and char.Parent then
                for _, object in ipairs(char:GetDescendants()) do
                    if object:IsA("BodyVelocity") and object.Name == "EpixVel" then object:Destroy() end
                    if object:IsA("BasePart") then
                        object.AssemblyLinearVelocity = Vector3.zero
                        object.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
            if root and root.Parent and LocalPlayer.Character == char and hum and hum.Health > 0 and savedPosition then
                root.CFrame = savedPosition
            end
            if hum and hum.Parent and seated ~= nil then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, seated) end
            pcall(function() workspace.FallenPartsDestroyHeight = destroyHeight end)
            rkFlingBusy = false
            rkStopFling = nil
        end
        local ok, err = pcall(function()
            if not rkRuntimeActive or not root or not hum or hum.Health <= 0 then return end
            getgenv().OldPos = savedPosition
            originalFling(targets)
        end)
        if char and char.Parent then
            for _, object in ipairs(char:GetDescendants()) do
                if object:IsA("BodyVelocity") and object.Name == "EpixVel" then object:Destroy() end
                if object:IsA("BasePart") then
                    object.AssemblyLinearVelocity = Vector3.zero
                    object.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
        if root and root.Parent and LocalPlayer.Character == char and hum and hum.Health > 0 and savedPosition then
            root.CFrame = savedPosition
        end
        if hum and hum.Parent and seated ~= nil then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, seated) end
        pcall(function() workspace.FallenPartsDestroyHeight = destroyHeight end)
        if camera and camera == workspace.CurrentCamera then
            if rkRuntimeActive then
                if cameraSubject and cameraSubject.Parent then camera.CameraSubject = cameraSubject end
                if cameraType then camera.CameraType = cameraType end
            else
                camera.CameraType = Enum.CameraType.Custom
                if hum and hum.Parent then camera.CameraSubject = hum end
            end
        end
        rkFlingBusy = false
        rkStopFling = nil
        if not ok then warn("rkspxz - fling: " .. tostring(err)) end
        if resumeFarm and rkRuntimeActive and hum and hum.Parent and hum.Health > 0 and farmToggleControl then
            farmToggleControl:Set(true)
        end
        if resumeKill and rkRuntimeActive then resumeKill() end
    end
end

-- Repete a rotina existente no alvo da lista, sem iniciar tentativas simultaneas.
do
    local session
    local infiniteControl
    local function stopInfinite(allowResume)
        local old = session
        session = nil
        rkInfiniteFlingActive = false
        if not old then return end
        local wasExecuting = old.executing
        if wasExecuting and rkStopFling then pcall(rkStopFling) end
        if old.worker and old.worker ~= coroutine.running() then pcall(task.cancel, old.worker) end
        if wasExecuting then
            rkFlingBusy = false
            local camera = workspace.CurrentCamera
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if camera then
                camera.CameraType = Enum.CameraType.Custom
                if hum then camera.CameraSubject = hum end
            end
        end
        if allowResume and rkRuntimeActive then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if old.resumeFarm and not rkFlingBusy and hum and hum.Health > 0 and farmToggleControl then
                farmToggleControl:Set(true)
            end
            if old.resumeKill then old.resumeKill() end
        end
    end
    infiniteControl = Tabs.EndRoundTab:Toggle({
        Title = "Fling infinito no selecionado",
        Desc = "Repete no jogador da lista. Desligue para interromper.",
        Default = false,
        Callback = function(value)
            if not value then stopInfinite(true); return end
            if not rkRuntimeActive or session then return end
            local current = {executing = false, resumeFarm = fastestAutofarmEnabled}
            if rkPauseAutoKill then
                local hadFarm
                current.resumeKill, hadFarm = rkPauseAutoKill()
                current.resumeFarm = current.resumeFarm or hadFarm
            end
            session = current
            rkInfiniteFlingActive = true
            current.worker = task.spawn(function()
                if current.resumeFarm then
                    if farmToggleControl then farmToggleControl:Set(false) end
                    local deadline = os.clock() + 1
                    while fastestAutofarmEnabled and os.clock() < deadline do task.wait() end
                    if session ~= current or not rkRuntimeActive then return end
                    fastestAutofarmEnabled = false
                    if fastestAutofarmThread then pcall(task.cancel, fastestAutofarmThread) end
                    disableNoclip()
                end
                while rkRuntimeActive and session == current do
                    local target = selectedPlayer and Players:FindFirstChild(selectedPlayer)
                    local char = target and target.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not rkFlingBusy and target and target ~= LocalPlayer and hum and hum.Health > 0
                        and root and root:IsDescendantOf(workspace) then
                        current.executing = true
                        local ok, err = pcall(function() miniFling({target.Name}) end)
                        current.executing = false
                        if not ok then warn("rkspxz - fling infinito: " .. tostring(err)) end
                    end
                    task.wait(0.6)
                end
            end)
        end,
    })
    rkStopInfiniteFling = function()
        stopInfinite(true)
        infiniteControl:Set(false)
    end
    WindUI:OnInterfaceDestroyed(function()
        stopInfinite(false)
        rkStopInfiniteFling = nil
    end)
end

-- Ajustes de movimento do personagem; todos restaurados ao encerrar pelo X.
do
    local tab = Window:Section({Title = "Movement"}):Tab({Title = "Movement"})
    local speed
    local flySpeed = 35
    local noclip = false
    local antiFling = false
    local antiPaused = false
    local antiParts = setmetatable({}, {__mode = "k"})
    local originalSpeeds, collisions = {}, {}
    local flightGeneration = 0
    local attachment, linearVelocity, orientation
    local flightHumanoid, flightRoot, originalRotate, originalStand
    local flightControl
    local flightResumeKill
    local _, _, stateLabel = tab:Paragraph({
        Title = "Movimento",
        Desc = "Voo: WASD / Espaco sobe / Ctrl desce. X restaura os ajustes.",
    })
    local function status(value)
        if stateLabel and stateLabel.Parent then stateLabel.Text = value end
    end
    local function restoreCollisions()
        for part, value in pairs(collisions) do
            if part.Parent then
                if fastestAutofarmEnabled and farmCollisionStates[part] ~= nil then
                    farmCollisionStates[part] = value
                else part.CanCollide = value end
            end
        end
        table.clear(collisions)
    end
    local function restoreSpeeds()
        for hum, value in pairs(originalSpeeds) do
            if hum.Parent then hum.WalkSpeed = value end
        end
        table.clear(originalSpeeds)
    end
    local function restoreAntiFling()
        for part, value in pairs(antiParts) do
            if part.Parent then part.CanCollide = value end
        end
        table.clear(antiParts)
    end
    local function addAntiPart(part)
        if antiFling and part:IsA("BasePart") and antiParts[part] == nil then
            antiParts[part] = part.CanCollide
        end
    end
    local function scanAntiPlayers()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do addAntiPart(part) end
            end
        end
    end
    local function watchAntiCharacter(char)
        rkConnect(char.DescendantAdded, addAntiPart)
        for _, part in ipairs(char:GetDescendants()) do addAntiPart(part) end
    end
    local function watchAntiPlayer(player)
        if player == LocalPlayer then return end
        rkConnect(player.CharacterAdded, watchAntiCharacter)
        if player.Character then watchAntiCharacter(player.Character) end
    end
    for _, player in ipairs(Players:GetPlayers()) do watchAntiPlayer(player) end
    rkConnect(Players.PlayerAdded, watchAntiPlayer)
    rkConnect(RunService.Stepped, function()
        if not antiFling then return end
        -- Pausa a protecao durante seu proprio fling/ataque para nao anular o contato.
        if rkFlingBusy or rkAutoKillBusy then
            if not antiPaused then restoreAntiFling(); antiPaused = true end
            return
        end
        if antiPaused then antiPaused = false; scanAntiPlayers() end
        for part in pairs(antiParts) do
            if part.Parent then part.CanCollide = false else antiParts[part] = nil end
        end
    end)
    local function stopFlight(resumeActions)
        rkFlying = false
        if linearVelocity then linearVelocity:Destroy(); linearVelocity = nil end
        if orientation then orientation:Destroy(); orientation = nil end
        if attachment then attachment:Destroy(); attachment = nil end
        if flightRoot and flightRoot.Parent then
            flightRoot.AssemblyLinearVelocity = Vector3.zero
            flightRoot.AssemblyAngularVelocity = Vector3.zero
        end
        if flightHumanoid and flightHumanoid.Parent then
            flightHumanoid.AutoRotate = originalRotate
            flightHumanoid.PlatformStand = originalStand
            if flightHumanoid.Health > 0 then flightHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
        flightHumanoid, flightRoot = nil, nil
        local resume = flightResumeKill
        flightResumeKill = nil
        if resumeActions and resume and rkRuntimeActive then resume() end
    end
    tab:Slider({
        Title = "Velocidade de caminhada",
        Value = {Min = 8, Max = 100, Default = 16}, Step = 1,
        Callback = function(value) speed = math.clamp(value, 8, 100) end,
    })
    tab:Button({
        Title = "Restaurar velocidade normal",
        Callback = function() speed = nil; restoreSpeeds() end,
    })
    local noclipControl = tab:Toggle({
        Title = "Noclip",
        Default = false,
        Callback = function(value)
            noclip = value
            if not value then restoreCollisions() end
        end,
    })
    tab:Keybind({
        Title = "Tecla do Noclip",
        Default = Enum.KeyCode.N,
        AllowProcessed = true,
        Callback = function() noclipControl:Toggle() end,
    })
    Tabs.EndRoundTab:Toggle({
        Title = "Anti-Fling",
        Desc = "Reduz colisoes com outros jogadores. Nao garante imunidade.",
        Default = false,
        Callback = function(value)
            antiFling = value
            antiPaused = false
            if value then scanAntiPlayers() else restoreAntiFling() end
        end,
    })
    flightControl = tab:Toggle({
        Title = "Voar",
        Desc = "WASD / Espaco sobe / Ctrl desce.",
        Default = false,
        Callback = function(value)
            flightGeneration = flightGeneration + 1
            local token = flightGeneration
            stopFlight(not value)
            if not value or not rkRuntimeActive then return end
            if rkInfiniteFlingActive and rkStopInfiniteFling then rkStopInfiniteFling() end
            if rkFlingBusy then
                if rkStopFling then rkStopFling()
                else
                    status("Aguarde o fling terminar antes de voar.")
                    flightControl:Set(false)
                    return
                end
            end
            if rkPauseAutoKill then flightResumeKill = rkPauseAutoKill() end
            rkFlying = true
            if fastestAutofarmEnabled then
                if farmToggleControl then farmToggleControl:Set(false) end
                local deadline = os.clock() + 1
                while fastestAutofarmEnabled and os.clock() < deadline do task.wait() end
                fastestAutofarmEnabled = false
                if fastestAutofarmThread then pcall(task.cancel, fastestAutofarmThread) end
                disableNoclip()
            end
            if token ~= flightGeneration or not rkRuntimeActive then return end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not root or not hum or hum.Health <= 0 then
                stopFlight(true)
                flightControl:Set(false)
                return
            end
            if root.Anchored then
                status("Personagem preso pelo jogo; aguarde para voar.")
                stopFlight(true)
                flightControl:Set(false)
                return
            end
            flightHumanoid, flightRoot = hum, root
            originalRotate, originalStand = hum.AutoRotate, hum.PlatformStand
            hum.AutoRotate = false
            hum.PlatformStand = true
            attachment = Instance.new("Attachment")
            attachment.Name = "RKSPXZ_FlightAttachment"
            attachment.Parent = root
            linearVelocity = Instance.new("LinearVelocity")
            linearVelocity.Name = "RKSPXZ_FlightVelocity"
            linearVelocity.Attachment0 = attachment
            linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
            linearVelocity.MaxForce = math.max(10000, root.AssemblyMass * workspace.Gravity * 20)
            linearVelocity.VectorVelocity = Vector3.zero
            linearVelocity.Parent = root
            orientation = Instance.new("AlignOrientation")
            orientation.Name = "RKSPXZ_FlightOrientation"
            orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
            orientation.Attachment0 = attachment
            orientation.MaxTorque = 1e6
            orientation.Responsiveness = 20
            orientation.CFrame = root.CFrame.Rotation
            orientation.Parent = root
            status("Voo ativo: WASD / Espaco sobe / Ctrl desce.")
        end,
    })
    tab:Keybind({
        Title = "Tecla para voar",
        Default = Enum.KeyCode.F,
        AllowProcessed = true,
        Callback = function() flightControl:Toggle() end,
    })
    tab:Slider({
        Title = "Velocidade do voo",
        Value = {Min = 5, Max = 80, Default = 35}, Step = 1,
        Callback = function(value) flySpeed = math.clamp(value, 5, 80) end,
    })
    rkStopFlight = function()
        flightGeneration = flightGeneration + 1
        stopFlight(true)
        flightControl:Set(false)
    end
    rkConnect(RunService.Stepped, function()
        if not noclip then return end
        if rkFlingBusy or rkAutoKillBusy then restoreCollisions(); return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if collisions[part] == nil then
                    if farmCollisionStates[part] ~= nil then collisions[part] = farmCollisionStates[part]
                    else collisions[part] = part.CanCollide end
                end
                part.CanCollide = false
            end
        end
    end)
    rkConnect(RunService.Heartbeat, function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if speed and hum then
            if originalSpeeds[hum] == nil then originalSpeeds[hum] = hum.WalkSpeed end
            hum.WalkSpeed = speed
        end
        if not rkFlying or not linearVelocity then return end
        if not flightRoot or not flightRoot.Parent or flightHumanoid ~= hum or hum.Health <= 0 then
            stopFlight(true)
            flightControl:Set(false)
            return
        end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local direction = Vector3.zero
        if not UserInputService:GetFocusedTextBox() then
            local forward, sideways, vertical = 0, 0, 0
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then forward = forward + 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then forward = forward - 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then sideways = sideways + 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then sideways = sideways - 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = vertical + 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = vertical - 1 end
            direction = camera.CFrame.LookVector * forward + camera.CFrame.RightVector * sideways + Vector3.new(0, vertical, 0)
            if direction.Magnitude > 1 then direction = direction.Unit end
        end
        linearVelocity.VectorVelocity = direction * flySpeed
        orientation.CFrame = camera.CFrame.Rotation
    end)
    WindUI:OnInterfaceDestroyed(function()
        flightGeneration = flightGeneration + 1
        speed, noclip = nil, false
        antiFling = false
        stopFlight()
        restoreAntiFling()
        restoreCollisions()
        restoreSpeeds()
        rkStopFlight = nil
    end)
end

-- Desliga o estado e destroi os objetos criados pelo script, nao apenas o menu.
WindUI:OnInterfaceDestroyed(function()
    rkRuntimeActive = false
    ESPSettings.AutoGrabGun = false
    ESPSettings.Enabled = false
    ESPSettings.OutlineESP = false
    ESPSettings.BoxESP = false
    ESPSettings.ShowName = false
    ESPSettings.ShowDistance = false
    ESPSettings.GunDropESP = false
    ESPSettings.NotifyGunDrop = false
    fastestAutofarmEnabled = false
    coinDetectionEnabled = false
    flingMurdererEnabled = false
    silentAimEnabled = false
    if rkStopFling then pcall(rkStopFling) end
    if fastestAutofarmThread then pcall(task.cancel, fastestAutofarmThread) end
    if coinDetectionThread then pcall(task.cancel, coinDetectionThread) end
    if reportingThread then pcall(task.cancel, reportingThread) end
    pcall(disableNoclip)
    for player, objects in pairs(ESPObjects) do
        for _, object in pairs(objects) do
            if typeof(object) == "Instance" then pcall(function() object:Destroy() end) end
        end
        ESPObjects[player] = nil
    end
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:GetAttribute("RKSPXZOwned") == true then pcall(function() object:Destroy() end) end
    end
    pcall(RemoveShotButton)
    pcall(RemoveAimButton)
    pcall(function() Aimbot.Functions:Exit() end)
    local camera = workspace.CurrentCamera
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        if hum then camera.CameraSubject = hum end
    end
end)
