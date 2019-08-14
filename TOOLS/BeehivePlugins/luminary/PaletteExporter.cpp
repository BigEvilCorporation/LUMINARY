// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 13th August 2019
// ============================================================================================
// PaletteExporter.cpp - Palette exporter
// ============================================================================================

#include "PaletteExporter.h"

namespace luminary
{
	bool PaletteExporter::ExportPalettes(const std::string& filename, const std::vector<Palette>& palettes)
	{
		ion::io::File file(filename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			std::stringstream stream;
			stream << std::hex << std::setfill('0') << std::uppercase;

			for (int i = 0; i < palettes.size(); i++)
			{
				for (int j = 0; j < Palette::coloursPerPalette; j++)
				{
					u32 value = palettes[i].IsColourUsed(j) ? palettes[i].GetColour(j).ToVDPFormat() : 0;
					stream << "\tdc.w\t0x" << std::setw(4) << value << std::endl;
				}

				stream << std::endl;
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
			return true;
		}

		return false;
	}
}