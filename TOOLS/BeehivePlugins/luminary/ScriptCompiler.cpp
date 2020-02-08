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

const std::string g_baseTypes = "typedef unsigned short ComponentHndl;";

const std::string g_blockHeaderStruct =
"struct BlockHeader\n\
{\n\
\tunsigned short flags;\n\
\tunsigned short nextBlock;\n\
};";

const std::string g_entityBaseStruct =
"struct Entity : BlockHeader\n\
{\n\
\tunsigned short typeDesc;\n\
\tunsigned int positionX;\n\
\tunsigned int positionY;\n\
\tunsigned short extentsX;\n\
\tunsigned short extentsY;\n\
};";

const std::string g_getComponentFunc =
"\ttemplate <typename T>\n\
\tinline __attribute__((always_inline)) T& GetComponent(ComponentHndl hndl)\n\
\t{\n\
\t\treturn *((T*)((unsigned int)0x0F000000 | (unsigned int)hndl));\n\
\t}";

const std::string g_funcDeclarations =
"\tvoid OnStart();\n\
\tvoid OnShutdown();\n\
\tvoid OnUpdate();";

namespace luminary
{
	bool ScriptTranspiler::GenerateEntityCppHeader(const Entity& entity, const std::string& outputDir)
	{
		std::string filename = outputDir + "\\" + entity.name + ".h";

		ion::io::File file(filename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			std::stringstream stream;

			stream << g_baseTypes << std::endl << std::endl;
			stream << g_blockHeaderStruct << std::endl << std::endl;
			stream << g_entityBaseStruct << std::endl << std::endl;

			std::set<std::string> exportedComponentHeaders;

			for (int i = 0; i < entity.components.size(); i++)
			{
				if (exportedComponentHeaders.find(entity.components[i].name) == exportedComponentHeaders.end())
				{
					stream << "struct " << entity.components[i].name << " : BlockHeader" << std::endl;
					stream << "{" << std::endl;

					for (int j = 0; j < entity.components[i].params.size(); j++)
					{
						std::string paramName = ion::string::RemoveSubstring(entity.components[i].params[j].name, entity.components[i].name + "_");
						paramName[0] = ion::string::ToLower(paramName)[0];

						switch (entity.components[i].params[j].size)
						{
						case ParamSize::Byte:
							stream << "\tunsigned char " << paramName << ";" << std::endl;
							break;
						case ParamSize::Word:
							stream << "\tunsigned short " << paramName << ";" << std::endl;
							break;
						case ParamSize::Long:
							stream << "\tunsigned int " << paramName << ";" << std::endl;
							break;
						}
					}

					stream << "};" << std::endl << std::endl;

					exportedComponentHeaders.insert(entity.components[i].name);
				}
			}

			stream << "struct " << entity.name << std::endl;
			stream << "{" << std::endl;
			stream << "\tEntity& entity;" << std::endl << std::endl;

			stream << "\tstruct" << std::endl;
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

			stream << "\t} components;" << std::endl << std::endl;

			stream << g_getComponentFunc << std::endl << std::endl;
			stream << g_funcDeclarations << std::endl;

			stream << "};" << std::endl;

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
			return true;
		}

		return false;
	}
}