; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; PALETTES.ASM - Palette loading and management routines
; ============================================================================================

VDP_LoadPalette:
    ; ======================================
    ; Loads a palette into CRAM
    ; ======================================
    ; a0   Palette
    ; d0.b Palette index
    ; ======================================

    ; Index to CRAM addr
    andi.w #0x0F, d0
    lsl.w  #SIZE_PALETTE_SHIFT, d0
    VDP_SETADDRESS d0,#0x0000,#VDP_CMD_CRAM_WRITE

    ; 32 bytes
    REPT 8
    move.l (a0)+, PORT_VDP_DATA
    ENDR

    rts