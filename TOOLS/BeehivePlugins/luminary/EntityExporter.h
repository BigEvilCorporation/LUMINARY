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
		EntityExporter();

		bool ExportArchetypes(const std::string& filename, const std::vector<Archetype>& archetypes);
	};
}