; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 4th August 2019
; ============================================================================================
; BOOTSTRP.ASM - First include file, includes bldconf, consts, and vector table
; ============================================================================================
; See LUMINARY.ASM for example include order
; ============================================================================================

    ; Build configs
    include 'engine/bldconf.asm'
    include 'framewk/bldconf.asm'

    ; Constants
    include 'engine/consts.asm'
    include 'framewk/consts.asm'

    ; 68000 vector table
    include 'engine/vectrtab.asm'