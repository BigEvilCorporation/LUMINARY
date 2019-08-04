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
    move.l Sprite_VRAMHndl(a0), d2
    or.w   Sprite_DrawFlags(a0), d2

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