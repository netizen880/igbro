--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Chuddy = {}
Chuddy.__index = Chuddy
Chuddy.Flags = {} :: any
Chuddy._accentRegistry = {} :: any
Chuddy._flagDefaults = {} :: any
Chuddy._flagTypes = {} :: any
Chuddy._flagSetters = {} :: any
Chuddy._flagOrder = {} :: any
Chuddy._windows = {} :: any

Chuddy.Theme = {
	Accent         = Color3.fromRGB(240, 110, 30),
	AccentDim      = Color3.fromRGB(110, 52, 16),
	AccentBarDark  = Color3.fromRGB(85, 32, 6),
	AccentBar      = Color3.fromRGB(165, 72, 18),
	AccentBarBright= Color3.fromRGB(240, 110, 30),
	ToggleOn       = Color3.fromRGB(110, 158, 75),

	HeaderBg   = Color3.fromRGB(22, 22, 22),
	WindowBg   = Color3.fromRGB(31, 31, 31),
	PanelBg    = Color3.fromRGB(31, 31, 31),
	ControlBg  = Color3.fromRGB(16, 16, 16),
	CheckboxBg = Color3.fromRGB(28, 28, 28),
	ListEven   = Color3.fromRGB(28, 28, 28),
	ListOdd    = Color3.fromRGB(36, 36, 36),

	WindowBorder = Color3.fromRGB(13, 13, 13),
	Stroke       = Color3.fromRGB(62, 62, 62),
	StrokeHover  = Color3.fromRGB(108, 108, 108),
	TabBorder    = Color3.fromRGB(65, 65, 65),

	TabHighlight = Color3.fromRGB(162, 144, 124),
	SliderTrack  = Color3.fromRGB(26, 26, 26),
	SliderFill   = Color3.fromRGB(240, 110, 30),
	SliderKnob   = Color3.fromRGB(155, 155, 155),
	BevelDark    = Color3.fromRGB(14, 14, 14),
	BevelLight   = Color3.fromRGB(66, 66, 66),

	Text         = Color3.fromRGB(205, 205, 205),
	TextStrong   = Color3.fromRGB(255, 255, 255),
	TextDisabled = Color3.fromRGB(112, 112, 112),
	TitleText    = Color3.fromRGB(240, 240, 240),
}

Chuddy.FontBody = Enum.Font.Arial
Chuddy.FontBold = Enum.Font.ArialBold

Chuddy.BindMode = { Toggle = 0, Hold = 1, Always = 2 }

local function New(className: string, props: any?, children: any?): Instance
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				pcall(function()
					(inst :: any)[k] = v
				end)
			end
		end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	if props and (props :: any).Parent then
		inst.Parent = (props :: any).Parent
	end
	return inst
end

local function Stroke(parent: Instance, color: Color3, thickness: number?): UIStroke
	return New("UIStroke", {
		Parent = parent,
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter,
	}) :: UIStroke
end

local function Pad(parent: Instance, l: number?, t: number?, r: number?, b: number?): UIPadding
	return New("UIPadding", {
		Parent = parent,
		PaddingLeft = UDim.new(0, l or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
	}) :: UIPadding
end

local function DrawLine(parent: Instance, x1: number, y1: number, x2: number, y2: number, thick: number, color: Color3): Frame
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	return New("Frame", {
		Parent = parent,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((x1 + x2) * 0.5, (y1 + y2) * 0.5),
		Size = UDim2.fromOffset(len + thick * 0.4, thick),
		Rotation = math.deg(math.atan2(dy, dx)),
	}) :: Frame
end

local function Label(text: string, size: number, color: Color3, bold: boolean?): TextLabel
	return New("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Chuddy.FontBody,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.XY,
	}) :: TextLabel
end

local function trackAccent(inst: GuiObject, kind: string)
	table.insert(Chuddy._accentRegistry, { Inst = inst, Kind = kind })
end

function Chuddy:SetAccent(c: Color3)
	local t = self.Theme
	t.Accent = c
	t.AccentBarBright = c
	t.SliderFill = c
	t.AccentBar = Color3.new(c.R * 0.67, c.G * 0.67, c.B * 0.67)
	t.AccentDim = Color3.new(c.R * 0.47, c.G * 0.47, c.B * 0.47)
	t.AccentBarDark = Color3.new(c.R * 0.31, c.G * 0.31, c.B * 0.31)
	for _, e in ipairs(Chuddy._accentRegistry) do
		local inst = e.Inst :: GuiObject
		if e.Kind == "bg" then inst.BackgroundColor3 = t.Accent
		elseif e.Kind == "accentBar" then inst.BackgroundColor3 = t.AccentBar
		elseif e.Kind == "accentBarDark" then inst.BackgroundColor3 = t.AccentBarDark
		elseif e.Kind == "accentBarBright" then inst.BackgroundColor3 = t.AccentBarBright
		elseif e.Kind == "text" then (inst :: TextLabel).TextColor3 = t.Accent end
	end

	for _, W in ipairs(Chuddy._windows) do
		for _, tb in ipairs(W.Tabs) do
			if tb.Page.Visible then tb.Label.TextColor3 = t.Accent end
		end
		for _, bar in ipairs(W._subBars or {}) do
			for i, pg in ipairs(bar._pages) do
				if pg.Visible then bar._buttons[i].Label.TextColor3 = t.Accent end
			end
		end
	end
end

function Chuddy:RegisterFlag(flag: string, default: any, setter: (any)->())
	if flag == nil or flag == "" then return end
	if Chuddy.Flags[flag] == nil then
		Chuddy.Flags[flag] = default
		Chuddy._flagDefaults[flag] = default
		Chuddy._flagSetters[flag] = setter
		table.insert(Chuddy._flagOrder, flag)
	end
end

function Chuddy:FlagType(flag: string, t: string)
	if flag and flag ~= "" and Chuddy._flagTypes[flag] == nil then
		Chuddy._flagTypes[flag] = t
	end
end

local KeyNames: any = {}
for _, kc in ipairs(Enum.KeyCode:GetEnumItems()) do
	KeyNames[kc] = kc.Name
end
local function KeyLabel(key: Enum.KeyCode?): string
	if key == nil then return "-" end
	local n: string = (key :: any).Name
	if n == "Unknown" then return "-" end
	local short: any = {
		ButtonR2 = "M1", ButtonL2 = "M2", ButtonR1 = "M3",
		RightShift = "RShift", LeftShift = "LShift",
		RightControl = "RCtrl", LeftControl = "LCtrl",
		RightAlt = "RAlt", LeftAlt = "LAlt",
	}
	if short[n] then return short[n] end

	return n
end

export type WindowOpts = {
	Title1: string?,
	Title2: string?,
	Title3: string?,
	Size: UDim2?,
	Position: UDim2?,
	ToggleKey: Enum.KeyCode?,
	Accent: Color3?,
	SearchEnabled: boolean?,
}

function Chuddy:CreateWindow(opts: WindowOpts?): any
	opts = opts or {}
	local T = self.Theme
	if opts.Accent then self:SetAccent(opts.Accent) end

	local title1 = opts.Title1 or "chud"
	local title2 = opts.Title2 or "vision"
	local title3 = opts.Title3 or ".net"
	local toggleKeyRef = { Key = opts.ToggleKey or Enum.KeyCode.Insert }

	local guiParent: Instance
	do
		local ok, hui = pcall(function() return gethui and gethui() end)
		if ok and hui then guiParent = hui
		else
			local cg = game:GetService("CoreGui")
			local ok2 = pcall(function() cg:GetChildren() end)
			guiParent = if ok2 then cg else LocalPlayer:WaitForChild("PlayerGui")
		end
	end

	local screen = New("ScreenGui", {
		Name = "chudvision",
		Parent = guiParent,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})

	local winSize: UDim2 = opts.Size or UDim2.fromOffset(458, 373)
	local winPos: UDim2 = opts.Position or UDim2.new(0.5, -229, 0.5, -186)

	local main = New("Frame", {
		Name = "Main",
		Parent = screen,
		Position = winPos,
		Size = winSize,
		BackgroundColor3 = T.PanelBg,
		BorderSizePixel = 0,
		Active = true,
	}) :: Frame
	Stroke(main, T.WindowBorder, 1)
	New("UISizeConstraint", { Parent = main, MinSize = Vector2.new(400, 320) })

	local TITLE_H, TAB_H = 18, 15

	local underline = New("Frame", {
		Parent = main, BackgroundColor3 = T.Stroke, BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, TITLE_H + TAB_H),
		Size = UDim2.new(1, -12, 0, 1),
	}) :: Frame

	local header = New("Frame", {
		Parent = main, BackgroundColor3 = T.HeaderBg, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, TITLE_H + TAB_H), Active = true,
	}) :: Frame

	local titleRow = New("Frame", {
		Parent = header, BackgroundTransparency = 1, Active = true,
		Size = UDim2.new(1, 0, 0, TITLE_H),
	}) :: Frame

	local t1 = Label(title1, 10, T.TitleText) t1.Font = Chuddy.FontBold
	t1.Position = UDim2.fromOffset(6, 2) t1.Parent = titleRow

	local w1 = TextService:GetTextSize(title1, 10, Chuddy.FontBold, Vector2.new(500, 20)).X
	local t2 = Label(title2, 10, T.Accent) t2.Font = Chuddy.FontBold
	t2.Position = UDim2.fromOffset(6 + w1, 2) t2.Parent = titleRow
	trackAccent(t2, "text")
	local w2 = TextService:GetTextSize(title2, 10, Chuddy.FontBold, Vector2.new(500, 20)).X
	local t3 = Label(title3, 10, T.TitleText) t3.Font = Chuddy.FontBold
	t3.Position = UDim2.fromOffset(6 + w1 + w2, 2) t3.Parent = titleRow

	local tabRow = New("Frame", {
		Parent = header, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, TITLE_H),
		Size = UDim2.new(1, 0, 0, TAB_H),
	}) :: Frame
	New("UIListLayout", {
		Parent = tabRow, FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	})
	Pad(tabRow, 6, 0, 6, 0)

	local content = New("Frame", {
		Parent = main, BackgroundColor3 = T.PanelBg, BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, TITLE_H + TAB_H + 1),
		Size = UDim2.new(1, -12, 1, -(TITLE_H + TAB_H + 7)),
	}) :: Frame
	Stroke(content, T.TabBorder, 1)

	do
		local dragging = false
		local dragStart: Vector2 = Vector2.zero
		local startPos: UDim2 = main.Position
		UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			local mp = input.Position
			local tp, ts = titleRow.AbsolutePosition, titleRow.AbsoluteSize
			if mp.X < tp.X or mp.X > tp.X + ts.X or mp.Y < tp.Y or mp.Y > tp.Y + ts.Y then return end
			dragging = true
			dragStart = mp
			startPos = main.Position
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			if main == nil or startPos == nil or dragStart == nil then
				dragging = false
				return
			end
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end

	local Window: any = {}
	Window.Gui = screen
	Window.Main = main
	Window.Tabs = {}
	Window._searchables = {}
	Window._subBars = {} :: any
	Window._current = nil

	function Window:ToggleVisible()
		screen.Enabled = not screen.Enabled
	end
	function Window:SetToggleKey(key: Enum.KeyCode?)
		toggleKeyRef.Key = key
	end

	function Window:SetScale(s: number)
		self._scale = s
		local u = self.Main:FindFirstChildOfClass("UIScale")
		if not u then
			u = New("UIScale", { Parent = self.Main })
		end
		(u :: UIScale).Scale = s
	end
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if toggleKeyRef.Key ~= nil and input.KeyCode == toggleKeyRef.Key then
			screen.Enabled = not screen.Enabled
		end
	end)

	function Window:_registerSearchable(frame: GuiObject, keys: string)
		table.insert(self._searchables, { Frame = frame, Keys = keys })
	end

	local function buildTopTab(parent: Frame, tname: string, isActive: boolean, order: number, heightY: UDim): any
		local tw = TextService:GetTextSize(tname, 11, Chuddy.FontBody, Vector2.new(1000, 20)).X
		local btn = New("TextButton", {
			Parent = parent, Text = "", AutoButtonColor = false,
			BackgroundColor3 = T.WindowBg, BorderSizePixel = 0,
			Size = UDim2.new(0, tw + 10, heightY.Scale, heightY.Offset),
			LayoutOrder = order,
		}) :: TextButton
		local lbl = Label(tname, 11, T.TextStrong)
		lbl.AutomaticSize = Enum.AutomaticSize.None
		lbl.Position = UDim2.fromOffset(5, 0)
		lbl.Size = UDim2.new(1, -5, 1, 0)
		lbl.Parent = btn
		trackAccent(lbl, "text")

		local capDark = New("Frame", { Parent = btn, BackgroundColor3 = T.AccentBarDark, BorderSizePixel = 0,
			Position = UDim2.fromOffset(3, -3), Size = UDim2.new(1, -6, 0, 1), Visible = isActive }) :: Frame
		trackAccent(capDark, "accentBarDark")
		local capMid = New("Frame", { Parent = btn, BackgroundColor3 = T.AccentBar, BorderSizePixel = 0,
			Position = UDim2.fromOffset(2, -2), Size = UDim2.new(1, -4, 0, 1), Visible = isActive }) :: Frame
		trackAccent(capMid, "accentBar")
		local capTop = New("Frame", { Parent = btn, BackgroundColor3 = T.AccentBarBright, BorderSizePixel = 0,
			Position = UDim2.fromOffset(1, -1), Size = UDim2.new(1, -2, 0, 1), Visible = isActive }) :: Frame
		trackAccent(capTop, "accentBarBright")

		local edgeTop = New("Frame", { Parent = btn, BackgroundColor3 = if isActive then T.TabHighlight else T.TabBorder,
			BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 1) }) :: Frame
		New("Frame", { Parent = btn, BackgroundColor3 = T.TabBorder, BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, 1, 1, 0) })
		New("Frame", { Parent = btn, BackgroundColor3 = T.WindowBorder, BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0) })

		local foot = New("Frame", { Parent = btn, BackgroundColor3 = T.WindowBg, BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), Visible = isActive }) :: Frame
		return { Btn = btn, Label = lbl, Cap = {capDark, capMid, capTop}, EdgeTop = edgeTop, Foot = foot }
	end

	function Window:AddTab(name: string): any
		local order = #self.Tabs + 1
		local isActive = order == 1

		local parts = buildTopTab(tabRow, name, isActive, order, UDim.new(1, 0))
		local btn, lbl = parts.Btn, parts.Label
		local capDark, capMid, capTop = parts.Cap[1], parts.Cap[2], parts.Cap[3]
		local edgeTop = parts.EdgeTop
		local foot = parts.Foot

		local page = New("ScrollingFrame", {
			Parent = content, BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1), Visible = isActive,
			ScrollBarThickness = 2, ScrollBarImageColor3 = T.Stroke,
			CanvasSize = UDim2.fromScale(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}) :: ScrollingFrame
		Pad(page, 4, 4, 4, 4)
		local hlist = New("UIListLayout", {
			Parent = page, FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		}) :: UIListLayout

		local Tab: any = {}
		Tab.Name = name
		Tab.Button = btn
		Tab.Page = page
		Tab._columns = {}
		Tab._window = self

		function Tab:CreateColumn(ratio: number?): any
			local idx = #self._columns + 1
			local col = New("Frame", {
				Parent = page, BackgroundTransparency = 1, LayoutOrder = idx,
			}) :: Frame
			if ratio and ratio > 0 then
				col.Size = UDim2.new(ratio, -3, 0, 0)
				col.AutomaticSize = Enum.AutomaticSize.Y
			else
				col.Size = UDim2.new(0.5, -3, 0, 0)
				col.AutomaticSize = Enum.AutomaticSize.Y
			end
			New("UIListLayout", { Parent = col, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
			table.insert(self._columns, col)

			local Col: any = {}
			Col.Frame = col
			function Col:AddGroupbox(title: string, heightPx: number?): any
				return Tab._window:_addGroupbox(col, title, heightPx)
			end

			return Col
		end

		function Tab:AddLeftGroupbox(title: string): any
			if #self._columns == 0 then self:CreateColumn(0.5) self:CreateColumn(nil) end
			return Tab._window:_addGroupbox(self._columns[1], title)
		end
		function Tab:AddRightGroupbox(title: string): any
			if #self._columns == 0 then self:CreateColumn(0.5) self:CreateColumn(nil) end
			return Tab._window:_addGroupbox(self._columns[2], title)
		end
		function Tab:AddGroupbox(title: string, side: string?): any
			if #self._columns == 0 then self:CreateColumn(0.5) self:CreateColumn(nil) end
			if side == "right" then return Tab._window:_addGroupbox(self._columns[2], title) end
			return Tab._window:_addGroupbox(self._columns[1], title)
		end

		function Tab:CreateSubTabBar(ratio: number?): any
			local idx = 0
			for _, _ in ipairs(page:GetChildren()) do idx += 1 end
			local holder = New("Frame", { Parent = page, BackgroundTransparency = 1, LayoutOrder = idx }) :: Frame
			if ratio and ratio > 0 then holder.Size = UDim2.new(ratio, -3, 0, 0)
			else holder.Size = UDim2.new(0.5, -3, 0, 0) end
			holder.AutomaticSize = Enum.AutomaticSize.Y
			New("UIListLayout", { Parent = holder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) })

			New("Frame", { Parent = holder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 3), LayoutOrder = 1 })
			New("Frame", { Parent = holder, BackgroundColor3 = T.Stroke, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 3 })
			local strip = New("Frame", { Parent = holder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), LayoutOrder = 2 }) :: Frame
			New("UIListLayout", { Parent = strip, FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom })
			local contentH = New("Frame", { Parent = holder, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4 }) :: Frame
			Pad(contentH, 0, 5, 0, 0)

			local Bar: any = { _pages = {}, _buttons = {} }
			function Bar:AddTab(tname: string): Frame
				local torder = #Bar._pages + 1
				local active = torder == 1
				local tp = buildTopTab(strip, tname, active, torder, UDim.new(0, 15))
				for i = #Chuddy._accentRegistry, 1, -1 do
					if Chuddy._accentRegistry[i].Inst == tp.Label then table.remove(Chuddy._accentRegistry, i) end
				end
				tp.Label.TextColor3 = active and T.Accent or T.TextStrong
				local pg = New("Frame", { Parent = contentH, BackgroundTransparency = 1, Visible = active,
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }) :: Frame
				New("UIListLayout", { Parent = pg, FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
				table.insert(Bar._pages, pg)
				table.insert(Bar._buttons, tp)
				tp.Btn.MouseButton1Click:Connect(function()
					for i, p2 in ipairs(Bar._buttons) do
						local on = Bar._pages[i] == pg
						Bar._pages[i].Visible = on
						p2.Cap[1].Visible = on; p2.Cap[2].Visible = on; p2.Cap[3].Visible = on
						p2.Foot.Visible = on
						p2.EdgeTop.BackgroundColor3 = on and T.TabHighlight or T.TabBorder
						p2.Label.TextColor3 = on and T.Accent or T.TextStrong
					end
				end)
				return pg
			end
			function Bar:AddGroupbox(pg: Frame, title: string, heightPx: number?, widthScale: number?): any
				return Tab._window:_addGroupbox(pg, title, heightPx, widthScale)
			end
			table.insert(Tab._window._subBars, Bar)
			return Bar
		end

		local function refreshTabs()
			for i, tb in ipairs(self.Tabs) do
				local active = tb.Tab == Tab
				tb.Page.Visible = active
				tb.Cap[1].Visible = active; tb.Cap[2].Visible = active; tb.Cap[3].Visible = active
				tb.Foot.Visible = active
				tb.EdgeTop.BackgroundColor3 = active and T.TabHighlight or T.TabBorder

				if active then tb.Label.TextColor3 = T.Accent else tb.Label.TextColor3 = T.TextStrong end
			end
		end
		btn.MouseButton1Click:Connect(refreshTabs)

		for i = #Chuddy._accentRegistry, 1, -1 do
			if Chuddy._accentRegistry[i].Inst == lbl then table.remove(Chuddy._accentRegistry, i) end
		end

		table.insert(self.Tabs, { Tab = Tab, Page = page, Label = lbl, Cap = {capDark, capMid, capTop}, EdgeTop = edgeTop, Foot = foot })
		if isActive then refreshTabs() end
		return Tab
	end

	function Window:_addGroupbox(column: Frame, title: string, heightPx: number?, widthScale: number?): any
		local T2 = Chuddy.Theme
		local holder = New("Frame", {
			Parent = column, BackgroundTransparency = 1,
			Size = UDim2.new(widthScale or 1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		}) :: Frame

		local caption = Label(title, 11, T2.TextStrong) caption.Font = Chuddy.FontBold
		caption.Parent = holder

		local boxProps: any = {
			Parent = holder, BackgroundColor3 = T2.PanelBg, BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 6), ClipsDescendants = true,
		}
		if heightPx and heightPx > 0 then
			boxProps.Size = UDim2.new(1, 0, 0, heightPx)
		else
			boxProps.Size = UDim2.new(1, 0, 0, 0)
			boxProps.AutomaticSize = Enum.AutomaticSize.Y
		end
		local box = New("Frame", boxProps) :: Frame
		Stroke(box, T2.Stroke, 1)
		New("UICorner", { Parent = box, CornerRadius = UDim.new(0, 2) })
		Pad(box, 9, 8, 9, 6)
		New("UIListLayout", { Parent = box, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })

		local chip = New("Frame", {
			Parent = holder, BackgroundColor3 = T2.WindowBg, BorderSizePixel = 0,
			Position = UDim2.fromOffset(3, 0), Size = UDim2.fromOffset(10, 12),
			AutomaticSize = Enum.AutomaticSize.X,
		}) :: Frame
		caption.Parent = chip
		caption.Position = UDim2.fromOffset(4, 0)

		local Group: any = {}
		Group.Frame = box
		Group._window = self
		Group._indent = 0
		Group._captionLabel = caption

		function Group:SetTitle(t: string)
			(Group._captionLabel :: TextLabel).Text = t
		end

		function Group:Indent()
			Group._indent = math.min((Group._indent or 0) + 8, 64)
		end
		function Group:Unindent()
			Group._indent = math.max((Group._indent or 0) - 8, 0)
		end

		local function indentWrap(roots: {GuiObject}): GuiObject
			if (Group._indent or 0) <= 0 then return roots[1] end
			local w = New("Frame", {
				Parent = box, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			}) :: Frame
			Pad(w, Group._indent, 0, 0, 0)
			for _, r in ipairs(roots) do r.Parent = w end
			if #roots > 1 then
				New("UIListLayout", { Parent = w, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })
			end
			return w
		end

		local function makeSwatch(anchor: Frame, getPos: (number) -> UDim2, cp: any): any
			cp = cp or {}
			local def: Color3 = cp.Default or Color3.fromRGB(220, 220, 220)
			local ccb = cp.Callback
			local cflag = cp.Flag
			if cflag and Chuddy.Flags[cflag] ~= nil then
				local v = Chuddy.Flags[cflag]
				if typeof(v) == "Color3" then def = v end
			end
			if cflag then Chuddy:FlagType(cflag, "color") end
			local sw = New("TextButton", { Parent = anchor, Text = "", AutoButtonColor = false,
				BackgroundColor3 = def, BorderSizePixel = 0, ZIndex = 3,
				AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(28, 10) }) :: TextButton
			sw.Position = getPos(28)
			Stroke(sw, T2.Stroke, 1)
			local alpha0 = 1
			if cflag then
				local av = Chuddy.Flags[cflag .. "Alpha"]
				if typeof(av) == "number" then alpha0 = math.clamp(av, 0, 1) end
			end
			local C: any = { Value = def, Alpha = alpha0 }
			local function refreshSwatch()
				sw.BackgroundColor3 = C.Value
				sw.BackgroundTransparency = 1 - C.Alpha
			end
			function C:Set(c: Color3)
				C.Value = c; refreshSwatch()
				if cflag then Chuddy.Flags[cflag] = c end
				if ccb then task.spawn(ccb, c) end
			end
			function C:SetAlpha(a: number)
				C.Alpha = math.clamp(a, 0, 1); refreshSwatch()
				if cflag then Chuddy.Flags[cflag .. "Alpha"] = C.Alpha end
				if ccb then task.spawn(ccb, C.Value) end
			end
			if cflag then
				Chuddy:FlagType(cflag .. "Alpha", "float")
				Chuddy:RegisterFlag(cflag .. "Alpha", C.Alpha, function(a) C:SetAlpha(a) end)
			end
			refreshSwatch()

			local pop: Frame? = nil
			sw.MouseButton1Click:Connect(function()
				if pop and pop.Parent then pop:Destroy() pop = nil return end
				pop = New("Frame", { BackgroundColor3 = T2.CheckboxBg, BorderSizePixel = 0,
					Size = UDim2.fromOffset(150, 178) }) :: Frame
				pop.Parent = screen; pop.ZIndex = 60
				do
					local p = sw.AbsolutePosition
					local sp = screen.AbsolutePosition
					pop.Position = UDim2.fromOffset(p.X - sp.X - 122, (p.Y - sp.Y) + 12)
				end
				Stroke(pop, T2.Stroke, 1); Pad(pop, 6, 6, 6, 6)
				New("UIListLayout", { Parent = pop, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })

				local hue, sat, val = C.Value:ToHSV()
				local savedH, savedS = hue, sat
				local alpha: number = C.Alpha
				local SV = 138

				local function renderHue(): number
					return if sat <= 0 then savedH else hue
				end

				local svBase = New("Frame", { Parent = pop, BackgroundColor3 = Color3.fromHSV(renderHue(), 1, 1),
					BorderSizePixel = 0, Size = UDim2.fromOffset(SV, SV), LayoutOrder = 1 }) :: Frame
				local svWhite = New("Frame", { Parent = svBase, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }) :: Frame
				New("UIGradient", { Parent = svWhite, Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
				local svBlack = New("Frame", { Parent = svBase, BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }) :: Frame
				New("UIGradient", { Parent = svBlack, Rotation = 90, Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
				Stroke(svBase, T2.BevelDark, 1)
				local svCurO = New("Frame", { Parent = svBase, BackgroundColor3 = T2.BevelDark,
					BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 7) }) :: Frame
				New("Frame", { Parent = svCurO, BackgroundColor3 = T2.TextStrong,
					BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(5, 5) })

				local hueBar = New("Frame", { Parent = pop, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0, Size = UDim2.fromOffset(SV, 8), LayoutOrder = 2 }) :: Frame
				New("UIGradient", { Parent = hueBar, Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }) })
				Stroke(hueBar, T2.BevelDark, 1)
				local hueHO = New("Frame", { Parent = hueBar, BackgroundColor3 = T2.BevelDark,
					BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 10) }) :: Frame
				New("Frame", { Parent = hueHO, BackgroundColor3 = T2.TextStrong,
					BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(2, 8) })

				local alphaBar = New("Frame", { Parent = pop, BackgroundColor3 = Color3.fromRGB(200, 200, 200),
					BorderSizePixel = 0, ClipsDescendants = true,
					Size = UDim2.fromOffset(SV, 8), LayoutOrder = 3 }) :: Frame
				do
					local cell = 5
					for yy = 0, 1 do
						for xx = 0, 27 do
							New("Frame", { Parent = alphaBar,
								BackgroundColor3 = if (xx + yy) % 2 == 0
									then Color3.fromRGB(200, 200, 200) else Color3.fromRGB(140, 140, 140),
								BorderSizePixel = 0, Position = UDim2.fromOffset(xx * cell, yy * cell),
								Size = UDim2.fromOffset(cell, cell) })
						end
					end
				end
				local alphaGrad = New("Frame", { Parent = alphaBar, BackgroundColor3 = C.Value,
					BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }) :: Frame
				New("UIGradient", { Parent = alphaGrad, Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
				Stroke(alphaBar, T2.BevelDark, 1)
				local alphaHO = New("Frame", { Parent = alphaBar, BackgroundColor3 = T2.BevelDark,
					BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 10) }) :: Frame
				New("Frame", { Parent = alphaHO, BackgroundColor3 = T2.TextStrong,
					BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(2, 8) })

				local function paint()
					svBase.BackgroundColor3 = Color3.fromHSV(renderHue(), 1, 1)
					svCurO.Position = UDim2.fromOffset(
						math.clamp(sat * SV, 3, SV - 3), math.clamp((1 - val) * SV, 3, SV - 3))
					hueHO.Position = UDim2.fromOffset(math.clamp(hue * SV, 2, SV - 2), 4)
					alphaGrad.BackgroundColor3 = C.Value
					alphaHO.Position = UDim2.fromOffset(math.clamp(alpha * SV, 2, SV - 2), 4)
					refreshSwatch()
				end
				local function push()
					C:Set(Color3.fromHSV(renderHue(), sat, val))
					paint()
				end
				local function setAlpha(a: number)
					alpha = math.clamp(a, 0, 1)
					C:SetAlpha(alpha)
					paint()
				end

				local function dragZone(btn: TextButton, fn: (Vector2) -> ())
					btn.InputBegan:Connect(function(inp)
						if inp.UserInputType == Enum.UserInputType.MouseButton1 then
							fn(inp.Position)
							local mv; mv = UserInputService.InputChanged:Connect(function(mm)
								if mm.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then fn(mm.Position) end
							end)
							UserInputService.InputEnded:Wait(); if mv then mv:Disconnect() end
						end
					end)
				end
				local svZone = New("TextButton", { Parent = svBase, BackgroundTransparency = 1, Text = "",
					AutoButtonColor = false, Size = UDim2.fromScale(1, 1) }) :: TextButton
				local hueZone = New("TextButton", { Parent = hueBar, BackgroundTransparency = 1, Text = "",
					AutoButtonColor = false, Size = UDim2.fromScale(1, 1) }) :: TextButton
				local alphaZone = New("TextButton", { Parent = alphaBar, BackgroundTransparency = 1, Text = "",
					AutoButtonColor = false, Size = UDim2.fromScale(1, 1) }) :: TextButton
				dragZone(svZone, function(p)
					local sn = math.clamp((p.X - svBase.AbsolutePosition.X) / SV, 0, 1)
					local vn = 1 - math.clamp((p.Y - svBase.AbsolutePosition.Y) / SV, 0, 1)
					sat = sn; val = vn; savedS = sat
					if sat <= 0 then hue = savedH end
					if val <= 0 then sat = savedS end
					push()
				end)
				dragZone(hueZone, function(p)
					hue = math.min(math.clamp((p.X - hueBar.AbsolutePosition.X) / SV, 0, 1), 0.9999)
					savedH = hue
					push()
				end)
				dragZone(alphaZone, function(p)
					setAlpha(math.clamp((p.X - alphaBar.AbsolutePosition.X) / SV, 0, 1))
				end)
				paint()
			end)
			return C
		end

		function Group:AddColorRow(opts2: any): any
			local text = opts2.Text or ""
			local row = New("Frame", { Parent = box, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14) }) :: Frame
			local lab = Label(text, 11, T2.Text)
			lab.AutomaticSize = Enum.AutomaticSize.None
			lab.Position = UDim2.fromOffset(0, 0); lab.Size = UDim2.new(1, -40, 1, 0)
			lab.TextTruncate = Enum.TextTruncate.AtEnd; lab.Parent = row
			local rightX = 0
			local function reserveR(w: number): UDim2
				rightX += w + 3
				return UDim2.new(1, -rightX, 0.5, 0)
			end
			local C = makeSwatch(row, reserveR, opts2)
			local root = indentWrap({row})
			self._window:_registerSearchable(root, text)
			return C
		end

		function Group:AddLabel(text: string)
			local l = Label(text, 11, T2.Text)
			l.Parent = box
			indentWrap({l})
			return l
		end
		function Group:AddDivider()
			local d = New("Frame", { Parent = box, BackgroundColor3 = T2.Stroke,
				BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1) }) :: Frame
			return d
		end
		function Group:AddButton(opts2: any): any
			local text = opts2.Text or opts2[1] or "Button"
			local cb = opts2.Callback or opts2.Func
			local w: number? = opts2.Width
			local h: number = opts2.Height or 20
			local b = New("TextButton", {
				Parent = box, Text = "", AutoButtonColor = false,
				BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0,
				Size = if w then UDim2.fromOffset(w, h) else UDim2.new(1, 0, 0, h),
			}) :: TextButton
			Stroke(b, T2.Stroke, 1)
			local bl = Label(text, 11, T2.Text)
			bl.AnchorPoint = Vector2.new(0.5, 0.5); bl.Position = UDim2.fromScale(0.5, 0.5)
			bl.Parent = b
		b.MouseEnter:Connect(function()
			Stroke(b, T2.StrokeHover, 1)
			bl.TextColor3 = T2.TextStrong
		end)
		b.MouseLeave:Connect(function()
			for _, s in ipairs(b:GetChildren()) do if s:IsA("UIStroke") then s:Destroy() end end
			Stroke(b, T2.Stroke, 1)
			bl.TextColor3 = T2.Text
		end)
			b.MouseButton1Click:Connect(function() if cb then task.spawn(cb) end end)
			local broot = if opts2.NoIndent then b else indentWrap({b})
			self._window:_registerSearchable(broot, text)
			return b
		end

		function Group:AddButtonRow(items: any): any
			local rowF = New("Frame", { Parent = box, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16) }) :: Frame
			New("UIListLayout", { Parent = rowF, FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
			local outs: any = {}
			local n = #items
			for i, spec in ipairs(items) do
				local bb = Group:AddButton({ Text = spec.Text or spec[1], Callback = spec.Callback, Height = 16, NoIndent = true })
				bb.Parent = rowF
				bb.Size = UDim2.new(1 / n, -6 * (n - 1) / n, 0, 16)
				bb.LayoutOrder = i
				table.insert(outs, bb)
			end
			return outs
		end

		function Group:AddCheckbox(opts2: any): any
			local text = opts2.Text or opts2[1] or "Checkbox"
			local default = if opts2.Default ~= nil then opts2.Default else false
			local cb = opts2.Callback
			local flag = opts2.Flag
			if flag and Chuddy.Flags[flag] ~= nil then default = Chuddy.Flags[flag] end

			local row = New("Frame", { Parent = box, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14) }) :: Frame
			local hit = New("TextButton", { Parent = row, Text = "", BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1), ZIndex = 2 }) :: TextButton
			local cbox = New("Frame", { Parent = row, BackgroundColor3 = T2.CheckboxBg,
				BorderSizePixel = 0, Position = UDim2.fromOffset(0, 2), Size = UDim2.fromOffset(10, 10) }) :: Frame

			New("Frame", { Parent = cbox, BackgroundColor3 = T2.BevelDark, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1) })
			New("Frame", { Parent = cbox, BackgroundColor3 = T2.BevelDark, BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, 0) })
			New("Frame", { Parent = cbox, BackgroundColor3 = T2.BevelLight, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1) })
			New("Frame", { Parent = cbox, BackgroundColor3 = T2.BevelLight, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0) })
			local checkG = New("Frame", {
				Parent = cbox, BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1), Visible = default,
			}) :: Frame

			trackAccent(DrawLine(checkG, 2.2, 5.0, 4.4, 7.2, 2, T2.Accent), "bg")
			trackAccent(DrawLine(checkG, 4.4, 7.2, 8.0, 2.4, 2, T2.Accent), "bg")

			trackAccent(New("Frame", { Parent = checkG, BackgroundColor3 = T2.Accent, BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(4.4, 7.2),
				Size = UDim2.fromOffset(2.5, 2.5) }), "bg")
			local lab = Label(text, 11, default and T2.TextStrong or T2.Text)
			lab.AutomaticSize = Enum.AutomaticSize.None
			lab.Position = UDim2.fromOffset(15, 0); lab.Size = UDim2.new(1, -40, 1, 0)
			lab.TextTruncate = Enum.TextTruncate.AtEnd; lab.Parent = row

			local Ctrl: any = {}
			Ctrl.Row = row; Ctrl.Value = default
			if flag then Chuddy:FlagType(flag, "bool") end
			if flag then Chuddy:RegisterFlag(flag, default, function(v) Ctrl:Set(v) end) end
			function Ctrl:Set(v: boolean)
				Ctrl.Value = v
				checkG.Visible = v
				lab.TextColor3 = v and T2.TextStrong or T2.Text
				if flag then Chuddy.Flags[flag] = v end
				if cb then task.spawn(cb, v) end
			end
			function Ctrl:Get() return Ctrl.Value end
			hit.MouseButton1Click:Connect(function() Ctrl:Set(not Ctrl.Value) end)

			local rightX = 0
			local function reserve(w: number): UDim2
				rightX += w + 3
				return UDim2.new(1, -rightX, 0.5, 0)
			end
			function Ctrl:AddKeybind(kb: any): any
				kb = kb or {}
				if kb.Flag then Chuddy:FlagType(kb.Flag, "key") end
				if kb.ModeFlag then Chuddy:FlagType(kb.ModeFlag, "int") end
				local dKey: Enum.KeyCode? = kb.Default
				local dMode: number = kb.Mode or 0
				local kcb = kb.Callback
				local kflag, mflag = kb.Flag, kb.ModeFlag
				if kflag and Chuddy.Flags[kflag] ~= nil then dKey = Chuddy.Flags[kflag] end
				local pill = New("TextButton", { Parent = row, Text = "", AutoButtonColor = false,
					BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0, ZIndex = 3,
					AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(34, 13) }) :: TextButton
				pill.Position = reserve(34)
				Stroke(pill, T2.Stroke, 1)
				local pl = Label("-", 8, T2.TextStrong) pl.AnchorPoint = Vector2.new(0.5, 0.5)
				pl.AutomaticSize = Enum.AutomaticSize.None; pl.Size = UDim2.fromScale(1, 1)
				pl.TextXAlignment = Enum.TextXAlignment.Center; pl.TextTruncate = Enum.TextTruncate.AtEnd
				pl.Position = UDim2.fromScale(0.5, 0.5); pl.Parent = pill
				local K: any = { Key = dKey, Mode = dMode, Capturing = false }
				local function paint()
					if K.Capturing then pl.Text = "..."
					elseif K.Mode == 2 then pl.Text = "ON"; pl.TextColor3 = T2.ToggleOn
					else pl.Text = KeyLabel(K.Key); pl.TextColor3 = T2.TextStrong end
				end
				paint()
				pill.MouseButton1Click:Connect(function()
					K.Capturing = true; paint()
				end)
				pill.MouseButton2Click:Connect(function()
					K.Mode = (K.Mode + 1) % 3; paint()
					if mflag then Chuddy.Flags[mflag] = K.Mode end
					if kcb then task.spawn(kcb, K.Key, K.Mode) end
				end)
				UserInputService.InputBegan:Connect(function(input, gpe)
					if K.Capturing then
						if input.KeyCode == Enum.KeyCode.Escape then K.Key = nil
						elseif input.KeyCode ~= Enum.KeyCode.Unknown then K.Key = input.KeyCode end
						K.Capturing = false; paint()
						if kflag then Chuddy.Flags[kflag] = K.Key end
						if kcb then task.spawn(kcb, K.Key, K.Mode) end
						return
					end
					if gpe or K.Key == nil then return end
					if input.KeyCode == K.Key then
						if K.Mode == 0 then Ctrl:Set(not Ctrl.Value)
						elseif K.Mode == 1 then Ctrl:Set(true) end
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if not K.Capturing and K.Key ~= nil and input.KeyCode == K.Key and K.Mode == 1 then
						Ctrl:Set(false)
					end
				end)

				task.spawn(function()
					while pill.Parent do
						if K.Mode == 2 and not Ctrl.Value then Ctrl:Set(true) end
						task.wait(0.25)
					end
				end)
				return K
			end
			function Ctrl:AddColorPicker(cp: any): any
				return makeSwatch(row, reserve, cp)
			end
			function Ctrl:AddBadge(defaultOn: boolean?): any
				local b = New("Frame", { Parent = row, BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(28, 12) }) :: Frame
				b.Position = reserve(28)
				Stroke(b, T2.Stroke, 1)
				local bl = Label(defaultOn and "ON" or "OFF", 7, defaultOn and T2.ToggleOn or T2.TextDisabled)
				bl.AnchorPoint = Vector2.new(0.5, 0.5); bl.Position = UDim2.fromScale(0.5, 0.5); bl.Parent = b
				bl.AutomaticSize = Enum.AutomaticSize.None; bl.Size = UDim2.fromScale(1, 1)
				bl.TextXAlignment = Enum.TextXAlignment.Center; bl.TextTruncate = Enum.TextTruncate.AtEnd
				local B: any = {}
				function B:Set(on: boolean)
					bl.Text = on and "ON" or "OFF"
					bl.TextColor3 = on and T2.ToggleOn or T2.TextDisabled
				end

				local oldSet = Ctrl.Set
				function Ctrl:Set(v: boolean)
					oldSet(v); B:Set(v)
				end
				return B
			end

			local croot = indentWrap({row})
			self._window:_registerSearchable(croot, text)
			return Ctrl
		end

		function Group:AddSlider(opts2: any): any
			local text = opts2.Text or opts2[1] or "Slider"
			local min = opts2.Min or 0
			local max = opts2.Max or 100
			local default = if opts2.Default ~= nil then opts2.Default else min
			local suffix = opts2.Suffix or opts2.Format or ""
			local isFloat = opts2.Float or opts2.Decimals ~= nil
			local decimals = opts2.Decimals or 0
			local cb = opts2.Callback
			local flag = opts2.Flag
			if flag and Chuddy.Flags[flag] ~= nil then default = Chuddy.Flags[flag] end
			if flag then Chuddy:FlagType(flag, if isFloat then "float" else "int") end
			local unlimitedAtMax = opts2.UnlimitedAtMax

			local wrap = New("Frame", { Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26) }) :: Frame
			local nameL = Label(text, 11, T2.TextStrong) nameL.Position = UDim2.fromOffset(0, 0)
			nameL.AutomaticSize = Enum.AutomaticSize.None; nameL.Size = UDim2.new(1, -56, 1, 0)
			nameL.TextTruncate = Enum.TextTruncate.AtEnd; nameL.Parent = wrap
			local valL = Label("", 11, T2.TextStrong) valL.AnchorPoint = Vector2.new(1, 0)
			valL.Position = UDim2.new(1, 0, 0, 0) valL.Parent = wrap
			local track = New("TextButton", { Parent = wrap, Text = "", AutoButtonColor = false,
				BackgroundColor3 = T2.SliderTrack, BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 8) }) :: TextButton

			New("Frame", { Parent = track, BackgroundColor3 = T2.BevelDark, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1) })
			New("Frame", { Parent = track, BackgroundColor3 = T2.BevelLight, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1) })
			local fill = New("Frame", { Parent = track, BackgroundColor3 = T2.Accent, BorderSizePixel = 0,
				Position = UDim2.new(0, 1, 0.5, -1), Size = UDim2.new(0, 0, 0, 2) }) :: Frame
			trackAccent(fill, "bg")

			local knob = New("Frame", { Parent = track, BackgroundTransparency = 1,
				Size = UDim2.fromOffset(5, 12), Position = UDim2.new(0, 0, 0.5, -6) }) :: Frame
			New("Frame", { Parent = knob, BackgroundColor3 = T2.SliderKnob, BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(5, 10) })
			New("Frame", { Parent = knob, BackgroundColor3 = T2.SliderKnob, BorderSizePixel = 0,
				Position = UDim2.fromOffset(1, 10), Size = UDim2.fromOffset(3, 1) })
			New("Frame", { Parent = knob, BackgroundColor3 = T2.SliderKnob, BorderSizePixel = 0,
				Position = UDim2.fromOffset(2, 11), Size = UDim2.fromOffset(1, 1) })

			local S: any = { Value = default }
			local function fmt(v: number): string
				if unlimitedAtMax and math.floor(v + 0.5) >= max then return "Unlimited" end
				if isFloat then return string.format("%." .. tostring(decimals) .. "f%s", v, suffix) end
				return string.format("%d%s", math.floor(v + 0.5), suffix)
			end
			function S:Set(v: number, silent: boolean?)
				v = math.clamp(v, min, max)
				if not isFloat then v = math.floor(v + 0.5) end
				S.Value = v
				valL.Text = fmt(v)
				local f = if max > min then (v - min) / (max - min) else 0
				fill.Size = UDim2.new(f, -2, 0, 2)
				knob.Position = UDim2.new(f, -2, 0.5, -6)
				if flag then Chuddy.Flags[flag] = v end
				if cb and not silent then task.spawn(cb, v) end
			end
			function S:Get() return S.Value end
			S:Set(default, true)

			track.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 then
					local function upd(p: Vector2)
						local rel = math.clamp((p.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
						S:Set(min + rel * (max - min))
					end
					upd(inp.Position)
					local mv; mv = UserInputService.InputChanged:Connect(function(m)
						if m.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then upd(m.Position) end
					end)
					UserInputService.InputEnded:Wait(); if mv then mv:Disconnect() end
				end
			end)
			if flag then Chuddy:RegisterFlag(flag, default, function(v) S:Set(v, true) end) end
			local sroot = indentWrap({wrap})
			self._window:_registerSearchable(sroot, text)
			return S
		end

		function Group:AddDropdown(opts2: any): any
			local text = opts2.Text or opts2[1] or ""
			local items = opts2.Items or opts2.Options or { "Option 1" }
			local default = opts2.Default or 1
			if typeof(default) == "string" then
				for i, v in ipairs(items) do if v == default then default = i break end end
				if typeof(default) == "string" then default = 1 end
			end
			local cb = opts2.Callback
			local flag = opts2.Flag
			if flag then Chuddy:FlagType(flag, "int") end
			if flag and Chuddy.Flags[flag] ~= nil then
				local fv = Chuddy.Flags[flag]
				if typeof(fv) == "number" then default = math.clamp(fv, 1, #items)
				elseif typeof(fv) == "string" then for i, v in ipairs(items) do if v == fv then default = i break end end end
			end

			local shown: string = (text:match("^(.-)##") or text)
			local droots: {GuiObject} = {}
			if text ~= "" then
				local cap = Label(shown, 11, T2.Text) cap.Position = UDim2.fromOffset(0, 0) cap.Parent = box
				table.insert(droots, cap)
			end
			local dd = New("TextButton", { Parent = box, Text = "", AutoButtonColor = false,
				BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 15) }) :: TextButton
			table.insert(droots, dd)
			Stroke(dd, T2.Stroke, 1)
			local cur = Label(items[default] or "", 11, T2.TextStrong)
			cur.AutomaticSize = Enum.AutomaticSize.None
			cur.Position = UDim2.fromOffset(5, 0); cur.Size = UDim2.new(1, -20, 1, 0)
			cur.TextTruncate = Enum.TextTruncate.AtEnd; cur.Parent = dd
			local arrow = Label("▼", 8, T2.TextDisabled)
			arrow.AnchorPoint = Vector2.new(1, 0.5); arrow.Position = UDim2.new(1, -5, 0.5, 0); arrow.Parent = dd
			dd.MouseEnter:Connect(function() for _, s in ipairs(dd:GetChildren()) do if s:IsA("UIStroke") then s.Color = T2.StrokeHover end end end)
			dd.MouseLeave:Connect(function() for _, s in ipairs(dd:GetChildren()) do if s:IsA("UIStroke") then s.Color = T2.Stroke end end end)

			local D: any = { Index = default, Items = items }
			local pop: Frame? = nil
			function D:Set(i: number)
				D.Index = math.clamp(i, 1, #D.Items)
				cur.Text = D.Items[D.Index]
				if flag then Chuddy.Flags[flag] = D.Index end
				if cb then task.spawn(cb, D.Items[D.Index], D.Index) end
			end
			function D:Get() return D.Items[D.Index], D.Index end
			dd.MouseButton1Click:Connect(function()
				if pop and pop.Parent then pop:Destroy() pop = nil return end
				pop = New("Frame", { BackgroundColor3 = T2.ListEven, BorderSizePixel = 0,
					Size = UDim2.new(0, dd.AbsoluteSize.X, 0, #items * 13 + 4) }) :: Frame
				pop.Parent = screen; pop.ZIndex = 100

				local p = dd.AbsolutePosition
				local sp = screen.AbsolutePosition
				pop.Position = UDim2.fromOffset(p.X - sp.X, p.Y - sp.Y + 16)
				Stroke(pop, T2.Stroke, 1); Pad(pop, 0, 2, 0, 2)
				New("UIListLayout", { Parent = pop, Padding = UDim.new(0, 0) })
				for i, name in ipairs(items) do
					local it = New("TextButton", { Parent = pop, Text = "", AutoButtonColor = false,
						BackgroundColor3 = T2.ListEven, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 13) }) :: TextButton
					local il = Label(name, 11, if i == D.Index then T2.Accent else T2.Text)
					il.AutomaticSize = Enum.AutomaticSize.None
					il.Position = UDim2.fromOffset(5, 0); il.Size = UDim2.new(1, -10, 1, 0)
					il.TextTruncate = Enum.TextTruncate.AtEnd; il.Parent = it
					it.MouseEnter:Connect(function() il.TextColor3 = T2.Accent end)
					if i ~= D.Index then it.MouseLeave:Connect(function() il.TextColor3 = T2.Text end) end
					it.MouseButton1Click:Connect(function()
						D:Set(i); if pop then pop:Destroy() pop = nil end
					end)
				end
			end)
			if flag then Chuddy:RegisterFlag(flag, default, function(v) if typeof(v)=="number" then D:Set(v) end end) end
			local droot = indentWrap(droots)
			self._window:_registerSearchable(droot, shown .. " " .. table.concat(items, " "))
			return D
		end
		Group.AddCombo = Group.AddDropdown

		function Group:AddKeybind(opts2: any): any
			opts2 = opts2 or {}
			local text = opts2.Text or "Keybind"
			local dKey: Enum.KeyCode? = opts2.Default
			local dMode: number = opts2.Mode or 0
			local cb = opts2.Callback
			local kflag, mflag = opts2.Flag, opts2.ModeFlag
			if kflag and Chuddy.Flags[kflag] ~= nil then dKey = Chuddy.Flags[kflag] end
			if mflag and typeof(Chuddy.Flags[mflag]) == "number" then dMode = Chuddy.Flags[mflag] end
			if kflag then Chuddy:FlagType(kflag, "key") end
			if mflag then Chuddy:FlagType(mflag, "int") end

			local row = New("Frame", { Parent = box, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14) }) :: Frame
			local lab = Label(text, 11, T2.Text)
			lab.AutomaticSize = Enum.AutomaticSize.None
			lab.Position = UDim2.fromOffset(0, 0); lab.Size = UDim2.new(1, -44, 1, 0)
			lab.TextTruncate = Enum.TextTruncate.AtEnd; lab.Parent = row
			local pill = New("TextButton", { Parent = row, Text = "", AutoButtonColor = false,
				BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0, ZIndex = 3,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(34, 13) }) :: TextButton
			Stroke(pill, T2.Stroke, 1)
			local pl = Label("-", 8, T2.TextStrong) pl.AnchorPoint = Vector2.new(0.5, 0.5)
			pl.AutomaticSize = Enum.AutomaticSize.None; pl.Size = UDim2.fromScale(1, 1)
			pl.TextXAlignment = Enum.TextXAlignment.Center; pl.TextTruncate = Enum.TextTruncate.AtEnd
			pl.Position = UDim2.fromScale(0.5, 0.5); pl.Parent = pill
			local K: any = { Key = dKey, Mode = dMode, State = false, Capturing = false }
			local function paint()
				if K.Capturing then pl.Text = "..."
				elseif K.Mode == 2 then pl.Text = "ON"; pl.TextColor3 = T2.ToggleOn
				else pl.Text = KeyLabel(K.Key); pl.TextColor3 = T2.TextStrong end
			end
			paint()
			local function fire()
				if cb then task.spawn(cb, K.State) end
			end
			pill.MouseButton1Click:Connect(function()
				K.Capturing = true; paint()
			end)
			pill.MouseButton2Click:Connect(function()
				K.Mode = (K.Mode + 1) % 3; paint()
				if mflag then Chuddy.Flags[mflag] = K.Mode end
			end)
			UserInputService.InputBegan:Connect(function(input, gpe)
				if K.Capturing then
					if input.KeyCode == Enum.KeyCode.Escape then K.Key = nil
					elseif input.KeyCode ~= Enum.KeyCode.Unknown then K.Key = input.KeyCode end
					K.Capturing = false; paint()
					if kflag then Chuddy.Flags[kflag] = K.Key end
					return
				end
				if gpe or K.Key == nil then return end
				if input.KeyCode == K.Key then
					if K.Mode == 0 then K.State = not K.State; fire()
					elseif K.Mode == 1 then K.State = true; fire() end
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if not K.Capturing and K.Key ~= nil and input.KeyCode == K.Key and K.Mode == 1 then
					K.State = false; fire()
				end
			end)
			task.spawn(function()
				while pill.Parent do
					if K.Mode == 2 and not K.State then K.State = true; fire() end
					task.wait(0.25)
				end
			end)
			local root = indentWrap({row})
			self._window:_registerSearchable(root, text)
			return K
		end

		function Group:AddListbox(opts2: any): any
			local items: any = opts2.Items or { "Player1", "Player2" }
			local h: number = opts2.Height or 90
			local cb = opts2.Callback
			local onCheck = opts2.OnCheck
			local multi = opts2.Multi or false
			local checks = opts2.Checks or false
			local list = New("ScrollingFrame", { Parent = box, BackgroundColor3 = T2.ListEven,
				BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, h),
				ScrollBarThickness = 2, ScrollBarImageColor3 = T2.Stroke,
				CanvasSize = UDim2.fromScale(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }) :: ScrollingFrame
			Stroke(list, T2.Stroke, 1)
			New("UIListLayout", { Parent = list, Padding = UDim.new(0, 0) })
			local L: any = { Selected = {} :: any, Checked = {} :: any, _rows = {} :: any }
			if opts2.Checked then
				for k, v in pairs(opts2.Checked) do L.Checked[k] = v end
			end
			local function paintRow(i: number)
				local r = L._rows[i]
				if not r then return end
				local sel = L.Selected[i] ~= nil
				r.Label.TextColor3 = sel and T2.Accent or T2.Text
				if r.Tick then
					r.Tick.Visible = L.Checked[i] == true
				end
			end
			local function buildRow(i: number, name: any)
				local rowB = New("TextButton", { Parent = list, Text = "", AutoButtonColor = false,
					BackgroundColor3 = if i % 2 == 1 then T2.ListEven else T2.ListOdd,
					BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 13), LayoutOrder = i }) :: TextButton
				local row: any = { Btn = rowB, Name = name }
				local labelX = 4
				if checks then
					local cbox = New("Frame", { Parent = rowB, BackgroundColor3 = T2.CheckboxBg,
						BorderSizePixel = 0, Position = UDim2.fromOffset(4, 2), Size = UDim2.fromOffset(10, 10) }) :: Frame
					local tick = New("Frame", { Parent = cbox, BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1), Visible = L.Checked[i] == true }) :: Frame
					trackAccent(DrawLine(tick, 2.2, 5.0, 4.4, 7.2, 2, T2.Accent), "bg")
					trackAccent(DrawLine(tick, 4.4, 7.2, 8.0, 2.4, 2, T2.Accent), "bg")
					trackAccent(New("Frame", { Parent = tick, BackgroundColor3 = T2.Accent, BorderSizePixel = 0,
						AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(4.4, 7.2),
						Size = UDim2.fromOffset(2.5, 2.5) }), "bg")
					row.Tick = tick
					labelX = 19
				end
				local rl = Label(tostring(name), 11, T2.Text)
				rl.AutomaticSize = Enum.AutomaticSize.None
				rl.Position = UDim2.fromOffset(labelX, 0); rl.Size = UDim2.new(1, -labelX - 4, 1, 0)
				rl.TextTruncate = Enum.TextTruncate.AtEnd; rl.Parent = rowB
				row.Label = rl
				L._rows[i] = row
				rowB.InputBegan:Connect(function(inp)
					if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					if checks and (inp.Position.X - rowB.AbsolutePosition.X) <= 17 then
						L.Checked[i] = not L.Checked[i]
						paintRow(i)
						if onCheck then task.spawn(onCheck, name, L.Checked[i]) end
						return
					end
					if multi then
						if L.Selected[i] then L.Selected[i] = nil else L.Selected[i] = name end
					else
						table.clear(L.Selected); L.Selected[i] = name
					end
					for j in ipairs(items) do paintRow(j) end
					if cb then task.spawn(cb, L:Get()) end
				end)
			end
			for i, name in ipairs(items) do buildRow(i, name) end
			if opts2.Default ~= nil then
				for i, name in ipairs(items) do
					if name == opts2.Default then L.Selected[i] = name; paintRow(i); break end
				end
			end
			function L:Get(): any
				if multi then
					local out: any = {}
					for _, v in pairs(L.Selected) do table.insert(out, v) end
					return out
				end
				for _, v in pairs(L.Selected) do return v end
				return nil
			end
			function L:SetItems(newItems: any)
				for _, r in ipairs(L._rows) do (r.Btn :: GuiObject):Destroy() end
				table.clear(L._rows); table.clear(L.Selected)
				items = newItems
				for i, name in ipairs(newItems) do buildRow(i, name) end
			end
			local lroot = indentWrap({list})
			self._window:_registerSearchable(lroot, table.concat(items, " "))
			return L
		end

		function Group:AddTextbox(opts2: any): any
			local text = opts2.Text or ""
			local ph = opts2.Placeholder or text
			local def = opts2.Default or ""
			local cb = opts2.Callback
			local flag = opts2.Flag
			if flag then Chuddy:FlagType(flag, "string") end
			if flag and Chuddy.Flags[flag] ~= nil then def = tostring(Chuddy.Flags[flag]) end
			local troots: {GuiObject} = {}
			if text ~= "" then
				local cap = Label(text, 11, T2.Text) cap.Parent = box
				table.insert(troots, cap)
			end
			local tb = New("TextBox", { Parent = box, BackgroundColor3 = T2.CheckboxBg,
				TextColor3 = T2.Text, PlaceholderText = ph, PlaceholderColor3 = T2.TextDisabled,
				Font = Chuddy.FontBody, TextSize = 11, Text = def, ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16) }) :: TextBox
			Pad(tb, 4, 0, 0, 0); Stroke(tb, T2.Stroke, 1)
			tb.FocusLost:Connect(function()
				if flag then Chuddy.Flags[flag] = tb.Text end
				if cb then task.spawn(cb, tb.Text) end
			end)
			table.insert(troots, tb)
			indentWrap(troots)
			return tb
		end

		return Group
	end

	function Window:SaveConfig(): string
		local lines: any = {}
		for _, k in ipairs(Chuddy._flagOrder) do
			local v = Chuddy.Flags[k]
			local t = Chuddy._flagTypes[k]
			if t == "color" and typeof(v) == "Color3" then
				local a = Chuddy.Flags[k .. "Alpha"]
				if typeof(a) ~= "number" then a = 1 end
				table.insert(lines, string.format("%s=%.4f %.4f %.4f %.4f", k, v.R, v.G, v.B, a))
			elseif t == "float" and typeof(v) == "number" then
				table.insert(lines, string.format("%s=%.4f", k, v))
			elseif t == "int" and typeof(v) == "number" then
				table.insert(lines, string.format("%s=%d", k, math.floor(v + 0.5)))
			elseif t == "bool" then
				table.insert(lines, string.format("%s=%d", k, v and 1 or 0))
			elseif t == "key" then
				table.insert(lines, string.format("%s=%s", k, if typeof(v) == "EnumItem" then (v :: any).Name else "-"))
			elseif typeof(v) == "string" then
				table.insert(lines, string.format("%s=%s", k, v))
			elseif typeof(v) == "number" then
				table.insert(lines, string.format("%s=%d", k, math.floor(v + 0.5)))
			elseif typeof(v) == "boolean" then
				table.insert(lines, string.format("%s=%d", k, v and 1 or 0))
			end
		end
		return table.concat(lines, "\n")
	end
	function Window:LoadConfig(text: string): boolean
		if typeof(text) ~= "string" then return false end
		for line in string.gmatch(text, "[^\r\n]+") do
			local eq = string.find(line, "=", 1, true)
			if eq then
				local k = string.sub(line, 1, eq - 1)
				local payload = string.sub(line, eq + 1)
				local t = Chuddy._flagTypes[k]
				if t == "bool" then
					Chuddy.Flags[k] = tonumber(payload) ~= 0
				elseif t == "int" then
					Chuddy.Flags[k] = math.floor(tonumber(payload) or 0)
				elseif t == "float" then
					Chuddy.Flags[k] = tonumber(payload) or 0
				elseif t == "color" then
					local r, g, b, a = string.match(payload, "([%d%.%-]+)%s+([%d%.%-]+)%s+([%d%.%-]+)%s*([%d%.%-]*)")
					if r and g and b then
						Chuddy.Flags[k] = Color3.new(tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0)
						local aa = tonumber(a)
						if aa ~= nil then
							Chuddy.Flags[k .. "Alpha"] = math.clamp(aa, 0, 1)
							local aset = Chuddy._flagSetters[k .. "Alpha"]
							if aset then pcall(aset, Chuddy.Flags[k .. "Alpha"]) end
						end
					end
				elseif t == "key" then
					local okkc, kc = pcall(function() return (Enum.KeyCode :: any)[payload] end)
					Chuddy.Flags[k] = if okkc then kc else nil
				elseif t == "string" then
					Chuddy.Flags[k] = payload
				else
					local num = tonumber(payload)
					if num ~= nil then Chuddy.Flags[k] = num end
				end
				local setter = Chuddy._flagSetters[k]
				if setter then pcall(setter, Chuddy.Flags[k]) end
			end
		end
		return true
	end
	function Window:Unload()
		screen:Destroy()
	end

	table.insert(Chuddy._windows, Window)
	return Window
end

return Chuddy
