// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 22nd August 2019
// ============================================================================================
// TerrainExporter.cpp - Terrain and collision tile/block exporter
// ============================================================================================

#include "TerrainExporter.h"

#include <ion/core/memory/Endian.h>

namespace luminary
{
	bool TerrainExporter::ExportTerrainTileset(const std::string& binFilename, const TerrainTileset& tileset, int tileWidth)
	{
		ion::io::File file(binFilename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			for (int i = 0; i < tileset.GetCount(); i++)
			{
				if (const TerrainTile* tile = tileset.GetTerrainTile(i))
				{
					std::vector<s8> heights;
					std::vector<s8> widths;
					tile->GetHeights(heights);
					tile->GetWidths(widths);
					file.Write(heights.data(), heights.size());
					file.Write(widths.data(), widths.size());
				}
			}

			file.Close();
			return true;
		}

		return false;
	}

	bool TerrainExporter::ExportTerrainStamps(const std::string& binFilename, const std::vector<Stamp>& stamps, const TerrainTileset& tileset, u32 defaultTileId)
	{
		ion::io::File file(binFilename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			if (stamps.size() > 0)
			{
				int stampWidth = stamps[0].GetWidth();
				int stampHeight = stamps[0].GetHeight();
				int stampSize = stampWidth * stampHeight;

				//Find unique, add to m_uniqueStamps, remap to m_remap
				TerrainStamp currStamp;
				currStamp.resize(stampSize);

				for (int i = 0; i < stamps.size(); i++)
				{
					for (int y = 0; y < stampHeight; y++)
					{
						for (int x = 0; x < stampWidth; x++)
						{
							u16 tileId = stamps[i].GetTerrainTile(x, y);
							u16 flags = stamps[i].GetCollisionTileFlags(x, y);
							u8 angleByte = 0;
							u8 quadrant = 0;
							float degrees = 0.0f;

							if (const TerrainTile* tile = tileset.GetTerrainTile(tileId))
							{
								degrees = tile->GetAngleDegrees();
								angleByte = tile->GetAngleByte();
								quadrant = ion::maths::Round(degrees / 90.0f) % 4;
							}
							
							//Flags start at bit 12
							flags |= (quadrant << 8);
							flags |= angleByte;

							currStamp[(y * stampWidth) + x].first = tileId;
							currStamp[(y * stampWidth) + x].second = flags;
						}
					}

					std::vector<TerrainStamp>::const_iterator it = std::find(m_uniqueStamps.begin(), m_uniqueStamps.end(), currStamp);
					if (it == m_uniqueStamps.end())
					{
						//Unique
						m_uniqueStamps.push_back(currStamp);
						m_remap.insert(std::make_pair(i, m_uniqueStamps.size() - 1));
					}
					else
					{
						//Duplicate
						m_remap.insert(std::make_pair(i, it - m_uniqueStamps.begin()));
					}
				}

				//Export all unique stamps
				for (int i = 0; i < m_uniqueStamps.size(); i++)
				{
					for (int j = 0; j < m_uniqueStamps[i].size(); j++)
					{
						u16 tileId = m_uniqueStamps[i][j].first;
						u16 flags = m_uniqueStamps[i][j].second;

						if (tileId == InvalidTerrainTileId)
							tileId = defaultTileId;

						u32 longword = (flags << 16) | tileId;

						ion::memory::EndianSwap(longword);

						file.Write(&longword, sizeof(u32));
					}
				}

				return true;
			}
		}

		return false;
	}

	bool TerrainExporter::ExportTerrainMap(const std::string& binFilename, const Map& map, int stampWidth, int stampHeight)
	{
		//Use ids from m_remap, export addr offsets (width*height*u16*2)

		ion::io::File file(binFilename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			int widthStamps = map.GetWidth() / stampWidth;
			int heightStamps = map.GetHeight() / stampHeight;
			u32 stampSizeBytes = stampWidth * stampHeight * sizeof(u16) * 2;

			std::vector<u32> stampMap;
			stampMap.resize(widthStamps * heightStamps);

			for (TStampPosMap::const_iterator it = map.StampsBegin(), end = map.StampsEnd(); it != end; ++it)
			{
				int x = it->m_position.x / stampWidth;
				int y = it->m_position.y / stampHeight;
				u16 tileId = m_remap[it->m_id];
				u32 addr = (tileId * stampSizeBytes);
				ion::memory::EndianSwap(addr);
				stampMap[(y * widthStamps) + x] = addr;
			}

			file.Write(stampMap.data(), stampMap.size() * sizeof(u32));
			file.Close();
			return true;
		}

		return false;
	}
}