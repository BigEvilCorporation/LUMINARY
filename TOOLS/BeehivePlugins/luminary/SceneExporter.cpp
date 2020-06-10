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

			std::map<std::string, EntityExporter::ExportedSpawnData> exportedSpawnDatas;

			// ============================================================================================
			//Export dynamic entity and component spawn data tables
			// ============================================================================================
			for (int i = 0; i < sceneData.dynamicEntities.size(); i++)
			{
				const Entity& entity = sceneData.dynamicEntities[i];
				std::stringstream spawnDataName;
				spawnDataName << "SceneEntitySpawnData_" << sceneName << "_" << entity.typeName << "_" << entity.spawnData.name;
				stream << EntityExporter::ExportEntitySpawnTableData(spawnDataName.str(), entity, exportedSpawnDatas);
			}

			stream << std::endl;

			// ============================================================================================
			//Export static entities
			// ============================================================================================
			for (int i = 0; i < sceneData.staticEntities.size(); i++)
			{
				const Entity& entity = sceneData.staticEntities[i];
				stream << "SceneEntity_" << sceneName << "_" << entity.typeName << "_" << entity.spawnData.name << ":" << std::endl;
				stream << EntityExporter::ExportStaticEntityData(entity);
			}

			stream << std::endl;

			// ============================================================================================
			//Export static entity spawn tables
			// ============================================================================================
			stream << "SceneEntityDataStatic_" << sceneName << ":" << std::endl;

			for (int i = 0; i < sceneData.staticEntities.size(); i++)
			{
				const Entity& entity = sceneData.staticEntities[i];
				stream << "\tdc.l " << "SceneEntity_" << sceneName << "_" << entity.typeName << "_" << entity.spawnData.name << std::endl;
			}

			stream << std::endl;

			// ============================================================================================
			//Export dynamic entity spawn tables
			// ============================================================================================
			stream << "SceneEntityDataDynamic_" << sceneName << ":" << std::endl;

			for (int i = 0; i < sceneData.dynamicEntities.size(); i++)
			{
				const Entity& entity = sceneData.dynamicEntities[i];

				std::stringstream spawnDataName;
				spawnDataName << "SceneEntity_" << sceneName << "_" << entity.typeName << "_" << entity.spawnData.name << ":" << std::endl;

				std::map<std::string, EntityExporter::ExportedSpawnData>::const_iterator it = exportedSpawnDatas.find(entity.spawnData.name);
				if (it != exportedSpawnDatas.end())
				{
					spawnDataName.str(it->second.labelName);
				}

				ion::Vector2i extents(entity.spawnData.width / 2, entity.spawnData.height / 2);

				// SceneEntity
				stream << "\tdc.w " << entity.typeName << "_Typedesc\t; SceneEntity_EntityType" << std::endl;
				stream << "\tdc.l " << spawnDataName.str() << "\t; SceneEntity_SpawnData" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.spawnData.positionX) << "\t; SceneEntity_PosX" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.spawnData.positionY) << "\t; SceneEntity_PosY" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.x) << "\t; SceneEntity_ExtentsX" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.y) << "\t; SceneEntity_ExtentsY" << std::endl;
			}

			stream << std::endl;

			// ============================================================================================
			// Export scene
			// ============================================================================================

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