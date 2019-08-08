// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 8th August 2019
// ============================================================================================
// SpriteExporter.h - Sprite sheet and animation exporter
// ============================================================================================

#pragma once

#include <string>

namespace luminary
{
	class SpriteExporter
	{
	public:
		enum class SpriteLayout
		{
			Layout_1x1, // 0000 (1x1)
			Layout_1x2, // 0001 (1x2)
			Layout_1x3, // 0010 (1x3)
			Layout_1x4, // 0011 (1x4)
			Layout_2x1, // 0100 (2x1)
			Layout_2x2, // 0101 (2x2)
			Layout_2x3, // 0110 (2x3)
			Layout_2x4, // 0111 (2x4)
			Layout_3x1, // 1000 (3x1)
			Layout_3x2, // 1001 (3x2)
			Layout_3x3, // 1010 (3x3)
			Layout_3x4, // 1011 (3x4)
			Layout_4x1, // 1100 (4x1)
			Layout_4x2, // 1101 (4x2)
			Layout_4x3, // 1110 (4x3)
			Layout_4x4, // 1111 (4x4)
		};

		static SpriteLayout GetSpriteLayout(int width, int height);
		static const std::string& GetSpriteLayoutName(SpriteLayout layout);
	};
}