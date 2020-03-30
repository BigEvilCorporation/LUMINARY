// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th February 2020
// ============================================================================================
// ScriptCompiler.h - Entity script to C++ transpiler, and C++ compiler interface
// ============================================================================================

#pragma once

#include "Types.h"

#include <string>
#include <vector>

namespace luminary
{
	class ScriptTranspiler
	{
	public:
		bool GenerateEntityCppHeader(const Entity& entity, const std::string& outputDir);
		bool GenerateEntityCppBoilerplate(const Entity& entity, const std::string& outputDir);
	};

	class ScriptCompiler
	{
	public:
		std::string GetBinPath(const std::string& compilerDir);
		std::string GetLibExecPath(const std::string& compilerDir, const std::string& compilerVer);
		std::string GenerateCompileCommand(const std::string& filename, const std::string& compilerDir, const std::string& includeDirs);
		std::string GenerateObjCopyCommand(const std::string& filename, const std::string& compilerDir);
		std::string GenerateSymbolReadCommand(const std::string& filename, const std::string& compilerDir);
		int FindFunctionOffset(const std::vector<std::string>& symbolOutput, const std::string& className, const std::string& name);
		int FindGlobalVarOffset(const std::vector<std::string>& symbolOutput, const std::string& typeName);
	};
}