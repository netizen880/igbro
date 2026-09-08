--[[
	Universal  --  Universal Player ESP (primo UI)
	=============================================
	Faithful port of swa.lua's player ESP (lines 5285-6434), game-agnostic:
	  - dropped items / corpse / object ESP  (SWA) -> gone
	  - NPC / helicopter / aizones / project_delta -> gone
	  - SWA get_gun/get_team / cheat.*            -> generic

	Kept (full fidelity):
	  2D box from part extents + BLACK box outline, 2-color GRADIENT box /
	  health bar, name, distance(m), health bar+text, wireframe skeleton,
	  chams (BoxHandleAdornment, glow x2), per-flag labels (UIListLayout),
	  BOX ROTATION + GRADIENT SPIN + HOLDER SPIN (with speeds), team check
	  (TeamColor; no Team = enemy), weapon via Tool.

	Driven by the primordial menu flags below.
--]]

-- Rebrand the two lines next to the logo (read by ui.lua as
-- getgenv().script_name / script_version). First line "Primo",
-- second line "Kitty".
getgenv().script_name = "Primo"
getgenv().script_version = "Kitty"

--------------------------------------------------------------------
-- 1. LOAD THE LIBRARY (ui.lua)
--------------------------------------------------------------------
local juju = getgenv().juju
if not juju or not juju.menu then
	local src = ""
	local candidates = { "juju recode/ui.lua", "ui.lua", "juju-main/ui.lua" }
	local ok = pcall(function()
		for _, path in ipairs(candidates) do
			if isfile(path) then
				src = readfile(path)
				if src ~= "" then break end
			end
		end
	end)
	if not ok or src == "" then
		for _ = 1, 4 do
			local fetch_ok, fetched = pcall(function()
				return game:HttpGet("https://raw.githubusercontent.com/panduh16/juju/main/ui.lua")
			end)
			if fetch_ok and fetched and #fetched > 100 then
				src = fetched
				break
			end
			task.wait(0.2)
		end
	end
	-- Fetch the Primordial logo bytes and point the stock logo Data line at
	-- them (network ui.lua reads an asset file; swap that one line only).
	-- Same mechanism ui.lua uses for its own logo -- no size/position/text
	-- changes, no texture tricks.
	pcall(function()
		local img = game:HttpGet("https://raw.githubusercontent.com/netizen880/son/main/Primordial.png", true)
		if img and img ~= "" and #img > 100 then
			getgenv()._PRIMORDIAL_LOGO_ = img
		end
	end)
	local lgo = '["Data"] = readfile(file_path .. "/assets/logo.png"),'
	local ok_l, patched_l = pcall(function()
		local pat = lgo:gsub("([%(%)%.%[%]%*%+%-%?])", "%%%1")
		return src:gsub(pat, '["Data"] = getgenv()._PRIMORDIAL_LOGO_ or "",')
	end)
	if ok_l and patched_l and patched_l ~= src then
		src = patched_l
	end
	-- Make tab text measurement nil-safe: some executor drawing libs don't
	-- populate TextBounds, which crashes create_tab before it can auto-select
	-- the first tab (blank right panel).
	local p2_needle = '["Size"] = udim2_new(0, 70, 0, text["TextBounds"]["Y"]),'
	local p2_pat = p2_needle:gsub("([%(%)%.%[%]%*%+%-%?])", "%%%1")
	local ok_p2, patched2 = pcall(function()
		return src:gsub(p2_pat,
			'["Size"] = udim2_new(0, 70, 0, (text["TextBounds"] and text["TextBounds"]["Y"]) or 7),')
	end)
	if ok_p2 and patched2 and patched2 ~= src then
		src = patched2
	end
-- Primordial theme: replace the stock menu's entire teal/blue shade family
		-- (shadow, accent, success, logo, juju, build, cursor) with Primordial's
		-- light-pink "button_alt" color (rgb(209,180,188)) so no blue shades remain
		-- and the accent reads as pink instead of dark/ashy.
		local teal = 'color3_fromrgb(154, 213, 222)'
		local ok_a, patched_a = pcall(function()
			local pat = teal:gsub("([%(%)%.%[%]%*%+%-%?])", "%%%1")
			return src:gsub(pat, 'color3_fromrgb(209, 180, 188)')
		end)
	if ok_a and patched_a and patched_a ~= src then
		src = patched_a
	end
	-- Logo color -> white (after the teal->pink swap above, force the logo white).
	local ok_lw, patched_lw = pcall(function()
		return src:gsub('["logo"] = color3_fromrgb(209, 180, 188),', '["logo"] = color3_fromrgb(255, 255, 255),', 1)
	end)
	if ok_lw and patched_lw and patched_lw ~= src then
		src = patched_lw
	end
	-- The two remaining "primordial blue" grays (dropdown arrow uses dark_text;
	-- highlighted tints selectable borders) are desaturated blue-gray. Warm
	-- them toward the pink/lavender family so nothing reads as primordial blue.
	local warm = {
		['["dark_text"] = color3_fromrgb(104, 122, 126),'] = '["dark_text"] = color3_fromrgb(150, 138, 152),',
		['["highlighted"] = color3_fromrgb(78, 98, 106),'] = '["highlighted"] = color3_fromrgb(95, 78, 92),',
	}
	for needle, repl in pairs(warm) do
		local ok, patched = pcall(function()
			local esc = needle:gsub("([%(%)%.%[%]%*%+%-%?])", "%%%1")
			return src:gsub(esc, repl)
		end)
		if ok and patched and patched ~= src then src = patched end
	end
	-- The logo Image tints itself with the accent color on init. Force it to
	-- render white. We patch only the "logo" Image block, so no other
	-- accent-tint element is touched and we don't depend on exact whitespace.
	local esc2 = function(s) return s:gsub("([%(%)%.%[%]%*%+%-%?])", "%%%1") end
	local logoDecl = src:find('local logo = drawing_proxy["new"]("Image"', 1, true)
	if logoDecl then
		local from = src:find(esc2('["Color"] = menu["colors"]["accent"],\n\t\t["Data"] = '), logoDecl)
		if from then
			src = src:sub(1, from - 1)
				.. '["Color"] = color3_fromrgb(255, 255, 255),\n\t\t["Data"] = '
				.. src:sub(from + #'["Color"] = menu["colors"]["accent"],\n\t\t["Data"] = ')
		end
	end
	-- Same for the logo shown while dragging the menu (drag_logo) so it is
	-- white too, not the pink accent.
	local dlogoDecl = src:find('local drag_logo = drawing_proxy["new"]("Image"', 1, true)
	if dlogoDecl then
		local from2 = src:find(esc2('["Color"] = menu["colors"]["accent"],\n\t\t["Data"] = '), dlogoDecl)
		if from2 then
			src = src:sub(1, from2 - 1)
				.. '["Color"] = color3_fromrgb(255, 255, 255),\n\t\t["Data"] = '
				.. src:sub(from2 + #'["Color"] = menu["colors"]["accent"],\n\t\t["Data"] = ')
		end
	end
	-- Rename the visible "juju color" picker labels -> "accent color".
	local ok_j, patched_j = pcall(function()
		return src:gsub('["name"] = "juju color"', '["name"] = "accent color"')
	end)
	if ok_j and patched_j and patched_j ~= src then
		src = patched_j
	end
	-- Slider value number display: force it white (it inherits the blue-gray
	-- "dark_text" color on init) instead of showing a blue/teal number.
	local sd = '["Color"] = menu["colors"]["dark_text"],\n\t\t\t\t\t["Text"] = "",'
	local ok_sd, patched_sd = pcall(function()
		return src:gsub(esc2(sd), '["Color"] = color3_fromrgb(255, 255, 255),\n\t\t\t\t\t["Text"] = "",', 1)
	end)
	if ok_sd and patched_sd and patched_sd ~= src then
		src = patched_sd
	end
	-- Slider increments by whole numbers: round the value in set_slider so the
	-- displayed number (and the stored flag) step by 1 instead of showing a
	-- long float dragged from the mouse position.
	local sv = 'value = clamp(value, min, max)'
	local ok_sv, patched_sv = pcall(function()
		return src:gsub(esc2(sv), 'value = round(clamp(value, min, max))', 1)
	end)
	if ok_sv and patched_sv and patched_sv ~= src then
		src = patched_sv
	end
	-- Brighten the dark UI shades (keep the notification "alert" color and the
	-- pure-black base unchanged). Slightly lifts each to reduce the dim look.
	local brighten = {
		['["border"] = color3_fromrgb(24, 25, 24),']				= '["border"] = color3_fromrgb(45, 46, 45),',
		['["image"] = color3_fromrgb(89, 89, 89),']					= '["image"] = color3_fromrgb(122, 122, 122),',
		['["section"] = color3_fromrgb(6, 6, 6),']					= '["section"] = color3_fromrgb(20, 20, 20),',
		['["inactive_text"] = color3_fromrgb(75, 72, 72),']			= '["inactive_text"] = color3_fromrgb(112, 108, 108),',
		['["highlighted"] = color3_fromrgb(51, 65, 70),']			= '["highlighted"] = color3_fromrgb(78, 98, 106),',
		['["dark_text"] = color3_fromrgb(70, 85, 87),']				= '["dark_text"] = color3_fromrgb(104, 122, 126),',
		['["active_text"] = color3_fromrgb(197, 197, 197),']		= '["active_text"] = color3_fromrgb(223, 223, 223),',
		['["keybind_text"] = color3_fromrgb(197, 197, 197),']		= '["keybind_text"] = color3_fromrgb(223, 223, 223),',
		['["background"] = color3_fromrgb(0, 0, 0),']				= '["background"] = color3_fromrgb(0, 0, 0),',
	}
	for from, to in pairs(brighten) do
		local pat = from:gsub("([%(%)%.%[%]%*%+%-%?])", "%%%1")
		local ok_b, nsrc = pcall(function()
			return src:gsub(pat, to, 1)
		end)
		if ok_b and nsrc and nsrc ~= src then
			src = nsrc
		end
	end
	-- Scope the keybind click to just the small keybind box instead of the
	-- whole element row. The stock library registers `start_binding` on the
	-- full-width row `frame`, so clicking anywhere on a toggle+keybind row
	-- starts a rebind (huge hitbox) and fights the toggle. We add a tiny
	-- right-edge Square and attach the hover/click to that instead.
	local kb_orig = '\t\t\t\tcreate_hover_connection(parent, frame, function()\n' ..
		'\t\t\t\t\ttween(keybind_border, { Color = menu["colors"]["highlighted"] }, circular, out, 0.17)\n' ..
		'\t\t\t\tend, function()\n' ..
		'\t\t\t\t\ttween(keybind_border, { Color = menu["colors"]["border"] }, circular, out, 0.17)\n' ..
		'\t\t\t\tend)\n' ..
		'\n' ..
		'\t\t\t\tcreate_click_connection(parent, frame, function()\n' ..
		'\t\t\t\t\tstart_binding(new_element)\n' ..
		'\t\t\t\tend)'
	local kb_new = '\t\t\t\tlocal keybind_click = drawing_proxy["new"]("Square", {\n' ..
		'\t\t\t\t\t["Parent"] = frame,\n' ..
		'\t\t\t\t\t["Size"] = udim2_new(0, size + 2, 1, 0),\n' ..
		'\t\t\t\t\t["Transparency"] = 0,\n' ..
		'\t\t\t\t\t["Visible"] = true,\n' ..
		'\t\t\t\t\t["ZIndex"] = zindex + 4,\n' ..
		'\t\t\t\t\t["Position"] = udim2_new(1, -size - 2, 0, 0),\n' ..
		'\t\t\t\t})\n' ..
		'\n' ..
		'\t\t\t\tcreate_hover_connection(parent, keybind_click, function()\n' ..
		'\t\t\t\t\ttween(keybind_border, { Color = menu["colors"]["highlighted"] }, circular, out, 0.17)\n' ..
		'\t\t\t\tend, function()\n' ..
		'\t\t\t\t\ttween(keybind_border, { Color = menu["colors"]["border"] }, circular, out, 0.17)\n' ..
		'\t\t\t\tend)\n' ..
		'\n' ..
		'\t\t\t\tcreate_click_connection(parent, keybind_click, function()\n' ..
		'\t\t\t\t\tstart_binding(new_element)\n' ..
		'\t\t\t\tend)'
	local ok_kb, patched_kb = pcall(function()
		return src:gsub(esc2(kb_orig), kb_new, 1)
	end)
	if ok_kb and patched_kb and patched_kb ~= src then
		src = patched_kb
	end
	local kb2_orig = '\t\t\t\tif properties["flag"] then\n' ..
		'\t\t\t\t\tnew_element["keybind_flag"] = properties["flag"]\n' ..
		'\n' ..
		'\t\t\t\t\tlocal data = math_random(9000000, 90000000)\n' ..
		'\t\t\t\t\tkeybind_data[data] = {\n' ..
		'\t\t\t\t\t\t["key"] = properties["default"],\n' ..
		'\t\t\t\t\t\t["value"] = true,\n' ..
		'\t\t\t\t\t\t["original_value"] = false,\n' ..
		'\t\t\t\t\t\t["set_activated"] = function()\n' ..
		'\t\t\t\t\t\t\tnew_element["on_key_press"]:Fire()\n' ..
		'\t\t\t\t\t\tend,\n' ..
		'\t\t\t\t\t}\n' ..
		'\t\t\t\t\tcreate_connection(new_element["on_key_change"], function(key)\n' ..
		'\t\t\t\t\t\tkeybind_data[data]["key"] = key\n' ..
		'\t\t\t\t\t\tflags[properties["flag"]] = key\n' ..
		'\t\t\t\t\tend)\n' ..
		'\t\t\t\tend'
	local kb2_new = '\t\t\t\tif properties["flag"] then\n' ..
		'\t\t\t\t\tnew_element["keybind_flag"] = properties["flag"]\n' ..
		'\n' ..
		'\t\t\t\t\tlocal toggle_flag = elements["toggle"] and elements["toggle"]["flag"]\n' ..
		'\n' ..
		'\t\t\t\t\tif toggle_flag then\n' ..
		'\t\t\t\t\t\tlocal data = setmetatable({\n' ..
		'\t\t\t\t\t\t\t["key"] = properties["default"],\n' ..
		'\t\t\t\t\t\t\t["method"] = 1,\n' ..
		'\t\t\t\t\t\t\t["value"] = flags[toggle_flag],\n' ..
		'\t\t\t\t\t\t\t["original_value"] = flags[toggle_flag],\n' ..
		'\t\t\t\t\t\t\t["type"] = 3,\n' ..
		'\t\t\t\t\t\t\t["element"] = new_element,\n' ..
		'\t\t\t\t\t\t}, keybind)\n' ..
		'\n' ..
		'\t\t\t\t\t\tkeybind_data[new_element] = data\n' ..
		'\n' ..
		'\t\t\t\t\t\tcreate_connection(new_element["on_key_change"], function(key)\n' ..
		'\t\t\t\t\t\t\tkeybind_data[new_element]["key"] = key\n' ..
		'\t\t\t\t\t\t\tflags[properties["flag"]] = key\n' ..
		'\t\t\t\t\t\tend)\n' ..
		'\n' ..
		'\t\t\t\t\t\tif properties["default"] then\n' ..
		'\t\t\t\t\t\t\tnew_element:set_key(properties["default"])\n' ..
		'\t\t\t\t\t\tend\n' ..
		'\n' ..
		'\t\t\t\t\t\ton_keybind_created:Fire(data, new_element)\n' ..
		'\t\t\t\t\telse\n' ..
		'\t\t\t\t\t\tlocal data = math_random(9000000, 90000000)\n' ..
		'\t\t\t\t\t\tkeybind_data[data] = {\n' ..
		'\t\t\t\t\t\t\t["key"] = properties["default"],\n' ..
		'\t\t\t\t\t\t\t["value"] = true,\n' ..
		'\t\t\t\t\t\t\t["original_value"] = false,\n' ..
		'\t\t\t\t\t\t\t["set_activated"] = function()\n' ..
		'\t\t\t\t\t\t\t\tnew_element["on_key_press"]:Fire()\n' ..
		'\t\t\t\t\t\t\tend,\n' ..
		'\t\t\t\t\t\t}\n' ..
		'\t\t\t\t\t\tcreate_connection(new_element["on_key_change"], function(key)\n' ..
		'\t\t\t\t\t\t\tkeybind_data[data]["key"] = key\n' ..
		'\t\t\t\t\t\t\tflags[properties["flag"]] = key\n' ..
		'\t\t\t\t\t\tend)\n' ..
		'\t\t\t\t\tend\n' ..
		'\t\t\t\tend'
	local ok_kb2, patched_kb2 = pcall(function()
		return src:gsub(esc2(kb2_orig), kb2_new, 1)
	end)
	if ok_kb2 and patched_kb2 and patched_kb2 ~= src then
		src = patched_kb2
	end
	local kb_clear_orig = '\t\t\t\tif key == escape or key == tilde then\n' ..
		'\t\t\t\t\tkey = nil\n' ..
		'\t\t\t\tend'
	local kb_clear_new = '\t\t\t\tif key == escape or key == tilde or key == Enum["KeyCode"]["Backspace"] then\n' ..
		'\t\t\t\t\tkey = nil\n' ..
		'\t\t\t\tend'
	local ok_kb_clear, patched_kb_clear = pcall(function()
		return src:gsub(esc2(kb_clear_orig), kb_clear_new, 1)
	end)
	if ok_kb_clear and patched_kb_clear and patched_kb_clear ~= src then
		src = patched_kb_clear
	end
	-- Trim ui.lua's on-first-run download list so it only fetches (and caches)
	-- the files this ESP build actually reads at runtime: the drawing api, the
	-- colorpicker saturation grid, and data.dat state. Everything else in the
	-- the stock library `files` table (sounds, models, extra textures, spam/config jsons,
	-- default theme) is dead weight for this build and would otherwise be
	-- downloaded on first execute. We surgically rewrite the table header from
	-- `local files = {` through the last folder block (`["configs"] = {}`),
	-- leaving the `["data.dat"]` line and the rest untouched.
	local dl_repl  = '\t\tlocal files = {\n' ..
		'\t\t\t["assets"] = {\n' ..
		'\t\t\t\t["api.lua"] = safeHttp("https://raw.githubusercontent.com/panduh16/juju/main/assets/api.lua"),\n' ..
		'\t\t\t\t["saturation.png"] = safeHttp("https://raw.githubusercontent.com/panduh16/juju/main/assets/saturation.png"),\n' ..
		'\t\t\t},\n' ..
		'\t\t\t["custom"] = {},\n' ..
		'\t\t\t["themes"] = {},\n' ..
		'\t\t\t["addons"] = {},\n' ..
		'\t\t\t["configs"] = {},'
	local dl_a = src:find("local files = {", 1, true)
	local dl_b = src:find('["data.dat"]', 1, true)
	if dl_a and dl_b and dl_b > dl_a then
		src = src:sub(1, dl_a - 1) .. dl_repl .. src:sub(dl_b)
	end
	-- Remove the "custom kick screen" settings row from the menu (its toggle,
	-- background textbox, and colorpicker). It's a dead UI option for this ESP
	-- build; strip the whole `settings_section:create_element({ ... })` call by
	-- slicing from its opener line up to the next `create_connection(` (the
	-- start of the adjacent "unload juju" block, which must be preserved).
	local kk = ('["name"] = "custom kick screen",')
	local kb = src:find(kk, 1, true)
	if kb then
		local ka = nil
		local kpos = 1
		while true do
			local kna = src:find("settings_section:create_element({", kpos, true)
			if not kna or kna > kb then break end
			ka = kna
			kpos = kna + 36
		end
		local kline = ka
		while kline > 1 and src:sub(kline - 1, kline - 1) ~= "\n" do
			kline = kline - 1
		end
		local kend = src:find("create_connection(", kb, true)
		if kline and kend and kend > kline then
			src = src:sub(1, kline - 1) .. src:sub(kend)
		end
	end
	getgenv()._UNIVERSAL_SRC_ = src
	-- Point the stock UI library's working folder (themes/configs/data/logo
	-- assets, default "juju recode") at the Primordial folder name so no
	-- "juju recode" directory is created.
	getgenv().custom_folder = "Primordial BETA"
	local ok_load, loaded = pcall(loadstring, src or "")
	if not ok_load or type(loaded) ~= "function" then
		getgenv()._UNIVERSAL_LOAD_ERR = ("loadstring failed, src len=%d err=%s"):format(#(src or ""), tostring(loaded))
		error("Universal: failed to compile primo ui.lua")
	end
	local ok_run, ran = pcall(loaded)
	if not ok_run or type(ran) ~= "table" then
		getgenv()._UNIVERSAL_LOAD_ERR = ("run failed, src len=%d err=%s"):format(#(src or ""), tostring(ran))
		error("Universal: failed to run primo ui.lua: " .. tostring(ran))
	end
	juju = ran
	getgenv().juju = juju

	-- Force the logo color to white at runtime: the menu reads the "!logo_color"
	-- flag (and menu.colors.logo) for the logo tint / color-picker default, which
	-- otherwise falls back to the theme's pink. Override both so the logo stays
	-- white and the logo slider opens white (not the old primordial blue).
	pcall(function()
		local light = Color3.fromRGB(209, 180, 188)
		local white = Color3.fromRGB(255, 255, 255)
		local warmText = Color3.fromRGB(150, 138, 152)
		local warmHL = Color3.fromRGB(95, 78, 92)
		if juju and juju.menu and juju.menu.colors then
			local c = juju.menu.colors
			for _, k in ipairs({ "accent", "success", "juju", "build", "shadow" }) do
				c[k] = light
			end
			c.dark_text = warmText
			c.highlighted = warmHL
			c.logo = white
		end
		if juju and juju.flags then
			local ff = juju.flags
			for _, k in ipairs({ "!accent_color", "!success_color", "!juju_color", "!build_color", "!shadow_color" }) do
				ff[k] = light
			end
			ff["!dark_text_color"] = warmText
			ff["!active_border_color"] = warmHL
			ff["!logo_color"] = white
		end
		-- The color overrides above mutate menu.colors but NOT the already-drawn
		-- widget text (keybind/button drawings that were created during menu build
		-- using the source dark_text default, which reads as primordial blue-gray).
		-- Recolor those drawn text objects to the warm palette so "toggle bind" /
		-- the unload button (and any other keybind/button) match the rest of the menu.
		if juju and juju.menu and juju.menu.settings then
			for _, sec in pairs(juju.menu.settings) do
				if type(sec) == "table" and sec.elements then
					for _, elm in ipairs(sec.elements) do
						local d = elm and elm.drawings
						if d then
							for _, k in ipairs({ "keybind_text", "button_text", "text2", "button_icon", "dropdown_arrow", "dropdown_text", "slider_text", "textbox_text" }) do
								local v = d[k]
								if v then pcall(function() v.Color = warmText end) end
							end
						end
					end
				end
			end
		end
		-- Rebrand the residual visible "juju" wording ("unload juju" button, the
		-- "juju color" picker that survives the source rename) to "primo" or
		-- "primordial" depending on how much room the label has. Walk every
		-- group tab + settings section and rewrite any drawn Text with juju.
local function primoText(v)
				if type(v) == "table" and type(v.Text) == "string" and v.Text:lower():find("juju") then
					v.Text = v.Text:gsub("unload juju", "unload primordial"):gsub("Juju", "Primordial"):gsub("juju", "primo")
					return true
				end
			end
		if juju and juju.menu then
			local function primoList(list)
				for _, elm in ipairs(list or {}) do
					local d = elm and elm.drawings
					if d then
						for _, v in pairs(d) do
							pcall(function() primoText(v) end)
						end
					end
				end
			end
			for _, grp in pairs(juju.menu.groups or {}) do
				for _, tab in pairs(grp.tabs or {}) do
					for _, sec in pairs(tab.sections or {}) do
						primoList(sec.elements)
					end
				end
			end
			for _, sec in pairs(juju.menu.settings or {}) do
				if type(sec) == "table" then
					primoList(sec.elements)
				end
			end
		end
	end)
end

local menu            = juju.menu
local flags           = juju.flags
local create_connection = juju.create_connection

--------------------------------------------------------------------
-- 2. PRIMORDIAL MENU (ESP controls)
--------------------------------------------------------------------
local visual = menu.create_group("visuals")
visual:create_tab("players")
visual:create_tab("misc")

-- Left column = feature toggles + filters + gradient controls (scrolls on hover).
-- Right column = one big colors section, fully contained (no overflow).
local esp = visual:create_section("players", "players", 1, 0.6, 0)
local col = visual:create_section("players", "colors", 2, 1, 0)
local local_section = visual:create_section("players", "local", 1, 0.4, 0.6)
local world = visual:create_section("misc", "misc", 1, 1, 0)

menu:setup_configs(visual)

-- The executor's drawing lib can't measure text on create, so create_tab's
-- built-in auto-activate is skipped and no tab ends up active (blank right
-- panel). Force the players tab active so its sections render.
do
	local esp_tab_obj = visual.tabs["players"]
	if esp_tab_obj then
		local actives = menu.activate_tab or menu.actives or nil
		if type(actives) == "function" then
			pcall(actives, esp_tab_obj)
		end
	end
end

local esp_elements = {}
local function el(section, name, opts)
	local e = section:create_element({ name = name }, opts)
	table.insert(esp_elements, e)
	return e
end

-- toggles / sub-features
el(esp, "enabled",       { toggle = { flag = "esp_enabled",   default = true } })
local box = el(esp, "box", { toggle = { flag = "esp_box", default = true } })
local box_cog = box:create_settings(1)
box_cog:create_element({ name = "box outline", section = 1 }, {
	toggle = { flag = "esp_outline", default = true },
})
box_cog:create_element({ name = "gradient spin", section = 1 }, {
	toggle = { flag = "esp_grad_spin", default = true },
})
box_cog:create_element({ name = "gradient speed", section = 1 }, {
	slider = { flag = "esp_grad_speed", min = 10, max = 720, default = 360, suffix = " deg/s" },
})
el(esp, "health bar",    { toggle = { flag = "esp_health_bar", default = true } })
el(esp, "health text",   { toggle = { flag = "esp_health_text", default = true } })
el(esp, "name",          { toggle = { flag = "esp_name",      default = true } })
el(esp, "distance",      { toggle = { flag = "esp_distance",  default = true } })
el(esp, "tool",          { toggle = { flag = "esp_weapon",    default = false } })
el(esp, "skeleton",      { toggle = { flag = "esp_skeleton",  default = true } })
local chams_el  = el(esp, "chams",         { toggle = { flag = "esp_chams",     default = false } })
local chams_cog = chams_el:create_settings(1)
local chams_type_dd = chams_cog:create_element({ name = "Type", section = 1 }, {
	dropdown = { flag = "esp_chams_type", options = { "Solid", "Lobotomized", "Highlight" }, default = "Solid" },
})
local chams_trans_sl = chams_cog:create_element({ name = "transparency", section = 1 }, {
	slider = { flag = "esp_chams_trans", min = 0, max = 100, default = 0, suffix = "%" },
})

-- local section (under the players list, column 1 bottom) - avatar changer
local av_toggle = el(local_section, "Avatar changer", { toggle = { flag = "local_avatar_changer", default = false } })
local av_cog = av_toggle:create_settings(1)
local av_userid  = av_cog:create_element({ name = "Avatar UserId", section = 1 }, {
	textbox = { flag = "local_avatar_userid", default = "80254" },
})

-- particle aura (ported from j2 archive "Juju v2 - da hood") - local character visual
local aura_el = el(local_section, "Particle aura", { toggle = { flag = "local_aura", default = false } })
local aura_cog = aura_el:create_settings(1)
local aura_type_dd = aura_cog:create_element({ name = "Type", section = 1 }, {
	dropdown = { flag = "local_aura_type", options = { "Swirl", "Bubble", "Air", "Ritual", "Rain", "starlight", "heavenly", "ribbon", "sakura", "angel", "wind", "flow", "star" }, default = "Swirl" },
})
local aura_color_pk = aura_cog:create_element({ name = "Color", section = 1 }, {
	colorpicker = { color_flag = "local_aura_color", transparency_flag = "",
		default_color = Color3.fromRGB(0, 255, 38), default_transparency = 0 },
})

-- filters
el(esp, "show teammates", { toggle = { flag = "esp_team",      default = false } })
el(esp, "ignore dead",    { toggle = { flag = "esp_dead",      default = false } })
el(esp, "max distance",   { slider = { flag = "esp_dist", min = 100, max = 5000, default = 1000, suffix = " studs" } })

-- colors: two endpoints per gradient so the box/health actually show a gradient
local function colorpick(name, cf, dc)
	return el(col, name, {
		colorpicker = { color_flag = cf, transparency_flag = "",
			default_color = dc, default_transparency = 0 },
	})
end
colorpick("box 1",      "esp_box_col1",      Color3.fromRGB(255, 60, 63))
colorpick("box 2",      "esp_box_col2",      Color3.fromRGB(255, 200, 40))
colorpick("box outline","esp_outline_col",   Color3.new(0, 0, 0))
colorpick("health 1",   "esp_health_col1",   Color3.fromRGB(60, 255, 120))
colorpick("health 2",   "esp_health_col2",   Color3.fromRGB(80, 255, 255))
colorpick("health text","esp_health_text_col", Color3.new(1, 1, 1))
colorpick("name",       "esp_name_col",      Color3.new(1, 1, 1))
colorpick("distance",   "esp_dist_col",      Color3.new(1, 1, 1))
colorpick("tool",       "esp_weapon_col",    Color3.new(1, 1, 1))
colorpick("skeleton",   "esp_skel_col",      Color3.new(1, 1, 1))
colorpick("chams",      "esp_chams_col",     Color3.fromRGB(60, 120, 255))

--------------------------------------------------------------------
-- 3. UNIVERSAL PLAYER ESP  (ported 1:1 from swa.lua, game-agnostic)
--------------------------------------------------------------------
do
	local Players    = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local CoreGui    = game:GetService("CoreGui")
	local GuiService = game:GetService("GuiService")
	local Camera     = workspace.CurrentCamera
	local lplr       = Players.LocalPlayer

	local container = Instance.new("Folder", CoreGui.RobloxGui)
	container.Name  = "UniversalContainer"
	local gui_inset = GuiService:GetGuiInset()

	-- every top-level connection so UniversalUnload can fully tear the ESP down
	local conns = {}

	local FontSans  = Font.new("rbxasset://fonts/families/GothamSSm.json")

	local min = math.min
	local max = math.max
	local floor = math.floor
	local round = math.round or function(x) return math.floor(x + 0.5) end
	local tick = tick

	local function S(t) return flags[t] or false end
	local function C(c) return flags[c] or Color3.new(1, 1, 1) end
	local function N(n) return flags[n] or 0 end
	-- primordial dropdowns store the selected value as a table (multi-select list),
	-- so unwrap it: returns the first selected option as a string (or "").
	local function D(d)
		local v = flags[d]
		if type(v) == "string" then return v end
		if type(v) == "table" then return tostring(v[1] or "") end
		return tostring(v or "")
	end

	local function create_obj(new, args, tbl)
		local obj = Instance.new(new)
		for k, v in args do obj[k] = v end
		if tbl then table.insert(tbl, obj) end
		return obj
	end

	-- both R6 and R15 standard body names so per-part chams cover every rig.
	-- (SWA only listed R15 names, which is why R6 chams degraded to just the head.)
	local valid_parts = {
		-- R6
		Head = true, Torso = true,
		["Left Arm"] = true, ["Right Arm"] = true,
		["Left Leg"] = true, ["Right Leg"] = true,
		-- R15
		LeftFoot = true,  LeftLowerLeg = true,  LeftUpperLeg = true,
		RightFoot = true, RightLowerLeg = true, RightUpperLeg = true,
		LeftHand = true,  LeftLowerArm = true,  LeftUpperArm = true,
		RightHand = true, RightLowerArm = true, RightUpperArm = true,
		LowerTorso = true, UpperTorso = true,
	}
	local function isBodyPart(n) return valid_parts[n] end

	local VERTICES = {
		Vector3.new(-1, -1, -1), Vector3.new(-1, 1, -1),
		Vector3.new(-1, 1, 1),   Vector3.new(-1, -1, 1),
		Vector3.new(1, -1, -1),  Vector3.new(1, 1, -1),
		Vector3.new(1, 1, 1),    Vector3.new(1, -1, 1),
	}
	local skeleton_order = {
		-- R15
		LeftFoot = "LeftLowerLeg",  LeftLowerLeg = "LeftUpperLeg",  LeftUpperLeg = "LowerTorso",
		RightFoot = "RightLowerLeg",RightLowerLeg = "RightUpperLeg",RightUpperLeg = "LowerTorso",
		LeftHand = "LeftLowerArm",  LeftLowerArm = "LeftUpperArm",  LeftUpperArm = "UpperTorso",
		RightHand = "RightLowerArm",RightLowerArm = "RightUpperArm",RightUpperArm = "UpperTorso",
		LowerTorso = "UpperTorso",  UpperTorso = "Head",
		-- R6
		["Left Leg"] = "Torso", ["Right Leg"] = "Torso",
		["Left Arm"] = "Torso", ["Right Arm"] = "Torso",
		Torso = "Head",
	}

	local function v2min(...)
		local out
		for _, v in { ... } do
			out = out and Vector2.new(min(out.X, v.X), min(out.Y, v.Y)) or v
		end
		return out
	end
	local function v2max(...)
		local out
		for _, v in { ... } do
			out = out and Vector2.new(max(out.X, v.X), max(out.Y, v.Y)) or v
		end
		return out
	end
	local function v3min(...)
		local out
		for _, v in { ... } do
			out = out and Vector3.new(min(out.X, v.X), min(out.Y, v.Y), min(out.Z, v.Z)) or v
		end
		return out
	end
	local function v3max(...)
		local out
		for _, v in { ... } do
			out = out and Vector3.new(max(out.X, v.X), max(out.Y, v.Y), max(out.Z, v.Z)) or v
		end
		return out
	end

	local function getBoundingBox(parts)
		local mn, mx
		for _, p in parts do
			local cf, sz = p[1], p[2]
			local lo = cf - sz * 0.5
			local hi = cf + sz * 0.5
			mn = mn and v3min(mn, lo.Position) or lo.Position
			mx = mx and v3max(mx, hi.Position) or hi.Position
		end
		local center = (mn + mx) * 0.5
		local front = Vector3.new(center.X, center.Y, mx.Z)
		return CFrame.new(center, front), mx - mn
	end

	local function worldToScreen(world)
		local s, inBounds = Camera:WorldToScreenPoint(world)
		return Vector2.new(s.X, s.Y) + gui_inset, inBounds, s.Z
	end

	local function calculateCorners(cf, size)
		local corners = table.create(#VERTICES)
		for i, v in VERTICES do
			corners[i] = worldToScreen((cf + size * 0.5 * v).Position)
		end
		return v2min(Camera.ViewportSize, unpack(corners)), v2max(Vector2.zero, unpack(corners))
	end

	local is_teammate = function(player)
		local lp, pp = lplr.Team, player.Team
		if not (lp and pp) then return false end
		return player.Team == lplr.Team
	end

	local function get_gun(player, character, humanoid)
		local tool = character and character:FindFirstChildOfClass("Tool")
		return tool and tool.Name
	end

	local loaded = {}

	-- NHV3-style "Lobotomized" chams: clone the character's visible parts into
	-- a weld-anchored clone model and light it with two Highlights (one behind
	-- walls / Occluded, one AlwaysOnTop) so it reads as a filled silhouette.
	local function destroy_lobo(data)
		if not (data and data.lbo) then return end
		local lbo = data.lbo
		pcall(function() lbo.model:Destroy() end)
		if lbo.wconn then pcall(function() lbo.wconn:Disconnect() end) end
		data.lbo = nil
	end

	local function build_lobo(data, character)
		destroy_lobo(data)
		if not (character and character:IsA("Model")) then return end

		local chams_ignore = {
			HumanoidRootPart = true, Hitbox = true, FakeHead = true,
			FaceHitBox = true, HeadHB = true, HeadTopHitBox = true,
			PlayerCollision = true,
		}

		local model = Instance.new("Model")
		model.Name = "EspLobo"
		model.Parent = workspace

		local chains = {}
		local seen = {}
		local function clone_to(part)
			if not (part and part:IsA("BasePart")) then return end
			if seen[part] then return end
			if part.Transparency >= 1 or part.LocalTransparencyModifier >= 1 then return end
			if chams_ignore[part.Name] then return end
			seen[part] = true
			local cl = part:Clone()
			cl.Parent = model
			for _, sub in cl:GetChildren() do
				if not sub:IsA("DataModelMesh") then pcall(function() sub:Destroy() end) end
			end
			cl.CanCollide = false
			cl.CanQuery = false
			cl.CanTouch = false
			cl.Massless = true
			cl.CastShadow = false
			cl.Material = Enum.Material.SmoothPlastic
			if cl:IsA("MeshPart") then
				pcall(function() cl.TextureID = "" end)
				pcall(function() cl.RenderFidelity = Enum.RenderFidelity.Performance end)
			end
			cl.Size = cl.Size * 0.98
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = cl
			weld.Part1 = part
			weld.Parent = cl
			chains[#chains + 1] = weld
		end

		-- top-level parts + explicit Hair model (NHV3 BuildChams equivalent)
		for _, child in character:GetChildren() do
			if child:IsA("BasePart") then
				clone_to(child)
			elseif child:IsA("Model") and child.Name == "Hair" then
				for _, part in child:GetDescendants() do
					clone_to(part)
				end
			end
		end
		-- fallback: any remaining visible BaseParts anywhere in the character
		-- (catches hair/accessories nested in models we don't special-case)
		for _, part in character:GetDescendants() do
			clone_to(part)
		end

		if #chains == 0 then
			pcall(function() model:Destroy() end)
			return
		end

		local occ = Instance.new("Highlight")
		occ.DepthMode = Enum.HighlightDepthMode.Occluded
		occ.Enabled = false
		occ.Adornee = model
		-- NHV3 "Visible Textured" default: negative FillTransparency produces the
		-- cursed/inverted scanned fill instead of a clean solid silhouette.
		occ.FillTransparency = -4.8
		occ.OutlineTransparency = 0
		occ.Parent = model

		local onTop = Instance.new("Highlight")
		onTop.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		onTop.Enabled = false
		onTop.FillTransparency = -4.8
		onTop.OutlineTransparency = 0
		onTop.Parent = model

		local wconn = nil
		pcall(function()
			wconn = character:GetPropertyChangedSignal("Parent"):Connect(function()
				destroy_lobo(data)
			end)
		end)

		data.lbo = { model = model, occ = occ, onTop = onTop, wconn = wconn }
	end

	-- Primordial-style highlight chams: a single Highlight on the character
	-- with Fill+Outline in the cham color and a static (non-animated)
	-- transparency, parented into the CoreGui container so it reads as a
	-- filled silhouette over walls.
	local function destroy_hlight(data)
		if not (data and data.hlight) then return end
		pcall(function() data.hlight:Destroy() end)
		data.hlight = nil
	end

	local function build_hlight(data, character)
		destroy_hlight(data)
		if not (character and character:IsA("Model")) then return end
		local node = C("esp_chams_col")
		local light = Instance.new("Highlight")
		light.Name = "EspHighlight"
		light.Parent = container
		light.Adornee = character
		light.FillColor = node
		light.OutlineColor = node
		light.DepthMode = Enum.HighlightDepthMode.Occluded
		-- static, no breathe animation; transparency mirrors the slider:
		-- 0% slider = opaque fill, 100% = faded
		light.FillTransparency = 0.05 + (N("esp_chams_trans") / 100) * 0.85
		light.OutlineTransparency = 0.05
		light.Enabled = S("esp_chams")
		data.hlight = light
	end

	local function destroy_esp(obj_plr)
		local data = loaded[obj_plr]
		if not data then return end
		for _, cl in data.connections do pcall(function() cl:Disconnect() end) end
		for _, o in data.obj do pcall(function() o:Destroy() end) end
		for part, cham in data.chams do
			pcall(function() cham.connection:Disconnect() end)
			pcall(function() cham.cham:Destroy() end)
		end
		destroy_lobo(data)
		destroy_hlight(data)
		loaded[obj_plr] = nil
	end

	local function create_esp(plr_instance)
		local data = { obj = {}, connections = {}, chams = {} }
		loaded[plr_instance] = data
		local obj = data.obj

		local main_holder = create_obj("Frame", {
			Parent = container, ZIndex = 2, BorderSizePixel = 0,
			Size = UDim2.fromScale(0, 0), Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1, Visible = false,
		}, obj)
		local box_holder = create_obj("Frame", {
			Parent = main_holder, ZIndex = -1, BorderSizePixel = 0,
			Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
		}, obj)
		local box_outline_holder = create_obj("Frame", {
			Parent = main_holder, ZIndex = -1, BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2),
			BackgroundTransparency = 1,
		}, obj)

		local main_box = create_obj("UIStroke", {
			Parent = box_holder, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(1, 1, 1),
		}, obj)
		local main_box_color = create_obj("UIGradient", {
			Parent = main_box,
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1)) }),
		}, obj)
		local main_box_outline_1 = create_obj("UIStroke", {
			Parent = main_holder, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(),
		}, obj)
		local main_box_outline_2 = create_obj("UIStroke", {
			Parent = box_outline_holder, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new(),
		}, obj)

		local main_name = create_obj("TextLabel", {
			Parent = main_holder, TextStrokeTransparency = 0, BorderSizePixel = 0,
			TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, FontFace = FontSans,
			TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 200, 0, 13),
			Text = plr_instance.Name, Position = UDim2.new(0.5, 0, 0, -17),
		}, obj)
		local main_distance = create_obj("TextLabel", {
			Parent = main_holder, TextStrokeTransparency = 0, BorderSizePixel = 0,
			TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, FontFace = FontSans,
			TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 200, 0, 13),
			Text = "0m", Position = UDim2.new(0.5, 0, 1, 1),
		}, obj)
		local main_weapon = create_obj("TextLabel", {
			Parent = main_holder, TextStrokeTransparency = 0, BorderSizePixel = 0,
			TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, FontFace = FontSans,
			TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 200, 0, 13),
			Text = "", Position = UDim2.new(0.5, 0, 1, 14),
		}, obj)
		create_obj("UIStroke", { Parent = main_name, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new() }, obj)
		create_obj("UIStroke", { Parent = main_distance, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new() }, obj)
		create_obj("UIStroke", { Parent = main_weapon, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new() }, obj)

		local health_bar_holder = create_obj("Frame", {
			Parent = main_holder, BackgroundColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0, -5, 0, 0), BorderSizePixel = 0,
		}, obj)
		create_obj("UIStroke", { Parent = health_bar_holder, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new() }, obj)
		local main_health_bar = create_obj("Frame", {
			Parent = health_bar_holder, ZIndex = 2, BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(1, 0, 0, 0),
		}, obj)
		local main_health_text = create_obj("TextLabel", {
			Parent = main_health_bar, TextStrokeTransparency = 0, BorderSizePixel = 0,
			TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, FontFace = FontSans,
			TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
			Size = UDim2.new(50, 0, 0, 6), AnchorPoint = Vector2.new(1, 0), Text = "100",
			Position = UDim2.new(-2, 0, 1, 0),
		}, obj)
		create_obj("UIStroke", { Parent = main_health_text, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Miter, Color = Color3.new() }, obj)
		local health_bar_thing = create_obj("Frame", {
			Parent = health_bar_holder, BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 1, 0),
		}, obj)
		local main_health_bar_color = create_obj("UIGradient", {
			Parent = health_bar_thing, Rotation = 90,
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1)) }),
		}, obj)

		local main_wireframe = create_obj("WireframeHandleAdornment", {
			Parent = container, Color3 = Color3.new(1, 1, 1), Transparency = 0,
			AlwaysOnTop = true, CFrame = CFrame.new(), Scale = Vector3.one,
			Thickness = 1, AdornCullingMode = Enum.AdornCullingMode.Automatic,
		}, obj)

		local is_visible = false
local function refresh_chams()
			local c1 = C("esp_chams_col")
			local trans = -(1 - N("esp_chams_trans") / 100)
			local typ = D("esp_chams_type")
			local solid = S("esp_chams") and (typ == "Solid")
			local lobo = S("esp_chams") and typ == "Lobotomized"
			local hlight = S("esp_chams") and typ == "Highlight"
			for part, cham in data.chams do
				cham.cham.Adornee = is_visible and solid and part or nil
				cham.cham.Color3 = c1
				cham.cham.Transparency = trans
			end
			if data.lbo then
				local l = data.lbo
				-- single chams color for both Highlights, black outline (NHV3-style)
				l.occ.OutlineColor = Color3.new()
				l.occ.FillColor = c1
				l.onTop.FillColor = c1
				l.onTop.OutlineColor = Color3.new()
				local en = is_visible and lobo
				l.occ.Enabled = en
				l.onTop.Enabled = en
			end
			if data.hlight then
				local h = data.hlight
				h.FillColor = c1
				h.OutlineColor = c1
				h.FillTransparency = 0.05 + (N("esp_chams_trans") / 100) * 0.85
				h.Enabled = is_visible and hlight
			end
		end
		local function setvis(bool)
			if is_visible == bool then return end
			is_visible = bool
			main_holder.Visible = bool
			main_wireframe.Visible = bool
			if not bool and data.lbo then
				local l = data.lbo
				l.occ.Enabled = false
				l.onTop.Enabled = false
			end
			refresh_chams()
		end

		local function destroy_cham(part)
			local cham = data.chams[part]
			if not cham then return end
			pcall(function() cham.connection:Disconnect() end)
			pcall(function() cham.cham:Destroy() end)
			data.chams[part] = nil
		end

		-- Solid chams box size per part. The Head on standard/FallenSurvival rigs is
		-- often a plain 2x1x1 Part (a big collision box) even though the visible head
		-- is ~1.2x1.2x1.2, so cap it to a head sized box to avoid a "big lego brick".
		local function cham_size(part)
			if part.Name == "Head" then
				return Vector3.new(
					min(part.Size.X, 1.25), min(part.Size.Y, 1.25), min(part.Size.Z, 1.25)
				) * 0.95
			end
			return part.Size * 0.95
		end

		local function create_cham(part)
			if not (part:IsA("BasePart") and isBodyPart(part.Name)) then return end
			if data.chams[part] then destroy_cham(part) end
			local node = C("esp_chams_col")
			local cham = create_obj("BoxHandleAdornment", {
				Parent = container, Size = cham_size(part),
				Adornee = is_visible and S("esp_chams") and part or nil,
				Color3 = node,
				-- transparency slider: 0% -> -1 (opaque solid xray cham, the
				-- classic look), 100% -> 0 (faded). Out-of-range -1 is how
				-- BoxHandleAdornment renders the solid see-through fill.
				Transparency = -(1 - N("esp_chams_trans") / 100),
				Shading = Enum.AdornShading.XRayShaded,
				ZIndex = -1, AlwaysOnTop = false,
			}, obj)
			local conn = part:GetPropertyChangedSignal("Size"):Connect(function()
				if cham then cham.Size = cham_size(part) end
			end)
			data.chams[part] = { cham = cham, connection = conn }
		end

		local function character_added(character)
			if character then
				for _, part in character:GetChildren() do create_cham(part) end
				data.connections.character_childadded = character.ChildAdded:Connect(create_cham)
				data.connections.character_childremoved = character.ChildRemoved:Connect(destroy_cham)
				if D("esp_chams_type") == "Lobotomized" then build_lobo(data, character) end
				if D("esp_chams_type") == "Highlight" then build_hlight(data, character) end
			end
		end

		local function character_removing(character)
			if data.connections.character_childadded then data.connections.character_childadded:Disconnect() end
			if data.connections.character_childremoved then data.connections.character_childremoved:Disconnect() end
			for part, _ in data.chams do destroy_cham(part) end
			destroy_lobo(data)
			destroy_hlight(data)
		end

		if plr_instance.Character then character_added(plr_instance.Character) end
		data.connections.character_added = plr_instance.CharacterAdded:Connect(character_added)
		data.connections.character_removing = plr_instance.CharacterRemoving:Connect(character_removing)

		local character, humanoid, root

		-- re-apply color/visibility from the primo flags (like SWA's forceupdate)
		data.apply = function()
			main_box_outline_1.Enabled = S("esp_outline")
			main_box_outline_1.Color = C("esp_outline_col")
			main_box_outline_1.Transparency = 0
			main_box_outline_2.Enabled = S("esp_outline")
			main_box_outline_2.Color = C("esp_outline_col")
			main_box_outline_2.Transparency = 0

			main_box.Enabled = S("esp_box")
			main_box_color.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, C("esp_box_col1")),
				ColorSequenceKeypoint.new(1, C("esp_box_col2")),
			})

			health_bar_holder.Visible = S("esp_health_bar")
			main_health_bar_color.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, C("esp_health_col1")),
				ColorSequenceKeypoint.new(1, C("esp_health_col2")),
			})

			main_health_text.Visible = S("esp_health_text")
			main_health_text.TextColor3 = C("esp_health_text_col")
			main_health_text.TextTransparency = 0

			main_name.Visible = S("esp_name")
			main_name.TextColor3 = C("esp_name_col")
			main_name.TextTransparency = 0

			main_distance.Visible = S("esp_distance")
			main_distance.TextColor3 = C("esp_dist_col")
			main_distance.TextTransparency = 0

			main_weapon.Visible = S("esp_weapon")
			main_weapon.TextColor3 = C("esp_weapon_col")
			main_weapon.TextTransparency = 0

			main_wireframe.Visible = S("esp_skeleton")
			main_wireframe.Color3 = C("esp_skel_col")
			main_wireframe.Transparency = 0

			refresh_chams()
		end
		data.apply()

		data.render = function(delta)
			if not S("esp_enabled") then return setvis(false) end

			character = plr_instance.Character
			root = character and character:FindFirstChild("HumanoidRootPart")
			humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if not (character and root and humanoid) then return setvis(false) end

			local h_health = humanoid.Health
			local h_max = humanoid.MaxHealth
			local h_dist = (Camera.CFrame.Position - root.Position).Magnitude

			if (not S("esp_team") and is_teammate(plr_instance)) then return setvis(false) end
			if S("esp_dead") and h_health <= 0 then return setvis(false) end
			if h_dist > N("esp_dist") then return setvis(false) end

			local _, on_screen = Camera:WorldToViewportPoint(root.Position)
			if not on_screen then return setvis(false) end

			local cache = table.create(15)
			local count = 0
			for _, part in character:GetChildren() do
				if part:IsA("BasePart") and isBodyPart(part.Name) then
					cache[part.Name] = { part.CFrame, part.Size }
					count += 1
				end
			end
			if count <= 0 then return setvis(false) end

			-- rig-agnostic world-axis-aligned box over the character's parts so it
			-- always hugs the player (never squished by nonstandard names, never
			-- tilted by extents orientation).
			local mnW, mxW
			for _, part in character:GetChildren() do
				if part:IsA("BasePart") then
					local half = part.Size * 0.5
					local lo = (part.CFrame * CFrame.new(-half.X, -half.Y, -half.Z)).Position
					local hi = (part.CFrame * CFrame.new(half.X, half.Y, half.Z)).Position
					mnW = mnW and v3min(mnW, lo) or lo
					mxW = mxW and v3max(mxW, hi) or hi
				end
			end
			local sizeW = mxW - mnW
			if sizeW.Magnitude <= 0.001 then return setvis(false) end
			local topLeft, bottomRight = calculateCorners(CFrame.new((mnW + mxW) * 0.5), sizeW)

			setvis(true)

			-- Solid chams: re-assert Adornee each frame so a cham doesn't get stuck
			-- on a single part (e.g. just an arm) when a limb's Adornee is cleared
			-- by a replan/reparent mid-frame.
			if S("esp_chams") and D("esp_chams_type") == "Solid" then
				for part, cham in data.chams do
					if part.Parent then cham.cham.Adornee = part end
				end
			end

			local pos = topLeft
			local size = bottomRight - topLeft
			main_holder.Position = UDim2.fromOffset(pos.X - gui_inset.X, pos.Y - gui_inset.Y)
			main_holder.Size = UDim2.fromOffset(size.X, size.Y)

			-- animated box gradient (no box-rotation static offset, no holder spin)
			main_box_color.Rotation = S("esp_grad_spin") and tick() % 1 * N("esp_grad_speed") % 360 or 0

			main_distance.Text = round(h_dist / 3) .. "m"

			main_weapon.Visible = S("esp_weapon")
			if main_weapon.Visible then
				local gun = get_gun(plr_instance, character, humanoid)
				if gun then
					main_weapon.Text = gun
					main_weapon.Position = S("esp_distance") and UDim2.new(0.5, 0, 1, 14) or UDim2.new(0.5, 0, 1, 1)
				else
					main_weapon.Visible = false
				end
			end

			main_health_text.Text = tostring(floor(h_health))
			main_health_bar.Size = UDim2.fromScale(1, 1 - h_health / (h_max > 0 and h_max or 1))

			main_wireframe:Clear()
			if S("esp_skeleton") and root then
				main_wireframe.Adornee = root
				local points = table.create(15 * 2)
				local counter = 0
				local root_pos = root.CFrame
				for part_name, info in cache do
					local parent_name = skeleton_order[part_name]
					local parent_info = parent_name and cache[parent_name]
					if parent_info then
						points[counter + 1] = root_pos:VectorToObjectSpace(info[1].Position - root_pos.Position)
						points[counter + 2] = root_pos:VectorToObjectSpace(parent_info[1].Position - root_pos.Position)
						counter += 2
					end
				end
				main_wireframe:AddLines(points)
			end
		end
	end

	-- live re-apply on any menu change (toggles + sliders + colorpickers),
	-- mirroring SWA's ocr callback -> EspLibrary.icaca() -> every plr:forceupdate()
	for _, elem in esp_elements do
		if elem.on_toggle_change then
			conns[#conns + 1] = create_connection(elem.on_toggle_change, function() for _, d in loaded do if d.apply then d.apply() end end end)
		end
		if elem.on_slider_change then
			conns[#conns + 1] = create_connection(elem.on_slider_change, function() for _, d in loaded do if d.apply then d.apply() end end end)
		end
		if elem.on_color_change then
			conns[#conns + 1] = create_connection(elem.on_color_change, function() for _, d in loaded do if d.apply then d.apply() end end end)
		end
		if elem.on_transparency_change then
			conns[#conns + 1] = create_connection(elem.on_transparency_change, function() for _, d in loaded do if d.apply then d.apply() end end end)
		end
	end

	-- dropdown changes (chams Type Solid<->Lobotomized): rebuild clone models
	-- for existing players so the switch applies immediately, then restyle.
	if chams_type_dd and chams_type_dd["on_dropdown_change"] then
		conns[#conns + 1] = create_connection(chams_type_dd["on_dropdown_change"], function()
			for _, plr in Players:GetPlayers() do
				if plr ~= lplr and plr.Character then
					local d = loaded[plr]
					if d then
						build_lobo(d, plr.Character)
						build_hlight(d, plr.Character)
					end
				end
			end
			for _, d in loaded do if d.apply then d.apply() end end
		end)
	end

	-- chams transparency slider (cog element, not in esp_elements): re-apply
	if chams_trans_sl and chams_trans_sl["on_slider_change"] then
		conns[#conns + 1] = create_connection(chams_trans_sl["on_slider_change"], function()
			for _, d in loaded do if d.apply then d.apply() end end
		end)
	end

	-- spawn / despawn
	for _, p in Players:GetPlayers() do if p ~= lplr then create_esp(p) end end
	conns[#conns + 1] = Players.PlayerAdded:Connect(function(p) create_esp(p) end)
	conns[#conns + 1] = Players.PlayerRemoving:Connect(destroy_esp)

	-- avatar changer (ported from Swimhub "view_avatar_changer"): swap the
	-- local player's avatar for another user's (body colors, shirt/pants,
	-- accessories), and wipe game-applied accessories while it's on.
	do
		local av_valid_parts = {
			["Head"] = true, ["LeftFoot"] = true, ["LeftHand"] = true,
			["LeftLowerArm"] = true, ["LeftLowerLeg"] = true,
			["LeftUpperArm"] = true, ["LeftUpperLeg"] = true,
			["RightFoot"] = true, ["RightHand"] = true,
			["RightLowerArm"] = true, ["RightLowerLeg"] = true,
			["RightUpperArm"] = true, ["RightUpperLeg"] = true,
			["LowerTorso"] = true, ["UpperTorso"] = true,
		}

		local avatar_used = false

		local function change_avatar()
			if not flags["local_avatar_changer"] then return end
			avatar_used = true
			local ok_num, user_id = pcall(tonumber, tostring(flags["local_avatar_userid"]))
			if not (ok_num and user_id) then return end

			local ok, wanted = pcall(Players.CreateHumanoidModelFromUserId, Players, user_id)
			if not (ok and wanted) then return end

			local character = lplr.Character or lplr.CharacterAdded:Wait()
			for _, child in character:GetChildren() do
				if child:IsA("Accessory") or child:GetAttribute("ItemType") then
					pcall(function() child:Destroy() end)
				end
			end

			for _, child in wanted:GetChildren() do
				local class = child.ClassName
				if class == "Shirt" or class == "Pants" then
					local stuff = character:FindFirstChildOfClass(class)
					if not stuff then
						stuff = Instance.new(class)
						pcall(function() stuff.Parent = character end)
					end
					if stuff and stuff[class .. "Template"] then
						pcall(function() stuff[class .. "Template"] = child[class .. "Template"] end)
					end
				elseif class == "Accessory" then
					local handle = child:FindFirstChild("Handle")
					local weld = handle and handle:FindFirstChild("AccessoryWeld")
					local target = weld and character:FindFirstChild(weld.Part1.Name)
					if weld and target then
						pcall(function() weld.Part1 = target end)
						child.Parent = character
					end
				elseif class == "MeshPart" and av_valid_parts[child.Name] then
					local target = character:FindFirstChild(child.Name)
					if target then
						pcall(function() target.Color = child.Color end)
					end
				end
			end
			pcall(function() wanted:Destroy() end)
		end

		local av_char_conn
		local function av_arm()
			task.spawn(change_avatar)
			if av_char_conn then pcall(function() av_char_conn:Disconnect() end) end
			av_char_conn = lplr.CharacterAdded:Connect(function(ch)
				avatar_used = false
				task.spawn(change_avatar)
				ch.ChildAdded:Connect(function(child)
					if avatar_used and child:GetAttribute("ItemType") then pcall(function() child:Destroy() end) end
				end)
			end)
		end

		-- trigger from the toggle and the textbox
		if av_toggle and av_toggle["on_toggle_change"] then
			conns[#conns + 1] = create_connection(av_toggle["on_toggle_change"], function() av_arm() end)
		end
		if av_userid and av_userid["on_textbox_change"] then
			conns[#conns + 1] = create_connection(av_userid["on_textbox_change"], function() change_avatar() end)
		end
		conns[#conns + 1] = lplr.CharacterAdded:Connect(function() avatar_used = false; task.spawn(change_avatar) end)
		task.spawn(change_avatar)
	end

	-- particle aura (ported from j2 archive "Juju v2 - da hood"): ring of
	-- particle emitters centered on the local player's root. The part lives in
	-- a Workspace folder while on (so Roblox reliably renders the emitters),
	-- and moves under the ESP container while off (follows J2's ignored_folder/cg).
	do
		local aura_folder = Instance.new("Folder")
		aura_folder.Name = "Primordial BETA"

		local aura_part = Instance.new("Part")
		aura_part.Name = "aura_part"
		aura_part.Size = Vector3.new(0.01, 0.01, 0.01)
		aura_part.Transparency = 1
		aura_part.CanCollide = false
		aura_part.Anchored = true
		aura_part.Parent = container

		local aura_cs = ColorSequence.new

		local auras = {
			["Swirl"] = {
				{
					Brightness = 10,
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(0.101961, 1, 0.101961)), ColorSequenceKeypoint.new(1, Color3.new(0.101961, 1, 0.101961))},
					Lifetime = NumberRange.new(1, 1),
					LightEmission = 0.4,
					LockedToPart = true,
					Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
					Rate = 10,
					RotSpeed = NumberRange.new(200, 400),
					Rotation = NumberRange.new(-180, 180),
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 3.0625, 1.8806), NumberSequenceKeypoint.new(0.642055, 2, 1.76194), NumberSequenceKeypoint.new(1, 0.75, 0.75)},
					Speed = NumberRange.new(3, 6),
					SpreadAngle = Vector2.new(10, -10),
					Texture = "rbxassetid://8047533775",
					Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.170245, 0.7, 0.014881), NumberSequenceKeypoint.new(0.22546, 0.03125, 0.03125), NumberSequenceKeypoint.new(0.285276, 0, 0), NumberSequenceKeypoint.new(0.702454, 0, 0), NumberSequenceKeypoint.new(0.837423, 0.9125, 0.0601461), NumberSequenceKeypoint.new(1, 1, 0)},
				},
				{
					Brightness = 10,
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(0.129412, 1, 0.129412)), ColorSequenceKeypoint.new(1, Color3.new(0.129412, 1, 0.129412))},
					Lifetime = NumberRange.new(1, 1),
					LightEmission = 1,
					LockedToPart = true,
					Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
					Rate = 10,
					RotSpeed = NumberRange.new(100, 300),
					Rotation = NumberRange.new(-180, 180),
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 3.125, 0), NumberSequenceKeypoint.new(0.416533, 1.375, 1.375), NumberSequenceKeypoint.new(1, 0.9375, 0.9375)},
					Speed = NumberRange.new(3, 5),
					SpreadAngle = Vector2.new(10, -10),
					Texture = "rbxassetid://8047796070",
					Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.22546, 0.03125, 0.03125), NumberSequenceKeypoint.new(0.628834, 0.25625, 0.0593491), NumberSequenceKeypoint.new(0.837423, 0.9125, 0.0601461), NumberSequenceKeypoint.new(1, 1, 0)},
				},
				{
					Acceleration = Vector3.new(0, 3, 0),
					Brightness = 10,
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(0, 1, 0.14902)), ColorSequenceKeypoint.new(1, Color3.new(0, 1, 0.14902))},
					Drag = 3,
					Lifetime = NumberRange.new(0.3, 1),
					LightEmission = 1,
					Orientation = Enum.ParticleOrientation.VelocityParallel,
					Rate = 30,
					RotSpeed = NumberRange.new(-30, 30),
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.14687, 0.4375, 0.1875), NumberSequenceKeypoint.new(1, 0, 0)},
					Speed = NumberRange.new(5, 15),
					SpreadAngle = Vector2.new(180, -180),
					Texture = "rbxassetid://8611887361",
					ZOffset = -1,
				},
				{
					Acceleration = Vector3.new(0, 3, 0),
					Brightness = 10,
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(0, 1, 0.14902)), ColorSequenceKeypoint.new(1, Color3.new(0, 1, 0.14902))},
					Drag = 3,
					Lifetime = NumberRange.new(1, 1),
					LightEmission = 1,
					RotSpeed = NumberRange.new(-30, 30),
					Rotation = NumberRange.new(-30, 30),
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.149278, 0.6875, 0.6875), NumberSequenceKeypoint.new(1, 0, 0)},
					Speed = NumberRange.new(5, 10),
					SpreadAngle = Vector2.new(180, -180),
					Texture = "rbxassetid://8611887703",
					ZOffset = 2,
				},
			},
			["Bubble"] = {
				{
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0.588235)), ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.901961, 0.396078)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 0.588235))},
					Lifetime = NumberRange.new(0.333, 0.333),
					LightEmission = 1,
					LockedToPart = true,
					Rate = 12,
					Rotation = NumberRange.new(-180, 180),
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 4.8, 0.4), NumberSequenceKeypoint.new(1, 4.8, 0.4)},
					Speed = NumberRange.new(0, 0),
					Texture = "rbxassetid://1084955012",
					Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.883114, 0), NumberSequenceKeypoint.new(1, 1, 0)},
				},
				{
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.49481, Color3.new(1, 0.815686, 0.254902)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))},
					Lifetime = NumberRange.new(1, 1),
					LightEmission = 1,
					LockedToPart = true,
					Rate = 6,
					Rotation = NumberRange.new(-180, 180),
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 4, 0), NumberSequenceKeypoint.new(1, 4, 0)},
					Speed = NumberRange.new(0, 0),
					Texture = "rbxassetid://1084955488",
					Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.5, 0.7, 0), NumberSequenceKeypoint.new(1, 1, 0)},
				},
			},
			["Air"] = {
				{
					Brightness = 15,
					Lifetime = NumberRange.new(2, 2),
					LightEmission = 1,
					Orientation = Enum.ParticleOrientation.VelocityParallel,
					Rate = 75,
					RotSpeed = NumberRange.new(200, 200),
					ShapeInOut = Enum.ParticleEmitterShapeInOut.InAndOut,
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 7, 0), NumberSequenceKeypoint.new(1, 7, 0)},
					Speed = NumberRange.new(0.01, 0.01),
					SpreadAngle = Vector2.new(-360, 360),
					Squash = NumberSequence.new{NumberSequenceKeypoint.new(0, 0, 0.163934), NumberSequenceKeypoint.new(1, 0, 0)},
					Texture = "rbxassetid://10558425570",
					Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.500623, 0.93125, 0.01875), NumberSequenceKeypoint.new(1, 1, 0)},
					ZOffset = -1,
					LockedToPart = true,
				},
			},
			["Ritual"] = {
				{
					Brightness = 7,
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)), ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))},
					Lifetime = NumberRange.new(1, 1),
					LightEmission = 1,
					LockedToPart = true,
					Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
					Rate = 1,
					RotSpeed = NumberRange.new(300, 300),
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 5, 0), NumberSequenceKeypoint.new(1, 5, 0)},
					Speed = NumberRange.new(0.001, 0.001),
					Texture = "rbxassetid://8920073892",
					Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.166879, 0.617143, 0), NumberSequenceKeypoint.new(0.831847, 0.6, 0), NumberSequenceKeypoint.new(1, 1, 0)},
					ZOffset = 1,
				},
				{
					Brightness = 7,
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)), ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))},
					Lifetime = NumberRange.new(1, 1),
					LightEmission = 1,
					LockedToPart = true,
					Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
					Rate = 1,
					RotSpeed = NumberRange.new(360, 360),
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 5, 0), NumberSequenceKeypoint.new(1, 5, 0)},
					Speed = NumberRange.new(0.001, 0.001),
					Texture = "http://www.roblox.com/asset/?id=564938805",
					Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.107643, 0, 0), NumberSequenceKeypoint.new(0.828025, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)},
				},
			},
			["Rain"] = {
				{
					Color = aura_cs{ColorSequenceKeypoint.new(0, Color3.new(0.67451, 0.815686, 0.85098)), ColorSequenceKeypoint.new(1, Color3.new(0.67451, 0.815686, 0.85098))},
					EmissionDirection = Enum.NormalId.Bottom,
					Lifetime = NumberRange.new(200, 200),
					LightInfluence = 1,
					Rate = 100,
					Size = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.5, 0), NumberSequenceKeypoint.new(1, 0.5, 0)},
					Speed = NumberRange.new(25, 25),
					Texture = "rbxassetid://419625073",
					Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.5, 0), NumberSequenceKeypoint.new(1, 0.5, 0)},
					VelocityInheritance = 100,
				},
			},
		}

		local aura_offsets = {
			["Ritual"] = Vector3.new(0, -2.99, 0),
			["Rain"] = Vector3.new(0, 3.5, 0),
		}

		-- extra model-based auras (from "da hood (1).lua" local character section):
		-- each is a Roblox model whose BaseParts (named by body part) carry the
		-- ParticleEmitters. When selected we clone the model and re-parent its
		-- emitters onto the matching character part. Fires on those auras too.
		local model_aura_ids = {
			["starlight"] = "134645216613107",
			["heavenly"]  = "139300897520961",
			["ribbon"]    = "132069507632161",
			["sakura"]    = "81755778619404",
			["angel"]     = "97658130917593",
			["wind"]      = "80694081850877",
			["flow"]      = "119913533725648",
			["star"]      = "73754563740680",
		}

		local function get_model_aura(name)
			local id = model_aura_ids[name]
			if not id then return nil end
			for _ = 1, 3 do
				local ok, m = pcall(game.GetObjects, game, "rbxassetid://" .. id)
				if ok and m and m[1] then return m[1] end
				task.wait(0.1)
			end
			return nil
		end

		-- Track the model-aura emitters we attach to the character + leftover
		-- clones so teardown is exact (J2 pushes them onto a `particles` list).
		local AURA_MARK = "__PRIMORDIAL_AURA__"
		local model_emitters = {}
		local function clear_model_aura()
			for i = 1, #model_emitters do
				local e = model_emitters[i]
				if e then pcall(function() e:Destroy() end) end
			end
			model_emitters = {}
			for _, child in aura_folder:GetChildren() do
				if child ~= aura_part then pcall(function() child:Destroy() end) end
			end
		end

		local function get_selected()
			local cur = flags["local_aura_type"] or flags.local_aura_type
			if type(cur) == "table" then cur = cur[1] end
			if not cur then cur = "Swirl" end
			return cur
		end

		local function update_aura(selected, enabled)
			if type(selected) == "table" then selected = selected[1] end
			for _, p in aura_part:GetChildren() do
				pcall(function() p:Destroy() end)
			end
			clear_model_aura()
			local on = flags["local_aura"] or enabled
			if on then
				aura_folder.Parent = workspace
				local cfg = auras[selected]
				if cfg then
					if not model_aura_ids[selected] then
						aura_part.Parent = aura_folder
					end
					for _, props in cfg do
						local em = Instance.new("ParticleEmitter")
						for k, v in props do
							pcall(function() em[k] = v end)
						end
						em.Parent = aura_part
					end
				elseif model_aura_ids[selected] then
					task.spawn(function()
						task.wait()
						local model = get_model_aura(selected)
						local ch = lplr.Character
						local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
						if model and hrp then
							pcall(function()
								for _, part in model:GetChildren() do
									if part:IsA("BasePart") then
										local target = ch:FindFirstChild(part.Name)
										if target then
											for _, em in part:GetChildren() do
												if not em:IsA("BasePart") then
													em.Parent = target
													em.Name = AURA_MARK
													model_emitters[#model_emitters + 1] = em
												end
											end
										end
									end
								end
							end)
							pcall(function() model:Destroy() end)
						end
					end)
					aura_part.Parent = container
				end
			else
				aura_part.Parent = container
				pcall(function() if aura_folder.Parent == workspace then aura_folder.Parent = nil end end)
			end
			local size = selected == "Rain" and Vector3.new(5, 0.01, 5) or Vector3.new(0.01, 0.01, 0.01)
			aura_part.Size = size
		end

		local function aura_color()
			local c = flags["local_aura_color"] or flags.local_aura_color
			if type(c) == "table" then c = c[1] or c[2] end
			if type(c) ~= "Color3" then c = Color3.fromRGB(0, 255, 38) end
			return c
		end

		if aura_el and aura_el["on_toggle_change"] then
			conns[#conns + 1] = create_connection(aura_el["on_toggle_change"], function(v)
				update_aura(get_selected(), v)
			end)
		end
		if aura_type_dd and aura_type_dd["on_dropdown_change"] then
			conns[#conns + 1] = create_connection(aura_type_dd["on_dropdown_change"], function(v)
				update_aura(v, flags["local_aura"] or flags.local_aura)
			end)
		end
		if aura_color_pk and aura_color_pk["on_color_change"] then
			conns[#conns + 1] = create_connection(aura_color_pk["on_color_change"], function(c)
				local seq = ColorSequence.new{ColorSequenceKeypoint.new(0, c), ColorSequenceKeypoint.new(1, c)}
				local function tint(obj)
					if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
						pcall(function() obj.Color = seq end)
					end
					for _, d in obj:GetDescendants() do
						if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
							pcall(function() d.Color = seq end)
						end
					end
				end
				tint(aura_part)
				for _, e in model_emitters do
					tint(e)
				end
				for _, cfg in auras do
					for _, props in cfg do
						pcall(function() props.Color = seq end)
					end
				end
			end)
		end

		conns[#conns + 1] = lplr.CharacterAdded:Connect(function()
			task.spawn(function()
				local s = get_selected()
				if model_aura_ids[s] and (flags["local_aura"] or flags.local_aura) then
					task.wait()
					update_aura(s, true)
				end
			end)
		end)

		conns[#conns + 1] = RunService.RenderStepped:Connect(function()
			local ch = lplr.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			if hrp then
				pcall(function()
					aura_part.CFrame = CFrame.new(hrp.Position + (aura_offsets[get_selected()] or Vector3.new()))
				end)
			end
		end)

		-- set initial parent/build from the persisted flag
		task.spawn(function() update_aura(get_selected(), flags["local_aura"] or flags.local_aura) end)
	end

	conns[#conns + 1] = RunService.RenderStepped:Connect(function(delta)
		for _, d in loaded do
			pcall(d.render, d, delta)
		end
	end)

	getgenv().UniversalUnload = function()
			for p in loaded do destroy_esp(p) end
			for i = 1, #conns do
				pcall(function() conns[i]:Disconnect() end)
			end
			conns = nil
			if getgenv()._UNIVERSAL_MISC_CLEANUP then
				pcall(getgenv()._UNIVERSAL_MISC_CLEANUP)
				getgenv()._UNIVERSAL_MISC_CLEANUP = nil
			end
			container:Destroy()
			local af = workspace:FindFirstChild("Primordial BETA")
			if af then af:Destroy() end
			-- Remove the whole primordial menu/library in one shot via its official
			-- unload. It destroys every group/tab/section/element, disconnects
			-- the library's connections, unbinds actions, restores globals and
			-- nils itself (so no dead menu is left behind). Then drop the
			-- cached library handle so the next injection rebuilds everything
			-- from scratch with a single fresh menu.
			pcall(getgenv()._JUJU)
			if getgenv().juju then getgenv().juju = nil end
getgenv().UniversalUnload = nil
	end
end

-------------------------------------------------------------------
-- 5. MISC - desync features (misc tab)
-- executors expose raknet / setfflag / sethiddenproperty primitives,
-- so these are gated behind pcall and no-op cleanly on executors
-- that do not provide them. It's a toggle + keybind combo.
-------------------------------------------------------------------
do
	local wiring = {}
	local function wire_el(widgets, on, is_on)
		if widgets and widgets["on_toggle_change"] then
			wiring[#wiring + 1] = create_connection(widgets["on_toggle_change"], on)
		end
		if widgets and widgets["on_key_press"] then
			wiring[#wiring + 1] = create_connection(widgets["on_key_press"], function() on(not is_on()) end)
		end
	end
	local function add_misc_el(name, opts)
		local e = el(world, name, opts)
		table.insert(esp_elements, e)
		return e
	end

	-- ---- Evil desync (freeze) ----
	local frz_ = add_misc_el("Evil desync", {
		toggle = { flag = "misc_freeze", default = false },
		keybind = { flag = "misc_freeze_key", default = Enum.KeyCode.F },
	})
	local frz_enabled = false
	local frz_thread
	local function frz_loop()
		local Players = game:GetService("Players")
		local plr = Players.LocalPlayer
		local dsfs = 0
		local issync = false
		while frz_enabled and plr and plr.Character do
			if not issync then
				if dsfs <= 0 then
					issync = true
					local root = plr.Character:FindFirstChild("HumanoidRootPart")
					if root then
						pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", nil) end)
						task.wait(0.1)
						pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", root) end)
					end
					issync = false
					dsfs = 20
				else
					dsfs = dsfs - 1
					local root = plr.Character:FindFirstChild("HumanoidRootPart")
					if root then
						pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", root) end)
					end
				end
			end
			task.wait(1 / 240)
		end
	end
	local function frz_set(on)
		if on == frz_enabled then return end
		frz_enabled = on
		if on then
			pcall(function() setfflag("S2PhysicsSenderRate", "1000") end)
			if frz_thread == nil then frz_thread = task.spawn(frz_loop) end
		else
			frz_thread = nil
		end
	end
	wire_el(frz_, frz_set, function() return frz_enabled end)

	-- ---- Virtualizer (see server-side position) ----
	-- Anchored neon ghost of the local character pinned at the spot the
	-- server last confirmed. When desync engages the tracked
	-- position is latched, so the ghost shows exactly where the server
	-- still has you while the real body desyncs away.
	local Players = game:GetService("Players")
	local lplr = Players.LocalPlayer
	local RunService = game:GetService("RunService")
	local vir_ = add_misc_el("Virtualizer", {
		toggle = { flag = "misc_virtualizer", default = false },
	})
	local vir_on = false
	local vir_ghost = {}
	local vir_servercf
	local vir_prev_desync = false
	local vir_rs_conn
	local vir_char_conn
	local vir_build_lock = false

	local function vir_destroy_ghost()
		for _, data in pairs(vir_ghost) do
			pcall(function() data.ghost:Destroy() end)
		end
		vir_ghost = {}
	end

	local function vir_build()
		if vir_build_lock then return end
		vir_build_lock = true
		pcall(function()
			vir_destroy_ghost()
			local char = lplr.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not (char and root) then return end
			local rootcf = root.CFrame
			for _, p in ipairs(char:GetChildren()) do
				if p:IsA("BasePart") and p ~= root and p.Name ~= "HumanoidRootPart" then
					local ghost = Instance.new("Part")
					ghost.Size = p.Size
					ghost.Anchored = true
					ghost.CanCollide = false
					ghost.CastShadow = false
					ghost.Material = Enum.Material.Neon
					ghost.Color = Color3.fromRGB(194, 155, 165)
					ghost.Transparency = 0.5
					ghost.TopSurface = Enum.SurfaceType.Smooth
					ghost.BottomSurface = Enum.SurfaceType.Smooth
					ghost.Parent = workspace
					vir_ghost[p] = { ghost = ghost, offset = rootcf:Inverse() * p.CFrame }
				end
			end
		end)
		vir_build_lock = false
	end

	local function vir_set(on)
		if on == vir_on then return end
		vir_on = on
		if on then
			if vir_rs_conn == nil then
				vir_rs_conn = RunService.RenderStepped:Connect(function()
					if not vir_on then return end
					local char = lplr.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if not root then return end
					local desynced = frz_enabled
					if desynced ~= vir_prev_desync then
						vir_prev_desync = desynced
						if desynced then
							vir_servercf = root.CFrame
							vir_build()
						else
							vir_destroy_ghost()
							vir_servercf = nil
						end
					end
					if desynced and vir_servercf and next(vir_ghost) then
						for _, data in pairs(vir_ghost) do
							if data.ghost and data.ghost.Parent then
								data.ghost.CFrame = vir_servercf * data.offset
							end
						end
					end
				end)
			end
			if vir_char_conn == nil then
				vir_char_conn = lplr.CharacterAdded:Connect(function()
					if vir_on and vir_prev_desync then vir_build() end
				end)
			end
		else
			vir_destroy_ghost()
			vir_servercf = nil
			vir_prev_desync = false
			if vir_rs_conn then pcall(function() vir_rs_conn:Disconnect() end) vir_rs_conn = nil end
		end
	end
	wire_el(vir_, vir_set, function() return vir_on end)

	getgenv()._UNIVERSAL_MISC_CLEANUP = function()
		frz_set(false)
		vir_set(false)
		if vir_char_conn then pcall(function() vir_char_conn:Disconnect() end) vir_char_conn = nil end
		for i = 1, #wiring do
			pcall(function() wiring[i]:Disconnect() end)
		end
		wiring = nil
	end
end

menu.new_notification("Universal loaded", 1)

-------------------------------------------------------------------
-- 6. WATERMARK  (ported from PrisionLife/Primordial.lua)
-- Top-right watermark: "Primordial" in white, " beta" in an
-- oscillating warm-pink, then uid/fps/ping/time separators.
-------------------------------------------------------------------
do
	local RunService = game:GetService("RunService")
	local Stats      = game:GetService("Stats")
	local CoreGui    = game:GetService("CoreGui")

	local wm_gui = Instance.new("ScreenGui")
	wm_gui.Name = "PrimordialWatermark"
	wm_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	wm_gui.ResetOnSpawn = false
	wm_gui.IgnoreGuiInset = true
	wm_gui.DisplayOrder = 9999
	wm_gui.Parent = CoreGui

	local rgbstr = function(c)
		return string.format("rgb(%d,%d,%d)", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
	end

	local button = Color3.fromRGB(194, 155, 165)
	local white  = Color3.new(1, 1, 1)
	local black  = Color3.new(0, 0, 0)

	local corner_text = Instance.new("TextLabel")
	corner_text.Name = "corner_text"
	corner_text.Size = UDim2.new(0, 0, 0, 0)
	corner_text.AutomaticSize = Enum.AutomaticSize.XY
	corner_text.Position = UDim2.new(1, -5, 0, 5)
	corner_text.AnchorPoint = Vector2.new(1, 0)
	corner_text.BackgroundTransparency = 1
	corner_text.TextColor3 = white
	corner_text.TextStrokeTransparency = 0
	corner_text.TextStrokeColor3 = black
	corner_text.RichText = true
	corner_text.TextSize = 11
	corner_text.Font = Enum.Font.Gotham
	corner_text.TextXAlignment = Enum.TextXAlignment.Right
	corner_text.ZIndex = 99999
	corner_text.Parent = wm_gui

	local function time12h()
		local t = os.date("*t")
		return string.format("%d:%02d %s", (t.hour % 12 == 0 and 12 or t.hour % 12), t.min, t.hour >= 12 and "PM" or "AM")
	end

	local targetFPS, targetPing = 0, 0
	local fpsValue, pingValue = 0, 0
	local sine = 0

	local function smooth(cur, target, dt)
		local alpha = math.clamp(0.1 * dt * 60, 0, 1)
		return cur + (target - cur) * alpha
	end

	local conn = RunService.RenderStepped:Connect(function(dt)
		if dt <= 0 then return end
		sine += dt * 60
		targetFPS = math.floor(1 / dt)
		local pingItem = Stats.Network.ServerStatsItem["Data Ping"]
		if pingItem then targetPing = math.floor(pingItem:GetValue()) end

		-- smooth fps/ping so the numbers glide instead of jumping, then
		-- rewrite every frame (matches PrisionLife's corner watermark;
		-- the per-frame rewrite keeps the label from looking choppy/5fps)
		fpsValue = smooth(fpsValue, targetFPS, dt)
		pingValue = smooth(pingValue, targetPing, dt)
		local activeText = string.format(" | %d fps | %d ms | %s", math.floor(fpsValue), math.floor(pingValue), time12h())
		local interp = button:Lerp(black, math.abs(0.1 - 0.05 * math.cos(sine / 30)))
		corner_text.Text = string.format("Primordial<font color='%s'> beta</font>%s", rgbstr(interp), activeText)
	end)

	local prev_cleanup = getgenv()._UNIVERSAL_MISC_CLEANUP
	getgenv()._UNIVERSAL_MISC_CLEANUP = function()
		if prev_cleanup then pcall(prev_cleanup) end
		pcall(function() conn:Disconnect() end)
		pcall(function() wm_gui:Destroy() end)
	end
end


-------------------------------------------------------------------
-- 7. BRM5 FEATURES  (ported from Lean V1.7 | BRM5)
-- New group in the Primo menu: combat, movement, gun, esp, world
-------------------------------------------------------------------
local brm5 = menu.create_group("brm5")
menu:setup_configs(brm5)

local aim_tab      = brm5:create_tab("aim")
local trigger_tab  = brm5:create_tab("trigger")
local movement_tab = brm5:create_tab("movement")
local gun_tab      = brm5:create_tab("gun")
local esp_tab      = brm5:create_tab("esp")
local world_tab    = brm5:create_tab("world")

-- Column layout: side 1 = left, side 2 = right, size = height fraction, y = vertical offset fraction
-- NOTE: create_section lives on the GROUP (brm5:create_section(tab_name, ...)), not on the tab.
local aim_sec      = brm5:create_section("aim", "silent aim", 1, 0.55, 0)
local aim_fov_sec  = brm5:create_section("aim", "fov", 1, 0.45, 0.55)
local aim_pred_sec = brm5:create_section("aim", "prediction", 2, 0.35, 0)
local aim_chk_sec  = brm5:create_section("aim", "checks", 2, 0.65, 0.35)

local trig_sec     = brm5:create_section("trigger", "trigger bot", 1, 1, 0)
local trig_mag_sec = brm5:create_section("trigger", "magnetic", 2, 1, 0)

local mov_sec      = brm5:create_section("movement", "movement", 1, 0.55, 0)
local mov_res_sec  = brm5:create_section("movement", "restrictions", 2, 0.55, 0)
local mov_fly_sec  = brm5:create_section("movement", "fly", 1, 0.45, 0.55)
local mov_mod_sec  = brm5:create_section("movement", "modifier", 2, 0.45, 0.55)

local gun_hnd_sec  = brm5:create_section("gun", "handling", 1, 0.5, 0)
local gun_bal_sec  = brm5:create_section("gun", "ballistics", 2, 0.5, 0)
local gun_vis_sec  = brm5:create_section("gun", "appearance", 1, 0.5, 0.5)
local gun_trc_sec  = brm5:create_section("gun", "tracers", 2, 0.5, 0.5)

local esp_corp_sec = brm5:create_section("esp", "corpses", 1, 0.5, 0)
local esp_npc_sec  = brm5:create_section("esp", "npcs", 1, 0.5, 0.5)
local esp_zmb_sec  = brm5:create_section("esp", "zombies", 2, 0.45, 0)
local esp_set_sec  = brm5:create_section("esp", "settings", 2, 0.55, 0.45)

local wm_wld_sec   = brm5:create_section("world", "world", 1, 0.55, 0)
local wm_lit_sec   = brm5:create_section("world", "lighting", 2, 0.45, 0)
local wm_gfx_sec   = brm5:create_section("world", "graphics", 2, 0.55, 0.45)

-- Connections table for cleanup (separate from existing esp_elements cleanup)
local brm5_connections = {}

local function wire_signal(element, signal_name, callback)
	if element and element[signal_name] then
		brm5_connections[#brm5_connections + 1] = create_connection(element[signal_name], callback)
	end
end

local function brm5_el(section, name, opts)
	return section:create_element({ name = name }, opts)
end

-- Helper: create a key-picker proxy that Combat.KeyActive can read
local function makePicker(flag, mode)
	return setmetatable({}, { __index = function(_, k)
		if k == "Key" then return flags[flag] end
		if k == "Mode" then return mode end
	end })
end
-------------------------------------------------------------------
-- 7b. COMBAT ENGINE  (verbatim from b.txt lines 61-84, 94-603)
-------------------------------------------------------------------
local AimPlayers = game:GetService("Players")
local AimRunService = game:GetService("RunService")
local AimUIS = game:GetService("UserInputService")
    local AimLocalPlayer = AimPlayers.LocalPlayer
    local AimCamera = workspace.CurrentCamera
    local Silent = {
        Enabled=false,Targets={NPCs=true,Players=true},HitPart="Head",Hitscan=false,TeamCheck=false,VisibleCheck=true,
        MaxDistance=1000,HitChance=100,StickyAim=false,FOVEnabled=true,ShowFOV=true,FOV=120,
        FOVColor=Color3.fromRGB(150,80,255),FillFOV=false,FOVFillColor=Color3.fromRGB(150,80,255),
        FOVFillTransparency=.4,GradientFOV=false,
        GradientSpin=false,GradientSpinSpeed=1,
        GradientColorA=Color3.fromRGB(150,80,255),GradientColorB=Color3.fromRGB(255,110,60),
        AutoPrediction=true,BulletDropCompensation=true,
    }
    local TriggerBotSettings = {
        Enabled=false,Targets={NPCs=true,Players=true},TeamCheck=false,VisibleCheck=true,
        MaxDistance=1000,ReactionTime=50,ShootTime=100,Magnetic=false,
    }
    local Combat = {
        Silent=Silent,Trigger=TriggerBotSettings,active=true,actors={},samples={},parts={},
        sticky=nil,target=nil,nextScan=0,lastShot=0,targetSince=0,triggerActor=nil,
        connections={},drawings={},hookState="Waiting for game adapter",
    }
    getgenv().LeanCombat = Combat
    local SilentKeyPicker = makePicker("silent_key", "Hold")
    local TriggerKeyPicker = makePicker("trigger_key", "Hold")
    local HitPartOptions={"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm",
        "LeftUpperLeg","RightUpperLeg","Closest Part","Random"}
    local function aim_getMouseLocation() return AimUIS:GetMouseLocation() end
    function Combat.SetTargets(settings,selected)
        local result={}
        if type(selected)=="table" then
            for _,v in ipairs(selected) do if v=="NPCs" or v=="Players" or v=="Zombies" then result[v]=true end end
        end
        settings.Targets=result
        Combat.target=nil;Combat.sticky=nil;Combat.triggerActor=nil
    end
    function Combat.Service()
        if Combat.service then return Combat.service end
        if Combat.resolveAt and os.clock()<Combat.resolveAt then return nil end
        Combat.resolveAt=os.clock()+2
        for _,m in ipairs(getloadedmodules()) do
            if m.Name=="ClientService" then
                local ok,value=pcall(require,m)
                if ok and type(value)=="table" and value.Replicator then Combat.service=value;break end
            end
        end
        return Combat.service
    end
    function Combat.Kind(actor)
        local c=Combat.Service()
        local registry=c and c.Replicator and c.Replicator.Actors
        if not registry or not actor or not actor.UID or registry[actor.UID]~=actor then return nil end
        if actor.IsLocalPlayer or actor.Owner==AimLocalPlayer or actor==c.Replicator.LocalActor then return nil end
        if actor.Zombie==true then return "Zombies" end
        if actor.Owner==nil then return "NPCs" end
        if typeof(actor.Owner)=="Instance" and actor.Owner:IsA("Player") then return "Players" end
    end
    function Combat.IsAlive(actor)
        if not actor or actor.Alive==false then return false end
        if actor.Zombie then
            return type(actor.Health)=="table" or (type(actor.Health)=="number" and actor.Health>0)
        end
        return type(actor.Health)=="number" and actor.Health>0
    end
    function Combat.Allowed(actor,settings)
        local kind=Combat.Kind(actor)
        if not kind or not settings.Targets[kind] then return false end
        if not Combat.IsAlive(actor) then return false end
        if not actor.Character or not actor.Character.Parent then return false end
        if settings.TeamCheck and kind=="Players" and AimLocalPlayer.Team~=nil and actor.Owner.Team==AimLocalPlayer.Team then return false end
        return true
    end
    function Combat.Origin(camera)
        local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
        return me and me.Position or camera.CFrame.Position
    end
    function Combat.Sync(force)
        if not force and os.clock()<Combat.nextScan then return end
        Combat.nextScan=os.clock()+.05
        local c=Combat.Service();local registry=c and c.Replicator and c.Replicator.Actors or {}
        local list={};local now=os.clock()
        for _,a in pairs(registry) do
            if Combat.Kind(a) and typeof(a.Position)=="Vector3" then
                list[#list+1]=a
                local old=Combat.samples[a]
                local vel=Vector3.zero
                if old and old.model==a.Character and old.root==a.RootPart and now>old.time then
                    local measured=(a.Position-old.position)/(now-old.time)
                    if measured.Magnitude<300 then vel=old.velocity:Lerp(measured,.5) end
                end
                Combat.samples[a]={position=a.Position,time=now,velocity=vel,model=a.Character,root=a.RootPart}
                local parts,seen={},{}
                local function add(p)
                    if typeof(p)=="Instance" and p:IsA("BasePart") and a.Character
                        and p:IsDescendantOf(a.Character) and not seen[p] then
                        seen[p]=true;parts[#parts+1]=p
                    end
                end
                for _,p in pairs(a.Parts or {}) do add(p) end
                if a.Character then for _,p in ipairs(a.Character:GetChildren()) do add(p) end end
                Combat.parts[a]={model=a.Character,list=parts}
            end
        end
        for a in pairs(Combat.samples) do if not a.UID or registry[a.UID]~=a then Combat.samples[a]=nil;Combat.parts[a]=nil end end
        Combat.actors=list
    end
    function Combat.PartCFrame(actor,part)
        if not Combat.IsAlive(actor) then return part.CFrame end
        local root=actor.RootPart
        if not root or root:IsDescendantOf(workspace) then return part.CFrame end
        local pose=typeof(actor.CFrame)=="CFrame" and actor.CFrame.Rotation or CFrame.identity
        local actorFrame=pose+actor.Position
        return actorFrame*root.CFrame:ToObjectSpace(part.CFrame)
    end
    function Combat.PartPosition(actor,part)
        return Combat.PartCFrame(actor,part).Position
    end
    local combatRayParams=RaycastParams.new()
    combatRayParams.FilterType=Enum.RaycastFilterType.Exclude
    combatRayParams.IgnoreWater=false
    pcall(function() combatRayParams.CollisionGroup="9" end)
    function Combat.Visible(actor,point,camera)
        local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
        local excluded={camera}
        if me and me.Character then excluded[#excluded+1]=me.Character end
        combatRayParams.FilterDescendantsInstances=excluded
        local hit=workspace:Raycast(camera.CFrame.Position,point-camera.CFrame.Position,combatRayParams)
        if not hit then return true end
        if actor.Character and hit.Instance:IsDescendantOf(actor.Character) then return true end
        local replicator=c and c.Replicator
        local registry=replicator and replicator.Actors
        if not registry or registry[actor.UID]~=actor then return false end
        local uid=hit.Instance:GetAttribute("ActorUID")
        if uid==actor.UID then return true end
        if type(replicator.GetFromBodyPart)=="function" then
            local ok,resolvedUID=pcall(replicator.GetFromBodyPart,replicator,hit.Instance)
            if ok and resolvedUID==actor.UID then return true end
        end
        return false
    end
    function Combat.PickPart(actor,settings,camera,mouse)
        local parts=actor.Parts or {}
        local option=settings.HitPart
        local function valid(part)
            return typeof(part)=="Instance" and part:IsA("BasePart") and actor.Character
                and part:IsDescendantOf(actor.Character)
        end
        if option=="HumanoidRootPart" then
            return valid(actor.RootPart) and actor.RootPart or actor.Character:FindFirstChild("HumanoidRootPart")
        end
        if option=="Closest Part" or option=="Random" then
            local best,distance,pool=nil,math.huge,{}
            for _,part in ipairs((Combat.parts[actor] or {}).list or {}) do
                if valid(part) then
                    if option=="Random" then pool[#pool+1]=part else
                        local sp,on=camera:WorldToViewportPoint(Combat.PartPosition(actor,part))
                        if on then local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude;if d<distance then best,distance=part,d end end
                    end
                end
            end
            if option=="Random" then return #pool>0 and pool[math.random(#pool)] or nil end
            return best
        end
        local part=parts[option]
        if valid(part) then return part end
        part=actor.Character:FindFirstChild(option)
        if valid(part) then return part end
        part=actor.Character:FindFirstChild("Head")
        if valid(part) then return part end
        if valid(parts.Head) then return parts.Head end
        if valid(actor.RootPart) then return actor.RootPart end
    end
    function Combat.Predict(actor,part,settings,camera)
        return Combat.PartPosition(actor,part)
    end
    function Combat.FindTarget(settings,camera,mouse,sticky)
        Combat.Sync()
        camera=camera or workspace.CurrentCamera;mouse=mouse or aim_getMouseLocation()
        local origin=Combat.Origin(camera)
        local function candidate(a)
            if not Combat.Allowed(a,settings) or (a.Position-origin).Magnitude>settings.MaxDistance then return nil end
            local function check(part)
                if not part or not part.Parent or not part:IsDescendantOf(a.Character) then return nil end
                local point=Combat.PartPosition(a,part)
                local sp,on=camera:WorldToViewportPoint(point)
                if not on then return nil end
                local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude
                if settings.FOVEnabled and d>settings.FOV then return nil end
                if (settings.VisibleCheck or settings.Hitscan) and not Combat.Visible(a,point,camera) then return nil end
                return {actor=a,part=part,position=point,distance=d}
            end
            local preferred=Combat.PickPart(a,settings,camera,mouse)
            local selected=check(preferred)
            if selected or not settings.Hitscan then return selected end
            local best
            for _,part in ipairs((Combat.parts[a] or {}).list or {}) do
                if part~=preferred and part~=a.RootPart then
                    local hit=check(part)
                    if hit and (not best or hit.distance<best.distance) then best=hit end
                end
            end
            return best
        end
        if settings.StickyAim and sticky then local current=candidate(sticky);if current then return current end end
        local best
        for _,a in ipairs(Combat.actors) do
            local current=candidate(a)
            if current and (not best or current.distance<best.distance) then best=current end
        end
        return best
    end
    function Combat.RayBox(origin,direction,cf,size)
        local p=cf:PointToObjectSpace(origin)
        local d=cf:VectorToObjectSpace(direction)
        local half=size*.5;local lo,hi=0,math.huge
        for _,axis in ipairs({"X","Y","Z"}) do
            if math.abs(d[axis])<1e-6 then if math.abs(p[axis])>half[axis] then return nil end
            else
                local a,b=(-half[axis]-p[axis])/d[axis],(half[axis]-p[axis])/d[axis]
                if a>b then a,b=b,a end
                lo=math.max(lo,a);hi=math.min(hi,b);if hi<lo then return nil end
            end
        end
        return lo
    end
    function Combat.TriggerTarget(settings,camera,mouse)
        if settings.Magnetic then
            local selected=Combat.target
            if Silent.Enabled and Combat.silentActive and selected and Combat.Allowed(selected.actor,settings)
                and (selected.actor.Position-Combat.Origin(camera)).Magnitude<=settings.MaxDistance
                and (not settings.VisibleCheck or Combat.Visible(selected.actor,selected.position,camera)) then return selected.actor end
            return nil
        end
        Combat.Sync()
        local ray=camera:ViewportPointToRay(mouse.X,mouse.Y)
        local closest,nearest=nil,settings.MaxDistance
        for _,a in ipairs(Combat.actors) do
            if Combat.IsAlive(a) and a.RootPart and a.Character and a.Character.Parent then
                local delta=a.Position-a.RootPart.Position
                for _,p in ipairs((Combat.parts[a] or {}).list or {}) do
                    if p.Parent then
                        local hit=Combat.RayBox(ray.Origin,ray.Direction,Combat.PartCFrame(a,p),p.Size)
                        if hit and hit<nearest then nearest=hit;closest=a end
                    end
                end
            end
        end
        if not closest or not Combat.Allowed(closest,settings) then return nil end
        if settings.VisibleCheck and not Combat.Visible(closest,ray.Origin+ray.Direction*nearest,camera) then return nil end
        return closest
    end
    function Combat.KeyActive(picker,state)
        if not picker then return false end
        if picker.Mode=="Always" then return true end
        local key=picker.Key
        if type(key)=="string" then
            local mouseKeys={MB1=Enum.UserInputType.MouseButton1,MB2=Enum.UserInputType.MouseButton2,MB3=Enum.UserInputType.MouseButton3}
            key=mouseKeys[key] or key
            if type(key)=="string" and key~="NONE" then
                local name=key:match("([^%.]+)$")
                local ok,value=pcall(function() return Enum.KeyCode[name] end)
                if ok then key=value end
            end
        end
        local down=false
        if typeof(key)=="EnumItem" then
            if key.EnumType==Enum.UserInputType then down=AimUIS:IsMouseButtonPressed(key)
            elseif key.EnumType==Enum.KeyCode then down=AimUIS:IsKeyDown(key) end
        end
        if picker.Mode=="Toggle" then if down and not state.down then state.on=not state.on end;state.down=down;return state.on==true end
        state.down=down;return down
    end
    function Combat.TriggerStep(actor,now,fire)
        if actor~=Combat.triggerActor then Combat.triggerActor=actor;Combat.targetSince=now end
        if not actor then return false end
        if (now-Combat.targetSince)*1000<TriggerBotSettings.ReactionTime or (now-Combat.lastShot)*1000<TriggerBotSettings.ShootTime then return false end
        fire();Combat.lastShot=now;return true
    end
    function Combat.Fire()
        if mouse1click then mouse1click()
        elseif mouse1press and mouse1release then
            Combat.mouseHeld=true;mouse1press()
            task.delay(.02,function() if Combat.mouseHeld then Combat.mouseHeld=false;mouse1release() end end)
        end
    end
    local keyStates={silent={},trigger={}}
    function Combat.Frame()
        if not Combat.active then return end
        AimCamera=workspace.CurrentCamera
        if not AimCamera then return end
        if Silent.Enabled and not Combat.installed and (not Combat.retryAt or os.clock()>=Combat.retryAt) then
            Combat.retryAt=os.clock()+2
            Combat.Install()
        end
        local menuOpen = menu.is_menu_open()
        local blocked=menuOpen or AimUIS:GetFocusedTextBox()~=nil
        Combat.silentActive=Combat.KeyActive(SilentKeyPicker,keyStates.silent)
        local triggerActive=Combat.KeyActive(TriggerKeyPicker,keyStates.trigger)
        if not blocked and Silent.Enabled and Combat.silentActive then
            Combat.target=Combat.FindTarget(Silent,nil,nil,Combat.sticky)
            Combat.sticky=Combat.target and Combat.target.actor
        else Combat.target=nil;Combat.sticky=nil end
        if not blocked and TriggerBotSettings.Enabled and triggerActive then
            local actor=Combat.TriggerTarget(TriggerBotSettings,AimCamera,aim_getMouseLocation())
            Combat.TriggerStep(actor,os.clock(),Combat.Fire)
        else Combat.triggerActor=nil;Combat.targetSince=0 end
    end
    function Combat.Destroy()
        Combat.active=false;Silent.Enabled=false;TriggerBotSettings.Enabled=false;Combat.target=nil
        if Combat.Unhook then Combat.Unhook() end
        for _,c in ipairs(Combat.connections) do c:Disconnect() end
        for _,d in ipairs(Combat.drawings) do d:Remove() end
        Combat.connections={};Combat.drawings={}
    end
    function Combat.RedirectMuzzle(cf,target)
        if typeof(cf)~="CFrame" or not target or typeof(target.position)~="Vector3" then return cf end
        if (target.position-cf.Position).Magnitude<.001 then return cf end
        return CFrame.lookAt(cf.Position,target.position)
    end
    function Combat.Intercept(origin,point,velocity,speed,compensateDrop)
        if type(speed)~="number" or speed<=0 then return point,0 end
        local time=(point-origin).Magnitude/speed
        local aim=point
        for _=1,6 do
            aim=point+velocity*time+Vector3.new(0,compensateDrop and 16.1*time*time or 0,0)
            time=(aim-origin).Magnitude/speed
        end
        return aim,time
    end
    function Combat.ShotFrame(weapon,cf,target)
        if typeof(cf)~="CFrame" or not target then return cf end
        local tune=weapon._firearm and weapon._firearm.Tune
        local bulletService=Combat.bulletService
        if (not Silent.AutoPrediction and not Silent.BulletDropCompensation)
            or not tune or not bulletService then return Combat.RedirectMuzzle(cf,target) end
        local ok,speed=pcall(bulletService.GetInfo,bulletService,tune.Caliber,tune.Barrel)
        if not ok or type(speed)~="number" or speed<=0 then return Combat.RedirectMuzzle(cf,target) end
        local sample=Combat.samples[target.actor]
        local velocity=Silent.AutoPrediction and sample and sample.velocity or Vector3.zero
        local point=Combat.PartPosition(target.actor,target.part)
        local aim=Combat.Intercept(cf.Position,point,velocity,speed,Silent.BulletDropCompensation)
        local frame=Combat.RedirectMuzzle(cf,{position=aim})
        local actor=weapon._actor
        local zero=actor and actor.ADS and actor.ViewModel and actor.ViewModel.Zero
        if type(zero)=="table" then zero=zero[4] end
        if Silent.BulletDropCompensation and type(zero)=="number" then
            local angle=math.asin(math.clamp(zero*32.2/(speed*speed),-1,1))*.5
            frame=frame*CFrame.Angles(-angle,0,0)
        end
        return frame
    end
    function Combat.Install()
        if Combat.installed then return true end
        local class
        for _,module in ipairs(getloadedmodules()) do
            if module.Name=="FirearmInventory" then
                local ok,result=pcall(require,module)
                if ok and type(result)=="table" then class=result end
            elseif module.Name=="BulletService" then
                local ok,result=pcall(require,module)
                if ok and type(result)=="table" and type(result.GetInfo)=="function" then Combat.bulletService=result end
            end
        end
        if not class or type(class.Discharge)~="function" or type(class.GetMuzzleCFrame)~="function" then
            Combat.hookState="FirearmInventory not loaded yet"
            return false
        end
        local originalDischarge,originalMuzzle=class.Discharge,class.GetMuzzleCFrame
        local rawDischarge,rawMuzzle=rawget(class,"Discharge"),rawget(class,"GetMuzzleCFrame")
        local contexts=setmetatable({}, {__mode="k"})
        local function discharge(weapon,...)
            local thread=coroutine.running()
            local oldContext=contexts[thread]
            local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
            local selected
            if Combat.active and Silent.Enabled and Combat.silentActive and weapon._actor==me
                and not AimUIS:GetFocusedTextBox()
                and math.random(1,100)<=Silent.HitChance then
                selected=Combat.FindTarget(Silent,nil,nil,Combat.sticky)
            end
            contexts[thread]=selected and {weapon=weapon,target=selected} or nil
            local result=table.pack(pcall(originalDischarge,weapon,...))
            contexts[thread]=oldContext
            if not result[1] then error(result[2],0) end
            return table.unpack(result,2,result.n)
        end
        local function muzzle(weapon,...)
            local result=table.pack(originalMuzzle(weapon,...))
            local ctx=contexts[coroutine.running()]
            if Combat.active and Silent.Enabled and ctx and ctx.weapon==weapon and Combat.Allowed(ctx.target.actor,Silent) then
                result[1]=Combat.ShotFrame(weapon,result[1],ctx.target)
            end
            return table.unpack(result,1,result.n)
        end
        class.Discharge=discharge
        class.GetMuzzleCFrame=muzzle
        Combat.installed=true;Combat.hookState="Local firearm adapter ready"
        Combat.hookClass=class;Combat.hookDischarge=discharge;Combat.hookMuzzle=muzzle
        Combat.Unhook=function()
            if class.Discharge==discharge then class.Discharge=rawDischarge end
            if class.GetMuzzleCFrame==muzzle then class.GetMuzzleCFrame=rawMuzzle end
            Combat.installed=false
        end
        return true
    end
    local function silent_applyHooks() Combat.Install() end

-------------------------------------------------------------------
-- 7c. FOV RING + SILENT AIM CIRCLE  (b.txt 497-603)
-------------------------------------------------------------------
local GRAD_FOV_SEGMENTS = 48
local function makeGradientRing()
    local segments = {}
    if Drawing then
        for i = 1, GRAD_FOV_SEGMENTS do
            local ln = Drawing.new("Line")
            table.insert(Combat.drawings,ln)
            ln.Thickness = 2
            ln.Transparency = 1
            ln.Visible = false
            segments[i] = ln
        end
    end
    local ring = { segments = segments }
    function ring:hide()
        for _, ln in ipairs(self.segments) do ln.Visible = false end
    end
    local gui=Instance.new("ScreenGui")
    gui.Name="LeanFOVGradient";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false
    gui.DisplayOrder=0;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.Parent=(gethui and gethui()) or game:GetService("CoreGui")
    Combat.gradientGui=gui
    local fill=Instance.new("Frame")
    fill.Name="Fill";fill.AnchorPoint=Vector2.new(.5,.5)
    fill.BackgroundColor3=Color3.new(1,1,1);fill.BorderSizePixel=0
    fill.Visible=false;fill.Active=false;fill.Parent=gui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=fill
    local gradient=Instance.new("UIGradient");gradient.Parent=fill
    local hideOutline=ring.hide
    function ring:hide()
        hideOutline(self);fill.Visible=false
    end
    ring.phase=0
    function ring:draw(center,radius,colorA,colorB,filled,alpha,dt)
        if Silent.GradientSpin then
            self.phase=(self.phase+(dt or 0)*Silent.GradientSpinSpeed*math.pi*2)%(math.pi*2)
        else self.phase=0 end
        local n=#self.segments
        for i,ln in ipairs(self.segments) do
            local a0=(i-1)/n*math.pi*2
            local a1=i/n*math.pi*2
            ln.From=center+Vector2.new(math.cos(a0),math.sin(a0))*radius
            ln.To=center+Vector2.new(math.cos(a1),math.sin(a1))*radius
            ln.Color=colorA:Lerp(colorB,(math.sin((a0+a1)*.5-self.phase)+1)*.5)
            ln.Transparency=1;ln.Visible=true;ln.ZIndex=1
        end
        fill.Visible=filled and alpha>0
        fill.Position=UDim2.fromOffset(center.X,center.Y)
        fill.Size=UDim2.fromOffset(radius*2,radius*2)
        fill.BackgroundTransparency=1-math.clamp(alpha,0,1)
        gradient.Color=ColorSequence.new(colorA,colorB)
        gradient.Rotation=90+math.deg(self.phase)
    end
    return ring
end

local SilentFOVCircle, SilentFOVFill
if Drawing then
    SilentFOVFill = Drawing.new("Circle")
    table.insert(Combat.drawings,SilentFOVFill)
    SilentFOVFill.NumSides = 64
    SilentFOVFill.Filled = true
    SilentFOVFill.Color = Silent.FOVFillColor
    SilentFOVFill.Transparency = Silent.FOVFillTransparency
    SilentFOVFill.Visible = false

    SilentFOVCircle = Drawing.new("Circle")
    table.insert(Combat.drawings,SilentFOVCircle)
    SilentFOVCircle.Thickness = 1
    SilentFOVCircle.NumSides = 64
    SilentFOVCircle.Color = Silent.FOVColor
    SilentFOVCircle.Filled = false
    SilentFOVCircle.Transparency = 1
    SilentFOVCircle.Visible = false
end

local SilentGradRing = makeGradientRing()
brm5_connections[#brm5_connections + 1] = AimRunService.RenderStepped:Connect(function(dt)
    local show = Silent.Enabled and Silent.FOVEnabled and Silent.ShowFOV
    local mouse = aim_getMouseLocation()
    if SilentFOVFill then
        SilentFOVFill.Visible = show and Silent.FillFOV and not Silent.GradientFOV
        SilentFOVFill.Position = mouse
        SilentFOVFill.Radius = Silent.FOV
        SilentFOVFill.Color = Silent.FOVFillColor
        SilentFOVFill.Transparency = Silent.FOVFillTransparency
    end
    if show and Silent.GradientFOV then
        if SilentFOVCircle then SilentFOVCircle.Visible = false end
        SilentGradRing:draw(mouse, Silent.FOV, Silent.GradientColorA,
            Silent.GradientColorB, Silent.FillFOV, Silent.FOVFillTransparency, dt)
    else
        SilentGradRing:hide()
        if SilentFOVCircle then
            SilentFOVCircle.Visible = show
            SilentFOVCircle.Position = mouse
            SilentFOVCircle.Radius = Silent.FOV
            SilentFOVCircle.Color = Silent.FOVColor
        end
    end
end)

-------------------------------------------------------------------
-- 7d. COMBAT ACTIVATION (b.txt 1400-1406)
-------------------------------------------------------------------
table.insert(Combat.connections,AimRunService.RenderStepped:Connect(function()
    if Combat.Gun and Combat.Gun.active then Combat.Gun.Resolve();Combat.Gun.UpdateTune();Combat.Gun.UpdateVisuals() end
end))
table.insert(Combat.connections,AimRunService.RenderStepped:Connect(Combat.Frame))
Combat.Install()

-------------------------------------------------------------------
-- 7e. MOVEMENT ENGINE (b.txt 850-1047)
-------------------------------------------------------------------
do
    local M={active=true,hooks={},Speed=false,SpeedValue=24,Smoothing=false,Stamina=false,
        Penalties=false,Survival=false,Fly=false,FlySpeed=40,Modifier=false,Multiplier=2,Noclip=false,
        speedState={},flyState={},modifierState={}}
    Combat.Movement=M
    function M.IsLocal(ctrl)
        local service=Combat.Service()
        return M.active and service and service.Replicator and ctrl._localActor==service.Replicator.LocalActor
    end
    function M.CanMove(ctrl)
        local a=ctrl._localActor
        return a and not (a.Downed or a.Frozen or a.Forced or a.Rappelling or a.Ladder or ctrl.Goal or ctrl._forceCFrame or ctrl._startPhysics
            or (a.CurrentState and (a.CurrentState.Dragged or a.CurrentState.Emote)))
    end
    function M.Wrap(class,key,handler)
        local original=class[key]
        assert(type(original)=="function","Missing CharacterController."..key)
        local wrapper=function(ctrl,...)
            if M.IsLocal(ctrl) then return handler(original,ctrl,...) end
            return original(ctrl,...)
        end
        class[key]=wrapper
        table.insert(M.hooks,{class=class,key=key,original=original,wrapper=wrapper})
    end
    function M.Install(class)
        local standing
        local inspect=(debug and debug.getupvalues) or getupvalues
        if inspect then
            for _,fn in ipairs({class.new,class.Update}) do
                local ok,values=pcall(inspect,fn)
                if ok then
                    for _,value in pairs(values) do
                        if type(value)=="table" and type(value.CharacterHeightState)=="table" then
                            standing=value.CharacterHeightState.Standing
                            break
                        end
                    end
                end
                if standing~=nil then break end
            end
        end
        if standing==nil then warn("[Movements] Sprint options unavailable: controller enum could not be resolved") end
        for _,key in ipairs({"_accelerate","_decelerate","_exhaust","Update","_processNewPosition","_processMovementInput"}) do
            assert(type(class[key])=="function","Missing CharacterController."..key)
        end
        M.Wrap(class,"_processMovementInput",function(original,ctrl,input,dt)
            local actor=ctrl._localActor
            if standing~=nil and (M.OmniSprint or M.SprintCombat) and M.CanMove(ctrl) and ctrl.TrySprinting
                and ctrl.HeightState==standing and not ctrl.IsSliding and not ctrl.IsSwimming
                and not actor.CurrentState.Dragging and input.Magnitude>.01 then
                local directionOK=M.OmniSprint or input.Y<-.5
                local aimOK=M.SprintCombat or not actor.ADS
                if directionOK and aimOK then ctrl.IsSprinting=true end
            end
            return original(ctrl,input,dt)
        end)
        M.Wrap(class,"_accelerate",function(original,ctrl,dt,magnitude)
            local a=ctrl._localActor
            local saved={}
            local function change(object,key,value)
                table.insert(saved,{object=object,key=key,value=rawget(object,key)})
                object[key]=value
            end
            if M.Penalties then
                change(a,"SpeedPenalty",nil);change(a,"HitSlowness",nil)
                change(a,"CQB",nil);change(a,"Weight",0);change(ctrl,"_weightMulti",1)
            end
            if M.Survival or M.Penalties then
                local client=Combat.Service().LocalClient
                if client then
                    local full={getValue=function() return 1 end}
                    change(client,"Hunger",full);change(client,"Thirst",full)
                end
            end
            local result=table.pack(pcall(original,ctrl,M.Smoothing and 1000000 or dt,magnitude))
            for i=#saved,1,-1 do local v=saved[i];v.object[v.key]=v.value end
            if not result[1] then error(result[2],0) end
            if M.speedActive and M.CanMove(ctrl) then ctrl.MoveSpeed=M.SpeedValue*math.clamp(magnitude,0,1) end
            return table.unpack(result,2,result.n)
        end)
        M.Wrap(class,"_decelerate",function(original,ctrl,...)
            if M.Smoothing then ctrl.MoveSpeed=0;return end
            return original(ctrl,...)
        end)
        M.Wrap(class,"_exhaust",function(original,ctrl,...)
            if M.Stamina then ctrl._exhaustStart=tick()-2;ctrl._exhausted=tick()-1;return true end
            return original(ctrl,...)
        end)
        M.Wrap(class,"Update",function(original,ctrl,input,dt)
            if M.Stamina then ctrl._exhaustStart=tick()-2;ctrl._exhausted=tick()-1 end
            if M.Smoothing then ctrl._lastMovement=input end
            if not (M.flyActive and M.CanMove(ctrl)) then
                local result=table.pack(original(ctrl,input,dt))
                if M.SprintCombat and M.CanMove(ctrl) then
                    M.sprintActor=ctrl._localActor;M.sprintController=ctrl
                    ctrl._localActor.Sprinting=false
                else M.sprintActor=nil;M.sprintController=nil end
                return table.unpack(result,1,result.n)
            end
            local camera=workspace.CurrentCamera
            if not camera then return original(ctrl,input,dt) end
            local position=ctrl._position
            if ctrl._groundHitbox then position=ctrl._groundHitbox.CFrame:PointToWorldSpace(position) end
            local direction=Vector3.zero
            if not AimUIS:GetFocusedTextBox() then
                local function down(key) return AimUIS:IsKeyDown(key) and 1 or 0 end
                direction=camera.CFrame.LookVector*(down(Enum.KeyCode.W)-down(Enum.KeyCode.S))
                    +camera.CFrame.RightVector*(down(Enum.KeyCode.D)-down(Enum.KeyCode.A))
                    +Vector3.yAxis*(down(Enum.KeyCode.Space)-down(Enum.KeyCode.LeftControl))
            end
            if direction.Magnitude>1 then direction=direction.Unit end
            local speed=M.FlySpeed*(M.modifierActive and M.Multiplier or 1)
            local target=position+direction*speed*math.clamp(dt,0,.1)
            local grounded,normal=false,Vector3.yAxis
            if not M.Noclip then
                local oldPosition=ctrl._position
                ctrl._position=position
                local result=table.pack(pcall(ctrl._processNewPosition,ctrl,target))
                ctrl._position=oldPosition
                if not result[1] then error(result[2],0) end
                target,grounded,normal=result[2],result[3],result[4]
            end
            ctrl._position=target;ctrl._correctedPosition=target;ctrl._groundHitbox=nil
            ctrl.VelocityGravity=0;ctrl.MoveSpeed=0;ctrl.IsGrounded=grounded;ctrl.SlopeNormal=normal
            ctrl.IsSliding=false;ctrl.IsSprinting=false;ctrl._lastMovement=Vector2.zero
            local actor=ctrl._localActor
            actor.Platform=nil;actor.SimulatedPosition=target;actor.Grounded=grounded
            actor.Sliding=false;actor.Sprinting=false
        end)
    end
    function M.Destroy()
        M.active=false
        if M.sprintActor and M.sprintController then M.sprintActor.Sprinting=M.sprintController.IsSprinting end
        if M.connection then M.connection:Disconnect() end
        for i=#M.hooks,1,-1 do
            local h=M.hooks[i]
            if h.class[h.key]==h.wrapper then h.class[h.key]=h.original end
        end
        table.clear(M.hooks)
    end
    local oldDestroy=Combat.Destroy
    Combat.Destroy=function() M.Destroy();oldDestroy() end
    M.connection=AimRunService.Heartbeat:Connect(function()
        local focused=AimUIS:GetFocusedTextBox()~=nil
        if not focused then
            local speed=Combat.KeyActive(makePicker("movement_speed_key","Toggle"),M.speedState)
            local fly=Combat.KeyActive(makePicker("movement_fly_key","Toggle"),M.flyState)
            local boost=Combat.KeyActive(makePicker("movement_modifier_key","Hold"),M.modifierState)
            M.speedActive=M.Speed and speed;M.flyActive=M.Fly and fly
            M.modifierActive=M.flyActive and M.Modifier and boost
        else M.speedActive=false;M.flyActive=M.Fly and M.flyActive;M.modifierActive=false end
        if not M.installed and tick()> (M.nextResolve or 0) then
            M.nextResolve=tick()+2
            for _,module in ipairs(getloadedmodules()) do
                if module.Name=="CharacterController" then
                    local ok,class=pcall(require,module)
                    if ok and type(class)=="table" then
                        local installed,err=pcall(M.Install,class)
                        if installed then M.installed=true
                        else M.Destroy();warn("[Movements] "..tostring(err)) end
                    end
                    break
                end
            end
        end
    end)
end

-------------------------------------------------------------------
-- 7f. GUN ENGINE (b.txt 1049-1351)
-------------------------------------------------------------------
local Gun={NoRecoil=false,InstantADS=false,NoSway=false,NoSpread=false,SpreadReduction=100,
    UnlockModes=false,AutoReload=false,ForceHeadshot=false,active=true,originals={},hooks={},nextResolve=0,
    Visuals=false,Transparency=0,Material="Original",visualParts={},nextVisualScan=0,nextReload=0,
    WeaponColor=Color3.fromRGB(150,80,255),Tracers=false,TracerStyle="Lightning",
    TracerColor=Color3.fromRGB(150,80,255),TracerDuration=.6,TracerWidth=.08}
Combat.Gun=Gun
function Gun.RestoreTunes()
    for tune,fields in pairs(Gun.originals) do
        for key,saved in pairs(fields) do
            if tune[key]==saved.applied then tune[key]=saved.value end
        end
    end
    Gun.originals={}
end
function Gun.ApplyField(tune,key,enabled,transform)
    local fields=Gun.originals[tune]
    local saved=fields and fields[key]
    if not enabled then
        if saved then
            if tune[key]==saved.applied then tune[key]=saved.value end
            fields[key]=nil
        end
        return
    end
    if not fields then fields={};Gun.originals[tune]=fields end
    if not saved then saved={value=tune[key]};fields[key]=saved
    elseif tune[key]~=saved.applied then saved.value=tune[key] end
    saved.applied=transform(saved.value)
    tune[key]=saved.applied
end
function Gun.RestoreModes(weapon)
    local tune=weapon and weapon._firearm and weapon._firearm.Tune
    local saved=tune and Gun.originals[tune] and Gun.originals[tune].Firemodes
    local meta=weapon and weapon._item and weapon._item.MetaData
    if saved and type(saved.value)=="table" and meta then
        local mode=tune.Firemodes[meta.Mode]
        meta.Mode=table.find(saved.value,mode) or 1
    end
    if tune then Gun.ApplyField(tune,"Firemodes",false) end
end
function Gun.UpdateTune()
    local c=Combat.Service()
    local actor=c and c.Replicator and c.Replicator.LocalActor
    local weapon=actor and actor._inventory and actor._inventory[actor._equipped]
    local tune=weapon and weapon._firearm and weapon._firearm.Tune
    if Gun.modeWeapon and (Gun.modeWeapon~=weapon or not Gun.UnlockModes) then
        Gun.RestoreModes(Gun.modeWeapon);Gun.modeWeapon=nil
    end
    for old in pairs(Gun.originals) do
        if old~=tune then
            Gun.ApplyField(old,"Firemodes",false)
            Gun.ApplyField(old,"Barrel_Spread",false)
            Gun.originals[old]=nil
        end
    end
    if type(tune)~="table" then return end
    Gun.ApplyField(tune,"Barrel_Spread",Gun.NoSpread,function(base)
        return (base or 1)*(1-Gun.SpreadReduction/100)
    end)
    if type(tune.Firemodes)=="table" then
        Gun.ApplyField(tune,"Firemodes",Gun.UnlockModes,function(base)
            if Gun.modeBase~=base then
                Gun.modeBase=base;Gun.modeList=table.clone(base)
                for _,mode in ipairs({0,1,2,3}) do
                    if not table.find(Gun.modeList,mode) then table.insert(Gun.modeList,mode) end
                end
            end
            return Gun.modeList
        end)
        if Gun.UnlockModes then Gun.modeWeapon=weapon end
    end
    local meta=weapon._item and weapon._item.MetaData
    if Gun.AutoReload and weapon.Equipped and not weapon._reloading and meta
        and (not weapon._mag or (weapon._mag.Capacity or 0)<=0)
        and (tune.NoChamber or not meta.Chamber) and os.clock()>=Gun.nextReload
        and type(weapon._reload)=="function" then
        Gun.nextReload=os.clock()+1
        task.defer(function()
            if Gun.active and Gun.AutoReload and weapon.Equipped and not weapon._reloading then
                weapon:_reload(true)
            end
        end)
    end
end
function Gun.RestoreVisuals()
    for part,saved in pairs(Gun.visualParts) do
        if part.Parent then
            for key,value in pairs(saved.original) do
                if part[key]==saved.applied[key] then part[key]=value end
            end
        end
    end
    Gun.visualParts={};Gun.visualModel=nil;Gun.nextVisualScan=0
end
function Gun.UpdateVisuals()
    local c=Combat.Service()
    local actor=c and c.Replicator and c.Replicator.LocalActor
    local weapon=actor and actor._inventory and actor._inventory[actor._equipped]
    local model=weapon and weapon._firearm and actor.ViewModel and actor.ViewModel.CurrentModel
    if not Gun.Visuals or model~=Gun.visualModel then Gun.RestoreVisuals() end
    if not Gun.Visuals or not model or not model.Parent then return end
    Gun.visualModel=model
    if os.clock()>=Gun.nextVisualScan then
        Gun.nextVisualScan=os.clock()+.2
        for _,part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency<1 and not Gun.visualParts[part] then
                Gun.visualParts[part]={original={Material=part.Material,MaterialVariant=part.MaterialVariant,
                    Transparency=part.Transparency,Color=part.Color},applied={}}
            end
        end
    end
    for part,saved in pairs(Gun.visualParts) do
        if not part:IsDescendantOf(model) then
            if part.Parent then
                for key,value in pairs(saved.original) do
                    if part[key]==saved.applied[key] then part[key]=value end
                end
            end
            Gun.visualParts[part]=nil
        else
            local material=Gun.Material=="Original" and saved.original.Material or Enum.Material[Gun.Material]
            local values={Material=material,MaterialVariant=Gun.Material=="Original" and saved.original.MaterialVariant or "",
                Transparency=Gun.Transparency/100,Color=Gun.Material~="Original" and Gun.WeaponColor or saved.original.Color}
            for key,value in pairs(values) do
                saved.applied[key]=value
                if part[key]~=value then part[key]=value end
            end
        end
    end
end
function Gun.ClearTracers()
    if Gun.tracerFolder then Gun.tracerFolder:Destroy();Gun.tracerFolder=nil end
end
function Gun.TracerPoints(from,to,style,random)
    local length=(to-from).Magnitude
    if length<.01 then return {} end
    local cf=CFrame.lookAt(from,to)
    local turns=math.clamp(length/18,2,5)
    local smooth=style=="DNA"
    local count=style=="Line" and 1 or (smooth and math.ceil(turns*12) or math.clamp(math.ceil(length/3),12,48))
    local strands=style=="DNA" and 2 or 1
    local paths={}
    for strand=1,strands do
        local points={}
        for i=0,count do
            local t=i/count
            local offset=Vector3.zero
            if i>0 and i<count then
                if style=="Lightning" then
                    local radius=math.min(length*.025,.65)
                    offset=cf.RightVector*random:NextNumber(-radius,radius)+cf.UpVector*random:NextNumber(-radius,radius)
                elseif style=="DNA" then
                    local angle=t*math.pi*2*turns+(strand-1)*math.pi*2/strands
                    local envelope=math.sin(math.min(1,math.min(t,1-t)*8)*math.pi*.5)
                    local radius=math.min(length*.03,.45)*envelope
                    offset=(cf.RightVector*math.cos(angle)+cf.UpVector*math.sin(angle))*radius
                end
            end
            points[#points+1]=from:Lerp(to,t)+offset
        end
        paths[#paths+1]=points
    end
    return paths
end
function Gun.DrawTracer(from,to)
    if not Gun.active or not Gun.Tracers or typeof(from)~="Vector3" or typeof(to)~="Vector3" then return end
    local paths=Gun.TracerPoints(from,to,Gun.TracerStyle,Random.new())
    if #paths==0 or not workspace.CurrentCamera then return end
    if not Gun.tracerFolder then
        Gun.tracerFolder=Instance.new("Folder");Gun.tracerFolder.Name="LeanGunTracers"
    end
    Gun.tracerFolder.Parent=workspace.CurrentCamera
    local existing=Gun.tracerFolder:GetChildren()
    if #existing>=24 then existing[1]:Destroy() end
    local anchor=Instance.new("Part")
    anchor.Name="Tracer";anchor.Anchored=true;anchor.Transparency=1;anchor.Size=Vector3.one*.01
    anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.CastShadow=false
    anchor.CFrame=CFrame.new(from);anchor.Parent=Gun.tracerFolder
    local function connect(a,b,width)
        local beam=Instance.new("Beam")
        beam.Attachment0=a;beam.Attachment1=b;beam.FaceCamera=true
        beam.Width0=width;beam.Width1=width;beam.Segments=1
        beam.Color=ColorSequence.new(Gun.TracerColor);beam.LightEmission=1;beam.LightInfluence=0
        beam.Transparency=NumberSequence.new(0);beam.Parent=anchor
        game:GetService("TweenService"):Create(beam,TweenInfo.new(Gun.TracerDuration),{Width0=0,Width1=0}):Play()
    end
    local attachments={}
    for index,points in ipairs(paths) do
        local list={};attachments[index]=list
        for i,point in ipairs(points) do
            local a=Instance.new("Attachment");a.Position=point-from;a.Parent=anchor;list[i]=a
            if i>1 then connect(list[i-1],a,Gun.TracerWidth) end
        end
    end
    if Gun.TracerStyle=="DNA" and #attachments==2 then
        for i=4,#attachments[1]-3,3 do connect(attachments[1][i],attachments[2][i],Gun.TracerWidth*.35) end
    end
    game:GetService("Debris"):AddItem(anchor,Gun.TracerDuration)
end
function Gun.Hook(class,key,make)
    local original=class[key]
    if type(original)~="function" then return false end
    local raw=rawget(class,key)
    local wrapper=make(original)
    class[key]=wrapper
    Gun.hooks[#Gun.hooks+1]={class=class,key=key,raw=raw,wrapper=wrapper}
    return true
end
function Gun.Resolve()
    if os.clock()<Gun.nextResolve then return end
    Gun.nextResolve=os.clock()+2
    local service=Combat.Service()
    local replicator=service and service.Replicator
    if replicator and replicator~=Gun.effectsReplicator and type(replicator._bulletEffects)=="function" then
        if Gun.Hook(replicator,"_bulletEffects",function(original)
            return function(self,from,to,part,normal,material,caliber,isLocal,...)
                local result=table.pack(original(self,from,to,part,normal,material,caliber,isLocal,...))
                if isLocal then
                    local ok,err=pcall(Gun.DrawTracer,from,to)
                    if not ok then Gun.tracerError=tostring(err) end
                end
                return table.unpack(result,1,result.n)
            end
        end) then Gun.effectsReplicator=replicator end
    end
    if replicator and replicator~=Gun.impactReplicator and type(replicator._bulletProcess)=="function" then
        if Gun.Hook(replicator,"_bulletProcess",function(original)
            return function(self,uid,replicate,position,part,normal,material,elapsed,...)
                if Gun.active and Gun.ForceHeadshot and replicate and part then
                    local actorUID,actor=self:GetFromBodyPart(part)
                    local kind=actor and Combat.Kind(actor)
                    local head=actor and actor.Parts and actor.Parts.Head
                    local friendly=kind=="Players" and actor.Owner.Team~=nil
                        and actor.Owner.Team==AimLocalPlayer.Team
                    if actorUID and kind and not friendly and head and head.Parent
                        and head:IsDescendantOf(actor.Character) then
                        part=head
                    end
                end
                return original(self,uid,replicate,position,part,normal,material,elapsed,...)
            end
        end) then Gun.impactReplicator=replicator end
    end
    for _,m in ipairs(getloadedmodules()) do
        if m.Name=="Recoiler" and not Gun.recoiler then
            local ok,class=pcall(require,m)
            if ok and type(class)=="table" then
                Gun.Hook(class,"GetViewmodelAdjustment",function(original)
                    return function(self,...)
                        if Gun.active and Gun.NoRecoil then return CFrame.identity end
                        return original(self,...)
                    end
                end)
                Gun.Hook(class,"GetCameraAdjustment",function(original)
                    return function(self,...)
                        if Gun.active and Gun.NoRecoil then return CFrame.identity,0 end
                        return original(self,...)
                    end
                end)
                Gun.recoiler=true
            end
        elseif m.Name=="ViewmodelClass" and not Gun.viewmodel then
            local ok,class=pcall(require,m)
            if ok and type(class)=="table" then
                Gun.viewmodel=Gun.Hook(class,"Update",function(original)
                    return function(vm,...)
                        local c=Combat.Service()
                        local localActor=c and c.Replicator and c.Replicator.LocalActor
                        if not Gun.active or vm.Actor~=localActor then return original(vm,...) end
                        if Gun.InstantADS then
                            vm.ADSLerp=(localActor.ADS and not vm.Reloading and not localActor.Sliding) and 1 or 0
                        end
                        local sway,kick=vm._swaySpring,vm.Kick
                        if Gun.NoSway and sway then
                            vm._swaySpring={Position={ToCFrame=function() return CFrame.identity end}}
                        end
                        if Gun.NoRecoil and kick then vm.Kick={Position=Vector3.zero} end
                        local result=table.pack(pcall(original,vm,...))
                        vm._swaySpring=sway;vm.Kick=kick
                        if not result[1] then error(result[2],0) end
                        return table.unpack(result,2,result.n)
                    end
                end)
            end
        end
    end
end
function Gun.Destroy()
    Gun.active=false
    Gun.RestoreModes(Gun.modeWeapon)
    Gun.RestoreTunes()
    Gun.RestoreVisuals()
    Gun.ClearTracers()
    for _,h in ipairs(Gun.hooks) do
        if h.class[h.key]==h.wrapper then h.class[h.key]=h.raw end
    end
    Gun.hooks={}
end
local destroyCombat=Combat.Destroy
Combat.Destroy=function() Gun.Destroy();destroyCombat() end

-------------------------------------------------------------------
-- 7g. SENSE ESP ENGINE (b.txt 1408-1838, esp_ → sense_ for shared settings)
-------------------------------------------------------------------
local Sense = (function()
    local E = {
        _hasLoaded = false, objects = {}, errors = {}, scanAt = 0,
        sharedSettings = {textSize=13, textFont=2, limitDistance=false, maxDistance=1000,
            teamBasedColor=false, neutralColor=Color3.fromRGB(100,220,150)},
        teamSettings = {}, chams = {}, advanced = {},
    }
    local white, black = Color3.new(1,1,1), Color3.new(0,0,0)
    local t = {
        enabled=true, box=false, box3d=false, boxColor={white,1}, box3dColor={white,1},
        boxOutline=true, boxOutlineColor={black,1}, boxOutlineThickness=1,
        boxFill=false, boxFillColor={Color3.fromRGB(150,80,255),.2},
        healthBar=false, healthyColor=Color3.new(0,1,0), dyingColor=Color3.new(1,0,0),
        healthBarOutline=true, healthText=false, healthTextColor={white,1}, healthTextOutline=true,
        name=false, nameColor={white,1}, nameOutline=true,
        weapon=false, weaponColor={white,1}, weaponOutline=true,
        distance=false, distanceColor={white,1}, distanceOutline=true,
        tracer=false, tracerOrigin="Bottom", tracerColor={white,1}, tracerOutline=true,
        offScreenArrow=false, offScreenArrowSize=15, offScreenArrowRadius=150,
        offScreenArrowColor={white,1},
    }
    E.teamSettings.npc = t
    E.teamSettings.players={}
    for k,v in pairs(t) do E.teamSettings.players[k]=type(v)=="table" and table.clone(v) or v end
    E.teamSettings.players.enabled=false
    E.teamSettings.players.teamCheck=false
    E.teamSettings.players.boxOutlineThickness=1
    E.chams.npc = {enabled=false, visibleColor=Color3.fromRGB(0,255,100),visibleIntensity=.85,
        occludedColor=white,occludedIntensity=.25}
    E.advanced.npc = {nameType="Name",skeleton=false,skeletonColor=white}
    E.chams.players=table.clone(E.chams.npc)
    E.advanced.players=table.clone(E.advanced.npc)
    for _,kind in ipairs({"zombies","corpses"}) do
        E.teamSettings[kind]={}
        for k,v in pairs(t) do E.teamSettings[kind][k]=type(v)=="table" and table.clone(v) or v end
        E.teamSettings[kind].enabled=false
        E.teamSettings[kind].name=true
        E.teamSettings[kind].distance=true
        E.chams[kind]=table.clone(E.chams.npc)
        E.advanced[kind]=table.clone(E.advanced.npc)
    end
    local service, resolveAt, connection, anchor
    local signs = {Vector3.new(-1,-1,-1),Vector3.new(-1,1,-1),Vector3.new(-1,1,1),Vector3.new(-1,-1,1),
        Vector3.new(1,-1,-1),Vector3.new(1,1,-1),Vector3.new(1,1,1),Vector3.new(1,-1,1)}
    local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.IgnoreWater = true
    function E.Service()
        if service then return service end
        if resolveAt and os.clock() < resolveAt then return nil end
        resolveAt = os.clock()+2
        for _, module in ipairs(getloadedmodules()) do
            if module.Name == "ClientService" then
                local ok, value = pcall(require,module)
                if ok and type(value)=="table" and value.Replicator then service=value; break end
            end
        end
        return service
    end
    function E.IsNPC(actor)
        local c = E.Service()
        local registry = c and c.Replicator and c.Replicator.Actors
        return type(actor)=="table" and registry and actor.UID and registry[actor.UID]==actor
            and actor.Owner==nil and actor.IsLocalPlayer~=true
            and typeof(actor.Character)=="Instance" and actor.Character:IsA("Model")
    end
    function E.IsPlayer(actor)
        local c=E.Service();local registry=c and c.Replicator and c.Replicator.Actors
        return type(actor)=="table" and registry and actor.UID and registry[actor.UID]==actor
            and typeof(actor.Owner)=="Instance" and actor.Owner:IsA("Player")
            and actor.Owner~=AimLocalPlayer and actor.IsLocalPlayer~=true
            and typeof(actor.Character)=="Instance" and actor.Character:IsA("Model")
    end
    function E.Kind(actor)
        if E.IsNPC(actor) or E.IsPlayer(actor) then
            if not Combat.IsAlive(actor) then return "corpses" end
            if actor.Zombie then return "zombies" end
        end
        if E.IsNPC(actor) then return "npc" end
        if E.IsPlayer(actor) then return "players" end
    end
    local function newDrawing(o,key,class,props)
        local d = (E.DrawingFactory or Drawing.new)(class)
        d.Visible=false
        d.Transparency=1
        for k,v in pairs(props or {}) do d[k]=v end
        o.drawings[key]=d
        return d
    end
    local function drawing(o,key,class,props)
        return o.drawings[key] or newDrawing(o,key,class,props)
    end
    local function hide(o)
        for _,d in pairs(o.drawings) do d.Visible=false end
        for _,d in pairs(o.adornments) do d.Visible=false end
    end
    local function destroy(o)
        for _,d in pairs(o.drawings) do d:Remove() end
        for _,d in pairs(o.adornments) do d:Destroy() end
    end
    local function rig(o)
        o.parts={}; o.links={}
        local seen={}
        for _,part in pairs(o.actor.Parts or {}) do
            if typeof(part)=="Instance" and part:IsA("BasePart") and part:IsDescendantOf(o.model) then
                o.parts[#o.parts+1]=part; seen[part]=true
            end
        end
        if #o.parts==0 then
            for _,part in ipairs(o.model:GetChildren()) do
                if part:IsA("BasePart") and part~=o.actor.RootPart then o.parts[#o.parts+1]=part;seen[part]=true end
            end
        end
        for _,joint in ipairs(o.model:GetDescendants()) do
            if joint:IsA("Motor6D") and seen[joint.Part0] and seen[joint.Part1] then
                o.links[#o.links+1]={joint.Part0,joint.Part1}
            elseif joint:IsA("BallSocketConstraint") or joint:IsA("HingeConstraint") then
                local a,b=joint.Attachment0,joint.Attachment1
                if a and b and seen[a.Parent] and seen[b.Parent] then o.links[#o.links+1]={a.Parent,b.Parent} end
            elseif joint:IsA("Bone") and joint.Parent:IsA("Bone") then
                o.links[#o.links+1]={joint.Parent,joint}
            end
        end
    end
    function E.Sync(force)
        if not force and os.clock()<E.scanAt then return end
        E.scanAt=os.clock()+.4
        for actor,o in pairs(E.objects) do
            if not E.Kind(actor) or actor.Character~=o.model or not o.model.Parent then
                destroy(o);E.objects[actor]=nil
            end
        end
        local c=E.Service()
        for _,actor in pairs(c and c.Replicator and c.Replicator.Actors or {}) do
            if E.Kind(actor) and actor.Character.Parent then
                local o=E.objects[actor]
                if not o then
                    o={actor=actor,model=actor.Character,drawings={},adornments={},nextRay=0}
                    E.objects[actor]=o;rig(o)
                else rig(o) end
            end
        end
    end
    local function color(value)
        if typeof(value)=="Color3" then return value,1 end
        if type(value)=="table" then return value[1],math.clamp(value[2] or 1,0,1) end
        return white,1
    end
    function E.TeamColor(actor)
        if E.IsPlayer(actor) and actor.Owner.Team then return actor.Owner.Team.TeamColor.Color end
        for _,value in pairs({actor.TeamColor,actor.FactionColor,actor.Team,actor.Faction,actor.Company}) do
            if typeof(value)=="Color3" then return value end
            if typeof(value)=="BrickColor" then return value.Color end
            if typeof(value)=="Instance" and value:IsA("Team") then return value.TeamColor.Color end
            if type(value)=="table" then
                if typeof(value.Color)=="Color3" then return value.Color end
                if typeof(value.TeamColor)=="BrickColor" then return value.TeamColor.Color end
            end
        end
        return E.sharedSettings.neutralColor
    end
    local function style(d,value,override)
        local c,a=color(value);d.Color=override or c;d.Transparency=a;d.Visible=a>0
    end
    local function clipLine(a,b)
        local v=workspace.CurrentCamera.ViewportSize
        local delta=b-a
        local lo,hi=0,1
        for _,test in ipairs({{-delta.X,a.X},{delta.X,v.X-a.X},{-delta.Y,a.Y},{delta.Y,v.Y-a.Y}}) do
            local p,q=test[1],test[2]
            if math.abs(p)<1e-8 then if q<0 then return nil end
            else
                local r=q/p
                if p<0 then lo=math.max(lo,r) else hi=math.min(hi,r) end
                if lo>hi then return nil end
            end
        end
        return a+delta*lo,a+delta*hi
    end
    local function line(o,key,a,b,value,thickness,override)
        a,b=clipLine(a,b)
        if not a then return nil end
        local d=drawing(o,key,"Line")
        d.From=a;d.To=b;d.Thickness=thickness or 1;style(d,value,override)
        return d
    end
    local function square(o,key,pos,size,value,filled,thickness,override)
        local view=workspace.CurrentCamera.ViewportSize
        local corner=(pos+size):Min(view)
        pos=pos:Max(Vector2.zero)
        size=corner-pos
        if size.X<=0 or size.Y<=0 then return nil end
        local d=drawing(o,key,"Square")
        d.Position=pos;d.Size=size;d.Filled=filled;d.Thickness=thickness or 1;style(d,value,override)
        return d
    end
    local function textAt(o,key,value,pos,col,outline,override)
        local view=workspace.CurrentCamera.ViewportSize
        if pos.X<0 or pos.Y<0 or pos.X>view.X or pos.Y>view.Y then return end
        local d=drawing(o,key,"Text")
        d.Text=tostring(value);d.Position=pos;d.Size=E.sharedSettings.textSize
        d.Font=E.sharedSettings.textFont;d.Center=true;d.Outline=outline;d.OutlineColor=black
        style(d,col,override)
    end
    local function partPosition(p)
        return p:IsA("Bone") and p.WorldPosition or p.Position
    end
    local function bodyBounds(o,delta,position)
        local lo,hi
        for _,p in ipairs(o.parts) do
            if p.Parent then
                local cf=p.CFrame;local h=p.Size*.5
                local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
                local extent=Vector3.new(math.abs(r.X)*h.X+math.abs(u.X)*h.Y+math.abs(l.X)*h.Z,
                    math.abs(r.Y)*h.X+math.abs(u.Y)*h.Y+math.abs(l.Y)*h.Z,
                    math.abs(r.Z)*h.X+math.abs(u.Z)*h.Y+math.abs(l.Z)*h.Z)
                local center=p.Position+delta
                lo=lo and lo:Min(center-extent) or center-extent
                hi=hi and hi:Max(center+extent) or center+extent
            end
        end
        if not lo then return position,Vector3.new(2,5,2) end
        return (lo+hi)*.5,hi-lo
    end
    function E.Weapon(actor)
        local item=actor._inventory and actor._inventory[actor._equipped]
        if not item then return "Unarmed" end
        local model=item._heroModel or item._lodModel
        if typeof(model)=="Instance" then return model.Name:gsub("^AI_","") end
        local name=item._item and item._item.Name
        return name and name:gsub("^FirearmPrimary",""):gsub("^AI_","") or "Unknown"
    end
    local function chams(o,camera,delta,position,teamColor)
        local cfg=E.chams[E.Kind(o.actor)]
        if not cfg then return end
        if not cfg.enabled then return end
        if os.clock()>=o.nextRay then
            o.nextRay=os.clock()+.12
            local c=E.Service();local me=c and c.Replicator and c.Replicator.LocalActor
            local ignore={o.model,workspace.CurrentCamera}
            if me and me.Character then ignore[#ignore+1]=me.Character end
            ray.FilterDescendantsInstances=ignore
            o.partClear={}
            for _,p in ipairs(o.parts) do
                if p:IsDescendantOf(o.model) then
                    local cf=Combat.PartCFrame(o.actor,p)
                    for _,offset in ipairs({0,.35,-.35}) do
                        local point=cf:PointToWorldSpace(Vector3.new(0,p.Size.Y*offset,0))
                        local hit=workspace:Raycast(camera.CFrame.Position,point-camera.CFrame.Position,ray)
                        if not hit then o.partClear[p]=true;break end
                    end
                end
            end
        end
        if not anchor then
            anchor=Instance.new("Part");anchor.Name="LeanNPCOverlayAnchor"
            anchor.Size=Vector3.new(.01,.01,.01);anchor.CFrame=CFrame.identity
            anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false
            anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false
        end
        anchor.Parent=workspace.CurrentCamera
        for i,p in ipairs(o.parts) do
            if p:IsDescendantOf(o.model) and p~=o.actor.RootPart then
                local clear=o.partClear and o.partClear[p]
                local col=clear and cfg.visibleColor or cfg.occludedColor
                local alpha=clear and cfg.visibleIntensity or cfg.occludedIntensity
                local ad=o.adornments[i]
                if not ad then
                    ad=Instance.new("BoxHandleAdornment");ad.Name="LeanNPCChams"
                    ad.Adornee=anchor;ad.AlwaysOnTop=true;ad.ZIndex=3;ad.Parent=anchor
                    o.adornments[i]=ad
                end
                ad.Size=p.Size;ad.CFrame=Combat.PartCFrame(o.actor,p);ad.Color3=teamColor or col
                ad.Transparency=1-math.clamp(alpha,0,1);ad.Visible=alpha>0
            end
        end
    end
    function E.RenderActor(o,camera,origin)
        hide(o)
        local a=o.actor
        local kind=E.Kind(a)
        if not kind then return end
        local t=E.teamSettings[kind]
        if kind=="players" and t.teamCheck and AimLocalPlayer.Team~=nil and a.Owner.Team==AimLocalPlayer.Team then return end
        if not t.enabled or not E.Kind(a) or a.Character~=o.model or not o.model.Parent
            or (kind~="corpses" and not Combat.IsAlive(a)) then return end
        local root=a.RootPart
        local position=a.Position or (root and root.Position)
        if kind=="corpses" then
            if not o.model:IsDescendantOf(workspace) then return end
            root=nil
            position=o.model:GetPivot().Position
        end
        if typeof(position)~="Vector3" then return end
        local dist=(position-origin).Magnitude
        local shared=E.sharedSettings
        if shared.limitDistance and dist>shared.maxDistance then return end
        local adv=E.advanced[kind]
        local override=shared.teamBasedColor and E.TeamColor(a) or nil
        local delta=root and position-root.Position or Vector3.zero
        local view=camera.ViewportSize
        local sp,onScreen=camera:WorldToViewportPoint(position)
        if not onScreen and t.offScreenArrow then
            local rel=camera.CFrame:PointToObjectSpace(position)
            local direction=Vector2.new(rel.X,rel.Z)
            if direction.Magnitude<.0001 then direction=Vector2.new(0,1) else direction=direction.Unit end
            local center=view*.5
            local radius=math.min(t.offScreenArrowRadius,math.max(0,math.min(view.X,view.Y)*.5-t.offScreenArrowSize-4))
            local tip=center+direction*radius
            local back=tip-direction*t.offScreenArrowSize
            local side=Vector2.new(-direction.Y,direction.X)*t.offScreenArrowSize*.5
            local d=drawing(o,"arrow","Triangle")
            d.PointA=tip;d.PointB=back+side;d.PointC=back-side;d.Filled=true;style(d,t.offScreenArrowColor,override)
        end
        if sp.Z<=.05 then return end
        local needsBox=t.box or t.box3d or t.boxFill or t.name or t.weapon or t.distance or t.healthBar or t.healthText or t.tracer
        local min,max,corners
        if needsBox then
            local center,size=bodyBounds(o,delta,position)
            corners={}
            for i,sign in ipairs(signs) do
                local p=camera:WorldToViewportPoint(center+size*.5*sign)
                corners[i]=p
                if p.Z>.05 then
                    local v=Vector2.new(p.X,p.Y)
                    min=min and min:Min(v) or v;max=max and max:Max(v) or v
                end
            end
        end
        local boxVisible=min and max and max.X>=0 and max.Y>=0 and min.X<=view.X and min.Y<=view.Y
        if onScreen or boxVisible then chams(o,camera,delta,position,override) end
        if boxVisible then
            local size=max-min;local cx=(min.X+max.X)*.5
            if t.boxFill then square(o,"fill",min,size,t.boxFillColor,true,1,override) end
            if t.box then
                if t.boxOutline then square(o,"boxOutline",min,size,t.boxOutlineColor,false,1+2*t.boxOutlineThickness) end
                square(o,"box",min,size,t.boxColor,false,1,override)
            end
            if t.box3d then
                for i,edge in ipairs(edges) do
                    local p,q=corners[edge[1]],corners[edge[2]]
                    if p.Z>.05 and q.Z>.05 then
                        local v,w=Vector2.new(p.X,p.Y),Vector2.new(q.X,q.Y)
                        if t.boxOutline then line(o,"edgeOutline"..i,v,w,t.boxOutlineColor,1+2*t.boxOutlineThickness) end
                        line(o,"edge"..i,v,w,t.box3dColor,1,override)
                    end
                end
            end
            local hp,maxhp=type(a.Health)=="number" and a.Health or 0,a.MaxHealth or 100
            local ratio=math.clamp(hp/math.max(1,maxhp),0,1)
            if t.healthBar then
                local bottom=Vector2.new(min.X-5,max.Y)
                if t.healthBarOutline then line(o,"hpOutline",bottom+Vector2.new(0,1),Vector2.new(min.X-5,min.Y-1),black,4) end
                line(o,"hp",bottom,Vector2.new(min.X-5,max.Y-size.Y*ratio),t.dyingColor:Lerp(t.healthyColor,ratio),2)
            end
            if t.healthText then textAt(o,"hpText",math.ceil(hp),Vector2.new(min.X-20,max.Y-size.Y*ratio-shared.textSize*.5),t.healthTextColor,t.healthTextOutline) end
            if t.name then
                local label=kind=="players" and a.Owner.Name or o.model.Name
                if kind=="players" and adv.nameType=="Display Name" then label=a.Owner.DisplayName
                elseif adv.nameType=="Display Name" then
                    label=a.DisplayName or (a.OwnerName~="???" and a.OwnerName) or (a.Zombie and "Zombie" or "NPC")
                    label=tostring(label).." ["..tostring(a.UID):sub(1,6).."]"
                end
                if kind=="zombies" then label="Zombie"
                elseif kind=="corpses" then label="Corpse: "..(a.Zombie and "Zombie" or (E.IsPlayer(a) and a.Owner.Name or "NPC")) end
                textAt(o,"name",label,Vector2.new(cx,min.Y-shared.textSize-3),t.nameColor,t.nameOutline,override)
            end
            local textY=max.Y+2
            if kind=="players" and t.weapon then textAt(o,"weapon",E.Weapon(a),Vector2.new(cx,textY),t.weaponColor,t.weaponOutline,override);textY+=shared.textSize+2 end
            if t.distance then textAt(o,"distance",string.format("%.0f studs",dist),Vector2.new(cx,textY),t.distanceColor,t.distanceOutline,override) end
            if t.tracer then
                local y=t.tracerOrigin=="Top" and 0 or (t.tracerOrigin=="Middle" and view.Y*.5 or view.Y)
                local from,to=Vector2.new(view.X*.5,y),Vector2.new(cx,max.Y)
                if t.tracerOutline then line(o,"tracerOutline",from,to,black,3) end
                line(o,"tracer",from,to,t.tracerColor,1,override)
            end
        end
        if adv.skeleton then
            for i,pair in ipairs(o.links) do
                if pair[1].Parent and pair[2].Parent then
                    local p,po=camera:WorldToViewportPoint(partPosition(pair[1])+delta)
                    local q,qo=camera:WorldToViewportPoint(partPosition(pair[2])+delta)
                    if p.Z>.05 and q.Z>.05 and (po or qo) then
                        line(o,"bone"..i,Vector2.new(p.X,p.Y),Vector2.new(q.X,q.Y),adv.skeletonColor,1,override)
                    end
                end
            end
        end
    end
    function E.Render(cameraOverride)
        if E.Paused then return end
        E.Sync()
        local camera=cameraOverride or workspace.CurrentCamera
        if not camera then return end
        local c=E.Service();local me=c and c.Replicator and c.Replicator.LocalActor
        local origin=me and me.Position or camera.CFrame.Position
        for actor,o in pairs(E.objects) do
            local ok,err=pcall(E.RenderActor,o,camera,origin)
            if not ok then
                hide(o)
                if not E.errors[tostring(err)] then E.errors[tostring(err)]=true;warn("[NPC ESP]",err) end
            end
        end
    end
    function E.Load()
        if E._hasLoaded then return end
        E._hasLoaded=true
        E.Sync(true)
        connection=AimRunService.RenderStepped:Connect(function() E.Render() end)
        brm5_connections[#brm5_connections + 1] = connection
    end
    function E.Unload()
        if connection then connection:Disconnect();connection=nil end
        for a,o in pairs(E.objects) do destroy(o);E.objects[a]=nil end
        if anchor then anchor:Destroy();anchor=nil end
        E._hasLoaded=false
    end
    return E
end)()
getgenv().LeanNPCESP = Sense
local ChamsEngine, AdvancedESP = Sense.chams, Sense.advanced
local function espSetColor(tbl,key)
    return function(c,a)
        if type(tbl[key])=="table" then tbl[key][1]=c;if a~=nil then tbl[key][2]=a end
        else tbl[key]=c end
    end
end
local function espDefault(tbl,key)
    if type(tbl[key])=="table" then return tbl[key][1],tbl[key][2] end
    return tbl[key],1
end
Sense.Load()

-------------------------------------------------------------------
-- 7h. WORLDMOD ENGINE (b.txt 2220-2490)
-------------------------------------------------------------------
local WMLighting = game:GetService("Lighting")

local WMBackup = {
    Ambient = WMLighting.Ambient, OutdoorAmbient = WMLighting.OutdoorAmbient,
    ColorShift_Top = WMLighting.ColorShift_Top, ColorShift_Bottom = WMLighting.ColorShift_Bottom,
    ClockTime = WMLighting.ClockTime,
    FogStart = WMLighting.FogStart, FogEnd = WMLighting.FogEnd, FogColor = WMLighting.FogColor,
    Brightness = WMLighting.Brightness, ExposureCompensation = WMLighting.ExposureCompensation,
    EnvironmentDiffuseScale = WMLighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = WMLighting.EnvironmentSpecularScale,
    GlobalShadows = WMLighting.GlobalShadows, ShadowSoftness = WMLighting.ShadowSoftness,
}

local WM = {
    ambient    = { enabled = false, a = WMLighting.Ambient, b = WMLighting.OutdoorAmbient },
    colorShift = { enabled = false, top = WMLighting.ColorShift_Top, bottom = WMLighting.ColorShift_Bottom },
    time       = { enabled = false, value = WMLighting.ClockTime },
    fog        = { enabled = false, s = WMLighting.FogStart, e = WMLighting.FogEnd, color = WMLighting.FogColor },
    light      = { enabled = false, brightness = WMLighting.Brightness, exposure = WMLighting.ExposureCompensation,
                   diffuse = WMLighting.EnvironmentDiffuseScale, specular = WMLighting.EnvironmentSpecularScale },
    shadows    = { enabled = false, softness = WMLighting.ShadowSoftness, tech = "ShadowMap" },
}

brm5_connections[#brm5_connections + 1] = AimRunService.RenderStepped:Connect(function()
    if WM.ambient.enabled then
        WMLighting.Ambient = WM.ambient.a
        WMLighting.OutdoorAmbient = WM.ambient.b
    end
    if WM.colorShift.enabled then
        WMLighting.ColorShift_Top = WM.colorShift.top
        WMLighting.ColorShift_Bottom = WM.colorShift.bottom
    end
    if WM.time.enabled then
        WMLighting.ClockTime = WM.time.value
    end
    if WM.fog.enabled then
        WMLighting.FogStart = WM.fog.s
        WMLighting.FogEnd = WM.fog.e
        WMLighting.FogColor = WM.fog.color
    end
    if WM.light.enabled then
        WMLighting.Brightness = WM.light.brightness
        WMLighting.ExposureCompensation = WM.light.exposure
        WMLighting.EnvironmentDiffuseScale = WM.light.diffuse
        WMLighting.EnvironmentSpecularScale = WM.light.specular
    end
    if WM.shadows.enabled then
        WMLighting.GlobalShadows = true
        WMLighting.ShadowSoftness = WM.shadows.softness
    end
end)

-------------------------------------------------------------------
-- 7i. PRIMO UI ELEMENTS  (create_element + signal wiring)
-------------------------------------------------------------------

-- ─── AIM TAB ─────────────────────────────────────────────────

-- Silent Aim section
do
    local el = brm5_el(aim_sec, "Enabled", { toggle = { flag = "lean_silent_enabled", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Silent.Enabled=v; if v then silent_applyHooks() end end)
end
do
    local el = brm5_el(aim_sec, "FOV Radius", { slider = { flag = "lean_silent_fov", min = 1, max = 500, default = 120, suffix = " px" } })
    wire_signal(el, "on_slider_change", function(v) Silent.FOV=v end)
end
do
    local el = brm5_el(aim_sec, "Hit Chance", { slider = { flag = "lean_silent_hitchance", min = 0, max = 100, default = 100, suffix = "%" } })
    wire_signal(el, "on_slider_change", function(v) Silent.HitChance=v end)
end
do
    local el = brm5_el(aim_sec, "Hit Part", { dropdown = { flag = "lean_silent_hitpart", options = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","Closest Part","Random"}, default = "Head" } })
    wire_signal(el, "on_dropdown_change", function(v) Silent.HitPart=v end)
end
do
    local el = brm5_el(aim_sec, "Max Distance", { slider = { flag = "lean_silent_maxdist", min = 50, max = 5000, default = 1000, suffix = " studs" } })
    wire_signal(el, "on_slider_change", function(v) Silent.MaxDistance=v end)
end
do
    local el = brm5_el(aim_sec, "Sticky Aim", { toggle = { flag = "lean_silent_sticky", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Silent.StickyAim=v end)
end
do
    local el = brm5_el(aim_sec, "Silent Aim Key", { keybind = { flag = "silent_key", default = Enum.UserInputType.MouseButton2 } })
    if flags["silent_key"] == nil then flags["silent_key"] = Enum.UserInputType.MouseButton2 end
end

-- FOV section
do
    local el = brm5_el(aim_fov_sec, "Show FOV", { toggle = { flag = "lean_silent_showfov", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Silent.ShowFOV=v end)
end
do
    local el = brm5_el(aim_fov_sec, "FOV Color", { colorpicker = { color_flag = "lean_silent_fovcolor", transparency_flag = "", default_color = Color3.fromRGB(150,80,255), default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) Silent.FOVColor=v end)
end
do
    local el = brm5_el(aim_fov_sec, "Fill FOV", { toggle = { flag = "lean_silent_fillfov", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Silent.FillFOV=v end)
end
do
    local el = brm5_el(aim_fov_sec, "Fill Color", { colorpicker = { color_flag = "lean_silent_fillcolor", transparency_flag = "", default_color = Color3.fromRGB(150,80,255), default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) Silent.FOVFillColor=v end)
end
do
    local el = brm5_el(aim_fov_sec, "Gradient FOV", { toggle = { flag = "lean_silent_gradient", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Silent.GradientFOV=v end)
end
do
    local el = brm5_el(aim_fov_sec, "Gradient Color A", { colorpicker = { color_flag = "lean_silent_grada", transparency_flag = "", default_color = Color3.fromRGB(150,80,255), default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) Silent.GradientColorA=v end)
end
do
    local el = brm5_el(aim_fov_sec, "Gradient Color B", { colorpicker = { color_flag = "lean_silent_gradb", transparency_flag = "", default_color = Color3.fromRGB(255,110,60), default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) Silent.GradientColorB=v end)
end
do
    local el = brm5_el(aim_fov_sec, "Spin Gradient", { toggle = { flag = "lean_silent_spin", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Silent.GradientSpin=v end)
end
do
    local el = brm5_el(aim_fov_sec, "Spin Speed", { slider = { flag = "lean_silent_spinspeed", min = 0.1, max = 5, default = 1 } })
    wire_signal(el, "on_slider_change", function(v) Silent.GradientSpinSpeed=v end)
end

-- Prediction section
do
    local el = brm5_el(aim_pred_sec, "Auto Prediction", { toggle = { flag = "lean_silent_autopred", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Silent.AutoPrediction=v end)
end
do
    local el = brm5_el(aim_pred_sec, "Bullet Drop", { toggle = { flag = "lean_silent_bulldrop", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Silent.BulletDropCompensation=v end)
end

-- Checks section
do
    local el = brm5_el(aim_chk_sec, "Hitscan", { toggle = { flag = "lean_silent_hitscan", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Silent.Hitscan=v end)
end
do
    local el = brm5_el(aim_chk_sec, "Team Check", { toggle = { flag = "lean_silent_teamcheck", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Silent.TeamCheck=v end)
end
do
    local el = brm5_el(aim_chk_sec, "Visible Check", { toggle = { flag = "lean_silent_vischeck", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Silent.VisibleCheck=v end)
end

-- ─── TRIGGER TAB ─────────────────────────────────────────────

-- Trigger Bot section
do
    local el = brm5_el(trig_sec, "Enabled", { toggle = { flag = "lean_trigger_enabled", default = false } })
    wire_signal(el, "on_toggle_change", function(v) TriggerBotSettings.Enabled=v end)
end
do
    local el = brm5_el(trig_sec, "Reaction Time", { slider = { flag = "lean_trigger_reaction", min = 0, max = 500, default = 50, suffix = " ms" } })
    wire_signal(el, "on_slider_change", function(v) TriggerBotSettings.ReactionTime=v end)
end
do
    local el = brm5_el(trig_sec, "Shoot Time", { slider = { flag = "lean_trigger_shoot", min = 0, max = 1000, default = 100, suffix = " ms" } })
    wire_signal(el, "on_slider_change", function(v) TriggerBotSettings.ShootTime=v end)
end
do
local el = brm5_el(trig_sec, "Trigger Key", { keybind = { flag = "trigger_key", default = Enum.UserInputType.MouseButton2 } })
    if flags["trigger_key"] == nil then flags["trigger_key"] = Enum.UserInputType.MouseButton2 end
end

-- Magnetic section
do
    local el = brm5_el(trig_mag_sec, "Magnetic", { toggle = { flag = "lean_trigger_magnetic", default = false } })
    wire_signal(el, "on_toggle_change", function(v) TriggerBotSettings.Magnetic=v end)
end
do
    local el = brm5_el(trig_mag_sec, "Team Check", { toggle = { flag = "lean_trigger_teamcheck", default = false } })
    wire_signal(el, "on_toggle_change", function(v) TriggerBotSettings.TeamCheck=v end)
end
do
    local el = brm5_el(trig_mag_sec, "Visible Check", { toggle = { flag = "lean_trigger_vischeck", default = true } })
    wire_signal(el, "on_toggle_change", function(v) TriggerBotSettings.VisibleCheck=v end)
end
do
    local el = brm5_el(trig_mag_sec, "Max Distance", { slider = { flag = "lean_trigger_maxdist", min = 50, max = 5000, default = 1000, suffix = " studs" } })
    wire_signal(el, "on_slider_change", function(v) TriggerBotSettings.MaxDistance=v end)
end

-- ─── MOVEMENT TAB ────────────────────────────────────────────

-- Movement section
do
    local el = brm5_el(mov_sec, "Speed", { toggle = { flag = "movement_Speed", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.Speed=v end)
end
do
    local el = brm5_el(mov_sec, "Speed Value", { slider = { flag = "movement_speed_value", min = 1, max = 150, default = 24, suffix = " studs/s" } })
    wire_signal(el, "on_slider_change", function(v) Combat.Movement.SpeedValue=v end)
end
do
local el = brm5_el(mov_sec, "Speed Key", { keybind = { flag = "movement_speed_key", default = Enum.KeyCode.G } })
    if flags["movement_speed_key"] == nil then flags["movement_speed_key"] = Enum.KeyCode.G end
end
do
    local el = brm5_el(mov_sec, "No Smoothing", { toggle = { flag = "movement_Smoothing", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.Smoothing=v end)
end
do
    local el = brm5_el(mov_sec, "Omni Sprint", { toggle = { flag = "movement_OmniSprint", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.OmniSprint=v end)
end
do
    local el = brm5_el(mov_sec, "Sprint Combat", { toggle = { flag = "movement_SprintCombat", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.SprintCombat=v end)
end

-- Restrictions section
do
    local el = brm5_el(mov_res_sec, "Infinite Stamina", { toggle = { flag = "movement_Stamina", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.Stamina=v end)
end
do
    local el = brm5_el(mov_res_sec, "No Speed Penalties", { toggle = { flag = "movement_Penalties", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.Penalties=v end)
end

-- Fly section
do
    local el = brm5_el(mov_fly_sec, "Fly", { toggle = { flag = "movement_Fly", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.Fly=v end)
end
do
    local el = brm5_el(mov_fly_sec, "Fly Speed", { slider = { flag = "movement_fly_speed", min = 1, max = 150, default = 40, suffix = " studs/s" } })
    wire_signal(el, "on_slider_change", function(v) Combat.Movement.FlySpeed=v end)
end
do
local el = brm5_el(mov_fly_sec, "Fly Key", { keybind = { flag = "movement_fly_key", default = Enum.KeyCode.F } })
    if flags["movement_fly_key"] == nil then flags["movement_fly_key"] = Enum.KeyCode.F end
end
do
    local el = brm5_el(mov_fly_sec, "Noclip", { toggle = { flag = "movement_Noclip", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.Noclip=v end)
end

-- Modifier section
do
    local el = brm5_el(mov_mod_sec, "Fly Modifier", { toggle = { flag = "movement_Modifier", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Combat.Movement.Modifier=v end)
end
do
    local el = brm5_el(mov_mod_sec, "Speed Multiplier", { slider = { flag = "movement_fly_multiplier", min = 1, max = 5, default = 2 } })
    wire_signal(el, "on_slider_change", function(v) Combat.Movement.Multiplier=v end)
end
do
local el = brm5_el(mov_mod_sec, "Modifier Key", { keybind = { flag = "movement_modifier_key", default = Enum.KeyCode.LeftShift } })
    if flags["movement_modifier_key"] == nil then flags["movement_modifier_key"] = Enum.KeyCode.LeftShift end
end

-- ─── GUN TAB ─────────────────────────────────────────────────

-- Handling section
do
    local el = brm5_el(gun_hnd_sec, "No Recoil", { toggle = { flag = "gun_NoRecoil", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.NoRecoil=v end)
end
do
    local el = brm5_el(gun_hnd_sec, "Instant ADS", { toggle = { flag = "gun_InstantADS", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.InstantADS=v end)
end
do
    local el = brm5_el(gun_hnd_sec, "No Sway", { toggle = { flag = "gun_NoSway", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.NoSway=v end)
end
do
    local el = brm5_el(gun_hnd_sec, "All Firemodes", { toggle = { flag = "gun_unlock_modes", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.UnlockModes=v; Gun.UpdateTune() end)
end
do
    local el = brm5_el(gun_hnd_sec, "Auto Reload", { toggle = { flag = "gun_auto_reload", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.AutoReload=v; Gun.UpdateTune() end)
end

-- Ballistics section
do
    local el = brm5_el(gun_bal_sec, "No Spread", { toggle = { flag = "gun_no_spread", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.NoSpread=v; Gun.UpdateTune() end)
end
do
    local el = brm5_el(gun_bal_sec, "Spread Reduction", { slider = { flag = "gun_spread_reduction", min = 0, max = 100, default = 100, suffix = "%" } })
    wire_signal(el, "on_slider_change", function(v) Gun.SpreadReduction=v; Gun.UpdateTune() end)
end
do
    local el = brm5_el(gun_bal_sec, "Force Headshot", { toggle = { flag = "gun_force_headshot", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.ForceHeadshot=v end)
end

-- Appearance section
do
    local el = brm5_el(gun_vis_sec, "Weapon Visuals", { toggle = { flag = "gun_visuals", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.Visuals=v; Gun.UpdateVisuals() end)
end
do
    local el = brm5_el(gun_vis_sec, "Material", { dropdown = { flag = "gun_material", options = {"Original","ForceField","Neon","SmoothPlastic","Glass","Metal","Ice"}, default = "Original" } })
    wire_signal(el, "on_dropdown_change", function(v) Gun.Material=v; Gun.UpdateVisuals() end)
end
do
    local el = brm5_el(gun_vis_sec, "Transparency", { slider = { flag = "gun_transparency", min = 0, max = 100, default = 0, suffix = "%" } })
    wire_signal(el, "on_slider_change", function(v) Gun.Transparency=v; Gun.UpdateVisuals() end)
end
do
    local el = brm5_el(gun_vis_sec, "Weapon Color", { colorpicker = { color_flag = "gun_weapon_color", transparency_flag = "", default_color = Gun.WeaponColor, default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) Gun.WeaponColor=v; Gun.UpdateVisuals() end)
end

-- Tracers section
do
    local el = brm5_el(gun_trc_sec, "Tracers", { toggle = { flag = "gun_tracers", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Gun.Tracers=v; if not v then Gun.ClearTracers() end end)
end
do
    local el = brm5_el(gun_trc_sec, "Tracer Style", { dropdown = { flag = "gun_tracer_style", options = {"Line","Lightning","DNA"}, default = "Lightning" } })
    wire_signal(el, "on_dropdown_change", function(v) Gun.TracerStyle=(v=="Line" or v=="Lightning" or v=="DNA") and v or "Lightning" end)
end
do
    local el = brm5_el(gun_trc_sec, "Tracer Color", { colorpicker = { color_flag = "gun_tracer_color", transparency_flag = "", default_color = Gun.TracerColor, default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v)
        Gun.TracerColor=v
        if Gun.tracerFolder then
            for _,beam in ipairs(Gun.tracerFolder:GetDescendants()) do
                if beam:IsA("Beam") then beam.Color=ColorSequence.new(v) end
            end
        end
    end)
end
do
    local el = brm5_el(gun_trc_sec, "Duration", { slider = { flag = "gun_tracer_duration", min = 0.1, max = 3, default = 0.6, suffix = " s" } })
    wire_signal(el, "on_slider_change", function(v) Gun.TracerDuration=v end)
end
do
    local el = brm5_el(gun_trc_sec, "Width", { slider = { flag = "gun_tracer_width", min = 0.02, max = 0.3, default = 0.08 } })
    wire_signal(el, "on_slider_change", function(v) Gun.TracerWidth=v end)
end

-- ─── ESP TAB ─────────────────────────────────────────────────

-- Corpses section (per-kind toggles + colors)
do
    local el = brm5_el(esp_corp_sec, "Corpse ESP", { toggle = { flag = "sense_corpses_enabled", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.corpses.enabled=v end)
end
do
    local el = brm5_el(esp_corp_sec, "Name", { toggle = { flag = "sense_corpses_name", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.corpses.name=v end)
end
do
    local el = brm5_el(esp_corp_sec, "Distance", { toggle = { flag = "sense_corpses_dist", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.corpses.distance=v end)
end
do
    local el = brm5_el(esp_corp_sec, "Box", { toggle = { flag = "sense_corpses_box", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.corpses.box=v end)
end
do
    local el = brm5_el(esp_corp_sec, "Tracer", { toggle = { flag = "sense_corpses_tracer", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.corpses.tracer=v end)
end
do
    local el = brm5_el(esp_corp_sec, "Color", { colorpicker = { color_flag = "sense_corpses_boxcolor", transparency_flag = "", default_color = Color3.new(1,1,1), default_transparency = 0 } })
    wire_signal(el, "on_color_change", espSetColor(Sense.teamSettings.corpses,"boxColor"))
end

-- NPCs section
do
    local el = brm5_el(esp_npc_sec, "NPC ESP", { toggle = { flag = "sense_npc_enabled", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.npc.enabled=v end)
end
do
    local el = brm5_el(esp_npc_sec, "Box", { toggle = { flag = "sense_npc_box", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.npc.box=v end)
end
do
    local el = brm5_el(esp_npc_sec, "Name", { toggle = { flag = "sense_npc_name", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.npc.name=v end)
end
do
    local el = brm5_el(esp_npc_sec, "Distance", { toggle = { flag = "sense_npc_dist", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.npc.distance=v end)
end
do
    local el = brm5_el(esp_npc_sec, "Health Bar", { toggle = { flag = "sense_npc_hp", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.npc.healthBar=v end)
end
do
    local el = brm5_el(esp_npc_sec, "Tracer", { toggle = { flag = "sense_npc_tracer", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.npc.tracer=v end)
end
do
    local el = brm5_el(esp_npc_sec, "Box Color", { colorpicker = { color_flag = "sense_npc_boxcolor", transparency_flag = "", default_color = Color3.new(1,1,1), default_transparency = 0 } })
    wire_signal(el, "on_color_change", espSetColor(Sense.teamSettings.npc,"boxColor"))
end

-- Zombies section
do
    local el = brm5_el(esp_zmb_sec, "Zombie ESP", { toggle = { flag = "sense_zombies_enabled", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.zombies.enabled=v end)
end
do
    local el = brm5_el(esp_zmb_sec, "Box", { toggle = { flag = "sense_zombies_box", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.zombies.box=v end)
end
do
    local el = brm5_el(esp_zmb_sec, "Name", { toggle = { flag = "sense_zombies_name", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.zombies.name=v end)
end
do
    local el = brm5_el(esp_zmb_sec, "Distance", { toggle = { flag = "sense_zombies_dist", default = true } })
    wire_signal(el, "on_toggle_change", function(v) Sense.teamSettings.zombies.distance=v end)
end
do
    local el = brm5_el(esp_zmb_sec, "Box Color", { colorpicker = { color_flag = "sense_zombies_boxcolor", transparency_flag = "", default_color = Color3.new(1,1,1), default_transparency = 0 } })
    wire_signal(el, "on_color_change", espSetColor(Sense.teamSettings.zombies,"boxColor"))
end

-- Settings section (shared across all Sense types)
do
    local el = brm5_el(esp_set_sec, "Text Size", { slider = { flag = "sense_text_size", min = 8, max = 30, default = 13 } })
    wire_signal(el, "on_slider_change", function(v) Sense.sharedSettings.textSize=v end)
end
do
    local el = brm5_el(esp_set_sec, "Limit Distance", { toggle = { flag = "sense_limit_distance", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.sharedSettings.limitDistance=v end)
end
do
    local el = brm5_el(esp_set_sec, "Max Distance", { slider = { flag = "sense_max_distance", min = 100, max = 5000, default = 1000, suffix = " studs" } })
    wire_signal(el, "on_slider_change", function(v) Sense.sharedSettings.maxDistance=v end)
end
do
    local el = brm5_el(esp_set_sec, "Team Based Color", { toggle = { flag = "sense_team_based_color", default = false } })
    wire_signal(el, "on_toggle_change", function(v) Sense.sharedSettings.teamBasedColor=v end)
end
do
    local el = brm5_el(esp_set_sec, "Neutral Color", { colorpicker = { color_flag = "sense_neutral_color", transparency_flag = "", default_color = Color3.fromRGB(100,220,150), default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) Sense.sharedSettings.neutralColor=v end)
end

-- ─── WORLD TAB ───────────────────────────────────────────────

-- World section
do
    local el = brm5_el(wm_wld_sec, "Custom Ambient", { toggle = { flag = "wm_ambient", default = false } })
    wire_signal(el, "on_toggle_change", function(v)
        WM.ambient.enabled=v
        if not v then WMLighting.Ambient=WMBackup.Ambient;WMLighting.OutdoorAmbient=WMBackup.OutdoorAmbient end
    end)
end
do
    local el = brm5_el(wm_wld_sec, "Ambient", { colorpicker = { color_flag = "wm_ambient_a", transparency_flag = "", default_color = WM.ambient.a, default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) WM.ambient.a=v end)
end
do
    local el = brm5_el(wm_wld_sec, "Outdoor Ambient", { colorpicker = { color_flag = "wm_ambient_b", transparency_flag = "", default_color = WM.ambient.b, default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) WM.ambient.b=v end)
end
do
    local el = brm5_el(wm_wld_sec, "Custom Color Shift", { toggle = { flag = "wm_colorshift", default = false } })
    wire_signal(el, "on_toggle_change", function(v)
        WM.colorShift.enabled=v
        if not v then WMLighting.ColorShift_Top=WMBackup.ColorShift_Top;WMLighting.ColorShift_Bottom=WMBackup.ColorShift_Bottom end
    end)
end
do
    local el = brm5_el(wm_wld_sec, "Color Shift Top", { colorpicker = { color_flag = "wm_colorshift_top", transparency_flag = "", default_color = WM.colorShift.top, default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) WM.colorShift.top=v end)
end
do
    local el = brm5_el(wm_wld_sec, "Color Shift Bottom", { colorpicker = { color_flag = "wm_colorshift_bottom", transparency_flag = "", default_color = WM.colorShift.bottom, default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) WM.colorShift.bottom=v end)
end
do
    local el = brm5_el(wm_wld_sec, "Custom World Time", { toggle = { flag = "wm_time", default = false } })
    wire_signal(el, "on_toggle_change", function(v)
        WM.time.enabled=v
        if not v then WMLighting.ClockTime=WMBackup.ClockTime end
    end)
end
do
    local el = brm5_el(wm_wld_sec, "World Time", { slider = { flag = "wm_time_value", min = 0, max = 24, default = 14 } })
    wire_signal(el, "on_slider_change", function(v) WM.time.value=v end)
end
do
    local el = brm5_el(wm_wld_sec, "Custom Fog", { toggle = { flag = "wm_fog", default = false } })
    wire_signal(el, "on_toggle_change", function(v)
        WM.fog.enabled=v
        if not v then WMLighting.FogStart=WMBackup.FogStart;WMLighting.FogEnd=WMBackup.FogEnd;WMLighting.FogColor=WMBackup.FogColor end
    end)
end
do
    local el = brm5_el(wm_wld_sec, "Fog Start", { slider = { flag = "wm_fog_start", min = 0, max = 5000, default = 0 } })
    wire_signal(el, "on_slider_change", function(v) WM.fog.s=v end)
end
do
    local el = brm5_el(wm_wld_sec, "Fog End", { slider = { flag = "wm_fog_end", min = 0, max = 10000, default = 1000 } })
    wire_signal(el, "on_slider_change", function(v) WM.fog.e=v end)
end
do
    local el = brm5_el(wm_wld_sec, "Fog Color", { colorpicker = { color_flag = "wm_fog_color", transparency_flag = "", default_color = WM.fog.color, default_transparency = 0 } })
    wire_signal(el, "on_color_change", function(v) WM.fog.color=v end)
end

-- Lighting section
do
    local el = brm5_el(wm_lit_sec, "Custom Lighting", { toggle = { flag = "wm_light", default = false } })
    wire_signal(el, "on_toggle_change", function(v)
        WM.light.enabled=v
        if not v then
            WMLighting.Brightness=WMBackup.Brightness;WMLighting.ExposureCompensation=WMBackup.ExposureCompensation
            WMLighting.EnvironmentDiffuseScale=WMBackup.EnvironmentDiffuseScale
            WMLighting.EnvironmentSpecularScale=WMBackup.EnvironmentSpecularScale
        end
    end)
end
do
    local el = brm5_el(wm_lit_sec, "Brightness", { slider = { flag = "wm_brightness", min = 0, max = 10, default = WM.light.brightness } })
    wire_signal(el, "on_slider_change", function(v) WM.light.brightness=v end)
end
do
    local el = brm5_el(wm_lit_sec, "Exposure", { slider = { flag = "wm_exposure", min = -5, max = 5, default = WM.light.exposure } })
    wire_signal(el, "on_slider_change", function(v) WM.light.exposure=v end)
end
do
    local el = brm5_el(wm_lit_sec, "Diffuse", { slider = { flag = "wm_diffuse", min = 0, max = 1, default = WM.light.diffuse } })
    wire_signal(el, "on_slider_change", function(v) WM.light.diffuse=v end)
end
do
    local el = brm5_el(wm_lit_sec, "Specular", { slider = { flag = "wm_specular", min = 0, max = 1, default = WM.light.specular } })
    wire_signal(el, "on_slider_change", function(v) WM.light.specular=v end)
end

-- Graphics section
do
    local el = brm5_el(wm_gfx_sec, "Global Shadows", { toggle = { flag = "wm_shadows", default = false } })
    wire_signal(el, "on_toggle_change", function(v)
        WM.shadows.enabled=v
        if v then
            pcall(function() WMLighting.Technology=Enum.Technology[WM.shadows.tech] end)
        else
            WMLighting.GlobalShadows=WMBackup.GlobalShadows;WMLighting.ShadowSoftness=WMBackup.ShadowSoftness
        end
    end)
end
do
    local el = brm5_el(wm_gfx_sec, "Shadow Softness", { slider = { flag = "wm_shadow_softness", min = 0, max = 1, default = WM.shadows.softness } })
    wire_signal(el, "on_slider_change", function(v) WM.shadows.softness=v end)
end
do
    local el = brm5_el(wm_gfx_sec, "Technology", { dropdown = { flag = "wm_tech", options = {"ShadowMap","Unified","Future","Voxel","Compatibility"}, default = "ShadowMap" } })
    wire_signal(el, "on_dropdown_change", function(v)
        WM.shadows.tech=v
        if WM.shadows.enabled then pcall(function() WMLighting.Technology=Enum.Technology[v] end) end
    end)
end

-------------------------------------------------------------------
-- 7j. MENU CAMERA / MOUSE FREEZE
-- BRM5's first-person camera keeps consuming the mouse while the Primo
-- menu is open (LockCenter look + camera controller), so the drawing
-- cursor can't move unless the map is open. We use BindToRenderStep at
-- priority 500 (after camera/character at 200/250) so it always runs
-- AFTER the game camera controller, pinning the camera and freeing the
-- mouse each frame while the menu is open.
-------------------------------------------------------------------
do
    local UIS = game:GetService("UserInputService")
    local RS = AimRunService
    local FREEZE_NAME = "Brm5CamFreeze"
    local Freeze = { active = false, behavior = nil, camera_type = nil, cf = nil }

    RS:BindToRenderStep(FREEZE_NAME, 1000, function()
        local cam = workspace.CurrentCamera
        local open = menu.is_menu_open()
        if open ~= Freeze.active then
            if open then
                Freeze.behavior = UIS.MouseBehavior
                Freeze.camera_type = cam and cam.CameraType or nil
                Freeze.cf = cam and cam.CFrame or nil
                pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
            else
                pcall(function() UIS.MouseBehavior = Freeze.behavior or Enum.MouseBehavior.Default end)
                pcall(function() if cam and Freeze.camera_type then cam.CameraType = Freeze.camera_type end end)
                Freeze.behavior, Freeze.camera_type, Freeze.cf = nil, nil, nil
            end
            Freeze.active = open
        end
        if Freeze.active and cam then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
            cam.CameraType = Enum.CameraType.Scriptable
            if Freeze.cf then
                cam.CFrame = Freeze.cf
            end
        end
    end)

    brm5_connections[#brm5_connections + 1] = {
        Disconnect = function()
            pcall(function() RS:UnbindFromRenderStep(FREEZE_NAME) end)
            local cam = workspace.CurrentCamera
            local UIS = game:GetService("UserInputService")
            if Freeze.active then
                pcall(function() UIS.MouseBehavior = Freeze.behavior or Enum.MouseBehavior.Default end)
                pcall(function() if cam and Freeze.camera_type then cam.CameraType = Freeze.camera_type end end)
                Freeze.active = false
            end
        end
    }
end

-------------------------------------------------------------------
-- 7k. CLEANUP CHAIN
-------------------------------------------------------------------
do
    local prev_cleanup = getgenv()._UNIVERSAL_MISC_CLEANUP
    getgenv()._UNIVERSAL_MISC_CLEANUP = function()
        if prev_cleanup then prev_cleanup() end
        if Combat then Combat.Destroy() end
        if Sense then Sense.Unload() end
        for _, c in ipairs(brm5_connections) do pcall(function() c:Disconnect() end) end
        table.clear(brm5_connections)
    end
end

-- Mark as installed
getgenv()._BRM5_PORT_LOADED = true
print("[BRM5] Lean features ported to Primo menu successfully")

