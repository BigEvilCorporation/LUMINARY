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

		static std::string ExportSpawnParamsData(const std::string& name, const std::vector<Param>& entityParams, const std::vector<Component>& components);
		static std::string ExportStaticEntityData(const Entity& entity);
		static std::string ExportEntitySpawnTableData(const std::string& label, const Entity& entity, std::map<std::string, ExportedSpawnData>& exportedSpawnDatas);
		static std::string ExportDebugNameData(const std::string& name, int maxLength);
	};
}