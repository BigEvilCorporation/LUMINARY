; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; STRINGS.ASM - String manipulation
; ============================================================================================

STR_ItoA_Hex_b:
    ; ======================================
    ; Converts a byte to hex ASCII
    ; ======================================
    ; In:
	; a0   String address
	; d0.b Number to convert
    ; ======================================
    ; Out:
    ; a0   String address
    ; a1   String end address
    ; ======================================

	; 2 nybbles + terminator, working backwards
    move.l a0, a1
	addq.l #0x3, a0
    addq.l #0x2, a1                     ; End addr - terminator

	; Zero terminate
	move.b #0x0, -(a0)

	move.w #0x0, d1	; Char ptr
	move.w #0x1, d2	; 2 nybbles in a word

	@NybbleLp:
	move.b d0, d3			; Byte to d3
	andi.b #0x0F, d3		; Bottom nybble
	cmp.b  #0x9, d3
	ble    @Numeric			; Branch if in numeric range
	addi.b #(STR_ASCII_ALPHA_OFFSET-0xA), d3	; In alpha range (A - F)
	move.b d3, -(a0)		; Back to string
	lsr.w  #0x4, d0			; Next nybble
	dbra   d2, @NybbleLp	; Loop
	bra    @End
	@Numeric:
	addi.b #STR_ASCII_NUMERIC_OFFSET, d3	; In numeric range (0 - 9)
	move.b d3, -(a0)		; Back to string
	lsr.w  #0x4, d0			; Next nybble
	dbra   d2, @NybbleLp	; Loop

	@End:

	rts

STR_ItoA_Hex_w:
    ; ======================================
    ; Converts a word to hex ASCII
    ; ======================================
    ; In:
	; a0   String address
	; d0.w Number to convert
    ; ======================================
    ; Out:
    ; a0   String address
    ; a1   String end address
    ; ======================================

	; 4 nybbles + terminator, working backwards
    move.l a0, a1
	addq.l #0x5, a0
    addq.l #0x4, a1                     ; End addr - terminator

	; Zero terminate
	move.b #0x0, -(a0)

	move.w #0x0, d1	; Char ptr
	move.w #0x3, d2	; 4 nybbles in a word

	@NybbleLp:
	move.b d0, d3			; Byte to d3
	andi.b #0x0F, d3		; Bottom nybble
	cmp.b  #0x9, d3
	ble    @Numeric			; Branch if in numeric range
	addi.b #(STR_ASCII_ALPHA_OFFSET-0xA), d3	; In alpha range (A - F)
	move.b d3, -(a0)		; Back to string
	lsr.w  #0x4, d0			; Next nybble
	dbra   d2, @NybbleLp	; Loop
	bra    @End
	@Numeric:
	addi.b #STR_ASCII_NUMERIC_OFFSET, d3	; In numeric range (0 - 9)
	move.b d3, -(a0)		; Back to string
	lsr.w  #0x4, d0			; Next nybble
	dbra   d2, @NybbleLp	; Loop

	@End:

	rts