// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 13th August 2019
// ============================================================================================
// MapExporter.cpp - Map exporter
// ============================================================================================

#include "MapExporter.h"

#include <ion/core/memory/Endian.h>

namespace luminary
{
	bool MapExporter::ExportMap(const std::string& binFilename, const Map& map, int stampWidth, int stampHeight)
	{
		ion::io::File file(binFilename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			int widthStamps = map.GetWidth() / stampWidth;
			int heightStamps = map.GetHeight() / stampHeight;
			u32 stampSizeBytes = stampWidth * stampHeight * 2;

			std::vector<u32> stampMap;
			stampMap.resize(widthStamps * heightStamps);

			for (TStampPosMap::const_iterator it = map.StampsBegin(), end = map.StampsEnd(); it != end; ++it)
			{
				int x = it->m_position.x / stampWidth;
				int y = it->m_position.y / stampHeight;
				u32 word = (it->m_id * stampSizeBytes);
				ion::memory::EndianSwap(word);
				stampMap[(y * widthStamps) + x] = word;
			}

			file.Write(stampMap.data(), stampMap.size() * sizeof(u32));
			file.Close();
			return true;
		}

		return false;
	}
}