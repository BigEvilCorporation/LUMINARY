; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; TILES.ASM - Tile loading and management routines
; ============================================================================================

VDP_LoadTiles:
    ; ======================================
    ; Loads tiles into VRAM
    ; ======================================
    ; a0   Tiles
    ; d0.w VRAM address
    ; d1.w Num tiles
    ; ======================================

    VDP_SETADDRESS d0,#0x0000,#VDP_CMD_VRAM_WRITE

    subq   #0x1, d1
    @TileLp:
    ; 32 bytes per tile
    REPT 8
    move.l (a0)+, PORT_VDP_DATA
    ENDR
    dbra   d1, @TileLp

    rts