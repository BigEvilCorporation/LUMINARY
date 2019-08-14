// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 13th August 2019
// ============================================================================================
// PaletteExporter.h - Palette exporter
// ============================================================================================

#pragma once

#include <string>
#include <vector>

#include <ion/beehive/Palette.h>

namespace luminary
{
	class PaletteExporter
	{
	public:
		bool ExportPalettes(const std::string& filename, const std::vector<Palette>& palettes);
	};
}