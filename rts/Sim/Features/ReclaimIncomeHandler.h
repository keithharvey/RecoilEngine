#ifndef RECLAIM_INCOME_HANDLER_H
#define RECLAIM_INCOME_HANDLER_H

#include "System/creg/creg_cond.h"

struct ReclaimIncomeData {
    int reclaimingTeam;
    int sourceTeam;
    int resourceType; // 0 = metal, 1 = energy
    float amount;
    int sourceUnitDefID;
    int sourceFeatureDefID;
};

struct ReclaimIncomeResult {
    float finalAmount;
    float taxAmount;
    bool blocked;
};

class CReclaimIncomeHandler {
public:
    static ReclaimIncomeResult ProcessReclaimIncome(const ReclaimIncomeData& data);
    static bool CallLuaReclaimIncomeProcessor(const ReclaimIncomeData& data, ReclaimIncomeResult& result);
};

#endif // RECLAIM_INCOME_HANDLER_H
