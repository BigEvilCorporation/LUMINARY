; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; HELLO.ASM - "Hello world" using Luminary Engine
; ============================================================================================

    ; Code includes
    include 'luminary.asm'
    include 'system/header.asm'
    include 'system/memmap.asm'
    include 'entities/bridge.asm'
    include 'entities/enemy.asm'
    include 'entities/chopper.asm'
    include 'entities/buzzbomb.asm'
    include 'entities/flicky.asm'
    include 'entities/lrswitch.asm'
    include 'entities/monitor.asm'
    include 'entities/motobug.asm'
    include 'entities/player.asm'
    include 'entities/ring.asm'
    include 'effects/vfx.asm'

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
    lea    SceneData_ghz1, a1
    bsr    SCN_LoadScene

    ; Set player
    lea    EPlayer_TypeDesc, a0
    bsr    ENT_FindFirstOfType
    move.l a1, RAM_PLAYER_1

    move.w #10, RAM_PAL_CYCLE_TIMER
    
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
    bsr    VDP_UpdatePaletteFade
    bsr    DMA_CommitAndClearQueue
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
    ;bsr    ENT_DebugDrawMemory

    move.w  RAM_PAL_CYCLE_TIMER, d0
    subi.w  #0x1, d0
    move.w  d0, RAM_PAL_CYCLE_TIMER
    bne     @NoCycle
    move.w  #6, RAM_PAL_CYCLE_TIMER
    moveq   #0, d0
    moveq   #8, d1
    moveq   #11, d2
    bsr     VDP_CyclePalette
    @NoCycle:

    rts

    ; Engine asset includes
	include 'engine/assets.asm'

    ; Game asset includes
    include 'data/data.asm'
