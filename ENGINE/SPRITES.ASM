; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 3rd August 2019
; ============================================================================================
; SPRITES.ASM - Sprites and sprite table routines
; ============================================================================================

    ; Sprite sheet
    STRUCT_BEGIN SpriteSheet
SpriteSheet_FirstFrame    			    rs.l 1 ; Frame 0
SpriteSheet_VRAMSizeTiles		        rs.w 1 ; Size of largest frame in tiles
    STRUCT_END

    ; Sprite animation frame
    STRUCT_BEGIN SpriteFrame
SpriteFrame_SizeTiles				    rs.w 1 ; Size of frame in tiles
SpriteFrame_SizeSubsprites			    rs.w 1 ; Size of frame in subsprites
SpriteFrame_TileData                    rs.l 1 ; Address of tile data
SpriteFrame_LayoutTable                 rs.l 1 ; Address of table of VDP layout per subsprite
SpriteFrame_PosOffsetTable	            rs.l 1 ; Address of table of position offsets per subsprite
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

SPR_Draw:
    ; ======================================
    ; Adds a sprite for drawing
    ; ======================================
    ; d0.w X coord
    ; d1.w Y coord
    ; d2.w Tile ID
    ; d3.w Draw flags
    ; d4.b Layout
    ; ======================================

    ; Get table ptr
    move.l RAM_SPRITE_TABLE_PTR, a1

    ; Get next sprite index
    move.w RAM_SPRITE_NEXT_IDX, d6

    ; Check if table depleted
    cmp.w  #VDP_MAX_SPRITES, d6
    bge    @Err_OutOfSprites

    ; Combine tile ID and flags
    or.w   d3, d2

    ; Link prev in table to this (-1st sprite is blank sprite)
	move.b  d6, (-SIZEOF_VDPSprite+VDPSprite_NextId)(a1)

    ; Populate hardware sprite
    move.w d1, (a1)+                    ; Coord Y
    move.b d4, (a1)+                    ; Layout
    move.b #0, (a1)+                    ; Next ID
    move.w d2, (a1)+                    ; Prio/pal/flip/tileId
    move.w d0, (a1)+                    ; Coord X

    ; Advance ptr
    move.l a1, RAM_SPRITE_TABLE_PTR

    ; Advance index
    addq.w #0x1, d6
    move.w d6, RAM_SPRITE_NEXT_IDX

    rts

    @Err_OutOfSprites:
    DBG_RAISE_ERROR "Out of sprites"

    rts

SPR_DrawFrame:
    ; ======================================
    ; Adds a sprite frame for drawing
    ; ======================================
	; a0   SpriteFrame
    ; d0.w X coord
    ; d1.w Y coord
    ; d2.w VRAM handle
    ; d3.w Draw flags
    ; ======================================

    ; Get table ptr
    move.l RAM_SPRITE_TABLE_PTR, a1

    ; Get next sprite index
    move.w RAM_SPRITE_NEXT_IDX, d6

    ; Get num subsprites
    move.w SpriteFrame_SizeSubsprites(a0), d5

    ; Check if table depleted
    move.w d6, d4
    add.w  d5, d4
    cmp.w  #VDP_MAX_SPRITES, d6
    bge    @Err_OutOfSprites

    ; Get layout table
    move.l SpriteFrame_LayoutTable(a0), a2

    ; Get pos offset table
    move.l SpriteFrame_PosOffsetTable(a0), a4
    
    ; Get layout tile count table
    lea    SpriteLayoutTileCountTable, a5

    ; If flipped X, start the offset table at next coord
    btst   #VDP_SPRITE_FLAG_FLIPX, d3
    beq    @NoFlipX
    adda.w #SIZE_LONG, a4               ; Skip to X flip offset
    @NoFlipX:

    ; If flipped Y, start the offset table at next coord
    btst   #VDP_SPRITE_FLAG_FLIPY, d3
    beq    @NoFlipY
    adda.w #SIZE_LONG*2, a4             ; Skip to Y or XY flip offset
    @NoFlipY:

    ; Combine tile ID and flags
    or.w   d3, d2
    
    ; Clear for tile count offset
    moveq  #0x0, d7

    subi.w #0x1, d5
    @SubSpriteLp:

    ; Link prev in table to this (-1st sprite is blank sprite)
	move.b  d6, (-SIZEOF_VDPSprite+VDPSprite_NextId)(a1)

    ; Next ID
    addq.w #0x1, d6
    
    ; Next pos
    add.w  (a4)+, d0                    ; X offset
    add.w  (a4)+, d1                    ; Y offset
    adda.w #SIZE_LONG*3, a4             ; Skip other 3 flipped coords entries in table
    
    ; Next layout
    move.b (a2)+, d7

    ; Populate next hardware sprite
    move.w d1, (a1)+                    ; Coord Y
    move.b d7, (a1)+                    ; Layout
    move.b #0, (a1)+                    ; Next ID
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
	moveq  #0x1, d1			            ; If no sprites, still need to DMA first sprite
	@SpritesValid:                      ; (has been unlinked and moved to border)
	lea    RAM_SPRITE_TABLE, a0
	move.w #VRAM_ADDR_SPRITE_TABLE, d0
	mulu.w #SIZEOF_VDPSprite/SIZE_WORD, d1
	bsr    VDPDMA_TransferImmediateVRAM

    ; Reset sprite link counter and table ptr
    move.l #RAM_SPRITE_TABLE, RAM_SPRITE_TABLE_PTR
    move.w #0x0, RAM_SPRITE_NEXT_IDX

	; Move first sprite to border and unlink
	lea    RAM_SPRITE_TABLE, a0
	move.w #0x1, VDPSprite_CoordX(a0)
	move.w #0x1, VDPSprite_CoordY(a0)
	move.b #0x0, VDPSprite_NextID(a0)

    rts