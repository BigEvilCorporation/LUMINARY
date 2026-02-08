; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 31st October 2021
; ============================================================================================
; YARN.ASM - A Yarn VM implementation, designed for use with data from YarnToLuminary.exe
; ============================================================================================

YARN_RUNLINE: macro string
	; =======================================
	; Displays a dialog line, waits for input
	; =======================================
	; string   - Address of string to display
	; =======================================
	move.l \string, a0
    move.w #DLG_DEFAULT_X, d1
    move.w #DLG_DEFAULT_Y, d2
	jsr    DLG_Open
	move.l #\@NextInstr\@, RAM_YARN_ENTRY_ADDR
	move.b #YARN_STATE_WAITING_DLG, RAM_YARN_STATE
	rts
	\@NextInstr\@:
	endm

YARN_ADDOPTION: macro string,address
    moveq  #0, d0
    move.b RAM_YARN_CHOICE_COUNT, d0
    move.w d0, d1
    lsl.w  #3, d0   ; count * longwords * 2
    lea    RAM_YARN_CHOICE_LIST, a0
    adda.w d0, a0
    move.l \string, (a0)+
    move.l \address, (a0)+
    move.l #0x0, (a0)+
    addq.w #1, d1
    move.b d1, RAM_YARN_CHOICE_COUNT
	endm

YARN_SHOWOPTIONS: macro
    move.l #0, a0
    lea    RAM_YARN_CHOICE_LIST, a2
    move.b RAM_YARN_CHOICE_COUNT, d0
    move.w #DLG_DEFAULT_X, d1
    move.w #DLG_DEFAULT_Y, d2
	jsr    DLG_OpenChoice
	move.l #\@NextInstr\@, RAM_YARN_ENTRY_ADDR
	move.b #YARN_STATE_WAITING_CHOICE, RAM_YARN_STATE
	rts
	\@NextInstr\@:
	endm

YARN_JUMP: macro
    move.l RAM_YARN_STACK_PTR, a1
    move.l (a1), a0
    jmp    (a0)
	endm

YARN_JUMPTO: macro address
    jmp    \address
	endm

YARN_PUSHSTRING: macro string
    move.l RAM_YARN_STACK_PTR, a1
    move.l \string, (a1)+
    move.l a1, RAM_YARN_STACK_PTR
	endm

YARN_POP: macro
    move.l RAM_YARN_STACK_PTR, a1
    move.l -(a1), a0
    move.l a1, RAM_YARN_STACK_PTR
	endm

YARN_RUNNODE: macro
    YARN_POP
    jsr    (a0)
	endm

YARN_STOP: macro
    move.b #YARN_STATE_STOPPED, RAM_YARN_STATE
    rts
	endm
