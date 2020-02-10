// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 9th February 2020
// ============================================================================================
// BeehiveToLuminary.h - Utilities for converting between Luminary and Beehive types
// ============================================================================================

#pragma once

#include <string>
#include <vector>

#include "Types.h"

#include <beehive/Project.h>
#include <beehive/Actor.h>
#include <beehive/GameObject.h>
#include <beehive/SpriteSheet.h>
#include <beehive/SpriteAnimation.h>

namespace luminary
{
	namespace beehive
	{
		const SpriteSheet* FindSpriteSheet(const Actor& actor, const GameObjectType& gameObjectType, const GameObject* gameObject, const GameObjectVariable* variable);
		const SpriteAnimation* FindSpriteAnim(const Actor& actor, const GameObjectType& gameObjectType, const GameObject* gameObject, const GameObjectArchetype* archetype, const GameObjectVariable& variable, std::string& sheetName);
		void ExportParam(luminary::Param& param, const GameObjectVariable& variable, const GameObjectType& gameObjectType, const GameObjectArchetype* archetype, const GameObject* gameObject, const Actor* actor);
		void ExportArchetype(const Project& project, const GameObjectArchetype& srcArchetype, luminary::Archetype& archetype);
		void ConvertScriptEntity(const GameObjectType& gameObjectType, luminary::Entity& entity);
		void ExportEntity(const Project& project, const GameObjectType& gameObjectType, const GameObject& gameObject, luminary::Entity& entity);
	}
}