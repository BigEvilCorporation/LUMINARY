; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; BLDCONF.ASM - Engine build config - override with BLDCONF_DEFINED
; ============================================================================================

    IFND BLDCONF_DEFINED

; Error checks
BLDCONF_ERROR_CHECKS                    equ 1

; Debug draw
BLDCONF_DEBUG_DRAW                      equ 1

    ENDIF
