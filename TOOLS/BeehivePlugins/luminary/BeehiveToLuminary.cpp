// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 9th February 2020
// ============================================================================================
// BeehiveToLuminary.h - Utilities for converting between Luminary and Beehive types
// ============================================================================================

#include "BeehiveToLuminary.h"
#include "Tags.h"

#include <ion/core/utils/STL.h>

namespace luminary
{
	namespace beehive
	{
		const Actor* FindActorInComponent(const TActorMap& actors, const GameObjectType& gameObjectType, const GameObject* gameObject, const GameObjectType::PrefabChild* prefabChild, const GameObjectArchetype* archetype, int componentIdx)
		{
			const GameObjectVariable* actorVar = gameObject ? gameObject->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteActor), componentIdx) : nullptr;

			// From game object
			if (!actorVar)
				actorVar = gameObject ? gameObject->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteActor), componentIdx) : nullptr;

			// From prefab
			if (!actorVar)
				actorVar = prefabChild ? prefabChild->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteActor), componentIdx) : nullptr;

			// From archetype
			if (!actorVar)
				actorVar = archetype ? archetype->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteActor), componentIdx) : nullptr;

			// From game object type
			if (!actorVar)
				actorVar = gameObjectType.FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteActor), componentIdx);

			const Actor* actor = nullptr;

			if (actorVar)
			{
				for (TActorMap::const_iterator it = actors.begin(), end = actors.end(); it != end && !actor; ++it)
				{
					if (ion::string::CompareNoCase(it->second.GetName(), actorVar->m_value))
					{
						actor = &it->second;
					}
				}
			}

			return actor;
		}

		const SpriteSheet* FindSpriteSheetInComponent(const TActorMap& actors, const GameObjectType& gameObjectType, const GameObject* gameObject, const GameObjectType::PrefabChild* prefabChild, const GameObjectArchetype* archetype, int componentIdx, std::string& actorName)
		{
			//Get actor
			const Actor* actor = FindActorInComponent(actors, gameObjectType, gameObject, prefabChild, archetype, componentIdx);
			if (!actor)
				return nullptr;

			actorName = actor->GetName();

			const SpriteSheet* spriteSheet = nullptr;

			//From game object
			const GameObjectVariable* spriteSheetVar = gameObject ? gameObject->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteSheet), componentIdx) : nullptr;

			//From prefab
			if (!spriteSheetVar)
				spriteSheetVar = prefabChild ? prefabChild->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteSheet), componentIdx) : nullptr;

			//From archetype
			if (!spriteSheetVar)
				spriteSheetVar = archetype ? archetype->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteSheet), componentIdx) : nullptr;

			//From game object type
			if (!spriteSheetVar)
				spriteSheetVar = gameObjectType.FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteSheet), componentIdx);

			if (spriteSheetVar)
				spriteSheet = actor->FindSpriteSheet(spriteSheetVar->m_value);

			return spriteSheet;
		}

		const Actor* FindSpriteActor(const TActorMap& actors, const std::string& name)
		{
			const Actor* actor = nullptr;

			for (TActorMap::const_iterator it = actors.begin(), end = actors.end(); it != end && !actor; ++it)
			{
				if (ion::string::CompareNoCase(it->second.GetName(), name))
				{
					actor = &it->second;
				}
			}

			return actor;
		}

		const SpriteSheet* FindSpriteSheet(const TActorMap& actors, const GameObjectType& gameObjectType, const GameObject* gameObject, const GameObjectType::PrefabChild* prefabChild, const GameObjectArchetype* archetype, const std::string& name, int componentIdx, std::string& actorName)
		{
			//Get actor
			const Actor* actor = FindActorInComponent(actors, gameObjectType, gameObject, prefabChild, archetype, componentIdx);
			if (!actor)
				return nullptr;

			actorName = actor->GetName();

			//Sprite sheet from variable
			return actor->FindSpriteSheet(name);
		}

		const SpriteAnimation* FindSpriteAnim(const TActorMap& actors, const GameObjectType& gameObjectType, const GameObject* gameObject, const GameObjectType::PrefabChild* prefabChild, const GameObjectArchetype* archetype, const std::string& name, int componentIdx, std::string& actorName, std::string& sheetName)
		{
			//Get sprite sheet
			const SpriteSheet* spriteSheet = FindSpriteSheetInComponent(actors, gameObjectType, gameObject, prefabChild, archetype, componentIdx, actorName);
			if (!spriteSheet)
				return nullptr;

			sheetName = spriteSheet->GetName();

			//Sprite anim from variable
			return spriteSheet->FindAnimation(name);
		}

		void CreatePrefabType(GameObjectType& gameObjectType)
		{
			//EPrefab entity type
			gameObjectType.SetName("EPrefab");

			//Add prefab data variable
			GameObjectVariable& variable = gameObjectType.AddVariable();
			variable.m_name = "SDPrefab_Data";
			variable.m_size = (u8)luminary::ParamSize::Long;
			variable.m_value = std::string("prefabdata_") + gameObjectType.GetPrefabName();
			variable.m_tags.push_back(luminary::tags::GetTagName(luminary::tags::TagType::PrefabData));
		}

		void ConvertParam(luminary::Param& param, const GameObjectVariable& variable, const GameObjectType& gameObjectType, const GameObjectArchetype* archetype, const GameObject* gameObject, const GameObjectType::PrefabChild* prefabChild, const TActorMap& actors, const luminary::ScriptAddressMap& scriptAddresses)
		{
			param.name = variable.m_name;
			param.value = "0";

			std::string scriptAddress;

			//Search for supported tags
			if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::EntityDesc)))
			{
				std::stringstream stream;
				stream << variable.m_value << "_TypeDesc";
				param.value = stream.str();
			}
			else if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::EntityArchetype)))
			{
				if (variable.m_value == "0")
				{
					param.value = "0";
				}
				else
				{
					//Find entity type first
					std::string entityTypeName;
					const GameObjectVariable* typeVariable = nullptr;

					if (archetype)
					{
						//Find variable in archetype
						typeVariable = archetype->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::EntityDesc), variable.m_componentIdx);
					}
					if (gameObject && !typeVariable)
					{
						//Find variable on instance
						typeVariable = gameObject->FindVariableByTag(luminary::tags::GetTagName(luminary::tags::TagType::EntityDesc), variable.m_componentIdx);
					}

					if (typeVariable)
						entityTypeName = typeVariable->m_value;
					else
						entityTypeName = gameObjectType.GetName();

					std::stringstream stream;
					stream << "Archetype_" << entityTypeName << "_" << variable.m_value;
					param.value = stream.str();
				}
			}
			else if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::PositionX)))
			{
				if (gameObject)
					param.value = std::to_string(gameObject->GetPosition().x + GameObject::spriteSheetBorderX);
			}
			else if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::PositionY)))
			{
				if (gameObject)
					param.value = std::to_string(gameObject->GetPosition().y + GameObject::spriteSheetBorderY);
			}
			else if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteActor)))
			{
				//Unused
				param.value = "0";
			}
			else if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteSheet)))
			{
				std::string actorName;
				if (const SpriteSheet* spriteSheet = FindSpriteSheet(actors, gameObjectType, gameObject, prefabChild, archetype, variable.m_value, variable.m_componentIdx, actorName))
				{
					std::stringstream stream;
					stream << "actor_" << actorName << "_spritesheet_" << spriteSheet->GetName();
					param.value = stream.str();
				}
			}
			else if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::SpriteAnimation)))
			{
				std::string actorName;
				std::string sheetName;
				if (const SpriteAnimation* spriteAnim = FindSpriteAnim(actors, gameObjectType, gameObject, prefabChild, archetype, variable.m_value, variable.m_componentIdx, actorName, sheetName))
				{
					std::stringstream stream;
					stream << "actor_" << actorName << "_sheet_" << sheetName << "_anim_" << spriteAnim->GetName();

					param.value = stream.str();
				}
			}
			else if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::ScriptData)))
			{
				param.value = std::string("scriptdata_") + gameObjectType.GetName();
			}
			else if (variable.HasTag(luminary::tags::GetTagName(luminary::tags::TagType::PrefabData)))
			{
				param.value = std::string("prefabdata_") + gameObjectType.GetPrefabName();
			}
			else if (variable.FindTagValue("SCRIPTFUNC", scriptAddress))
			{
				ScriptAddressMap::const_iterator it = scriptAddresses.find(gameObjectType.GetName());
				if (it != scriptAddresses.end())
				{
					for (auto address : it->second)
					{
						if (address.name == scriptAddress)
						{
							std::stringstream stream;
							stream << "0x" << SSTREAM_HEX4(address.address);
							param.value = stream.str();
							break;
						}
					}
				}
			}
			else if (variable.FindTagValue("SCRIPTGLOBAL", scriptAddress))
			{
				ScriptAddressMap::const_iterator it = scriptAddresses.find(gameObjectType.GetName());
				if (it != scriptAddresses.end())
				{
					for (auto address : it->second)
					{
						if (address.name == scriptAddress)
						{
							std::stringstream stream;
							stream << "0x" << SSTREAM_HEX4(address.address);
							param.value = stream.str();
							break;
						}
					}
				}
			}
			else
			{
				param.value = variable.m_value;

				//If game object has overridden the variable, take that value instead
				if (gameObject)
				{
					if (const GameObjectVariable* overriddenVar = gameObject->FindVariable(variable.m_name))
					{
						param.value = overriddenVar->m_value;
					}
				}
			}

			switch (variable.m_size)
			{
			case eSizeByte:
				param.size = luminary::ParamSize::Byte;
				break;
			case eSizeWord:
				param.size = luminary::ParamSize::Word;
				break;
			case eSizeLong:
				param.size = luminary::ParamSize::Long;
				break;
			}
		}

		void ConvertArchetype(const Project& project, const GameObjectArchetype& srcArchetype, const luminary::ScriptAddressMap& scriptAddresses, luminary::Archetype& archetype)
		{
			if (const GameObjectType* gameObjectType = project.GetGameObjectType(srcArchetype.typeId))
			{
				archetype.name = srcArchetype.name;
				archetype.entityTypeName = gameObjectType->GetName();
				const Actor* actor = project.GetActor(srcArchetype.spriteActorId);
				if (!actor)
					actor = project.GetActor(gameObjectType->GetSpriteActorId());

				//Create archetype params
				int paramIdx = 0;
				int componentIdx = -1;

				const std::vector<GameObjectVariable>& variables = gameObjectType->GetVariables();

				for (int j = 0; j < variables.size(); j++, paramIdx++)
				{
					//Find overridden variable on archetype
					const GameObjectVariable* variable = srcArchetype.FindVariable(variables[j].m_name, variables[j].m_componentIdx);
					if (!variable)
					{
						//Use variable from game object type
						variable = &variables[j];
					}

					luminary::Param* param = nullptr;

					if (variable->m_componentIdx == -1)
					{
						//Entity param
						archetype.params.resize(paramIdx + 1);
						param = &archetype.params[paramIdx];
					}
					else
					{
						//Component param
						if (componentIdx != variable->m_componentIdx)
						{
							componentIdx = variable->m_componentIdx;
							archetype.components.resize(componentIdx + 1);
							archetype.components[componentIdx].name = variable->m_componentName;
							paramIdx = 0;
						}

						archetype.components[componentIdx].spawnData.params.resize(paramIdx + 1);
						param = &archetype.components[componentIdx].spawnData.params[paramIdx];
					}

					ConvertParam(*param, *variable, *gameObjectType, &srcArchetype, nullptr, nullptr, project.GetActors(), scriptAddresses);
				}
			}
		}

		void ConvertPrefabType(const Project& project, const GameObjectType& gameObjectType, luminary::Prefab& prefab)
		{
			prefab.name = gameObjectType.GetPrefabName();
			prefab.id = gameObjectType.GetId() & 0xFFFF;

			//Convert children to luminary entities
			for (auto child : gameObjectType.GetPrefabChildren())
			{
				if (const GameObjectType* childType = project.GetGameObjectType(child.typeId))
				{
					luminary::Entity entity;
					luminary::beehive::ConvertPrefabChild(project, *childType, child, entity);
					entity.id = child.instanceId;
					entity.spawnData.positionX = child.relativePos.x;
					entity.spawnData.positionY = child.relativePos.y;
					prefab.children.push_back(entity);
				}
			}
		}

		const GameObjectVariable* FindVariable(const std::vector<GameObjectVariable>& variables, const std::string& name, int componentIdx)
		{
			for (int i = 0; i < variables.size(); i++)
			{
				if (((componentIdx == -1) || (componentIdx == variables[i].m_componentIdx)) && ion::string::CompareNoCase(variables[i].m_name, name))
				{
					return &variables[i];
				}
			}

			return nullptr;
		}

		void ConvertPrefabChild(const Project& project, const GameObjectType& gameObjectType, const GameObjectType::PrefabChild& prefabChild, luminary::Entity& entity)
		{
			//Convert base type
			ConvertEntityType(project, gameObjectType, entity);

			entity.spawnData.name = prefabChild.name;

			//Merge instance variables
			int paramIdx = 0;
			int componentIdx = -1;

			const std::vector<GameObjectVariable>& typeVariables = gameObjectType.GetVariables();

			const Actor* actor = project.GetActor(prefabChild.spriteActorId);

			if (!actor)
				actor = project.GetActor(gameObjectType.GetSpriteActorId());

			luminary::ScriptAddressMap scriptAddresses;

			for (int j = 0; j < typeVariables.size(); j++, paramIdx++)
			{
				//Find overridden variable
				const GameObjectVariable* variable = FindVariable(prefabChild.variables, typeVariables[j].m_name, typeVariables[j].m_componentIdx);
				if (!variable)
				{
					//Use variable from game object type
					variable = &typeVariables[j];
				}

				luminary::Param* param = nullptr;

				if (variable->m_componentIdx == -1)
				{
					//Entity param
					entity.spawnData.params.resize(paramIdx + 1);
					param = &entity.spawnData.params[paramIdx];
				}
				else
				{
					//Component param
					if (componentIdx != variable->m_componentIdx)
					{
						componentIdx = variable->m_componentIdx;
						entity.components.resize(componentIdx + 1);
						entity.components[componentIdx].name = variable->m_componentName;
						paramIdx = 0;
					}

					entity.components[componentIdx].spawnData.params.resize(paramIdx + 1);
					param = &entity.components[componentIdx].spawnData.params[paramIdx];
				}

				ConvertParam(*param, *variable, gameObjectType, nullptr, nullptr, &prefabChild, project.GetActors(), scriptAddresses);
			}
		}

		void ConvertEntityType(const Project& project, const GameObjectType& gameObjectType, luminary::Entity& entity)
		{
			//Entity name and id
			entity.typeName = gameObjectType.GetName();
			entity.spawnData.name = gameObjectType.IsPrefabType() ? gameObjectType.GetPrefabName() : gameObjectType.GetName();
			entity.id = gameObjectType.GetId() & 0xFFFF;

			//Size
			entity.spawnData.width = gameObjectType.GetDimensions().x;
			entity.spawnData.height = gameObjectType.GetDimensions().y;

			//Sprite actor from game object type
			const Actor* actor = project.GetActor(gameObjectType.GetSpriteActorId());

			//Create entity and component spawn params
			int paramIdx = 0;
			int componentIdx = -1;

			const std::vector<GameObjectVariable>& variables = gameObjectType.GetVariables();
			luminary::ScriptAddressMap scriptAddresses;

			for (int j = 0; j < variables.size(); j++, paramIdx++)
			{
				//Find overridden variable on game object
				const GameObjectVariable* variable = &variables[j];

				luminary::Param* param = nullptr;

				if (variable->m_componentIdx == -1)
				{
					//Entity param
					entity.spawnData.params.resize(paramIdx + 1);
					param = &entity.spawnData.params[paramIdx];
				}
				else
				{
					//Component param
					if (componentIdx != variable->m_componentIdx)
					{
						componentIdx = variable->m_componentIdx;
						entity.components.resize(componentIdx + 1);
						entity.components[componentIdx].name = variable->m_componentName;
						paramIdx = 0;
					}

					entity.components[componentIdx].spawnData.params.resize(paramIdx + 1);
					param = &entity.components[componentIdx].spawnData.params[paramIdx];
				}

				ConvertParam(*param, *variable, gameObjectType, nullptr, nullptr, nullptr, project.GetActors(), scriptAddresses);
			}

			//Convert entity/component script functions
			const std::vector<GameObjectScriptFunc>& scriptFuncs = gameObjectType.GetScriptFunctions();

			for (int j = 0; j < scriptFuncs.size(); j++)
			{
				ScriptFunc scriptFunc;
				scriptFunc.name = scriptFuncs[j].name;
				scriptFunc.params = scriptFuncs[j].params;
				scriptFunc.returnType = scriptFuncs[j].returnType;
				scriptFunc.routine = scriptFuncs[j].routine;

				if (scriptFuncs[j].componentIdx == -1)
				{
					scriptFunc.scope = entity.typeName;
					entity.scriptFuncs.push_back(scriptFunc);
				}
				else
				{
					scriptFunc.scope = entity.components[scriptFuncs[j].componentIdx].name;
					entity.components[scriptFuncs[j].componentIdx].scriptFuncs.push_back(scriptFunc);
				}
			}
		}

		void ConvertEntityInstance(const Project& project, const GameObjectType& gameObjectType, const GameObject& gameObject, const luminary::ScriptAddressMap& scriptAddresses, luminary::Entity& entity)
		{
			//Entity name and id
			entity.typeName = gameObjectType.GetName();
			entity.id = gameObject.GetId() & 0xFFFF;

			//Entity name
			if (gameObject.GetName().size() > 0)
				entity.spawnData.name = gameObject.GetName();
			else
				entity.spawnData.name = gameObjectType.GetName() + std::to_string(gameObject.GetId());

			//Spawn position
			entity.spawnData.positionX = gameObject.GetPosition().x + GameObject::spriteSheetBorderX;
			entity.spawnData.positionY = gameObject.GetPosition().y + GameObject::spriteSheetBorderY;
			entity.spawnData.width = (gameObject.GetDimensions().x > 0) ? gameObject.GetDimensions().x : gameObjectType.GetDimensions().x;
			entity.spawnData.height = (gameObject.GetDimensions().y > 0) ? gameObject.GetDimensions().y : gameObjectType.GetDimensions().y;

			//Sprite actor from game object
			const Actor* actor = project.GetActor(gameObject.GetSpriteActorId());

			//Sprite actor from game object type
			if (!actor)
				actor = project.GetActor(gameObjectType.GetSpriteActorId());

			//Create entity and component spawn params
			int paramIdx = 0;
			int componentIdx = -1;

			const std::vector<GameObjectVariable>& variables = gameObjectType.GetVariables();

			for (int j = 0; j < variables.size(); j++, paramIdx++)
			{
				//Find overridden variable on game object
				const GameObjectVariable* variable = gameObject.FindVariable(variables[j].m_name, variables[j].m_componentIdx);
				if (!variable)
				{
					//Use variable from game object type
					variable = &variables[j];
				}

				luminary::Param* param = nullptr;

				if (variable->m_componentIdx == -1)
				{
					//Entity param
					entity.spawnData.params.resize(paramIdx + 1);
					param = &entity.spawnData.params[paramIdx];
				}
				else
				{
					//Component param
					if (componentIdx != variable->m_componentIdx)
					{
						componentIdx = variable->m_componentIdx;
						entity.components.resize(componentIdx + 1);
						entity.components[componentIdx].name = variable->m_componentName;
						paramIdx = 0;
					}

					entity.components[componentIdx].spawnData.params.resize(paramIdx + 1);
					param = &entity.components[componentIdx].spawnData.params[paramIdx];
				}

				ConvertParam(*param, *variable, gameObjectType, nullptr, &gameObject, nullptr, project.GetActors(), scriptAddresses);
			}

			//Create entity/component script functions
			const std::vector<GameObjectScriptFunc>& scriptFuncs = gameObjectType.GetScriptFunctions();

			for (int j = 0; j < scriptFuncs.size(); j++)
			{
				ScriptFunc scriptFunc;
				scriptFunc.name = scriptFuncs[j].name;
				scriptFunc.params = scriptFuncs[j].params;
				scriptFunc.returnType = scriptFuncs[j].returnType;
				scriptFunc.routine = scriptFuncs[j].routine;

				if (scriptFuncs[j].componentIdx == -1)
				{
					scriptFunc.scope = entity.typeName;
					entity.scriptFuncs.push_back(scriptFunc);
				}
				else
				{
					scriptFunc.scope = entity.components[scriptFuncs[j].componentIdx].name;
					entity.components[scriptFuncs[j].componentIdx].scriptFuncs.push_back(scriptFunc);
				}
			}
		}
	}
}