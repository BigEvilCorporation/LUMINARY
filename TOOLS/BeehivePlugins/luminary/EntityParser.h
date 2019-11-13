// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 6th August 2019
// ============================================================================================
// EntityParser.h - Utilities for parsing the Luminary engine and game files to build lists
// of entities and components for tools exporting.
// ============================================================================================

#pragma once

#include <string>
#include <vector>

#include "Types.h"

namespace luminary
{
	class EntityParser
	{
	public:
		EntityParser();

		bool ParseDirectory(const std::string& directory, std::vector<Entity>& entities);

	private:
		struct TextBlock
		{
			std::string name;
			std::vector<std::vector<std::string>> block;
		};

		std::vector<TextBlock> m_entityTextBlocks;
		std::vector<TextBlock> m_staticEntityTextBlocks;
		std::vector<TextBlock> m_entitySpawnTextBlocks;
		std::vector<SpawnData> m_entitySpawnData;

		std::vector<TextBlock> m_componentTextBlocks;
		std::vector<TextBlock> m_componentSpawnTextBlocks;
		std::vector<SpawnData> m_componentSpawnData;

		std::vector<Component> m_components;

		void FindTextBlocks(const std::string& filename);
		std::string GetNameToken(const std::vector<std::string>& tokens);
		bool ParseEntity(const TextBlock& textBlock, Entity& entity);
		void ParseStaticEntity(const TextBlock& textBlock, Entity& entity);
		bool ParseComponent(const TextBlock& textBlock, Component& component);
		void ParseSpawnData(const TextBlock& textBlock, SpawnData& spawnData);
		bool ParseParam(const std::vector<std::string>& line, Param& param);
		void ParseTags(const std::string& tagLine, Param& param);
		Component* ParseComponentDef(const std::vector<std::string>& line, size_t pos);
		SpawnData* FindComponentSpawnData(const std::string& componentName);
		SpawnData* FindEntitySpawnData(const std::string& entityName);
	};
}