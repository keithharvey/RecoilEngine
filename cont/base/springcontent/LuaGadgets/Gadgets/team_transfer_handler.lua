function gadget:GetInfo()
	return {
		name      = "Team Transfer Handler",
		desc      = "Provides default handlers for team transfer events.",
		author    = "Spring Engine",
		date      = "2024",
		license   = "GPL-v2",
		layer     = -1, -- Ensures it runs before other gadgets
		enabled   = true,
	}
end

if not gadgetHandler:IsSyncedCode() then
	return
end

-- Define the enum values that match C++ ChangeTeamReasonCpp
-- This serves as a base for games to extend.
GG.CHANGETEAM_REASON = GG.CHANGETEAM_REASON or {}
GG.CHANGETEAM_REASON.RECLAIMED = 0
GG.CHANGETEAM_REASON.GIVEN = 1
GG.CHANGETEAM_REASON.CAPTURED = 2

------------------------------------------------------------------------------------------------
-- Handler functions
------------------------------------------------------------------------------------------------

local function HandleAllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, reason)
	-- Default implementation allows all transfers.
	-- Games can override this to add custom logic.
	return true
end

local function HandleTeamTransfer(unitID, oldTeam, newTeam, reason)
	-- This is the base handler for the TeamTransfer event.
	-- It calls the legacy UnitGiven/UnitTaken events for backward compatibility.

	if reason == GG.CHANGETEAM_REASON.GIVEN then
		gadgetHandler:UnitGiven(unitID, Spring.GetUnitDefID(unitID), oldTeam, newTeam)
	else
		-- All other reasons are considered a "take" for legacy purposes.
		gadgetHandler:UnitTaken(unitID, Spring.GetUnitDefID(unitID), oldTeam, newTeam)
	end
end

local function HandleBuilderCapture(unitID, oldTeam, newTeam, reason)
	-- Default implementation for builder capture.
	-- Transfers the unit with the CAPTURED reason.
	Spring.TransferUnit(unitID, newTeam, false, GG.CHANGETEAM_REASON.CAPTURED)
end

local function HandleNetShareTransfer(unitID, oldTeam, newTeam, reason)
	-- Default implementation for network share transfers.
	-- Transfers the unit with the GIVEN reason.
	Spring.TransferUnit(unitID, newTeam, true, GG.CHANGETEAM_REASON.GIVEN)
end

local function HandleTeamGiveEverything(unitID, oldTeam, newTeam, reason)
	-- Default implementation for GiveEverythingTo transfers.
	-- Transfers the unit with the GIVEN reason.
	Spring.TransferUnit(unitID, newTeam, true, GG.CHANGETEAM_REASON.GIVEN)
end

------------------------------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------------------------------

function gadget:Initialize()
	-- Register for AllowUnitTransfer callins
	gadgetHandler:AddSyncAction("AllowUnitTransfer", function(unitID, unitDefID, oldTeam, newTeam, reason)
		return HandleAllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, reason)
	end)

	-- Register for team transfer events
	gadgetHandler:AddSyncAction("TeamTransfer", function(unitID, oldTeam, newTeam, reason)
		return HandleTeamTransfer(unitID, oldTeam, newTeam, reason)
	end)

	-- Register for builder capture events
	gadgetHandler:AddSyncAction("BuilderCapture", function(unitID, oldTeam, newTeam, reason)
		return HandleBuilderCapture(unitID, oldTeam, newTeam, reason)
	end)

	-- Register for network share transfers
	gadgetHandler:AddSyncAction("NetShareTransfer", function(unitID, oldTeam, newTeam, reason)
		return HandleNetShareTransfer(unitID, oldTeam, newTeam, reason)
	end)
	
	-- Register for team give-everything transfers
	gadgetHandler:AddSyncAction("TeamGiveEverything", function(unitID, oldTeam, newTeam, reason)
		return HandleTeamGiveEverything(unitID, oldTeam, newTeam, reason)
	end)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("AllowUnitTransfer")
	gadgetHandler:RemoveSyncAction("TeamTransfer")
	gadgetHandler:RemoveSyncAction("BuilderCapture")
	gadgetHandler:RemoveSyncAction("NetShareTransfer")
	gadgetHandler:RemoveSyncAction("TeamGiveEverything")
end
