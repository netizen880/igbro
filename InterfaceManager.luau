-- Facility addon | InterfaceManager
-- Reglages de l'interface elle-meme : touche du menu, echelle, dechargement.

return function(Library)
	local InterfaceManager = {}
	InterfaceManager.Library = Library
	InterfaceManager.Folder = "Facility"
	InterfaceManager.Flags = { "interface_menu_key", "interface_scale", "interface_hotkeys" }

	function InterfaceManager:SetLibrary(lib)
		self.Library = lib or Library
	end

	function InterfaceManager:SetWindow(window)
		self.Window = window
	end

	function InterfaceManager:SetFolder(folder)
		self.Folder = folder
		self.Library:BuildFolders(folder)
	end

	function InterfaceManager:GetWindow()
		return self.Window or self.Library.Windows[1]
	end

	function InterfaceManager:BuildInterfaceSection(tab, column)
		self.Settings = self.Settings or { MenuKey = "RightShift", Scale = 100, Hotkeys = false }

		local section = tab:Section("interface", column or 1)
		local window = self:GetWindow()

		local menuKey = section:Keybind({
			Text = "menu key",
			Flag = "interface_menu_key",
			Default = self.Settings.MenuKey,
			OnChanged = function(key)
				self.Settings.MenuKey = key or ""
				self.Library:SetToggleKey(key)
			end,
		})

		local scale = section:Slider({
			Text = "ui scale",
			Flag = "interface_scale",
			Min = 70,
			Max = 130,
			Suffix = "%",
			Default = self.Settings.Scale,
			Callback = function(v)
				self.Settings.Scale = v
				local win = self:GetWindow()
				if win then win:SetUserScale(v / 100) end
			end,
		})

		local hotkeys = section:Toggle({
			Text = "keybind panel",
			Flag = "interface_hotkeys",
			Hint = "shows active keybinds on screen",
			Default = self.Settings.Hotkeys == true,
			Callback = function(state)
				self.Settings.Hotkeys = state
				self.Library:SetHotkeysVisible(state)
			end,
		})

		section:Button({
			Text = "unload",
			Callback = function()
				local window = self:GetWindow()
				if not window then return self.Library:Destroy() end
				window:Confirm({
					Title = "unload",
					Text = "Unload the interface? Unsaved changes will be lost.",
					Confirm = "unload",
					Cancel = "cancel",
					OnConfirm = function() self.Library:Destroy() end,
				})
			end,
		})

		menuKey:Set(self.Settings.MenuKey)
		scale:Set(self.Settings.Scale)
		hotkeys:Set(self.Settings.Hotkeys == true)

		self.Section = section
		return section
	end

	function Library:Warn(title, text, duration)
		return self:Notify({ Title = title, Text = text, Duration = duration, Style = "warning" })
	end

	function Library:Error(title, text, duration)
		return self:Notify({ Title = title, Text = text, Duration = duration, Style = "danger" })
	end

	function Library:Success(title, text, duration)
		return self:Notify({ Title = title, Text = text, Duration = duration, Style = "success" })
	end

	return InterfaceManager
end
