Archetype_EMotobug_Motobug1:
	IFND FINAL
	dc.b "Motobug1",0,0,0,0,0,0,0,0
	ENDIF
	dc.w 0x0000	; EntitySpawnData_Id
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_motobug_spritesheet_move	; SDSprite_Sheet
	dc.l actor_motobug_sheet_move_anim_move	; SDSprite_Animation
	dc.b 0x00	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECSprite
	dc.l 0	; SDSprite_Actor
	dc.l actor_motobug_spritesheet_exhaust	; SDSprite_Sheet
	dc.l actor_motobug_sheet_exhaust_anim_exhaust	; SDSprite_Animation
	dc.b 0x00	; SDSprite_PaletteSlotIdx
	dc.b 0	; SDSprite_DrawPriority
	dc.b 0	; SDSprite_StateFlags
	even
	; ECScript
	dc.l data_script_EMotobug	; SDScript_ScriptData
	dc.w 0x0000	; SDScript_FuncStart
	dc.w 0x0008	; SDScript_FuncShutdown
	dc.w 0x0010	; SDScript_FuncUpdate
	even

Archetype_EBridge_Bridge_GHZ:
	IFND FINAL
	dc.b "Bridge_GHZ",0,0,0,0,0,0
	ENDIF
	dc.w 0x0000	; EntitySpawnData_Id
	; ECBridgeRenderer
	dc.l 0	; SDBridgeRenderer_Actor
	dc.l actor_bridge_spritesheet_segment	; SDBridgeRenderer_Sheet
	even

