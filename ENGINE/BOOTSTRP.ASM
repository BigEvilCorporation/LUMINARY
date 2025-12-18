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

    ; Initialise Z80
    bsr    Z80_Initialise

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
 
    ; Load debug font
    bsr    FNT_LoadDebugFont

    ; Init status register
	move.w #CPU_STATUS_REG_INIT, sr	    ; INT level 3 (all interrupts) + supervisor

    ; Flush DMA queue
    bsr    VDPDMA_CommitAndClearQueue

    ; Jump to program main
    jmp    Main