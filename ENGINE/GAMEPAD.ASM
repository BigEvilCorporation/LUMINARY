; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 3rd August 2019
; ============================================================================================
; GAMEPAD.ASM - Gamepad port initialisation and reading
; ============================================================================================

PAD_Initialise:
    ; ======================================
    ; Initialises all gamepad ports.
    ; ======================================
    ; No params
    ; ======================================

    move.b #PAD_BYTE_LATCH, PORT_PAD_CTRL_A  ; Controller port 1 CTRL
	move.b #PAD_BYTE_LATCH, PORT_PAD_CTRL_B  ; Controller port 2 CTRL
	move.b #PAD_BYTE_LATCH, PORT_PAD_CTRL_C  ; EXP port CTRL

    rts

PAD_ReadPortA:
    ; ======================================
    ; Reads gamepad port A
    ; ======================================
    ; In:
    ; No params
    ; ======================================
    ; Out:
    ; d0.w Pad A return result
    ;      (00SA0000 00CBRLDU)
    ; ======================================
	
	move.b #0x0, PORT_PAD_DATA_A        ; Set port to read byte 0
	nop						            ; 2-NOP delay to respond to change
	nop
	move.b PORT_PAD_DATA_A, d0          ; Read byte
	rol.w  #0x8, d0                     ; Move to upper byte of d0
	move.b #PAD_BYTE_LATCH, PORT_PAD_DATA_A ; Set port to read byte 1
	nop						            ; 2-NOP delay to respond to change
	nop
	move.b PORT_PAD_DATA_A, d0          ; Read byte
	
	; Invert and mask
	neg.w  d0
	subq.w #0x1, d0
	andi.w #PAD_BUTTON_ALL, d0

    rts

PAD_ReadPortB:
    ; ======================================
    ; Reads gamepad port B
    ; ======================================
    ; In:
    ; No params
    ; ======================================
    ; Out:
    ; d0.w Pad A return result
    ;      (00SA0000 00CBRLDU)
    ; ======================================
	
	move.b #0x0, PORT_PAD_DATA_B        ; Set port to read byte 0
	nop						            ; 2-NOP delay to respond to change
	nop
	move.b PORT_PAD_DATA_B, d0          ; Read byte
	rol.w  #0x8, d0                     ; Move to upper byte of d0
	move.b #PAD_BYTE_LATCH, PORT_PAD_DATA_B ; Set port to read byte 1
	nop						            ; 2-NOP delay to respond to change
	nop
	move.b PORT_PAD_DATA_B, d0          ; Read byte
	
	; Invert and mask
	neg.w  d0
	subq.w #0x1, d0
	andi.w #PAD_BUTTON_ALL, d0

    rts

PAD_WaitAnyButton:
    ; ======================================
    ; Spins waiting for button press on
    ; any gamepad port, for debugging use.
    ; ======================================
    ; No params
    ; ======================================

    ; Get initial readings
    bsr    PAD_ReadPortA
    move.w d0, d2
    ;bsr    PAD_ReadPortB
    ;move.w d0, d3

    ; Spin until a pad bit goes high
    @Lp:
    bsr    PAD_ReadPortA
    cmp.w  d0, d2
    blt    @End
    move.w d0, d2
    ;bsr    PAD_ReadPortB
    ;cmp.w  d0, d3
    ;blt    @End
    ;move.w d0, d3
    nop
    nop
    bra    @Lp

    @End:

    rts