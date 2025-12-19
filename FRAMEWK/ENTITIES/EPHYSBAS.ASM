; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; EPHYSBAS.ASM - Basic physics body component
; ============================================================================================
; - Single terrain probe, downwards only
; - Horizontal wall probes
; - Single collision layer
; - Basic accel and decel
; - No ground speed behaviour
; - No terrain angle detection
; - No slope correction
; ============================================================================================

ECPHYSBODY_FLAG_BIT_GRAVITY     equ 0x0
ECPHYSBODY_FLAG_BIT_COL_FLOOR   equ 0x1
ECPHYSBODY_FLAG_BIT_COL_WALL    equ 0x2

    COMPONENT_SPAWN_DATA_BEGIN ECPhysBodyBasic
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECPhysBodyBasic
ECPhysBodyBasic_VelX                      rs.l 1
ECPhysBodyBasic_VelY                      rs.l 1
ECPhysBodyBasic_MaxVelX                   rs.l 1
ECPhysBodyBasic_AccelX                    rs.w 1
ECPhysBodyBasic_AccelY                    rs.w 1
ECPhysBodyBasic_DecelX                    rs.w 1
ECPhysBodyBasic_LastTerrainFlags          rs.w 1
ECPhysBodyBasic_Flags                     rs.b 1
    ENTITY_COMPONENT_END

ECPhysBodyBasic_Initialise:
    ; ======================================
    ; ECPhysBodyBasic constructor
    ; ======================================
	; a0   Component
    ; a1   Component spawn data
    ; ======================================

    move.l #0x0, ECPhysBodyBasic_VelX(a0)
    move.l #0x0, ECPhysBodyBasic_VelY(a0)
    move.l #PHYS_DEFAULT_MAX_VEL_X, ECPhysBodyBasic_MaxVelX(a0)
    move.w #0x0, ECPhysBodyBasic_AccelX(a0)
    move.w #0x0, ECPhysBodyBasic_AccelY(a0)
    move.w #0x0, ECPhysBodyBasic_LastTerrainFlags(a0)

    ; Default flags
    move.b #0x0, ECPhysBodyBasic_Flags(a0)
    bset   #ECPHYSBODY_FLAG_BIT_GRAVITY, ECPhysBodyBasic_Flags(a0)
    bset   #ECPHYSBODY_FLAG_BIT_COL_FLOOR, ECPhysBodyBasic_Flags(a0)
    bset   #ECPHYSBODY_FLAG_BIT_COL_WALL, ECPhysBodyBasic_Flags(a0)

    rts

ECPhysBodyBasic_Shutdown:
    ; ======================================
    ; ECPhysBodyBasic destructor
    ; ======================================
	; a0   Component
    ; ======================================

    rts

ECPhysBodyBasic_StepAll:
    ; ======================================
    ; Steps all basic physics bodies and
    ; handles collisions
    ; ======================================
	; No params
    ; ======================================

    ENT_COMPONENT_GET_LIST_HEAD ECPhysBodyBasic, a3
    cmp.w  #0x0, a3
    beq    @NoBodies

    move.l RAM_SCENE_DATA, a5           ; Get physics world
    move.l SceneData_ColMap(a5), a0
    move.l SceneData_ColStampset(a5), a1
    move.l SceneData_ColTileset(a5), a2
    move.w SceneData_ColMapWidthStamps(a5), d7

    @BodyLp:
    movea.w Component_Owner(a3), a4     ; Get owning entity

    ; ======================================
    ; Get input
    ; ======================================
    move.l Entity_PosX(a4), d0          ; Get pos
    move.l Entity_PosY(a4), d1

    move.l ECPhysBodyBasic_VelX(a3), d2   ; Get vel
    move.l ECPhysBodyBasic_VelY(a3), d3

    move.w ECPhysBodyBasic_AccelX(a3), d4 ; Get accel
    move.w ECPhysBodyBasic_AccelY(a3), d5
    ext.l  d4
    ext.l  d5
    
    PUSH.L a4                           ; Backup entity

    ; ======================================
    ; Step
    ; ======================================
    btst   #ECPHYSBODY_FLAG_BIT_GRAVITY, ECPhysBodyBasic_Flags(a3)
    beq    @NoGravity
    addi.l #PHYS_GRAVITY_Y, d5          ; Apply gravity to Y accel
    @NoGravity:

    tst.l  d4
    bne    @Accelerate

    ; Deceleration
    @Decelerate:
    move.w ECPhysBodyBasic_DecelX(a3), d6 ; Apply X decel to X velocity
    ext.l  d6
    tst.l  d4                           ; Reverse sign if vel < 0
    beq    @DecelDone
    bge    @PositiveVel
    add.l  d6, d4
    bgt    @FullStop
    bra    @DecelDone
    @PositiveVel:
    sub.l  d6, d4
    bgt    @NotFullStop
    @FullStop:
    moveq  #0x0, d4                     ; Fully decelerated, stop
    @NotFullStop:
    @DecelDone:

    @Accelerate:

    add.l  d4, d2                       ; Apply accel to vel
    add.l  d5, d3

    ; Clamp X velocity
    move.l ECPhysBodyBasic_MaxVelX(a3), d4
    move.l d4, d5
    neg.l  d5
    CLAMP.L d2,d5,d4

    move.l d2, a5                       ; Backup vel
    move.l d3, a6

    @VelLp:

    move.l d2, d6                       ; If vel is zero, skip terrain detection
    or.l   d3, d6
    beq    @ZeroVel

    PUSH.W d7                           ; Backup map width

    ; Apply velocity in tile*2 steps
    move.l d2, d4                       ; Clamp X/Y vel to tile width/height
    move.l d3, d5
    CLAMP.L d4, #-((COLLISION_TILE_WIDTH*2)<<16), #((COLLISION_TILE_WIDTH*2)<<16)
    CLAMP.L d5, #-((COLLISION_TILE_HEIGHT*2)<<16), #((COLLISION_TILE_HEIGHT*2)<<16)

    sub.l  d4, d2                       ; Subtract from total vel
    sub.l  d5, d3

    add.l  d4, d0                       ; Apply vel to pos
    add.l  d5, d1
    
    ; Clear last terrain flags
    move.w #0x0, ECPhysBodyBasic_LastTerrainFlags(a3)

    ; Search down for floor
    btst   #ECPHYSBODY_FLAG_BIT_COL_FLOOR, ECPhysBodyBasic_Flags(a3)
    beq    @NoFloorCollision
    bsr    ECPhysBodyBasic_TerrainSearch_Down
    @NoFloorCollision:

    ; Search horizontally for walls
    btst   #ECPHYSBODY_FLAG_BIT_COL_WALL, ECPhysBodyBasic_Flags(a3)
    beq    @NoWallCollision
    jsr    ECPhysBodyBasic_WallSearch
    @NoWallCollision:

    POP.W  d7                           ; Restore map width

    bra    @VelLp                       ; Next velocity step

    ; ======================================
    ; Store output
    ; ======================================

    @ZeroVel:
    
    POP.L  a4                           ; Restore entity

    move.l d0, Entity_PosX(a4)          ; Store pos
    move.l d1, Entity_PosY(a4)

    move.l a5, ECPhysBodyBasic_VelX(a3) ; Store vel
    move.l a6, ECPhysBodyBasic_VelY(a3)

    ; ======================================

    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @BodyLp

    @NoBodies:

    rts

ECPhysBodyBasic_WallSearch:
    ; ======================================
    ; Searches for solid walls horizontally.
    ; Corrects object X position, returns
    ; collision flags.
    ; ======================================
    ; In:
    ;  a0   Terrain stamp map data
	;  a1   Terrain stampset data
    ;  a2   Terrain tileset data
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d5.w Prev terrain flags
    ;  d7.w Map width (stamps)
    ;  a4   Entity
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; Out:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d3.l Collision flags
    ;  a5.l X velocity
    ;  a6.l Y velocity
    ; ======================================

    PUSHM.L d2/d6-d7

    move.w d7, d2                       ; Map width (stamps)

    ; Get probe position
    PUSHM.L d0-d5/a0-a6
    swap   d0                                       ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X, d0                 ; X to map space
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d1; Y to map space - step height
    add.w  Entity_ExtentsY(a4), d1                  ; Centre to probe Y offset
    move.l #1<<COLLISION_TEST_BIT_SOLID_L, d5
    move.b #0x0, d5       							; Terrain layer 0
    
    ; Probe for collision
    cmp.l  #0x0, a5
    ble    @SearchLeft
    add.w  Entity_ExtentsX(a4), d0      ; Centre to probe X offset
    bsr    COL_ProbeTerrainRight        ; Probe terrain map (search right)
    bra    @SearchRight
    @SearchLeft:
    sub.w  Entity_ExtentsX(a4), d0      ; Centre to probe X offset
    bsr    COL_ProbeTerrainLeft         ; Probe terrain map (search left)
    @SearchRight:
    
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    btst   #COLLISION_FLAG_BIT_SOLID_W, d6 ; Check if hit wall
    beq    @EndWall
    addi.w #VDP_SPRITE_BORDER_X, d7     ; X back to sprite space
    cmp.l  #0x0, a5
    ble    @ProbeLeft
    sub.w  Entity_ExtentsX(a4), d7      ; Probe offset back to centre
    bra    @ProbeRight
    @ProbeLeft:
    add.w  Entity_ExtentsX(a4), d7      ; Probe offset back to centre
    @ProbeRight:
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    cmp.l  d7, d0                       ; Check if penetrating wall
    ble    @EndWall
    move.l d7, d0                       ; Hit wall, cap X and zero velocity
    move.l #0x0, d2                     ; Zero X velocity
    move.l #0x0, a5                     ; Zero X velocity (mirror)
    bclr   #COLLISION_FLAG_BIT_TERRAIN_W, d6      ; Don't treat this as terrain
    lsr.w  #0x8, d6                               ; Leave angle unchanged
    or.b   d6, ECPhysBodyBasic_LastTerrainFlags(a3) ; Store flags (leave angle unchanged)

    @EndWall:

    POPM.L  d2/d6-d7

    rts

ECPhysBodyBasic_TerrainSearch_Down:
    ; ======================================
    ; Searches for terrain downwards.
    ; Corrects object Y, returns
    ; collision flags and terrain height
    ; ======================================
    ; In:
    ;  a0   Terrain stamp map data
	;  a1   Terrain stampset data
    ;  a2   Terrain tileset data
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d5.w Prev terrain flags
    ;  d7.w Map width (stamps)
    ;  a4   Entity
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; Out:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d6-d7

    move.w d7, d2                       ; Map width (stamps)

    ; Probe position
    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X, d0                     ; X to map space
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d1    ; Y to map space - step height
    add.w  Entity_ExtentsY(a4), d1                      ; Centre to Y probe offset

    ; Probe for floor
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b #0x0, d5						; Terrain layer 0
    bsr    COL_ProbeTerrainDown         ; Probe terrain map (search downwards)
    move.w d3, d6                       ; Backup tile flags
    POPM.L d0-d5/a0-a6

    cmp.w  #-1, d7                      ; d7 = terrain height, or -1
    beq    @EndTerrain
    addi.w #VDP_SPRITE_BORDER_Y, d7     ; Y back to sprite space
    sub.w  Entity_ExtentsY(a4), d7      ; Probe offset back to centre
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    cmp.l  d7, d1                       ; Check if on or under floor
    blt    @EndTerrain
    subi.w #PHYS_STEP_HEIGHT, d1        ; - step height
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
    move.l #0x0, d3                     ; Zero Y velocity
    move.l #0x0, a6                     ; Zero Y velocity (mirror)
    move.w d6, ECPhysBodyBasic_LastTerrainFlags(a3)   ; Store flags

    @EndTerrain:

    POPM.L  d2/d6-d7

    rts
