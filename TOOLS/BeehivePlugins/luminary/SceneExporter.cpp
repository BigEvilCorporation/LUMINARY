// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th August 2019
// ============================================================================================
// SceneExporter.cpp - Utilities for exporting Beehive GameObject data to Luminary scene,
// entity and component spawn data
// ============================================================================================

#include "SceneExporter.h"
#include "EntityExporter.h"

#include <ion/io/File.h>
#include <ion/core/utils/STL.h>
#include <ion/maths/Vector.h>

#include <sstream>
#include <map>

namespace luminary
{
	SceneExporter::SceneExporter()
	{

	}

	bool SceneExporter::ExportScene(const std::string& filename, const std::string& sceneName, const SceneData& sceneData)
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

			//Export dynamic entity and component spawn data tables
			for (int i = 0; i < sceneData.dynamicEntities.size(); i++)
			{
				const Entity& entity = sceneData.dynamicEntities[i];
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

					// IFND FINAL
					// SpawnData_DebugName                     rs.b ENT_DEBUG_NAME_LEN
					// ENDIF

					stream << "\tIFND FINAL" << std::endl;
					stream << "\tdc.b " << EntityExporter::CreateDebugNameData(entity.name, EntityExporter::s_debugNameLen) << std::endl;
					stream << "\tENDIF" << std::endl;

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

			//Export static entities
				// IFND FINAL
				// EntityBlock_DebugName                   rs.b ENT_DEBUG_NAME_LEN (16)
				// ENDIF
				// EntityBlock_Flags                       rs.w 1
				// EntityBlock_Next                        rs.w 1
				// Entity_TypeDesc                         rs.w 1; Entity type
				// Entity_PosX                             rs.l 1; World pos X(16.16)
				// Entity_PosY                             rs.l 1; World pos Y(16.16)
				// Entity_ExtentsX                         rs.w 1; Width in pixels
				// Entity_ExtentsY                         rs.w 1; Height in pixels
				// ...all params

			for (int i = 0; i < sceneData.staticEntities.size(); i++)
			{
				const Entity& entity = sceneData.staticEntities[i];
				stream << "SceneEntity_" << sceneName << "_" << entity.name << "_" << entity.spawnData.name << ":" << std::endl;

				ion::Vector2i extents(entity.spawnData.width / 2, entity.spawnData.height / 2);

				stream << "\tIFND FINAL" << std::endl;
				stream << "\tdc.b " << EntityExporter::CreateDebugNameData(entity.name, EntityExporter::s_debugNameLen) << std::endl;
				stream << "\tENDIF" << std::endl;
				stream << "\tdc.w 0x0\t; EntityBlock_Flags" << std::endl;
				stream << "\tdc.w 0x0\t; EntityBlock_Next" << std::endl;
				stream << "\tdc.w " << entity.name << "_Typedesc\t; Entity_TypeDesc" << std::endl;
				stream << "\tdc.l 0x" << SSTREAM_HEX8((entity.spawnData.positionX + extents.x)<<16) << "\t; Entity_PosX" << std::endl;
				stream << "\tdc.l 0x" << SSTREAM_HEX8((entity.spawnData.positionY + extents.y)<<16) << "\t; Entity_PosY" << std::endl;
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
			}

			stream << std::endl;

			//Export static entity table
			stream << "SceneEntityDataStatic_" << sceneName << ":" << std::endl;

			for (int i = 0; i < sceneData.staticEntities.size(); i++)
			{
				const Entity& entity = sceneData.staticEntities[i];
				stream << "\tdc.l " << "SceneEntity_" << sceneName << "_" << entity.name << "_" << entity.spawnData.name << std::endl;
			}

			stream << std::endl;

			//Export dynamic entity spawn tables
			stream << "SceneEntityDataDynamic_" << sceneName << ":" << std::endl;

			for (int i = 0; i < sceneData.dynamicEntities.size(); i++)
			{
				const Entity& entity = sceneData.dynamicEntities[i];

				std::stringstream spawnDataName;
				spawnDataName << "SceneEntity_" << sceneName << "_" << entity.name << "_" << entity.spawnData.name << ":" << std::endl;

				std::map<std::string, ExportedSpawnData>::const_iterator it = exportedSpawnDatas.find(entity.spawnData.name);
				if (it != exportedSpawnDatas.end())
				{
					spawnDataName.str(it->second.labelName);
				}

				ion::Vector2i extents(entity.spawnData.width / 2, entity.spawnData.height / 2);

				stream << "\tdc.w " << entity.name << "_Typedesc\t; Entity descriptor" << std::endl;
				stream << "\tdc.l " << spawnDataName.str() << "\t; Entity spawn data" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.spawnData.positionX + extents.x) << "\t; Position X" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.spawnData.positionY + extents.y) << "\t; Position Y" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.x) << "\t; ExtentsX" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.y) << "\t; ExtentsY" << std::endl;
			}

			stream << std::endl;

			// SceneData_GfxTileset                    rs.l 1
			// SceneData_GfxStampset                   rs.l 1
			// SceneData_GfxMapFg                      rs.l 1
			// SceneData_GfxMapBg                      rs.l 1
			// SceneData_ColTileset                    rs.l 1
			// SceneData_ColStampset                   rs.l 1
			// SceneData_ColMap                        rs.l 1
			// SceneData_Palettes                      rs.l 1
			// SceneData_Entities                      rs.l 1
			// SceneData_GfxTileCount                  rs.w 1
			// SceneData_GfxStampCount                 rs.w 1
			// SceneData_GfxMapFgWidthStamps           rs.w 1
			// SceneData_GfxMapFgHeightStamps          rs.w 1
			// SceneData_GfxMapBgWidthStamps           rs.w 1
			// SceneData_GfxMapBgHeightStamps          rs.w 1
			// SceneData_ColTileCount                  rs.w 1
			// SceneData_ColStampCount                 rs.w 1
			// SceneData_ColMapWidthStamps             rs.w 1
			// SceneData_ColMapHeightStamps            rs.w 1
			// SceneData_PaletteCount                  rs.w 1
			// SceneData_StaticEntityCount             rs.w 1
			// SceneData_DynamicEntityCount            rs.w 1

			stream << "SceneData_" << sceneName << ":" << std::endl;
			stream << "\tdc.l " << sceneData.tilesetLabel << "\t; SceneData_GfxTileset" << std::endl;
			stream << "\tdc.l " << sceneData.stampsetLabel << "\t; SceneData_GfxStampset" << std::endl;
			stream << "\tdc.l " << sceneData.mapFgLabel << "\t; SceneData_GfxMapFg" << std::endl;
			stream << "\tdc.l " << sceneData.mapBgLabel << "\t; SceneData_GfxMapBg" << std::endl;
			stream << "\tdc.l " << sceneData.collisionTilesetLabel << "\t; SceneData_ColTileset" << std::endl;
			stream << "\tdc.l " << sceneData.collisionStampsetLabel << "\t; SceneData_ColStampset" << std::endl;
			stream << "\tdc.l " << sceneData.collisionMapLabel << "\t; SceneData_ColMap" << std::endl;
			stream << "\tdc.l " << sceneData.palettesLabel << "\t; SceneData_Palettes" << std::endl;
			stream << "\tdc.l " << "SceneEntityDataStatic_" << sceneName << "\t; SceneData_StaticEntities" << std::endl;
			stream << "\tdc.l " << "SceneEntityDataDynamic_" << sceneName << "\t; SceneData_DynamicEntities" << std::endl;
			stream << "\tdc.w " << sceneData.numTiles << "\t; SceneData_GfxTileCount" << std::endl;
			stream << "\tdc.w " << sceneData.numStamps << "\t; SceneData_GfxStampCount" << std::endl;
			stream << "\tdc.w " << sceneData.mapFgWidthStamps << "\t; SceneData_GfxMapFgWidthStamps" << std::endl;
			stream << "\tdc.w " << sceneData.mapFgHeightStamps << "\t; SceneData_GfxMapFgHeightStamps" << std::endl;
			stream << "\tdc.w " << sceneData.mapBgWidthStamps << "\t; SceneData_GfxMapBgWidthStamps" << std::endl;
			stream << "\tdc.w " << sceneData.mapBgHeightStamps << "\t; SceneData_GfxMapBgHeightStamps" << std::endl;
			stream << "\tdc.w " << sceneData.numCollisionTiles << "\t; SceneData_ColTileCount" << std::endl;
			stream << "\tdc.w " << sceneData.numCollisionStamps << "\t; SceneData_ColStampCount" << std::endl;
			stream << "\tdc.w " << sceneData.collisionMapWidthStamps << "\t; SceneData_ColMapWidthStamps" << std::endl;
			stream << "\tdc.w " << sceneData.collisionMapHeightStamps << "\t; SceneData_ColMapHeightStamps" << std::endl;
			stream << "\tdc.w " << sceneData.numPalettes << "\t; SceneData_PaletteCount" << std::endl;
			stream << "\tdc.w " << sceneData.staticEntities.size() << "\t; SceneData_StaticEntityCount" << std::endl;
			stream << "\tdc.w " << sceneData.dynamicEntities.size() << "\t; SceneData_DynamicEntityCount" << std::endl;

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
		}

		return true;
	}
}