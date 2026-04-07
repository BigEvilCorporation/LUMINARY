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
#include "Serialiser.h"

#include <ion/core/io/File.h>
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
		SerialiserAsm serialiser(filename);
		if (!serialiser.IsOpen())
			return false;

		std::map<std::string, EntityExporter::ExportedSpawnData> exportedSpawnDatas;

		// ============================================================================================
		//Export dynamic entity and component spawn data tables
		// ============================================================================================
		for (int i = 0; i < sceneData.dynamicEntities.size(); i++)
		{
			const Entity& entity = sceneData.dynamicEntities[i];
			std::string spawnDataName = "SceneEntitySpawnData_" + sceneName + "_" + entity.typeName + "_" + entity.spawnData.name;
			EntityExporter::ExportEntitySpawnTableData(serialiser, spawnDataName, entity, exportedSpawnDatas);
		}

		serialiser.Break();

		// ============================================================================================
		//Export static entities
		// ============================================================================================
		for (int i = 0; i < sceneData.staticEntities.size(); i++)
		{
			const Entity& entity = sceneData.staticEntities[i];
			serialiser.Label("SceneEntity_", sceneName, "_", entity.typeName, "_", entity.spawnData.name);
			EntityExporter::ExportStaticEntityData(serialiser, entity);
		}

		serialiser.Break();

		// ============================================================================================
		//Export static entity spawn tables
		// ============================================================================================
		serialiser.Label("SceneEntityDataStatic_", sceneName);

		for (int i = 0; i < sceneData.staticEntities.size(); i++)
		{
			const Entity& entity = sceneData.staticEntities[i];
			serialiser.Value("SceneEntity_", sceneName, "_", entity.typeName, "_", entity.spawnData.name);
		}

		serialiser.Break();

		// ============================================================================================
		//Export dynamic entity spawn tables
		// ============================================================================================
		serialiser.Label("SceneEntityDataDynamic_", sceneName);

		for (int i = 0; i < sceneData.dynamicEntities.size(); i++)
		{
			const Entity& entity = sceneData.dynamicEntities[i];

			std::string spawnDataName =  "SceneEntity_" + sceneName + "_" + entity.typeName + "_" + entity.spawnData.name;

			std::map<std::string, EntityExporter::ExportedSpawnData>::const_iterator it = exportedSpawnDatas.find(entity.spawnData.name);
			if (it != exportedSpawnDatas.end())
			{
				spawnDataName = it->second.labelName;
			}

			// SceneEntity
			serialiser.Value(entity.typeName, "_Typedesc");
			serialiser.Value(spawnDataName);
			serialiser.Value(entity.spawnData.position,	"SceneEntity_Pos");
			serialiser.Value(entity.spawnData.extents,	"SceneEntity_Extents");
		}

		serialiser.Break();

		// ============================================================================================
		//Export stamp animations
		// ============================================================================================
		serialiser.Label("SceneStampAnims_", sceneName);

		for (int i = 0; i < sceneData.stampAnimations.size(); i++)
		{
			const StampAnim& stampAnim = sceneData.stampAnimations[i];
			serialiser.Value("actor_", stampAnim.actorName, "_spritesheet_", stampAnim.tileSheetName);
			serialiser.Value("actor_", stampAnim.actorName, "_sheet_", stampAnim.tileSheetName, "_anim_", stampAnim.animationName);
			serialiser.Value(stampAnim.tileIndex, "StampAnim_TileIndex");
		}

		serialiser.Break();

		// ============================================================================================
		// Export scene
		// ============================================================================================

		// StreamingMap_PlaneAddr                  rs.l 1
		// StreamingMap_VRAMhndl                   rs.l 1
		// StreamingMap_TileSet                    rs.l 1
		// StreamingMap_StampSet                   rs.l 1
		// StreamingMap_StampMap                   rs.l 1
		// StreamingMap_NumTiles                   rs.w 1
		// StreamingMap_NumStamps                  rs.w 1
		// StreamingMap_WidthStamps                rs.w 1
		// StreamingMap_HeightStamps               rs.w 1
		// StreamingMap_StreamPosX                 rs.w 1
		// StreamingMap_StreamPosY                 rs.w 1
		// StreamingMap_ScrollX                    rs.w 1
		// StreamingMap_ScrollY                    rs.w 1

		u16 zeroW = 0;
		u32 zeroL = 0;

		// FG map
		serialiser.Label("StreamingMap_", sceneName, "_PlaneA");
		serialiser.Value(zeroL,							"StreamingMap_PlaneAddr");
		serialiser.Value(zeroL,							"StreamingMap_VRAMhndl");
		serialiser.Value(sceneData.tilesetFgLabel);
		serialiser.Value(sceneData.stampsetFgLabel);
		serialiser.Value(sceneData.mapFgLabel);
		serialiser.Value(sceneData.numTilesFg,			"StreamingMap_NumTiles");
		serialiser.Value(sceneData.numStampsFg,			"StreamingMap_NumStamps");
		serialiser.Value(sceneData.mapFgWidthStamps,	"StreamingMap_WidthStamps");
		serialiser.Value(sceneData.mapFgHeightStamps,	"StreamingMap_HeightStamps");
		serialiser.Value(zeroW,							"StreamingMap_StreamPosX");
		serialiser.Value(zeroW,							"StreamingMap_StreamPosY");
		serialiser.Value(zeroW,							"StreamingMap_ScrollX");
		serialiser.Value(zeroW,							"StreamingMap_ScrollY");
		serialiser.Break();

		// BG map
		serialiser.Label("StreamingMap_", sceneName, "_PlaneB");
		serialiser.Value(zeroL,							"StreamingMap_PlaneAddr");
		serialiser.Value(zeroL,							"StreamingMap_VRAMhndl");
		serialiser.Value(sceneData.tilesetBgLabel);
		serialiser.Value(sceneData.stampsetBgLabel);
		serialiser.Value(sceneData.mapBgLabel);
		serialiser.Value(sceneData.numTilesBg,			"StreamingMap_NumTiles");
		serialiser.Value(sceneData.numStampsBg,			"StreamingMap_NumStamps");
		serialiser.Value(sceneData.mapBgWidthStamps,	"StreamingMap_WidthStamps");
		serialiser.Value(sceneData.mapBgHeightStamps,	"StreamingMap_HeightStamps");
		serialiser.Value(zeroW,							"StreamingMap_StreamPosX");
		serialiser.Value(zeroW,							"StreamingMap_StreamPosY");
		serialiser.Value(zeroW,							"StreamingMap_ScrollX");
		serialiser.Value(zeroW,							"StreamingMap_ScrollY");
		serialiser.Break();

		// SceneData_StreamingMapFg                rs.l 1
		// SceneData_StreamingMapBg                rs.l 1
		// SceneData_ColTileset                    rs.l 1
		// SceneData_ColStampset                   rs.l 1
		// SceneData_ColMap                        rs.l 1
		// SceneData_Palettes                      rs.l 4
		// SceneData_StaticEntities                rs.l 1
		// SceneData_DynamicEntities               rs.l 1
		// SceneData_StampAnimations               rs.l 1
		// SceneData_ColTileCount                  rs.w 1
		// SceneData_ColStampCount                 rs.w 1
		// SceneData_ColMapWidthStamps             rs.w 1
		// SceneData_ColMapHeightStamps            rs.w 1
		// SceneData_PaletteCount                  rs.w 1
		// SceneData_StaticEntityCount             rs.w 1
		// SceneData_DynamicEntityCount            rs.w 1
		// SceneData_StampAnimCount                rs.w 1

		serialiser.Label("SceneData_", sceneName);
		serialiser.Value("StreamingMap_", sceneName, "_PlaneA");
		serialiser.Value("StreamingMap_", sceneName, "_PlaneB");
		serialiser.Value(sceneData.collisionTilesetLabel);
		serialiser.Value(sceneData.collisionStampsetLabel);
		serialiser.Value(sceneData.collisionMapLabel);

		for(int i = 0; i < sceneData.palettes.size(); i++)
			serialiser.Value(sceneData.palettes[i]);

		serialiser.Value("SceneEntityDataStatic_", sceneName);
		serialiser.Value("SceneEntityDataDynamic_", sceneName);
		serialiser.Value("SceneStampAnims_", sceneName);
		serialiser.Value(sceneData.numCollisionTiles,			"SceneData_ColTileCount");
		serialiser.Value(sceneData.numCollisionStamps,			"SceneData_ColStampCount");
		serialiser.Value(sceneData.collisionMapWidthStamps,		"SceneData_ColMapWidthStamps");
		serialiser.Value(sceneData.collisionMapHeightStamps,	"SceneData_ColMapHeightStamps");
		serialiser.Value((u16)sceneData.staticEntities.size(),	"SceneData_StaticEntityCount");
		serialiser.Value((u16)sceneData.dynamicEntities.size(),	"SceneData_DynamicEntityCount");
		serialiser.Value((u16)sceneData.stampAnimations.size(), "SceneData_StampAnimCount");

		return true;
	}
}