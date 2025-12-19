; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 17th August 2019
; ============================================================================================
; MATHS.ASM - Maths utility macros
; ============================================================================================

BYTES_TO_WORDS: macro reg
    ; ======================================
    ; Converts bytes to words
    ; ======================================
    ; .X         - Element size
	; reg        - In/out: value to convert
	; ======================================
	lsl.\0 \reg
	endm

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
    ; .X         - Element size
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
    ; .X         - Element size
    ; value_a    - In/out: Value 1
    ; value_b    - Value 2
    ; ======================================
	cmp.\0  \value_b, \value_a
	blt     @A\@
	move.\0 \value_b, \value_a
	@A\@:
	endm

LERP_INT1024: macro destreg,A,B,T,tempreg
    ; ======================================
    ; Integer linear interpolation between A and B by T (0-1024)
    ; (A*(1024-T) + B * T) >> 10
    ; ======================================
    ; destreg    - Output
    ; A          - Source value
    ; B          - Target value
    ; T          - Time (0-1024)
    ; tempreg    - Temp reg
    ; ======================================
	move.l #1024,\tempreg		; Backup T
	sub.l  \T,\tempreg	; (1024-T)
	mulu   \tempreg,\A		; A*(1024-T)
	mulu   \T,\B			; B*T
	add.l  \A,\B			; (A*(1024-T) + B * T)
	lsr.l  #0x8,\B			; (A*(1024-T) + B * T) >> 10
	lsr.l  #0x2,\B
	move.l \B,\destreg
	endm