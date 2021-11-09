; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; LUMINARY.ASM - main engine include file
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
    include 'engine/macros/strings.asm'
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
    include 'engine/z80.asm'

    ; Game framework macros
    include 'framewk/macros/entity.asm'
    include 'framewk/macros/entmgr.asm'
    include 'framewk/macros/script.asm'
    include 'framewk/macros/sprite.asm'
    include 'framewk/macros/vector2.asm'
    include 'framewk/macros/vfx.asm'
    include 'framewk/macros/yarn.asm'

    ; Game framework
    include 'framewk/canvas.asm'
    include 'framewk/camera.asm'
    include 'framewk/dialogue.asm'
    include 'framewk/entity.asm'
    include 'framewk/entmgr.asm'
    include 'framewk/geometry.asm'
    include 'framewk/maths3d.asm'
    include 'framewk/physutil.asm'
    include 'framewk/scene.asm'
    include 'framewk/script.asm'
    include 'framewk/scriptfn.asm'
    include 'framewk/text.asm'
    include 'framewk/yarn.asm'

    ; Entities and components
    include 'framewk/entities/ephysbas.asm'
    include 'framewk/entities/ephyschr.asm'
    include 'framewk/entities/eplatfrm.asm'
    include 'framewk/entities/eprefab.asm'
    include 'framewk/entities/espawner.asm'
    include 'framewk/entities/escript.asm'
    include 'framewk/entities/esprite.asm'
    include 'framewk/entities/evfx.asm'

    ; Memory maps
    include 'engine/memmap.asm'
    include 'framewk/memmap.asm'
