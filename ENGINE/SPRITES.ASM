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
Sprite_Layout                           rs.b 1 ; Layout/dimensions
    STRUCT_END

    ; Multi-sprite
    STRUCT_BEGIN MultiSprite
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
    ; d2.b Palette
    ; d3.b Priority (0 or 1)
    ; d4.b Flip X
    ; d5.b Flip Y
    ; ======================================

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

    ; Get tile ID
    move.l Sprite_VRAMHndl(a0), d6

    ; Build palette/flip/priority/tileId word
	; Bit pattern: LPPV HTTT TTTT TTTT (L=Lo/Hi priority, P=Palette, V=VFlip, H=HFlip, T-TileId)
	andi.w #0x3, d2		; Palette in bottom two bits
	andi.w #0x1, d3		; Priority in bottom bit
	andi.w #0x1, d4		; Flip X in bottom bit
    andi.w #0x1, d5		; Flip Y in bottom bit
	ror.w  #0x3, d2		; Palette to bits 13-14
	ror.w  #0x1, d3		; Priority to bit 15
	ror.w  #0x5, d4		; Flip X to bit 11
    ror.w  #0x4, d5		; Flip Y to bit 12
	or.w   d3, d2		; Combine
	or.w   d4, d2
    or.w   d5, d2
	or.w   d6, d3

    ; Get table ptr
    move.l RAM_SPRITE_TABLE_PTR, a1

    ; Populate next hardware sprite
    move.w d1, (a1)+                    ; Coord Y
    move.b Sprite_Layout(a0), (a1)+     ; Dimensions
    move.b #0x0, (a1)+                  ; Next ID
    move.w d3, (a1)+                    ; Prio/pal/flip/tileId
    move.w d0, (a1)+                    ; Coord X

    ; Advance ptr
    move.l a1, RAM_SPRITE_TABLE_PTR

    rts

    @Err_OutOfSprites:
    DBG_RAISE_ERROR "Out of sprites"

    rts

SPR_DrawMulti:
    ; ======================================
    ; Adds a multi-sprite for drawing at
    ; the end of the frame.
    ; ======================================
	; a0   Sprite
    ; d0.w X coord
    ; d1.w Y coord
    ; ======================================

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