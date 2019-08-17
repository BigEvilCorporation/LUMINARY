; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 17th August 2019
; ============================================================================================
; MATHS.ASM - Maths utility macros
; ============================================================================================

CLAMP: macro valuereg,min,max
    ; ======================================
    ; Clamps a value from min to max
    ; ======================================
    ; .X         - Element size
    ; valuereg   - In/out: value to clamp
    ; min        - Minimum value
    ; max        - Maximum value
    ; ======================================
	cmp.\0 \min,\valuereg
	bge    @WITHIN_MIN\@
	move.\0 \min,\valuereg
	@WITHIN_MIN\@:
	cmp.\0  \max,\valuereg
	ble    @WITHIN_MAX\@
	move.\0 \max,\valuereg
	@WITHIN_MAX\@:
	endm