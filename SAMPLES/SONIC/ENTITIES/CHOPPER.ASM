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
