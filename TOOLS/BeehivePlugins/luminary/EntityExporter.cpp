// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 6th December 2019
// ============================================================================================
// EntityExporter.cpp - Exports entities and archetypes
// ============================================================================================

#include "EntityExporter.h"

#include <ion/core/io/File.h>
#include <ion/core/utils/STL.h>
#include <ion/maths/Vector.h>
#include <ion/maths/Fixed.h>

#include <sstream>

namespace luminary
{
	EntityExporter::EntityExporter()
	{

	}

	bool EntityExporter::ExportArchetypes(const std::string& filename, const std::vector<Archetype>& archetypes)
	{
		if (archetypes.size() == 0)
			return false;

		SerialiserAsm serialiser(filename);
		if (!serialiser.IsOpen())
			return false;

		for (int i = 0; i < archetypes.size(); i++)
		{
			const Archetype& archetype = archetypes[i];

			//Export to file
			serialiser.Label("Archetype_", archetype.entityTypeName, "_", archetype.name);
			ExportSpawnParamsData(serialiser, archetype.name, 0, archetype.params, archetype.components);
		}

		return true;
	}

	bool EntityExporter::ExportPrefabs(const std::string& filename, const std::vector<Prefab>& prefabs)
	{
		if (prefabs.size() == 0)
			return false;

		SerialiserAsm serialiser(filename);
		if (!serialiser.IsOpen())
			return false;

		//Export root datas
		for (auto prefab : prefabs)
		{
			serialiser.Label("prefabdata_", prefab.name);
			serialiser.Value(prefab.id,						"Prefab_TypeId");
			serialiser.Value((u16)prefab.children.size(),	"Prefab_ChildCount");
			serialiser.Value("prefabspawntable_", prefab.name);
			serialiser.Break();
		}

		serialiser.Break();

		//Export entity/component param tables
		std::map<std::string, EntityExporter::ExportedSpawnData> exportedSpawnDatas;

		for (auto prefab : prefabs)
		{
			for (auto child : prefab.children)
			{
				std::string spawnDataName = "prefabchildspawndata_" + prefab.name + "_" + child.spawnData.name;
				EntityExporter::ExportEntitySpawnTableData(serialiser, spawnDataName, child, exportedSpawnDatas);
				serialiser.Break();
			}
		}

		serialiser.Break();

		//Export spawn table
		for (auto prefab : prefabs)
		{
			serialiser.Label("prefabspawntable_", prefab.name);

			for (auto child : prefab.children)
			{
				std::string spawnDataName = "prefabchildspawndata_" + prefab.name + "_" + child.spawnData.name;

				std::map<std::string, EntityExporter::ExportedSpawnData>::const_iterator it = exportedSpawnDatas.find(child.spawnData.name);
				if (it != exportedSpawnDatas.end())
				{
					spawnDataName = it->second.labelName;
				}

				// SceneEntity
				serialiser.Value(child.typeName, "_Typedesc");
				serialiser.Value(spawnDataName);
				serialiser.Value(child.spawnData.position,	"SceneEntity_Pos");
				serialiser.Value(child.spawnData.extents,	"SceneEntity_Extents");
				serialiser.Break();
			}

			serialiser.Break();
		}

		return true;
	}

	bool EntityExporter::ExportAnimations(const std::string& filename, const std::vector<Animation>& animations)
	{
		if (animations.size() == 0)
			return false;

		SerialiserAsm serialiser(filename);
		if (!serialiser.IsOpen())
			return false;

		for (const auto& animation : animations)
		{
			const int megaDriveFramesPerSecond = 60;
			const int keyframesPerSecond = 15;
			const int numKeyframes = animation.length * keyframesPerSecond;
			float keyframeStep = animation.length / numKeyframes;
			float megaDriveFramesPerKeyframe = (keyframeStep * megaDriveFramesPerSecond);

			// STRUCT_BEGIN ECAnimData
			// ECAnimData_InitialPosList          rs.l 1
			// ECAnimData_KeyframeTimesList       rs.l 1
			// ECAnimData_KeyframeTrackListPos    rs.l 1
			// ECAnimData_ActorCount              rs.w 1
			// ECAnimData_KeyframeCount           rs.w 1
			// ECAnimData_Looping                 rs.b 1
			// STRUCT_END

			serialiser.Define(animation.name + "_ActorCount", (u32)animation.actorNames.size());
			serialiser.Define(animation.name + "_KeyframeCount", numKeyframes);
			serialiser.Define(animation.name + "_Looping", animation.looping ? 1 : 0);

			serialiser.Break();

			serialiser.Label(animation.name);
			serialiser.Long(animation.name + "_InitialPositions");
			serialiser.Long(animation.name + "_KeyframeTimes");
			serialiser.Long(animation.name + "_KeyframeTrackList_Pos");
			serialiser.Word(animation.name + "_ActorCount");
			serialiser.Word(animation.name + "_KeyframeCount");
			serialiser.Byte(animation.name + "_Looping");
			serialiser.Align();

			serialiser.Break();

			// =========================================================================================================================

			//; Initial object positions
			//SceneAnim_l1a1_BossTest11_InitialPositions:
			//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Core_3
			//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Joint_4
			//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Joint_5
			//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Joint_6
			//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Joint_7

			serialiser.Comment("Initial object positions");
			serialiser.Label(animation.name, "_InitialPositions");

			for (const auto& positionTrack : animation.positionTracks)
			{
				//	dc.w 0x0001, 0x0000

				ion::Vector2i position = positionTrack.GetValue(0.0f);
				serialiser.Value(position);
			}

			serialiser.Break();

			// =========================================================================================================================

			//; Keyframe times
			//SceneAnim_l1a1_BossTest11_KeyframeTimes :
			//	dc.w 0x0000
			//	dc.w 0x0004
			//	dc.w 0x0008
			//	dc.w 0x000C
			//	dc.w 0x0010
			//	dc.w 0x0014
			//	dc.w 0x0018
			//	dc.w 0x001C

			serialiser.Comment("Keyframe times");
			serialiser.Label(animation.name, "_KeyframeTimes");

			for (int i = 0; i < numKeyframes; i++)
			{
				serialiser.Value((u16)(megaDriveFramesPerKeyframe * i));
			}

			serialiser.Break();

			// =========================================================================================================================

			//; Keyframe tracks (position)
			//SceneAnim_l1a1_BossTest11_KeyframeTrackList_Pos:
			//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Core_3
			//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Joint_4
			//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Joint_5
			//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Joint_6
			//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Joint_7

			serialiser.Comment("Keyframe tracks (position)");
			serialiser.Label(animation.name, "_KeyframeTrackList_Pos");

			for (const auto& name : animation.actorNames)
			{
				serialiser.Value(animation.name, "_KeyframeTrack_Pos_", name);
			}

			serialiser.Break();

			for(int i = 0; i < animation.actorNames.size(); i++)
			{
				//; Keyframe track(position, actor Core_3)
				//SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Core_3:
				//	dc.w 0x0001, 0x0000
				//	dc.w 0x0000, 0x0001
				//	dc.w 0x0002, 0x0000
				//	dc.w 0x0000, 0x0002
				//	dc.w 0x0003, 0x0000
				//	dc.w 0x0000, 0x0003
				//	dc.w 0x0004, 0x0000
				//	dc.w 0x0000, 0x0004

				const auto& name = animation.actorNames[i];
				const auto& positionTrack = animation.positionTracks[i];

				serialiser.Comment("Keyframe track(position, actor " + name + ")");
				serialiser.Label(animation.name, "_KeyframeTrack_Pos_", name);

				ion::Vector2i lastPosition = positionTrack.GetValue(0.0f);

				for (int j = 1; j < numKeyframes + 1; j++)
				{
					ion::Vector2i position = positionTrack.GetValue(keyframeStep * j);

					ion::Vector2i delta = position - lastPosition;
					ion::Vector2 velocity((float)delta.x / megaDriveFramesPerKeyframe, (float)delta.y / megaDriveFramesPerKeyframe);
					lastPosition = position;
					serialiser.Value(ion::maths::FloatToFixed1616(velocity.x), ion::maths::FloatToFixed1616(velocity.y));
				}

				serialiser.Break();
			}
		}

		return true;
	}

	void EntityExporter::ExportSpawnParamsData(SerialiserAsm& serialiser, const std::string& name, unsigned short id, const std::vector<Param>& entityParams, const std::vector<std::pair<Component,std::string>>& components)
	{
		// IFND FINAL
		// EntitySpawnData_DebugName                     rs.b ENT_DEBUG_NAME_LEN
		// ENDIF
		serialiser.IfNDef("FINAL");
		EntityExporter::ExportDebugNameData(serialiser, name, s_debugNameLen);
		serialiser.EndIf();

		serialiser.Value(id, "EntitySpawnData_Id");

		//Export entity params
		for (int j = 0; j < entityParams.size(); j++)
		{
			const Param& param = entityParams[j];
			std::string value = param.value;
			if (value.size() == 0)
				value = "0";

			switch (param.size)
			{
				case ParamSize::Byte:
					serialiser.Byte(value, param.name);
					break;
				case ParamSize::Word:
					serialiser.Word(value, param.name);
					break;
				case ParamSize::Long:
					serialiser.Long(value, param.name);
					break;
			}
		}

		//Export component params
		for (int j = 0; j < components.size(); j++)
		{
			const Component& component = components[j].first;
			if (component.spawnData.params.size() > 0)
			{
				serialiser.Comment(component.typeName);

				for (int k = 0; k < component.spawnData.params.size(); k++)
				{
					const Param& param = component.spawnData.params[k];
					std::string value = param.value;
					if (value.size() == 0)
						value = "0";

					switch (param.size)
					{
						case ParamSize::Byte:
							serialiser.Byte(value, param.name);
							break;
						case ParamSize::Word:
							serialiser.Word(value, param.name);
							break;
						case ParamSize::Long:
							serialiser.Long(value, param.name);
							break;
					}
				}

				serialiser.Align();
			}
		}

		serialiser.Break();
	}

	void EntityExporter::ExportStaticEntityData(SerialiserAsm& serialiser, const Entity& entity)
	{
		// IFND FINAL
		// EntityBlock_DebugName                   rs.b ENT_DEBUG_NAME_LEN (16)
		// ENDIF
		// EntityBlock_Flags                       rs.b 1
		// EntityBlock_Priority                    rs.b 1
		// EntityBlock_Next                        rs.w 1
		// Entity_TypeDesc                         rs.w 1; Entity type
		// Entity_Id                               rs.w 1; Unique id
		// Entity_SpawnData                        rs.l 1; Spawn data
		// Entity_PosX                             rs.l 1; World pos X(16.16)
		// Entity_PosY                             rs.l 1; World pos Y(16.16)
		// Entity_ExtentsX                         rs.w 1; Width in pixels
		// Entity_ExtentsY                         rs.w 1; Height in pixels
		// ...all params

		u8 zero8 = 0;
		u16 zero16 = 0;

		std::string spawnDataName = entity.spawnData.name + "_" + std::to_string(entity.id) + "_SpawnData";

		serialiser.IfNDef("FINAL");
		EntityExporter::ExportDebugNameData(serialiser, entity.spawnData.name, EntityExporter::s_debugNameLen);
		serialiser.EndIf();
		serialiser.Value(zero8,								"EntityBlock_Flags");
		serialiser.Value(zero8,								"EntityBlock_Priority");
		serialiser.Value(zero16,							"EntityBlock_Next");
		serialiser.Word(entity.typeName + "_Typedesc",		"Entity_TypeDesc");
		serialiser.Value(entity.id,							"Entity_Id");
		serialiser.Value(spawnDataName);
		serialiser.Value(entity.spawnData.position.x << 16,	"Entity_PosX");
		serialiser.Value(entity.spawnData.position.y << 16,	"Entity_PosY");
		serialiser.Value(entity.spawnData.extents,			"Entity_Extents");

		serialiser.Break();

		//Export all params
		serialiser.Label(spawnDataName);

		for (int j = 0; j < entity.spawnData.params.size(); j++)
		{
			const Param& param = entity.spawnData.params[j];
			std::string value = param.value;
			if (value.size() == 0)
				value = "0";

			switch (param.size)
			{
				case ParamSize::Byte:
					serialiser.Byte(value, param.name);
					break;
				case ParamSize::Word:
					serialiser.Word(value, param.name);
					break;
				case ParamSize::Long:
					serialiser.Long(value, param.name);
					break;
			}
		}

		serialiser.Align();
	}

	void EntityExporter::ExportEntitySpawnTableData(SerialiserAsm& serialiser, const std::string& spawnDataName, const Entity& entity, std::map<std::string, ExportedSpawnData>& exportedSpawnDatas)
	{
		std::stringstream stream;

		//Build spawn data block from entity and all components
		std::vector<const SpawnData*> spawnDataBlock;
		spawnDataBlock.push_back(&entity.spawnData);

		for (int j = 0; j < entity.components.size(); j++)
		{
			spawnDataBlock.push_back(&entity.components[j].first.spawnData);
		}

		//If spawn data params matches any previously exported, save some space by sharing it
		const ExportedSpawnData* matchingSpawnData = nullptr;

#if 0 // TODO: Name and id needs removing from spawn params, so variables alone can match up
		for (std::map<std::string, ExportedSpawnData>::const_iterator it = exportedSpawnDatas.begin(), end = exportedSpawnDatas.end(); it != end && !matchingSpawnData; ++it)
		{
			bool match = it->second.data.size() == spawnDataBlock.size();

			//Ignoring position, so compare individual SpawnData::params
			for (int j = 0; j < it->second.data.size() && match; j++)
			{
				match = (it->second.data[j]->params == spawnDataBlock[j]->params);
			}

			if (match)
			{
				matchingSpawnData = &it->second;
			}
		}
#endif

		if (matchingSpawnData)
		{
			ExportedSpawnData exportedData;
			exportedData.labelName = matchingSpawnData->labelName;
			exportedSpawnDatas.insert(std::make_pair(entity.spawnData.name, exportedData));
		}
		else
		{
			//Export to file
			serialiser.Label(spawnDataName);
			EntityExporter::ExportSpawnParamsData(serialiser, entity.spawnData.name, entity.id, entity.spawnData.params, entity.components);

			ExportedSpawnData exportedData;
			exportedData.labelName = spawnDataName;
			exportedData.data = spawnDataBlock;
			exportedSpawnDatas.insert(std::make_pair(entity.spawnData.name, exportedData));
		}
	}

	void EntityExporter::ExportDebugNameData(SerialiserAsm& serialiser, const std::string& name, int maxLength)
	{
		serialiser.FixedString(name, maxLength);
	}
}