; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 24th July 2019
; ============================================================================================
; DBGDRAW.ASM - Debug drawing routines
; ============================================================================================

DBG_DrawString:
    ; ======================================
    ; Draws debug text string to plane A.
    ; Palette 0 only.
    ; Not corrected for scrolling.
    ; Assumes 2 byte VDP autoincrement.
    ; ======================================
    ; a0   String
    ; d0.w X coord (plane A cells)
    ; d1.w Y coord (plane A cells)
    ; ======================================

    ; Coord to plane offset, set address for writing
    VRAM_PLANE_COORDS_TO_BYTES d0, d1, d3
    VDP_SETADDRESS d3, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE

    ; Get font addr
    move.l RAM_DBG_FONT_VRAM, d0

    ; Loop until terminator
    @CharLp:
    moveq  #0x0, d3
    move.b (a0)+, d3
    beq    @End
    sub.b  #STR_ASCII_START, d3         ; Tile idx = char - ascii start + font addr
    add.w  d0, d3
    move.w d3, PORT_VDP_DATA
    bra    @CharLp                      

    @End:

    rts
