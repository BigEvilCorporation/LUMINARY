; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 10th April 2020
; ============================================================================================
; SCRIPT.ASM - Script helper macros
; ============================================================================================

    ; ======================================
    ; Declares a script function within an
    ; entity/component
    ; ======================================
    ; Routine
    ; Return val
    ; Name
    ; type,param,type,param,type,param...
    ; ======================================
SCRIPT_FUNC: macro
    
    endm

SCRIPTFUNC_GETPARAM: macro index,outreg
    ; ======================================
    ; Fetches a script param from stack
    ; (C++ calling convention)
    ; ======================================
    ; index    Index of param (left to right)
    ; outreg   Reg to copy to
    ; ======================================
    ; Stack:
    ;   0(sp) = return addr
    ;   4(sp) = param 1...
    ;   8(sp) = param 2...
    ;  12(sp) = param 3...
    ; ======================================
    move.l (4+(index*4))(sp), \outreg
    endm