; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 27th November 2019
; ============================================================================================
; CHOPPER.ASM - Sonic 1 razor fish
; ============================================================================================

; Chopper constants
ECHOPPER_IMPULSE_Y                      equ 0x00070000
ECHOPPER_GRAVITY                        equ 0x00001800
ECHOPPER_IDLE_TIME                      equ 60*3

; Chopper spawn data
    ENTITY_SPAWN_DATA_BEGIN EChopper
    ENTITY_SPAWN_DATA_END

; Chopper entity
    ENTITY_BEGIN EChopper
EChopper_StartPosY                      rs.w 1
EChopper_VelY                           rs.l 1
    ENT_COMPONENT ECSprite
    ENT_COMPONENT ECEnemy
    ENTITY_END

EChopper_Initialise:
    ; ======================================
    ; EChopper constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Initial state
    move.w Entity_PosY(a0), EChopper_StartPosY(a0)
    move.l #-ECHOPPER_IMPULSE_Y, EChopper_VelY(a0)

    ; Set palette
    ; TODO: Better palette management
    ENT_GETCOMPONENT EChopper,ECSprite,a0,a1
    move.w #0x2, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0

    ; Init enemy component
    ENT_GETCOMPONENT EChopper,ECEnemy,a0,a1
    move.w #EChopper_OnHit, ECEnemy_CallbackOnHit(a1)

    rts

EChopper_Shutdown:
    rts

EChopper_Update:
    ; ======================================
    ; EChopper movement path update
    ; ======================================
	; a0   Entity
    ; ======================================

    ; Apply gravity
    move.l EChopper_VelY(a0), d0
    addi.l #ECHOPPER_GRAVITY, d0

    ; Move
    move.l Entity_PosY(a0), d1
    add.l  d0, d1

    ; Dropped back to original pos?
    move.l EChopper_StartPosY(a0), d2
    cmp.l  d2, d1
    blt    @NoImpulse

    ; Impulse
    move.l #-ECHOPPER_IMPULSE_Y, d0
    move.l d2, d1

    ; Apply new position and velocity
    @NoImpulse:
    move.l d0, EChopper_VelY(a0)
    move.l d1, Entity_PosY(a0)

    rts

EChopper_OnHit:
    ; ======================================
    ; EChopper on player hit callback from
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

    PUSH.L a1

    ; If player spinning, take damage
    btst   #PLAYER_FLAG_SPINNING, EPlayer_StateFlags(a2)
    bne    @Spinning

    ; If player jumping, take damage and rebound player
    btst   #PLAYER_FLAG_JUMPING, EPlayer_StateFlags(a2)
    beq    @NotJumping
    ENT_GETCOMPONENT EPlayer,ECPhysBodyChar,a2,a1
    move.l ECPhysBodyChar_VelY(a1), d0
    neg.l  d0
    move.l d0, ECPhysBodyChar_VelY(a1)

    @Spinning:

    ; Despawn
    bsr    ENT_DespawnEntity

    ; Spawn explosion
    VFX_SPAWN VFXExplosion2,Entity_PosX(a0),Entity_PosY(a0)

    ; Spawn critter
    PUSHM.L a0-a2
    move.w Entity_PosX(a0), d0
    move.w Entity_PosY(a0), d1
    subi.w #EFLICKY_HEIGHT, d1
    move.w #EFLICKY_WIDTH, d2
    move.w #EFLICKY_HEIGHT, d3
    lea    EFlicky_TypeDesc, a0
    lea    EFlicky_Default_SpawnData, a1
    bsr    ENT_SpawnEntity
    POPM.L a0-a2
    
    @NotJumping:

    ; If player not spinning, deal damage to player

    POP.L  a1

    rts
