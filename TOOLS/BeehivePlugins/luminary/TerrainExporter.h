// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 22nd August 2019
// ============================================================================================
// TerrainExporter.h - Terrain and collision tile/block exporter
// ============================================================================================

#pragma once

#include <ion/beehive/TerrainTile.h>
#include <ion/beehive/TerrainTileset.h>
#include <ion/beehive/Stamp.h>
#include <ion/beehive/Map.h>

namespace luminary
{
	class TerrainExporter
	{
	public:
		bool ExportTerrainTileset(const std::string& binFilename, const TerrainTileset& tileset, int tileWidth);
		bool ExportTerrainStamps(const std::string& binFilename, const std::vector<Stamp>& stamps, const TerrainTileset& tileset, u32 defaultTileId);
		bool ExportTerrainMap(const std::string& binFilename, const Map& map, int stampWidth, int stampHeight);

	private:
		typedef std::vector<std::pair<TerrainTileId, u16>> TerrainStamp;
		std::vector<TerrainStamp> m_uniqueStamps;
		std::map<StampId, StampId> m_remap;
	};
}