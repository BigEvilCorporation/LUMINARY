; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; STRINGS.ASM - String manipulation
; ============================================================================================

STR_LenA:
	; ======================================
    ; Walks an ASCII string to calculate its
	; length
    ; ======================================
    ; In:
	; a0   String
	; Out:
	; d0.w Length
    ; ======================================

	move.l a0, a1
	moveq  #0, d0
	@Lp:
	tst.b  (a1)+
	beq    @End
	addq.w #1, d0
	bra    @Lp
	@End:

	rts

STR_CopyA:
	; ======================================
    ; Copy a null terminated ASCII string
    ; ======================================
    ; In:
	; a0   Destination
	; a1   String to copy
    ; ======================================

	@CopyLp:
	move.b (a1)+, (a0)+
	bne    @CopyLp

	rts

STR_CopyA_s:
	; ======================================
    ; Copy a null terminated ASCII string
	; with max destination count
    ; ======================================
    ; In:
	; a0   Destination
	; a1   String to copy
	; d0.w Max string length
    ; ======================================

	subi.w #0x1, d0
	@CopyLp:
	move.b (a1)+, (a0)+
	beq    @End
	dbra.w d0, @CopyLp
	@End:

	rts

STR_ConcatA:
	; ======================================
    ; Concatenates two ASCII strings
    ; ======================================
    ; In:
	; a0   String to append to
	; a1   String to append
    ; ======================================
    ; Out:
    ; a0   String address
	; a1   String end address
    ; ======================================

	move.l a0, a2

	; Find end of string A
	@FindTermLp:
	tst.b  (a0)
	beq    @FoundEnd
	adda.l #0x1, a0
	bra    @FindTermLp
	@FoundEnd:

	; Copy string B until end
	@CopyLp:
	move.b (a1)+, (a0)+
	bne    @CopyLp

	move.l a0, a1	; String end
	move.l a2, a0	; String start

	rts

STR_ConcatLong:
	; ======================================
    ; Concatenates a packed 4-char string
	; from a register, and termminates
    ; ======================================
    ; In:
	; a0   String to append to
	; d0.l String to append (4 chars packed)
    ; ======================================
    ; Out:
    ; a0   String address
	; a1   String end address
    ; ======================================

	move.l a0, a2

	; Copy from reg
	move.b d0, (a0)+
	lsr.l  #0x8, d0
	move.b d0, (a0)+
	lsr.l  #0x8, d0
	move.b d0, (a0)+
	lsr.l  #0x8, d0
	move.b d0, (a0)+

	; Terminate
	move.b #0x0, (a0)+

	move.l a0, a1	; String end
	move.l a2, a0	; String start

	rts

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
	lsr.b  #0x4, d0			; Next nybble
	dbra   d2, @NybbleLp	; Loop
	bra    @End
	@Numeric:
	addi.b #STR_ASCII_NUMERIC_OFFSET, d3	; In numeric range (0 - 9)
	move.b d3, -(a0)		; Back to string
	lsr.b  #0x4, d0			; Next nybble
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

STR_ItoA_Hex_l
    ; ======================================
    ; Converts a longword to hex ASCII
    ; ======================================
    ; In:
	; a0   String address
	; d0.l Number to convert
    ; ======================================
    ; Out:
    ; a0   String address
    ; a1   String end address
    ; ======================================

	; 8 nybbles + terminator, working backwards
    move.l a0, a1
	addi.l #0x9, a0
    addq.l #0x8, a1                     ; End addr - terminator

	; Zero terminate
	move.b #0x0, -(a0)

	move.w #0x0, d1	; Char ptr
	move.w #0x7, d2	; 8 nybbles in a longword

	@NybbleLp:
	move.b d0, d3			; Byte to d3
	andi.b #0x0F, d3		; Bottom nybble
	cmp.b  #0x9, d3
	ble    @Numeric			; Branch if in numeric range
	addi.b #(STR_ASCII_ALPHA_OFFSET-0xA), d3	; In alpha range (A - F)
	move.b d3, -(a0)		; Back to string
	lsr.l  #0x4, d0			; Next nybble
	dbra   d2, @NybbleLp	; Loop
	bra    @End
	@Numeric:
	addi.b #STR_ASCII_NUMERIC_OFFSET, d3	; In numeric range (0 - 9)
	move.b d3, -(a0)		; Back to string
	lsr.l  #0x4, d0			; Next nybble
	dbra   d2, @NybbleLp	; Loop

	@End:

	rts

STR_Concat_ItoA_Hex_l
    ; ======================================
    ; Converts a longword to hex ASCII and
	; concatenates to end of exist string
    ; ======================================
    ; In:
	; a0   String to append to
	; d0.l Number to convert
    ; ======================================
    ; Out:
    ; a0   String address
    ; a1   String end address
    ; ======================================

	move.l a0, a2

	; Find end of string
	@FindTermLp:
	tst.b  (a0)
	beq    @FoundEnd
	adda.l #0x1, a0
	bra    @FindTermLp
	@FoundEnd:

	; Concat ItoA
	bsr    STR_ItoA_Hex_l

	move.l a2, a0

	rts