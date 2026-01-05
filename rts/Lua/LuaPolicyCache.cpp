/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#include "LuaPolicyCache.h"
#include "LuaInclude.h"

namespace LuaPolicyCache {

CPolicyCache policyCache;

void CPolicyCache::Set(int policyType, int senderTeamId, int receiverTeamId, lua_State* L, int tableIdx) {
	PolicyEntry entry;
	
	if (!lua_istable(L, tableIdx))
		return;
	
	lua_pushnil(L);
	while (lua_next(L, tableIdx) != 0) {
		if (lua_isstring(L, -2)) {
			const char* key = lua_tostring(L, -2);
			
			if (lua_isboolean(L, -1)) {
				entry.fields[key] = static_cast<bool>(lua_toboolean(L, -1));
			} else if (lua_isnumber(L, -1)) {
				entry.fields[key] = static_cast<float>(lua_tonumber(L, -1));
			} else if (lua_isstring(L, -1)) {
				entry.fields[key] = std::string(lua_tostring(L, -1));
			}
		}
		lua_pop(L, 1);
	}
	
	cache[policyType][senderTeamId][receiverTeamId] = std::move(entry);
}

bool CPolicyCache::Get(int policyType, int senderTeamId, int receiverTeamId, lua_State* L) {
	auto typeIt = cache.find(policyType);
	if (typeIt == cache.end())
		return false;
	
	auto senderIt = typeIt->second.find(senderTeamId);
	if (senderIt == typeIt->second.end())
		return false;
	
	auto receiverIt = senderIt->second.find(receiverTeamId);
	if (receiverIt == senderIt->second.end())
		return false;
	
	const PolicyEntry& entry = receiverIt->second;
	
	lua_createtable(L, 0, entry.fields.size());
	
	for (const auto& [key, value] : entry.fields) {
		lua_pushstring(L, key.c_str());
		
		std::visit([L](auto&& arg) {
			using T = std::decay_t<decltype(arg)>;
			if constexpr (std::is_same_v<T, bool>) {
				lua_pushboolean(L, arg);
			} else if constexpr (std::is_same_v<T, float>) {
				lua_pushnumber(L, arg);
			} else if constexpr (std::is_same_v<T, std::string>) {
				lua_pushstring(L, arg.c_str());
			}
		}, value);
		
		lua_rawset(L, -3);
	}
	
	return true;
}

void CPolicyCache::Invalidate(int policyType, int senderTeamId, int receiverTeamId) {
	if (policyType < 0) {
		cache.clear();
		return;
	}
	
	auto typeIt = cache.find(policyType);
	if (typeIt == cache.end())
		return;
	
	if (senderTeamId < 0) {
		cache.erase(typeIt);
		return;
	}
	
	auto senderIt = typeIt->second.find(senderTeamId);
	if (senderIt == typeIt->second.end())
		return;
	
	if (receiverTeamId < 0) {
		typeIt->second.erase(senderIt);
		return;
	}
	
	senderIt->second.erase(receiverTeamId);
}

void CPolicyCache::Clear() {
	cache.clear();
}

}
