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
ECPhysicsBody_GroundSpeed               rs.l 1
ECPhysicsBody_VelX                      rs.l 1
ECPhysicsBody_VelY                      rs.l 1
ECPhysicsBody_AccelX                    rs.w 1
ECPhysicsBody_AccelY                    rs.w 1
ECPhysicsBody_LastTerrainFlags          rs.w 1
ECPhysicsBody_TerrainQuadrant           rs.b 1 ; PHYS_TERRAIN_SEARCH_QUADRANT_*
    ENTITY_COMPONENT_END

ECPhysicsBody_TerrainSearches:
    dc.l ECPhysicsBody_TerrainSearch_Down
    dc.l ECPhysicsBody_TerrainSearch_Right
    dc.l ECPhysicsBody_TerrainSearch_Up
    dc.l ECPhysicsBody_TerrainSearch_Left

ECPhysicsBody_Initialise:
    ; ======================================
    ; ECPhysicsBody constructor
    ; ======================================
	; a0   Component
    ; a1   Component spawn data
    ; ======================================

    move.l #0x0, ECPhysicsBody_GroundSpeed(a0)
    move.l #0x0, ECPhysicsBody_VelX(a0)
    move.l #0x0, ECPhysicsBody_VelY(a0)
    move.w #0x0, ECPhysicsBody_AccelX(a0)
    move.w #0x0, ECPhysicsBody_AccelY(a0)
    move.w #0x0, ECPhysicsBody_LastTerrainFlags(a0)
    move.b #PHYS_TERRAIN_SEARCH_QUADRANT_DOWN, ECPhysicsBody_TerrainQuadrant(a0)

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

    moveq  #0x0, d4                     ; Clear for accel
    moveq  #0x0, d5

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
    IF PHYS_GRAVITY_X                   ; Apply gravity to accel
    addi.l #PHYS_GRAVITY_X, d4
    ENDIF

    IF PHYS_GRAVITY_Y
    addi.l #PHYS_GRAVITY_Y, d5
    ENDIF

    add.l  d4, d2                       ; Apply accel to vel
    add.l  d5, d3

    ; If on floor, convert X ground speed to x/y vel using sin/cos of angle
    move.w ECPhysicsBody_LastTerrainFlags(a3), d6
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6
    beq    @NoGroundSpeed
    move.l ECPhysicsBody_GroundSpeed(a3), d5
    add.l  d4, d5                       ; Apply X accel to ground speed
    beq    @NoGroundSpeed
    move.l d5, ECPhysicsBody_GroundSpeed(a3) ; Store updated ground speed
    move.l #-0x400, d5
    move.l d5, d2						; x vel
    move.l d5, d3						; y vel
    andi.w #0xFF, d6					; Extract angle from flags
    add.w  d6, d6

    lea    testsin, a4                 ; Ground speed to y vel
    moveq  #0x0, d4
    move.w (a4,d6.w), d4
    ;ext.w  d4
    ;ext.l  d4
    muls.w d4, d3
            
    addi.w #0x80, d6					; Ground speed to x vel
    moveq  #0x0, d4
    move.w (a4,d6.w), d4
    ;ext.w  d4
    ;ext.l  d4
    muls.w d4, d2

    @NoGroundSpeed:

    move.l d2, a5                       ; Backup vel
    move.l d3, a6

    @VelLp:

    move.l d2, d6                       ; If vel is zero, skip terrain detection
    or.l   d3, d6
    beq    @ZeroVel

    PUSH.W d7                           ; Backup map width

    ; Apply velocity in tile width/height steps
    move.l d2, d4                       ; Clamp X/Y vel to tile width/height
    move.l d3, d5
    CLAMP.L d4, #-(COLLISION_TILE_WIDTH<<16), #(COLLISION_TILE_WIDTH<<16)
    CLAMP.L d5, #-(COLLISION_TILE_HEIGHT<<16), #(COLLISION_TILE_HEIGHT<<16)

    sub.l  d4, d2                       ; Subtract from total vel
    sub.l  d5, d3

    add.l  d4, d0                       ; Apply vel to pos
    add.l  d5, d1
    
    ; Clear last terrain flags
    ;move.w #0x0, ECPhysicsBody_LastTerrainFlags(a3)

    ; Get terrain lookup func from table
    moveq  #0x0, d6
    move.b ECPhysicsBody_TerrainQuadrant(a3), d6
    add.w  d6, d6
    add.w  d6, d6
    lea    ECPhysicsBody_TerrainSearches, a4
    move.l (a4,d6.w), a4
    jsr    (a4)                         ; Terrain lookup

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

ECPhysicsBody_TerrainSearch_Down:

    PUSHM.L d0-d5/a0-a6
    swap   d0                           ; 16.16 to integer
    swap   d1
    subi.w #VDP_SPRITE_BORDER_X, d0     ; X to map space
    move.w d7, d2

    ; Probe for floor
    subi.w #VDP_SPRITE_BORDER_Y+PHYS_STEP_HEIGHT, d1 ; Y - step height
    bsr    COL_ProbeTerrainDown         ; Probe terrain map (search downwards)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    cmp.w  #-1, d7                      ; d7 = terrain height, or -1
    beq    @EndTerrain
    addi.w #VDP_SPRITE_BORDER_Y, d7     ; Y back to sprite space
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    cmp.l  d7, d1                       ; Check if on or under floor
    blt    @EndTerrain
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
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
    move.w d7, d2

    ; Probe for right-hand wall
    subi.w #VDP_SPRITE_BORDER_X+PHYS_STEP_HEIGHT, d0 ; X - step height
    bsr    COL_ProbeTerrainRight        ; Probe terrain map (search right)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    cmp.w  #-1, d7                      ; d7 = terrain width, or -1
    beq    @EndTerrain
    addi.w #VDP_SPRITE_BORDER_X, d7     ; X back to sprite space
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    cmp.l  d7, d0                       ; Check if left of wall
    blt    @EndTerrain
    move.l d7, d0                       ; Hit terrain, cap X and zero velocity
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
    move.w d7, d2

    ; Probe for ceiling
    @SearchUp:
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_STEP_HEIGHT, d1 ; Y + step height
    bsr    COL_ProbeTerrainUp           ; Probe terrain map (search upwards)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    cmp.w  #-1, d7                      ; d7 = terrain height, or -1
    beq    @EndTerrain
    addi.w #VDP_SPRITE_BORDER_Y, d7     ; Y back to sprite space
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    cmp.l  d7, d1                       ; Check if on or above ceiling
    bgt    @EndTerrain
    move.l d7, d1                       ; Hit terrain, cap Y and zero velocity
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
    move.w d7, d2

    ; Probe for left-hand wall
    @SearchLeft:
    subi.w #VDP_SPRITE_BORDER_Y-PHYS_STEP_HEIGHT, d0 ; X - step height
    bsr    COL_ProbeTerrainLeft         ; Probe terrain map (search left)
    move.w d3, d6                       ; Backup tile flags/angle/quadrant
    POPM.L d0-d5/a0-a6

    cmp.w  #-1, d7                      ; d7 = terrain height, or -1
    beq    @EndTerrain
    addi.w #VDP_SPRITE_BORDER_X, d7     ; X back to sprite space
    swap   d7                           ; To 16.16, cap fraction
    move.w #0x0, d7
    cmp.l  d7, d0                       ; Check if right of wall
    bgt    @EndTerrain
    move.l d7, d0                       ; Hit terrain, cap X and zero velocity
    move.l #0x0, d2
    move.l #0x0, a5
    move.w d6, ECPhysicsBody_LastTerrainFlags(a3)   ; Store flags
    lsr.w  #0x8, d6                     ; Quadrant to terrain mode
    andi.b #0x3, d6
    move.b d6, ECPhysicsBody_TerrainQuadrant(a3)

    @EndTerrain:

    rts

testsin:
    incbin 'engine/sinewave.bin'
    even