---
name: pr-2664-game-economy
description: Status, design decisions, and the ECS-economy strategic pivot for PR 2664 (gameEconomy modrule / ProcessEconomy), incl. sprunk's review + competing PR #2642
metadata:
  type: project
---

PR https://github.com/beyond-all-reason/RecoilEngine/pull/2664 (branch `eco`) adds a `gameEconomy` modrule that hands TA-style resource sharing to Lua via a `ProcessEconomy` synced call-in. Pairs with BAR gadget `luarules/gadgets/game_resource_transfer_controller.lua` (waterfill solver) at /var/home/daniel/code/Beyond-All-Reason. Reviewer **sprunk** (collaborator) is deeply skeptical and has a competing minimal PR.

## Where it landed (2026-06-18, after long sprunk negotiation)

**The modrule fell back to redistribution-only**, which undercuts its justification. Key admissions:
- The `gameEconomy` unclamp branch in `Spring.SetTeamResource` (LuaSyncedCtrl.cpp:1457-1489) is a **proven no-op** — the BAR waterfill solver already clamps every team to storage before writing (`economy_waterfill_solver.lua:249-252`), so a normal clamped SetTeamResource gives the identical result. Removable. (Not yet removed — was in plan mode.)
- The genuine load-bearing modrule mechanic is **Team.cpp:342**: under gameEconomy, `SlowUpdate` skips the native storage-clamp + ally-share so overflow survives to the snapshot, where the solver redistributes it to allies before it's wasted. That (+ fire ProcessEconomy at TeamHandler.cpp:143 + route transfers via Lua) is the whole real footprint.

**sprunk's competing PR #2642** `gadget:ResourceExcess(excessTable) -> bool` (per-team over-storage overflow, end of EVERY frame, return true to take over). For redistribution-only it's largely sufficient + cleaner (broadcast, no modrule, no gating). Keith's two real objections, the only axes ProcessEconomy beats it on: **cadence** (#2642 fires every frame; ProcessEconomy at `TEAM_SLOWUPDATE_RATE`) and **payload** (#2642 passes only excess → must `GetTeamResources` re-query every team to rebuild state ProcessEconomy hands over batched). Single-owner is the 3rd diff but Keith concedes that's enforceable game-side. → Counter-position: **broaden #2642 to pass full per-tick state batched at slowupdate cadence; drop the modrule.**

## Strategic pivot: full ownership = native ECS economy, NOT Lua per-step

Keith's real goal is full game ownership of the economy. Decisive finding: **per-step consumption (nanolathe `AddBuildPower`, weapon fire, shields) CANNOT move to interpreted Lua** — faithful behavior needs synchronous per-step gating (slow build when broke), which can't be batched/deferred; each step becomes a C++→Lua synced-callin dispatch + `UseUnitResource` crossing (~50-200× the inline C++ cost), O(active builders/frame), spiking late-game. Structural, not constant-factor. `AllowUnitBuildStep` exists (BAR uses it for tech tax) but unconditional use taxes every step.

**ENTT/ECS is the realistic answer ("native modules" substitute):** Recoil has entt (`rts/lib/entt`, `Sim::registry`); units already have `entityReference` (SolidObject.h:333); systems are static `Update()` classes driven from OO handlers (UnitHandler.cpp:332); `GroundMoveSystem` already does the **batch-with-events** pattern (drains `ChangeHeadingEvent` via one `view.each`); `SaveLoadUtils` serializes components (sync/save path exists). The registry is **NOT Lua-exposed** → the boundary: **observation/accounting can batch to Lua (cheap); per-step CONTROL stays native.** So achievable "full ownership" = native ECS economy (mechanism, fast, configurable via data/policy) + Lua aggregate-distribution callin (policy). This *converges* with sprunk's "engine provides good native systems games configure" stance rather than opposing it.

**Full scope/RFC for the ECS economy refactor: `~/.claude/plans/wondrous-pondering-cookie.md`** (components, systems, migration phases 0-4, determinism risk = entt iteration order, parity burden). It's engine-team-scale, multi-PR — NOT bundled into 2664. Near-term deliverable = "Phase 0" = the broadened batched distribution callin.

## Code state / earlier review history

- **Un-gating commits stand** (`d555364777` production+storage, `3ac65e5840` refunds). sprunk said "put them back," but the redistribution-only decision *reversed* that — production (Unit.cpp:1066), storage (`SetStorage`), and the two refunds (build-decay Unit.cpp:1042, factory-cancel Factory.cpp:318) stay UNGATED because the solver doesn't replace them (gating them caused the 0-income bug). sprunk's "put them back" was premised on full-ownership which isn't happening near-term.
- Criticism A (return values) resolved: `ProcessEconomy` fire-and-forget; gadget applies via `Spring.SetTeamResource` + new `Spring.AddTeamResourceStats`.
- `/take` decoupled from gameEconomy (`allowTake` sole control). Double-registration guard on `SetEconomyController`/`SetUnitTransferController`.
- All 224 BAR busted specs pass (`lx --lua-version 5.1 test`). Engine compiles (Keith builds via BAR-Devtools).

## Negotiation notes

- sprunk fundamentally **doesn't want the modrule** ("faithful drop-in gadgets using existing interfaces" is his preferred migration path). His Dec 8 "gate all the lines + demonstrate a gadget" was a *challenge to prove isolation*, not an endorsement.
- Single-owner: do NOT lean on it as a pro-modrule argument — it's the bespoke `SetEconomyController` registration he already dislikes (Criticism B). Enforce single-owner game-side instead.
- Keith posted (live, not /tmp) a reply committing to: broaden the batched callin, measure full-ownership perf before committing, attempt event-batching, explore the ENTT hybrid, with the honest caveat that full take-over may be infeasible without native modules.
- Old reply drafts `/tmp/sprunk-reply-2664*.md` are superseded by the redistribution/ECS reframe.

See [[user-comment-style]].
