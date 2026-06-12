#pragma once

#include <tracy/Tracy.hpp>

#ifdef RECOIL_DETAILED_TRACY_ZONING
	// Use ZoneNamed with a distinct variable name to avoid collision with SCOPED_TIMER's ZoneScopedNC
	#define RECOIL_DETAILED_TRACY_ZONE ZoneNamed(___tracy_detailed_zone, true)
#else
	#define RECOIL_DETAILED_TRACY_ZONE do {} while(0)
#endif
