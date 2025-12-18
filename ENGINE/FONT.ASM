; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th April 2020
; ============================================================================================
; FONT.ASM - Font loading and effect routines
; ============================================================================================

FNT_LoadFontShadowed:
    ; ======================================
    ; Load font tiles, adding a shadow FX.
    ; Writes to VRAM
    ; ======================================
    ; Routine by Sik, used with permission
    ; ======================================
    ; a0   Tiles
    ; d0.w VRAM address (tiles)
    ; d1.w Num tiles
    ; d2.b Foreground color
    ; d3.b Background color
    ; d4.b Shadow color
    ; ======================================

    ; Start writing to VRAM
    lsl.w  #SIZE_TILE_SHIFT_B, d0
    VDP_SETADDRESS d0, #VRAM_ADDR_TILES, #VDP_CMD_VRAM_WRITE
    move.l #PORT_VDP_DATA, a6

    lsl.w   #3, d1                      ; Calculate row count
    subq.w  #1, d1                      ; Subtract due to DBF

    @RowLoop:                           ; Go through all rows
    move.w  d1, a1

    move.l  (a0)+, d0                   ; Get next row
    moveq   #0, d5                      ; Reset color counter
    moveq   #8-1, d6                    ; Go through all pixels

    @ColLoop:

    subq.b  #1, d5                      ; Update color counter
    lsl.l   #4, d7                      ; Make room for next pixel
    rol.l   #4, d0                      ; Read next pixel
    move.b  d0, d1
    andi.b  #0x0F, d1
    
    beq.s   @NoFG                       ; Is it foreground?
    moveq   #1, d5                      ; Set color counter
    @NoFG:
    
    tst.b   d5                          ; Determine which color to use for
    bgt.s   @FGColor                    ; this pixel
    beq.s   @Shadow
    
    or.b    d3, d7                      ; Background color
    bra.s   @ColorSet
    
    @FGColor:    
    or.b    d2, d7                      ; Foreground color
    bra.s   @ColorSet
    
    @Shadow:
    or.b    d4, d7                      ; Shadow color
    
    @ColorSet:
    dbf     d6, @ColLoop                ; Go for next pixel
    
    move.l  d7, (a6)                    ; Write 4bpp row to VRAM
    move.w  a1, d1
    dbf     d1, @RowLoop                ; Go for next row

    rts

FNT_LoadDebugFont:

    lea    RAM_VRAM_MANAGER, a0
    move.w #SIZEOF_debug_font/SIZE_TILE_B, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_DBG_FONT_VRAM

    lea    debug_font, a0
    move.w d1, d0
    move.w #SIZEOF_debug_font/SIZE_TILE_B, d1
    bsr    VDP_LoadTiles

    rts