function gadget:GetInfo()
    return {
        name = "Team Transfer",
        desc = "Provides example /take and /capture commands using the team transfer handler.",
        author = "Spring Engine",
        date = "2025-01-27",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = true,
    }
end

if gadgetHandler:IsSyncedCode() then
    local TeamTransfer = {}
    
    TeamTransfer.REASON = {
        GIVEN                = 1, -- When player explicitly shares units with allies
        CAPTURED             = 2, -- When units are captured from an enemy
        TAKEN                = 4, -- When units are taken from an ally (e.g. idle player)
    }

    GG.TeamTransfer = TeamTransfer

    function gadget:Initialize()
        Script.AddSyncedActionFallback("take", function(msg, playerID)
            return takeCommand(msg, playerID)
        end)
        Script.AddSyncedActionFallback("capture", function(msg, playerID)
            return captureCommand(msg, playerID)
        end)
    end

    function gadget:Shutdown()
        Script.RemoveSyncedActionFallback("take")
        Script.RemoveSyncedActionFallback("capture")
    end
    
    local function getPlayerData(playerID)
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
            return nil
        end
        return playerData
    end

    function takeCommand(msg, playerID)
        local targetTeamStr = string.sub(msg, 5):match("^%s*(%d*)%s*$")
        
        local playerData = getPlayerData(playerID)
        if not playerData then
            Spring.SendMessageToPlayer(playerID, "Take: No human player found")
            return false
        end

        local targetTeamID = (targetTeamStr and targetTeamStr ~= "") and tonumber(targetTeamStr) or nil
        if targetTeamID then
            if not Spring.GetTeamInfo(targetTeamID) then
                Spring.SendMessageToPlayer(playerID, "Take: Invalid team " .. targetTeamID)
                return false
            end

            local targetAllyTeamID = select(4, Spring.GetTeamInfo(targetTeamID))
            if playerData.allyTeamID ~= targetAllyTeamID then
                Spring.SendMessageToPlayer(playerID, "Take: Can only take from allied teams")
                return false
            end

            local hasHumanPlayer = false
            for _, pid in ipairs(Spring.GetPlayerList()) do
                local name, active, spec, teamID, allyTeamID, income, isAI = Spring.GetPlayerInfo(pid)
                if teamID == targetTeamID and (type(isAI) ~= 'boolean' or isAI == false) then
                    hasHumanPlayer = true
                    break
                end
            end

            if hasHumanPlayer then
                Spring.SendMessageToPlayer(playerID, "Take: Team " .. targetTeamID .. " has human players")
                return false
            end

            local units = Spring.GetTeamUnits(targetTeamID)
            for _, unitID in ipairs(units) do
                Spring.TransferUnit(unitID, playerData.teamID, false, TeamTransfer.REASON.TAKEN)
            end

            local metal, energy = Spring.GetTeamResources(targetTeamID)
            if metal > 0 then
                Spring.AddTeamResource(playerData.teamID, "metal", metal)
                Spring.AddTeamResource(targetTeamID, "metal", -metal)
            end
            if energy > 0 then
                Spring.AddTeamResource(playerData.teamID, "energy", energy)
                Spring.AddTeamResource(targetTeamID, "energy", -energy)
            end

            Spring.SendMessageToPlayer(playerID, "Take: Transferred team " .. targetTeamID)
            return true
        else
            local transferredTeams = 0
            for _, teamID in ipairs(Spring.GetTeamList()) do
                if teamID == playerData.teamID then
                    goto continue
                end

                local allyTeamID = select(4, Spring.GetTeamInfo(teamID))
                if playerData.allyTeamID ~= allyTeamID then
                    goto continue
                end

                local hasHumanPlayer = false
                for _, pid in ipairs(Spring.GetPlayerList()) do
                    local name, active, spec, pTeamID, pAllyTeamID, income, isAI = Spring.GetPlayerInfo(pid)
                    if pTeamID == teamID and (type(isAI) ~= 'boolean' or isAI == false) then
                        hasHumanPlayer = true
                        break
                    end
                end

                if not hasHumanPlayer then
                    local units = Spring.GetTeamUnits(teamID)
                    for _, unitID in ipairs(units) do
                        Spring.TransferUnit(unitID, playerData.teamID, false, TeamTransfer.REASON.TAKEN)
                    end

                    local metal, energy = Spring.GetTeamResources(teamID)
                    if metal > 0 then
                        Spring.AddTeamResource(playerData.teamID, "metal", metal)
                        Spring.AddTeamResource(teamID, "metal", -metal)
                    end
                    if energy > 0 then
                        Spring.AddTeamResource(playerData.teamID, "energy", energy)
                        Spring.AddTeamResource(targetTeamID, "energy", -energy)
                    end

                    transferredTeams = transferredTeams + 1
                end

                ::continue::
            end

            if transferredTeams > 0 then
                Spring.SendMessageToPlayer(playerID, "Take: Transferred " .. transferredTeams .. " teams")
                return true
            else
                Spring.SendMessageToPlayer(playerID, "Take: No uncontrolled teams to take from")
                return false
            end
        end
    end

    function captureCommand(msg, playerID)
        local targetTeamStr = string.sub(msg, 8):match("^%s*(%d*)%s*$")
        
        local playerData = getPlayerData(playerID)
        if not playerData then
            Spring.SendMessageToPlayer(playerID, "Capture: No human player found")
            return false
        end
        
        local targetTeamID = (targetTeamStr and targetTeamStr ~= "") and tonumber(targetTeamStr) or nil
        if targetTeamID then
            if not Spring.GetTeamInfo(targetTeamID) then
                Spring.SendMessageToPlayer(playerID, "Capture: Invalid team " .. targetTeamID)
                return false
            end

            local targetAllyTeamID = select(4, Spring.GetTeamInfo(targetTeamID))
            if playerData.allyTeamID == targetAllyTeamID then
                Spring.SendMessageToPlayer(playerID, "Capture: Cannot capture from allied teams")
                return false
            end

            local units = Spring.GetTeamUnits(targetTeamID)
            local capturedUnits = 0
            for _, unitID in ipairs(units) do
                local success = Spring.TransferUnit(unitID, playerData.teamID, true, TeamTransfer.REASON.CAPTURED)
                if success then
                    capturedUnits = capturedUnits + 1
                end
            end

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
            local capturedTeams = 0
            for _, teamID in ipairs(Spring.GetTeamList()) do
                if teamID == playerData.teamID then
                    goto continue
                end

                local allyTeamID = select(4, Spring.GetTeamInfo(teamID))
                if playerData.allyTeamID == allyTeamID then
                    goto continue
                end

                local units = Spring.GetTeamUnits(teamID)
                local capturedUnits = 0
                for _, unitID in ipairs(units) do
                    local success = Spring.TransferUnit(unitID, playerData.teamID, true, TeamTransfer.REASON.CAPTURED)
                    if success then
                        capturedUnits = capturedUnits + 1
                    end
                end

                local metal, energy = Spring.GetTeamResources(teamID)
                if metal > 0 then
                    Spring.AddTeamResource(playerData.teamID, "metal", metal)
                    Spring.AddTeamResource(teamID, "metal", -metal)
                end
                if energy > 0 then
                    Spring.AddTeamResource(playerData.teamID, "energy", energy)
                    Spring.AddTeamResource(targetTeamID, "energy", -energy)
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
