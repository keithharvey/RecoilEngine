
if addon.InGetInfo then
	return {
		name    = "Music",
		desc    = "plays music",
		author  = "jK",
		date    = "2012,2013",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

------------------------------------------

SpringUnsynced.SetSoundStreamVolume(0)
local musicfiles = VFS.DirList(LUA_DIRNAME .. "Assets/music", "*.ogg")
if (#musicfiles > 0) then
	SpringUnsynced.PlaySoundStream(musicfiles[ math.random(#musicfiles) ], 1)
	SpringUnsynced.SetSoundStreamVolume(0)
end


function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()

	-- fade in & out music with progress
	if (loadProgress < 0.9) then
		SpringUnsynced.SetSoundStreamVolume(loadProgress)
	else
		SpringUnsynced.SetSoundStreamVolume(0.9 + ((0.9 - loadProgress) * 9))
	end
end


function addon.Shutdown()
	SpringUnsynced.StopSoundStream()
	SpringUnsynced.SetSoundStreamVolume(1)
end
