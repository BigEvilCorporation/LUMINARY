; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; INTERPTS.ASM - Interrupt macros
; ============================================================================================

; Disable interrupts (pushes to stack)
INT_DISABLE: macro
	PUSH.W sr
	ori.w  #CPU_STATUS_REG_INT_DISABLE, sr
	endm

; Restore interrupts (pops from stack)
INT_RESTORE: macro
	POP.W  sr
	endm