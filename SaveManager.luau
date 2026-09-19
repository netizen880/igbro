-- Facility addon | SaveManager
-- Sauvegarde et chargement des configurations, au format JSON.

return function(Library)
	local HttpService = game:GetService("HttpService")
	local FileSystem = Library.FileSystem
	local Theme = Library.Theme

	local SaveManager = {}
	SaveManager.Library = Library
	SaveManager.Folder = "Facility"
	SaveManager.Ignore = {}
	SaveManager.Format = "json"

	function SaveManager:SetLibrary(lib)
		self.Library = lib or Library
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in ipairs(list or {}) do self.Ignore[key] = true end
	end

	function SaveManager:IgnoreThemeSettings()
		local library = self.Library
		if library.InterfaceManager then
			self:SetIgnoreIndexes(library.InterfaceManager.Flags)
		end
		if library.ThemeManager then
			self:SetIgnoreIndexes(library.ThemeManager.Flags)
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self.Library:BuildFolders(folder)
	end

	function SaveManager:Path(file)
		return self.Folder .. "/config/" .. file
	end

	function SaveManager:List()
		return FileSystem:List(self.Folder .. "/config")
	end

	function SaveManager:Save(name)
		if type(name) ~= "string" or string.gsub(name, "%s", "") == "" then return false, "empty name" end
		local file = name
		if not string.match(file, "%.%w+$") then file = file .. "." .. self.Format end
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(self.Library:GetConfig(self.Ignore))
		end)
		if not ok then return false, "encode failed" end
		FileSystem:Write(self:Path(file), encoded)
		self.Library:ClearDirty()
		return true, file
	end

	function SaveManager:Load(file)
		if type(file) ~= "string" or file == "" then return false, "no config" end
		local raw = FileSystem:Read(self:Path(file))
		if not raw then return false, "not found" end
		local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok then return false, "corrupted file" end
		self.Library:LoadConfig(data, self.Ignore)
		return true, file
	end

	function SaveManager:Delete(file)
		if type(file) ~= "string" or file == "" then return false, "no config" end
		FileSystem:Delete(self:Path(file))
		if self:GetAutoload() == file then self:ClearAutoload() end
		return true, file
	end

	function SaveManager:AutoloadPath()
		return self.Folder .. "/settings/autoload.txt"
	end

	function SaveManager:GetAutoload()
		local name = FileSystem:Read(self:AutoloadPath())
		if name == "" then return nil end
		return name
	end

	function SaveManager:SetAutoload(file)
		if type(file) ~= "string" or file == "" then return false end
		FileSystem:Write(self:AutoloadPath(), file)
		return true
	end

	function SaveManager:ClearAutoload()
		FileSystem:Delete(self:AutoloadPath())
	end

	function SaveManager:LoadAutoloadConfig()
		local file = self:GetAutoload()
		if not file then return false end
		local ok, err = self:Load(file)
		self.Library:Notify({
			Title = ok and "config loaded" or "config error",
			Text = ok and file or tostring(err),
			Duration = 3,
		})
		return ok
	end

	function SaveManager:BuildConfigSection(tab, column)
		local section = tab:Section("config", column or 2)
		local nameBox = section:Input({ Text = "name", Flag = false, Default = "default", Placeholder = "config name" })
		local savedBox = section:Dropdown({ Text = "saved", Flag = false, Options = self:List(), Empty = "none" })

		local autoloadLabel, dirtyLabel

		local function refreshList(select)
			savedBox:SetOptions(self:List())
			if select then savedBox:Set(select, true) end
		end

		local function selected()
			local file = savedBox:Get()
			if type(file) ~= "string" or file == "" then return nil end
			return file
		end

		local function notify(ok, result, action)
			self.Library:Notify({
				Title = ok and ("config " .. action) or "config error",
				Text = tostring(result),
				Duration = 3,
			})
		end

		section:ButtonRow({
			{
				Text = "save",
				Callback = function()
					local ok, result = self:Save(nameBox:Get())
					if ok then refreshList(result) end
					notify(ok, result, "saved")
				end,
			},
			{
				Text = "load",
				Callback = function()
					local ok, result = self:Load(selected())
					notify(ok, result, "loaded")
				end,
			},
		})

		section:ButtonRow({
			{
				Text = "delete",
				Callback = function()
					local file = selected()
					if not file then return notify(false, "no config", "") end

					local function remove()
						local ok, result = self:Delete(file)
						if ok then
							refreshList()
							if autoloadLabel then autoloadLabel:Set("autoload: " .. (self:GetAutoload() or "none")) end
						end
						notify(ok, result, "deleted")
					end

					local window = self.Library.Windows[1]
					if not window then return remove() end

					window:Confirm({
						Title = "delete config",
						Text = "Delete " .. file .. " permanently?",
						Confirm = "delete",
						Cancel = "cancel",
						OnConfirm = remove,
					})
				end,
			},
			{ Text = "refresh", Callback = function() refreshList() end },
		})

		section:ButtonRow({
			{
				Text = "set autoload",
				Callback = function()
					local file = selected()
					if not file then return notify(false, "no config", "") end
					self:SetAutoload(file)
					autoloadLabel:Set("autoload: " .. file)
				end,
			},
			{
				Text = "clear autoload",
				Callback = function()
					self:ClearAutoload()
					autoloadLabel:Set("autoload: none")
				end,
			},
		})

		section:ButtonRow({
			{
				Text = "copy",
				Callback = function()
					local ok, encoded = pcall(function()
						return HttpService:JSONEncode(self.Library:GetConfig(self.Ignore))
					end)
					if ok and typeof(setclipboard) == "function" then
						setclipboard(encoded)
						notify(true, "copied to clipboard", "copied")
					else
						notify(false, "clipboard unavailable", "")
					end
				end,
			},
			{
				Text = "paste",
				Callback = function()
					local reader = typeof(getclipboard) == "function" and getclipboard or nil
					if not reader then return notify(false, "clipboard unavailable", "") end
					local ok, data = pcall(function() return HttpService:JSONDecode(reader()) end)
					if not ok or type(data) ~= "table" then return notify(false, "invalid clipboard", "") end
					self.Library:LoadConfig(data, self.Ignore)
					notify(true, "config applied", "pasted")
				end,
			},
		})

		section:ButtonRow({
			{
				Text = "reset defaults",
				Callback = function()
					self.Library:ResetDefaults(self.Ignore)
					notify(true, "defaults restored", "reset")
				end,
			},
		})

		autoloadLabel = section:Label("autoload: " .. (self:GetAutoload() or "none"))
		dirtyLabel = section:Label("no unsaved changes")

		self.Library:CaptureDefaults()
		self.Library:ClearDirty()
		self.Library.OnDirty = function(state)
			dirtyLabel:Set(state and "unsaved changes" or "no unsaved changes")
			dirtyLabel:SetColor(state and Theme.Accent or Theme.TextDim)
		end

		self.Section = section
		return section
	end

	Library.DirtyIgnore = SaveManager.Ignore
	return SaveManager
end
