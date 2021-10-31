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
	move.l RAM_YARN_FONT, a1
	jsr    DLG_Open
	move.l #\@NextInstr\@, RAM_YARN_ENTRY_ADDR
	move.b #YARN_STATE_WAITING_DLG, RAM_YARN_STATE
	rts
	\@NextInstr\@:
	endm

YARN_ADDOPTION: macro string,address
	endm

YARN_SHOWOPTIONS: macro
	endm

YARN_JUMP: macro
	endm

YARN_JUMPTO: macro address
	endm

YARN_PUSHSTRING: macro string
	endm

YARN_POP: macro
	endm

YARN_RUNNODE: macro
	endm

YARN_STOP: macro
	endm
