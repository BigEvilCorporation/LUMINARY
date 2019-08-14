; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; BLDCONF.ASM - Engine build config - override with BLDCONF_ENGINE_CUSTOM_DEFINED
; ============================================================================================

    IFND BLDCONF_ENGINE_CUSTOM_DEFINED

; Stack size
BLDCONF_STACK_SIZE                      equ 1024

; Debugging and asserts
BLDCONF_VRAM_MGR_DEBUG                  equ 1

; Map streaming
BLDCONF_MAP_STREAM_STAMP_WIDTH          equ 32
BLDCONF_MAP_STREAM_STAMP_HEIGHT         equ 32
BLDCONF_MAP_STREAM_STAMP_WIDTH_SHIFT    equ 0x5
BLDCONF_MAP_STREAM_STAMP_HEIGHT_SHIFT   equ 0x5

    ENDIF
