; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; PHYSBODY.ASM - Physics body sprite component
; ============================================================================================

    COMPONENT_SPAWN_DATA_BEGIN ECPhysicsBody
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECPhysicsBody
ECPhysicsBody_VelX                      rs.l 1
ECPhysicsBody_VelY                      rs.l 1
ECPhysicsBody_MaxVelX                   rs.l 1
ECPhysicsBody_GroundSpeed               rs.w 1
ECPhysicsBody_AccelX                    rs.w 1
ECPhysicsBody_AccelY                    rs.w 1
ECPhysicsBody_DecelX                    rs.w 1
ECPhysicsBody_LastTerrainFlags          rs.w 1
ECPhysicsBody_TerrainQuadrant           rs.b 1 ; PHYS_TERRAIN_SEARCH_QUADRANT_*
ECPhysicsBody_TerrainLayer              rs.b 1
    ENTITY_COMPONENT_END

ECPhysicsBody_Initialise:
    ; ======================================
    ; ECPhysicsBody constructor
    ; ======================================
	; a0   Component
    ; a1   Component spawn data
    ; ======================================

    move.l #0x0, ECPhysicsBody_VelX(a0)
    move.l #0x0, ECPhysicsBody_VelY(a0)
    move.l #PHYS_DEFAULT_MAX_VEL_X, ECPhysicsBody_MaxVelX(a0)
    move.w #0x0, ECPhysicsBody_GroundSpeed(a0)
    move.w #0x0, ECPhysicsBody_AccelX(a0)
    move.w #0x0, ECPhysicsBody_AccelY(a0)
    move.w #0x0, ECPhysicsBody_LastTerrainFlags(a0)
    move.b #PHYS_TERRAIN_SEARCH_QUADRANT_DOWN, ECPhysicsBody_TerrainQuadrant(a0)
    move.b #0x0, ECPhysicsBody_TerrainLayer(a0)

    rts

ECPhysicsBody_Shutdown:
    ; ======================================
    ; ECPhysicsBody destructor
    ; ======================================
	; a0   Component
    ; ======================================

    rts

ECPhysicsBody_Step:
    ; ======================================
    ; Steps all physics bodies and handles
    ; collisions
    ; ======================================
	; No params
    ; ======================================

    ENT_COMPONENT_GET_LIST_HEAD ECPhysicsBody, a3
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

    move.l ECPhysicsBody_VelX(a3), d2   ; Get vel
    move.l ECPhysicsBody_VelY(a3), d3

    move.w ECPhysicsBody_AccelX(a3), d4 ; Get accel
    move.w ECPhysicsBody_AccelY(a3), d5
    ext.l  d4
    ext.l  d5
    
    PUSH.L a4                           ; Backup entity

    ; ======================================
    ; Step
    ; ======================================                  
    addi.l #PHYS_GRAVITY_Y, d5          ; Apply gravity to accel

    ; If on floor, move using ground speed
    move.w ECPhysicsBody_LastTerrainFlags(a3), d6	; Get flags and angle
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6		; Check on terrain
    beq    @InAir

    moveq  #0x0, d5
    move.w ECPhysicsBody_GroundSpeed(a3), d5		; Get ground speed
    ext.l  d5
    tst.l  d4
    beq    @Decelerate
    asr.l  #0x8, d4                                 ; X accel to ground speed range (16.16 >> 8)
    add.l  d4, d5                       			; Apply X accel to ground speed
    bra    @Accelerate

    ; Deceleration
    @Decelerate:
    move.w ECPhysicsBody_DecelX(a3), d4             ; Apply X decel to ground speed
    asr.w  #0x8, d4                                 ; X decel to ground speed range (16.16 >> 8)
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
    move.l ECPhysicsBody_MaxVelX(a3), d4	        ; Clamp ground speed to max
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

    muls.w #PHYS_SLOPE_RESISTANCE_FACTOR>>8, d4     ; Adjust ground speed by sine(angle)*slope factor
    asr.w  #0x8, d4
    add.w  d4, d5
            
    addi.w #SINE_TBL_COS_OFFS, d6		; X vel = ground speed * cos(angle)
    moveq  #0x0, d4
    move.w (a4,d6.w), d4
    muls.w d4, d2
    POP.L  a4

    move.w d5, ECPhysicsBody_GroundSpeed(a3)        ; Store updated ground speed

    bra    @EndGroundSpeed

    @InAir:
    
    ; Regular accel/velocity not using terrain angles
    add.l  d4, d2                       ; Apply accel to vel
    add.l  d5, d3

    ; Clamp X velocity
    moveq  #0x0, d4
    move.l ECPhysicsBody_MaxVelX(a3), d4
    move.l d4, d5
    neg.l  d5
    CLAMP.L d2,d5,d4

    ; Search terrain downwards
    move.b #PHYS_TERRAIN_SEARCH_QUADRANT_DOWN, ECPhysicsBody_TerrainQuadrant(a3)

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
    move.w ECPhysicsBody_LastTerrainFlags(a3), d5
    move.w #0x0, ECPhysicsBody_LastTerrainFlags(a3)
    PUSHM.W d5/d6

    ; Terrain lookup
    move.b ECPhysicsBody_TerrainQuadrant(a3), d6
    cmp.b  #PHYS_TERRAIN_SEARCH_QUADRANT_DOWN, d6
    beq    @Down
    cmp.b  #PHYS_TERRAIN_SEARCH_QUADRANT_RIGHT, d6
    beq    @Right
    cmp.b  #PHYS_TERRAIN_SEARCH_QUADRANT_LEFT, d6
    beq    @Left
    @Up:
    bsr    ECPhysicsBody_TerrainSearch_Up
    bra    @EndTerrain
    @Down:
    bsr    ECPhysicsBody_TerrainSearch_Down
    bra    @EndTerrain
    @Right:
    bsr    ECPhysicsBody_TerrainSearch_Right
    bra    @EndTerrain
    @Left:
    bsr    ECPhysicsBody_TerrainSearch_Left
    @EndTerrain:

    POPM.W  d5/d6

    ; Check if landed on ground this frame
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, ECPhysicsBody_LastTerrainFlags(a3)
    beq    @NotLanded
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d5
    bne    @NotLanded
    bsr    ECPhysicsBody_Landed
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

    move.l a5, ECPhysicsBody_VelX(a3)   ; Store vel
    move.l a6, ECPhysicsBody_VelY(a3)

    ; ======================================

    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @BodyLp

    @NoBodies:

    rts

ECPhysicsBody_Landed:

    ; If landed on floor, not ceiling
    tst.l  ECPhysicsBody_VelY(a3)
    blt    @LandedCeiling

    ; If X > Y, landed sideways
    move.l ECPhysicsBody_VelX(a3), d7
    move.l ECPhysicsBody_VelY(a3), d6
    ABS.L  d7
    cmp.l  d6, d7
    bge    @LandedSideways

    ; Get angle of terrain on impact
    ; TODO: Not the terrain angle, the movement angle from X/Y velocity
    move.w ECPhysicsBody_LastTerrainFlags(a3), d5
    moveq  #0x0, d6

    ; Shallow angle (0-22.5 deg, $F0-$FF/$00-$0F)
    move.b d5, d6
    addi.b #0x10, d6
    cmp.w  #0x10*2, d6
    ble    @ShallowAngle

    ; Steep angle (22.5-45 deg, $E0-$EF/$10-$1F)
    move.b d5, d6
    addi.b #0x20, d6
    cmp.w  #0x20*2, d6
    ble    @SteepAngle
    bra    @VerySteepAngle

    ; Landed at steep angle, set ground speed to Y velocity / 2
    @SteepAngle:
    move.l ECPhysicsBody_VelY(a3), d6
    asr.l  #0x8, d6                     ; Y vel to ground speed range (16.16 >> 8)
    asr.l  #0x1, d6                     ; / 2
    tst.b  d5                           ; Get sign of angle
    bge    @NoNeg1
    neg.w  d6                           ; -ve direction
    @NoNeg1:
    move.w d6, ECPhysicsBody_GroundSpeed(a3)
    
    rts

    ; Landed at very steep angle, clamp Y velocity to 0x0FC0 and set as ground speed
    @VerySteepAngle:
    move.l ECPhysicsBody_VelY(a3), d6
    asr.l  #0x8, d6                     ; Y vel to ground speed range (16.16 >> 8)
    cmpi.w #0x0FC0, d6
    ble    @NoClampY
    move.w #0x0FC0, d6
    @NoClampY:
    tst.b  d5                           ; Get sign of angle
    bge    @NoNeg2
    neg.w  d6                           ; -ve direction
    @NoNeg2:
    move.w d6, ECPhysicsBody_GroundSpeed(a3)
    
    rts

    @ShallowAngle:
    @LandedSideways:
    move.l ECPhysicsBody_VelX(a3), d6
    asr.l  #0x8, d6                     ; X vel to ground speed range (16.16 >> 8)
    move.w d6, ECPhysicsBody_GroundSpeed(a3)

    @LandedCeiling:

    rts

ECPhysicsBody_TerrainSearch_Down:

    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X, d0     ; X to map space
    add.w  Entity_ExtentsY(a4), d1      ; Centre to probe offset
    move.w d7, d2

    ; Probe for floor
    move.b ECPhysicsBody_TerrainLayer(a3), d5
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d1 ; Y - step height
    bsr    COL_ProbeTerrainDown         ; Probe terrain map (search downwards)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

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
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
    subi.w #PHYS_STEP_HEIGHT, d1        ; - step height
    move.l #0x0, d3
    move.l #0x0, a6
    move.w d6, ECPhysicsBody_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysicsBody_TerrainQuadrant(a3)

    @EndTerrain:

    rts

ECPhysicsBody_TerrainSearch_Right:

    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_Y, d1     ; Y to map space
    add.w  Entity_ExtentsX(a4), d0      ; Centre to probe offset
    move.w d7, d2

    ; Probe for right-hand wall
    move.b ECPhysicsBody_TerrainLayer(a3), d5
    subi.w #VDP_SPRITE_BORDER_X+PHYS_STEP_HEIGHT, d0 ; X - step height
    bsr    COL_ProbeTerrainRight        ; Probe terrain map (search right)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

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
    move.l d7, d0                       ; Hit terrain, cap X and zero velocity
    subi.w #PHYS_STEP_HEIGHT, d0        ; - step height
    move.l #0x0, d2
    move.l #0x0, a5
    move.w d6, ECPhysicsBody_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysicsBody_TerrainQuadrant(a3)

    @EndTerrain:

    rts

ECPhysicsBody_TerrainSearch_Up:

    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X, d0     ; X to map space
    sub.w  Entity_ExtentsY(a4), d1      ; Centre to probe offset
    move.w d7, d2

    ; Probe for ceiling
    move.b ECPhysicsBody_TerrainLayer(a3), d5
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_STEP_HEIGHT, d1 ; Y + step height
    bsr    COL_ProbeTerrainUp           ; Probe terrain map (search upwards)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

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
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
    addi.w #PHYS_STEP_HEIGHT, d1        ; + step height
    move.l #0x0, d3
    move.l #0x0, a6
    move.w d6, ECPhysicsBody_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysicsBody_TerrainQuadrant(a3)

    @EndTerrain:

    rts

ECPhysicsBody_TerrainSearch_Left:

    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_Y, d1     ; Y to map space
    sub.w  Entity_ExtentsX(a4), d0      ; Centre to probe offset
    move.w d7, d2

    ; Probe for left-hand wall
    move.b ECPhysicsBody_TerrainLayer(a3), d5
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_STEP_HEIGHT, d0 ; X - step height
    bsr    COL_ProbeTerrainLeft         ; Probe terrain map (search left)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

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
    move.l d7, d0                       ; Hit terrain, cap X and zero velocity
    addi.w #PHYS_STEP_HEIGHT, d1        ; + step height
    move.l #0x0, d2
    move.l #0x0, a5
    move.w d6, ECPhysicsBody_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysicsBody_TerrainQuadrant(a3)

    @EndTerrain:

    rts
