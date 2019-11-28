; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 9th November 2019
; ============================================================================================
; PLAYER.ASM - Player entity component
; ============================================================================================

PLAYER_ANIM_IDLE                        equ 0
PLAYER_ANIM_WALK                        equ 1
PLAYER_ANIM_WALK_45                     equ 2
PLAYER_ANIM_WALK_90                     equ 3
PLAYER_ANIM_WALK_135                    equ 4
PLAYER_ANIM_RUN                         equ 5
PLAYER_ANIM_RUN_45                      equ 6
PLAYER_ANIM_RUN_90                      equ 7
PLAYER_ANIM_RUN_135                     equ 8
PLAYER_ANIM_JUMP                        equ 9
PLAYER_ANIM_COUNT                       equ 10

PLAYER_FLAG_JUMPING                     equ 0
PLAYER_FLAG_SPINNING                    equ 1

PLAYER_ACCEL                            equ 0x0C00
PLAYER_ACCEL_AIR                        equ 0x1800
PLAYER_DECEL                            equ 0x0C00
PLAYER_DECEL_FORCED                     equ 0x7FFF
PLAYER_DECEL_SPIN                       equ 0x0600
PLAYER_SLOPE_FACTOR                     equ 0x2000>>PHYS_VEL_TO_GROUND_SPEED_SHIFT
PLAYER_SLOPE_FACTOR_SPIN_UP             equ 0x1400>>PHYS_VEL_TO_GROUND_SPEED_SHIFT
PLAYER_SLOPE_FACTOR_SPIN_DN             equ 0x5000>>PHYS_VEL_TO_GROUND_SPEED_SHIFT
PLAYER_JUMP_VEL                         equ 0x00068000
PLAYER_MAX_VEL_X                 		equ 0x00060000
PLAYER_MAX_VEL_X_SPIN            		equ 0x00160000
PLAYER_WALK_TO_RUN_VEL                  equ 0x00030000

PLAYER_SPIN_MIN_SPEED                   equ 0x00008000

PlayerSpriteAnimTable:
    dc.l   actor_sonic_spritesheet_idle, 0x0
    dc.l   actor_sonic_spritesheet_walk, actor_sonic_sheet_walk_anim_walk
    dc.l   actor_sonic_spritesheet_walk_45, actor_sonic_sheet_walk_45_anim_walk_45
    dc.l   actor_sonic_spritesheet_walk_90, actor_sonic_sheet_walk_90_anim_walk_90
    dc.l   actor_sonic_spritesheet_walk_135, actor_sonic_sheet_walk_135_anim_walk_135
    dc.l   actor_sonic_spritesheet_run,  actor_sonic_sheet_run_anim_run
    dc.l   actor_sonic_spritesheet_run_45,  actor_sonic_sheet_run_45_anim_run_45
    dc.l   actor_sonic_spritesheet_run_90,  actor_sonic_sheet_run_90_anim_run_90
    dc.l   actor_sonic_spritesheet_run_135,  actor_sonic_sheet_run_135_anim_run_135
    dc.l   actor_sonic_spritesheet_jump, actor_sonic_sheet_jump_anim_jump

PlayerSpriteAnimWalkAngleTable_CW:
    dc.b   PLAYER_ANIM_WALK,        0x1, 0x0   ; 00
    dc.b   PLAYER_ANIM_WALK_45,     0x1, 0x0   ; 10
    dc.b   PLAYER_ANIM_WALK_45,     0x1, 0x0   ; 20
    dc.b   PLAYER_ANIM_WALK_90,     0x1, 0x0   ; 30
    dc.b   PLAYER_ANIM_WALK_90,     0x1, 0x0   ; 40
    dc.b   PLAYER_ANIM_WALK_135,    0x1, 0x0   ; 50
    dc.b   PLAYER_ANIM_WALK_135,    0x1, 0x0   ; 60
    dc.b   PLAYER_ANIM_WALK,        0x0, 0x1   ; 70
    dc.b   PLAYER_ANIM_WALK,        0x0, 0x1   ; 80
    dc.b   PLAYER_ANIM_WALK_45,     0x0, 0x1   ; 90
    dc.b   PLAYER_ANIM_WALK_45,     0x0, 0x1   ; A0
    dc.b   PLAYER_ANIM_WALK_90,     0x0, 0x1   ; B0
    dc.b   PLAYER_ANIM_WALK_90,     0x0, 0x1   ; C0
    dc.b   PLAYER_ANIM_WALK_135,    0x0, 0x1   ; D0
    dc.b   PLAYER_ANIM_WALK_135,    0x0, 0x1   ; E0
    dc.b   PLAYER_ANIM_WALK,        0x1, 0x0   ; F0
    even

PlayerSpriteAnimWalkAngleTable_CCW:
    dc.b   PLAYER_ANIM_WALK,        0x0, 0x0   ; 00
    dc.b   PLAYER_ANIM_WALK_135,    0x1, 0x1   ; 10
    dc.b   PLAYER_ANIM_WALK_135,    0x1, 0x1   ; 20
    dc.b   PLAYER_ANIM_WALK_90,     0x1, 0x1   ; 30
    dc.b   PLAYER_ANIM_WALK_90,     0x1, 0x1   ; 40
    dc.b   PLAYER_ANIM_WALK_45,     0x1, 0x1   ; 50
    dc.b   PLAYER_ANIM_WALK_45,     0x1, 0x1   ; 60
    dc.b   PLAYER_ANIM_WALK,        0x1, 0x1   ; 70
    dc.b   PLAYER_ANIM_WALK,        0x1, 0x1   ; 80
    dc.b   PLAYER_ANIM_WALK_135,    0x0, 0x0   ; 90
    dc.b   PLAYER_ANIM_WALK_135,    0x0, 0x0   ; A0
    dc.b   PLAYER_ANIM_WALK_90,     0x0, 0x0   ; B0
    dc.b   PLAYER_ANIM_WALK_90,     0x0, 0x0   ; C0
    dc.b   PLAYER_ANIM_WALK_45,     0x0, 0x0   ; D0
    dc.b   PLAYER_ANIM_WALK_45,     0x0, 0x0   ; E0
    dc.b   PLAYER_ANIM_WALK,        0x0, 0x0   ; F0
    even

PlayerSpriteAnimRunAngleTable_CW:
    dc.b   PLAYER_ANIM_RUN,         0x1, 0x0   ; 00
    dc.b   PLAYER_ANIM_RUN_45,      0x1, 0x0   ; 10
    dc.b   PLAYER_ANIM_RUN_45,      0x1, 0x0   ; 20
    dc.b   PLAYER_ANIM_RUN_90,      0x1, 0x0   ; 30
    dc.b   PLAYER_ANIM_RUN_90,      0x1, 0x0   ; 40
    dc.b   PLAYER_ANIM_RUN_135,     0x1, 0x0   ; 50
    dc.b   PLAYER_ANIM_RUN_135,     0x1, 0x0   ; 60
    dc.b   PLAYER_ANIM_RUN,         0x0, 0x1   ; 70
    dc.b   PLAYER_ANIM_RUN,         0x0, 0x1   ; 80
    dc.b   PLAYER_ANIM_RUN_45,      0x0, 0x1   ; 90
    dc.b   PLAYER_ANIM_RUN_45,      0x0, 0x1   ; A0
    dc.b   PLAYER_ANIM_RUN_90,      0x0, 0x1   ; B0
    dc.b   PLAYER_ANIM_RUN_90,      0x0, 0x1   ; C0
    dc.b   PLAYER_ANIM_RUN_135,     0x0, 0x1   ; D0
    dc.b   PLAYER_ANIM_RUN_135,     0x0, 0x1   ; E0
    dc.b   PLAYER_ANIM_RUN,         0x1, 0x0   ; F0
    even

PlayerSpriteAnimRunAngleTable_CCW:
    dc.b   PLAYER_ANIM_RUN,         0x0, 0x0   ; 00
    dc.b   PLAYER_ANIM_RUN_135,     0x1, 0x1   ; 10
    dc.b   PLAYER_ANIM_RUN_135,     0x1, 0x1   ; 20
    dc.b   PLAYER_ANIM_RUN_90,      0x1, 0x1   ; 30
    dc.b   PLAYER_ANIM_RUN_90,      0x1, 0x1   ; 40
    dc.b   PLAYER_ANIM_RUN_45,      0x1, 0x1   ; 50
    dc.b   PLAYER_ANIM_RUN_45,      0x1, 0x1   ; 60
    dc.b   PLAYER_ANIM_RUN,         0x1, 0x1   ; 70
    dc.b   PLAYER_ANIM_RUN,         0x1, 0x1   ; 80
    dc.b   PLAYER_ANIM_RUN_135,     0x0, 0x0   ; 90
    dc.b   PLAYER_ANIM_RUN_135,     0x0, 0x0   ; A0
    dc.b   PLAYER_ANIM_RUN_90,      0x0, 0x0   ; B0
    dc.b   PLAYER_ANIM_RUN_90,      0x0, 0x0   ; C0
    dc.b   PLAYER_ANIM_RUN_45,      0x0, 0x0   ; D0
    dc.b   PLAYER_ANIM_RUN_45,      0x0, 0x0   ; E0
    dc.b   PLAYER_ANIM_RUN,         0x0, 0x0   ; F0
    even

SPRITE_ANIM_FROM_TABLE_I: macro table,index,sheet_addr,anim_addr
    ; =================================================
    ; Retrives sprite sheet and animation addresses
    ; from an animation table, given a table and index,
    ; from immediate index
    ; =================================================
    ;  table      - Const address of animation table
    ;  index      - Const animation index
    ; Out:
    ;  sheet_addr - Sprite sheet address reg
    ;  anim_addr  - Animation address reg
    ; =================================================
    move.l \table+(\index*SIZE_LONG*2), \sheet_addr
    move.l \table+(\index*SIZE_LONG*2)+SIZE_LONG, \anim_addr
    endm

SPRITE_ANIM_FROM_TABLE_R: macro table,index_reg,sheet_addr,anim_addr
    ; =================================================
    ; Retrives sprite sheet and animation addresses
    ; from an animation table, given a table and index,
    ; from register index
    ; =================================================
    ;  table      - Const address of animation table
    ;  index.b    - Animation index register
    ; Out:
    ;  sheet_addr - Sprite sheet address reg
    ;  anim_addr  - Animation address reg
    ; =================================================
    andi.l #0xFF, \index_reg
    lsl.w  #0x3, \index_reg
    lea    \table, \sheet_addr
    lea    \table, \anim_addr
    adda.w \index_reg, \sheet_addr
    adda.w \index_reg, \anim_addr
    adda.w #SIZE_LONG, \anim_addr
    move.l (\sheet_addr), \sheet_addr
    move.l (\anim_addr), \anim_addr
    endm

    ENTITY_SPAWN_DATA_BEGIN EPlayer
;SDPlayer_SomeArbitrarySpawnData         rs.l 1
    ENTITY_SPAWN_DATA_END

    ENTITY_BEGIN EPlayer
EPlayer_TerrainFlagsPrev                rs.w 1
EPlayer_StateFlags                      rs.b 1
	ENT_COMPONENT ECPhysicsBody
    ENT_COMPONENT ECSprite
    ENTITY_END

EPlayer_Initialise:
    ; ======================================
    ; EPlayer constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Initialise
    move.w #0x0, EPlayer_TerrainFlagsPrev(a0)
    move.b #0x0, EPlayer_StateFlags(a0)

    ; Set as camera target
    move.l RAM_CAMERA_CURRENT, a2
    cmpa.l #0x0, a2
    beq    @NoCam
    move.l a0, Camera_TargetEntity(a2)
    @NoCam:

    ENT_GETCOMPONENT EPlayer,ECSprite,a0,a2
    move.w #0x3, d0
    SPRITE_COMPONENT_SETPALETTE_REG a2,d0

    ; Init player's physics component
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a0
    move.l #PLAYER_MAX_VEL_X, ECPhysicsBody_MaxVelX(a0)
    move.w #PLAYER_DECEL, ECPhysicsBody_DecelX(a0)

    rts

EPlayer_Shutdown:
    rts

EPlayer_Update:
    ; ======================================
    ; EPlayer update
    ; ======================================
	; a0   Entity
    ; ======================================

    move.l #0x0, d1
    move.l #0x0, d2
    
    ; Get physics component
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a1

    ; Get ground speed
    move.w ECPhysicsBody_GroundSpeed(a1), d2

    ; Get player state and current terrain flags
    move.b EPlayer_StateFlags(a0), d5
    move.w ECPhysicsBody_LastTerrainFlags(a1), d6

    ; Handle input
    bsr    EPlayer_UpdateInput

    ; Update state
    bsr    EPlayer_UpdateState

    ; Store updated flags
    move.b d5, EPlayer_StateFlags(a0)
    move.w d6, ECPhysicsBody_LastTerrainFlags(a1)

    ; Store prev collision flags
    move.w d6, EPlayer_TerrainFlagsPrev(a0)

    ; Update animation from current state
    bsr    EPlayer_UpdateAnimation

    ; Collision check against enemies
    ENT_GETBOUNDS a0,d1,d2
    PUSH.L a0
    move.l a0, a2
    bsr    ECEnemy_CheckHitAll
    POP.L  a0

    rts

    ; Debug draw
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a1
    move.w ECPhysicsBody_LastTerrainFlags(a1), d7
    DBG_DRAW_WORD #100,#8,d7
    move.b ECPhysicsBody_TerrainQuadrant(a1), d7
    DBG_DRAW_BYTE #100,#9,d7

    rts

EPlayer_UpdateInput:
    ; ======================================
    ; Sets movement state from input
    ; ======================================
    ; In:
    ;  a0   Entity
    ;  a1   ECPhysicsBody
    ;  d5.b Player state flags
    ;  d6.w Terrain flags
    ; Out:
    ;  d5.b Player state flags
    ;  d6.w Terrain flags
    ; ======================================

    ; Read input
    bsr    PAD_ReadPortA
    move.w RAM_GAMEPAD_PREV_1, d7       ; For debounce
    move.w d0, RAM_GAMEPAD_PREV_1       ; Backup prev state

    ; If pressing down, spin
    btst   #PAD_BUTTON_DOWN, d0
    beq    @EndDown
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6    ; If on floor
    beq    @EndDown
    move.w ECPhysicsBody_GroundSpeed(a1), d4    ; If ground speed > threshold
    ABS.W  d4
    cmp.w  #PLAYER_SPIN_MIN_SPEED>>8, d4
    blt    @EndDown
    bset   #PLAYER_FLAG_SPINNING, d5            ; Spinning
    move.l #PLAYER_MAX_VEL_X_SPIN, ECPhysicsBody_MaxVelX(a1)    ; Set spinning max vel
    move.w #PLAYER_DECEL_SPIN, ECPhysicsBody_DecelX(a1)         ; Set spinning deceleration
    move.w #PLAYER_SLOPE_FACTOR_SPIN_DN, ECPhysicsBody_SlopeFact(a1) ; Set spinning slope factor
    @EndDown:

    ; Apply acceleration/forced deceleration
    btst   #PAD_BUTTON_LEFT, d0
    beq    @EndLeft
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6    ; Check on terrain
    beq    @InAirLeft
    tst.w  d2                                   ; Check if forcing opposite direction
    bgt    @AccelForceLeft
    btst   #PLAYER_FLAG_SPINNING, d5            ; Can't accel if spinning
    bne    @EndLeft
    move.w #-PLAYER_ACCEL, d1                   ; Just use plain ground accel
    bra    @EndLeft
    @AccelForceLeft:
    move.w #-PLAYER_DECEL_FORCED, d1            ; Forcing opposite direction, use force decel
    bra    @EndLeft
    @InAirLeft:                                 ; In air, use air accel
    move.w #-PLAYER_ACCEL_AIR, d1
    bra    @EndLeft
    @EndLeft:

    btst   #PAD_BUTTON_RIGHT, d0
    beq    @EndRight
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6    ; Check on terrain
    beq    @InAirRight
    tst.w  d2                                   ; Check if forcing opposite direction
    blt    @AccelForceRight
    btst   #PLAYER_FLAG_SPINNING, d5            ; Can't accel if spinning
    bne    @EndRight
    move.w #PLAYER_ACCEL, d1                    ; Just use plain ground accel
    bra    @EndRight
    @AccelForceRight:
    move.w #PLAYER_DECEL_FORCED, d1             ; Forcing opposite direction, use force decel
    bra    @EndRight
    @InAirRight:                                ; In air, use air accel
    move.w #PLAYER_ACCEL_AIR, d1
    bra    @EndRight
    @EndRight:

    ; Set new acceleration
    move.w d1, ECPhysicsBody_AccelX(a1)

    ; Jump
    btst   #PAD_BUTTON_B, d0
    beq    @NoB
    btst   #PAD_BUTTON_B, d7
    bne    @NoB
    bsr    EPlayer_Jump
    @NoB:

    rts

EPlayer_UpdateState:
    ; ======================================
    ; Updates current state
    ; ======================================
    ; In:
    ;  a0   Entity
    ;  a1   ECPhysicsBody
    ;  d5.b Player state flags
    ;  d6.w Terrain flags
    ; Out:
    ;  d5.b Player state flags
    ;  d6.w Terrain flags
    ; ======================================

    ; If in jump state and on floor, clear jump flag
    btst   #PLAYER_FLAG_JUMPING, d5
    beq    @EndJumpClear
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6
    beq    @EndJumpClear
    bclr   #PLAYER_FLAG_JUMPING, d5                 ; Reset jump flag
    @EndJumpClear:

    ; If in spin state
    btst   #PLAYER_FLAG_SPINNING, d5
    beq    @EndSpinClear

    ; Update slope factor based on terrain angle sign
    moveq  #0x0, d7
    move.b d6, d7                       ; Extract angle from flags
    subi.b #PHYS_TERRAIN_ANGLE_90, d7   ; -90 degrees
    add.w  d7, d7
    lea    sinetable, a4
    moveq  #0x0, d3
    move.w (a4,d7.w), d3
    tst.w  d3
    bge    @SlopeUp
    move.w #PLAYER_SLOPE_FACTOR_SPIN_DN, ECPhysicsBody_SlopeFact(a1)
    bra    @SlopeDown
    @SlopeUp:
    move.w #PLAYER_SLOPE_FACTOR_SPIN_UP, ECPhysicsBody_SlopeFact(a1)
    @SlopeDown:

    ; If velocity ground speed too low, or just landed, clear spin flag
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6
    beq    @EndSpinClear
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, EPlayer_TerrainFlagsPrev(a0) ; If hit ground this frame
    beq    @HitGround
    move.w ECPhysicsBody_GroundSpeed(a1), d4                ; or if ground speed > threshold
    ABS.W  d4
    cmp.w  #PLAYER_SPIN_MIN_SPEED>>8, d4
    bge    @EndSpinClear
    @HitGround:
    bclr   #PLAYER_FLAG_SPINNING, d5                        ; Reset spin flag
    move.l #PLAYER_MAX_VEL_X, ECPhysicsBody_MaxVelX(a1)     ; Reset max vel
    move.w #PLAYER_DECEL, ECPhysicsBody_DecelX(a1)          ; Reset deceleration
    move.w #PLAYER_SLOPE_FACTOR, ECPhysicsBody_SlopeFact(a1); Reset slope factor
    @EndSpinClear:

    rts

EPlayer_UpdateAnimation:
    ; ======================================
    ; Sets animation from current state
    ; ======================================
    ; In:
    ;  a0   Entity
    ;  a1   ECPhysicsBody
    ;  d5.b Player state flags
    ;  d6.w Terrain flags
    ; ======================================

    ; Backup physics component
    move.l a1, a3

    ; Determine animation
    btst   #PLAYER_FLAG_JUMPING, d5
    bne    @Jumping

    btst   #PLAYER_FLAG_SPINNING, d5
    bne    @Spinning

    move.w ECPhysicsBody_GroundSpeed(a1), d0
    tst.w  d0
    bne    @Moving

    ; Idle
    SPRITE_ANIM_FROM_TABLE_I PlayerSpriteAnimTable, PLAYER_ANIM_IDLE, a1, a2
    bra    @SetAnim

    ; Jumping
    @Jumping:
    SPRITE_ANIM_FROM_TABLE_I PlayerSpriteAnimTable, PLAYER_ANIM_JUMP, a1, a2
    bra    @SetAnim

    ; Spinning
    @Spinning:
    SPRITE_ANIM_FROM_TABLE_I PlayerSpriteAnimTable, PLAYER_ANIM_JUMP, a1, a2
    bra    @SetAnim

    @Moving:

    move.w d0, d2
    ABS.W  d2
    cmp.w  #PLAYER_WALK_TO_RUN_VEL>>8, d2
    bgt    @Running

    ; Walking
    bsr    EPlayer_GetWalkAnim
    bra    @SetAngleAnim

    @Running:

    ; Running
    bsr    EPlayer_GetRunAnim
    bra    @SetAngleAnim

    ; Load animation (without flip flags)
    @SetAnim:
    PUSH.L a0
    ENT_GETCOMPONENT EPlayer,ECSprite,a0,a0 ; Get sprite component
    bsr    ECSprite_LoadAnimation           ; Load animation

    ; Reset Y flip flag
    move.b #0x0, d1
    SPRITE_COMPONENT_SETFLIPY_REG a0,d1     ; Reset Y flip

    ; Set X flip flag
    move.b #0x0, d1
    move.l ECPhysicsBody_VelX(a3), d2
    tst.l  ECPhysicsBody_VelX(a3)
    beq    @NoFlipChange
    bgt    @FaceRight
    move.b #0x1, d1
    @FaceRight:
    SPRITE_COMPONENT_SETFLIPX_REG a0,d1     ; Set flip X flag
    @NoFlipChange:
    POP.L  a0

    rts

    ; Load animation (with flip flags)
    @SetAngleAnim:
    PUSH.L a0
    ENT_GETCOMPONENT EPlayer,ECSprite,a0,a0 ; Get sprite component
    SPRITE_COMPONENT_SETFLIPX_REG a0,d1     ; Set flip flags
    SPRITE_COMPONENT_SETFLIPY_REG a0,d2
    bsr    ECSprite_LoadAnimation           ; Load animation
    POP.L  a0

    rts

    ; ======================================
    ; Eplayer_GetWalk/Run/AngleAnim
    ; ======================================
    ; In:
    ;  a0   Entity
    ;  a1   ECPhysicsBody
    ; Out:
    ;  a1   Sprite sheet
    ;  a2   Sprite anim
    ;  d1.b X flip
    ;  d2.b Y flip
    ; ======================================
EPlayer_GetWalkAnim:
    tst.w  ECPhysicsBody_GroundSpeed(a1)
    blt    @CW
    lea    PlayerSpriteAnimWalkAngleTable_CCW, a2   ; Angle-to-anim table (counter clockwise)
    bra    Eplayer_GetAngleAnim
    @CW:
    lea    PlayerSpriteAnimWalkAngleTable_CW, a2    ; Angle-to-anim table (clockwise)
    bra    Eplayer_GetAngleAnim
EPlayer_GetRunAnim:
    tst.w  ECPhysicsBody_GroundSpeed(a1)
    blt    @CW
    lea    PlayerSpriteAnimRunAngleTable_CCW, a2    ; Angle-to-anim table (counter clockwise)
    bra    Eplayer_GetAngleAnim
    @CW:
    lea    PlayerSpriteAnimRunAngleTable_CW, a2     ; Angle-to-anim table (clockwise)
    bra    Eplayer_GetAngleAnim
Eplayer_GetAngleAnim:
    move.w ECPhysicsBody_LastTerrainFlags(a1), d0   ; Player terrain angle
    lsr.b  #0x4, d0                                 ; Segment as anim index
    andi.w #0x000F, d0
    mulu.w #0x3, d0
    adda.w d0, a2
    move.b (a2)+, d0                                ; Get anim index
    move.b (a2)+, d1                                ; Get X flip
    move.b (a2)+, d2                                ; Get Y flip
    SPRITE_ANIM_FROM_TABLE_R PlayerSpriteAnimTable, d0, a1, a2
    rts

EPlayer_Jump:
    ; ======================================
    ; EPlayer jump
    ; ======================================
    ; In:
    ;  a0   Entity
    ;  a1   ECPhysicsBody
    ; In/out:
    ;  d5.b PLAYER_FLAG_*
    ;  d6.b COLLISION_FLAG_*
    ; ======================================

    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6 ; Check on terrain
    beq    @NotOnFloor

    moveq  #0x0, d7
    move.b d6, d7                       ; Extract angle from flags
    subi.b #PHYS_TERRAIN_ANGLE_90, d7   ; -90 degrees
    add.w  d7, d7

    lea    sinetable, a4                ; Jump angle to y vel
    moveq  #0x0, d3
    move.w (a4,d7.w), d3
    muls   #PLAYER_JUMP_VEL>>8, d3      ; Ground speed values >> 8
    add.l  d3, ECPhysicsBody_VelY(a1)
            
    addi.w #SINE_TBL_COS_OFFS, d7		; Jump angle to x vel
    moveq  #0x0, d3
    move.w (a4,d7.w), d3
    muls   #PLAYER_JUMP_VEL>>8, d3      ; Ground speed values >> 8
    add.l  d3, ECPhysicsBody_VelX(a1)

    ; Set jump flag
    bset   #PLAYER_FLAG_JUMPING, d5

    ; Clear terrain floor flag
    bclr   #COLLISION_FLAG_BIT_TERRAIN_W, d6

    @NotOnFloor:

    rts