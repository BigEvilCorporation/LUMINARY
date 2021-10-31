; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 27th October 2021
; ============================================================================================
; TEXT.ASM - Text display routines
; ============================================================================================

TXT_LoadSpriteTiles:
    ; ======================================
    ; Loads glyphs for a single line text
    ; string into VRAM for sprite use.
    ; Assumes 2 byte VDP autoincrement.
    ; ======================================
    ; In:
    ;  a0   String
    ;  a1   Font
    ;  d0.l VRAM hndl (>= string length)
    ; Out:
    ;  d1.w String length
    ; ======================================

    move.l a0, a3
    move.l a1, a4
    move.w d0, d5
    VDP_TILES_TO_BYTES d5

    ; Loop until terminator
    moveq  #0, d1
    @CharLp:
    move.l a4, a0                       ; Reset font base addr
    moveq  #0x0, d7
    move.b (a3)+, d7
    beq    @End
    addq.w #1, d1                       ; String count
    PUSH.W d1
    sub.b  #STR_ASCII_START, d7         ; Tile idx = char - ascii start + font addr
    VDP_TILES_TO_BYTES d7               ; Tile to bytes
    add.l  d7, a0                       ; DMA src
    move.w d5, d0                       ; DMA dest
    move.w #SIZE_TILE_W, d1             ; DMA size
    bsr    VDPDMA_TransferImmediateVRAM
    POP.W  d1
    add.w  #SIZE_TILE_B, d5             ; Next tile
    bra    @CharLp                      

    @End:

    rts

TXT_DrawLineS:
    ; ======================================
    ; Draws a single line text string using
    ; packed sprites. Requires glyphs to
    ; be loaded in sprite order using
    ; TXT_LoadSpriteTiles.
    ; Assumes 2 byte VDP autoincrement.
    ; ======================================
    ; d0.w X coord (plane cells)
    ; d1.w Y coord (plane cells)
    ; d2.l VRAM hndl (>= string length)
    ; d3.b Palette
    ; d4.w String length
    ; ======================================

    move.w d4, d5
    move.w d4, d7

    ; Coords to sprite space
    VDP_TILES_TO_PIXELS d0
    VDP_TILES_TO_PIXELS d1
    addi.w #VDP_SPRITE_BORDER_X, d0
    addi.w #VDP_SPRITE_BORDER_Y, d1

    ; Palette to flags
    andi.w #3, d3
    ror.w  #VDP_SPRITE_FLAG_ROR_PAL, d3

    ; Layout
    move.b #VDP_SPRITE_LAYOUT_4x1, d4
    
    ; Draw all 4x1 sprites
    lsr.w  #2, d5 ; Quotient
    beq    @No4x1
    subq   #1, d5
    @Lp4x1:
    PUSH.W d2
    bsr    SPR_Draw
    POP.W  d2
    addq.w #4, d2   ; Next 4 glyphs
    addi.w #32, d0  ; Next X pos
    dbra   d5, @Lp4x1
    @No4x1:

    ; Draw remainder
    andi.w #3, d7 ; Remainder
    beq    @NoRemainder
    subq   #1, d7
    move.w d7, d4 ; Determine layout
    lsl.w  #2, d4
    bsr    SPR_Draw
    

    @NoRemainder:

    rts