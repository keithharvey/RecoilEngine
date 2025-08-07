function gadget:GetInfo()
	return {
		name = "Team Give Everything",
		desc = "Handles team give-everything transfers via Lua handlers",
		author = "Spring Engine",
		date = "2025",
		license = "GPL v2 or later",
		layer = 0,
		enabled = true
	}
end

-- Register this gadget as a handler for team give-everything transfers
function gadget:Initialize()
	Script.AddSyncedActionFallback("TeamGiveEverything", function(unitID, fromTeam, toTeam, reason)
		return handleTeamGiveEverything(unitID, fromTeam, toTeam, reason)
	end)
	
	Script.AddSyncedActionFallback("TeamGiveEverythingComplete", function(fromTeam, toTeam)
		return gadget:TeamGiveEverything(fromTeam, toTeam)
	end)
end

function gadget:Shutdown()
	Script.RemoveSyncedActionFallback("TeamGiveEverything")
	Script.RemoveSyncedActionFallback("TeamGiveEverythingComplete")
end

function handleTeamGiveEverything(unitID, fromTeam, toTeam, reason)
	-- Check if teams are valid
	if not Spring.IsTeamValid(fromTeam) or not Spring.IsTeamValid(toTeam) then
		return false
	end

	-- Check if unit is valid
	if not Spring.IsUnitValid(unitID) then
		return false
	end

	-- Check if unit belongs to source team
	if Spring.GetUnitTeam(unitID) ~= fromTeam then
		return false
	end

	-- Transfer the unit using the reason-based API
	Spring.TransferUnitWithReason(unitID, toTeam, reason)
	
	return true
end

-- Handle complete team give-everything transfers
function gadget:TeamGiveEverything(fromTeam, toTeam)
	-- Validate teams
	if not Spring.IsTeamValid(fromTeam) or not Spring.IsTeamValid(toTeam) then
		Spring.Log("TeamGiveEverything", LOG.ERROR, "Invalid teams: " .. fromTeam .. " -> " .. toTeam)
		return false
	end

	-- Transfer resources
	local metal, energy = Spring.GetTeamResources(fromTeam)
	if metal > 0 then
		Spring.AddTeamResource(toTeam, "metal", metal)
		Spring.UseTeamResource(fromTeam, "metal", metal)
	end
	if energy > 0 then
		Spring.AddTeamResource(toTeam, "energy", energy)
		Spring.UseTeamResource(fromTeam, "energy", energy)
	end

	-- Transfer all units
	local units = Spring.GetTeamUnits(fromTeam)
	local unitsTransferred = 0

	for _, unitID in ipairs(units) do
		if Spring.IsUnitValid(unitID) and not Spring.GetUnitIsDead(unitID) then
			-- Check if destination team can accept the unit
			if not Spring.IsTeamFull(toTeam) then
				Spring.TransferUnitWithReason(unitID, toTeam, GG.CHANGETEAM_REASON.GIVEN)
				unitsTransferred = unitsTransferred + 1
			end
		end
	end

	-- Log the transfer
	Spring.Log("TeamGiveEverything", LOG.INFO, 
		string.format("Transferred %d units and resources from team %d to team %d", 
			unitsTransferred, fromTeam, toTeam))

	return true
end 