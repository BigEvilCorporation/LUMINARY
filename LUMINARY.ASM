; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; LUMINARY.ASM - main engine include file
; ============================================================================================
; Include files from game project the following order:
;
;  - game/bldconf.asm (if applicable)
;  - engine/consts.asm
;  - engine/vectrtab.asm
;  - game/header.asm
;  - luminary.asm (this file)
;  - game/memmap.asm
;  - engine/assets.asm
;  - Everything else...
;
; ============================================================================================

    ; Default build config
    include 'engine/bldconf.asm'

    ; Macros
    include 'engine/macros/assets.asm'
    include 'engine/macros/debug.asm'
    include 'engine/macros/interpts.asm'
    include 'engine/macros/memory.asm'
    include 'engine/macros/stack.asm'
    include 'engine/macros/struct.asm'
    include 'engine/macros/vdp.asm'

    ; Engine
    include 'engine/bootstrp.asm'
    include 'engine/dbgdraw.asm'
    include 'engine/error.asm'
    include 'engine/gamepad.asm'
    include 'engine/interpts.asm'
    include 'engine/palettes.asm'
    include 'engine/ram.asm'
    include 'engine/strings.asm'
    include 'engine/tiles.asm'
    include 'engine/vdp.asm'
    include 'engine/vdpregs.asm'
    include 'engine/vram.asm'
    include 'engine/vrammgr.asm'

    ; Memory map
    include 'engine/memmap.asm'