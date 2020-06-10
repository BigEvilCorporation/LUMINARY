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
		const SpriteSheet* FindSpriteSheet(const Actor& actor, const GameObjectType& gameObjectType, const GameObject* gameObject, const GameObjectType::PrefabChild* prefabChild, const GameObjectVariable* variable);
		const SpriteAnimation* FindSpriteAnim(const Actor& actor, const GameObjectType& gameObjectType, const GameObject* gameObject, const GameObjectType::PrefabChild* prefabChild, const GameObjectArchetype* archetype, const GameObjectVariable& variable, std::string& sheetName);

		void CreatePrefabType(GameObjectType& gameObjectType);

		void ConvertParam(luminary::Param& param, const GameObjectVariable& variable, const GameObjectType& gameObjectType, const GameObjectArchetype* archetype, const GameObject* gameObject, const GameObjectType::PrefabChild* prefabChild, const Actor* actor, const luminary::ScriptAddressMap& scriptAddresses);
		void ConvertArchetype(const Project& project, const GameObjectArchetype& srcArchetype, const luminary::ScriptAddressMap& scriptAddresses, luminary::Archetype& archetype);
		void ConvertPrefabType(const Project& project, const GameObjectType& gameObjectType, luminary::Prefab& prefab);
		void ConvertPrefabChild(const Project& project, const GameObjectType& gameObjectType, const GameObjectType::PrefabChild& prefabChild, luminary::Entity& entity);
		void ConvertEntityType(const Project& project, const GameObjectType& gameObjectType, luminary::Entity& entity);
		void ConvertEntityInstance(const Project& project, const GameObjectType& gameObjectType, const GameObject& gameObject, const luminary::ScriptAddressMap& scriptAddresses, luminary::Entity& entity);
	}
}