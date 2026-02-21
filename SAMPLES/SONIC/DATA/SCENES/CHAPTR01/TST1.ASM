SceneEntitySpawnData_tst1_tst1_EPlayer_ent62:
	; ECSprite
	dc.l actor_sonic_spritesheet_run	; SDSprite_Sheet
	dc.l actor_sonic_sheet_run_anim_run	; SDSprite_Animation
	even
	; ECScript
	dc.l scriptdata_EPlayer	; SDScript_ScriptData
	dc.w 0x0000	; SDScript_FuncStart
	dc.w 0x0008	; SDScript_FuncShutdown
	dc.w 0x0010	; SDScript_FuncUpdate
	even
SceneEntitySpawnData_tst1_tst1_EMotobug_Motobug1:
	; ECSprite
	dc.l actor_motobug_spritesheet_move	; SDSprite_Sheet
	dc.l actor_motobug_sheet_move_anim_move	; SDSprite_Animation
	even
	; ECSprite
	dc.l actor_motobug_spritesheet_exhaust	; SDSprite_Sheet
	dc.l actor_motobug_sheet_exhaust_anim_exhaust	; SDSprite_Animation
	even
SceneEntitySpawnData_tst1_tst1_ERing_ent67:
	; ECSprite
	dc.l actor_ring_spritesheet_idle	; SDSprite_Sheet
	dc.l actor_ring_sheet_idle_anim_idle	; SDSprite_Animation
	even
SceneEntitySpawnData_tst1_tst1_EBuzzbomb_BuzzBomb1:
	; ECSprite
	dc.l actor_buzzbomb_spritesheet_fly	; SDSprite_Sheet
	dc.l 0x0	; SDSprite_Animation
	even
	; ECSprite
	dc.l actor_buzzbomb_spritesheet_wings	; SDSprite_Sheet
	dc.l actor_buzzbomb_sheet_wings_anim_wings	; SDSprite_Animation
	even
	; ECSprite
	dc.l actor_buzzbomb_spritesheet_thruster	; SDSprite_Sheet
	dc.l actor_buzzbomb_sheet_thruster_anim_thruster	; SDSprite_Animation
	even
	; ECSprite
	dc.l actor_buzzbomb_spritesheet_fire	; SDSprite_Sheet
	dc.l actor_buzzbomb_sheet_fire_anim_fire	; SDSprite_Animation
	even
SceneEntitySpawnData_tst1_tst1_EBridge_ent75:
	; ECBridgeRenderer
	dc.l actor_bridge_spritesheet_segment	; SDBridgeRenderer_Sheet
	even
SceneEntitySpawnData_tst1_tst1_EChopper_ent78:
	; ECSprite
	dc.l actor_chopper_spritesheet_chopper	; SDSprite_Sheet
	dc.l actor_chopper_sheet_chopper_anim_chopper	; SDSprite_Animation
	even

SceneEntity_tst1_tst1_SELayerSwitch_LoopSwitch1_Top:
	dc.w 0x0	; EntityBlock_Flags
	dc.w 0x0	; EntityBlock_Next
	dc.w SELayerSwitch_Typedesc	; Entity_TypeDesc
	dc.l 0x16000000	; Entity_PosX
	dc.l 0x02980000	; Entity_PosY
	dc.w 0x0008	; Entity_ExtentsX
	dc.w 0x0008	; Entity_ExtentsY
	dc.b 0x1	; SELayerSwitch_LayerA
	dc.b 0x0	; SELayerSwitch_LayerB
	dc.b LAYER_SWITCH_DIRECTION_HORIZONTAL	; SELayerSwitch_Direction
	even
SceneEntity_tst1_tst1_SELayerSwitch_LoopSwitch1_Bottom:
	dc.w 0x0	; EntityBlock_Flags
	dc.w 0x0	; EntityBlock_Next
	dc.w SELayerSwitch_Typedesc	; Entity_TypeDesc
	dc.l 0x16800000	; Entity_PosX
	dc.l 0x02E00000	; Entity_PosY
	dc.w 0x0008	; Entity_ExtentsX
	dc.w 0x0060	; Entity_ExtentsY
	dc.b 0x1	; SELayerSwitch_LayerA
	dc.b 0x0	; SELayerSwitch_LayerB
	dc.b LAYER_SWITCH_DIRECTION_HORIZONTAL	; SELayerSwitch_Direction
	even
SceneEntity_tst1_tst1_SESpawner_Spn_Motobug1:
	dc.w 0x0	; EntityBlock_Flags
	dc.w 0x0	; EntityBlock_Next
	dc.w SESpawner_Typedesc	; Entity_TypeDesc
	dc.l 0x04500000	; Entity_PosX
	dc.l 0x03B80000	; Entity_PosY
	dc.w 0x0008	; Entity_ExtentsX
	dc.w 0x0008	; Entity_ExtentsY
	dc.l EMotobug_TypeDesc	; SESpawner_EntityDesc
	dc.l Archetype_EMotobug_Motobug1	; SESpawner_SpawnParams
	even

SceneEntityDataStatic_tst1_tst1:
	dc.l SceneEntity_tst1_tst1_SELayerSwitch_LoopSwitch1_Top
	dc.l SceneEntity_tst1_tst1_SELayerSwitch_LoopSwitch1_Bottom
	dc.l SceneEntity_tst1_tst1_SESpawner_Spn_Motobug1

SceneEntityDataDynamic_tst1_tst1:
	dc.w EPlayer_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_EPlayer_ent62	; Entity spawn data
	dc.w 0x00CF	; Position X
	dc.w 0x0424	; Position Y
	dc.w 0x0014	; ExtentsX
	dc.w 0x0014	; ExtentsY
	dc.w EMotobug_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_EMotobug_Motobug1	; Entity spawn data
	dc.w 0x04A4	; Position X
	dc.w 0x03F0	; Position Y
	dc.w 0x0014	; ExtentsX
	dc.w 0x0010	; ExtentsY
	dc.w ERing_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_ERing_ent67	; Entity spawn data
	dc.w 0x01C8	; Position X
	dc.w 0x03D8	; Position Y
	dc.w 0x0008	; ExtentsX
	dc.w 0x0008	; ExtentsY
	dc.w ERing_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_ERing_ent67	; Entity spawn data
	dc.w 0x01E0	; Position X
	dc.w 0x03D8	; Position Y
	dc.w 0x0008	; ExtentsX
	dc.w 0x0008	; ExtentsY
	dc.w ERing_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_ERing_ent67	; Entity spawn data
	dc.w 0x01F8	; Position X
	dc.w 0x03D8	; Position Y
	dc.w 0x0008	; ExtentsX
	dc.w 0x0008	; ExtentsY
	dc.w EBuzzbomb_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_EBuzzbomb_BuzzBomb1	; Entity spawn data
	dc.w 0x049D	; Position X
	dc.w 0x03A4	; Position Y
	dc.w 0x0018	; ExtentsX
	dc.w 0x000C	; ExtentsY
	dc.w EBridge_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_EBridge_ent75	; Entity spawn data
	dc.w 0x0520	; Position X
	dc.w 0x0408	; Position Y
	dc.w 0x0060	; ExtentsX
	dc.w 0x0008	; ExtentsY
	dc.w EBridge_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_EBridge_ent75	; Entity spawn data
	dc.w 0x0B20	; Position X
	dc.w 0x0398	; Position Y
	dc.w 0x0060	; ExtentsX
	dc.w 0x0008	; ExtentsY
	dc.w EBridge_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_EBridge_ent75	; Entity spawn data
	dc.w 0x2020	; Position X
	dc.w 0x0398	; Position Y
	dc.w 0x0060	; ExtentsX
	dc.w 0x0008	; ExtentsY
	dc.w EChopper_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_EChopper_ent78	; Entity spawn data
	dc.w 0x0528	; Position X
	dc.w 0x04D3	; Position Y
	dc.w 0x0010	; ExtentsX
	dc.w 0x0010	; ExtentsY

SceneData_tst1_tst1:
	dc.l tileset_tst1	; SceneData_GfxTileset
	dc.l stampset_tst1	; SceneData_GfxStampset
	dc.l map_tst1_tst1	; SceneData_GfxMapFg
	dc.l map_tst1_bg	; SceneData_GfxMapBg
	dc.l collision_tileset_tst1	; SceneData_ColTileset
	dc.l collision_stampset_tst1	; SceneData_ColStampset
	dc.l collision_map_tst1_tst1	; SceneData_ColMap
	dc.l palettes_tst1	; SceneData_Palettes
	dc.l SceneEntityDataStatic_tst1_tst1	; SceneData_StaticEntities
	dc.l SceneEntityDataDynamic_tst1_tst1	; SceneData_DynamicEntities
	dc.w 966	; SceneData_GfxTileCount
	dc.w 63	; SceneData_GfxStampCount
	dc.w 40	; SceneData_GfxMapFgWidthStamps
	dc.w 6	; SceneData_GfxMapFgHeightStamps
	dc.w 6	; SceneData_GfxMapBgWidthStamps
	dc.w 1	; SceneData_GfxMapBgHeightStamps
	dc.w 746	; SceneData_ColTileCount
	dc.w 38	; SceneData_ColStampCount
	dc.w 40	; SceneData_ColMapWidthStamps
	dc.w 6	; SceneData_ColMapHeightStamps
	dc.w 2	; SceneData_PaletteCount
	dc.w 3	; SceneData_StaticEntityCount
	dc.w 10	; SceneData_DynamicEntityCount
