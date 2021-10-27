; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 24th July 2019
; ============================================================================================
; DBGDRAW.ASM - Debug drawing routines
; ============================================================================================

DBG_DrawStringS:
    ; ======================================
    ; Draws debug text string using sprites.
    ; Palette 0 only.
    ; Assumes 2 byte VDP autoincrement.
    ; ======================================
    ; a0   String
    ; d0.w X coord (plane cells)
    ; d1.w Y coord (plane cells)
    ; ======================================

    ; Coords to sprite space
    VDP_TILES_TO_PIXELS d0
    VDP_TILES_TO_PIXELS d1
    addi.w #VDP_SPRITE_BORDER_X, d0
    addi.w #VDP_SPRITE_BORDER_Y, d1

    ; Sprite flags and layout
    moveq  #0x0, d3
    moveq  #0x0, d4

    ; Get font addr
    move.l RAM_DBG_FONT_VRAM, d5
    VRAM_BYTES_TO_TILES d5

    ; Loop until terminator
    @CharLp:
    moveq  #0x0, d7
    move.b (a0)+, d7
    beq    @End
    sub.b  #STR_ASCII_START, d7         ; Tile idx = char - ascii start + font addr
    move.w d7, d2
    add.w  d5, d2
    bsr    SPR_Draw                     ; Draw sprite
    addq   #0x8, d0                     ; Next X coord
    bra    @CharLp                      

    @End:

    rts

DBG_DrawStringA:
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
    VRAM_CELL_COORDS_TO_BYTES d0, d1, d3
    VDP_SETADDRESS d3, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE

    ; Get font addr
    move.l RAM_DBG_FONT_VRAM, d0
    VRAM_BYTES_TO_TILES d0

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

DBG_DrawStringA_Pal:
    ; ======================================
    ; Draws debug text string to plane A,
    ; with variable palette.
    ; Not corrected for scrolling.
    ; Assumes 2 byte VDP autoincrement.
    ; ======================================
    ; a0   String
    ; d0.w X coord (plane A cells)
    ; d1.w Y coord (plane A cells)
    ; d2.b Palette idx
    ; ======================================

    ; Coord to plane offset, set address for writing
    VRAM_CELL_COORDS_TO_BYTES d0, d1, d3
    VDP_SETADDRESS d3, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE

    ; Palette to bits
    andi.w #0x3, d2
    lsl.w  #0x8, d2
    lsl.w  #0x5, d2

    ; Get font addr
    move.l RAM_DBG_FONT_VRAM, d0
    VRAM_BYTES_TO_TILES d0

    ; Loop until terminator
    @CharLp:
    moveq  #0x0, d3
    move.b (a0)+, d3
    beq    @End
    sub.b  #STR_ASCII_START, d3         ; Tile idx = char - ascii start + font addr
    add.w  d0, d3
    or.w   d2, d3
    move.w d3, PORT_VDP_DATA
    bra    @CharLp                      

    @End:

    rts
