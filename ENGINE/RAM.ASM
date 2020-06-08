; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; RAM.ASM - RAM manipulation
; ============================================================================================

RAM_Clear:
    ; ===========================================
    ; Clears 64kb 68000 RAM !! INCLUDING STACK !!
    ; Only call from top callstack level
    ; ===========================================
    ; No params
    ; ===========================================

    move.l (sp), d2			   ; Backup return address

    move.l #RAM_START, a0
    moveq  #0x0, d1
    move.w #(RAM_SIZE_L/8)-1, d0
    @Lp:
    move.l d1, (a0)+
    move.l d1, (a0)+
    move.l d1, (a0)+
    move.l d1, (a0)+
    move.l d1, (a0)+
    move.l d1, (a0)+
    move.l d1, (a0)+
    move.l d1, (a0)+
    dbra   d0, @Lp

    move.l #STACK_TOP, sp	   ; Reset stack
	move.l d2, -(sp)		   ; Restore return address

    rts
