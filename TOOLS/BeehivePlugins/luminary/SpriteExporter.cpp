// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 8th August 2019
// ============================================================================================
// SpriteExporter.cpp - Sprite sheet and animation exporter
// ============================================================================================

#include "SpriteExporter.h"

#include <vector>

namespace luminary
{
	const std::vector<std::string> s_layoutNames =
	{
		"VDP_SPRITE_LAYOUT_1x1", // 0000 (1x1)
		"VDP_SPRITE_LAYOUT_1x2", // 0001 (1x2)
		"VDP_SPRITE_LAYOUT_1x3", // 0010 (1x3)
		"VDP_SPRITE_LAYOUT_1x4", // 0011 (1x4)
		"VDP_SPRITE_LAYOUT_2x1", // 0100 (2x1)
		"VDP_SPRITE_LAYOUT_2x2", // 0101 (2x2)
		"VDP_SPRITE_LAYOUT_2x3", // 0110 (2x3)
		"VDP_SPRITE_LAYOUT_2x4", // 0111 (2x4)
		"VDP_SPRITE_LAYOUT_3x1", // 1000 (3x1)
		"VDP_SPRITE_LAYOUT_3x2", // 1001 (3x2)
		"VDP_SPRITE_LAYOUT_3x3", // 1010 (3x3)
		"VDP_SPRITE_LAYOUT_3x4", // 1011 (3x4)
		"VDP_SPRITE_LAYOUT_4x1", // 1100 (4x1)
		"VDP_SPRITE_LAYOUT_4x2", // 1101 (4x2)
		"VDP_SPRITE_LAYOUT_4x3", // 1110 (4x3)
		"VDP_SPRITE_LAYOUT_4x4", // 1111 (4x4)
	};

	SpriteExporter::SpriteLayout SpriteExporter::GetSpriteLayout(int width, int height)
	{
		if (width >= 0 && width < 4 && height >= 0 && height < 4)
		{
			return (SpriteLayout)(((width - 1) * 4) + (height - 1));
		}
		
		return (SpriteLayout)-1;
	}

	const std::string& SpriteExporter::GetSpriteLayoutName(SpriteLayout layout)
	{
		return s_layoutNames[(int)layout];
	}
}