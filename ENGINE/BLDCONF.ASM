; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; BLDCONF.ASM - Engine build config - override with BLDCONF_DEFINED
; ============================================================================================

    IFND BLDCONF_CUSTOM_DEFINED

; Debugging and asserts
BLDCONF_VRAM_MGR_DEBUG                  equ 1

    ENDIF
