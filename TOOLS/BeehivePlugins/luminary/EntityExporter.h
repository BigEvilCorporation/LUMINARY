// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 6th December 2019
// ============================================================================================
// EntityExporter.h - Exports entities and archetypes
// ============================================================================================

#pragma once

#include <string>
#include <vector>

#include "Types.h"
#include "Serialiser.h"

namespace luminary
{
	class EntityExporter
	{
	public:
		static const int s_debugNameLen = 16;

		struct ExportedSpawnData
		{
			std::string labelName;
			std::vector<const SpawnData*> data;
		};

		EntityExporter();

		bool ExportArchetypes(const std::string& filename, const std::vector<Archetype>& archetypes);
		bool ExportPrefabs(const std::string& filename, const std::vector<Prefab>& prefabs);
		bool ExportAnimations(const std::string& filename, const std::vector<Animation>& animations);

		static void ExportSpawnParamsData(SerialiserAsm& serialiser, const std::string& name, unsigned short id, const std::vector<Param>& entityParams, const std::vector<std::pair<Component, std::string>>& components);
		static void ExportStaticEntityData(SerialiserAsm& serialiser, const Entity& entity);
		static void ExportEntitySpawnTableData(SerialiserAsm& serialiser, const std::string& spawnDataName, const Entity& entity, std::map<std::string, ExportedSpawnData>& exportedSpawnDatas);
		static void ExportDebugNameData(SerialiserAsm& serialiser, const std::string& name, int maxLength);
	};
}