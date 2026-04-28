function widget:GetInfo()
return {
	name    = "Test-Widget",
	desc    = "Sets Speed + tries to keep framerate + autoexit",
	author  = "abma",
	date    = "Jan. 2015",
	license = "GNU GPL, v2 or later",
	layer   = 0,
	enabled = true,
}
end

local maxframes = 36000 -- run spring 20 minutes (ingame time)
local initialspeed = 120 -- speed at the beginning
local minunits = 10 -- if fewer than this units are created/destroyed print a warning
local timer
local unitscreated = 0
local unitsdestroyed = 0
local maxruntime = 120 -- run at max 2 minutes

local function ShowStats()
	local time = SpringUnsynced.DiffTimers(SpringUnsynced.GetTimer(), timer)
	local gameseconds = SpringShared.GetGameSeconds()
	local speed = gameseconds / time
	SpringShared.Echo("Test done:")
	SpringShared.Echo(string.format("Realtime %is gametime: %is", time, gameseconds ))
	SpringShared.Echo(string.format("Run at %.2fx real time", speed))
	SpringShared.Echo(string.format("Units created: %i Units destroyed: %i", unitscreated, unitsdestroyed))
	if unitscreated <= minunits or unitsdestroyed <= minunits then
		SpringShared.Log("test.lua", LOG.ERROR, string.format("Fewer then minunits %i units were created/destroyed!", minunits))
	end
end

function widget:GameOver()
	SpringUnsynced.SendCommands("quitforce")
	ShowStats()
end

function widget:Update()
	if (SpringUnsynced.DiffTimers(SpringUnsynced.GetTimer(), timer)) > maxruntime then
		SpringShared.Log("test.lua", LOG.WARNING, string.format("Tests run longer than %i seconds, aborting!", maxruntime ))
		SpringUnsynced.SendCommands("pause 1", "quitforce")
	end
end

function widget:Initialize()
	timer = SpringUnsynced.GetTimer()
	SpringUnsynced.SendCommands("setmaxspeed " .. 1000,
		"setminspeed " .. initialspeed,
		"setminspeed 1")
end

function widget:GameFrame(n)
	if n==maxframes then
		ShowStats()
		SpringUnsynced.SendCommands("quitforce")
	end
end


function widget:UnitCreated(unitID, unitDefID, unitTeam)
	unitscreated = unitscreated + 1
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	unitsdestroyed = unitsdestroyed + 1
end

