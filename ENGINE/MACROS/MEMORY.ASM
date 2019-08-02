; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 15th July 2019
; ============================================================================================
; MEMORY.ASM - Macros for memory manipulation
; ============================================================================================

MEMZERO: macro addressreg,countreg
    ; ======================================
    ; Sets block of RAM to 0
    ; ======================================
    ; .X         - Element size
    ; addressreg - Address reg
    ; countreg.w - Num elements reg
    ; ======================================
	subq.w #0x1, \countreg
	PUSH.L \addressreg
	@MEMZERO_LP\@:
	move.\0 #0x0, (\addressreg)+
	dbra   \countreg, @MEMZERO_LP\@
	POP.L  \addressreg
	endm

MEMSET: macro addressreg,value,countreg
    ; ======================================
    ; Sets block of RAM to a value
    ; ======================================
    ; .X         - Element size
    ; addressreg - Address reg
    ; value.X    - Value
    ; countreg.w - Num elements reg
    ; ======================================
	subq.w #0x1, \countreg
	PUSH.L \addressreg
	@MEMSET_LP\@:
	move.\0 \value, (\addressreg)+
	dbra   \countreg, @MEMSET_LP\@
	POP.L  \addressreg
	endm

MEMCPY: macro destreg,sourcereg,countreg
    ; ======================================
    ; Copies block of memory
    ; ======================================
    ; .X         - Element size
    ; destreg    - Destination address reg
    ; sourcereg  - Source address reg
    ; countreg.w - Num elements reg
    ; ======================================
	subq.w  #0x1, \countreg
	PUSHM.L \destreg/\sourcereg
	@MEMCPYB_LP\@:
	move.\0 (\sourcereg)+, (\destreg)+
	dbra    \countreg, @MEMCPYB_LP\@
	POPM.L  \destreg/\sourcereg
	endm