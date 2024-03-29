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

    ; Apply velocity in tile*2 steps
    move.l d2, d4                       ; Clamp X/Y vel to tile width/height
    move.l d3, d5
    CLAMP.L d4, #-((COLLISION_TILE_WIDTH*2)<<16), #((COLLISION_TILE_WIDTH*2)<<16)
    CLAMP.L d5, #-((COLLISION_TILE_HEIGHT*2)<<16), #((COLLISION_TILE_HEIGHT*2)<<16)

    sub.l  d4, d2                       ; Subtract from total vel
    sub.l  d5, d3

    add.l  d4, d0                       ; Apply vel to pos
    add.l  d5, d1
    
    ; Backup and clear last terrain flags
    move.w ECPhysBodyChar_LastTerrainFlags(a3), d5
    move.w #0x0, ECPhysBodyChar_LastTerrainFlags(a3)
    PUSHM.W d5/d6

    ; If not already on ground, search all directions
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d5
    bne    @SearchQuadrant
    bsr    ECPhysBodyChar_TerrainSearch_Down
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bne    @EndTerrain
    bsr    ECPhysBodyChar_TerrainSearch_Right
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bne    @EndTerrain
    bsr    ECPhysBodyChar_TerrainSearch_Left
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bne    @EndTerrain
    bsr    ECPhysBodyChar_TerrainSearch_Up
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bne    @EndTerrain

    ; Search platforms
    ; TODO: Both floor probes
    PUSHM.L d0-d5/a0-a4
    move.l a4, a0
    bsr    PHYS_EntityFindPlatform
    move.w d0, d6
    POPM.L  d0-d5/a0-a4
    cmp.w  #-1, d6
    beq    @NoPlatform
    INT_TO_FIXED16 d6
    cmp.l  d6, d1                       ; Check if on or below platform
    blt    @NoPlatform
    move.l d6, d1
    bset   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bra    @EndTerrain
    @NoPlatform:

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

    ; Already on ground, terrain lookup by quadrant
    @SearchQuadrant:
    move.w #0x0, ECPhysBodyChar_LastTerrainFlags(a3)
    move.b ECPhysBodyChar_TerrainQuadrant(a3), d6
    cmp.b  #PHYS_TERRAIN_SEARCH_QUADRANT_DOWN, d6
    beq    @Down
    cmp.b  #PHYS_TERRAIN_SEARCH_QUADRANT_RIGHT, d6
    beq    @Right
    cmp.b  #PHYS_TERRAIN_SEARCH_QUADRANT_LEFT, d6
    beq    @Left
    @Up:
    bsr    ECPhysBodyChar_TerrainSearch_Up
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bne    @SearchWalls
    bra    @Down
    @Right:
    bsr    ECPhysBodyChar_TerrainSearch_Right
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bne    @EndTerrain
    bra    @Down
    @Left:
    bsr    ECPhysBodyChar_TerrainSearch_Left
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    bne    @EndTerrain
    bra    @Down

    @Down:
    bsr    ECPhysBodyChar_TerrainSearch_Down

    @SearchWalls:
    ; Searched vertically for terrain, now search horizontally for walls
    jsr    ECPhysBodyChar_WallSearch

    @EndTerrain:

    POPM.W  d5/d6

    ; Check if landed on ground this frame
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyChar_LastTerrainFlags(a3)
    beq    @NotLanded
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d5
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
    ;  d5.w Prev terrain flags
    ;  d7.w Map width (stamps)
    ;  a4   Entity
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; Out:
    ;  d0.l Position X (map space)
    ;  d1.l Position Y (map space)
    ;  d3.l Collision flags (floor flag, angle, and quadrant unchanged)
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
    move.b ECPhysBodyChar_TerrainLayer(a3), d5       ; Get layer
    
    ; Probe for floor
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
    move.w #0x0, ECPhysBodyChar_GroundSpeed(a3) ; Zero ground speed
    bclr   #COLLISION_FLAG_BIT_TERRAIN_W, d6      ; Don't treat this as terrain
    lsr.w  #0x8, d6                               ; Leave angle unchanged
    or.b   d6, ECPhysBodyChar_LastTerrainFlags(a3) ; Store flags (leave angle unchanged)

    @EndWall:

    POPM.L  d2/d6-d7

    rts

ECPhysBodyChar_TerrainSearch_Down:
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
    ;  d7.w Terrain height (map space, -1 if not found)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d6-d7

    move.w d7, d2                       ; Map width (stamps)

    ; Probe A
    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X+PHYS_TERRAIN_PROBE_OFFSET, d0   ; X to map space - left probe
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d1            ; Y to map space - step height
    add.w  Entity_ExtentsY(a4), d1                              ; Centre to Y probe offset

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
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X-PHYS_TERRAIN_PROBE_OFFSET, d0   ; X to map space + right probe
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d1            ; Y to map space - step height
    add.w  Entity_ExtentsY(a4), d1                              ; Centre to Y probe offset

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
    beq    @EndTerrain
    addi.w #VDP_SPRITE_BORDER_Y, d7     ; Y back to sprite space
    sub.w  Entity_ExtentsY(a4), d7      ; Probe offset back to centre
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d5 ; If already on terrain, stick to it
    bne    @SnapToFloor
    cmp.l  d7, d1                       ; Check if on or under floor
    blt    @EndTerrain
    @SnapToFloor:
    subi.w #PHYS_STEP_HEIGHT, d1        ; - step height
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
    move.l #0x0, d3                     ; Zero Y velocity
    move.l #0x0, a6                     ; Zero Y velocity (mirror)
    move.w d6, ECPhysBodyChar_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysBodyChar_TerrainQuadrant(a3)

    @EndTerrain:

    POPM.L  d2/d6-d7

    rts

ECPhysBodyChar_TerrainSearch_Right:
    ; ======================================
    ; Searches for terrain to the right.
    ; Corrects object X, returns
    ; collision flags and terrain width
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
    ;  d7.w Terrain height (map space, -1 if not found)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d6-d7

    move.w d7, d2                       ; Map width (stamps)

    ; Probe A
    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_TERRAIN_PROBE_OFFSET, d1   ; Y to map space - bottom probe
    subi.w #VDP_SPRITE_BORDER_X+PHYS_STEP_HEIGHT, d0            ; X to map space - step height
    add.w  Entity_ExtentsX(a4), d0                              ; Centre to X probe offset

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
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_TERRAIN_PROBE_OFFSET, d1   ; Y to map space + top probe
    subi.w #VDP_SPRITE_BORDER_X+PHYS_STEP_HEIGHT, d0            ; X to map space - step height
    add.w  Entity_ExtentsX(a4), d0                              ; Centre to probe X offset

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
    addi.w #VDP_SPRITE_BORDER_X, d7     ; X back to sprite space
    sub.w  Entity_ExtentsX(a4), d7      ; Probe offset back to centre
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d5 ; If already on terrain, stick to it
    bne    @SnapToFloor
    cmp.l  d7, d0                       ; Check if left of wall
    blt    @EndTerrain
    @SnapToFloor:
    subi.w #PHYS_STEP_HEIGHT, d0        ; - step height
    move.l d7, d0                       ; Hit terrain, cap X and zero velocity
    move.l #0x0, d2                     ; Zero X velocity
    move.l #0x0, a5                     ; Zero X velocity (mirror)
    move.w d6, ECPhysBodyChar_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysBodyChar_TerrainQuadrant(a3)

    @EndTerrain:

    POPM.L  d2/d6-d7

    rts

ECPhysBodyChar_TerrainSearch_Up:
    ; ======================================
    ; Searches for terrain upwards.
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
    ;  d7.w Terrain height (map space, -1 if not found)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d6-d7

    move.w d7, d2                       ; Map width (stamps)

    ; Probe A
    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X+PHYS_TERRAIN_PROBE_OFFSET, d0   ; X to map space - left probe
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_STEP_HEIGHT, d1            ; Y to map space + step height
    sub.w  Entity_ExtentsY(a4), d1                              ; Centre to Y probe offset

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
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X-PHYS_TERRAIN_PROBE_OFFSET, d0   ; X to map space + right probe
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_STEP_HEIGHT, d1            ; Y to map space + step height
    sub.w  Entity_ExtentsY(a4), d1                              ; Centre to Y probe offset

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
    addi.w #VDP_SPRITE_BORDER_Y, d7     ; Y back to sprite space
    add.w  Entity_ExtentsX(a4), d7      ; Probe offset back to centre
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d5 ; If already on terrain, stick to it
    bne    @SnapToFloor
    cmp.l  d7, d1                       ; Check if on or above ceiling
    bgt    @EndTerrain
    @SnapToFloor:
    addi.w #PHYS_STEP_HEIGHT, d1        ; + step height
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
    move.l #0x0, d3                     ; Zero Y velocity
    move.l #0x0, a6                     ; Zero Y velocity (mirror)
    move.w d6, ECPhysBodyChar_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysBodyChar_TerrainQuadrant(a3)

    @EndTerrain:

    POPM.L  d2/d6-d7

    rts

ECPhysBodyChar_TerrainSearch_Left:
    ; ======================================
    ; Searches for terrain to the left.
    ; Corrects object X, returns
    ; collision flags and terrain width
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
    ;  d7.w Terrain height (map space, -1 if not found)
    ;  a5.l X velocity (mirror)
    ;  a6.l Y velocity (mirror)
    ; ======================================

    PUSHM.L d2/d6-d7

    move.w d7, d2                       ; Map width (stamps)

    ; Probe A
    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_TERRAIN_PROBE_OFFSET, d1   ; Y to map space + top probe
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_STEP_HEIGHT, d0            ; X to map space - step height
    sub.w  Entity_ExtentsX(a4), d0                              ; Centre to X probe offset

    ; Probe for floor
    move.l #1<<COLLISION_TEST_BIT_TERRAIN_L, d5
    move.b ECPhysBodyChar_TerrainLayer(a3), d5
    bsr    COL_ProbeTerrainLeft         ; Probe terrain map (search left)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    ; Probe B
    IF PHYS_TERRAIN_DUAL_PROBES
    PUSHM.L d0-d5/a0-a6
    PUSHM.W d6-d7                       ; Backup probe A's height/flags/angle/quadrant
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_TERRAIN_PROBE_OFFSET, d1   ; Y to map space - bottom probe
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_STEP_HEIGHT, d0            ; X to map space - step height
    sub.w  Entity_ExtentsX(a4), d0                              ; Centre to X probe offset

    ; Probe for floor
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
    addi.w #VDP_SPRITE_BORDER_X, d7     ; X back to sprite space
    add.w  Entity_ExtentsX(a4), d7      ; Probe offset back to centre
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d5 ; If already on terrain, stick to it
    bne    @SnapToFloor
    cmp.l  d7, d0                       ; Check if left of wall
    bgt    @EndTerrain
    @SnapToFloor:
    addi.w #PHYS_STEP_HEIGHT, d0        ; + step height
    move.l d7, d0                       ; Hit terrain, cap X and zero velocity
    move.l #0x0, d2                     ; Zero X velocity
    move.l #0x0, a5                     ; Zero X velocity (mirror)
    move.w d6, ECPhysBodyChar_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysBodyChar_TerrainQuadrant(a3)

    @EndTerrain:

    POPM.L  d2/d6-d7

    rts
