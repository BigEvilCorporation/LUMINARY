// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 11th August 2019
// ============================================================================================
// TilesetExporter.h - Map tileset and stamp exporter
// ============================================================================================

#pragma once

#include <string>
#include <vector>

#include <ion/beehive/Tileset.h>
#include <ion/beehive/Stamp.h>
#include <ion/beehive/Map.h>

namespace luminary
{
	class TilesetExporter
	{
	public:
		bool ExportTileset(const std::string& binFilename, const Tileset& tileset);
		bool ExportStamps(const std::string& binFilename, const std::vector<Stamp>& stamps, const Tileset& tileset, u32 backgroundTileId);
	};
}