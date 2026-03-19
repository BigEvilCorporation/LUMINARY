// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 13th August 2019
// ============================================================================================
// PaletteExporter.cpp - Palette exporter
// ============================================================================================

#include "PaletteExporter.h"
#include "Serialiser.h"

namespace luminary
{
	bool PaletteExporter::ExportPalettes(const std::string& filename, const std::vector<Palette>& palettes)
	{
		SerialiserAsm serialiser(filename);
		if (!serialiser.IsOpen())
			return false;

		for (int i = 0; i < palettes.size(); i++)
		{
			serialiser.Label("palette_", palettes[i].GetName());

			for (int j = 0; j < Palette::coloursPerPalette; j++)
			{
				u16 value = palettes[i].IsColourUsed(j) ? palettes[i].GetColour(j).ToVDPFormat() : 0;
				serialiser.Value(value);
			}

			serialiser.Break();
		}

		return true;
	}
}