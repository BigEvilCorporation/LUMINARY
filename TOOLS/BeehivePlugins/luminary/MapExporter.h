// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 13th August 2019
// ============================================================================================
// MapExporter.h - Map exporter
// ============================================================================================

#pragma once

#include <ion/beehive/Map.h>

namespace luminary
{
	class MapExporter
	{
	public:
		bool ExportMap(const std::string& binFilename, const Map& map, int stampWidth, int stampHeight);
	};
}