// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 11th August 2019
// ============================================================================================
// TilesetExporter.cpp - Map tileset and stamp exporter
// ============================================================================================

#include "TilesetExporter.h"

#include <ion/core/memory/Endian.h>

namespace luminary
{
	bool TilesetExporter::ExportTileset(const std::string& binFilename, const Tileset& tileset)
	{
		ion::io::File file(binFilename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			for (int i = 0; i < tileset.GetCount(); i++)
			{
				if (const Tile* tile = tileset.GetTile(i))
				{
					for (int y = 0; y < tile->GetHeight(); y++)
					{
						for (int x = 0; x < tile->GetWidth(); x += 2)
						{
							u8 nybble1 = (u8)tile->GetPixelColour(x, y) << 4;
							u8 nybble2 = ((x + 1) < tile->GetWidth()) ? (u8)tile->GetPixelColour(x + 1, y) : 0;

							u8 byte = nybble1 | nybble2;
							file.Write(&byte, sizeof(u8));
						}
					}
				}
			}

			file.Close();
			return true;
		}

		return false;
	}

	bool TilesetExporter::ExportStamps(const std::string& binFilename, const std::vector<Stamp>& stamps, const Tileset& tileset, u32 backgroundTileId)
	{
		ion::io::File file(binFilename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			for (int i = 0; i < stamps.size(); i++)
			{
				const Stamp& stamp = stamps[i];

				for (int y = 0; y < stamp.GetWidth(); y++)
				{
					for (int x = 0; x < stamp.GetHeight(); x++)
					{
						//16 bit word:
						//-------------------
						//ABBC DEEE EEEE EEEE
						//-------------------
						//A = Low/high plane
						//B = Palette ID
						//C = Horizontal flip
						//D = Vertical flip
						//E = Tile ID

						u8 paletteId = 0;

						//If blank tile, use background tile
						u32 tileId = stamp.GetTile(x, y);
						u16 tileFlags = stamp.GetTileFlags(x, y);

						if (tileId == InvalidTileId)
						{
							tileId = backgroundTileId;
						}

						const Tile* tile = tileset.GetTile(tileId);
						ion::debug::Assert(tile, "TilesetExporter::ExportStamps() - Invalid tile");

						//Generate components
						u16 tileIndex = tileId & 0x7FF;								//Bottom 11 bits = tile ID (index from 0)
						u16 flipH = (tileFlags & Map::eFlipX) ? 1 << 11 : 0;		//12th bit = Flip X flag
						u16 flipV = (tileFlags & Map::eFlipY) ? 1 << 12 : 0;		//13th bit = Flip Y flag
						u16 palette = (tile->GetPaletteId() & 0x3) << 13;			//14th+15th bits = Palette ID
						u16 plane = (tileFlags & Map::eHighPlane) ? 1 << 15 : 0;	//16th bit = High plane flag

						//Generate word
						u16 word = tileIndex | flipV | flipH | palette | plane;

						//Endian flip
						ion::memory::EndianSwap(word);

						//Write
						file.Write(&word, sizeof(u16));
					}
				}
			}

			file.Close();
			return true;
		}

		return false;
	}
}