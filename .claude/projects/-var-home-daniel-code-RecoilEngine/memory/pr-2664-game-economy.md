---
name: pr-2664-game-economy
description: Status and design decisions for PR 2664 (game_economy modrule / ProcessEconomy economy boundary), incl. sprunk's review asks
metadata:
  type: project
---

PR https://github.com/beyond-all-reason/RecoilEngine/pull/2664 (branch `eco`) adds a `gameEconomy` modrule that hands the TA-style resource economy to Lua via a `ProcessEconomy` synced call-in. Pairs with BAR gadget `luarules/gadgets/game_resource_transfer_controller.lua` (waterfill solver) at /var/home/daniel/code/Beyond-All-Reason.

Reviewer **sprunk** (collaborator) is skeptical; he raised several points. State as of 2026-06-18:

DONE
- **Criticism A (return values):** `ProcessEconomy` is now fire-and-forget (`pcall(...,0,0)`); engine applies nothing. Deleted `LuaUtils::ParseEconomyResult`. Gadget applies results itself via `Spring.SetTeamResource` (pools) + new `Spring.AddTeamResourceStats` (sent/received/excess stats, mirrors sprunk's suggested `spAddTeamResourceStats`). Behavior-preserving.
- **Dec 8 ask (gate legacy resourcing lines behind modrule):** gated in Unit.cpp (`SetStorage` in dtor + FinishedBuilding; buildDecay refund; the WHOLE per-unit production/upkeep block incl. mex/wind/tidal in SlowUpdate) and Factory.cpp `StopBuild` refund.
- **Take command:** decoupled from `gameEconomy`; `allowTake` is sole control (gameEconomy games must set `allowTake=false` themselves).
- **Double-registration guard:** `SetEconomyController`/`SetUnitTransferController` now `luaL_error` if already registered (was silent replace).

DEFERRED / OPEN
- **Criticism B (single c++ event client):** `SetEconomyController` bespoke single-ref registration + `MANAGED_BIT` is unchanged. Do NOT claim resolved when pinging sprunk. User's stance: single controller is intentional (economy has no associative merge rule, unlike the Allow family) — defend rather than convert to a broadcast `gadget:ProcessEconomy` callin. The guard above hardens that defense.
- **Re-registration lifecycle:** hard guard breaks gadget re-enable without full `/luarules reload` (no unregister API). Open: add `SetEconomyController(nil)` release path + gadget `Shutdown`.

All 224 BAR busted specs pass (run via `lx --lua-version 5.1 test`). Engine compiles (user builds via BAR-Devtools). See [[user-comment-style]].
