; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 9th November 2019
; ============================================================================================
; FIXED16.ASM - Fixed point 16.16 maths macros
; ============================================================================================

FIXED16_TO_INT: macro valuereg
    ; ======================================
    ; Converts a fixed point 16.16 number
    ; to integer word
    ; ======================================
    ; In:
    ;  value.l     - Fixed 16.16 to convert
    ; Out:
    ;  value.w     - Integer
    ; ======================================
    swap   \valuereg
    endm

INT_TO_FIXED16: macro valuereg
    ; ======================================
    ; Converts a signed integer word to a
    ; fixed point 16.16 number
    ; ======================================
    ; In:
    ;  value.w     - Integer to convert
    ; Out:
    ;  value.l     - Fixed 16.16
    ; ======================================
    swap   \valuereg
    move.w #0x0, \valuereg
    endm