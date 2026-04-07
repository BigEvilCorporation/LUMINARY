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
			std::string tilesetFgLabel;
			std::string tilesetBgLabel;
			std::string stampsetFgLabel;
			std::string stampsetBgLabel;
			std::string mapFgLabel;
			std::string mapBgLabel;
			std::string collisionTilesetLabel;
			std::string collisionStampsetLabel;
			std::string collisionMapLabel;
			std::vector<std::string> palettes;
			std::vector<Entity> staticEntities;
			std::vector<Entity> dynamicEntities;
			std::vector<StampAnim> stampAnimations;

			u16 numTilesFg;
			u16 numTilesBg;
			u16 numStampsFg;
			u16 numStampsBg;
			u16 mapFgWidthStamps;
			u16 mapFgHeightStamps;
			u16 mapBgWidthStamps;
			u16 mapBgHeightStamps;
			u16 numCollisionTiles;
			u16 numCollisionStamps;
			u16 collisionMapWidthStamps;
			u16 collisionMapHeightStamps;
			u16 numPalettes;
		};

		SceneExporter();

		bool ExportScene(const std::string& filename, const std::string& sceneName, const SceneData& sceneData);
	};
}