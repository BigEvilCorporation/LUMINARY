; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 3rd August 2019
; ============================================================================================
; SPRITES.ASM - Sprites and sprite table routines
; ============================================================================================

    ; Single sprite
    STRUCT_BEGIN Sprite
Sprite_VRAMHndl                         rs.l 1 ; VRAM handle
Sprite_DrawFlags                        rs.w 1 ; Priority/palette/flip flags preformatted for hardware (see SPRITE_SET_* macros)
Sprite_Layout                           rs.b 1 ; Layout/dimensions
    STRUCT_END

    ; Multi-sprite sheet
    STRUCT_BEGIN SpriteSheet
SpriteSheet_TileData    			    rs.l 1 ; Base address of tile data
SpriteSheet_LayoutTable                 rs.l 1 ; Address of table of VDP layout per subsprite
SpriteSheet_PosOffsetTable	            rs.l 1 ; Address of table of position offsets per subsprite
SpriteSheet_WidthHeightTiles		    rs.w 1 ; Sprite object width/height in tiles (0xWWHH)
SpriteSheet_SizeTiles				    rs.w 1 ; Sprite object single frame size in tiles
SpriteSheet_SizeSubsprites			    rs.w 1 ; Sprite object single frame size in subsprites
    STRUCT_END

    ; Hardware sprite
    STRUCT_BEGIN VDPSprite
VDPSprite_CoordY        		        rs.w 1 ; Y coord
VDPSprite_Dimensions                    rs.b 1 ; Dimensions bits
VDPSprite_NextId				        rs.b 1 ; Next sprite ID
VDPSprite_Prio_Pal_Flip_TileIdHi        rs.b 1 ; Priority (15), palette (14-13), v/h flip (12-11), tile ID hi (10-8)
VDPSprite_TileIdLo                      rs.b 1 ;  + tile ID lo (7-0)
VDPSprite_CoordX        		        rs.w 1 ; X coord
    STRUCT_END
    
    ; Number of tiles per sprite layout configuration
SpriteLayoutTileCountTable:
	dc.b 1  ; 0000 (1x1)
	dc.b 2  ; 0001 (1x2)
	dc.b 3  ; 0010 (1x3)
	dc.b 4  ; 0011 (1x4)
	dc.b 2  ; 0100 (2x1)
	dc.b 4  ; 0101 (2x2)
	dc.b 6  ; 0110 (2x3)
	dc.b 8  ; 0111 (2x4)
	dc.b 3  ; 1000 (3x1)
	dc.b 6  ; 1001 (3x2)
	dc.b 9  ; 1010 (3x3)
	dc.b 12 ; 1011 (3x4)
	dc.b 4  ; 1100 (4x1)
	dc.b 8  ; 1101 (4x2)
	dc.b 12 ; 1110 (4x3)
	dc.b 16 ; 1111 (4x4)

SPR_Initialise:
    ; ======================================
    ; Initialises sprite table and blanks
    ; first sprite.
    ; ======================================
	; No params
    ; ======================================

    ; Reset sprite link counter and table ptr
    move.l #RAM_SPRITE_TABLE, RAM_SPRITE_TABLE_PTR
    move.w #0x0, RAM_SPRITE_NEXT_IDX

	; Move first sprite to border and unlink
	lea    RAM_SPRITE_TABLE, a0
	move.w #0x1, VDPSprite_CoordX(a0)
	move.w #0x1, VDPSprite_CoordY(a0)
	move.b #0x0, VDPSprite_NextID(a0)

    rts

SPR_DrawSingle:
    ; ======================================
    ; Adds a single sprite for drawing at
    ; the end of the frame.
    ; ======================================
	; a0   Sprite
    ; d0.w X coord
    ; d1.w Y coord
    ; d2.l VRAM hndl
    ; d3.w Draw flags
    ; ======================================

    ; Get table ptr
    move.l RAM_SPRITE_TABLE_PTR, a1

    ; Get next sprite index
    move.w RAM_SPRITE_NEXT_IDX, d6

    ; Link prev in table to this
	beq     @FirstInTable
	move.b  d6, (-SIZEOF_VDPSprite+VDPSprite_NextId)(a1)
	@FirstInTable:

    ; Check if table depleted
    cmp.w  #VDP_MAX_SPRITES, d6
    beq    @Err_OutOfSprites

    ; Next ID
    addi.w #0x1, RAM_SPRITE_NEXT_IDX

    ; Combine tile ID and flags
    or.w   d3, d2

    ; Populate next hardware sprite
    move.w d1, (a1)+                    ; Coord Y
    move.b Sprite_Layout(a0), (a1)+     ; Dimensions
    move.b #0x0, (a1)+                  ; Next ID
    move.w d2, (a1)+                    ; Prio/pal/flip/tileId
    move.w d0, (a1)+                    ; Coord X

    ; Advance ptr
    move.l a1, RAM_SPRITE_TABLE_PTR

    rts

    @Err_OutOfSprites:
    DBG_RAISE_ERROR "Out of sprites"

    rts

SPR_DrawSheet:
    ; ======================================
    ; Adds a multi sprite from sheet for
    ; drawing at the end of the frame.
    ; ======================================
	; a0   Sprite sheet
    ; d0.w X coord
    ; d1.w Y coord
    ; d2.l VRAM handle
    ; d3.w Draw flags
    ; ======================================

    ; Get table ptr
    move.l RAM_SPRITE_TABLE_PTR, a1

    ; Get next sprite index
    move.w RAM_SPRITE_NEXT_IDX, d6

    ; Get num subsprites
    move.w SpriteSheet_SizeSubsprites(a0), d5

    ; Check if table depleted
    move.w d6, d4
    add.w  d5, d4
    cmp.w  #VDP_MAX_SPRITES, d4
    bge    @Err_OutOfSprites

    ; Get layout table
    move.l SpriteSheet_LayoutTable(a0), a2

    ; Get pos offset table
    move.l SpriteSheet_PosOffsetTable(a0), a4
    
    ; Get layout tile count table
    lea    SpriteLayoutTileCountTable, a5

    ; If flipped X, start the offset table at next coord
    btst   #VDP_SPRITE_FLAG_FLIPX, d3
    beq    @NoFlipX
    addq.w #SIZE_LONG, a4
    @NoFlipX:

    ; Combine tile ID and flags
    or.w   d3, d2
    
    ; Clear for tile count offset
    moveq  #0x0, d7

    subi.w #0x1, d5
    @SubSpriteLp:

    ; Link prev in table to this
    tst.w   d6
	beq     @FirstInTable
	move.b  d6, (-SIZEOF_VDPSprite+VDPSprite_NextId)(a1)
	@FirstInTable:

    ; Next ID
    addq.w #0x1, d6
    
    ; Next pos
    add.w  (a4)+, d0
    add.w  (a4)+, d1
    addq.w #SIZE_LONG, a4
    
    ; Next layout
    move.b (a2)+, d7

    ; Populate next hardware sprite
    move.w d1, (a1)+                    ; Coord Y
    move.b d7, (a1)+                    ; Layout
    move.b #0x0, (a1)+                  ; Next ID
    move.w d2, (a1)+                    ; Prio/pal/flip/tileId
    move.w d0, (a1)+                    ; Coord X
    
	; Next tile idx using layout table lookup
	move.b (a5,d7), d7
	add.w  d7, d2

    dbra   d5, @SubSpriteLp

    ; Advance ptr
    move.l a1, RAM_SPRITE_TABLE_PTR

    ; Advance index
    move.w d6, RAM_SPRITE_NEXT_IDX

    rts

    @Err_OutOfSprites:
    DBG_RAISE_ERROR "Out of sprites"

    rts

SPR_CommitAndClearTable:
    ; ======================================
    ; Commits the local sprite table to
    ; VRAM, and clears it for next frame.
    ; ======================================
	; No params
    ; ======================================

	; DMA the sprite table
	move.w RAM_SPRITE_NEXT_IDX, d1
	bne    @SpritesValid
	moveq  #0x1, d1			            ; If no sprites, still need to DMA "blank" sprite
	@SpritesValid:
	lea    RAM_SPRITE_TABLE, a0
	move.w #VRAM_ADDR_SPRITE_TABLE, d0
	mulu.w #SIZEOF_VDPSprite/SIZE_WORD, d1
	bsr    VDP_DMATransferVRAM

    ; Reset sprite link counter and table ptr
    move.l #RAM_SPRITE_TABLE, RAM_SPRITE_TABLE_PTR
    move.w #0x0, RAM_SPRITE_NEXT_IDX

	; Move first sprite to border and unlink
	lea    RAM_SPRITE_TABLE, a0
	move.w #0x1, VDPSprite_CoordX(a0)
	move.w #0x1, VDPSprite_CoordY(a0)
	move.b #0x0, VDPSprite_NextID(a0)

    rts