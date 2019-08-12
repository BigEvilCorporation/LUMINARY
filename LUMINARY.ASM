; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; LUMINARY.ASM - main engine include file
; ============================================================================================
; Include files from game project the following order:
;
;  - bootstrp.asm
;  - game/header.asm
;  - luminary.asm (this file)
;  - game/memmap.asm
;  - engine/assets.asm
;  - Everything else...
;
; ============================================================================================

    ; Engine macros
    include 'engine/macros/assets.asm'
    include 'engine/macros/debug.asm'
    include 'engine/macros/interpts.asm'
    include 'engine/macros/linklist.asm'
    include 'engine/macros/memory.asm'
    include 'engine/macros/sprites.asm'
    include 'engine/macros/stack.asm'
    include 'engine/macros/struct.asm'
    include 'engine/macros/vdp.asm'

    ; Engine
    include 'engine/bootstrp.asm'
    include 'engine/dbgdraw.asm'
    include 'engine/error.asm'
    include 'engine/gamepad.asm'
    include 'engine/interpts.asm'
    include 'engine/map.asm'
    include 'engine/palettes.asm'
    include 'engine/ram.asm'
    include 'engine/sprites.asm'
    include 'engine/strings.asm'
    include 'engine/tiles.asm'
    include 'engine/vdp.asm'
    include 'engine/vdpdma.asm'
    include 'engine/vdpregs.asm'
    include 'engine/vram.asm'
    include 'engine/vrammgr.asm'

    ; Game framework macros
    include 'framewk/macros/entity.asm'
    include 'framewk/macros/entmgr.asm'

    ; Game framework
    include 'framewk/entity.asm'
    include 'framewk/entmgr.asm'
    include 'framewk/scene.asm'

    ; Entities and components
    include 'framewk/entities/physbody.asm'
    include 'framewk/entities/sprite.asm'

    ; Memory maps
    include 'engine/memmap.asm'
    include 'framewk/memmap.asm'