; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; BOOTSTRP.ASM - Main system initialisation, entry point
; ============================================================================================

Bootstrap:
    ; ======================================
    ; Main entry point
    ; ======================================
    ; Called from vector table only
    ; ======================================

    ; Clear main RAM
    bsr    RAM_Clear

    ; Initialise TMSS
    bsr    VDP_InitialiseTMSS

    ; Load default VDP regs
    lea    default_vdp_regs, a0
    bsr    VDP_LoadRegisters

    ; Clear VRAM
    bsr    VRAM_Clear

    ; TODO: Init VRAM manager

    ; Load debug font
    ; TODO: Use VRAM manager
    lea    debug_font, a0
    move.w #0x0, d0
    move.w #SIZEOF_debug_font/SIZE_TILE_B, d1
    bsr    VDP_LoadTiles
    move.w #0x0, RAM_DBG_FONT_VRAM

    ; Jump to program main
    jmp    Main