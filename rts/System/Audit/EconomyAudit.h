/* This file is part of the Recoil engine (GPL v2 or later). */

#ifndef ECONOMY_AUDIT_H
#define ECONOMY_AUDIT_H

#include <string>
#include <vector>
#include <utility>
#include "System/Misc/SpringTime.h"
#include "System/Log/ILog.h"

/**
 * Unified economy audit system for tracing resource transfers and solver performance.
 * 
 * Usage from C++:
 *   economyAudit.Begin("PE", frame);  // Set context before calling Lua
 *   ... call Lua ...
 *   economyAudit.End();
 * 
 * Usage from Lua (via Spring.* bindings):
 *   Spring.EconomyAuditLog("team_input", {team_id=0, current=500, ...})
 *   Spring.EconomyAuditBreakpoint("Solver")
 */
class EconomyAudit {
public:
	static EconomyAudit& GetInstance();

	// Context management (called from C++ before/after Lua)
	void Begin(const std::string& sourcePath, int frame);
	void End();

	// Stopwatch functionality
	void Breakpoint(const std::string& name);
	long TotalMicros() const;

	// Logging (auto-includes context)
	void Log(const std::string& eventType, const std::string& jsonData);
	void LogBreakpoints();

	// State queries - IsEnabled checks if logging would actually output
	bool IsEnabled() const;
	bool IsActive() const { return active; }
	const std::string& GetSourcePath() const { return sourcePath; }
	int GetFrame() const { return frame; }

private:
	EconomyAudit() = default;
	~EconomyAudit() = default;
	EconomyAudit(const EconomyAudit&) = delete;
	EconomyAudit& operator=(const EconomyAudit&) = delete;

	bool active = false;
	std::string sourcePath;
	int frame = 0;

	spring_time startTime;
	spring_time lastTime;
	std::vector<std::pair<std::string, long>> breakpoints;
};

extern EconomyAudit& economyAudit;

#endif // ECONOMY_AUDIT_H
