if (SpringUnsynced.GetConfigInt('Headless', 0) == 0) then
   return false
end

function widget:GetInfo()
   return {
      name = "HeadlessSetup",
      desc = "Setup for headless botrunner games.",
      author = "aegis",
      date = "October 18, 2009",
      license = "Public Domain",
      layer = 0,
      enabled = true,
   }
end

local startingSpeed = 120
local timer
local headless

function widget:Initialize()
   headless = (SpringUnsynced.GetConfigInt('Headless', 0) ~= 0)
   if (headless) then
      SpringShared.Echo('Prepping for headless...')
      SpringUnsynced.SendCommands(
         string.format('setmaxspeed %i', startingSpeed),
         string.format('setminspeed %i', startingSpeed),
         'hideinterface'
         )
   end
end

function widget:GameStart()
   SpringShared.Echo('Game started... starting timer.')
   timer = SpringUnsynced.GetTimer()
end

function widget:GameOver()
   local time = SpringUnsynced.DiffTimers(SpringUnsynced.GetTimer(), timer)
   SpringShared.Echo(string.format('Game over, realtime: %i seconds, gametime: %i seconds', time, SpringShared.GetGameSeconds()))
end

