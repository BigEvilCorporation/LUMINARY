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
		ion::io::File file(filename, ion::io::File::OpenMode::Write);
		if (file.IsOpen())
		{
			std::stringstream stream;

			for (int i = 0; i < archetypes.size(); i++)
			{
				const Archetype& archetype = archetypes[i];

				//Export to file
				stream << "Archetype_" << archetype.entityTypeName << "_" << archetype.name << ":" << std::endl;
				stream << ExportSpawnParamsData(archetype.name, 0, archetype.params, archetype.components);
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();

			return true;
		}

		return false;
	}

	bool EntityExporter::ExportPrefabs(const std::string& filename, const std::vector<Prefab>& prefabs)
	{
		ion::io::File file(filename, ion::io::File::OpenMode::Write);
		if (file.IsOpen())
		{
			std::stringstream stream;

			//Export root datas
			for (auto prefab : prefabs)
			{
				stream << "prefabdata_" << prefab.name << ":" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(prefab.id) << "\t; Prefab_TypeId" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(prefab.children.size()) << "\t; Prefab_ChildCount" << std::endl;
				stream << "\tdc.l prefabspawntable_" << prefab.name << "\t; Prefab_SpawnTable" << std::endl;
				stream << std::endl;
			}

			stream << std::endl;

			//Export entity/component param tables
			std::map<std::string, EntityExporter::ExportedSpawnData> exportedSpawnDatas;

			for (auto prefab : prefabs)
			{
				for (auto child : prefab.children)
				{
					std::stringstream spawnDataName;
					spawnDataName << "prefabchildspawndata_" << prefab.name << "_" << child.spawnData.name;
					stream << EntityExporter::ExportEntitySpawnTableData(spawnDataName.str(), child, exportedSpawnDatas);
					stream << std::endl;
				}
			}

			stream << std::endl;

			//Export spawn table
			for (auto prefab : prefabs)
			{
				stream << "prefabspawntable_" << prefab.name << ":" << std::endl;

				for (auto child : prefab.children)
				{
					std::stringstream spawnDataName;
					spawnDataName << "prefabchildspawndata_" << prefab.name << "_" << child.spawnData.name;

					std::map<std::string, EntityExporter::ExportedSpawnData>::const_iterator it = exportedSpawnDatas.find(child.spawnData.name);
					if (it != exportedSpawnDatas.end())
					{
						spawnDataName.str(it->second.labelName);
					}

					ion::Vector2i extents(child.spawnData.width / 2, child.spawnData.height / 2);

					// SceneEntity
					stream << "\tdc.w " << child.typeName << "_Typedesc\t; SceneEntity_EntityType" << std::endl;
					stream << "\tdc.l " << spawnDataName.str() << "\t; SceneEntity_SpawnData" << std::endl;
					stream << "\tdc.w 0x" << SSTREAM_HEX4(child.spawnData.positionX) << "\t; SceneEntity_PosX" << std::endl;
					stream << "\tdc.w 0x" << SSTREAM_HEX4(child.spawnData.positionY) << "\t; SceneEntity_PosY" << std::endl;
					stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.x) << "\t; SceneEntity_ExtentsX" << std::endl;
					stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.y) << "\t; SceneEntity_ExtentsY" << std::endl;
					stream << std::endl;
				}

				stream << std::endl;
			}

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();

			return true;
		}

		return false;
	}

	bool EntityExporter::ExportAnimations(const std::string& filename, const std::vector<Animation>& animations)
	{
		ion::io::File file(filename, ion::io::File::OpenMode::Write);
		if (file.IsOpen())
		{
			std::stringstream stream;

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

				stream << animation.name << "_ActorCount\t\tequ " << animation.actorNames.size() << std::endl;
				stream << animation.name << "_KeyframeCount\t\tequ " << numKeyframes << std::endl;
				stream << animation.name << "_Looping\t\tequ " << (animation.looping ? "1" : "0") << std::endl;

				stream << std::endl;

				stream << animation.name << ":" << std::endl;
				stream << "\tdc.l " << animation.name << "_InitialPositions" << std::endl;
				stream << "\tdc.l " << animation.name << "_KeyframeTimes" << std::endl;
				stream << "\tdc.l " << animation.name << "_KeyframeTrackList_Pos" << std::endl;
				stream << "\tdc.w " << animation.name << "_ActorCount" << std::endl;
				stream << "\tdc.w " << animation.name << "_KeyframeCount" << std::endl;
				stream << "\tdc.b " << animation.name << "_Looping" << std::endl;
				stream << "\teven" << std::endl;

				stream << std::endl;

				// =========================================================================================================================

				//; Initial object positions
				//SceneAnim_l1a1_BossTest11_InitialPositions:
				//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Core_3
				//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Joint_4
				//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Joint_5
				//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Joint_6
				//	dc.l SceneAnim_l1a1_BossTest1_InitialPosition_l1a1_Joint_7

				stream << "; Initial object positions" << std::endl;
				stream << animation.name << "_InitialPositions:" << std::endl;

				for (const auto& positionTrack : animation.positionTracks)
				{
					//	dc.w 0x0001, 0x0000

					ion::Vector2i position = positionTrack.GetValue(0.0f);

					stream << "\tdc.w 0x" << SSTREAM_HEX4(position.x) << ", 0x" << SSTREAM_HEX4(position.y) << std::endl;
				}

				stream << std::endl;

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

				stream << "; Keyframe times" << std::endl;
				stream << animation.name << "_KeyframeTimes:" << std::endl;

				for (int i = 0; i < numKeyframes; i++)
				{
					stream << "\tdc.w 0x" << SSTREAM_HEX4((int)(megaDriveFramesPerKeyframe * i)) << std::endl;
				}

				stream << std::endl;

				// =========================================================================================================================

				//; Keyframe tracks (position)
				//SceneAnim_l1a1_BossTest11_KeyframeTrackList_Pos:
				//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Core_3
				//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Joint_4
				//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Joint_5
				//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Joint_6
				//	dc.l SceneAnim_l1a1_BossTest1_KeyframeTrack_Pos_l1a1_Joint_7

				stream << "; Keyframe tracks (position)" << std::endl;
				stream << animation.name << "_KeyframeTrackList_Pos:" << std::endl;

				for (const auto& name : animation.actorNames)
				{
					stream << "\tdc.l " << animation.name << "_KeyframeTrack_Pos_" << name << std::endl;
				}

				stream << std::endl;

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

					stream << "; Keyframe track (position, actor " << name << ")" << std::endl;
					stream << animation.name << "_KeyframeTrack_Pos_" << name << ":" << std::endl;

					ion::Vector2i lastPosition = positionTrack.GetValue(0.0f);

					for (int i = 1; i < numKeyframes + 1; i++)
					{
						ion::Vector2i position = positionTrack.GetValue(keyframeStep * i);

						ion::Vector2i delta = position - lastPosition;
						ion::Vector2 velocity((float)delta.x / megaDriveFramesPerKeyframe, (float)delta.y / megaDriveFramesPerKeyframe);
						lastPosition = position;
						stream << "\tdc.l 0x" << SSTREAM_HEX8(ion::maths::FloatToFixed1616(velocity.x)) << ", 0x" << SSTREAM_HEX8(ion::maths::FloatToFixed1616(velocity.y)) << std::endl;
					}

					stream << std::endl;
				}
			}

			stream << std::endl;
			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();

			return true;
		}

		return false;
	}

	std::string EntityExporter::ExportSpawnParamsData(const std::string& name, unsigned short id, const std::vector<Param>& entityParams, const std::vector<Component>& components)
	{
		std::stringstream stream;

		// IFND FINAL
		// EntitySpawnData_DebugName                     rs.b ENT_DEBUG_NAME_LEN
		// ENDIF
		stream << "\tIFND FINAL" << std::endl;
		stream << "\tdc.b " << EntityExporter::ExportDebugNameData(name, s_debugNameLen) << "\t; EntitySpawnData_DebugName" << std::endl;
		stream << "\tENDIF" << std::endl;

		stream << "\tdc.w 0x" << SSTREAM_HEX4(id) << "\t; EntitySpawnData_Id" << std::endl;

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
					stream << "\tdc.b " << value << "\t; " << param.name << std::endl;
					break;
				case ParamSize::Word:
					stream << "\tdc.w " << value << "\t; " << param.name << std::endl;
					break;
				case ParamSize::Long:
					stream << "\tdc.l " << value << "\t; " << param.name << std::endl;
					break;
			}
		}

		//Export component params
		for (int j = 0; j < components.size(); j++)
		{
			const Component& component = components[j];
			if (component.spawnData.params.size() > 0)
			{
				stream << "\t; " << component.name << std::endl;

				for (int k = 0; k < component.spawnData.params.size(); k++)
				{
					const Param& param = component.spawnData.params[k];
					std::string value = param.value;
					if (value.size() == 0)
						value = "0";

					switch (param.size)
					{
						case ParamSize::Byte:
							stream << "\tdc.b " << value << "\t; " << param.name << std::endl;
							break;
						case ParamSize::Word:
							stream << "\tdc.w " << value << "\t; " << param.name << std::endl;
							break;
						case ParamSize::Long:
							stream << "\tdc.l " << value << "\t; " << param.name << std::endl;
							break;
					}
				}

				stream << "\teven" << std::endl;
			}
		}

		stream << std::endl;

		return stream.str();
	}

	std::string EntityExporter::ExportStaticEntityData(const Entity& entity)
	{
		std::stringstream stream;

		// IFND FINAL
		// EntityBlock_DebugName                   rs.b ENT_DEBUG_NAME_LEN (16)
		// ENDIF
		// EntityBlock_Flags                       rs.w 1
		// EntityBlock_Next                        rs.w 1
		// Entity_TypeDesc                         rs.w 1; Entity type
		// Entity_Id                               rs.w 1; Unique id
		// Entity_PosX                             rs.l 1; World pos X(16.16)
		// Entity_PosY                             rs.l 1; World pos Y(16.16)
		// Entity_ExtentsX                         rs.w 1; Width in pixels
		// Entity_ExtentsY                         rs.w 1; Height in pixels
		// ...all params

		ion::Vector2i extents(entity.spawnData.width / 2, entity.spawnData.height / 2);

		stream << "\tIFND FINAL" << std::endl;
		stream << "\tdc.b " << EntityExporter::ExportDebugNameData(entity.spawnData.name, EntityExporter::s_debugNameLen) << std::endl;
		stream << "\tENDIF" << std::endl;
		stream << "\tdc.w 0x0\t; EntityBlock_Flags" << std::endl;
		stream << "\tdc.w 0x0\t; EntityBlock_Next" << std::endl;
		stream << "\tdc.w " << entity.typeName << "_Typedesc\t; Entity_TypeDesc" << std::endl;
		stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.id) << "\t; Entity_Id" << std::endl;
		stream << "\tdc.l 0x" << SSTREAM_HEX8((entity.spawnData.positionX) << 16) << "\t; Entity_PosX" << std::endl;
		stream << "\tdc.l 0x" << SSTREAM_HEX8((entity.spawnData.positionY) << 16) << "\t; Entity_PosY" << std::endl;
		stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.x) << "\t; Entity_ExtentsX" << std::endl;
		stream << "\tdc.w 0x" << SSTREAM_HEX4(extents.y) << "\t; Entity_ExtentsY" << std::endl;

		//Export all params
		for (int j = 0; j < entity.spawnData.params.size(); j++)
		{
			const Param& param = entity.spawnData.params[j];
			std::string value = param.value;
			if (value.size() == 0)
				value = "0";

			switch (param.size)
			{
				case ParamSize::Byte:
					stream << "\tdc.b " << value << "\t; " << param.name << std::endl;
					break;
				case ParamSize::Word:
					stream << "\tdc.w " << value << "\t; " << param.name << std::endl;
					break;
				case ParamSize::Long:
					stream << "\tdc.l " << value << "\t; " << param.name << std::endl;
					break;
			}
		}

		stream << "\teven" << std::endl;

		return stream.str();
	}

	std::string EntityExporter::ExportEntitySpawnTableData(const std::string& spawnDataName, const Entity& entity, std::map<std::string, ExportedSpawnData>& exportedSpawnDatas)
	{
		std::stringstream stream;

		//Build spawn data block from entity and all components
		std::vector<const SpawnData*> spawnDataBlock;
		spawnDataBlock.push_back(&entity.spawnData);

		for (int j = 0; j < entity.components.size(); j++)
		{
			spawnDataBlock.push_back(&entity.components[j].spawnData);
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
			stream << spawnDataName << ":" << std::endl;
			stream << EntityExporter::ExportSpawnParamsData(entity.spawnData.name, entity.id, entity.spawnData.params, entity.components);

			ExportedSpawnData exportedData;
			exportedData.labelName = spawnDataName;
			exportedData.data = spawnDataBlock;
			exportedSpawnDatas.insert(std::make_pair(entity.spawnData.name, exportedData));
		}

		return stream.str();
	}

	std::string EntityExporter::ExportDebugNameData(const std::string& name, int maxLength)
	{
		if (name.size() > maxLength - 1)
		{
			return "\"" + name.substr(0, maxLength - 1) + "\",0";
		}
		else
		{
			std::string out = "\"" + name.substr(0, maxLength - 1) + "\"";

			for (int i = 0; i < maxLength - name.size(); i++)
			{
				out += ",0";
			}

			return out;
		}
	}
}