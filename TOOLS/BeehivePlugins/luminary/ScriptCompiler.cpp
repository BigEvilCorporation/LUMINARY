// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th February 2020
// ============================================================================================
// ScriptCompiler.cpp - Entity script to C++ transpiler, and C++ compiler interface
// ============================================================================================

#include "ScriptCompiler.h"

#include <ion/core/string/String.h>
#include <ion/core/memory/Endian.h>
#include <ion/core/io/File.h>
#include <ion/core/io/FileDevice.h>

#include <sstream>
#include <set>

namespace luminary
{
	struct ScriptEntryPoint
	{
		std::string returnType;
		std::string methodName;
		std::string params;
	};

	const std::string g_compilerExe = "m68k-elf-gcc.exe";
	const std::string g_compilerArg = "-m68000 -O3 -Wall -fno-builtin -nostdlib -n -fno-inline -fpie -x c++ -c -Wl,-N";
	const std::string g_objcopyExe = "m68k-elf-objcopy.exe";
	const std::string g_objcopyArg = "-j .text -O binary";
	const std::string g_symbolReadExe = "m68k-elf-objdump.exe";
	const std::string g_symbolReadArg = "-t -r -C";

	const std::string g_header =
		"// ============================================================================================\n"
		"//   AUTOGENERATED WITH BEEHIVE - DO NOT EDIT MANUALLY\n"
		"// ============================================================================================\n"
		"//   http://www.bigevilcorporation.co.uk\n"
		"// ============================================================================================\n"
		"//   Beehive and LUMINARY Engine (c) Matt Phillips 2020\n"
		"// ============================================================================================\n";


	const std::string g_commonInclude = "Common.h";
	const std::string g_componentsInclude = "Components.h";

	const std::vector<ScriptEntryPoint> g_scriptFuncs =
	{
		{ "void", "OnStart", "const Engine& engine, const Scene& scene" },
		{ "void", "OnShutdown", "const Engine& engine, const Scene& scene" },
		{ "void", "OnUpdate", "const Engine& engine, const Scene& scene" },
	};

	bool ScriptTranspiler::GenerateComponentCppHeader(const std::vector<Component>& components, const std::string& outputDir)
	{
		std::string filename = outputDir + "\\" + g_componentsInclude;

		ion::io::File file(filename, ion::io::File::OpenMode::Write);
		if (file.IsOpen())
		{
			std::stringstream stream;
			std::set<std::string> exportedComponentHeaders;

			for (int i = 0; i < components.size(); i++)
			{
				if (exportedComponentHeaders.find(components[i].name) == exportedComponentHeaders.end())
				{
					stream << "struct " << components[i].name << " : ComponentBase" << std::endl;
					stream << "{" << std::endl;

					int structSize = 0;

					for (int j = 0; j < components[i].params.size(); j++)
					{
						std::string paramName = ion::string::RemoveSubstring(components[i].params[j].name, components[i].name + "_");
						paramName[0] = ion::string::ToLower(paramName)[0];

						switch (components[i].params[j].size)
						{
							case ParamSize::Byte:
								stream << "\tchar " << paramName << ";" << std::endl;
								structSize += 1;
								break;
							case ParamSize::Word:
								stream << "\tshort " << paramName << ";" << std::endl;
								structSize += 2;
								break;
							case ParamSize::Long:
								stream << "\tint " << paramName << ";" << std::endl;
								structSize += 4;
								break;
						}
					}

					if (structSize & 1)
					{
						stream << "\tunsigned char padding;" << std::endl;
					}

					if (components[i].scriptFuncs.size() > 0)
					{
						stream << std::endl;

						for (int j = 0; j < components[i].scriptFuncs.size(); j++)
						{
							stream << "\t" << components[i].scriptFuncs[j].returnType << " " << components[i].scriptFuncs[j].name << "(";

							for (int k = 0; k < components[i].scriptFuncs[j].params.size(); k++)
							{
								stream << components[i].scriptFuncs[j].params[k].first << " "<< components[i].scriptFuncs[j].params[k].second;

								if (k != components[i].scriptFuncs[j].params.size() - 1)
								{
									stream << ", ";
								}
							}

							stream << ");" << std::endl;
						}
					}

					stream << "};" << std::endl << std::endl;

					exportedComponentHeaders.insert(components[i].name);
				}
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
			return true;
		}

		return false;
	}

	bool ScriptTranspiler::GenerateEntityCppHeader(const Entity& entity, const std::string& outputDir)
	{
		std::string filename = outputDir + "\\" + entity.typeName + ".h";

		ion::io::File file(filename, ion::io::File::OpenMode::Write);
		if (file.IsOpen())
		{
			std::stringstream stream;

			stream << g_header << std::endl << std::endl;
			stream << "#include <" << g_commonInclude + ">" << std::endl;
			stream << "#include <" << g_componentsInclude + ">" << std::endl << std::endl;

			stream << "struct " << entity.typeName << " : Entity" << std::endl;
			stream << "{" << std::endl;

			stream << "\tstruct Components" << std::endl;
			stream << "\t{" << std::endl;

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

				stream << "\t\tComponentHndl " << nameNumbered << ";" << std::endl;
			}

			stream << "\t};" << std::endl << std::endl;
			
			int structSize = 0;

			for (int i = 0; i < entity.params.size(); i++)
			{
				std::string paramName = ion::string::RemoveSubstring(entity.params[i].name, entity.typeName + "_");
				paramName[0] = ion::string::ToLower(paramName)[0];

				switch (entity.params[i].size)
				{
				case ParamSize::Byte:
					stream << "\tchar " << paramName << ";" << std::endl;
					structSize += 1;
					break;
				case ParamSize::Word:
					stream << "\tshort " << paramName << ";" << std::endl;
					structSize += 2;
					break;
				case ParamSize::Long:
					stream << "\tint " << paramName << ";" << std::endl;
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
		std::string filename = outputDir + "\\" + entity.typeName + ".cpp";

		ion::io::File file(filename, ion::io::File::OpenMode::Write);
		if (file.IsOpen())
		{
			std::stringstream stream;
			stream << "#include \"" << entity.typeName << ".h\"" << std::endl << std::endl;

			for (auto func : g_scriptFuncs)
			{
				stream << func.returnType << " " << entity.typeName << "::" << func.methodName << "(" << func.params << ")" << std::endl;
				stream << "{" << std::endl << std::endl << "}" << std::endl << std::endl;
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
			return true;
		}

		return false;
	}

	bool ScriptTranspiler::GenerateGlobalOffsetTable(const std::vector<Entity>& entities, const std::vector<Component>& components, std::vector<ScriptFunc>& table, const std::string& asmFilename)
	{
		int scriptFuncIdx = 0;

		for (auto entity : entities)
		{
			for (auto scriptFunc : entity.scriptFuncs)
			{
				table.push_back(scriptFunc);
				table.back().tableOffset = scriptFuncIdx++;
			}
		}

		for (auto entity : entities)
		{
			for (auto scriptFunc : entity.scriptFuncs)
			{
				table.push_back(scriptFunc);
				table.back().tableOffset = scriptFuncIdx++;
			}
		}

		for (auto component : components)
		{
			for (auto scriptFunc : component.scriptFuncs)
			{
				table.push_back(scriptFunc);
				table.back().tableOffset = scriptFuncIdx++;
			}
		}

		ion::io::File file(asmFilename, ion::io::File::OpenMode::Write);
		if (file.IsOpen())
		{
			std::stringstream stream;

			for (auto scriptFunc : table)
			{
				stream << "\t dc.l " << scriptFunc.routine << "\t\t; " << scriptFunc.returnType << " " << scriptFunc.scope << "::" << scriptFunc.name << "(";

				for (int i = 0; i < scriptFunc.params.size(); i++)
				{
					stream << scriptFunc.params[i].first << " " << scriptFunc.params[i].second;

					if (i != scriptFunc.params.size() - 1)
						stream << ", ";
				}

				stream << ")" << std::endl;
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
			return true;
		}

		return false;
	}

	std::string ScriptCompiler::GetBinPath(const std::string& compilerDir)
	{
		return ion::io::FileDevice::GetDefault()->GetMountPoint() + "\\" + ion::io::FileDevice::GetDefault()->GetDirectory() + "\\" + compilerDir + "\\" + "bin";
	}

	std::string ScriptCompiler::GetLibExecPath(const std::string& compilerDir, const std::string& compilerVer)
	{
		return ion::io::FileDevice::GetDefault()->GetMountPoint() + "\\"
			+ ion::io::FileDevice::GetDefault()->GetDirectory() + "\\"
			+ compilerDir + "\\libexec\\gcc\\m68k-elf\\" + compilerVer;
	}

	std::string ScriptCompiler::GenerateCompileCommand(const std::string& filename, const std::string& outname, const std::string& compilerDir, const std::vector<std::string>& includeDirs, const std::vector<std::string>& defines)
	{
		std::string cmdLine = GetBinPath(compilerDir) + "\\" + g_compilerExe + " " + g_compilerArg + " -B" + compilerDir;

		for (auto include : includeDirs)
		{
			cmdLine += " -I" + include;
		}

		for (auto define : defines)
		{
			cmdLine += " -D" + define;
		}
			
		cmdLine += " " + filename + " -o " + outname + ".o";

		return cmdLine;
	}

	std::string ScriptCompiler::GenerateObjCopyCommand(const std::string& filename, const std::string& outname, const std::string& compilerDir)
	{
		return GetBinPath(compilerDir) + "\\" + g_objcopyExe + " " + g_objcopyArg + " " + outname + ".o " + outname + ".bin";
	}

	std::string ScriptCompiler::GenerateSymbolReadCommand(const std::string& filename, const std::string& outname, const std::string& compilerDir)
	{
		return GetBinPath(compilerDir) + "\\" + g_symbolReadExe + " " + g_symbolReadArg + " " + outname + ".o ";
	}

	int ScriptCompiler::ReadRelocationTable(const std::vector<std::string>& symbolOutput, const std::vector<ScriptFunc> globalOffsetsTable, std::vector<ScriptRelocation>& relocationTable)
	{
		for (auto line : symbolOutput)
		{
			//TODO: A bit primitive, will have many edge cases
			if (line.find("R_68K_GOT") != std::string::npos)
			{
				std::vector<std::string> tokens;
				ion::string::TokeniseByWhitespace(line, tokens);

				//Need at least 3 tokens - address, type, name
				if (tokens.size() >= 3)
				{
					ScriptRelocation entry;
					entry.address = std::stoul(tokens[0], nullptr, 16);

					std::vector<std::string> nameTokens;
					ion::string::Tokenise(tokens[2], nameTokens, "::");

					std::vector<char> stripChars = { ':', '(', ')' };

					if (nameTokens.size() == 2)
					{
						//Scoped C++ function
						entry.scope = ion::string::Strip(nameTokens[0], stripChars);

						//todo : substr up to first (
						int bracketPos = nameTokens[1].find('(');
						if (bracketPos != std::string::npos)
						{
							entry.name = ion::string::Strip(nameTokens[1].substr(0, bracketPos), stripChars);
						}
						else
						{
							entry.name = ion::string::Strip(nameTokens[1], stripChars);
						}

						//Match with GOT entry
						entry.tableIdx = -1;
						
						for (int i = 0; i < globalOffsetsTable.size(); i++)
						{
							if (entry.scope == globalOffsetsTable[i].scope && entry.name == globalOffsetsTable[i].name)
							{
								entry.tableIdx = i;
								break;
							}
						}
					}
					else if (nameTokens.size() == 1)
					{
						//Global, or the GOT
						entry.name = ion::string::Strip(nameTokens[0], stripChars);
					}

					relocationTable.push_back(entry);
				}
			}
		}

		//First entry should be the GOT, or there's a problem
		if (relocationTable.size() == 0 || relocationTable[0].name != "_GLOBAL_OFFSET_TABLE_")
		{
			relocationTable.clear();
		}

		return relocationTable.size();
	}

	int ScriptCompiler::FindFunctionOffset(const std::vector<std::string>& symbolOutput, const std::string& className, const std::string& name)
	{
		for (auto line : symbolOutput)
		{
			//TODO: A bit primitive, will have many edge cases
			if (line.find(className) != std::string::npos && line.find(name) != std::string::npos)
			{
				std::vector<std::string> tokens;
				ion::string::TokeniseByWhitespace(line, tokens);
				std::string addressHexText = tokens[0];
				return std::stoul(addressHexText, nullptr, 16);
			}
		}

		return -1;
	}

	int ScriptCompiler::FindGlobalVarOffset(const std::vector<std::string>& symbolOutput, const std::string& typeName)
	{
		for (auto line : symbolOutput)
		{
			//TODO: A bit primitive, will have many edge cases
			std::string searchTermRef = "static const " + typeName + "&";
			std::string searchTermPtr = "static const " + typeName + "*";

			if (line.find(searchTermRef) != std::string::npos || line.find(searchTermPtr) != std::string::npos)
			{
				std::vector<std::string> tokens;
				ion::string::TokeniseByWhitespace(line, tokens);
				std::string addressHexText = tokens[0];
				return std::stoul(addressHexText, nullptr, 16);
			}
		}

		return -1;
	}

	int ScriptCompiler::LinkProgram(const std::string& filename, std::vector<ScriptRelocation>& relocationTable, u16 globalOffsetTableSize, u16 binaryStartOffset)
	{
		ion::io::File file(filename, ion::io::File::OpenMode::Edit);
		if (file.IsOpen())
		{
			for (auto entry : relocationTable)
			{
				file.Seek(entry.address, ion::io::SeekMode::Start);

				if (entry.name == "_GLOBAL_OFFSET_TABLE_")
				{
					//Offset from PC to global offset table
					u16 tableOffsetShort = -entry.address - binaryStartOffset - globalOffsetTableSize;
					ion::memory::EndianSwap(tableOffsetShort);
					file.Write(&tableOffsetShort, sizeof(u16));
				}
				else
				{
					//Offset into global offset table (longword per entry)
					u16 tableOffsetShort = entry.tableIdx * sizeof(u32);
					ion::memory::EndianSwap(tableOffsetShort);
					file.Write(&tableOffsetShort, sizeof(u16));
				}
			}

			return file.GetSize();
		}

		return 0;
	}
}