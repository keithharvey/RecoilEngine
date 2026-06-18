---
name: pr-2664-game-economy
description: Status and design decisions for PR 2664 (game_economy modrule / ProcessEconomy economy boundary), incl. sprunk's review asks
metadata:
  type: project
---

PR https://github.com/beyond-all-reason/RecoilEngine/pull/2664 (branch `eco`) adds a `gameEconomy` modrule that hands the TA-style resource economy to Lua via a `ProcessEconomy` synced call-in. Pairs with BAR gadget `luarules/gadgets/game_resource_transfer_controller.lua` (waterfill solver) at /var/home/daniel/code/Beyond-All-Reason.

**Design frame (the line `gameEconomy` actually draws) — CORRECTED 2026-06-18:** `gameEconomy` replaces only the **distribution** layer, NOT production. Earlier "engine=consumption, game=production+distribution" framing was WRONG and caused a 0-income regression (see below).
- **Engine = data plane for ALL per-unit/per-frame resource flow**: production (income/upkeep/mex/wind/tidal/`resourceMake` — Unit.cpp:1066 block), consumption (weapon fire `Weapon.cpp:488`/`BeamLaser.cpp:189`; nanolathe `AddBuildPower`→`UseResources`), refunds (build-decay Unit.cpp:1042, factory-cancel Factory.cpp:318), and storage capacity (`SetStorage` at Unit.cpp:126 dtor + :431 FinishedBuilding). All ungated.
- **Lua (`gameEconomy`) = distribution only**: the waterfill solver replaces the engine's native ally excess-sharing (Team.cpp:342 else-branch), and team transfers route through Lua (Team.cpp:221). The BAR solver is purely *redistributive* — it reads `current`/`storage` from the snapshot and moves resources between allies; it generates NO income and sets NO storage. So those MUST stay engine-side.
- Why not move per-unit flow to Lua: `ProcessEconomy` is a tick-aggregate callin; per-unit per-frame production/consumption can't be reconstructed from it (and perf). Build-step consumption COULD move via `AllowUnitBuildStep` (BAR uses it for tech tax), but kept engine-side as a deliberate tradeoff. Weapons have no fire-time hook anyway (`AllowWeaponTarget*` = targeting only).

Reviewer **sprunk** (collaborator) is skeptical; he raised several points. State as of 2026-06-18:

DONE
- **Criticism A (return values):** `ProcessEconomy` is now fire-and-forget (`pcall(...,0,0)`); engine applies nothing. Deleted `LuaUtils::ParseEconomyResult`. Gadget applies results itself via `Spring.SetTeamResource` (pools) + new `Spring.AddTeamResourceStats` (sent/received/excess stats, mirrors sprunk's suggested `spAddTeamResourceStats`). Behavior-preserving.
- **Dec 8 ask (gate legacy resourcing lines behind modrule):** the ONLY correct gates are distribution — native ally excess-sharing (Team.cpp:342 else-branch) and team transfers (Team.cpp:221), plus the `ProcessEconomy` fire site (TeamHandler.cpp:143).
- **Over-gates from commit `447c2070ea` REVERTED (2026-06-18):** that "sprung flagged gameEconomy cleanup" commit over-gated FOUR per-unit things that all had to be un-gated because the BAR solver doesn't replace them:
  - production block (Unit.cpp:1066, mex/wind/tidal/`resourceMake`/upkeep) → caused **0 income** in-game (reported symptom: pool starts at 1000, spends down via ungated consumption, never refills). Solver is redistributive only.
  - storage registration (`SetStorage` Unit.cpp:126 dtor + :431 FinishedBuilding) → solver READS `resource.storage` from snapshot (LuaHandleSynced.cpp:750-751 ← `team->resStorage`) but never sets it; gating froze team capacity.
  - build-decay refund (Unit.cpp:1042) + factory-cancel refund (Factory.cpp:318) → refund side of nanolathe consumption; gating only the refund (not `AddBuildPower` consumption) gave consume-but-never-give-back.
- **Take command:** decoupled from `gameEconomy`; `allowTake` is sole control (gameEconomy games must set `allowTake=false` themselves).
- **Double-registration guard:** `SetEconomyController`/`SetUnitTransferController` now `luaL_error` if already registered (was silent replace).

DEFERRED / OPEN
- **Criticism B (single c++ event client):** `SetEconomyController` bespoke single-ref registration + `MANAGED_BIT` is unchanged. Do NOT claim resolved when pinging sprunk. User's stance: single controller is intentional (economy has no associative merge rule, unlike the Allow family) — defend rather than convert to a broadcast `gadget:ProcessEconomy` callin. The guard above hardens that defense.
- **Re-registration lifecycle:** hard guard breaks gadget re-enable without full `/luarules reload` (no unregister API). Open: add `SetEconomyController(nil)` release path + gadget `Shutdown`.
- **sprunk's latest comment (weapon calls):** flagged `Weapon.cpp:488` + `BeamLaser.cpp:189` as "unaffected resource-related legacy calls." User's position (correct): intentional — these are consumption events, defended via the design frame above. Do NOT claim consumption is "impossible" gameside (sprunk would point at the tax gadget using `AllowUnitBuildStep`); frame as deliberate tradeoff.

Reply drafts (user's voice, copy-paste ready): `/tmp/sprunk-reply-2664.md` (main review summary) and `/tmp/sprunk-reply-2664-weapons.md` (standalone reply to the weapon-calls comment). NOT yet posted — user posts manually via gh/web.

All 224 BAR busted specs pass (run via `lx --lua-version 5.1 test`). Engine compiles (user builds via BAR-Devtools). See [[user-comment-style]].
