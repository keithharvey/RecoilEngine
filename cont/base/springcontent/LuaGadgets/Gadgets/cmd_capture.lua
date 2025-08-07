--------------------------------------------------------------------------------
-- Capture Command Gadget
--------------------------------------------------------------------------------
--
--  name      = "Capture Command",
--  desc      = "Provides the /capture command to capture units and structures.",
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local gadget = gadget ---@type Gadget

function gadget:GetInfo()
    return {
        name = "Capture Command",
        desc = "Provides the /capture command to capture units and structures.",
        author = "Spring Engine",
        date = "2025",
        license = "GPL v2 or later",
        layer = 0,
        enabled = true
    }
end

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

if gadgetHandler:IsSyncedCode() then
    local spGetPlayerInfo = Spring.GetPlayerInfo
    local spGetTeamInfo = Spring.GetTeamInfo
    local spGetTeamList = Spring.GetTeamList
    local spGetPlayerList = Spring.GetPlayerList
    local spGetTeamUnits = Spring.GetTeamUnits
    local spTransferUnit = Spring.TransferUnit
    local spSendToPlayer = Spring.SendMessageToPlayer

    -- Register this gadget as a handler for /capture commands
    function gadget:Initialize()
        Script.AddSyncedActionFallback("capture", function(msg, playerID)
            return captureCommand(msg, playerID)
        end)
    end

    function gadget:Shutdown()
        Script.RemoveSyncedActionFallback("capture")
    end

    function captureCommand(msg, playerID)
        local targetTeam = string.sub(msg, 8):match("^%s*(%d*)%s*$")

        local actualPlayerID = -1
        local playerData = {}
        if playerID == 0 then
            for _, pid in ipairs(Spring.GetPlayerList()) do
                local name, active, spec, teamID, allyTeamID, income, isAI = Spring.GetPlayerInfo(pid)
                if type(isAI) ~= 'boolean' or isAI == false then
                    actualPlayerID = pid
                    playerData = { teamID = teamID, allyTeamID = allyTeamID }
                    break
                end
            end
        else
            actualPlayerID = playerID
            local name, active, spec, teamID, allyTeamID, income, isAI = Spring.GetPlayerInfo(playerID)
            playerData = { teamID = teamID, allyTeamID = allyTeamID }
        end

        if actualPlayerID == -1 then
            Spring.SendMessageToPlayer(playerID, "Capture: No human player found")
            return false
        end

        local targetTeamID = tonumber(targetTeam)
        if targetTeamID then
            -- Capture from specific team
            if not Spring.GetTeamInfo(targetTeamID) then
                Spring.SendMessageToPlayer(playerID, "Capture: Invalid team " .. targetTeamID)
                return false
            end

            local targetAllyTeamID = select(4, Spring.GetTeamInfo(targetTeamID))
            if playerData.allyTeamID == targetAllyTeamID then
                Spring.SendMessageToPlayer(playerID, "Capture: Cannot capture from allied teams")
                return false
            end

            -- Transfer units and resources (capture)
            local units = Spring.GetTeamUnits(targetTeamID)
            local capturedUnits = 0
            for _, unitID in ipairs(units) do
                local success = Spring.TransferUnit(unitID, playerData.teamID, true, 2) -- 2 = CAPTURED reason
                if success then
                    capturedUnits = capturedUnits + 1
                end
            end

            -- Transfer resources
            local metal, energy = Spring.GetTeamResources(targetTeamID)
            if metal > 0 then
                Spring.AddTeamResource(playerData.teamID, "metal", metal)
                Spring.AddTeamResource(targetTeamID, "metal", -metal)
            end
            if energy > 0 then
                Spring.AddTeamResource(playerData.teamID, "energy", energy)
                Spring.AddTeamResource(targetTeamID, "energy", -energy)
            end

            Spring.SendMessageToPlayer(playerID, "Capture: Captured " .. capturedUnits .. " units from team " .. targetTeamID)
            return true
        else
            -- Capture from all enemy teams
            local capturedTeams = 0
            for _, teamID in ipairs(Spring.GetTeamList()) do
                if teamID == playerData.teamID then
                    goto continue
                end

                local allyTeamID = select(4, Spring.GetTeamInfo(teamID))
                if playerData.allyTeamID == allyTeamID then
                    goto continue
                end

                -- Transfer units and resources (capture)
                local units = Spring.GetTeamUnits(teamID)
                local capturedUnits = 0
                for _, unitID in ipairs(units) do
                    local success = Spring.TransferUnit(unitID, playerData.teamID, true, 2) -- 2 = CAPTURED reason
                    if success then
                        capturedUnits = capturedUnits + 1
                    end
                end

                -- Transfer resources
                local metal, energy = Spring.GetTeamResources(teamID)
                if metal > 0 then
                    Spring.AddTeamResource(playerData.teamID, "metal", metal)
                    Spring.AddTeamResource(teamID, "metal", -metal)
                end
                if energy > 0 then
                    Spring.AddTeamResource(playerData.teamID, "energy", energy)
                    Spring.AddTeamResource(teamID, "energy", -energy)
                end

                if capturedUnits > 0 then
                    capturedTeams = capturedTeams + 1
                end

                ::continue::
            end

            if capturedTeams > 0 then
                Spring.SendMessageToPlayer(playerID, "Capture: Captured from " .. capturedTeams .. " enemy teams")
                return true
            else
                Spring.SendMessageToPlayer(playerID, "Capture: No enemy teams to capture from")
                return false
            end
        end
    end
end 