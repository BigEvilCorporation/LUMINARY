// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 13th August 2019
// ============================================================================================
// MapExporter.cpp - Map exporter
// ============================================================================================

#include "MapExporter.h"

namespace luminary
{
	bool MapExporter::ExportMap(const std::string& binFilename, const Map& map, int stampWidth, int stampHeight)
	{
		ion::io::File file(binFilename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			int widthStamps = map.GetWidth() / stampWidth;
			int heightStamps = map.GetHeight() / stampHeight;

			std::vector<u8> stampMap;
			stampMap.resize(widthStamps * heightStamps);

			for (TStampPosMap::const_iterator it = map.StampsBegin(), end = map.StampsEnd(); it != end; ++it)
			{
				int x = it->m_position.x / stampWidth;
				int y = it->m_position.y / stampHeight;
				stampMap[(y * widthStamps) + x] = it->m_id;
			}

			file.Write(stampMap.data(), stampMap.size());
			file.Close();
			return true;
		}

		return false;
	}
}