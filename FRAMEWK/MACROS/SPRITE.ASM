; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 9th November 2019
; ============================================================================================
; SPRITE.ASM - Sprite component helper macros
; ============================================================================================

SPRITE_COMPONENT_SETPALETTE_REG: macro sprite,pal_idx
    ; ======================================
    ; Set a sprite's palette idx from a reg
    ; ======================================
    ; sprite   - Address reg of sprite
    ; pal_idx  - Reg containing index (0-3)
    ; ======================================
    andi.w #0x3, \pal_idx
    ror.w  #VDP_SPRITE_FLAG_ROR_PAL, \pal_idx
    andi.w #VDP_SPRITE_FLAG_NMASK_PAL, ECSprite_DrawFlags(\sprite)
    or.w   \pal_idx, ECSprite_DrawFlags(\sprite)
    endm

SPRITE_COMPONENT_SETFLIPX_REG: macro sprite,enabled
    ; ======================================
    ; Set a sprite's flip X flag from a reg
    ; ======================================
    ; sprite   - Address reg of sprite
    ; enabled  - Reg containing 0 or 1
    ; ======================================
    andi.w #0x1, \enabled
    ror.w  #VDP_SPRITE_FLAG_ROR_FLIPX, \enabled
    andi.w #VDP_SPRITE_FLAG_NMASK_FLIPX, ECSprite_DrawFlags(\sprite)
    or.w   \enabled, ECSprite_DrawFlags(\sprite)
    endm
