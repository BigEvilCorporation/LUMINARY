; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 15th July 2019
; ============================================================================================
; STACK.ASM - Macros for stack manipulation
; ============================================================================================

PUSH: macro src
    ; ======================================
    ; Push single value to stack
    ; ======================================
    ; .X   - Value size
    ; src  - Value/source
    ; ======================================
    move.\0 \src, -(sp)
    endm
	
POP: macro dst
    ; ======================================
    ; Pop single value from stack
    ; ======================================
    ; .X   - Value size
    ; dst  - Destination
    ; ======================================
    move.\0 (sp)+, \dst
    endm

PUSHM: macro regs
    ; ======================================
    ; Push multiple regs to stack
    ; ======================================
    ; .X   - Value size
    ; regs - Register list
    ; ======================================
	 movem.\0 \regs, -(sp)
	 endm
	 
POPM: macro regs
    ; ======================================
    ; Pop multiple regs from stack
    ; ======================================
    ; .X   - Value size
    ; regs - Register list
    ; ======================================
	movem.\0 (sp)+, \regs
	endm

PUSHALL: macro
    ; ======================================
    ; Push d0-d7/a0-a6 to stack
    ; ======================================
    ; No params
    ; ======================================
	 movem.l d0-d7/a0-a6, -(sp)
	 endm
	 
POPALL: macro
    ; ======================================
    ; Pop d0-d7/a0-a6 from stack
    ; ======================================
    ; No params
    ; ======================================
	movem.l (sp)+, d0-d7/a0-a6
	endm

STACK_ALLOC: macro bytes,addr_reg
    ; ======================================
    ; Allocate bytes from stack
    ; ======================================
    ; bytes    - Bytes to alloc
    ; addr_reg - Dest address reg
    ; ======================================
	sub.l  \bytes, sp
    move.l sp, \addr_reg
	endm

STACK_ALLOC_STRING: macro bytes,addr_reg
    ; ======================================
    ; Allocate bytes from stack for string
    ; use (terminates first byte)
    ; ======================================
    ; bytes    - Bytes to alloc
    ; addr_reg - Dest address reg
    ; ======================================
	sub.l  \bytes, sp
    move.l sp, \addr_reg
    move.b #0x0, (\addr_reg)
	endm
	
STACK_FREE: macro bytes
    ; ======================================
    ; Free bytes to stack
    ; ======================================
    ; bytes    - Bytes to free
    ; ======================================
	addi.l \bytes, sp
	endm