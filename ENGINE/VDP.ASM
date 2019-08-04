; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; VDP.ASM - VDP control
; ============================================================================================

VDP_Initialise:
    ; ======================================
    ; Initialises the VDP - writes TMSS,
    ; loads default registers, and clears
    ; VRAM/CRAM/VSRAM.
    ; ======================================
    ; No params
    ; ======================================

    ; Write the TMSS
    bsr    VDP_WriteTMSS

    ; Load default VDP regs
    lea    default_vdp_regs, a0
    bsr    VDP_LoadRegisters

    ; Clear VRAM
    bsr    VRAM_Clear

    ; TODO: CRAM/VSRAM

    rts

VDP_WriteTMSS:
    ; ======================================
    ; Initialises TMSS
    ; ======================================
    ; No params
    ; ======================================

    ; Check version, TMSS only on model 1+
    move.b PORT_HARDWARE_VER, d0
	andi.b #0x0F, d0
	beq @Skip
	move.l #TMSS_SIGNATURE, PORT_VDP_TMSS
	@Skip:

	; Check VDP - hangs if no access
	move.w PORT_VDP_CONTROL, d0

    rts

VDP_LoadRegisters:
    ; ======================================
    ; Loads VDP registers
    ; ======================================
    ; a0   Regs table
    ; ======================================

	INT_DISABLE

    move.w #VDP_CMD_REG_WRITE, d1
    move.w #VDP_NUM_REGISTERS-1, d0
	@RegLp:
	move.b (a0)+, d1                    ; Get reg byte
	move.w d1, PORT_VDP_CONTROL         ; Write
	addi.w #0x0100, d1                  ; Next reg #
	dbra   d0, @RegLp

	INT_RESTORE

    rts

VDP_DMATransferVRAM:
    ; ======================================
    ; DMA transfer from 68K space to VRAM
    ; ======================================
	; a0   Source address
	; d0.w Dest address (VRAM)
	; d1.w Size in words
    ; ======================================

	; Disable interrupts
	INT_DISABLE
	
	; Size lo (register 13)
	move.w d1, d2
	andi.w #0x00FF, d2
	ori.w  #0x9300, d2
	move.w d2, PORT_VDP_CONTROL
	
	; Size hi (register 14)
	lsr.w  #0x8, d1
	andi.w #0x00FF, d1
	ori.w  #0x9400, d1
	move.w d1, PORT_VDP_CONTROL

	; Copy source address
	move.l a0, d2
	moveq #0x0, d3
	
	; Address byte 0 (register 15)
	lsr.l  #0x1, d2					    ; Ignore first bit (address is always even)
	move.w #0x9500, d3
	move.b d2, d3
	move.w d3, PORT_VDP_CONTROL
	
	; Address byte 1 (register 16)
	lsr.l  #0x8, d2					    ; Next byte
	move.w #0x9600, d3
	move.b d2, d3
	move.w d3, PORT_VDP_CONTROL
	
	; Address byte 2 + DMA mode (register 17)
	lsr.l  #0x8, d2					    ; Next byte
	move.w #0x9700, d3
	move.b d2, d3
	andi.b #VDP_DMA_ADDR_MASK_WRITE_B, d3 ; Top byte mask (to fit DMA mode)
	ori.b  #VDP_DMA_MODE_TRANSFER, d3	; DMA mode 0
	move.w d3, PORT_VDP_CONTROL
	
	; Generate dest command+address
	andi.l  #0xFFFF, d0
	lsl.l   #0x2, d0				    ; Shift bits 14/15 of dest address to bits 16/17
	lsr.w   #0x2, d0				    ; Shift lower word back
	swap    d0                     	    ; Swap address hi/lo
	ori.l   #VDP_CMD_DMA_VRAM_WRITE, d0 ; OR in VRAM+DMA write command
	
	; Read VDP reg 1
    ; TODO
	;VDP_GETREG 1, d4
	
	; Enable DMA
	;ori.w   #0x10, d4  			    ; Set register 1 + DMA bit (5)
	;VDP_SETREG 1, d4

	; Take Z80 bus
    ; TODO
	;jsr    Z80_TakeBus
	
	; Initiate DMA - command must come from RAM, so push to stack and pop for write
	move.l  d0, -(sp)
	move.w  (sp)+, PORT_VDP_CONTROL     ; Move dest address to VDP control port
	move.w  (sp)+, PORT_VDP_CONTROL     ; Move dest address to VDP control port

	; Release Z80 bus
	;jsr    Z80_ReleaseBus
	
	; Disable DMA
	;andi.b  #0xEF, d4 				    ; Clear DMA bit (5)
	;VDP_SETREG 1, d4

	; Restore interrupts
	INT_RESTORE
	
	rts