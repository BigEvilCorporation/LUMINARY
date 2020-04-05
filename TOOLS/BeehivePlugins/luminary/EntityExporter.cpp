// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 6th December 2019
// ============================================================================================
// EntityExporter.cpp - Exports entities and archetypes
// ============================================================================================

#include "EntityExporter.h"
#include <ion/io/File.h>
#include <sstream>

namespace luminary
{
	EntityExporter::EntityExporter()
	{

	}

	std::string EntityExporter::CreateDebugNameData(const std::string& name, int maxLength)
	{
		if (name.size() > maxLength)
		{
			return "\"" + name.substr(0, maxLength) + "\"";
		}
		else
		{
			std::string out = "\"" + name + "\"";

			for (int i = 0; i < maxLength - name.size(); i++)
			{
				out += ",0";
			}

			return out;
		}
	}

	bool EntityExporter::ExportArchetypes(const std::string& filename, const std::vector<Archetype>& archetypes)
	{
		ion::io::File file(filename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			std::stringstream stream;

			for (int i = 0; i < archetypes.size(); i++)
			{
				const Archetype& archetype = archetypes[i];

				//Export to file
				stream << "Archetype_" << archetype.entityTypeName << "_" << archetype.name << ":" << std::endl;

				// IFND FINAL
				// SpawnData_DebugName                     rs.b ENT_DEBUG_NAME_LEN
				// ENDIF

				stream << "\tIFND FINAL" << std::endl;
				stream << "\tdc.b " << EntityExporter::CreateDebugNameData(archetype.name, s_debugNameLen) << std::endl;
				stream << "\tENDIF" << std::endl;

				//Export entity params
				for (int j = 0; j < archetype.params.size(); j++)
				{
					const Param& param = archetype.params[j];
					std::string value = param.value;
					if (value.size() == 0)
						value = "0";

					switch (param.size)
					{
					case ParamSize::Byte:
						stream << "\tdc.b " << value << "\t; " << param.name << std::endl;
						break;
					case ParamSize::Word:
						stream << "\tdc.w " << value << "\t; " << param.name << std::endl;
						break;
					case ParamSize::Long:
						stream << "\tdc.l " << value << "\t; " << param.name << std::endl;
						break;
					}
				}

				//Export component params
				for (int j = 0; j < archetype.components.size(); j++)
				{
					const Component& component = archetype.components[j];
					if (component.spawnData.params.size() > 0)
					{
						stream << "\t; " << component.name << std::endl;

						for (int k = 0; k < component.spawnData.params.size(); k++)
						{
							const Param& param = component.spawnData.params[k];
							std::string value = param.value;
							if (value.size() == 0)
								value = "0";

							switch (param.size)
							{
							case ParamSize::Byte:
								stream << "\tdc.b " << value << "\t; " << param.name << std::endl;
								break;
							case ParamSize::Word:
								stream << "\tdc.w " << value << "\t; " << param.name << std::endl;
								break;
							case ParamSize::Long:
								stream << "\tdc.l " << value << "\t; " << param.name << std::endl;
								break;
							}
						}

						stream << "\teven" << std::endl;
					}
				}

				stream << std::endl;
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();

			return true;
		}

		return false;
	}
}