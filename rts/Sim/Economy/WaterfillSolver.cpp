/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#include "WaterfillSolver.h"
#include <algorithm>
#include <cmath>

#include "System/Misc/TracyDefs.h"

namespace Economy {

float WaterfillSolver::EffectiveSupply(
    const WaterfillMember& m,
    float target,
    float taxRate
) const {
    if (m.current <= target + EPSILON) {
        return 0.0f;
    }

    float grossDelta = m.current - target;
    float taxFree = std::min(grossDelta, m.allowance);
    float taxable = std::max(0.0f, grossDelta - m.allowance);
    float afterTax = taxable * (1.0f - taxRate);

    return taxFree + afterTax;
}

float WaterfillSolver::Demand(const WaterfillMember& m, float target) const {
    if (m.current >= target - EPSILON) {
        return 0.0f;
    }
    return target - m.current;
}

float WaterfillSolver::Balance(
    const std::vector<WaterfillMember>& members,
    float lift,
    float taxRate
) const {
    float supply = 0.0f;
    float demand = 0.0f;

    for (const auto& m : members) {
        float target = std::min(m.shareTarget + lift, m.storage);
        supply += EffectiveSupply(m, target, taxRate);
        demand += Demand(m, target);
    }

    return supply - demand;
}

WaterfillResult WaterfillSolver::Solve(
    const std::vector<WaterfillMember>& members,
    float taxRate
) const {
    ZoneScopedN("WaterfillSolve");

    WaterfillResult result;
    result.deltas.resize(members.size());

    if (members.empty()) {
        result.lift = 0.0f;
        return result;
    }

    float maxLift = 0.0f;
    for (const auto& m : members) {
        float headroom = m.storage - m.shareTarget;
        maxLift = std::max(maxLift, headroom);
    }

    float lo = 0.0f;
    float hi = maxLift;

    {
        ZoneScopedN("WaterfillBinarySearch");
        for (int i = 0; i < LIFT_ITERATIONS; ++i) {
            float mid = 0.5f * (lo + hi);
            if (Balance(members, mid, taxRate) >= 0.0f) {
                lo = mid;
            } else {
                hi = mid;
            }
        }
    }

    result.lift = lo;
    TracyPlot("Economy/Lift", static_cast<double>(result.lift));

    for (size_t i = 0; i < members.size(); ++i) {
        const auto& m = members[i];
        float target = std::min(m.shareTarget + result.lift, m.storage);

        WaterfillDelta& d = result.deltas[i];

        if (m.current > target + EPSILON) {
            d.gross = -(m.current - target);
            float grossSend = -d.gross;
            float taxFree = std::min(grossSend, m.allowance);
            float taxable = std::max(0.0f, grossSend - m.allowance);
            d.taxed = taxable * taxRate;
            d.net = -(taxFree + taxable - d.taxed);
        } else if (m.current < target - EPSILON) {
            d.gross = target - m.current;
            d.net = d.gross;
            d.taxed = 0.0f;
        } else {
            d.gross = 0.0f;
            d.net = 0.0f;
            d.taxed = 0.0f;
        }
    }

    return result;
}

} // namespace Economy


