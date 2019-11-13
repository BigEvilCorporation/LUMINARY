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
		static const int s_terrainLayers = 2;

		bool ExportTerrainTileset(const std::string& binFilename, const TerrainTileset& tileset, int tileWidth);
		bool ExportTerrainStamps(const std::string& binFilename, const std::vector<Stamp>& stamps, const TerrainTileset& tileset, u32 defaultTileId);
		bool ExportTerrainMap(const std::string& binFilename, const Map& map, int stampWidth, int stampHeight);

		int GetNumUniqueTerrainStamps() const { return m_uniqueStamps.size(); }

	private:
		struct TerrainStamp
		{
			bool operator == (const TerrainStamp& rhs) const
			{
				for (int i = 0; i < s_terrainLayers; i++)
				{
					if (layers[i] != rhs.layers[i])
						return false;
				}

				return true;
			}

			struct TerrainTile
			{
				bool operator == (const TerrainTile& rhs) const
				{
					return tileId == rhs.tileId && flags == rhs.flags;
				}

				TerrainTileId tileId;
				u16 flags;
			};

			std::vector<TerrainTile> layers[s_terrainLayers];
		};

		std::vector<TerrainStamp> m_uniqueStamps;
		std::map<StampId, StampId> m_remap;
	};
}