; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 27th November 2019
; ============================================================================================
; MOTOBUG.ASM - Sonic 1 Motobug enemy
; ============================================================================================

; Motobug constants
EMOTOBUG_VEL_X                          equ 0x00010000
EMOTOBUG_IDLE_TIME                      equ 60*3

; Motobug spawn data
    ENTITY_SPAWN_DATA_BEGIN EMotobug
    ENTITY_SPAWN_DATA_END

; Motobug entity
    ENTITY_BEGIN EMotobug
EMotobug_IdleTimer                      rs.w 1
EMotobug_Direction                      rs.b 1
	ENT_COMPONENT ECPhysBodyBasic
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
    move.b #-1, EMotobug_Direction(a0)

    ; Set palette
    ; TODO: Better palette management
    ENT_GETCOMPONENT EPlayer,ECSprite,a0,a1
    move.w #0x2, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0

    ; Init physics component
    ENT_GETCOMPONENT EMotobug,ECPhysBodyBasic,a0,a1
    move.l #EMOTOBUG_VEL_X, ECPhysBodyBasic_MaxVelX(a1)
    move.l #-EMOTOBUG_VEL_X, ECPhysBodyBasic_MaxVelX(a1)

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
    bne    @End

    ; Switch direction and start moving again
    move.b EMotobug_Direction(a0), d0
    ext.w  d0
    mulu.w #-1, d0
    move.l #EMOTOBUG_VEL_X, d1
    move.b d0, EMotobug_Direction(a0)
    bgt    @MoveRight
    neg.l  d1
    @MoveRight:
    move.l d0, ECPhysBodyBasic_MaxVelX(a1)

    ; Set moving animation

    @Moving:

    ; Move until no floor found
    ENT_GETCOMPONENT EMotobug,ECPhysBodyBasic,a0,a1
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, ECPhysBodyBasic_LastTerrainFlags(a1)
    beq    @End

    ; No terrain, stop moving and initialise idle timer
    move.l #0x0, ECPhysBodyBasic_VelX(a1)
    move.w #EMOTOBUG_IDLE_TIME, EMotobug_IdleTimer(a0)

    ; Set idle animation

    @End:

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
