// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th August 2019
// ============================================================================================
// Types.h - Data types for working with Luminary scenes, entities, components
// ============================================================================================

#pragma once

#include <ion/core/Types.h>

namespace luminary
{
	enum class ParamSize
	{
		Byte,
		Word,
		Long
	};

	struct Param
	{
		bool operator == (const Param& rhs) const
		{
			return name == rhs.name && size == rhs.size && value == rhs.value;
		}

		std::string name;
		ParamSize size;
		std::string value;
		std::vector<std::string> tags;
	};

	struct SpawnData
	{
		u32 positionX;
		u32 positionY;
		u32 width;
		u32 height;
		std::string name;
		std::vector<Param> params;
	};

	struct Component
	{
		std::string name;
		SpawnData spawnData;
		std::vector<Param> params;
	};

	struct Entity
	{
		std::string name;
		SpawnData spawnData;
		std::vector<Param> params;
		std::vector<Component> components;
		bool isStatic;
	};

	struct Archetype
	{
		std::string name;
		std::string entityTypeName;
		std::vector<Param> params;
		std::vector<Component> components;
	};
}