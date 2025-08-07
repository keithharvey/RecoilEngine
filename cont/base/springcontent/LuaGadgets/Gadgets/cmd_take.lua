--------------------------------------------------------------------------------
-- Take Command Gadget
--------------------------------------------------------------------------------
--
--  name      = "Take Command",
--  desc      = "Provides the /take command to transfer units and resources from allied teams without active players.",
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local gadget = gadget ---@type Gadget

function gadget:GetInfo()
    return {
        name = "Take Command",
        desc = "Provides the /take command to transfer units and resources from allied teams without active players.",
        author = "Spring Engine",
        date = "2025-01-27",
        license = "GNU GPL, v2 or later",
        layer = 1,
        enabled = true,
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
    local spAddTeamResource = Spring.AddTeamResource
    local spSendToPlayer = Spring.SendMessageToPlayer

    -- Register this gadget as a handler for /take commands
    function gadget:Initialize()
        Script.AddSyncedActionFallback("take", function(msg, playerID)
            return takeCommand(msg, playerID)
        end)
    end

    function gadget:Shutdown()
        Script.RemoveSyncedActionFallback("take")
    end

    function takeCommand(msg, playerID)
        local targetTeam = string.sub(msg, 5):match("^%s*(%d*)%s*$")

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
            Spring.SendMessageToPlayer(playerID, "Take: No human player found")
            return false
        end

        local targetTeamID = tonumber(targetTeam)
        if targetTeamID then
            -- Take from specific team
            if not Spring.GetTeamInfo(targetTeamID) then
                Spring.SendMessageToPlayer(playerID, "Take: Invalid team " .. targetTeamID)
                return false
            end

            local targetAllyTeamID = select(4, Spring.GetTeamInfo(targetTeamID))
            if playerData.allyTeamID ~= targetAllyTeamID then
                Spring.SendMessageToPlayer(playerID, "Take: Can only take from allied teams")
                return false
            end

            -- Check if team has human players
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

            -- Transfer units and resources
            local units = Spring.GetTeamUnits(targetTeamID)
            for _, unitID in ipairs(units) do
                Spring.TransferUnit(unitID, playerData.teamID, false, 4) -- 4 = TAKEN reason
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

            Spring.SendMessageToPlayer(playerID, "Take: Transferred team " .. targetTeamID)
            return true
        else
            -- Take from all allied teams without human players
            local transferredTeams = 0
            for _, teamID in ipairs(Spring.GetTeamList()) do
                if teamID == playerData.teamID then
                    goto continue
                end

                local allyTeamID = select(4, Spring.GetTeamInfo(teamID))
                if playerData.allyTeamID ~= allyTeamID then
                    goto continue
                end

                -- Check if team has human players
                local hasHumanPlayer = false
                for _, pid in ipairs(Spring.GetPlayerList()) do
                    local name, active, spec, pTeamID, pAllyTeamID, income, isAI = Spring.GetPlayerInfo(pid)
                    if pTeamID == teamID and (type(isAI) ~= 'boolean' or isAI == false) then
                        hasHumanPlayer = true
                        break
                    end
                end

                if not hasHumanPlayer then
                    -- Transfer units and resources
                    local units = Spring.GetTeamUnits(teamID)
                    for _, unitID in ipairs(units) do
                        Spring.TransferUnit(unitID, playerData.teamID, false, 4) -- 4 = TAKEN reason
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

end 