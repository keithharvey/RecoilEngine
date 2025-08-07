# Team Transfer System QA Plan

## Overview

This document outlines the comprehensive testing plan for the new centralized team transfer system. The system replaces scattered `AllowUnitTransfer` implementations with a unified validation chain that consolidates all transfer logic.

## System Architecture Summary

- **Central Handler**: `team_transfer_bar.lua` (layer -1001)
- **Validator Registry**: Gadgets register validation functions instead of implementing `AllowUnitTransfer`
- **Single Entry Point**: All transfers flow through `BARTransfer.ChangeTeamWithReason()`
- **Reason Enum**: `GG.BARTransfer.REASON` replaces scattered enum usage

## Test Matrix: 3 System States

### State 1: Updated (Engine + Game Updated)
- **Engine**: C++ deprecated, calls `SyncedActionFallback` → Lua
- **Game**: New centralized `BARTransfer` system active
- **Expected**: All transfers handled by Lua, validators run in chain

### State 2: Fallbacks (Game Not Updated, Engine Updated)
- **Engine**: C++ deprecated, calls `SyncedActionFallback` but falls back to C++
- **Game**: Old scattered `AllowUnitTransfer` functions active
- **Expected**: C++ fallback logic handles transfers (backward compatibility)

### State 3: Future (Engine Deprecation Applied)
- **Engine**: C++ enum completely removed
- **Game**: Must use new `BARTransfer` system
- **Expected**: Pure Lua implementation, no C++ involvement

---

## Validator Testing

### Core Validators

| Validator | Description | Test Cases | State 1 | State 2 | State 3 |
|-----------|-------------|------------|---------|---------|---------|
| **PreventExcessiveShare** | Unit count limits | Unit limit reached, under limit, cheating enabled | ☐ | ☐ | ☐ |
| **NoShareToEnemy** | Block enemy transfers | Allied transfer, enemy transfer, non-player teams | ☐ | ☐ | ☐ |
| **MarketplaceRequired** | Marketplace validation | Both have markets, missing market, same team | ☐ | ☐ | ☐ |
| **TaxUnitLimit** | Tax system limits | Under tax limit, over tax limit, cheating enabled | ☐ | ☐ | ☐ |
| **DisableUnitSharing** | Complete disable | All sharing blocked, captures allowed | ☐ | ☐ | ☐ |

### Transfer Type Testing

| Transfer Type | Reason Code | Engine Trigger | Test Scenarios | State 1 | State 2 | State 3 |
|---------------|-------------|----------------|----------------|---------|---------|---------|
| **Builder Capture** | `CAPTURED=2` | `BuilderCapture` SyncedActionFallback | Enemy capture, ally capture, invalid units | ☐ | ☐ | ☐ |
| **Team Give Everything** | `GIVEN=1` | `TeamGiveEverything` SyncedActionFallback | Team elimination, manual give, resource limits | ☐ | ☐ | ☐ |
| **Network Share** | `GIVEN=1` | `NetShareTransfer` SyncedActionFallback | Allied share, resource cost, unit limits | ☐ | ☐ | ☐ |
| **Take Command** | `TAKEN=4` | Lua command | Allied take, enemy take, human player check | ☐ | ☐ | ☐ |
| **Market Sales** | `SOLD=5` | Lua trigger | Valid sale, missing marketplace, price validation | ☐ | ☐ | ☐ |
| **Scavenger** | `SCAVENGED=6` | Lua trigger | Scav spawn timing, unit type limits, team validation | ☐ | ☐ | ☐ |
| **Unit Upgrade** | `UPGRADED=7` | Lua trigger | Valid upgrade path, resource costs, tech requirements | ☐ | ☐ | ☐ |
| **Reclaimed** | `RECLAIMED=0` | Direct `ChangeTeam` | Metal reclaim, unit conversion, ownership change | ☐ | ☐ | ☐ |

---

## Integration Testing

### Validator Chain Testing

| Test Case | Validators Involved | Expected Behavior | State 1 | State 2 | State 3 |
|-----------|-------------------|-------------------|---------|---------|---------|
| **Market + Enemy Block** | MarketplaceRequired, NoShareToEnemy | Enemy transfers blocked even with marketplace | ☐ | ☐ | ☐ |
| **Unit Limit + Tax** | PreventExcessiveShare, TaxUnitLimit | Most restrictive limit wins | ☐ | ☐ | ☐ |
| **Share Disabled Override** | DisableUnitSharing + all others | All sharing blocked regardless of other validators | ☐ | ☐ | ☐ |
| **Validator Order** | All validators | Order shouldn't affect final result | ☐ | ☐ | ☐ |
| **Performance** | All validators | No significant latency increase | ☐ | ☐ | ☐ |

### Backward Compatibility

| Scenario | Description | Expected Behavior | State 1 | State 2 | State 3 |
|----------|-------------|-------------------|---------|---------|---------|
| **Missing BARTransfer** | Central system not loaded | Old gadgets use fallback functions | ☐ | ☐ | ☐ |
| **Mixed Versions** | Some gadgets updated, others not | Both systems work without conflict | ☐ | ☐ | ☐ |
| **Old Enum Usage** | Code using `GG.CHANGETEAM_REASON` | Still works but deprecated warnings | ☐ | ☐ | ☐ |
| **Layer Loading** | Gadget load order issues | Central system loads first (-1001) | ☐ | ☐ | ☐ |

---

## Error Handling & Edge Cases

### Error Conditions

| Error Case | Test Input | Expected Behavior | State 1 | State 2 | State 3 |
|------------|------------|-------------------|---------|---------|---------|
| **Invalid Unit ID** | Non-existent unit | Graceful failure, no crash | ☐ | ☐ | ☐ |
| **Invalid Team ID** | Non-existent team | Graceful failure, no crash | ☐ | ☐ | ☐ |
| **Same Team Transfer** | oldTeam == newTeam | Allowed or sensible handling | ☐ | ☐ | ☐ |
| **Unknown Reason** | Invalid reason code | Default allow behavior | ☐ | ☐ | ☐ |
| **Validator Exception** | Validator throws error | Other validators still run | ☐ | ☐ | ☐ |

### Performance Edge Cases

| Performance Test | Scenario | Acceptance Criteria | State 1 | State 2 | State 3 |
|------------------|----------|-------------------|---------|---------|---------|
| **High Frequency** | 100+ transfers per second | No significant frame drops | ☐ | ☐ | ☐ |
| **Many Validators** | 10+ registered validators | Linear performance scaling | ☐ | ☐ | ☐ |
| **Large Teams** | 16+ teams with units | No exponential slowdown | ☐ | ☐ | ☐ |
| **Memory Usage** | Long running games | No memory leaks in validator registry | ☐ | ☐ | ☐ |

---

## Logging & Debugging

### Log Verification

| Log Category | Test Cases | Expected Output | State 1 | State 2 | State 3 |
|--------------|------------|-----------------|---------|---------|---------|
| **Validator Registration** | System startup | "Registered validator: X" for each | ☐ | ☐ | ☐ |
| **Transfer Rejections** | Blocked transfers | "Transfer rejected by validator: X" | ☐ | ☐ | ☐ |
| **Transfer Success** | Allowed transfers | Transfer type and teams logged | ☐ | ☐ | ☐ |
| **Error Conditions** | Invalid inputs | Clear error messages, no spam | ☐ | ☐ | ☐ |

---

## Game Mode Compatibility

### Specific Game Modes

| Game Mode | Special Requirements | Test Cases | State 1 | State 2 | State 3 |
|-----------|-------------------|------------|---------|---------|---------|
| **FFA** | No sharing allowed | All transfers blocked except captures | ☐ | ☐ | ☐ |
| **Coop vs AI** | Unrestricted sharing | All allied transfers allowed | ☐ | ☐ | ☐ |
| **Market Economy** | Marketplace required | Only market sales work | ☐ | ☐ | ☐ |
| **Raptors** | Special raptor rules | Raptor transfers work, player restrictions apply | ☐ | ☐ | ☐ |
| **Scavengers** | Scav unit spawning | Scavenger transfers work independently | ☐ | ☐ | ☐ |

---

## Migration Verification

### Code Quality Checks

| Check | Description | Acceptance Criteria | Status |
|-------|-------------|-------------------|--------|
| **Enum Consolidation** | All `GG.CHANGETEAM_REASON` usage found | Use `GG.BARTransfer.REASON` instead | ☐ |
| **Duplicate Logic Removal** | No scattered reason checking | Central `IsTransferReason()` function used | ☐ |
| **Performance Regression** | No slower than old system | Benchmark transfer operations | ☐ |
| **Memory Usage** | No memory leaks | Monitor validator registry size | ☐ |

### Documentation Verification

| Documentation | Content | Completion | Status |
|---------------|---------|------------|--------|
| **Architecture Overview** | System design explanation | Complete | ☐ |
| **Migration Guide** | How to update existing gadgets | Complete | ☐ |
| **API Reference** | Validator registration examples | Complete | ☐ |
| **Troubleshooting** | Common issues and solutions | Complete | ☐ |

---

## Success Criteria

### Must Pass (Blocking Issues)
- ☐ All transfer types work in State 1 (new system)
- ☐ Backward compatibility maintained in State 2
- ☐ No crashes or infinite loops in any state
- ☐ Performance within 10% of previous system

### Should Pass (Important)
- ☐ All validators work correctly in validator chain
- ☐ Proper error handling for edge cases
- ☐ Clear logging for debugging
- ☐ Game mode specific rules work correctly

### Could Pass (Nice to Have)
- ☐ Performance improvements over old system
- ☐ Enhanced debugging capabilities
- ☐ Simplified gadget development

---

## Test Execution Notes

### Prerequisites
1. Both Spring engine with deprecated C++ enum and BAR with new system
2. Test scenarios for each system state
3. Performance benchmarking tools
4. Log analysis setup

### Test Environment
- Multiple game modes configured
- Various team setups (2v2, FFA, coop)
- Different hardware configurations
- Network and local play testing

### Reporting
- Document all failures with reproduction steps
- Performance metrics comparison
- Log file analysis results
- Validator behavior verification