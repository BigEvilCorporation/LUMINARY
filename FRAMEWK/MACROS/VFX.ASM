; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 30th November 2019
; ============================================================================================
; VFX.ASM - VFX helper macros
; ============================================================================================

    ; ======================================
    ; Defines a visual effect with a sprite
    ; sheet, animation, and palette
    ; ======================================
    ; name         - VFX name (used for VFX_SPAWN)
    ; sprite_sheet - Sprite sheet
    ; sprite_anim  - Sprite anim
    ; palette_idx  - Palette id
    ; ======================================
VFX_DEFINE: macro name,sprite_sheet,sprite_anim,palette_idx,width,height
    ENTITY_SPAWN_DATA VFX_\name\_SpawnData
    dc.b   \palette_idx                 ; Palette idx
    even
    ; SDSprite
    dc.l   \sprite_sheet                ; SDSprite_Sheet
    dc.l   \sprite_anim                 ; SDSprite_Animation
    even
    endm

    ; ======================================
    ; Spawns a visual effect
    ; ======================================
    ; name    - VFX name (used for VFX_SPAWN)
    ; pos_x.w - X centre (sprite space)
    ; pos_y.w - Y centre (sprite space)
    ; ======================================
VFX_SPAWN: macro name,pos_x,pos_y
    PUSHM.L d0-d3/a0-a2
    move.w \pos_x\, d0
    move.w \pos_y\, d1
    move.w #0x0, d2
    move.w #0x0, d3
    lea    EVisualEffect_TypeDesc, a0
    lea    VFX_\name\_SpawnData, a1
    bsr    ENT_SpawnEntity
    POPM.L d0-d3/a0-a2
    endm