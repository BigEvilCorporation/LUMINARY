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

    ; Initialise gamepads
    bsr    PAD_Initialise

    ; Clear VRAM
    bsr    VRAM_Clear

    ; Initialise VRAM manager
    lea    RAM_VRAM_Manager, a0
    bsr    VRAM_ManagerInit

    ; TODO: Take initial pools from table
    move.w #0x0000, d0
    move.w #0xB000/SIZE_TILE_B, d1
    bsr    VRAM_AddPool

    ; Load debug font
    lea    RAM_VRAM_Manager, a0
    move.w #SIZEOF_debug_font/SIZE_TILE_B, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_DBG_FONT_VRAM

    lea    debug_font, a0
    move.w d1, d0
    move.w #SIZEOF_debug_font/SIZE_TILE_B, d1
    bsr    VDP_LoadTiles

    ; Jump to program main
    jmp    Main