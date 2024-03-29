// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 8th August 2019
// ============================================================================================
// Tags.h - Supported param tags
// ============================================================================================

#pragma once

#include <string>

namespace luminary
{
	namespace tags
	{
		enum class TagType
		{
			PositionX,
			PositionY,
			SpriteActor,
			SpriteSheet,
			SpriteAnimation,
			EntityDesc,
			EntityArchetype,
			ScriptData,
			PrefabData,
		};

		struct ParamTag
		{
			std::string name;
			TagType tagType;
		};

		const std::string& GetTagName(TagType tagType);
		TagType FindTagType(const std::string& name);
		const ParamTag* FindTag(const std::string& name);
	}
}
