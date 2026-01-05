/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#include "LuaConstPolicyType.h"

#include "LuaInclude.h"
#include "LuaUtils.h"

/***
 * Policy type constants for the engine policy cache system.
 *
 * Used with Spring.SetCachedPolicy, Spring.GetCachedPolicy, and Spring.InvalidatePolicyCache.
 *
 * @enum PolicyType
 */

bool LuaConstPolicyType::PushEntries(lua_State* L)
{
	/*** @field PolicyType.MetalTransfer 1 */
	LuaPushNamedNumber(L, "MetalTransfer", 1);
	/*** @field PolicyType.EnergyTransfer 2 */
	LuaPushNamedNumber(L, "EnergyTransfer", 2);
	/*** @field PolicyType.UnitTransfer 3 */
	LuaPushNamedNumber(L, "UnitTransfer", 3);

	return true;
}
