; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; HELLO.ASM - "Hello world" using Luminary Engine
; ============================================================================================

    ; Code includes
    include 'luminary.asm'
    include 'samples/hello/system/header.asm'
    include 'samples/hello/system/memmap.asm'
    include 'samples/hello/entities/bridge.asm'
    include 'samples/hello/entities/enemy.asm'
    include 'samples/hello/entities/chopper.asm'
    include 'samples/hello/entities/buzzbomb.asm'
    include 'samples/hello/entities/flicky.asm'
    include 'samples/hello/entities/lrswitch.asm'
    include 'samples/hello/entities/motobug.asm'
    include 'samples/hello/entities/player.asm'
    include 'samples/hello/entities/ring.asm'
    include 'samples/hello/effects/vfx.asm'

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

    ; Set player
    lea    EPlayer_TypeDesc, a0
    bsr    ENT_FindFirstOfType
    move.l a1, RAM_PLAYER_1

    ; Load palettes
    lea    palette_sonic, a0
    move.b #0x3, d0
    bsr    VDP_LoadPalette

    lea    palette_motobug, a0
    move.b #0x2, d0
    bsr    VDP_LoadPalette
    
    @Lp:

    ;DRAW_VRAM

    ; Update
    bsr    ENT_UpdateAll
    bsr    ECScript_StepAll
    bsr    ECPhysBodyChar_StepAll
    bsr    ECPhysBodyBasic_StepAll
    bsr    CAM_UpdateAll
    bsr    MAP_ClampScroll
    bsr    MAP_UpdateStreaming

    ; Draw
    bsr    Game_Render

    ; Wait vsync
    bsr    VDP_WaitVSync

    ; DMA and VDP
    bsr    MAP_ApplyScroll
    bsr    VDPDMA_CommitAndClearQueue
    bsr    SPR_CommitAndClearTable

    ; Loop forever
    bra    @Lp
    rts

Game_Render:

    ; Get camera bounds
    moveq  #0x0, d4
    moveq  #0x0, d5
    moveq  #0x0, d6
    moveq  #0x0, d7

    move.l RAM_CAMERA_CURRENT, a0
    cmpa.w #0x0, a0
    beq    @NoCamera
    move.w Camera_PosX(a0), d4
    move.w Camera_PosY(a0), d5
    move.w d4, d6
    move.w d5, d7
    @NoCamera:

    subi.w #VDP_SCREEN_WIDTH_PX/2, d4     ; Left
    addi.w #VDP_SCREEN_WIDTH_PX/2, d6     ; Right
    subi.w #VDP_SCREEN_HEIGHT_PX/2, d5    ; Top
    addi.w #VDP_SCREEN_HEIGHT_PX/2, d7    ; Bottom

    ; Draw objects
    bsr    ECSprite_DrawAll
    bsr    ECBridgeRenderer_DrawAll

    ; Debug draw
    bsr    ENT_DebugDrawMemory

    rts

    ; Asset includes
	include 'engine/assets.asm'

    ; Entity archetypes
    include 'samples/hello/data/entities/archtyps.asm'

    ; Scene data
    include 'samples/hello/data/scenes/chaptr01/include.asm'

    ; Sprite data
    include 'samples/hello/data/sprites/sprites.asm'
    include 'samples/hello/data/anims/sprtanms.asm'
    include 'samples/hello/data/palettes/sprtpals.asm'

    ; Script data
    include 'samples/hello/scripts/scripts.asm'
