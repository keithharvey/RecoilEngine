/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#ifndef LUA_CONST_POLICY_TYPE_H
#define LUA_CONST_POLICY_TYPE_H

struct lua_State;

class LuaConstPolicyType {
	public:
		static bool PushEntries(lua_State* L);
};

#endif /* LUA_CONST_POLICY_TYPE_H */
