; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; EPHYSCHR.ASM - Physics body character component
; ============================================================================================
; - Dual terrain probes in all 4 directions
; - Horizontal wall probes
; - Multiple collision layers
; - Ground speed based movement
; - Terrain angle detection
; - Slope correction and slope landing force
; ============================================================================================

COL_PROBE_DBG equ 0

    
COL_PROBE_DBG_DRAW: macro y_pos
	IF COL_PROBE_DBG
    ;DBG_DRAW_WORD_S #8,\y_pos,d0
    ;DBG_DRAW_WORD_S #13,\y_pos,d1
    addi.w #VDP_SPRITE_BORDER_X, d0
    addi.w #VDP_SPRITE_BORDER_Y, d1
    bsr    DBG_DrawLocator
    subi.w #VDP_SPRITE_BORDER_X, d0
    subi.w #VDP_SPRITE_BORDER_Y, d1
    ENDIF
    endm

    COMPONENT_SPAWN_DATA_BEGIN ECPhysBodyChar
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECPhysBodyChar
ECPhysBodyChar_VelX                      rs.l 1 ; X velocity (16.16)
ECPhysBodyChar_VelY                      rs.l 1 ; Y velocity (16.16)
ECPhysBodyChar_MaxVelX                   rs.l 1 ; Max ground speed or X vel (16.16)
ECPhysBodyChar_GroundSpeed               rs.w 1 ; Current speed if on ground
ECPhysBodyChar_AccelX                    rs.w 1 ; X acceleration
ECPhysBodyChar_AccelY                    rs.w 1 ; Y acceleration
ECPhysBodyChar_DecelX                    rs.w 1 ; X deceleration if X acceleration == 0
ECPhysBodyChar_SlopeFact                 rs.w 1 ; Multiplyer to reduce speed on slope
ECPhysBodyChar_LastTerrainFlags          rs.w 1 ; Flags and angle
ECPhysBodyChar_TerrainQuadrant           rs.b 1 ; PHYS_TERRAIN_SEARCH_QUADRANT_*
ECPhysBodyChar_TerrainLayer              rs.b 1 ; Current terrain layer idx
    ENTITY_COMPONENT_END

    ; ---------------------------------------------------------------------
    ; Angle     | Decimal   | >>5       | Enum
    ; ----------|-----------|-----------|----------------------------------
    ; 360 - 316 |   0 -  31 | 000 - 000 | PHYS_TERRAIN_SEARCH_QUADRANT_DOWN
    ; 315 - 225 |  32 -  95 | 001 - 010 | PHYS_TERRAIN_SEARCH_QUADRANT_LEFT
    ; 224 - 136 |  96 - 159 | 011 - 100 | PHYS_TERRAIN_SEARCH_QUADRANT_UP
    ; 135 -  45 | 160 - 223 | 101 - 110 | PHYS_TERRAIN_SEARCH_QUADRANT_RIGHT
    ;  44 -   0 | 224 - 255 | 111 - 111 | PHYS_TERRAIN_SEARCH_QUADRANT_DOWN
    ; ---------------------------------------------------------------------
AngToQuadTable:
    dc.b PHYS_TERRAIN_SEARCH_QUADRANT_DOWN  ; 000 = 0
    dc.b PHYS_TERRAIN_SEARCH_QUADRANT_LEFT  ; 001 = 1
    dc.b PHYS_TERRAIN_SEARCH_QUADRANT_LEFT  ; 010 = 2
    dc.b PHYS_TERRAIN_SEARCH_QUADRANT_UP    ; 011 = 3
    dc.b PHYS_TERRAIN_SEARCH_QUADRANT_UP    ; 100 = 4
    dc.b PHYS_TERRAIN_SEARCH_QUADRANT_RIGHT ; 101 = 5
    dc.b PHYS_TERRAIN_SEARCH_QUADRANT_RIGHT ; 110 = 6
    dc.b PHYS_TERRAIN_SEARCH_QUADRANT_DOWN  ; 111 = 7

ANG_TO_QUAD: macro angle,tmpreg
    lea    AngToQuadTable, \tmpreg
    lsr.b  #0x5, \angle           ; Angle>>5 == quadrant table index
    andi.w #0x7, \angle
    adda.w \angle, \tmpreg
    move.b (\tmpreg), \angle
    endm

    ; Quadrant search routines
QuadrantSearchTable:
    dc.l ECPhysBodyChar_TerrainSearch_Down      ; PHYS_TERRAIN_SEARCH_QUADRANT_DOWN
    dc.l ECPhysBodyChar_TerrainSearch_Left      ; PHYS_TERRAIN_SEARCH_QUADRANT_LEFT
    dc.l ECPhysBodyChar_TerrainSearch_Up        ; PHYS_TERRAIN_SEARCH_QUADRANT_UP
    dc.l ECPhysBodyChar_TerrainSearch_Right     ; PHYS_TERRAIN_SEARCH_QUADRANT_RIGHT
    
    ; Quadrants to search if moving down
QuadrantSearchTableDown:
    dc.l ECPhysBodyChar_TerrainSearch_Down
    dc.l ECPhysBodyChar_TerrainSearch_Left
    dc.l ECPhysBodyChar_TerrainSearch_Right

	; Quadrants to search if moving up
QuadrantSearchTableUp:
    dc.l ECPhysBodyChar_TerrainSearch_Up
    dc.l ECPhysBodyChar_TerrainSearch_Left
    dc.l ECPhysBodyChar_TerrainSearch_Right

	; Quadrants to search if moving left
QuadrantSearchTableLeft:
    dc.l ECPhysBodyChar_TerrainSearch_Left
    dc.l ECPhysBodyChar_TerrainSearch_Down
    dc.l ECPhysBodyChar_TerrainSearch_Up

	; Quadrants to search if moving right
QuadrantSearchTableRight:
    dc.l ECPhysBodyChar_TerrainSearch_Right
    dc.l ECPhysBodyChar_TerrainSearch_Down
    dc.l ECPhysBodyChar_TerrainSearch_Up

ECPhysBodyChar_Initialise:
    ; ======================================
    ; ECPhysBodyChar constructor
    ; ======================================
	; a0   Component
    ; a1   Component spawn data
    ; ======================================

    move.l #0x0, ECPhysBodyChar_VelX(a0)
    move.l #0x0, ECPhysBodyChar_VelY(a0)
    move.l #PHYS_DEFAULT_MAX_VEL_X, ECPhysBodyChar_MaxVelX(a0)
    move.w #0x0, ECPhysBodyChar_GroundSpeed(a0)
    move.w #0x0, ECPhysBodyChar_AccelX(a0)
    move.w #0x0, ECPhysBodyChar_AccelY(a0)
    move.w #0x0, ECPhysBodyChar_LastTerrainFlags(a0)
    move.w #PHYS_DEFAULT_SLOPE_FACTOR, ECPhysBodyChar_SlopeFact(a0)
    move.b #PHYS_TERRAIN_SEARCH_QUADRANT_DOWN, ECPhysBodyChar_TerrainQuadrant(a0)
    move.b #0x0, ECPhysBodyChar_TerrainLayer(a0)

    rts

ECPhysBodyChar_Shutdown:
    ; ======================================
    ; ECPhysBodyChar destructor
    ; ======================================
	; a0   Component
    ; ======================================

    rts

ECPhysBodyChar_StepAll:
    ; ======================================
    ; Steps all character physics bodies and
    ; handles collisions, terrain angles,
    ; and slope correction
    ; ======================================
	; No params
    ; ======================================

    ENT_COMPONENT_GET_LIST_HEAD ECPhysBodyChar, a3
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

    move.l ECPhysBodyChar_VelX(a3), d2   ; Get vel
    move.l ECPhysBodyChar_VelY(a3), d3

    move.w ECPhysBodyChar_AccelX(a3), d4 ; Get accel
    move.w ECPhysBodyChar_AccelY(a3), d5
    ext.l  d4
    ext.l  d5
    
    PUSH.L a4                           ; Backup entity

    ; ======================================
    ; Step
    ; ======================================                  
    addi.l #PHYS_GRAVITY_Y, d5          ; Apply gravity to Y accel

    ; If on floor, move using ground speed
    move.w ECPhysBodyChar_LastTerrainFlags(a3), d6	; Get flags and angle
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6		; Check on terrain
    beq    @InAir

    moveq  #0x0, d5
    move.w ECPhysBodyChar_GroundSpeed(a3), d5		; Get ground speed
    ext.l  d5
    tst.l  d4
    beq    @Decelerate
    asr.l  #0x8, d4                                 ; X accel to ground speed range (16.16 >> 8)
    add.l  d4, d5                       			; Apply X accel to ground speed
    bra    @Accelerate

    ; Deceleration
    @Decelerate:
    move.w ECPhysBodyChar_DecelX(a3), d4            ; Apply X decel to ground speed
    asr.w  #0x8, d4                                 ; X decel to ground speed range
    ext.l  d4
    tst.l  d5                                       ; Reverse sign if vel < 0
    beq    @DecelDone
    bge    @PositiveVel
    add.l  d4, d5
    bgt    @FullStop
    bra    @DecelDone
    @PositiveVel:
    sub.l  d4, d5
    bgt    @NotFullStop
    @FullStop:
    moveq  #0x0, d5                                 ; Fully decelerated, stop
    @NotFullStop:
    @DecelDone:

    @Accelerate:
    
    PUSH.L d7
    move.l ECPhysBodyChar_MaxVelX(a3), d4	        ; Clamp ground speed to max
    asr.l  #0x8, d4                                 ; Max X vel to ground speed range (16.16 >> 8)
    move.w d4, d7
    neg.w  d7
    CLAMP.W d5,d7,d4
    POP.L  d7

    ; Convert X ground speed to x/y vel using sin/cos of angle
    move.l d5, d2						; x vel
    move.l d5, d3						; y vel
    andi.w #0xFF, d6					; Extract angle from flags
    add.w  d6, d6

    PUSH.L a4
    lea    sinetable, a4                ; Y vel = ground speed * sine(angle)
    moveq  #0x0, d4
    move.w (a4,d6.w), d4
    muls.w d4, d3

    cmp.w  #PHYS_SLOPE_MIN*2, d6
    blt    @NoSlope
    cmp.w  #(0xFF-PHYS_SLOPE_MIN)*2, d6
    bgt    @NoSlope
    muls.w ECPhysBodyChar_SlopeFact(a3), d4 ; Adjust ground speed by sine(angle)*slope factor
    asr.w  #0x8, d4
    add.w  d4, d5
    @NoSlope:
            
    addi.w #SINE_TBL_COS_OFFS, d6		; X vel = ground speed * cos(angle)
    moveq  #0x0, d4
    move.w (a4,d6.w), d4
    muls.w d4, d2
    POP.L  a4

    move.w d5, ECPhysBodyChar_GroundSpeed(a3) ; Store updated ground speed

    bra    @EndGroundSpeed

    @InAir:
    
    ; Regular accel/velocity not using terrain angles
    add.l  d4, d2                       ; Apply accel to vel
    add.l  d5, d3

    ; Clamp X velocity
    moveq  #0x0, d4
    move.w ECPhysBodyChar_MaxVelX(a3), d4
    INT_TO_FIXED16 d4
    move.l d4, d5
    neg.l  d5
    CLAMP.L d2,d5,d4

    @EndGroundSpeed:
    
    move.l d2, a5                       ; Backup vel
    move.l d3, a6

    @VelLp:

    move.l d2, d6                       ; If vel is zero, skip terrain detection
    or.l   d3, d6
    beq    @ZeroVel

    PUSH.W d7                           ; Backup map width

    ; Apply velocity in COLLISION_MAX_TERRAIN_SEARCH_TILES steps
    move.l d2, d4                       ; Clamp X/Y vel to tile width/height
    move.l d3, d5
    CLAMP.L d4, #-((COLLISION_MAX_TERRAIN_SEARCH_TILES*COLLISION_TILE_WIDTH)<<16), #((COLLISION_MAX_TERRAIN_SEARCH_TILES*COLLISION_TILE_WIDTH)<<16)
    CLAMP.L d5, #-((COLLISION_MAX_TERRAIN_SEARCH_TILES*COLLISION_TILE_HEIGHT)<<16), #((COLLISION_MAX_TERRAIN_SEARCH_TILES*COLLISION_TILE_HEIGHT)<<16)

    sub.l  d4, d2                       ; Subtract from total vel
    sub.l  d5, d3

    add.l  d4, d0                       ; Apply vel to pos
    add.l  d5, d1
    
    ; Backup and clear last terrain flags
    move.w ECPhysBodyChar_LastTerrainFlags(a3), d6
    move.w #0x0, ECPhysBodyChar_LastTerrainFlags(a3)
    PUSHM.W d5/d6

    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6		; Check on terrain
    beq    @CheckTerrainInAir
    
    ; On ground - check the last found quadrant again
    move.w Entity_ExtentsX(a4), d4
    move.w Entity_ExtentsY(a4), d5
    
    lea    QuadrantSearchTable, a4
    moveq  #0x0, d6
    move.b ECPhysBodyChar_TerrainQuadrant(a3), d6
    lsl.w  #0x2, d6
    adda.w d6, a4
    move.l (a4), a4
    jsr    (a4)
    bra    @EndTerrain
    
    @CheckTerrainInAir:
    
    ; In air - check up to three quadrants depending on current direction
    PUSH.L  a5
    move.l  a4, a5
    
    PUSHM.L d6-d7
    
    ; Determine dominant axis
    move.l d4, d6
    move.l d5, d7
    ABS.L  d6
    ABS.L  d7
    cmp.l  d6, d7
    bgt    @AxisY
    
    ; Determine dominant direction on X axis
    tst.l  d4
    bge    @Right
    lea    QuadrantSearchTableLeft, a4
    bra    @EndQuadrant
    @Right:
    lea    QuadrantSearchTableRight, a4
    bra    @EndQuadrant

	; Determine dominant direction on Y axis    
    @AxisY:
    tst.l  d5
    bge    @Down
    lea    QuadrantSearchTableUp, a4
    bra    @EndQuadrant
    @Down:
    lea    QuadrantSearchTableDown, a4

    @EndQuadrant:
    
    POPM.L d6-d7
    
    ; Get extents for terrain search
    move.w Entity_ExtentsX(a5), d4
    move.w Entity_ExtentsY(a5), d5
    
    POP.L  a5

	; Search up to three directions until terrain found
    moveq  #3-1, d6
    @QuadrantLp:
    PUSHM.L a4/d6
    move.l (a4), a4
    jsr    (a4)
    POPM.L  a4/d6
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bne    @EndTerrain
    adda.w #SIZE_LONG, a4
    dbra.w d6, @QuadrantLp

	@EndTerrain:
	
    ; Now search horizontally for walls
    jsr    ECPhysBodyChar_WallSearch

    POPM.W  d5/d6

    ; Check if landed on ground this frame
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    beq    @NotLanded
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6
    bne    @NotLanded
    bsr    ECPhysBodyChar_Landed
    moveq  #0x0, d2                     ; Done, clear remaining velocity
    moveq  #0x0, d3
    @NotLanded:

    POP.W  d7                           ; Restore map width

    bra    @VelLp                       ; Next velocity step

    ; ======================================
    ; Store output
    ; ======================================

    @ZeroVel:
    
    POP.L  a4                           ; Restore entity

    move.l d0, Entity_PosX(a4)          ; Store pos
    move.l d1, Entity_PosY(a4)

    move.l a5, ECPhysBodyChar_VelX(a3)   ; Store vel
    move.l a6, ECPhysBodyChar_VelY(a3)

    ; ======================================

    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @BodyLp

    @NoBodies:

    rts

ECPhysBodyChar_Landed:
    ; ======================================
    ; Re-acquisition of ground - converts
    ; air velocity back into ground speed
    ; after a terrain impact
    ; ======================================
    ; In/out:
    ;  d0.l Position X
    ;  d1.l Position Y
    ;  a3   CPhysBodyChar component
    ;  a4   Entity
    ;  a5   Backup vel X
    ;  a6   Backup vel Y
    ; ======================================

    ; Get angle of terrain on impact
    move.w ECPhysBodyChar_LastTerrainFlags(a3), d5
    moveq  #0x0, d7
    move.b d5, d7
    add.w  d7, d7                       ; Word offset

    ; Get current velocity
    moveq  #0x0, d2
    moveq  #0x0, d3
    move.w ECPhysBodyChar_VelX(a3), d2  ; Velocity X
    move.w ECPhysBodyChar_VelY(a3), d3  ; Velocity Y

    ; Get terrain normal
    moveq  #0x0, d4
    moveq  #0x0, d5
    lea    sinetable, a4
    move.w (a4,d7.w), d5                ; Normal Y
    addi.w #SINE_TBL_COS_OFFS, d7
    move.w (a4,d7.w), d4                ; Normal X
    
    ; Normal dot velocity (v1.x * v2.x + v1.y * v2.y)
    muls.w d2, d4
    muls.w d3, d5
    add.w  d4, d5

    move.w d5, ECPhysBodyChar_GroundSpeed(a3)

    rts

ECPhysBodyChar_WallSearch:
    ; ======================================
    ; Searches for solid walls horizontally.
    ; Corrects object X position, returns
    ; collision flags.
    ; Does not affect angle or quadrant.
    ; ======================================
    ; In:
    ;  a0   Terrain stamp map data
	;  a1   Terrain stampset data
    ;  a2   Terrain tileset data
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d4.w Extents X
    ;  d5.w Extents Y
    ;  d7.w Map width (stamps)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; Out:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d3.l Collision flags (floor flag, angle, and quadrant unchanged)
    ;  a5.l X velocity
    ;  a6.l Y velocity
    ; ======================================

    PUSHM.L d2/d7

    move.w d7, d2                       ; Map width (stamps)

    ; Get probe position
    PUSHM.L d0-d5/a0-a6
    swap   d0                                       ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X, d0                 ; X to map space
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d1; Y to map space - step height
    add.w  d5, d1                                   ; Centre to probe Y offset
    move.l #1<<COLLISION_TEST_BIT_SOLID_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5       ; Get layer
    
    ; Probe for floor
    cmp.l  #0x0, a5
    ble    @SearchLeft
    add.w  d4, d0                       ; Centre to probe X offset
    bsr    COL_ProbeTerrainRight        ; Probe terrain map (search right)
    bra    @SearchRight
    @SearchLeft:
    sub.w  d4, d0                       ; Centre to probe X offset
    bsr    COL_ProbeTerrainLeft         ; Probe terrain map (search left)
    @SearchRight:
    
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    btst   #COLLISION_FLAG_BIT_SOLID_W, d6 ; Check if hit wall
    beq    @EndWall
    addi.w #VDP_SPRITE_BORDER_X, d7     ; X back to sprite space
    cmp.l  #0x0, a5
    ble    @ProbeLeft
    sub.w  d4, d7                       ; Probe offset back to centre
    bra    @ProbeRight
    @ProbeLeft:
    add.w  d4, d7                       ; Probe offset back to centre
    @ProbeRight:
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    cmp.l  d7, d0                       ; Check if penetrating wall
    ble    @EndWall
    move.l d7, d0                       ; Hit wall, cap X and zero velocity
    move.l #0x0, d2                     ; Zero X velocity
    move.l #0x0, a5                     ; Zero X velocity (mirror)
    move.w #0x0, ECPhysBodyChar_GroundSpeed(a3) ; Zero ground speed
    bclr   #COLLISION_FLAG_BIT_TERRAIN_W, d6      ; Don't treat this as terrain
    lsr.w  #0x8, d6                               ; Leave angle unchanged
    or.b   d6, ECPhysBodyChar_LastTerrainFlags(a3) ; Store flags (leave angle unchanged)

    @EndWall:

    POPM.L  d2/d7

    rts

ECPhysBodyChar_TerrainSearch_Down:
    ; ======================================
    ; Searches for terrain or platforms downwards.
    ; Corrects object Y, returns
    ; collision flags and terrain height
    ; ======================================
    ; In:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d4.w Extents X
    ;  d5.w Extents Y
    ;  d7.w Map width (stamps)
    ;  a0   Terrain stamp map data
	;  a1   Terrain stampset data
    ;  a2   Terrain tileset data
    ;  a3   ECPhysBodyChar component
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; Out:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d7.w Terrain height (map space, -1 if not found)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d7

    move.w d7, d2                       ; Map width (stamps)
    swap   d0                           ; Position 16.16 to integer
    swap   d1
    
    moveq  #0x0, d7						; Pre-clear fraction of result

    ; Probe A
    PUSHM.L d0-d5/a0-a6
    subi.w #VDP_SPRITE_BORDER_X+PHYS_TERRAIN_PROBE_OFFSET, d0   ; X to map space - left probe
    subi.w #VDP_SPRITE_BORDER_Y, d1     ; Y to map space
    COL_PROBE_DBG_DRAW #8

    ; Probe for floor
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainDown         ; Probe terrain map (search downwards)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    ; Probe B
    IF PHYS_TERRAIN_DUAL_PROBES
    PUSHM.L d0-d5/a0-a6
    PUSHM.W d6-d7                       ; Backup probe A's height/flags/angle/quadrant
    subi.w #VDP_SPRITE_BORDER_X-PHYS_TERRAIN_PROBE_OFFSET, d0   ; X to map space + right probe
    subi.w #VDP_SPRITE_BORDER_Y, d1     ; Y to map space
    COL_PROBE_DBG_DRAW #9

    ; Probe for floor
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainDown         ; Probe terrain map (search downwards)
    move.w d7, d4                       ; Backup probe B's height
    POPM.W d6-d7                        ; Restore probe A's height/flags/angle/quadrant
    cmp.w  #-1, d7                      ; If probe A didn't find a floor, use B
    beq    @ProbeB
    cmp.w  #-1, d4                      ; If probe B didn't find a floor, use A
    beq    @ProbeA
    cmp.w  d4, d7
    ble    @ProbeA                      ; If probe A found a lesser height, use B
    @ProbeB:
    move.w d4, d7                       ; Use probe B's height
    move.w d3, d6                       ; Use probe B's flags/angle/quadrant
    @ProbeA:
    POPM.L d0-d5/a0-a6
    ENDIF

    cmp.w  #-1, d7                      ; d7 = terrain height, or -1
    beq    @NoTerrain
    
    ; Found terrain, check if within step height
    addi.w #VDP_SPRITE_BORDER_Y, d7     ; Y back to sprite space
    sub.w  d5, d7                       ; Y to centre
    subi.w #PHYS_STEP_HEIGHT, d7        ; - step height
    cmp.w  d7, d1                       ; Check if on or under floor
    blt    @NoTerrain
    
    ; Within step height, snap to floor
    addi.w #PHYS_STEP_HEIGHT, d7        ; + step height
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
    move.l #0x0, d3                     ; Zero Y velocity
    move.l #0x0, a6                     ; Zero Y velocity (mirror)
    move.w d6, ECPhysBodyChar_LastTerrainFlags(a3)   ; Store flags
    move.w d6, d7
    PUSH.L a4
    ANG_TO_QUAD  d6,a4                  ; Angle to quadrant
    POP.L  a4
    move.b d6, ECPhysBodyChar_TerrainQuadrant(a3)

    @NoTerrain:

    ; Search platforms
    ; TODO: Both floor probes
    PUSHM.L d0-d5/a0-a4
    movea.w Component_Owner(a3), a0
    bsr    PHYS_FindPlatform
    moveq  #0x0, d6						; Pre-clear fraction of result
    move.w d0, d6
    POPM.L  d0-d5/a0-a4
    cmp.w  #-1, d6
    beq    @NoPlatform
    subi.w #PHYS_STEP_HEIGHT, d6        ; - step height
    cmp.w  d6, d1                       ; Check if on or below platform
    blt    @NoPlatform
    addi.w #PHYS_STEP_HEIGHT, d6        ; + step height
    move.l d6, d1
    move.w #0x0, ECPhysBodyChar_LastTerrainFlags(a3) ; Angle is always up for a platform
    bset   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    move.b #PHYS_TERRAIN_SEARCH_QUADRANT_DOWN, ECPhysBodyChar_TerrainQuadrant(a3) ; Quadrant is always down for a platform
    move.l #0x0, d3                     ; Zero Y velocity
    move.l #0x0, a6                     ; Zero Y velocity (mirror)
    @NoPlatform:

    @FoundTerrain:

    swap   d0                           ; Position back to 16.16
    swap   d1
    
    POPM.L  d2/d7

    rts

ECPhysBodyChar_TerrainSearch_Right:
    ; ======================================
    ; Searches for terrain to the right.
    ; Corrects object X, returns
    ; collision flags and terrain width
    ; ======================================
    ; In:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d4.w Extents X
    ;  d5.w Extents Y
    ;  d7.w Map width (stamps)
    ;  a0   Terrain stamp map data
	;  a1   Terrain stampset data
    ;  a2   Terrain tileset data
    ;  a3   ECPhysBodyChar component
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; Out:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d7.w Terrain height (map space, -1 if not found)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d7

    move.w d7, d2                       ; Map width (stamps)
    swap   d0                           ; Position 16.16 to integer
    swap   d1
    
    moveq  #0x0, d7						; Pre-clear fraction of result
    
    ; Probe A
    PUSHM.L d0-d5/a0-a6
    subi.w #VDP_SPRITE_BORDER_X, d0     ; X to map space
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_TERRAIN_PROBE_OFFSET, d1   ; Y to map space - bottom probe
    COL_PROBE_DBG_DRAW #8

    ; Probe for right wall
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainRight        ; Probe terrain map (search right)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    ; Probe B
    IF PHYS_TERRAIN_DUAL_PROBES
    PUSHM.L d0-d5/a0-a6
    PUSHM.W d6-d7                       ; Backup probe A's width/flags/angle/quadrant
    subi.w #VDP_SPRITE_BORDER_X, d0     ; X to map space
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_TERRAIN_PROBE_OFFSET, d1   ; Y to map space + top probe
    COL_PROBE_DBG_DRAW #9

    ; Probe for right wall
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainRight        ; Probe terrain map (search right)
    move.w d7, d4                       ; Backup probe B's width
    POPM.W d6-d7                        ; Restore probe A's width/flags/angle/quadrant
    cmp.w  #-1, d7                      ; If probe A didn't find a floor, use B
    beq    @ProbeB
    cmp.w  #-1, d4                      ; If probe B didn't find a floor, use A
    beq    @ProbeA
    cmp.w  d4, d7
    ble    @ProbeA                      ; If probe A found a lesser width, use B
    @ProbeB:
    move.w d4, d7                       ; Use probe B's width
    move.w d3, d6                       ; Use probe B's flags/angle/quadrant
    @ProbeA:
    POPM.L d0-d5/a0-a6
    ENDIF

    cmp.w  #-1, d7                      ; d7 = terrain width, or -1
    beq    @EndTerrain
    
    ; Found terrain, check if within step height
    addi.w #VDP_SPRITE_BORDER_X, d7     ; X back to sprite space
    sub.w  d4, d7                       ; X to centre
    subi.w #PHYS_STEP_HEIGHT, d7        ; - step height
    cmp.w  d7, d0                       ; Check if right of wall
    blt    @EndTerrain
    
    ; Within step height, snap to terrain
    addi.w #PHYS_STEP_HEIGHT, d7        ; + step height
    move.l d7, d0                       ; Hit terrain, cap X and zero velocity
    move.l #0x0, d2                     ; Zero X velocity
    move.l #0x0, a5                     ; Zero X velocity (mirror)
    move.w d6, ECPhysBodyChar_LastTerrainFlags(a3)   ; Store flags
    PUSH.L a4
    ANG_TO_QUAD  d6,a4                  ; Angle to quadrant
    POP.L  a4
    move.b d6, ECPhysBodyChar_TerrainQuadrant(a3)

    @EndTerrain:
    
    swap   d0                           ; Position back to 16.16
    swap   d1

    POPM.L  d2/d7

    rts

ECPhysBodyChar_TerrainSearch_Up:
    ; ======================================
    ; Searches for terrain upwards.
    ; Corrects object Y, returns
    ; collision flags and terrain height
    ; ======================================
    ; In:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d4.w Extents X
    ;  d5.w Extents Y
    ;  d7.w Map width (stamps)
    ;  a0   Terrain stamp map data
	;  a1   Terrain stampset data
    ;  a2   Terrain tileset data
    ;  a3   ECPhysBodyChar component
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; Out:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d7.w Terrain height (map space, -1 if not found)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d7

    move.w d7, d2                       ; Map width (stamps)
    swap   d0                           ; Position 16.16 to integer
    swap   d1
    
    moveq  #0x0, d7						; Pre-clear fraction of result

    ; Probe A
    PUSHM.L d0-d5/a0-a6
    subi.w #VDP_SPRITE_BORDER_X+PHYS_TERRAIN_PROBE_OFFSET, d0   ; X to map space - left probe
    subi.w #VDP_SPRITE_BORDER_Y, d1     ; Y to map space
    COL_PROBE_DBG_DRAW #8

    ; Probe for ceiling
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainUp           ; Probe terrain map (search upwards)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    ; Probe B
    IF PHYS_TERRAIN_DUAL_PROBES
    PUSHM.L d0-d5/a0-a6
    PUSHM.W d6-d7                       ; Backup probe A's width/flags/angle/quadrant
    subi.w #VDP_SPRITE_BORDER_X-PHYS_TERRAIN_PROBE_OFFSET, d0   ; X to map space + right probe
    subi.w #VDP_SPRITE_BORDER_Y, d1     ; Y to map space
    COL_PROBE_DBG_DRAW #9

    ; Probe for ceiling
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainUp           ; Probe terrain map (search upwards)
    move.w d7, d4                       ; Backup probe B's width
    POPM.W d6-d7                        ; Restore probe A's width/flags/angle/quadrant
    cmp.w  #-1, d7                      ; If probe A didn't find a floor, use B
    beq    @ProbeB
    cmp.w  #-1, d4                      ; If probe B didn't find a floor, use A
    beq    @ProbeA
    cmp.w  d4, d7
    bge    @ProbeA                      ; If probe A found a greater width, use B
    @ProbeB:
    move.w d4, d7                       ; Use probe B's width
    move.w d3, d6                       ; Use probe B's flags/angle/quadrant
    @ProbeA:
    POPM.L d0-d5/a0-a6
    ENDIF

    cmp.w  #-1, d7                      ; d7 = terrain height, or -1
    beq    @EndTerrain
    
	; Found terrain, check if within step height
    addi.w #VDP_SPRITE_BORDER_Y, d7     ; Y back to sprite space
    add.w  d4, d7                       ; Y to centre
    addi.w #PHYS_STEP_HEIGHT, d7        ; + step height
    cmp.w  d7, d1                       ; Check if on or above ceiling
    bgt    @EndTerrain
    
    ; Within step height, snap to terrain
    subi.w #PHYS_STEP_HEIGHT, d7        ; - step height
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
    move.l #0x0, d3                     ; Zero Y velocity
    move.l #0x0, a6                     ; Zero Y velocity (mirror)
    move.w d6, ECPhysBodyChar_LastTerrainFlags(a3)   ; Store flags
    PUSH.L a4
    ANG_TO_QUAD  d6,a4                  ; Angle to quadrant
    POP.L  a4
    move.b d6, ECPhysBodyChar_TerrainQuadrant(a3)

    @EndTerrain:

    swap   d0                           ; Position back to 16.16
    swap   d1
    
    POPM.L  d2/d7

    rts

ECPhysBodyChar_TerrainSearch_Left:
    ; ======================================
    ; Searches for terrain to the left.
    ; Corrects object X, returns
    ; collision flags and terrain width
    ; ======================================
    ; In:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d4.w Extents X
    ;  d5.w Extents Y
    ;  d7.w Map width (stamps)
    ;  a0   Terrain stamp map data
	;  a1   Terrain stampset data
    ;  a2   Terrain tileset data
    ;  a3   ECPhysBodyChar component
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; Out:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d2.l X velocity
    ;  d3.l Y velocity
    ;  d7.w Terrain height (map space, -1 if not found)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d7

    move.w d7, d2                       ; Map width (stamps)
    swap   d0                           ; Position 16.16 to integer
    swap   d1
    
    moveq  #0x0, d7						; Pre-clear fraction of result

    ; Probe A
    PUSHM.L d0-d5/a0-a6
    subi.w #VDP_SPRITE_BORDER_X, d0     ; X to map space
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_TERRAIN_PROBE_OFFSET, d1   ; Y to map space + top probe
    COL_PROBE_DBG_DRAW #8

    ; Probe for wall
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainLeft         ; Probe terrain map (search left)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    ; Probe B
    IF PHYS_TERRAIN_DUAL_PROBES
    PUSHM.L d0-d5/a0-a6
    PUSHM.W d6-d7                       ; Backup probe A's height/flags/angle/quadrant
    subi.w #VDP_SPRITE_BORDER_X, d0     ; X to map space
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_TERRAIN_PROBE_OFFSET, d1   ; Y to map space - bottom probe
    COL_PROBE_DBG_DRAW #9

    ; Probe for wall
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainLeft         ; Probe terrain map (search left)
    move.w d7, d4                       ; Backup probe B's height
    POPM.W d6-d7                        ; Restore probe A's height/flags/angle/quadrant
    cmp.w  #-1, d7                      ; If probe A didn't find a floor, use B
    beq    @ProbeB
    cmp.w  #-1, d4                      ; If probe B didn't find a floor, use A
    beq    @ProbeA
    cmp.w  d4, d7
    bge    @ProbeA                      ; If probe A found a lesser height, use B
    @ProbeB:
    move.w d4, d7                       ; Use probe B's height
    move.w d3, d6                       ; Use probe B's flags/angle/quadrant
    @ProbeA:
    POPM.L d0-d5/a0-a6
    ENDIF

    cmp.w  #-1, d7                      ; d7 = terrain height, or -1
    beq    @EndTerrain
    
    ; Found terrain, check if within step height
    addi.w #VDP_SPRITE_BORDER_X, d7     ; X back to sprite space
    add.w  d4, d7                       ; X to centre
    addi.w #PHYS_STEP_HEIGHT, d7        ; + step height
    cmp.w  d7, d0                       ; Check if left of wall
    bgt    @EndTerrain
    
    ; Within step height, snap to terrain
    subi.w #PHYS_STEP_HEIGHT, d7        ; - step height
    move.l d7, d0                       ; Hit terrain, cap X and zero velocity
    move.l #0x0, d2                     ; Zero X velocity
    move.l #0x0, a5                     ; Zero X velocity (mirror)
    move.w d6, ECPhysBodyChar_LastTerrainFlags(a3)   ; Store flags
    PUSH.L a4
    ANG_TO_QUAD  d6,a4                  ; Angle to quadrant
    POP.L  a4
    move.b d6, ECPhysBodyChar_TerrainQuadrant(a3)

    @EndTerrain:
    
    swap   d0                           ; Position back to 16.16
    swap   d1

    POPM.L  d2/d7

    rts
