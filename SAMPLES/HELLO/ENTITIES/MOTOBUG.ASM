; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 27th November 2019
; ============================================================================================
; MOTOBUG.ASM - Sonic 1 Motobug enemy
; ============================================================================================

; Motobug constants
EMOTOBUG_VEL_X                          equ 0x0001
EMOTOBUG_IDLE_TIME                      equ 60*3

; Motobug spawn data
    ENTITY_SPAWN_DATA_BEGIN EMotobug
    ENTITY_SPAWN_DATA_END

; Motobug entity
    ENTITY_BEGIN EMotobug
EMotobug_IdleTimer                      rs.w 1
EMotoBug_VelX                           rs.w 1
    ENT_COMPONENT ECSprite
    ENT_COMPONENT ECEnemy
    ENTITY_END

EMotobug_Initialise:
    ; ======================================
    ; EMotobug constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Initial state
    move.w #0x0, EMotobug_IdleTimer(a0)
    move.w #-EMOTOBUG_VEL_X, EMotoBug_VelX(a0)

    ; Set palette
    ; TODO: Better palette management
    ENT_GETCOMPONENT EMotobug,ECSprite,a0,a1
    move.w #0x2, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0

    ; Init enemy component
    ENT_GETCOMPONENT EMotobug,ECEnemy,a0,a1
    move.l #EMotobug_OnHit, ECEnemy_CallbackOnHit(a1)

    rts

EMotobug_Shutdown:
    rts

EMotobug_Update:
    ; ======================================
    ; EMotobug movement path update
    ; ======================================
	; a0   Entity
    ; ======================================

    ; Process idle timer
    move.w EMotobug_IdleTimer(a0), d0
    tst.w  d0
    beq    @Moving
    subi.w #0x1, d0
    move.w d0, EMotobug_IdleTimer(a0)
    beq    @TimerElapsed

    rts

    @TimerElapsed:

    ; Switch direction and start moving again
    move.w EMotoBug_VelX(a0), d0
    neg.w  d0
    move.w d0, EMotoBug_VelX(a0)

    ; Set sprite flip
    ENT_GETCOMPONENT EMotobug,ECSprite,a0,a1
    rol.w  #0x1, d0
    eor.b  #0x1, d0
    SPRITE_COMPONENT_SETFLIPX_REG a1,d0

    ; Restart animation
    move.l ECSprite_Animation(a1), a2
    move.w SpriteAnim_DefaultSpeed(a2), ECSprite_AnimSpeed(a1)

    @Moving:

    ; Move
    move.w EMotoBug_VelX(a0), d0
    add.w  d0, Entity_PosX(a0)

    ; Check floor
    PUSH.L a0
    move.l a0, a3
    move.l RAM_SCENE_DATA, a4
    move.l SceneData_ColMap(a4), a0
    move.l SceneData_ColStampset(a4), a1
    move.l SceneData_ColTileset(a4), a2
    move.w SceneData_ColMapWidthStamps(a4), d2
    bsr    PHYS_EntityFindFloor
    POP.L  a0
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d3
    beq    @NoTerrain

    ; Snap to floor
    move.w d7, Entity_PosY(a0)
    
    rts

    @NoTerrain:

    ; No terrain, stop moving and initialise idle timer
    move.l #0x0, ECPhysBodyBasic_VelX(a1)
    move.w #EMOTOBUG_IDLE_TIME, EMotobug_IdleTimer(a0)

    ; Stop animation
    ENT_GETCOMPONENT EMotobug,ECSprite,a0,a1
    move.w #0x0, ECSprite_AnimSpeed(a1)

    rts

EMotobug_OnHit:
    ; ======================================
    ; EMotobug on player hit callback from
    ; ECEnemy_CheckHit
    ; ======================================
    ; In:
	;   a0    Entity
    ;   a1    ECEnemy component
    ;   a2    Player
    ;   d1.ww Player top left bounds
    ;   d2.ww Player bottom right bounds
    ;   d3.ww Player top left bounds
    ;   d4.ww Player bottom right bounds
    ; Out:
    ;   d5.b  Damage taken from player
    ;   d6.b  Damage dealt to player
    ; ======================================

    ; If player rolling, take damage

    ; If player not rolling, deal damage

    rts
