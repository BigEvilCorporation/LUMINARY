; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; HELLO.ASM - "Hello world" using Luminary Engine
; ============================================================================================

    ; Code includes
    include 'bootstrp.asm'
    include 'samples/hello/system/header.asm'
    include 'luminary.asm'
    include 'samples/hello/system/memmap.asm'
    include 'samples/hello/entities/player.asm'

DRAW_VRAM: macro
    PUSH.L a0
    bsr    ERR_ResetForError
    bsr    VRAMMGR_DrawTable
    POP.L  a0
    endm

Main:
    ; ======================================
    ; Program entry point
    ; ======================================
    ; Called from bootstrap only
    ; ======================================

    ; Initialise entity manager
    ; TODO: LuminaryInit
    bsr    ENT_Initialise

    ; Initialise camera
    ; TODO: LuminaryInit
    bsr    CAM_Initialise

    ; Load scene
    lea    RAM_TESTSCENE1, a0
    lea    SceneData_tst1_tst1, a1
    bsr    SCN_LoadScene

    ; Load palettes
    lea    palette_sonic, a0
    move.b #0x3, d0
    bsr    VDP_LoadPalette
    
    @Lp:

    ;DRAW_VRAM

    ; Update
    bsr    ENT_UpdateAll
    bsr    ECPhysicsBody_Step
    bsr    CAM_UpdateAll
    bsr    MAP_ClampScroll
    bsr    MAP_UpdateStreaming

    ; Draw
    bsr    ECSprite_DrawAll

    ; Wait vsync
    bsr    VDP_WaitVSync

    ; DMA and VDP
    bsr    MAP_ApplyScroll
    bsr    VDPDMA_CommitAndClearQueue
    bsr    SPR_CommitAndClearTable

    ; Loop forever
    bra    @Lp

    ; Asset includes
	include 'engine/assets.asm'

    ; Scene data
    include 'samples/hello/data/scenes/chaptr01/include.asm'

    ; Sprite data
    include 'samples/hello/data/sprites/sprites.asm'
    include 'samples/hello/data/anims/sprtanms.asm'
    include 'samples/hello/data/palettes/sprtpals.asm'
