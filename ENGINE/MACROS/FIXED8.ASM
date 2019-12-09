; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 9th November 2019
; ============================================================================================
; FIXED8.ASM - Fixed point 8.8 maths macros
; ============================================================================================

FIXED8_TO_INT: macro valuereg
    ; ======================================
    ; Converts a fixed point 8.8 number
    ; to integer word
    ; ======================================
    ; In:
    ;  value.l     - Fixed 8.8 to convert
    ; Out:
    ;  value.w     - Integer
    ; ======================================
    lsr.w  #0x8, \valuereg
    endm

INT_TO_FIXED8: macro valuereg
    ; ======================================
    ; Converts a signed integer word to a
    ; fixed point 8.8 number
    ; ======================================
    ; In:
    ;  value.w     - Integer to convert
    ; Out:
    ;  value.l     - Fixed 8.8
    ; ======================================
    lsl.w  #0x8, \valuereg
    endm

FIXED8_MUL: macro multiplier, value
    ; ======================================
    ; Multiplies two fixed point 8.8
    ; numbers
    ; ======================================
    ; In:
    ;  value.w      - Fixed 8.8 number to multiply
    ;  multiplier.w - Fixed 8.8 multiplier
    ; Out:
    ;  value.l      - Fixed 8.8
    ; ======================================
    mulu   \multiplier, \value
    lsr.l  #0x8, \value
    endm