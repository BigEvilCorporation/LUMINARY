; ============================================================================================
; THE ALEXANDRA PROJECT / THE NICO EXPERIMENT - a game for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 31st October 2021
; ============================================================================================
; YARN.ASM - A Yarn VM implementation, designed for use with data from YarnToLuminary.exe
; ============================================================================================

YARN_STATE_STOPPED			equ 0	; Stopped
YARN_STATE_RUNNING			equ 1	; Running instructions
YARN_STATE_WAITING_DLG		equ 2	; Waiting for dialog dismissal from user
YARN_STATE_WAITING_CHOICE	equ 3	; Waiting for dialog choice selection from user

Yarn_Initialise:
	; =======================================
	; Initialises the Yarn VM
	; =======================================
	; a0   - Default font
	; =======================================

	move.l a0, RAM_YARN_FONT
	move.l #0, RAM_YARN_ENTRY_ADDR
	move.b #YARN_STATE_STOPPED, RAM_YARN_STATE
	move.l #RAM_YARN_STACK, RAM_YARN_STACK_PTR

	rts

YARN_RUNLINE: macro string
	; =======================================
	; Displays a dialog line, waits for input
	; =======================================
	; string   - Address of string to display
	; =======================================
	move.l \string, a0
	move.l RAM_YARN_FONT, a1
	jsr    DLG_Open
	move.l \@NextInstr\@, RAM_YARN_ENTRY_ADDR
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
