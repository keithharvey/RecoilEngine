function widget:GetInfo()
  return {
    name      = "Start Point Adder",
    desc      = "Add team start points once the game begins",
    author    = "abma",
    date      = "July 05, 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

function widget:Initialize()
	local _, _, spec = SpringShared.GetPlayerInfo(SpringUnsynced.GetMyPlayerID())
	if spec then
		widgetHandler:RemoveWidget()
		return false
	end
end

function widget:Update()
	if (SpringShared.GetGameSeconds() > 0) then
		local x, y, z = SpringShared.GetTeamStartPosition(SpringUnsynced.GetMyTeamID())
		local id=SpringUnsynced.GetMyPlayerID()
		SpringUnsynced.MarkerAddPoint(x, y, z, "Start " .. id )
		widgetHandler:RemoveWidget()
	end
end
