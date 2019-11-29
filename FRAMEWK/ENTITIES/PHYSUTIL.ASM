; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 29th Novebmer 2019
; ============================================================================================
; PHYSUTIL.ASM - Physics utilities - terrain queries, collisiom solving
; ============================================================================================

PHYS_EntityFindFloor:
    ; ======================================
    ; Searches for terrain downwards,
    ; returns terrain height and flags.
    ; Terrain layer 0 only.
    ; ======================================
    ; In:
    ;  a0   Terrain stamp map data
	;  a1   Terrain stampset data
    ;  a2   Terrain tileset data
    ;  a3   Entity
    ;  d2.w Map width (stamps)
    ; Out:
    ;  d3.w Terrain flags + angle
    ;  d7.w Position Y (map space)
    ; ======================================

    ; Probe position
    move.w Entity_PosX(a3), d0                          ; Get entity position
    move.w Entity_PosY(a3), d1
    subi.w #VDP_SPRITE_BORDER_X, d0                     ; X to map space
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d1    ; Y to map space - step height
    add.w  Entity_ExtentsY(a3), d1                      ; Centre to Y probe offset

    ; Probe for floor
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b #0x0, d5						; Terrain layer 0
    move.l a3, a4
    bsr    COL_ProbeTerrainDown         ; Probe terrain map (search downwards)

    cmp.w  #-1, d7                      ; d7 = terrain height, or -1
    beq    @EndTerrain
    addi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d7    ; Y back to sprite space - step height
    sub.w  Entity_ExtentsY(a4), d7      ; Probe offset back to centre

    @EndTerrain:

    rts
