function widget:GetInfo()
return {
	name    = "Downloader test widget",
	desc    = "a simple test widget to show capabilities of downloader",
	author  = "abma",
	date    = "Nov. 2014",
	license = "GNU GPL, v2 or later",
	layer   = 0,
	enabled = true,
}
end

local LOG_SECTION = "RapidDownload"

local archiveName = "ba:stable"
local archiveType = "game" -- Optional. If undefined it will be auto-detected.

function widget:Initialize()
	SpringShared.Log(LOG_SECTION, LOG.NOTICE, "Starting download of " .. archiveType .. " " .. archiveName)
	VFS.DownloadArchive(archiveName, archiveType)
	-- FIXME: there are issues if multiple archives are queued. Rapid doesn't seem to be shutting down cleanly.
	--VFS.DownloadArchive(archiveName, archiveType)
end

function widget:DownloadStarted(id)
	SpringShared.Log(LOG_SECTION, LOG.NOTICE, "Download started. ID: " .. id)
end

function widget:DownloadQueued(id)
	SpringShared.Log(LOG_SECTION, LOG.NOTICE, "Download queued. ID: " .. id)
end

function widget:DownloadFinished(id)
	SpringShared.Log(LOG_SECTION, LOG.NOTICE, "Download finished. ID: " .. id)
end

function widget:DownloadFailed(id, errorid)
	SpringShared.Log(LOG_SECTION, LOG.NOTICE, "Download failed. ID: " .. id .. ", error ID: " .. errorid)
end

function widget:DownloadProgress(id, downloaded, total)
	SpringShared.Log(LOG_SECTION, LOG.NOTICE, "Download progress. ID: " .. id .. ", progress: " .. downloaded .. "/" .. total)
end

