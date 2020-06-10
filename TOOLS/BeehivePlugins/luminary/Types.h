// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th August 2019
// ============================================================================================
// Types.h - Data types for working with Luminary scenes, entities, components
// ============================================================================================

#pragma once

#include <ion/core/Types.h>

#include <string>
#include <vector>
#include <map>

namespace luminary
{
	enum class ParamSize
	{
		Byte = 1,
		Word = 2,
		Long = 4
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

	struct ScriptFunc
	{
		u32 tableOffset;
		std::string routine;
		std::string scope;
		std::string name;
		std::string returnType;
		std::vector<std::pair<std::string, std::string>> params;
	};

	struct ScriptRelocation
	{
		u32 address;
		u16 tableIdx;
		std::string scope;
		std::string name;
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
		std::vector<ScriptFunc> scriptFuncs;
	};

	struct Entity
	{
		std::string typeName;
		unsigned short id;
		SpawnData spawnData;
		std::vector<Param> params;
		std::vector<Component> components;
		std::vector<ScriptFunc> scriptFuncs;
		bool isStatic;
		bool isPrefab;
	};

	struct Prefab
	{
		std::string name;
		unsigned short id;
		std::vector<Entity> children;
	};

	struct Archetype
	{
		std::string name;
		std::string entityTypeName;
		std::vector<Param> params;
		std::vector<Component> components;
	};

	struct ScriptAddress
	{
		std::string name;
		int address;
	};

	typedef std::map<std::string, std::vector<luminary::ScriptAddress>> ScriptAddressMap;
}