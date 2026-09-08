local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

repeat
	task.wait()
until LocalPlayer and game:IsLoaded()

local config = getgenv().ban
if type(config) ~= "table" then
	config = {}
	getgenv().ban = config
end

config.auto_rejoin = config.auto_rejoin ~= false
config.allow_kick = config.allow_kick == true

if not config._shield_installed then
	config._shield_installed = true

	local old_kick
	old_kick = hookfunction(LocalPlayer.Kick, function(self, ...)
		if rawequal(self, LocalPlayer) and not config.allow_kick then
			return nil
		end
		return old_kick(self, ...)
	end)
end

LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
	if LocalPlayer.Parent ~= nil or not config.auto_rejoin then
		return
	end

	task.spawn(function()
		for attempt = 1, 10 do
			local ok, err = pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)

			if ok then
				return
			end

			task.wait(0.25)
		end
	end)
end)
