// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th August 2019
// ============================================================================================
// SceneExporter.cpp - Utilities for exporting Beehive GameObject data to Luminary scene,
// entity and component spawn data
// ============================================================================================

#include "SceneExporter.h"

#include <ion/io/File.h>
#include <ion/core/utils/STL.h>

#include <sstream>
#include <map>

namespace luminary
{
	SceneExporter::SceneExporter()
	{

	}

	bool SceneExporter::ExportScene(const std::string& filename, const std::string& sceneName, const std::vector<Entity>& entities)
	{
		ion::io::File file(filename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			std::stringstream stream;

			struct ExportedSpawnData
			{
				std::string labelName;
				std::vector<const SpawnData*> data;
			};

			std::map<std::string, ExportedSpawnData> exportedSpawnDatas;

			//Export entity and component spawn data tables
			for (int i = 0; i < entities.size(); i++)
			{
				const Entity& entity = entities[i];
				std::stringstream spawnDataName;
				spawnDataName << "SceneEntitySpawnData_" << sceneName << "_" << entity.name << "_" << entity.spawnData.name;

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
					stream << spawnDataName.str() << ":" << std::endl;

					//Export entity spawn data
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

					//Export component spawn data
					for (int j = 0; j < entity.components.size(); j++)
					{
						const Component& component = entity.components[j];
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

					ExportedSpawnData exportedData;
					exportedData.labelName = spawnDataName.str();
					exportedData.data = spawnDataBlock;
					exportedSpawnDatas.insert(std::make_pair(entity.spawnData.name, exportedData));
				}
			}

			stream << std::endl;

			//Export entity spawn tables
			stream << "SceneEntityData_" << sceneName << ":" << std::endl;

			for (int i = 0; i < entities.size(); i++)
			{
				const Entity& entity = entities[i];

				std::stringstream spawnDataName;
				spawnDataName << "SceneEntity_" << sceneName << "_" << entity.name << "_" << entity.spawnData.name << ":" << std::endl;

				std::map<std::string, ExportedSpawnData>::const_iterator it = exportedSpawnDatas.find(entity.spawnData.name);
				if (it != exportedSpawnDatas.end())
				{
					spawnDataName.str(it->second.labelName);
				}

				stream << "\tdc.l " << entity.name << "_Typedesc\t; Entity descriptor" << std::endl;
				stream << "\tdc.l " << spawnDataName.str() << "\t; Entity spawn data" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.spawnData.positionX) << "\t; Position X" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.spawnData.positionY) << "\t; Position Y" << std::endl;
			}

			stream << std::endl;

			//Export scene
			stream << "SceneData_" << sceneName << ":" << std::endl;
			stream << "\tdc.w " << entities.size() << "\t; Entity count" << std::endl;
			stream << "\tdc.l " << "SceneEntityData_" << sceneName << "\t; Entity table" << std::endl;

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
		}

		return true;
	}
}