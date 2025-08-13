#include "ReclaimIncomeHandler.h"
#include "Game/GameHelper.h"
#include "Lua/LuaHandle.h"
#include "Lua/LuaHandleSynced.h"
#include "Game/Game.h"
#include "System/Log/ILog.h"

ReclaimIncomeResult CReclaimIncomeHandler::ProcessReclaimIncome(const ReclaimIncomeData& data) {
    ReclaimIncomeResult result;
    result.finalAmount = data.amount;
    result.taxAmount = 0.0f;
    result.blocked = false;
    
    if (CallLuaReclaimIncomeProcessor(data, result)) {
        return result;
    }
    
    return result;
}

bool CReclaimIncomeHandler::CallLuaReclaimIncomeProcessor(const ReclaimIncomeData& data, ReclaimIncomeResult& result) {
    if (!luaHandleSynced || !luaHandleSynced->IsValid()) {
        return false;
    }
    
    game->SetGameRulesParam("ReclaimIncomeData_reclaimingTeam", data.reclaimingTeam);
    game->SetGameRulesParam("ReclaimIncomeData_sourceTeam", data.sourceTeam);
    game->SetGameRulesParam("ReclaimIncomeData_resourceType", data.resourceType);
    game->SetGameRulesParam("ReclaimIncomeData_amount", data.amount);
    game->SetGameRulesParam("ReclaimIncomeData_sourceUnitDefID", data.sourceUnitDefID);
    game->SetGameRulesParam("ReclaimIncomeData_sourceFeatureDefID", data.sourceFeatureDefID);
    
    std::string msg = "SyncedActionFallback:ProcessReclaimIncome";
    luaHandleSynced->RecvLuaMsg(msg, 0);
    
    result.finalAmount = game->GetGameRulesParam("ReclaimIncomeResult_finalAmount");
    result.taxAmount = game->GetGameRulesParam("ReclaimIncomeResult_taxAmount");
    result.blocked = (game->GetGameRulesParam("ReclaimIncomeResult_blocked") != 0.0f);
    
    game->SetGameRulesParam("ReclaimIncomeData_reclaimingTeam", 0);
    game->SetGameRulesParam("ReclaimIncomeData_sourceTeam", 0);
    game->SetGameRulesParam("ReclaimIncomeData_resourceType", 0);
    game->SetGameRulesParam("ReclaimIncomeData_amount", 0);
    game->SetGameRulesParam("ReclaimIncomeData_sourceUnitDefID", 0);
    game->SetGameRulesParam("ReclaimIncomeData_sourceFeatureDefID", 0);
    game->SetGameRulesParam("ReclaimIncomeResult_finalAmount", 0);
    game->SetGameRulesParam("ReclaimIncomeResult_taxAmount", 0);
    game->SetGameRulesParam("ReclaimIncomeResult_blocked", 0);
    
    return true;
}
