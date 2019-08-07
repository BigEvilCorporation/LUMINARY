// ============================================================================================
// LUMINARY - a game engine and framework for the SEGA Mega Drive
// ============================================================================================
// Matt Phillips - Big Evil Corporation Ltd - 7th August 2019
// ============================================================================================
// SceneExporter.cpp - Utilities for exporting Beehive GameObject data to Luminary scene,
// entity and component spawn data
// ============================================================================================

#include "SceneExporter.h"

#include <ion/io/File.h>
#include <ion/core/utils/STL.h>

#include <sstream>

namespace luminary
{
	SceneExporter::SceneExporter()
	{

	}

	bool SceneExporter::ExportScene(const std::string& filename, const std::string& sceneName, const std::vector<Entity>& entities)
	{
		//	PlayerSpawnData:
		//		; SDPlayer
		//		dc.w   0x000F
		//
		//		; SDPhysicsBody
		//
		//		; SDSprite
		//		dc.l   TestSprite
		//		dc.w   1
		//		dc.b   VDP_SPRITE_LAYOUT_1x1
		//
		//		even

		//	TestScene1_Entities:
		//		dc.l   EPlayer_TypeDesc; SceneEntity_EntityType
		//		dc.l   PlayerSpawnData; SceneEntity_SpawnData
		//		dc.w   0x0088; SceneEntity_PosX
		//		dc.w   0x0088; SceneEntity_PosY
		//		; --
		//		dc.l   EPlayer_TypeDesc; SceneEntity_EntityType
		//		dc.l   PlayerSpawnData; SceneEntity_SpawnData
		//		dc.w   0x0030; SceneEntity_PosX
		//		dc.w   0x0100; SceneEntity_PosY
		//		; --
		//		dc.l   EPlayer_TypeDesc; SceneEntity_EntityType
		//		dc.l   PlayerSpawnData; SceneEntity_SpawnData
		//		dc.w   0x0090; SceneEntity_PosX
		//		dc.w   0x0110; SceneEntity_PosY
		//		; --
		//		dc.l   EPlayer_TypeDesc; SceneEntity_EntityType
		//		dc.l   PlayerSpawnData; SceneEntity_SpawnData
		//		dc.w   0x0100; SceneEntity_PosX
		//		dc.w   0x0120; SceneEntity_PosY
		//	
		//		TestScene1 :
		//		dc.w 4; SceneData_EntityCount
		//		dc.l TestScene1_Entities; SceneData_Entities

		ion::io::File file(filename, ion::io::File::eOpenWrite);
		if (file.IsOpen())
		{
			std::stringstream stream;

			//Export entity and component spawn data tables
			for (int i = 0; i < entities.size(); i++)
			{
				const Entity& entity = entities[i];

				stream << "SceneEntitySpawnData_" << sceneName << "_" << entity.name << "_" << entity.spawnData.name << ":" << std::endl;

				//Export entity spawn data
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

				//Export component spawn data
				for (int j = 0; j < entity.components.size(); j++)
				{
					const Component& component = entity.components[j];
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
			}

			stream << std::endl;

			//Export entity spawn tables
			stream << "SceneEntityData_" << sceneName << ":" << std::endl;

			for (int i = 0; i < entities.size(); i++)
			{
				const Entity& entity = entities[i];

				stream << "SceneEntity_" << sceneName << "_" << entity.name << "_" << entity.spawnData.name << ":" << std::endl;

				stream << "\tdc.l " << entity.name << "_Typedesc\t; Entity descriptor" << std::endl;
				stream << "\tdc.l " << "SceneEntitySpawnData_" << sceneName << "_" << entity.name << "_" << entity.spawnData.name << "\t; Entity spawn data" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.spawnData.positionX) << "\t; Position X" << std::endl;
				stream << "\tdc.w 0x" << SSTREAM_HEX4(entity.spawnData.positionY) << "\t; Position Y" << std::endl;
			}

			stream << std::endl;

			//Export scene
			stream << "SceneData_" << sceneName << ":" << std::endl;
			stream << "\tdc.w " << entities.size() << "\t; Entity count" << std::endl;
			stream << "\tdc.l " << "SceneEntityData_" << sceneName << "\t; Entity table" << std::endl;

			file.Write(stream.str().c_str(), stream.str().size());
			file.Close();
		}

		return true;
	}
}