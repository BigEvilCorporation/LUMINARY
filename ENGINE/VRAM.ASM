; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; VRAM.ASM - VRAM manipulation
; ============================================================================================

; ======================================
; VRAM_Clear - Clears 64kb VRAM
; ======================================
; No params
; ======================================
VRAM_Clear:

    VDP_SET_VRAM_WRITE 0x0000

    movea  #0x0, a0
    movea  PORT_VDP_CONTROL, a5
    moveq  #0x0, d1
    move.w #VRAM_SIZE_L-1, d0
    @Lp:
    move.l d1, a5
    dbra   d0, @Lp

    rts

; ======================================
; VSRAM_Clear - Clears VSRAM
; ======================================
; No params
; ======================================
VSRAM_Clear:

	INT_DISABLE

	move.w #0x9350, PORT_VDP_CONTROL    ; Set bytes to fill (lo) (reg 19)
	move.w #0x9400, PORT_VDP_CONTROL    ; Set bytes to fill (hi) (reg 20)
	move.w #0x9780, PORT_VDP_CONTROL    ; Set DMA to Fill (reg 23, bits 0-1)
	move.l #VDP_CMD_DMA_VSRAM_WRITE, PORT_VDP_CONTROL ; Set destination address
	move.w #0x0, PORT_VDP_DATA          ; Value to write

	INT_RESTORE

	@WaitForDMA:                    
	move.w PORT_VDP_CONTROL, d1         ; Read VDP status reg
	btst   #0x1, d1                     ; Check if DMA finished
	bne.s  @WaitForDMA

	move.w #0x8F02, PORT_VDP_CONTROL    ; Set autoincrement to 2 bytes
	
	rts