; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; BLDCONF.ASM - Game framework build config - override with BLDCONF_FRAMEWORK_CUSTOM_DEFINED
; ============================================================================================

    IFND BLDCONF_FRAMEWORK_CUSTOM_DEFINED

; Entity/component system block size
BLDCONF_ENT_BLOCK_SIZE                  equ 32

    ENDIF
