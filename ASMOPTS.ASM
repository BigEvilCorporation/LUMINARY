; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 22nd December 2019
; ============================================================================================
; ASMOPTS.ASM - Assembler optimisation options and section directives
; ============================================================================================
; !! MUST BE FIRST FILE INCLUDED !!
; ============================================================================================

; Assembler optimisations
    OPT op+,os+,ow+,oz+,oaq+,osq+,omq+

;GROUP_SCRIPT_TABLE Group ; file('scriptbl.bin')

; Section layout
    Section    SECTION_VECTOR_TABLE
    Section    SECTION_HEADER
    Section    SECTION_MAIN
    Section    SECTION_SCRIPT_TABLE ;,GROUP_SCRIPT_TABLE

; Begin main section
    Section    SECTION_MAIN