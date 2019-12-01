; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 30th November 2019
; ============================================================================================
; RING.ASM - Sonic ring
; ============================================================================================

; Ring constants
ERING_WIDTH                           equ 0x10
ERING_HEIGHT                          equ 0x10

; Ring spawn data
    ENTITY_SPAWN_DATA_BEGIN ERing
    ENTITY_SPAWN_DATA_END

; Ring entity
    ENTITY_BEGIN ERing
    ENT_COMPONENT ECSprite
    ENTITY_END

ERing_Initialise:
    ; ======================================
    ; ERing constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Set palette
    ; TODO: Better palette management
    ENT_GETCOMPONENT ERing,ECSprite,a0,a1
    move.w #0x2, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0

    rts

ERing_Shutdown:
    rts

ERing_Update:
    ; ======================================
    ; ERing movement path update
    ; ======================================
	; a0   Entity
    ; ======================================

    ; Get player
    move.l RAM_PLAYER_1, a1

    ; Check bounds
    ENT_GETBOUNDS a0,d1,d2
    ENT_GETBOUNDS a1,d3,d4
    bsr    GEOM_BoxIntersectBox
    tst.b  d0
    beq    @NoHit

    ; Despawn
    bsr    ENT_DespawnEntity

    ; Spawn VFX
    VFX_SPAWN VFXRingCollect,Entity_PosX(a0),Entity_PosY(a0)

    @NoHit:

    rts
