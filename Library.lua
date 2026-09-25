--[[--------------------------------------------------------------------
    chudvision.net  ->  Roblox Lua port ("ChuddyLib")
    Original: ImGui-Chudvision-Framework (C++ / Dear ImGui) by KingsleydotDev
    Port: pure Luau, no dependencies. Drawing + behavior cloned from:
      style/style.hpp, gui/gui.cpp, framework/{checkbox,slider,combo,
      button,groupbox,tab,bind,colorswatch,list,badge,search,layout}.cpp

    Usage:
      local Chuddy = loadstring(game:HttpGet(".../Library.lua"))()
      -- or: local Chuddy = require(path.Library)
--------------------------------------------------------------------]]
--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Chuddy = {}
Chuddy.__index = Chuddy
Chuddy.Flags = {} :: any
Chuddy._accentRegistry = {} :: any -- { [instance] = "bg" | "text" | "stroke" }
Chuddy._flagDefaults = {} :: any

--// Theme (1:1 from style.hpp) --------------------------------------------
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

Chuddy.FontBody = Enum.Font.Code
Chuddy.FontBold = Enum.Font.Code

--// small helpers ----------------------------------------------------------
local function New(className: string, props: any?, children: any?): Instance
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				local ok = pcall(function()
					(inst :: any)[k] = v
				end)
				if not ok then warn("[Chuddy] bad prop " .. tostring(k)) end
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
		if e.Kind == "bg" then (e.Inst :: GuiObject).BackgroundColor3 = c
		elseif e.Kind == "text" then (e.Inst :: TextLabel).TextColor3 = c end
	end
end

function Chuddy:RegisterFlag(flag: string, default: any, setter: (any)->())
	if flag == nil or flag == "" then return end
	if Chuddy.Flags[flag] == nil then
		Chuddy.Flags[flag] = default
		Chuddy._flagDefaults[flag] = default
	end
end

-- key name helper (mirrors bind.cpp KeyLabel) ------------------------------
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
	-- compact: "MouseButton1" checks are UserInputType, handled by caller
	return n
end

--// Window -----------------------------------------------------------------
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
	local toggleKey = opts.ToggleKey or Enum.KeyCode.Insert
	local searchEnabled = opts.SearchEnabled
	if searchEnabled == nil then searchEnabled = true end

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

	local TITLE_H, TAB_H = 18, 20

	-- header ----------------------------------------------------------------
	local header = New("Frame", {
		Parent = main, BackgroundColor3 = T.HeaderBg, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, TITLE_H + TAB_H),
	}) :: Frame

	local titleRow = New("Frame", {
		Parent = header, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, TITLE_H),
	}) :: Frame

	local t1 = Label(title1, 13, T.TitleText) t1.Font = Chuddy.FontBold
	t1.Position = UDim2.fromOffset(6, 1) t1.Parent = titleRow
	-- measure to chain vision + .net
	local w1 = TextService:GetTextSize(title1, 13, Chuddy.FontBold, Vector2.new(500, 20)).X
	local t2 = Label(title2, 13, T.Accent) t2.Font = Chuddy.FontBold
	t2.Position = UDim2.fromOffset(6 + w1, 1) t2.Parent = titleRow
	trackAccent(t2, "text")
	local w2 = TextService:GetTextSize(title2, 13, Chuddy.FontBold, Vector2.new(500, 20)).X
	local t3 = Label(title3, 13, T.TitleText) t3.Font = Chuddy.FontBold
	t3.Position = UDim2.fromOffset(6 + w1 + w2, 1) t3.Parent = titleRow

	local searchBox: TextBox? = nil
	if searchEnabled then
		searchBox = New("TextBox", {
			Parent = titleRow,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 2),
			Size = UDim2.fromOffset(110, 14),
			BackgroundColor3 = T.CheckboxBg,
			TextColor3 = T.Text,
			PlaceholderText = "search",
			PlaceholderColor3 = T.TextDisabled,
			Font = Chuddy.FontBody, TextSize = 11,
			Text = "", ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
		}) :: TextBox
		Pad(searchBox, 4, 0, 0, 0)
		Stroke(searchBox, T.Stroke, 1)
	end

	-- tab row + underline ----------------------------------------------------
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

	local underline = New("Frame", {
		Parent = main, BackgroundColor3 = T.Stroke, BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, TITLE_H + TAB_H),
		Size = UDim2.new(1, -12, 0, 1), ZIndex = 5,
	}) :: Frame

	-- content well ------------------------------------------------------------
	local content = New("Frame", {
		Parent = main, BackgroundColor3 = T.PanelBg, BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, TITLE_H + TAB_H + 1),
		Size = UDim2.new(1, -12, 1, -(TITLE_H + TAB_H + 7)),
	}) :: Frame
	Stroke(content, T.TabBorder, 1)

	-- resize grip (bottom-right triangle approx with a small frame) ----------
	local grip = New("TextButton", {
		Parent = main, Text = "", AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, ZIndex = 10,
	}) :: TextButton
	local gripMark = New("Frame", {
		Parent = main, BackgroundColor3 = T.Stroke, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(6, 6), ZIndex = 9,
	}) :: Frame
	New("UIGradient", { Parent = gripMark, Rotation = 45, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.51, 1), NumberSequenceKeypoint.new(1, 1),
	}) })

	-- drag (header) -----------------------------------------------------------
	do
		local dragging = false
		local dragStart, startPos: Vector2, UDim2
		titleRow.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = i.Position
				startPos = main.Position
				i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - dragStart
				main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		-- resize
		local resizing = false
		local rStart: Vector2, sStart: Vector2
		grip.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = true
				rStart = i.Position; sStart = main.AbsoluteSize
				i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then resizing = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - rStart
				main.Size = UDim2.fromOffset(math.max(400, sStart.X + d.X), math.max(320, sStart.Y + d.Y))
			end
		end)
	end

	local Window: any = {}
	Window.Gui = screen
	Window.Main = main
	Window.Tabs = {}
	Window._searchables = {} -- {Frame, Keys:string}
	Window._current = nil

	function Window:ToggleVisible()
		screen.Enabled = not screen.Enabled
	end
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then
			screen.Enabled = not screen.Enabled
		end
	end)

	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local q = string.lower(searchBox.Text)
			for _, s in ipairs(Window._searchables) do
				if q == "" then (s.Frame :: GuiObject).Visible = true
				else
					(s.Frame :: GuiObject).Visible = string.find(string.lower(s.Keys), q, 1, true) ~= nil
				end
			end
		end)
	end

	function Window:_registerSearchable(frame: GuiObject, keys: string)
		table.insert(self._searchables, { Frame = frame, Keys = keys })
	end

	-- Tabs ------------------------------------------------------------------
	function Window:AddTab(name: string): any
		local order = #self.Tabs + 1
		local isActive = order == 1

		-- tab button (mirrors tab.cpp TopTab)
		local btn = New("TextButton", {
			Parent = tabRow, Text = "", AutoButtonColor = false,
			BackgroundColor3 = T.WindowBg, BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = order,
		}) :: TextButton
		Pad(btn, 7, 0, 7, 0)
		local lbl = Label(name, 11, T.TextStrong)
		lbl.Parent = btn
		trackAccent(lbl, "text") -- recolored when active below; guard via tag
		-- active cap: 3 stacked 1px bars above button
		local capDark = New("Frame", { Parent = btn, BackgroundColor3 = T.AccentBarDark, BorderSizePixel = 0,
			Position = UDim2.fromOffset(3, -3), Size = UDim2.new(1, -6, 0, 1), Visible = isActive }) :: Frame
		local capMid = New("Frame", { Parent = btn, BackgroundColor3 = T.AccentBar, BorderSizePixel = 0,
			Position = UDim2.fromOffset(2, -2), Size = UDim2.new(1, -4, 0, 1), Visible = isActive }) :: Frame
		local capTop = New("Frame", { Parent = btn, BackgroundColor3 = T.AccentBarBright, BorderSizePixel = 0,
			Position = UDim2.fromOffset(1, -1), Size = UDim2.new(1, -2, 0, 1), Visible = isActive }) :: Frame

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
			if idx == 1 and ratio and ratio > 0 then
				col.Size = UDim2.new(ratio, -3, 0, 0)
				col.AutomaticSize = Enum.AutomaticSize.Y
			else
				col.Size = UDim2.new(0.5, -3, 0, 0)
				col.AutomaticSize = Enum.AutomaticSize.Y
				col.FlexMode = Enum.FlexMode.Grow
			end
			New("UIListLayout", { Parent = col, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
			table.insert(self._columns, col)

			local Col: any = {}
			Col.Frame = col
			function Col:AddGroupbox(title: string, heightRatio: number?): any
				return Tab._window:_addGroupbox(col, title)
			end
			-- sugar: column:AddCheckbox(...) creates an implicit group-less stack?
			return Col
		end

		-- convenience: two-column default like the C++ pages
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

		local function refreshTabs()
			for i, tb in ipairs(self.Tabs) do
				local active = tb.Tab == Tab
				tb.Page.Visible = active
				tb.Cap[1].Visible = active; tb.Cap[2].Visible = active; tb.Cap[3].Visible = active
				tb.Label.TextColor3 = active and T.AccentBarBright or T.TextStrong
				-- untrack trick: keep accent only for active label
				if active then tb.Label.TextColor3 = T.Accent else tb.Label.TextColor3 = T.TextStrong end
			end
		end
		btn.MouseButton1Click:Connect(refreshTabs)
		-- keep label refs (strip generic accent tracking for tab labels)
		for i = #Chuddy._accentRegistry, 1, -1 do
			if Chuddy._accentRegistry[i].Inst == lbl then table.remove(Chuddy._accentRegistry, i) end
		end

		table.insert(self.Tabs, { Tab = Tab, Page = page, Label = lbl, Cap = {capDark, capMid, capTop} })
		if isActive then refreshTabs() end
		return Tab
	end

	--// Groupbox (mirrors groupbox.cpp) -------------------------------------
	function Window:_addGroupbox(column: Frame, title: string): any
		local T2 = self.Theme
		local holder = New("Frame", {
			Parent = column, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		}) :: Frame

		local caption = Label(title, 11, T2.TextStrong) caption.Font = Chuddy.FontBold
		caption.Parent = holder

		local box = New("Frame", {
			Parent = holder, BackgroundColor3 = T2.PanelBg, BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 6),
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		}) :: Frame
		Stroke(box, T2.Stroke, 1)
		-- inner 1px dark bevel on bottom/right like C++ AddRect second pass
		local inner = New("Frame", {
			Parent = box, BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}) :: Frame
		Stroke(inner, T2.BevelDark, 1)
		Pad(box, 9, 8, 9, 6)
		New("UIListLayout", { Parent = box, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })

		-- caption chip overlapping border (windowBg behind text)
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

		-- layout helpers ----------------------------------------------------
		function Group:AddLabel(text: string)
			local l = Label(text, 11, T2.Text)
			l.Parent = box
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
			local b = New("TextButton", {
				Parent = box, Text = "", AutoButtonColor = false,
				BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 20),
			}) :: TextButton
			Stroke(b, T2.Stroke, 1)
			local bl = Label(text, 11, T2.Text)
			bl.AnchorPoint = Vector2.new(0.5, 0.5); bl.Position = UDim2.fromScale(0.5, 0.5)
			bl.Parent = b
			b.MouseEnter:Connect(function() (Stroke(b, T2.StrokeHover, 1)) bl.TextColor3 = T2.TextStrong end)
			b.MouseLeave:Connect(function() for _, s in ipairs(b:GetChildren()) do if s:IsA("UIStroke") then s:Destroy() end end Stroke(b, T2.Stroke, 1) bl.TextColor3 = T2.Text end)
			b.MouseButton1Click:Connect(function() if cb then task.spawn(cb) end end)
			self._window:_registerSearchable(b, text)
			return b
		end

		-- Checkbox + right-side attachments (bind / color / badge) ----------
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
			-- bevel: top/left dark, bottom/right light
			New("Frame", { Parent = cbox, BackgroundColor3 = T2.BevelDark, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1) })
			New("Frame", { Parent = cbox, BackgroundColor3 = T2.BevelDark, BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, 0) })
			New("Frame", { Parent = cbox, BackgroundColor3 = T2.BevelLight, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1) })
			New("Frame", { Parent = cbox, BackgroundColor3 = T2.BevelLight, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0) })
			local check = Label("✓", 11, T2.Accent) check.Font = Chuddy.FontBold
			check.Position = UDim2.fromOffset(0, -2); check.Visible = default; check.Parent = cbox
			trackAccent(check, "text")
			local lab = Label(text, 11, default and T2.TextStrong or T2.Text)
			lab.Position = UDim2.fromOffset(15, 0); lab.Size = UDim2.new(1, -40, 1, 0)
			lab.TextTruncate = Enum.TextTruncate.AtEnd; lab.Parent = row

			local Ctrl: any = {}
			Ctrl.Row = row; Ctrl.Value = default
			if flag then Chuddy:RegisterFlag(flag, default, function(v) Ctrl:Set(v) end) end
			function Ctrl:Set(v: boolean)
				Ctrl.Value = v
				check.Visible = v
				lab.TextColor3 = v and T2.TextStrong or T2.Text
				if flag then Chuddy.Flags[flag] = v end
				if cb then task.spawn(cb, v) end
			end
			function Ctrl:Get() return Ctrl.Value end
			hit.MouseButton1Click:Connect(function() Ctrl:Set(not Ctrl.Value) end)

			-- inline right slot (PlaceRight equivalent)
			local rightX = 0
			local function reserve(w: number): UDim2
				rightX += w + 3
				return UDim2.new(1, -rightX, 0.5, 0)
			end
			function Ctrl:AddKeybind(kb: any): any
				kb = kb or {}
				local dKey: Enum.KeyCode? = kb.Default
				local dMode: number = kb.Mode or 1 -- 1 hold, 2 toggle, 3 always
				local kcb = kb.Callback
				local kflag, mflag = kb.Flag, kb.ModeFlag
				if kflag and Chuddy.Flags[kflag] ~= nil then dKey = Chuddy.Flags[kflag] end
				local pill = New("TextButton", { Parent = row, Text = "", AutoButtonColor = false,
					BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(34, 13) }) :: TextButton
				pill.Position = reserve(34)
				Stroke(pill, T2.Stroke, 1)
				local pl = Label("-", 8, T2.TextStrong) pl.AnchorPoint = Vector2.new(0.5, 0.5)
				pl.Position = UDim2.fromScale(0.5, 0.5); pl.Parent = pill
				local K: any = { Key = dKey, Mode = dMode, Capturing = false }
				local function paint()
					if K.Capturing then pl.Text = "..."
					elseif K.Mode == 3 then pl.Text = "ON"; pl.TextColor3 = T2.ToggleOn
					else pl.Text = KeyLabel(K.Key); pl.TextColor3 = T2.TextStrong end
				end
				paint()
				pill.MouseButton1Click:Connect(function()
					K.Capturing = true; paint()
				end)
				pill.MouseButton2Click:Connect(function()
					K.Mode = (K.Mode % 3) + 1; paint()
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
						if K.Mode == 2 then Ctrl:Set(not Ctrl.Value)
						elseif K.Mode == 1 then Ctrl:Set(true) end
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if not K.Capturing and K.Key ~= nil and input.KeyCode == K.Key and K.Mode == 1 then
						Ctrl:Set(false)
					end
				end)
				-- always-on behaves like enabled
				task.spawn(function()
					while pill.Parent do
						if K.Mode == 3 and not Ctrl.Value then Ctrl:Set(true) end
						task.wait(0.25)
					end
				end)
				return K
			end
			function Ctrl:AddColorPicker(cp: any): any
				cp = cp or {}
				local def: Color3 = cp.Default or Color3.fromRGB(220, 220, 220)
				local ccb = cp.Callback
				local cflag = cp.Flag
				if cflag and Chuddy.Flags[cflag] ~= nil then
					local v = Chuddy.Flags[cflag]
					if typeof(v) == "Color3" then def = v end
				end
				local sw = New("TextButton", { Parent = row, Text = "", AutoButtonColor = false,
					BackgroundColor3 = def, BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(28, 10) }) :: TextButton
				sw.Position = reserve(28)
				Stroke(sw, T2.Stroke, 1)
				local C: any = { Value = def }
				function C:Set(c: Color3)
					C.Value = c; sw.BackgroundColor3 = c
					if cflag then Chuddy.Flags[cflag] = c end
					if ccb then task.spawn(ccb, c) end
				end
				-- popup with 3 RGB sliders
				local pop: Frame? = nil
				sw.MouseButton1Click:Connect(function()
					if pop and pop.Parent then pop:Destroy() pop = nil return end
					pop = New("Frame", { BackgroundColor3 = T2.CheckboxBg, BorderSizePixel = 0,
						Position = UDim2.new(0, 0, 0, 14), Size = UDim2.fromOffset(150, 86) }) :: Frame
					pop.Parent = row; pop.ZIndex = 50
					Stroke(pop, T2.Stroke, 1); Pad(pop, 6, 6, 6, 6)
					New("UIListLayout", { Parent = pop, Padding = UDim.new(0, 4) })
					local comps = {"R","G","B"}
					for i, comp in ipairs(comps) do
						local sl = New("Frame", { Parent = pop, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22) }) :: Frame
						local ll = Label(comp, 10, T2.Text) ll.Parent = sl
						local track = New("TextButton", { Parent = sl, Text = "", AutoButtonColor = false,
							BackgroundColor3 = T2.SliderTrack, BorderSizePixel = 0,
							Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 8) }) :: TextButton
						local fill = New("Frame", { Parent = track, BackgroundColor3 = T2.Accent, BorderSizePixel = 0,
							Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0, 1, 0.5, -1) }) :: Frame
						trackAccent(fill, "bg")
						local knob = New("Frame", { Parent = track, BackgroundColor3 = T2.SliderKnob, BorderSizePixel = 0,
							Size = UDim2.fromOffset(5, 12), Position = UDim2.new(0, 0, 0.5, -6) }) :: Frame
						local function paint2()
							local ch = string.format("%02X", math.floor(C.Value[comp] * 255 + 0.5))
							ll.Text = comp .. " " .. ch
							local f = C.Value[comp]
							fill.Size = UDim2.new(f, -2, 0, 2)
							knob.Position = UDim2.new(f, -2, 0.5, -6)
						end
						paint2()
						track.InputBegan:Connect(function(inp)
							if inp.UserInputType == Enum.UserInputType.MouseButton1 then
								local function upd(p: Vector2)
									local rel = math.clamp((p.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
									local r, g, b = C.Value.R, C.Value.G, C.Value.B
									if comp == "R" then r = rel elseif comp == "G" then g = rel else b = rel end
									C:Set(Color3.new(r, g, b)); paint2()
								end
								upd(inp.Position)
								local mv; mv = UserInputService.InputChanged:Connect(function(m)
									if m.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then upd(m.Position) end
								end)
								UserInputService.InputEnded:Wait(); if mv then mv:Disconnect() end
							end
						end)
					end
				end)
				return C
			end
			function Ctrl:AddBadge(defaultOn: boolean?): any
				local b = New("Frame", { Parent = row, BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(28, 12) }) :: Frame
				b.Position = reserve(28)
				Stroke(b, T2.Stroke, 1)
				local bl = Label(defaultOn and "ON" or "OFF", 8, defaultOn and T2.ToggleOn or T2.TextDisabled)
				bl.AnchorPoint = Vector2.new(0.5, 0.5); bl.Position = UDim2.fromScale(0.5, 0.5); bl.Parent = b
				local B: any = {}
				function B:Set(on: boolean)
					bl.Text = on and "ON" or "OFF"
					bl.TextColor3 = on and T2.ToggleOn or T2.TextDisabled
				end
				-- follow checkbox state
				local oldSet = Ctrl.Set
				function Ctrl:Set(v: boolean)
					oldSet(v); B:Set(v)
				end
				return B
			end

			self._window:_registerSearchable(row, text)
			return Ctrl
		end

		-- Slider (mirrors slider.cpp SliderRow) --------------------------------
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
			local unlimitedAtMax = opts2.UnlimitedAtMax -- for SliderDistance style

			local wrap = New("Frame", { Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26) }) :: Frame
			local nameL = Label(text, 11, T2.TextStrong) nameL.Position = UDim2.fromOffset(0, 0) nameL.Parent = wrap
			local valL = Label("", 11, T2.TextStrong) valL.AnchorPoint = Vector2.new(1, 0)
			valL.Position = UDim2.new(1, 0, 0, 0) valL.Parent = wrap
			local track = New("TextButton", { Parent = wrap, Text = "", AutoButtonColor = false,
				BackgroundColor3 = T2.SliderTrack, BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 8) }) :: TextButton
			-- bevel on track
			New("Frame", { Parent = track, BackgroundColor3 = T2.BevelDark, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1) })
			New("Frame", { Parent = track, BackgroundColor3 = T2.BevelLight, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1) })
			local fill = New("Frame", { Parent = track, BackgroundColor3 = T2.Accent, BorderSizePixel = 0,
				Position = UDim2.new(0, 1, 0.5, -1), Size = UDim2.new(0, 0, 0, 2) }) :: Frame
			trackAccent(fill, "bg")
			local knob = New("Frame", { Parent = track, BackgroundColor3 = T2.SliderKnob, BorderSizePixel = 0,
				Size = UDim2.fromOffset(5, 12), Position = UDim2.new(0, 0, 0.5, -6) }) :: Frame

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
			self._window:_registerSearchable(wrap, text)
			return S
		end

		-- Dropdown / Combo (mirrors combo.cpp) ---------------------------------
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
			if flag and Chuddy.Flags[flag] ~= nil then
				local fv = Chuddy.Flags[flag]
				if typeof(fv) == "number" then default = math.clamp(fv, 1, #items)
				elseif typeof(fv) == "string" then for i, v in ipairs(items) do if v == fv then default = i break end end end
			end
			local y = 0
			if text ~= "" then
				local cap = Label(text, 11, T2.Text) cap.Position = UDim2.fromOffset(0, 0) cap.Parent = box
				-- note: box list layout auto-stacks; keep caption as its own row:
				y = 0
			end
			local dd = New("TextButton", { Parent = box, Text = "", AutoButtonColor = false,
				BackgroundColor3 = T2.ControlBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 15) }) :: TextButton
			Stroke(dd, T2.Stroke, 1)
			local cur = Label(items[default] or "", 11, T2.TextStrong)
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
				-- position under dropdown in screen space
				local p = dd.AbsolutePosition
				local sp = screen.AbsolutePosition
				pop.Position = UDim2.fromOffset(p.X - sp.X, p.Y - sp.Y + 16)
				Stroke(pop, T2.Stroke, 1); Pad(pop, 0, 2, 0, 2)
				New("UIListLayout", { Parent = pop, Padding = UDim.new(0, 0) })
				for i, name in ipairs(items) do
					local it = New("TextButton", { Parent = pop, Text = "", AutoButtonColor = false,
						BackgroundColor3 = T2.ListEven, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 13) }) :: TextButton
					local il = Label(name, 11, if i == D.Index then T2.Accent else T2.Text)
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
			self._window:_registerSearchable(dd, text .. " " .. table.concat(items, " "))
			return D
		end
		Group.AddCombo = Group.AddDropdown

		-- Listbox (mirrors list.cpp) -------------------------------------------
		function Group:AddListbox(opts2: any): any
			local items: any = opts2.Items or { "Player1", "Player2" }
			local h: number = opts2.Height or 90
			local cb = opts2.Callback
			local multi = opts2.Multi or false
			local list = New("ScrollingFrame", { Parent = box, BackgroundColor3 = T2.ListEven,
				BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, h),
				ScrollBarThickness = 2, ScrollBarImageColor3 = T2.Stroke,
				CanvasSize = UDim2.fromScale(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }) :: ScrollingFrame
			Stroke(list, T2.Stroke, 1)
			New("UIListLayout", { Parent = list, Padding = UDim.new(0, 0) })
			local L: any = { Selected = {} :: any, _rows = {} :: any }
			local function paintRow(i: number)
				local r = L._rows[i]
				if not r then return end
				local sel = L.Selected[i] ~= nil
				r.Label.TextColor3 = sel and T2.Accent or T2.Text
			end
			for i, name in ipairs(items) do
				local rowB = New("TextButton", { Parent = list, Text = "", AutoButtonColor = false,
					BackgroundColor3 = if i % 2 == 1 then T2.ListEven else T2.ListOdd,
					BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 13), LayoutOrder = i }) :: TextButton
				local rl = Label(tostring(name), 11, T2.Text)
				rl.Position = UDim2.fromOffset(4, 0); rl.Size = UDim2.new(1, -8, 1, 0)
				rl.TextTruncate = Enum.TextTruncate.AtEnd; rl.Parent = rowB
				L._rows[i] = { Btn = rowB, Label = rl, Name = name }
				rowB.MouseButton1Click:Connect(function()
					if multi then
						if L.Selected[i] then L.Selected[i] = nil else L.Selected[i] = name end
					else
						table.clear(L.Selected); L.Selected[i] = name
					end
					for j in ipairs(items) do paintRow(j) end
					if cb then task.spawn(cb, L:Get()) end
				end)
			end
			-- filler rows like C++ EndList zebra fill: handled by background; fine.
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
				for i, name in ipairs(newItems) do
					local rowB = New("TextButton", { Parent = list, Text = "", AutoButtonColor = false,
						BackgroundColor3 = if i % 2 == 1 then T2.ListEven else T2.ListOdd,
						BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 13), LayoutOrder = i }) :: TextButton
					local rl = Label(tostring(name), 11, T2.Text)
					rl.Position = UDim2.fromOffset(4, 0); rl.Size = UDim2.new(1, -8, 1, 0); rl.Parent = rowB
					L._rows[i] = { Btn = rowB, Label = rl, Name = name }
					rowB.MouseButton1Click:Connect(function()
						table.clear(L.Selected); L.Selected[i] = name
						for j in ipairs(newItems) do paintRow(j) end
						if cb then task.spawn(cb, L:Get()) end
					end)
				end
			end
			return L
		end

		-- Text input (search-style field) ---------------------------------------
		function Group:AddTextbox(opts2: any): any
			local text = opts2.Text or ""
			local ph = opts2.Placeholder or text
			local def = opts2.Default or ""
			local cb = opts2.Callback
			local flag = opts2.Flag
			if flag and Chuddy.Flags[flag] ~= nil then def = tostring(Chuddy.Flags[flag]) end
			if text ~= "" then
				local cap = Label(text, 11, T2.Text) cap.Parent = box
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
			return tb
		end

		return Group
	end

	--// Config helpers (mirrors config/config.hpp VarRegistry) ----------------
	function Window:SaveConfig(): string
		local out: any = {}
		for k, v in pairs(Chuddy.Flags) do
			if typeof(v) == "Color3" then out[k] = { R = v.R, G = v.G, B = v.B }
			elseif typeof(v) == "EnumItem" then out[k] = (v :: any).Name
			else out[k] = v end
		end
		return HttpService:JSONEncode(out)
	end
	function Window:LoadConfig(json: string)
		local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
		if not ok or typeof(data) ~= "table" then return false end
		for k, v in pairs(data) do
			if typeof(v) == "table" and (v :: any).R ~= nil then
				Chuddy.Flags[k] = Color3.new((v :: any).R, (v :: any).G, (v :: any).B)
			else
				Chuddy.Flags[k] = v
			end
		end
		return true
	end
	function Window:Unload()
		screen:Destroy()
	end

	return Window
end

return Chuddy
