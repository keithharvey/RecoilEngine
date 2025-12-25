/* This file is part of the Recoil engine (GPL v2 or later). */

#include "EconomyAudit.h"
#include "System/FileSystem/DataDirLocater.h"
#include "System/Log/ILog.h"
#include <cstdio>

#define LOG_SECTION_ECONOMY_AUDIT "EconomyAudit"
LOG_REGISTER_SECTION_GLOBAL(LOG_SECTION_ECONOMY_AUDIT)

EconomyAudit& EconomyAudit::GetInstance() {
	static EconomyAudit instance;
	return instance;
}

EconomyAudit& economyAudit = EconomyAudit::GetInstance();

void EconomyAudit::Init() {
	// Check if economy audit section is enabled in springsettings
	enabled = log_frontend_isEnabled(LOG_LEVEL_INFO, LOG_SECTION_ECONOMY_AUDIT);
	
	if (!enabled) {
		LOG("[EconomyAudit] Disabled (set LogSections = EconomyAudit:30 to enable)");
		return;
	}

	// Open dedicated log file in writeable data directory
	logFilePath = dataDirLocater.GetWriteDirPath() + "economy_audit.txt";
	logFile.open(logFilePath, std::ios::out | std::ios::trunc);
	
	if (!logFile.is_open()) {
		LOG_L(L_ERROR, "[EconomyAudit] Failed to open %s", logFilePath.c_str());
		enabled = false;
		return;
	}
	
	LOG("[EconomyAudit] Logging to %s", logFilePath.c_str());
}

void EconomyAudit::Shutdown() {
	if (logFile.is_open()) {
		logFile.close();
	}
	enabled = false;
}

void EconomyAudit::Begin(const std::string& path, int f) {
	if (!enabled) return;
	sourcePath = path;
	frame = f;
	active = true;
	breakpoints.clear();
	startTime = spring_gettime();
	lastTime = startTime;
}

void EconomyAudit::End() {
	if (!enabled || !active) return;
	LogBreakpoints();
	active = false;
	sourcePath.clear();
	breakpoints.clear();
}

void EconomyAudit::Breakpoint(const std::string& name) {
	if (!enabled || !active) return;
	
	spring_time now = spring_gettime();
	breakpoints.emplace_back(name, (now - lastTime).toMicroSecsi());
	lastTime = now;
}

void EconomyAudit::LogTiming(const std::string& name, long microseconds) {
	if (!enabled || !active) return;
	breakpoints.emplace_back(name, microseconds);
}

long EconomyAudit::TotalMicros() const {
	return (spring_gettime() - startTime).toMicroSecsi();
}

void EconomyAudit::Log(const std::string& eventType, const std::string& jsonData) {
	if (!enabled || !logFile.is_open()) return;
	
	// Build enriched JSON with context prefix
	std::string enriched;
	if (!jsonData.empty() && jsonData[0] == '{') {
		// Insert context after opening brace
		char contextBuf[128];
		snprintf(contextBuf, sizeof(contextBuf), 
			"{\"source_path\":\"%s\",\"frame\":%d,\"game_time\":%.2f,",
			active ? sourcePath.c_str() : "", frame, frame / 30.0);
		enriched = std::string(contextBuf) + jsonData.substr(1);
	} else {
		enriched = jsonData;
	}
	
	// Write to dedicated file as NDJSON
	logFile << eventType << " " << enriched << "\n";
	logFile.flush();
}

void EconomyAudit::LogRaw(const std::string& eventType, const std::string& jsonData) {
	if (!enabled || !logFile.is_open()) return;
	
	// Write directly without context enrichment
	logFile << eventType << " " << jsonData << "\n";
	logFile.flush();
}

void EconomyAudit::LogBreakpoints() {
	char buf[256];
	for (const auto& bp : breakpoints) {
		snprintf(buf, sizeof(buf), "{\"metric\":\"%s\",\"time_us\":%ld}", bp.first.c_str(), bp.second);
		Log("solver_timing", buf);
	}
	
	snprintf(buf, sizeof(buf), "{\"metric\":\"%s_Overall\",\"time_us\":%ld}", sourcePath.c_str(), TotalMicros());
	Log("solver_timing", buf);
}
