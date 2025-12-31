/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#pragma once

#include <vector>

namespace Economy {

struct WaterfillMember {
    float current;
    float storage;
    float shareTarget;
    float allowance;
};

struct WaterfillDelta {
    float gross;
    float net;
    float taxed;
};

struct WaterfillResult {
    float lift;
    std::vector<WaterfillDelta> deltas;
};

class WaterfillSolver {
public:
    static constexpr float EPSILON = 1e-6f;
    static constexpr int LIFT_ITERATIONS = 40;

    WaterfillResult Solve(
        const std::vector<WaterfillMember>& members,
        float taxRate
    ) const;

private:
    float EffectiveSupply(
        const WaterfillMember& m,
        float target,
        float taxRate
    ) const;

    float Demand(const WaterfillMember& m, float target) const;

    float Balance(
        const std::vector<WaterfillMember>& members,
        float lift,
        float taxRate
    ) const;
};

} // namespace Economy


