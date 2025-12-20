; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 30th November 2019
; ============================================================================================
; EVFX.ASM - A fixed, one-shot animation entity that plays then dies
; ============================================================================================

    ; Spawn data
    ENTITY_SPAWN_DATA_BEGIN EVisualEffect
SDVisualEffect_PaletteIdx               rs.b 1
    ENTITY_SPAWN_DATA_END

    ; Entity
    ENTITY_BEGIN EVisualEffect
    ENT_COMPONENT ECSprite
    ENTITY_END

EVisualEffect_Initialise:
    ; ======================================
    ; EVisualEffect constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Set palette from spawn data and disable looping
    move.b SDVisualEffect_PaletteIdx(a1), d0
    ENT_GETCOMPONENT EVisualEffect,ECSprite,a0,a1
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0
    bclr   #ECSPRITE_STATE_FLAG_LOOPING, ECSprite_StateFlags(a1)

    rts

EVisualEffect_Shutdown:
    rts

EVisualEffect_Update:
    ; ======================================
    ; EVisualEffect movement path update
    ; ======================================
	; a0   Entity
    ; ======================================

    ; If anim finished, destroy
    ENT_GETCOMPONENT EVisualEffect,ECSprite,a0,a1
    btst   #ECSPRITE_STATE_FLAG_PLAYING, ECSprite_StateFlags(a1)
    bne    @Playing
    bsr    ENT_DespawnEntity
    @Playing:

    rts