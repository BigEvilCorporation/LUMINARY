; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 27th November 2019
; ============================================================================================
; MOTOBUG.ASM - Sonic 1 Motobug enemy
; ============================================================================================

; Motobug constants
EMOTOBUG_MAX_VEL_X                      equ 0x00010000
EMOTOBUG_ACCEL                          equ 0x2000
EMOTOBUG_DECEL                          equ 0x2000

; State machine
EMOTOBUG_STATE_IDLE                     equ 0x0
EMOTOBUG_STATE_MOVE                     equ 0x1

; Motobug spawn data
    ENTITY_SPAWN_DATA_BEGIN EMotobug
    ENTITY_SPAWN_DATA_END

; Motobug entity
    ENTITY_BEGIN EMotobug
EMotobug_StateTimer                     rs.w 1
EMotobug_State                          rs.b 1
	ENT_COMPONENT ECPhysicsBody
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

    ; Set palette
    ; TODO: Better palette management
    ENT_GETCOMPONENT EPlayer,ECSprite,a0,a1
    move.w #0x2, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0

    ; Init physics component
    ENT_GETCOMPONENT EMotobug,ECPhysicsBody,a0,a1
    move.l #EMOTOBUG_MAX_VEL_X, ECPhysicsBody_MaxVelX(a1)
    move.w #EMOTOBUG_DECEL, ECPhysicsBody_DecelX(a1)

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
