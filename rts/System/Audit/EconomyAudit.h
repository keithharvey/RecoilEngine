/* This file is part of the Recoil engine (GPL v2 or later). */

#ifndef ECONOMY_AUDIT_H
#define ECONOMY_AUDIT_H

#include <string>
#include <vector>
#include <utility>
#include <fstream>
#include "System/Misc/SpringTime.h"

// Economy audit tracing (resource transfers + solver timings).
// Writes NDJSON to economy_audit.txt in the writeable data dir; enabled via LogSections.
// C++ brackets Lua calls with Begin()/End(); Lua logs via the Spring.EconomyAudit* bindings.
class EconomyAudit {
public:
	static EconomyAudit& GetInstance();

	// Initialize file output (call after DataDirLocater is ready)
	void Init();
	void Shutdown();

	// Context management (called from C++ before/after Lua)
	void Begin(const std::string& sourcePath, int frame);
	void End();

	// Stopwatch functionality
	void Breakpoint(const std::string& name);
	void BreakpointAbsolute(const std::string& name); // Always measures from last C++ checkpoint
	void SaveCheckpoint(); // Save current time for later absolute measurement
	void LogTiming(const std::string& name, long microseconds);
	long TotalMicros() const;

	// Logging (auto-includes context)
	void Log(const std::string& eventType, const std::string& jsonData);
	void LogRaw(const std::string& eventType, const std::string& jsonData); // No context required
	void LogBreakpoints();

	// State queries
	bool IsEnabled() const { return enabled; }
	bool IsActive() const { return active; }
	const std::string& GetSourcePath() const { return sourcePath; }
	int GetFrame() const { return frame; }

private:
	EconomyAudit() = default;
	~EconomyAudit() = default;
	EconomyAudit(const EconomyAudit&) = delete;
	EconomyAudit& operator=(const EconomyAudit&) = delete;

	bool enabled = false;
	bool active = false;
	std::string sourcePath;
	int frame = 0;

	spring_time startTime;
	spring_time lastTime;
	spring_time checkpointTime; // Saved by C++ before entering Lua
	std::vector<std::pair<std::string, long>> breakpoints;

	std::ofstream logFile;
	std::string logFilePath;
};

extern EconomyAudit& economyAudit;

#endif // ECONOMY_AUDIT_H
