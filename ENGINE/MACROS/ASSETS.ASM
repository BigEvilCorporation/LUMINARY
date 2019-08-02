; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; ASSETS.ASM - Macros for including and managing text and binary assets
; ============================================================================================

ASSET_INCLUDE_BIN: macro name,path
\name:
    incbin \path
    even
\name\_end
SIZEOF_\name\ equ \name\_end-\name
    endm

ASSET_INCLUDE_ASM: macro name,path
\name:
    include \path
    even
\name\_end
SIZEOF_\name\ equ \name\_end-\name
    endm