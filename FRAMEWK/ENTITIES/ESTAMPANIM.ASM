; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 7th April 2026
; ============================================================================================
; ESTAMPANIM.ASM - Stamp animation management entity
; ============================================================================================

    ENTITY_SPAWN_DATA_BEGIN EStampAnim
SDStampAnim_VRAMHndl            rs.l 1
    ENTITY_SPAWN_DATA_END

    ENTITY_BEGIN EStampAnim
    ENT_COMPONENT ECSprite
    ENTITY_END

EStampAnim_Initialise:
    ; ======================================
    ; SEStampAnim static initialise
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ENT_GETCOMPONENT EStampAnim,ECSprite,a0,a2
    move.l SDStampAnim_VRAMHndl(a1), ECSprite_VRAMHndl(a2)

    rts

EStampAnim_Shutdown:
    rts

EStampAnim_Update:
    ; ======================================
    ; SEStampAnim static update
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; TODO: Support for entities that don't update

    rts