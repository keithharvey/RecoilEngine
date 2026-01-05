/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#ifndef LUA_POLICY_CACHE_H
#define LUA_POLICY_CACHE_H

#include <string>
#include <variant>
#include "System/UnorderedMap.hpp"

struct lua_State;

namespace LuaPolicyCache {

using PolicyValue = std::variant<bool, float, std::string>;
using PolicyFields = spring::unordered_map<std::string, PolicyValue>;

struct PolicyEntry {
	PolicyFields fields;
};

using ReceiverMap = spring::unordered_map<int, PolicyEntry>;
using SenderMap = spring::unordered_map<int, ReceiverMap>;
using PolicyTypeMap = spring::unordered_map<int, SenderMap>;

class CPolicyCache {
public:
	void Set(int policyType, int senderTeamId, int receiverTeamId, lua_State* L, int tableIdx);
	bool Get(int policyType, int senderTeamId, int receiverTeamId, lua_State* L);
	void Invalidate(int policyType = -1, int senderTeamId = -1, int receiverTeamId = -1);
	void Clear();

private:
	PolicyTypeMap cache;
};

extern CPolicyCache policyCache;

}

#endif // LUA_POLICY_CACHE_H
