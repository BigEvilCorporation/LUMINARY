SceneEntitySpawnData_tst1_tst1_EPlayer_ent62:
	; ECSprite
	dc.l actor_test2_spritesheet_test2	; SDSprite_Sheet
	dc.l 0x0	; SDSprite_Animation
	even

SceneEntityData_tst1_tst1:
	dc.l EPlayer_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_tst1_EPlayer_ent62	; Entity spawn data
	dc.w 0x0088	; Position X
	dc.w 0x0098	; Position Y

SceneData_tst1_tst1:
	dc.l tileset_tst1	; SceneData_GfxTileset
	dc.l stampset_tst1	; SceneData_GfxStampset
	dc.l map_tst1_tst1	; SceneData_GfxMap
	dc.l collision_tileset_tst1	; SceneData_ColTileset
	dc.l collision_stampset_tst1	; SceneData_ColStampset
	dc.l collision_map_tst1_tst1	; SceneData_ColMap
	dc.l palettes_tst1	; SceneData_Palettes
	dc.l SceneEntityData_tst1_tst1	; SceneData_Entities
	dc.w 678	; SceneData_GfxTileCount
	dc.w 57	; SceneData_GfxStampCount
	dc.w 8	; SceneData_GfxMapWidthStamps
	dc.w 4	; SceneData_GfxMapHeightStamps
	dc.w 117	; SceneData_ColTileCount
	dc.w 0	; SceneData_ColStampCount
	dc.w 8	; SceneData_ColMapWidthStamps
	dc.w 4	; SceneData_ColMapHeightStamps
	dc.w 1	; SceneData_PaletteCount
	dc.w 1	; SceneData_EntityCount
