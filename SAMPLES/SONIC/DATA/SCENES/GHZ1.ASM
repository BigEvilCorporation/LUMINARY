SceneEntitySpawnData_ghz1_EPlayer_EPlayer62:
	IFND FINAL
	dc.b "EPlayer62",0,0,0,0,0,0,0
	ENDIF
	dc.w 0x003E	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_sonic_spritesheet_idle	; SDSprite_Sheet
	dc.l 0	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECScript
	dc.l data_script_EPlayer	; SDScript_ScriptData
	dc.w 0x0000	; SDScript_FuncStart
	dc.w 0x0008	; SDScript_FuncShutdown
	dc.w 0x0010	; SDScript_FuncUpdate
	even

SceneEntitySpawnData_ghz1_EMotobug_Motobug1:
	IFND FINAL
	dc.b "Motobug1",0,0,0,0,0,0,0,0
	ENDIF
	dc.w 0x0042	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_motobug_spritesheet_move	; SDSprite_Sheet
	dc.l actor_motobug_sheet_move_anim_move	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_motobug_spritesheet_exhaust	; SDSprite_Sheet
	dc.l actor_motobug_sheet_exhaust_anim_exhaust	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECScript
	dc.l data_script_EMotobug	; SDScript_ScriptData
	dc.w 0x0000	; SDScript_FuncStart
	dc.w 0x0008	; SDScript_FuncShutdown
	dc.w 0x0010	; SDScript_FuncUpdate
	even

SceneEntitySpawnData_ghz1_ERing_ERing67:
	IFND FINAL
	dc.b "ERing67",0,0,0,0,0,0,0,0,0
	ENDIF
	dc.w 0x0043	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_ring_spritesheet_idle	; SDSprite_Sheet
	dc.l actor_ring_sheet_idle_anim_idle	; SDSprite_Animation
	dc.b 0x03	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even

SceneEntitySpawnData_ghz1_ERing_ERing68:
	IFND FINAL
	dc.b "ERing68",0,0,0,0,0,0,0,0,0
	ENDIF
	dc.w 0x0044	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_ring_spritesheet_idle	; SDSprite_Sheet
	dc.l actor_ring_sheet_idle_anim_idle	; SDSprite_Animation
	dc.b 0x03	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even

SceneEntitySpawnData_ghz1_ERing_ERing69:
	IFND FINAL
	dc.b "ERing69",0,0,0,0,0,0,0,0,0
	ENDIF
	dc.w 0x0045	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_ring_spritesheet_idle	; SDSprite_Sheet
	dc.l actor_ring_sheet_idle_anim_idle	; SDSprite_Animation
	dc.b 0x03	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even

SceneEntitySpawnData_ghz1_EBuzzbomb_BuzzBomb1:
	IFND FINAL
	dc.b "BuzzBomb1",0,0,0,0,0,0,0
	ENDIF
	dc.w 0x0046	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_buzzbomb_spritesheet_fly	; SDSprite_Sheet
	dc.l 0	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_buzzbomb_spritesheet_wings	; SDSprite_Sheet
	dc.l actor_buzzbomb_sheet_wings_anim_wings	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_buzzbomb_spritesheet_thruster	; SDSprite_Sheet
	dc.l actor_buzzbomb_sheet_thruster_anim_thruster	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_buzzbomb_spritesheet_fire	; SDSprite_Sheet
	dc.l actor_buzzbomb_sheet_fire_anim_fire	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even

SceneEntitySpawnData_ghz1_EBridge_EBridge75:
	IFND FINAL
	dc.b "EBridge75",0,0,0,0,0,0,0
	ENDIF
	dc.w 0x004B	; EntitySpawnData_Id
	; ECBridgeRenderer
	dc.l 0	; SDBridgeRenderer_Actor
	dc.l actor_bridge_spritesheet_segment	; SDBridgeRenderer_Sheet
	even

SceneEntitySpawnData_ghz1_EBridge_EBridge76:
	IFND FINAL
	dc.b "EBridge76",0,0,0,0,0,0,0
	ENDIF
	dc.w 0x004C	; EntitySpawnData_Id
	; ECBridgeRenderer
	dc.l 0	; SDBridgeRenderer_Actor
	dc.l actor_bridge_spritesheet_segment	; SDBridgeRenderer_Sheet
	even

SceneEntitySpawnData_ghz1_EBridge_EBridge77:
	IFND FINAL
	dc.b "EBridge77",0,0,0,0,0,0,0
	ENDIF
	dc.w 0x004D	; EntitySpawnData_Id
	; ECBridgeRenderer
	dc.l 0	; SDBridgeRenderer_Actor
	dc.l actor_bridge_spritesheet_segment	; SDBridgeRenderer_Sheet
	even

SceneEntitySpawnData_ghz1_EChopper_EChopper78:
	IFND FINAL
	dc.b "EChopper78",0,0,0,0,0,0
	ENDIF
	dc.w 0x004E	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_chopper_spritesheet_chopper	; SDSprite_Sheet
	dc.l actor_chopper_sheet_chopper_anim_chopper	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even

SceneEntitySpawnData_ghz1_EMonitor_EMonitor79:
	IFND FINAL
	dc.b "EMonitor79",0,0,0,0,0,0
	ENDIF
	dc.w 0x004F	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_monitor_spritesheet_monitor	; SDSprite_Sheet
	dc.l 0	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_monitor_spritesheet_img_ring	; SDSprite_Sheet
	dc.l actor_monitor_sheet_img_ring_anim_play	; SDSprite_Animation
	dc.b 0x01	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even


SceneEntity_ghz1_SELayerSwitch_LoopSwitch1_Top:
	IFND FINAL
	dc.b "LoopSwitch1_Top",0
	ENDIF
	dc.b 0x00	; EntityBlock_Flags
	dc.b 0x00	; EntityBlock_Priority
	dc.w 0x0000	; EntityBlock_Next
	dc.w SELayerSwitch_Typedesc	; Entity_TypeDesc
	dc.w 0x0040	; Entity_Id
	dc.l LoopSwitch1_Top_64_SpawnData
	dc.l 0x16000000	; Entity_PosX
	dc.l 0x02980000	; Entity_PosY
	dc.w 0x0008, 0x0008	; Entity_Extents

LoopSwitch1_Top_64_SpawnData:
	dc.b 0x1	; SELayerSwitch_LayerA
	dc.b 0x0	; SELayerSwitch_LayerB
	dc.b LAYER_SWITCH_DIRECTION_HORIZONTAL	; SELayerSwitch_Direction
	even
SceneEntity_ghz1_SELayerSwitch_LoopSwitch1_Bottom:
	IFND FINAL
	dc.b "LoopSwitch1_Bot",0
	ENDIF
	dc.b 0x00	; EntityBlock_Flags
	dc.b 0x00	; EntityBlock_Priority
	dc.w 0x0000	; EntityBlock_Next
	dc.w SELayerSwitch_Typedesc	; Entity_TypeDesc
	dc.w 0x0041	; Entity_Id
	dc.l LoopSwitch1_Bottom_65_SpawnData
	dc.l 0x16800000	; Entity_PosX
	dc.l 0x02E00000	; Entity_PosY
	dc.w 0x0008, 0x0060	; Entity_Extents

LoopSwitch1_Bottom_65_SpawnData:
	dc.b 0x1	; SELayerSwitch_LayerA
	dc.b 0x0	; SELayerSwitch_LayerB
	dc.b LAYER_SWITCH_DIRECTION_HORIZONTAL	; SELayerSwitch_Direction
	even

SceneEntityDataStatic_ghz1:
	dc.l SceneEntity_ghz1_SELayerSwitch_LoopSwitch1_Top
	dc.l SceneEntity_ghz1_SELayerSwitch_LoopSwitch1_Bottom

SceneEntityDataDynamic_ghz1:
	dc.l EPlayer_Typedesc
	dc.l SceneEntitySpawnData_ghz1_EPlayer_EPlayer62
	dc.w 0x00CF, 0x042B	; SceneEntity_Pos
	dc.w 0x0014, 0x0014	; SceneEntity_Extents
	dc.l EMotobug_Typedesc
	dc.l SceneEntitySpawnData_ghz1_EMotobug_Motobug1
	dc.w 0x04A4, 0x03F0	; SceneEntity_Pos
	dc.w 0x0014, 0x0010	; SceneEntity_Extents
	dc.l ERing_Typedesc
	dc.l SceneEntitySpawnData_ghz1_ERing_ERing67
	dc.w 0x01C8, 0x03D8	; SceneEntity_Pos
	dc.w 0x0008, 0x0008	; SceneEntity_Extents
	dc.l ERing_Typedesc
	dc.l SceneEntitySpawnData_ghz1_ERing_ERing68
	dc.w 0x01E0, 0x03D8	; SceneEntity_Pos
	dc.w 0x0008, 0x0008	; SceneEntity_Extents
	dc.l ERing_Typedesc
	dc.l SceneEntitySpawnData_ghz1_ERing_ERing69
	dc.w 0x01F8, 0x03D8	; SceneEntity_Pos
	dc.w 0x0008, 0x0008	; SceneEntity_Extents
	dc.l EBuzzbomb_Typedesc
	dc.l SceneEntitySpawnData_ghz1_EBuzzbomb_BuzzBomb1
	dc.w 0x049D, 0x03A4	; SceneEntity_Pos
	dc.w 0x0018, 0x000C	; SceneEntity_Extents
	dc.l EBridge_Typedesc
	dc.l SceneEntitySpawnData_ghz1_EBridge_EBridge75
	dc.w 0x0520, 0x0408	; SceneEntity_Pos
	dc.w 0x0060, 0x0008	; SceneEntity_Extents
	dc.l EBridge_Typedesc
	dc.l SceneEntitySpawnData_ghz1_EBridge_EBridge76
	dc.w 0x0B20, 0x0398	; SceneEntity_Pos
	dc.w 0x0060, 0x0008	; SceneEntity_Extents
	dc.l EBridge_Typedesc
	dc.l SceneEntitySpawnData_ghz1_EBridge_EBridge77
	dc.w 0x2020, 0x0398	; SceneEntity_Pos
	dc.w 0x0060, 0x0008	; SceneEntity_Extents
	dc.l EChopper_Typedesc
	dc.l SceneEntitySpawnData_ghz1_EChopper_EChopper78
	dc.w 0x0528, 0x04D3	; SceneEntity_Pos
	dc.w 0x0010, 0x0010	; SceneEntity_Extents
	dc.l EMonitor_Typedesc
	dc.l SceneEntitySpawnData_ghz1_EMonitor_EMonitor79
	dc.w 0x02C8, 0x03D0	; SceneEntity_Pos
	dc.w 0x0010, 0x0010	; SceneEntity_Extents

SceneStampAnims_ghz1:
	dc.b "ghz_moonflower",0,0
	dc.l actor_ghz_moonflower_spritesheet_ghz_moonflower
	dc.l actor_ghz_moonflower_sheet_ghz_moonflower_anim_raise
	dc.w 0x02D0	; StampAnim_TileIndex
	dc.b "ghz_sunflower",0,0,0
	dc.l actor_ghz_sunflower_spritesheet_ghz_sunflower
	dc.l actor_ghz_sunflower_sheet_ghz_sunflower_anim_rotate
	dc.w 0x02C0	; StampAnim_TileIndex

StreamingMap_ghz1_PlaneA:
	dc.l 0x00000000	; StreamingMap_PlaneAddr
	dc.l 0x00000000	; StreamingMap_VRAMhndl
	dc.l data_tileset_ghz
	dc.l data_stampset_ghz
	dc.l data_map_ghz1
	dc.w 0x02E4	; StreamingMap_NumTiles
	dc.w 0x0040	; StreamingMap_NumStamps
	dc.w 0x0028	; StreamingMap_WidthStamps
	dc.w 0x0006	; StreamingMap_HeightStamps
	dc.w 0x0000	; StreamingMap_StreamPosX
	dc.w 0x0000	; StreamingMap_StreamPosY
	dc.w 0x0000	; StreamingMap_ScrollX
	dc.w 0x0000	; StreamingMap_ScrollY

StreamingMap_ghz1_PlaneB:
	dc.l 0x00000000	; StreamingMap_PlaneAddr
	dc.l 0x00000000	; StreamingMap_VRAMhndl
	dc.l data_tileset_ghz
	dc.l data_stampset_ghz
	dc.l data_map_ghz_bg
	dc.w 0x02E4	; StreamingMap_NumTiles
	dc.w 0x0040	; StreamingMap_NumStamps
	dc.w 0x0007	; StreamingMap_WidthStamps
	dc.w 0x0001	; StreamingMap_HeightStamps
	dc.w 0x0000	; StreamingMap_StreamPosX
	dc.w 0x0000	; StreamingMap_StreamPosY
	dc.w 0x0000	; StreamingMap_ScrollX
	dc.w 0x0000	; StreamingMap_ScrollY

SceneData_ghz1:
	dc.l StreamingMap_ghz1_PlaneA
	dc.l StreamingMap_ghz1_PlaneB
	dc.l data_collision_tileset
	dc.l data_collision_stampset_ghz
	dc.l data_collision_map_ghz1
	dc.l palette_ghz_pal1
	dc.l palette_objs_pal1
	dc.l palette_ghz_pal2
	dc.l palette_objs_pal2
	dc.l SceneEntityDataStatic_ghz1
	dc.l SceneEntityDataDynamic_ghz1
	dc.l SceneStampAnims_ghz1
	dc.w 0x02EA	; SceneData_ColTileCount
	dc.w 0x0027	; SceneData_ColStampCount
	dc.w 0x0028	; SceneData_ColMapWidthStamps
	dc.w 0x0006	; SceneData_ColMapHeightStamps
	dc.w 0x0002	; SceneData_StaticEntityCount
	dc.w 0x000B	; SceneData_DynamicEntityCount
	dc.w 0x0002	; SceneData_StampAnimCount
