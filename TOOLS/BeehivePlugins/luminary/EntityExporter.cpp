// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 6th December 2019
// ============================================================================================
// EntityExporter.cpp - Exports entities and archetypes
// ============================================================================================

#include "EntityExporter.h"

#include <ion/io/File.h>
#include <ion/core/utils/STL.h>
#include <ion/maths/Vector.h>

#include <sstream>

namespace luminary
{
	EntityExporter::EntityExporter()
	{

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
				stream << ExportSpawnParamsData(archetype.name, 0, archetype.params, archetype.components);
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();

			return true;
		}

		return false;
	}

	bool EntityExporter::ExportPrefabs(const std::string& filename, const std::vector<Prefab>& prefabs)
	{
		ion::io::File file(filename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			std::stringstream stream;

			//Export root datas
			for (auto prefab : prefabs)
			{
				stream << "prefabdata_" << prefab.name << ":" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(prefab.id) << "\t; Prefab_TypeId" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(prefab.children.size()) << "\t; Prefab_ChildCount" << std::endl;
				stream << "\tdc.l prefabspawntable_" << prefab.name << "\t; Prefab_SpawnTable" << std::endl;
				stream << std::endl;
			}

			stream << std::endl;

			//Export entity/component param tables
			std::map<std::string, EntityExporter::ExportedSpawnData> exportedSpawnDatas;

			for (auto prefab : prefabs)
			{
				for (auto child : prefab.children)
				{
					std::stringstream spawnDataName;
					spawnDataName << "prefabchildspawndata_" << prefab.name << "_" << child.name;
					stream << EntityExporter::ExportEntitySpawnTableData(spawnDataName.str(), child, exportedSpawnDatas);
					stream << std::endl;
				}
			}

			stream << std::endl;

			//Export spawn table
			for (auto prefab : prefabs)
			{
				stream << "prefabspawntable_" << prefab.name << ":" << std::endl;

				for (auto child : prefab.children)
				{
					std::stringstream spawnDataName;
					spawnDataName << "prefabchildspawndata_" << prefab.name << "_" << child.name;

					std::map<std::string, EntityExporter::ExportedSpawnData>::const_iterator it = exportedSpawnDatas.find(child.spawnData.name);
					if (it != exportedSpawnDatas.end())
					{
						spawnDataName.str(it->second.labelName);
					}

					ion::Vector2i extents(child.spawnData.width / 2, child.spawnData.height / 2);

					stream << "\tdc.w " << child.name << "_Typedesc\t; Entity descriptor" << std::endl;
					stream << "\tdc.l " << spawnDataName.str() << "\t; Entity spawn data" << std::endl;
					stream << "\tdc.w 0x" << SSTREAM_HEX4(child.spawnData.positionX + extents.x) << "\t; Position X" << std::endl;
					stream << "\tdc.w 0x" << SSTREAM_HEX4(child.spawnData.positionY + extents.y) << "\t; Position Y" << std::endl;
					stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.x) << "\t; ExtentsX" << std::endl;
					stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.y) << "\t; ExtentsY" << std::endl;
					stream << std::endl;
				}

				stream << std::endl;
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();

			return true;
		}

		return false;
	}

	std::string EntityExporter::ExportSpawnParamsData(const std::string& name, unsigned short id, const std::vector<Param>& entityParams, const std::vector<Component>& components)
	{
		std::stringstream stream;

		// IFND FINAL
		// EntitySpawnData_DebugName                     rs.b ENT_DEBUG_NAME_LEN
		// ENDIF
		stream << "\tIFND FINAL" << std::endl;
		stream << "\tdc.b " << EntityExporter::ExportDebugNameData(name, s_debugNameLen) << "\t; EntitySpawnData_DebugName" << std::endl;
		stream << "\tENDIF" << std::endl;

		stream << "\tdc.w 0x" << SSTREAM_HEX4(id) << "\t; EntitySpawnData_Id" << std::endl;

		//Export entity params
		for (int j = 0; j < entityParams.size(); j++)
		{
			const Param& param = entityParams[j];
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
		for (int j = 0; j < components.size(); j++)
		{
			const Component& component = components[j];
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

		return stream.str();
	}

	std::string EntityExporter::ExportStaticEntityData(const Entity& entity)
	{
		std::stringstream stream;

		// IFND FINAL
		// EntityBlock_DebugName                   rs.b ENT_DEBUG_NAME_LEN (16)
		// ENDIF
		// EntityBlock_Flags                       rs.w 1
		// EntityBlock_Next                        rs.w 1
		// Entity_TypeDesc                         rs.w 1; Entity type
		// Entity_Id                               rs.w 1; Unique id
		// Entity_PosX                             rs.l 1; World pos X(16.16)
		// Entity_PosY                             rs.l 1; World pos Y(16.16)
		// Entity_ExtentsX                         rs.w 1; Width in pixels
		// Entity_ExtentsY                         rs.w 1; Height in pixels
		// ...all params

		ion::Vector2i extents(entity.spawnData.width / 2, entity.spawnData.height / 2);

		stream << "\tIFND FINAL" << std::endl;
		stream << "\tdc.b " << EntityExporter::ExportDebugNameData(entity.name, EntityExporter::s_debugNameLen) << std::endl;
		stream << "\tENDIF" << std::endl;
		stream << "\tdc.w 0x0\t; EntityBlock_Flags" << std::endl;
		stream << "\tdc.w 0x0\t; EntityBlock_Next" << std::endl;
		stream << "\tdc.w " << entity.name << "_Typedesc\t; Entity_TypeDesc" << std::endl;
		stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.id) << "\t; Entity_Id" << std::endl;
		stream << "\tdc.l 0x" << SSTREAM_HEX8((entity.spawnData.positionX + extents.x) << 16) << "\t; Entity_PosX" << std::endl;
		stream << "\tdc.l 0x" << SSTREAM_HEX8((entity.spawnData.positionY + extents.y) << 16) << "\t; Entity_PosY" << std::endl;
		stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.x) << "\t; Entity_ExtentsX" << std::endl;
		stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.y) << "\t; Entity_ExtentsY" << std::endl;

		//Export all params
		for (int j = 0; j < entity.spawnData.params.size(); j++)
		{
			const Param& param = entity.spawnData.params[j];
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

		return stream.str();
	}

	std::string EntityExporter::ExportEntitySpawnTableData(const std::string& spawnDataName, const Entity& entity, std::map<std::string, ExportedSpawnData>& exportedSpawnDatas)
	{
		std::stringstream stream;

		//Build spawn data block from entity and all components
		std::vector<const SpawnData*> spawnDataBlock;
		spawnDataBlock.push_back(&entity.spawnData);

		for (int j = 0; j < entity.components.size(); j++)
		{
			spawnDataBlock.push_back(&entity.components[j].spawnData);
		}

		//If spawn data params matches any previously exported, save some space by sharing it
		const ExportedSpawnData* matchingSpawnData = nullptr;
		for (std::map<std::string, ExportedSpawnData>::const_iterator it = exportedSpawnDatas.begin(), end = exportedSpawnDatas.end(); it != end && !matchingSpawnData; ++it)
		{
			bool match = it->second.data.size() == spawnDataBlock.size();

			//Ignoring position, so compare individual SpawnData::params
			for (int j = 0; j < it->second.data.size() && match; j++)
			{
				match = (it->second.data[j]->params == spawnDataBlock[j]->params);
			}

			if (match)
			{
				matchingSpawnData = &it->second;
			}
		}

		if (matchingSpawnData)
		{
			ExportedSpawnData exportedData;
			exportedData.labelName = matchingSpawnData->labelName;
			exportedSpawnDatas.insert(std::make_pair(entity.spawnData.name, exportedData));
		}
		else
		{
			//Export to file
			stream << spawnDataName << ":" << std::endl;
			stream << EntityExporter::ExportSpawnParamsData(entity.name, entity.id, entity.spawnData.params, entity.components);

			ExportedSpawnData exportedData;
			exportedData.labelName = spawnDataName;
			exportedData.data = spawnDataBlock;
			exportedSpawnDatas.insert(std::make_pair(entity.spawnData.name, exportedData));
		}

		return stream.str();
	}

	std::string EntityExporter::ExportDebugNameData(const std::string& name, int maxLength)
	{
		if (name.size() > maxLength - 1)
		{
			return "\"" + name.substr(0, maxLength - 1) + "\",0";
		}
		else
		{
			std::string out = "\"" + name.substr(0, maxLength - 1) + "\"";

			for (int i = 0; i < maxLength - name.size(); i++)
			{
				out += ",0";
			}

			return out;
		}
	}
}