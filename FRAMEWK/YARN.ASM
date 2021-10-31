; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 31st October 2021
; ============================================================================================
; YARN.ASM - A Yarn VM implementation, designed for use with data from YarnToLuminary.exe
; ============================================================================================

Yarn_Initialise:
	; =======================================
	; Initialises the Yarn VM
	; =======================================

	move.l #0, RAM_YARN_ENTRY_ADDR
	move.b #YARN_STATE_STOPPED, RAM_YARN_STATE
	move.l #RAM_YARN_STACK, RAM_YARN_STACK_PTR

	rts

Yarn_Update:
	; =======================================
	; Ticks the Yarn VM
	; =======================================

	move.b RAM_YARN_STATE, d0
	cmp.b  #YARN_STATE_WAITING_DLG, d0
	beq    @WaitingDlg
	cmp.b  #YARN_STATE_WAITING_CHOICE, d0
	beq    @WaitingChoice
	bra    @End

	@WaitingDlg:
	tst.b  RAM_DIALOG_WAIT_INPUT
	bne    @End
	
	; Re-entry
	move.b #YARN_STATE_RUNNING, RAM_YARN_STATE
	move.l RAM_YARN_ENTRY_ADDR, a0
	jsr    (a0)
	rts

	@WaitingChoice:
	tst.b  RAM_DIALOG_WAIT_INPUT
	bne    @End

	; Re-entry
	moveq  #0, d0
	move.b RAM_DIALOG_CURR_CHOICE, d0
	lsl.w  #3, d0   					; count * longwords * 2
	addq.w #SIZE_LONG, d0				; skip string
	lea    RAM_YARN_CHOICE_LIST, a0
	adda.w d0, a0
	move.l (a0), a3
	move.l #0, RAM_YARN_CHOICE_LIST
	move.b #0, RAM_YARN_CHOICE_COUNT
	jsr    (a3)

	@End:
	rts
