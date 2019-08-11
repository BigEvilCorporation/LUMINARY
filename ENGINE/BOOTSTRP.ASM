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

    ; Initialise VDP
    bsr    VDP_Initialise

    ; Initialise VDP DMA queue
    bsr    VDPDMA_Initialise

    ; Initialise sprite table
    bsr    SPR_Initialise

    ; Initialise gamepads
    bsr    PAD_Initialise

    ; Initialise VRAM manager
    bsr    VRAMMGR_Initialise

    ; TODO: Take initial pools from table
    move.w #0x0000, d0
    move.w #0xB000/SIZE_TILE_B, d1
    bsr    VRAMMGR_AddPool
    
    ; Load debug font
    lea    RAM_VRAM_MANAGER, a0
    move.w #SIZEOF_debug_font/SIZE_TILE_B, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_DBG_FONT_VRAM

    lea    debug_font, a0
    move.w d1, d0
    move.w #SIZEOF_debug_font/SIZE_TILE_B, d1
    bsr    VDP_LoadTiles

    ; Init status register
	move.w #CPU_STATUS_REG_INIT, sr	    ; INT level 3 (all interrupts) + supervisor

    ; Jump to program main
    jmp    Main