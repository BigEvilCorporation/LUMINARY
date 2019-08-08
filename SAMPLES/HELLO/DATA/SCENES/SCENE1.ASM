SceneEntitySpawnData_tst1_EPlayer_ent1:
	dc.w 0x1	; SDPlayer_SomeVariable
	; ECSprite
	dc.l TestSprite	; SDSprite_TileData
	dc.w 1	; SDSprite_SizeTiles
	dc.b VDP_SPRITE_LAYOUT_1x1	; SDSprite_Layout
	even
SceneEntitySpawnData_tst1_EPlayer_ent2:
	dc.w 0x0	; SDPlayer_SomeVariable
	; ECSprite
	dc.l TestSprite	; SDSprite_TileData
	dc.w 1	; SDSprite_SizeTiles
	dc.b VDP_SPRITE_LAYOUT_1x1	; SDSprite_Layout
	even

SceneEntityData_tst1:
SceneEntity_tst1_EPlayer_ent1:
	dc.l EPlayer_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_EPlayer_ent1	; Entity spawn data
	dc.w 0x00A0	; Position X
	dc.w 0x00A5	; Position Y
SceneEntity_tst1_EPlayer_ent2:
	dc.l EPlayer_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_EPlayer_ent2	; Entity spawn data
	dc.w 0x00C0	; Position X
	dc.w 0x00C8	; Position Y

SceneData_tst1:
	dc.w 2	; Entity count
	dc.l SceneEntityData_tst1	; Entity table
