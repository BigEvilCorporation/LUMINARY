SceneEntitySpawnData_tst1_EPlayer_player1:
	; ECSprite
	dc.l actor_test_sheet_test_frame_0	; SDSprite_TileData
	dc.w actor_test_sheet_test_frame_0_size_t	; SDSprite_SizeTiles
	dc.b 5	; SDSprite_Layout
	even
SceneEntitySpawnData_tst1_EPlayer_player2:
	; ECSprite
	dc.l actor_test_sheet_test_frame_0	; SDSprite_TileData
	dc.w actor_test_sheet_test_frame_0_size_t	; SDSprite_SizeTiles
	dc.b 5	; SDSprite_Layout
	even

SceneEntityData_tst1:
SceneEntity_tst1_EPlayer_player1:
	dc.l EPlayer_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_EPlayer_player1	; Entity spawn data
	dc.w 0x00A0	; Position X
	dc.w 0x00A5	; Position Y
SceneEntity_tst1_EPlayer_player2:
	dc.l EPlayer_Typedesc	; Entity descriptor
	dc.l SceneEntitySpawnData_tst1_EPlayer_player2	; Entity spawn data
	dc.w 0x00C0	; Position X
	dc.w 0x00C8	; Position Y

SceneData_tst1:
	dc.w 2	; Entity count
	dc.l SceneEntityData_tst1	; Entity table
