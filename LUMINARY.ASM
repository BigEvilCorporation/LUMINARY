; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; LUMINARY.ASM - main engine include file
; ============================================================================================
; Include files from game project the following order:
;
;  - asmopts.asm
;  - bootstrp.asm
;  - game/header.asm
;  - luminary.asm (this file)
;  - game/memmap.asm
;  - engine/assets.asm
;  - Everything else...
;
; ============================================================================================

    ; Bootstrap
    include 'bootstrp.asm'

    ; Engine macros
    include 'engine/macros/assets.asm'
    include 'engine/macros/debug.asm'
    include 'engine/macros/collisn.asm'
    include 'engine/macros/fixed8.asm'
    include 'engine/macros/fixed16.asm'
    include 'engine/macros/interpts.asm'
    include 'engine/macros/linklist.asm'
    include 'engine/macros/map.asm'
    include 'engine/macros/maths.asm'
    include 'engine/macros/memory.asm'
    include 'engine/macros/sprites.asm'
    include 'engine/macros/stack.asm'
    include 'engine/macros/struct.asm'
    include 'engine/macros/vdp.asm'

    ; Engine
    include 'engine/bootstrp.asm'
    include 'engine/collisn.asm'
    include 'engine/dbgdraw.asm'
    include 'engine/error.asm'
    include 'engine/exceptn.asm'
    include 'engine/font.asm'
    include 'engine/gamepad.asm'
    include 'engine/interpts.asm'
    include 'engine/map.asm'
    include 'engine/palettes.asm'
    include 'engine/ram.asm'
    include 'engine/sinewave.asm'
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
    include 'framewk/macros/sprite.asm'
    include 'framewk/macros/vfx.asm'

    ; Game framework
    include 'framewk/camera.asm'
    include 'framewk/entity.asm'
    include 'framewk/entmgr.asm'
    include 'framewk/geometry.asm'
    include 'framewk/scene.asm'

    ; Script system
    include 'framewk/script/script.asm'
    include 'framewk/script/engine.asm'

    ; Entities and components
    include 'framewk/entities/physbasc.asm'
    include 'framewk/entities/physchar.asm'
    include 'framewk/entities/physutil.asm'
    include 'framewk/entities/platform.asm'
    include 'framewk/entities/spawner.asm'
    include 'framewk/entities/script.asm'
    include 'framewk/entities/sprite.asm'
    include 'framewk/entities/vfx.asm'

    ; Memory maps
    include 'engine/memmap.asm'
    include 'framewk/memmap.asm'
