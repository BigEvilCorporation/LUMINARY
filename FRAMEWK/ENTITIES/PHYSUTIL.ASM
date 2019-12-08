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
    ;  d7.w Position Y (object space)
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
    addi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d7    ; Y back to object space - step height
    sub.w  Entity_ExtentsY(a4), d7      ; Probe offset back to centre

    @EndTerrain:

    rts

PHYS_EntityFindPlatform:
    ; ======================================
    ; Searches for platforms downwards,
    ; returns platform height and velocity.
    ; ======================================
    ; In:
    ;  a0   Entity
    ; Out:
    ;  a3   Found ECPlatform component
    ;  d0.w Platform height (or -1)
    ; ======================================

    ; Probe position
    move.w Entity_PosX(a0), d3          ; Get entity position
    move.w Entity_PosY(a0), d4
    subi.w #PHYS_STEP_HEIGHT, d4        ; - step height
    add.w  Entity_ExtentsY(a0), d4      ; Centre to Y probe offset

    ; Search all platforms
    move.w #-1, d0

    ; TODO: Only platforms in active world grid
    ENT_COMPONENT_GET_LIST_HEAD ECPlatform, a3
    cmp.w  #0x0, a3
    beq    @NoPlatforms

    @PlatformLp:
    movea.w Component_Owner(a3), a4     ; Get owning entity
    move.w Entity_PosX(a4), d1          ; Check probe X > platform X
    move.w d1, d5
    sub.w  Entity_ExtentsX(a4), d1
    cmp.w  d3, d1
    bgt    @NextPlatform
    add.w  Entity_ExtentsX(a4), d5      ; Check probe X < platform X+width
    cmp.w  d3, d5
    blt    @NextPlatform

    move.w Entity_PosY(a4), d0          ; Check platform Y > probe Y
    sub.w  Entity_ExtentsY(a4), d0      ; Platform top
    cmp.w  d4, d0
    blt    @NextPlatform
    addi.w #COLLISION_MAX_TERRAIN_SEARCH_TILES*8, d4 ; Check platform Y < probe Y + search height
    cmp.w  d4, d0
    ble    @Found

    @NextPlatform:
    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @PlatformLp

    @NoPlatforms:

    ; Not found
    move.l #0x0, a3
    move.w #-1, d0

    rts

    @Found:
    sub.w  Entity_ExtentsY(a0), d0      ; Probe offset back to centre

    @EndPlatforms:

    rts
