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
		bool GenerateComponentCppHeader(const std::vector<Component>& components, const std::string& outputDir);
		bool GenerateEntityCppHeader(const Entity& entity, const std::string& outputDir);
		bool GenerateEntityCppBoilerplate(const Entity& entity, const std::string& outputDir);
		bool GenerateGlobalOffsetTable(const std::vector<Entity>& entities, const std::vector<Component>& components, std::vector<ScriptFunc>& table, const std::string& asmFilename);
	};

	class ScriptCompiler
	{
	public:
		std::string GetBinPath(const std::string& compilerDir);
		std::string GetLibExecPath(const std::string& compilerDir, const std::string& compilerVer);
		std::string GenerateCompileCommand(const std::string& filename, const std::string& outname, const std::string& compilerDir, const std::vector<std::string>& includeDirs, const std::vector<std::string>& defines);
		std::string GenerateObjCopyCommand(const std::string& filename, const std::string& outname, const std::string& compilerDir);
		std::string GenerateSymbolReadCommand(const std::string& filename, const std::string& outname, const std::string& compilerDir);
		int ReadRelocationTable(const std::vector<std::string>& symbolOutput, const std::vector<ScriptFunc> globalOffsetsTable, std::vector<ScriptRelocation>& relocationTable);
		int FindFunctionOffset(const std::vector<std::string>& symbolOutput, const std::string& className, const std::string& name);
		int FindGlobalVarOffset(const std::vector<std::string>& symbolOutput, const std::string& typeName);
		int LinkProgram(const std::string& filename, std::vector<ScriptRelocation>& relocationTable, u16 globalOffsetTableSize, u16 binaryStartOffset);
	};
}