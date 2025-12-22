/* This file is part of the Recoil engine (GPL v2 or later). */

#include "EconomyAudit.h"
#include "System/Log/ILog.h"

#define LOG_SECTION_ECONOMY_AUDIT "EconomyAudit"
LOG_REGISTER_SECTION_GLOBAL(LOG_SECTION_ECONOMY_AUDIT)

#ifdef LOG_SECTION_CURRENT
	#undef LOG_SECTION_CURRENT
#endif
#define LOG_SECTION_CURRENT LOG_SECTION_ECONOMY_AUDIT

EconomyAudit& EconomyAudit::GetInstance() {
	static EconomyAudit instance;
	return instance;
}

EconomyAudit& economyAudit = EconomyAudit::GetInstance();

bool EconomyAudit::IsEnabled() const {
	// Check if EconomyAudit section would actually log at INFO level
	// This respects LogSections config - if not set, defaults to NOTICE (35) which blocks INFO (30)
	return log_frontend_isEnabled(LOG_LEVEL_INFO, LOG_SECTION_ECONOMY_AUDIT);
}

void EconomyAudit::Begin(const std::string& path, int f) {
	sourcePath = path;
	frame = f;
	active = true;
	breakpoints.clear();
	startTime = spring_gettime();
	lastTime = startTime;
}

void EconomyAudit::End() {
	if (IsEnabled() && active) {
		LogBreakpoints();
	}
	active = false;
	sourcePath.clear();
	breakpoints.clear();
}

void EconomyAudit::Breakpoint(const std::string& name) {
	if (!IsEnabled() || !active) return;
	
	spring_time now = spring_gettime();
	breakpoints.emplace_back(name, (now - lastTime).toMicroSecsi());
	lastTime = now;
}

long EconomyAudit::TotalMicros() const {
	return (spring_gettime() - startTime).toMicroSecsi();
}

void EconomyAudit::Log(const std::string& eventType, const std::string& jsonData) {
	if (!IsEnabled() || !active) return;
	
	// Insert source_path, frame, and game_time into the JSON data
	// Assumes jsonData starts with '{' and we inject after it
	char contextBuf[128];
	snprintf(contextBuf, sizeof(contextBuf), 
		"{\"source_path\":\"%s\",\"frame\":%d,\"game_time\":%.8g,", 
		sourcePath.c_str(), frame, frame / 30.0);
	
	std::string enrichedJson;
	if (!jsonData.empty() && jsonData[0] == '{') {
		enrichedJson = std::string(contextBuf) + jsonData.substr(1);
	} else {
		enrichedJson = std::string(contextBuf) + jsonData + "}";
	}
	
	LOG_L(L_INFO, "%s %s", eventType.c_str(), enrichedJson.c_str());
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
