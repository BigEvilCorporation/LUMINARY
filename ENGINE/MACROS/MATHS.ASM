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

ABS: macro valuereg
    ; ======================================
    ; Get positive absolute
    ; ======================================
    ; valuereg   - In/out: value to abs
	; ======================================
	cmp.\0 #0x0, \valuereg
	bge   @Pos\@
	neg.\0 \valuereg
	@Pos\@:
	endm

MAX: macro value_a,value_b,output
    ; ======================================
    ; Returns the max of two values
    ; ======================================
    ; value_a    - Value 1
    ; value_b    - Value 2
    ; output     - Return value
    ; ======================================
	move.\0 \value_a, \output
	cmp.\0  \value_a,\value_b
	blt     @A\@
	move.\0 \value_b, \output
	@A\@:
	endm