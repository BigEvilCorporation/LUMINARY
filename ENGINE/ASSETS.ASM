; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; ASSETS.ASM - Assets required for engine code
; ============================================================================================

    ; Default VDP registers
    ASSET_INCLUDE_ASM default_vdp_regs, 'engine/assets/vdp/vdpregs.asm'

    ; Debug draw font
	ASSET_INCLUDE_BIN debug_font, 'engine/assets/fonts/sans.bin'

    ; Error draw palette
    ASSET_INCLUDE_ASM error_palette, 'engine/assets/palettes/errorpal.asm'