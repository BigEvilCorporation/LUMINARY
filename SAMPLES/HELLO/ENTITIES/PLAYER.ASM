; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 9th November 2019
; ============================================================================================
; PLAYER.ASM - Player entity component
; ============================================================================================

PLAYER_ANIM_IDLE                        equ 0
PLAYER_ANIM_WALK                        equ 1
PLAYER_ANIM_RUN                         equ 2
PLAYER_ANIM_JUMP                        equ 3
PLAYER_ANIM_COUNT                       equ 4

PLAYER_FLAG_JUMPING                     equ 0

PLAYER_ACCEL                            equ 0x0C00
PLAYER_ACCEL_AIR                        equ 0x1800
PLAYER_DECEL                            equ 0x0C00
PLAYER_DECEL_FORCED                     equ 0x7FFF
PLAYER_JUMP_VEL                         equ 0x00068000
PLAYER_MAX_VEL_X                 		equ 0x00060000
PLAYER_WALK_TO_RUN_VEL                  equ 0x00030000

PlayerSpriteAnimTable:
    dc.l   actor_sonic_spritesheet_idle, 0x0
    dc.l   actor_sonic_spritesheet_walk, actor_sonic_sheet_walk_anim_walk
    dc.l   actor_sonic_spritesheet_run,  actor_sonic_sheet_run_anim_run
    dc.l   actor_sonic_spritesheet_jump, actor_sonic_sheet_jump_anim_jump

SPRITE_ANIM_FROM_TABLE: macro table,index,sheet_addr,anim_addr
    ; =================================================
    ; Retrives sprite sheet and animation addresses
    ; from an animation table, given a table and index
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

    ENTITY_SPAWN_DATA_BEGIN EPlayer
;SDPlayer_SomeArbitrarySpawnData         rs.l 1
    ENTITY_SPAWN_DATA_END

    ENTITY_BEGIN EPlayer
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

    ; Read input
    bsr    PAD_ReadPortA
    move.w RAM_GAMEPAD_PREV_1, d7       ; For debounce
    move.w d0, RAM_GAMEPAD_PREV_1       ; Backup prev state

    ; Apply acceleration/forced deceleration
    btst   #PAD_BUTTON_LEFT, d0
    beq    @EndLeft
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6    ; Check on terrain
    beq    @InAirLeft
    tst.w  d2                                   ; Check if forcing opposite direction
    bgt    @AccelForceLeft
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
    move.w #PLAYER_ACCEL, d1                    ; Just use plain ground accel
    bra    @EndRight
    @AccelForceRight:
    move.w #PLAYER_DECEL_FORCED, d1             ; Forcing opposite direction, use force decel
    bra    @EndRight
    @InAirRight:                                ; In air, use air accel
    move.w #PLAYER_ACCEL_AIR, d1
    bra    @EndRight
    @EndRight:

    move.w d1, ECPhysicsBody_AccelX(a1)

    ; If in jump state and on floor, clear jump flag
    btst   #PLAYER_FLAG_JUMPING, d5
    beq    @EndJumpClear
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d6
    beq    @EndJumpClear
    bclr   #PLAYER_FLAG_JUMPING, d5
    @EndJumpClear:

    ; Jump
    btst   #PAD_BUTTON_B, d0
    beq    @NoB
    btst   #PAD_BUTTON_B, d7
    bne    @NoB
    bsr    EPlayer_Jump
    @NoB:

    ; Store flags
    move.b d5, EPlayer_StateFlags(a0)
    move.w d6, ECPhysicsBody_LastTerrainFlags(a1)

    ; Debug draw
    move.w ECPhysicsBody_LastTerrainFlags(a1), d7
    DBG_DRAW_WORD #8,#8,d7
    move.b ECPhysicsBody_TerrainQuadrant(a1), d7
    DBG_DRAW_BYTE #8,#9,d7

    ; Backup physics component
    move.l a1, a3

    ; Determine animation
    btst   #PLAYER_FLAG_JUMPING, d5
    bne    @Jumping

    move.l ECPhysicsBody_VelX(a1), d0
    tst.l  d0
    bne    @Moving

    ; Idle
    SPRITE_ANIM_FROM_TABLE PlayerSpriteAnimTable, PLAYER_ANIM_IDLE, a1, a2
    bra    @SetAnim

    ; Jumping
    @Jumping:
    SPRITE_ANIM_FROM_TABLE PlayerSpriteAnimTable, PLAYER_ANIM_JUMP, a1, a2
    bra    @SetAnim

    @Moving:

    move.l d0, d2
    ABS.L  d2
    cmp.l  #PLAYER_WALK_TO_RUN_VEL, d2
    bgt    @Running

    ; Walking
    SPRITE_ANIM_FROM_TABLE PlayerSpriteAnimTable, PLAYER_ANIM_WALK, a1, a2
    bra    @SetAnim

    @Running:

    ; Running
    SPRITE_ANIM_FROM_TABLE PlayerSpriteAnimTable, PLAYER_ANIM_RUN, a1, a2
    bra    @SetAnim

    ; Load animation
    @SetAnim:
    ENT_GETCOMPONENT EPlayer,ECSprite,a0,a0 ; Get sprite component
    bsr    ECSprite_LoadAnimation           ; Load animation

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