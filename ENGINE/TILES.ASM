; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; TILES.ASM - Tile loading and management routines
; ============================================================================================

VDP_LoadTiles:
    ; ======================================
    ; Loads tiles into VRAM (via immediate
    ; DMA transfer)
    ; ======================================
    ; a0   Tiles
    ; d0.w VRAM address (tiles)
    ; d1.w Num tiles
    ; ======================================

    ; Address to bytes, count to words
    lsl.w  #SIZE_TILE_SHIFT_B, d0
    lsl.w  #SIZE_TILE_SHIFT_W, d1
	
	; If block crosses a 128kb boundary, split into two jobs
	; (but simpler to do with 64kb, can just use carry flag)
	move.l a0, d2
	move.w d1, d3
	lsl.w  #0x1, d3		; Words to bytes
	add.w  d3, d2		; Add size to lower 16 bits of address
	bcs    @SplitDMA	; Branch if Carry Set (result overflowed across 16 bit boundary)
	
	@SingleDMA:
	
	; Single DMA
	bsr    VDPDMA_TransferImmediateVRAM
	
	bra    @End
	
	@SplitDMA:
	
	; Edge case: end of data lands precisely on 64kb boundary
	beq    @SingleDMA
	
	; DMA 1
	moveq  #0x0, d6
	move.l a0, d2			; Source addr to d2
	PUSHM.W d0/d1			; Backup original size/dest
	move.l d2, d3
	andi.l #0xFFFF0000, d3	; Align source address down to 64kb boundary
	addi.l #0x00010000, d3	; Align up
	sub.l  d2, d3			; Get size difference from original address
	move.w d3, d6			; Backup job 1 size
	move.w d3, d1			; Size to d1
	lsr.w  #0x1, d1			; Size diff to words
    move.l d2, a0           ; Source address
	bsr    VDPDMA_TransferImmediateVRAM
	
	; DMA 2
	POPM.W  d0/d1			; Restore original size/dest
	add.l  d6, d2			; Offset source address (bytes)
	add.w  d6, d0			; Offset dest address (bytes)
	lsr.w  #0x1, d6			; Job 1 size to words
	sub.w  d6, d1			; Subtract job 1 size (words)
	bsr    VDPDMA_TransferImmediateVRAM
	
	@End:

    rts