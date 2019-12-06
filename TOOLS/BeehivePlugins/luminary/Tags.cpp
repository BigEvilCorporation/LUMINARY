// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 8th August 2019
// ============================================================================================
// Tags.cpp - Supported param tags
// ============================================================================================

#include "Tags.h"
#include <vector>
#include <ion/core/string/String.h>

namespace luminary
{
	namespace tags
	{
		static const std::vector<ParamTag> s_tags =
		{
			{ "POSITION_X", TagType::PositionX },
			{ "POSITION_Y", TagType::PositionY },
			{ "SPRITE_SHEET" , TagType::SpriteSheet },
			{ "SPRITE_ANIM", TagType::SpriteAnimation },
			{ "ENTITY_DESC", TagType::EntityDesc },
			{ "ENTITY_ARCHETYPE", TagType::EntityArchetype },
		};

		const std::string& GetTagName(TagType tagType)
		{
			return s_tags[(int)tagType].name;
		}

		TagType FindTagType(const std::string& name)
		{
			for (int i = 0; i < s_tags.size(); i++)
			{
				if (ion::string::CompareNoCase(s_tags[i].name, name))
				{
					return s_tags[i].tagType;
				}
			}

			return (TagType)-1;
		}

		const ParamTag* FindTag(const std::string& name)
		{
			for (int i = 0; i < s_tags.size(); i++)
			{
				if (ion::string::CompareNoCase(s_tags[i].name, name))
				{
					return &s_tags[i];
				}
			}

			return nullptr;
		}
	}
}
