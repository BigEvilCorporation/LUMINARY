// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th August 2019
// ============================================================================================
// SceneExporter.h - Utilities for exporting Beehive GameObject data to Luminary scene,
// entity and component spawn data
// ============================================================================================

#pragma once

#include <string>
#include <vector>

#include "Types.h"

namespace luminary
{
	class SceneExporter
	{
	public:

		struct SceneData
		{
			std::string tilesetLabel;
			std::string stampsetLabel;
			std::string mapFgLabel;
			std::string mapBgLabel;
			std::string collisionTilesetLabel;
			std::string collisionStampsetLabel;
			std::string collisionMapLabel;
			std::string palettesLabel;
			std::vector<Entity> staticEntities;
			std::vector<Entity> dynamicEntities;

			int numTiles;
			int numStamps;
			int mapFgWidthStamps;
			int mapFgHeightStamps;
			int mapBgWidthStamps;
			int mapBgHeightStamps;
			int numCollisionTiles;
			int numCollisionStamps;
			int collisionMapWidthStamps;
			int collisionMapHeightStamps;

			int numPalettes;
		};

		SceneExporter();

		bool ExportScene(const std::string& filename, const std::string& sceneName, const SceneData& sceneData);
	};
}