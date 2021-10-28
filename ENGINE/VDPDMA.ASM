; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; DMAQUEUE.ASM - VDP DMA job queue
; ============================================================================================

; Constants
VDPDMA_MAX_QUEUE_SIZE    				equ 0x28  ; Queue max size

	STRUCT_BEGIN VDPDMAJob
VDPDMAJob_SizeHiLoCmd					rs.l 1	; Set DMA size command
VDPDMAJob_AddrMidLoCmd					rs.l 1	; Set source address mid/lo command
VDPDMAJob_AddrHiModeCmd					rs.w 1	; Set source address hi and DMA mode command
VDPDMAJob_AutoIncCmd					rs.w 1	; Autoincrement set reg command
VDPDMAJob_DestAddrCmd					rs.l 1	; Set dest address command
	STRUCT_END

VDPDMA_TRANSFER_VRAM       				equ 0x0
VDPDMA_TRANSFER_CRAM       				equ 0x1

VDPDMA_Initialise:
    ; ======================================
    ; Initialises DMA queue
    ; ======================================
    ; No params
    ; ======================================
	move.l #RAM_VDP_DMA_QUEUE, RAM_VDP_DMA_QUEUE_NEXT
	rts

VDPDMA_AddJob:
    ; ======================================
    ; Pushes a DMA job to the queue
    ; ======================================
	; a0   Source addr (68k space)
	; d0.w Dest addr (VRAM space)
	; d1.w Data size (words)
	; d2.b Dest memory (VDPDMA_TRANSFER_VRAM/VDPDMA_TRANSFER_CRAM)
	; d3.b Data stride (bytes)
    ; ======================================

	move.b d2, d7
	move.b d3, d6
	
	; If block crosses a 128kb boundary, split into two jobs
	; (but simpler to do with 64kb, can just use carry flag)
	move.l a0, d2
	move.w d1, d3
	add.w  d3, d3		; Words to bytes
	add.w  d3, d2		; Add size to lower 16 bits of address
	bcs    @SplitJobs	; Branch if Carry Set (result overflowed across 16 bit boundary)
	
	@SingleJob:
	
	; Add single job
	move.l a0, d2
	bsr    VDPDMA_AddToQueue
	
	rts
	
	@SplitJobs:
	
	; Edge case: end of data lands precisely on 64kb boundary
	beq    @SingleJob
	
	; Job 1
	moveq  #0x0, d4
	move.l a0, d2			; Source addr to d2
	PUSHM.W d0/d1			; Backup original size/dest
	move.l d2, d3
	andi.l #0xFFFF0000, d3	; Align source address down to 64kb boundary
	addi.l #0x00010000, d3	; Align up
	sub.l  d2, d3			; Get size difference from original address
	move.w d3, d4			; Backup job 1 size
	move.w d3, d1			; Size to d1
	lsr.w  #0x1, d1			; Size diff to words
	bsr    VDPDMA_AddToQueue
	
	; Job 2
	move.l a0, d2			; Source address to d2
	POPM.W  d0/d1			; Restore original size/dest
	add.l  d4, d2			; Offset source address (bytes)
	add.w  d4, d0			; Offset dest address (bytes)
	lsr.w  #0x1, d4			; Job 1 size to words
	sub.w  d4, d1			; Subtract job 1 size (words)
	bsr    VDPDMA_AddToQueue
	
	rts

VDPDMA_AddToQueue:
    ; ======================================
    ; Pushes a DMA job to the queue - for
	; internal use only. Use VDPDMA_AddJob.
    ; ======================================
	; d0 (w) - Dest addr (VRAM space)
	; d1 (w) - Data size (words)
	; d2 (l) - Source addr (68k space)
	; d6 (b) - Autoincrement
	; d7 (b) - Dest memory (VDPDMA_TRANSFER_VRAM/VDPDMA_TRANSFER_CRAM)
    ; ======================================

	; Get queue address
	move.l RAM_VDP_DMA_QUEUE_NEXT, a1

	IFND FINAL
	tst.w d1
	bne   @NonZero
	DBG_RAISE_ERROR "Error: DMA size is 0"
	@NonZero:
	cmp.l #RAM_VDP_DMA_QUEUE+(SIZEOF_VDPDMAJob*VDPDMA_MAX_QUEUE_SIZE), a1
	bne   @NotFull
	DBG_RAISE_ERROR "Error: DMA queue full"
	@NotFull:
	ENDIF
	
	; Add DMA mode to top byte of address
	lsr.l  #0x1, d2							; Source addr to words
	andi.l #VDP_DMA_ADDR_MASK_WRITE_L, d2	; Top byte mask (to fit DMA mode)
	ori.l  #(VDP_DMA_MODE_TRANSFER<<16), d2	; DMA mode 0

	; Write source addr and size stream
	move.l  #$94009300, (a1)+				; Size hi and lo (regs 13 and 14) set commands
	move.l  #$97009600, (a1)+				; Source addr lo and mid (regs 15 and 16) set commands
	move.w  #$9500, (a1)+					; Source addr hi and mode (reg 17) set command
	movep.l d2, -7(a1)						; Disperse source address and DMA mode bytes first (or will overwrite size)
	movep.w d1, -9(a1)						; Disperse size bytes

	; Write autoincrement reg set command stream
	move.w  #0x8F00, d1
	move.b  d6, d1
	move.w  d1, (a1)+

	; Write dest addr and command stream
	andi.l  #0xFFFF, d0
	lsl.l   #0x2, d0						; Shift bits 14/15 of dest address to bits 16/17
	lsr.w   #0x2, d0						; Shift lower word back
	swap    d0								; Swap address hi/lo
	cmp.b   #VDPDMA_TRANSFER_VRAM, d7
	bne     @CRAM
	ori.l   #VDP_CMD_DMA_VRAM_WRITE, d0		; OR in VRAM+DMA write command
	bra     @VRAM
	@CRAM:
	ori.l   #VDP_CMD_DMA_CRAM_WRITE, d0		; OR in VRAM+DMA write command
	@VRAM:
	move.l  d0, (a1)+						; Set dest addr bytes

	; Advance queue
	move.l  a1, RAM_VDP_DMA_QUEUE_NEXT

	rts
	
VDPDMA_CommitAndClearQueue:
    ; ======================================
    ; Processes all DMA transfers and clears
	; the job queue
    ; ======================================
	; No params
    ; ======================================

	; Get queue address
	lea    RAM_VDP_DMA_QUEUE, a1

	; Get queue end
	move.l RAM_VDP_DMA_QUEUE_NEXT, a2

	; Check empty
	cmp.l  a1, a2
	beq    @NoJobs

	; Backup VDP regs 1 (DMA enable) and F (autoincrement)
	; TODO
	;VDP_GETREG 0x1, d4
	;VDP_GETREG 0xF, d6
	
	; Enable DMA
	; TODO
	;ori.w   #0x10, d4  			; Set register 1 + DMA bit (5)
	;VDP_SETREG 1, d4

	; Prepare VDP control port addr
	move.l  #PORT_VDP_CONTROL, a6

	; Take Z80 bus
	; TODO
	;jsr    Z80_TakeBus
	
	; Execute jobs
	@QueueLoop:
	INT_DISABLE
	move.l (a1)+, (a6)	; Size hi/lo
	move.l (a1)+, (a6)	; Source addr hi/mid + DMA mode
	move.l (a1)+, (a6)	; Source addr lo + dest addr/DMA command hi word
	move.l (a1)+, (a6)	; Autoincrement command, and dest addr/DMA command lo word
	INT_RESTORE
	cmp.l  a1, a2
	bne    @QueueLoop

	; Release Z80 bus
	; TODO
	;jsr   Z80_ReleaseBus

	; Disable DMA
	; TODO
	;andi.b  #0xEF, d4 				; Clear DMA bit (5)

	; Restore VDP regs 1 (DMA enable) and F (autoincrement)
	; TODO
	;VDP_SETREG 0x1, d4
	;VDP_SETREG 0xF, d6
	
	; Clear queue
	move.l #RAM_VDP_DMA_QUEUE, RAM_VDP_DMA_QUEUE_NEXT
	
	@NoJobs:

	rts
	
VDPDMA_TransferImmediateVRAM:
    ; ======================================
    ; DMA transfer from 68K space to VRAM
	; immediately (bypassing queue). Splits
	; into two blocks if crossing 64kb
	; boundary.
    ; ======================================
	; a0   Source address
	; d0.w Dest address (VRAM)
	; d1.w Size in words
    ; ======================================

	; If block crosses a 128kb boundary, split into two jobs
	; (but simpler to do with 64kb, can just use carry flag)
	move.l a0, d2
	move.w d1, d3
	add.w  d3, d3		; Words to bytes
	add.w  d3, d2		; Add size to lower 16 bits of address
	bcs    @SplitDMA	; Branch if Carry Set (result overflowed across 16 bit boundary)
	
	@SingleDMA:
	
	; Single DMA
	bsr    VDPDMA_TransferImmediateVRAM_NoBoundary
	
	rts
	
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
	bsr    VDPDMA_TransferImmediateVRAM_NoBoundary
	
	; DMA 2
	POPM.W  d0/d1			; Restore original size/dest
	add.l  d6, d2			; Offset source address (bytes)
	add.w  d6, d0			; Offset dest address (bytes)
	lsr.w  #0x1, d6			; Job 1 size to words
	sub.w  d6, d1			; Subtract job 1 size (words)
	bsr    VDPDMA_TransferImmediateVRAM_NoBoundary
	
	rts

VDPDMA_TransferImmediateVRAM_NoBoundary:
    ; ======================================
    ; DMA transfer from 68K space to VRAM
	; immediately (bypassing queue).
	; Source data cannot cross 64kb boundary
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