// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th February 2020
// ============================================================================================
// ScriptCompiler.cpp - Entity script to C++ transpiler, and C++ compiler interface
// ============================================================================================

#include "ScriptCompiler.h"

#include <ion/core/string/String.h>
#include <ion/io/File.h>

#include <sstream>
#include <set>

namespace luminary
{
	struct ScriptFunc
	{
		std::string returnType;
		std::string methodName;
		std::string params;
	};

	const std::string g_compilerExe = "m68k-elf-gcc.exe";
	const std::string g_compilerArg = "-m68000 -O3 -Wall -fno-builtin -nostdlib -n -fno-inline -fpie -x c++ -c";
	const std::string g_objcopyExe = "m68k-elf-objcopy.exe";
	const std::string g_objcopyArg = "-j .text -O binary";
	const std::string g_symbolReadExe = "m68k-elf-objdump.exe";
	const std::string g_symbolReadArg = "-t";

	const std::string g_header =
		"// ============================================================================================\n"
		"//   AUTOGENERATED WITH BEEHIVE - DO NOT EDIT MANUALLY\n"
		"// ============================================================================================\n"
		"//   http://www.bigevilcorporation.co.uk\n"
		"// ============================================================================================\n"
		"//   Beehive and LUMINARY Engine (c) Matt Phillips 2020\n"
		"// ============================================================================================\n";


	const std::string g_commonInclude = "#include <Common.h>";

	const std::string g_getComponentFunc =
		"\ttemplate <typename T>\n"
		"\tinline __attribute__((always_inline)) T& GetComponent(ComponentHndl hndl)\n"
		"\t{\n"
		"\t\treturn *((T*)((unsigned int)0x00FF0000 | (unsigned int)hndl));\n"
		"\t}";

	const std::vector<ScriptFunc> g_scriptFuncs =
	{
		{ "void", "OnStart", "" },
		{ "void", "OnShutdown", "" },
		{ "void", "OnUpdate", "" },
	};

	bool ScriptTranspiler::GenerateEntityCppHeader(const Entity& entity, const std::string& outputDir)
	{
		std::string filename = outputDir + "\\" + entity.name + ".h";

		ion::io::File file(filename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			std::stringstream stream;

			stream << g_header << std::endl << std::endl;
			stream << g_commonInclude << std::endl << std::endl;

			std::set<std::string> exportedComponentHeaders;

			for (int i = 0; i < entity.components.size(); i++)
			{
				if (exportedComponentHeaders.find(entity.components[i].name) == exportedComponentHeaders.end())
				{
					stream << "struct " << entity.components[i].name << " : ComponentBase" << std::endl;
					stream << "{" << std::endl;

					int structSize = 0;

					for (int j = 0; j < entity.components[i].params.size(); j++)
					{
						std::string paramName = ion::string::RemoveSubstring(entity.components[i].params[j].name, entity.components[i].name + "_");
						paramName[0] = ion::string::ToLower(paramName)[0];

						switch (entity.components[i].params[j].size)
						{
						case ParamSize::Byte:
							stream << "\tunsigned char " << paramName << ";" << std::endl;
							structSize += 1;
							break;
						case ParamSize::Word:
							stream << "\tunsigned short " << paramName << ";" << std::endl;
							structSize += 2;
							break;
						case ParamSize::Long:
							stream << "\tunsigned int " << paramName << ";" << std::endl;
							structSize += 4;
							break;
						}
					}

					if (structSize & 1)
					{
						stream << "\tunsigned char padding;" << std::endl;
					}

					stream << "};" << std::endl << std::endl;

					exportedComponentHeaders.insert(entity.components[i].name);
				}
			}

			stream << "struct Components" << std::endl;
			stream << "{" << std::endl;

			std::set<std::string> exportedHndls;

			for (int i = 0; i < entity.components.size(); i++)
			{
				std::string componentName = ion::string::StartsWith(entity.components[i].name, "EC") ? ion::string::RemoveSubstring(entity.components[i].name, "EC") : entity.components[i].name;
				componentName[0] = ion::string::ToLower(componentName)[0];

				std::string nameNumbered = componentName;
				int index = 1;

				while (exportedHndls.find(nameNumbered) != exportedHndls.end())
				{
					nameNumbered = componentName + std::to_string(++index);
				}

				exportedHndls.insert(nameNumbered);

				stream << "\tComponentHndl " << nameNumbered << ";" << std::endl;
			}

			stream << "};" << std::endl << std::endl;

			stream << "struct " << entity.name << " : Entity" << std::endl;
			stream << "{" << std::endl;
			
			int structSize = 0;

			for (int i = 0; i < entity.params.size(); i++)
			{
				std::string paramName = ion::string::RemoveSubstring(entity.params[i].name, entity.name + "_");
				paramName[0] = ion::string::ToLower(paramName)[0];

				switch (entity.params[i].size)
				{
				case ParamSize::Byte:
					stream << "\tunsigned char " << paramName << ";" << std::endl;
					structSize += 1;
					break;
				case ParamSize::Word:
					stream << "\tunsigned short " << paramName << ";" << std::endl;
					structSize += 2;
					break;
				case ParamSize::Long:
					stream << "\tunsigned int " << paramName << ";" << std::endl;
					structSize += 4;
					break;
				}
			}

			if (structSize & 1)
			{
				stream << "\tunsigned char padding;" << std::endl;
			}

			stream << std::endl;

			stream << "\tComponents components;" << std::endl << std::endl;

			stream << g_getComponentFunc << std::endl << std::endl;
			
			for (auto func : g_scriptFuncs)
			{
				stream << "\t" << func.returnType << " " << func.methodName << "(" << func.params << ");" << std::endl;
			}

			stream << "};" << std::endl;

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
			return true;
		}

		return false;
	}

	bool ScriptTranspiler::GenerateEntityCppBoilerplate(const Entity& entity, const std::string& outputDir)
	{
		std::string filename = outputDir + "\\" + entity.name + ".cpp";

		ion::io::File file(filename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			std::stringstream stream;
			stream << "#include \"" << entity.name << ".h\"" << std::endl << std::endl;

			for (auto func : g_scriptFuncs)
			{
				stream << func.returnType << " " << entity.name << "::" << func.methodName << "(" << func.params << ")" << std::endl;
				stream << "{" << std::endl << std::endl << "}" << std::endl << std::endl;
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
			return true;
		}

		return false;
	}

	std::string ScriptCompiler::GenerateCompileCommand(const std::string& filename, const std::string& compilerDir, const std::string& includeDirs)
	{
		std::string filenameNoExt = ion::string::RemoveSubstring(filename, ".cpp");
		return compilerDir + "\\" + g_compilerExe + " " + g_compilerArg + " -B" + compilerDir + " -I" + includeDirs + " " + filename + " -o " + filenameNoExt + ".o";
	}

	std::string ScriptCompiler::GenerateObjCopyCommand(const std::string& filename, const std::string& compilerDir)
	{
		std::string filenameNoExt = ion::string::RemoveSubstring(filename, ".cpp");
		return compilerDir + "\\" + g_objcopyExe + " " + g_objcopyArg + " " + filenameNoExt + ".o " + filenameNoExt + ".bin";
	}

	std::string ScriptCompiler::GenerateSymbolReadCommand(const std::string& filename, const std::string& compilerDir)
	{
		std::string filenameNoExt = ion::string::RemoveSubstring(filename, ".cpp");
		return compilerDir + "\\" + g_symbolReadExe + " " + g_symbolReadArg + " " + filenameNoExt + ".o ";
	}

	int ScriptCompiler::FindFunctionOffset(const std::vector<std::string>& symbolOutput, const std::string& className, const std::string& routineName)
	{
		for (auto line : symbolOutput)
		{
			//TODO: A bit primitive, will have many edge cases
			if (line.find(className) != std::string::npos && line.find(routineName) != std::string::npos)
			{
				std::vector<std::string> tokens;
				ion::string::TokeniseByWhitespace(line, tokens);
				std::string addressHexText = tokens[0];
				return std::stoul(addressHexText, nullptr, 16);
			}
		}

		return -1;
	}
}