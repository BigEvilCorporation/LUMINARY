; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 4th August 2019
; ============================================================================================
; SPRITES.ASM - Macros for setting sprite attributes
; ============================================================================================

SPRITE_SETFLIPX_REG: macro sprite,enabled
    ; ======================================
    ; Set a sprite's flip X flag from a reg
    ; ======================================
    ; sprite   - Address reg of sprite
    ; enabled  - Reg containing 0 or 1
    ; ======================================
    andi.w #0x1, \enabled
    ror.w  #VDP_SPRITE_FLAG_ROR_FLIPX, \enabled
    andi.w #VDP_SPRITE_FLAG_NMASK_FLIPX, Sprite_DrawFlags(\sprite)
    or.w   \enabled, Sprite_DrawFlags(\sprite)
    endm

SPRITE_SETFLIPY_REG: macro sprite,enabled
    ; ======================================
    ; Set a sprite's flip Y flag from a reg
    ; ======================================
    ; sprite   - Address reg of sprite
    ; enabled  - Reg containing 0 or 1
    ; ======================================
    andi.w #0x1, \enabled
    ror.w  #VDP_SPRITE_FLAG_ROR_FLIPY, \enabled
    andi.w #VDP_SPRITE_FLAG_NMASK_FLIPY, Sprite_DrawFlags(\sprite)
    or.w   \enabled, Sprite_DrawFlags(\sprite)
    endm

SPRITE_SETPRIORITY_REG: macro sprite,prio
    ; ======================================
    ; Set a sprite's prio Y flag from a reg
    ; ======================================
    ; sprite   - Address reg of sprite
    ; prio     - Reg containing 0 or 1
    ; ======================================
    andi.w #0x1, \prio
    ror.w  #VDP_SPRITE_FLAG_ROR_PRIO, \prio
    andi.w #VDP_SPRITE_FLAG_NMASK_PRIO, Sprite_DrawFlags(\sprite)
    or.w   \prio, Sprite_DrawFlags(\sprite)
    endm

SPRITE_SETPALETTE_REG: macro sprite,pal_idx
    ; ======================================
    ; Set a sprite's palette idx from a reg
    ; ======================================
    ; sprite   - Address reg of sprite
    ; pal_idx  - Reg containing index (0-3)
    ; ======================================
    andi.w #0x3, \pal_idx
    ror.w  #VDP_SPRITE_FLAG_ROR_PAL, \pal_idx
    andi.w #VDP_SPRITE_FLAG_NMASK_PAL, Sprite_DrawFlags(\sprite)
    or.w   \pal_idx, Sprite_DrawFlags(\sprite)
    endm

SPRITE_SETFLIPX_CONST: macro sprite,enabled
    ; ======================================
    ; Set a sprite's flip X flag from const
    ; ======================================
    ; sprite   - Address reg of sprite
    ; enabled  - Reg containing 0 or 1
    ; ======================================
    IF \enabled
    or.w   #VDP_SPRITE_FLAG_MASK_FLIPX, Sprite_DrawFlags(\sprite)
    ELSE
    andi.w #VDP_SPRITE_FLAG_NMASK_FLIPX, Sprite_DrawFlags(\sprite)
    ENDIF
    endm

SPRITE_SETFLIPY_CONST: macro sprite,enabled
    ; ======================================
    ; Set a sprite's flip Y flag from const
    ; ======================================
    ; sprite   - Address reg of sprite
    ; enabled  - Reg containing 0 or 1
    ; ======================================
    IF \enabled
    or.w   #VDP_SPRITE_FLAG_MASK_FLIPY, Sprite_DrawFlags(\sprite)
    ELSE
    andi.w #VDP_SPRITE_FLAG_NMASK_FLIPY, Sprite_DrawFlags(\sprite)
    ENDIF
    endm

SPRITE_SETPRIORITY_CONST: macro sprite,prio
    ; ======================================
    ; Set a sprite's prio Y flag from const
    ; ======================================
    ; sprite   - Address reg of sprite
    ; prio     - Reg containing 0 or 1
    ; ======================================
    IF \prio
    or.w   #VDP_SPRITE_FLAG_MASK_PRIO, Sprite_DrawFlags(\sprite)
    ELSE
    andi.w #VDP_SPRITE_FLAG_NMASK_PRIO, Sprite_DrawFlags(\sprite)
    ENDIF
    endm

SPRITE_SETPALETTE_CONST: macro sprite,pal_idx
    ; ======================================
    ; Set a sprite's palette idx from const
    ; ======================================
    ; sprite   - Address reg of sprite
    ; pal_idx  - Reg containing index (0-3)
    ; ======================================
    IF \pal_idx\=0
    andi.w #VDP_SPRITE_FLAG_NMASK_PAL, Sprite_DrawFlags(\sprite)
    ELSEIF \pal_idx\=3
    or.w   #\pal_idx\<<VDP_SPRITE_FLAG_SHIFT_PAL, Sprite_DrawFlags(\sprite)
    ELSE
    andi.w #VDP_SPRITE_FLAG_NMASK_PAL, Sprite_DrawFlags(\sprite)
    or.w   #\pal_idx\<<VDP_SPRITE_FLAG_SHIFT_PAL, Sprite_DrawFlags(\sprite)
    ENDIF
    endm