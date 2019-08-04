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
    bsr    ENT_Initialise

    bsr    TestSpawn

    ; Alloc test sprite
    move.w #0x1, d0
    bsr    VRAMMGR_Alloc
    lea    RAM_TEST_SPRITE, a0
    move.l d1, Sprite_VRAMHndl(a0)
    move.b #VDP_SPRITE_LAYOUT_1x1, Sprite_Layout(a0)    
    SPRITE_SETPALETTE_CONST a0,1
    SPRITE_SETFLIPX_CONST a0,1
    SPRITE_SETFLIPY_CONST a0,1

    ; Load test sprite tiles
    lea    TestSprite, a0
    move.w d1, d0
    move.w #0x1, d1
    bsr    VDP_LoadTiles

    lea    tst_pal_1, a0
    move.b #0x1, d0
    bsr    VDP_LoadPalette

    lea    tst_pal_2, a0
    move.b #0x2, d0
    bsr    VDP_LoadPalette

    lea    tst_pal_3, a0
    move.b #0x3, d0
    bsr    VDP_LoadPalette
    
    @Lp:

    lea    RAM_TEST_SPRITE, a0
    move.w #0x0088, d0
    move.w #0x0088, d1
    bsr    SPR_DrawSingle

    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
	lea    RAM_VRAM_MANAGER, a0
    move.w #0x0030, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_vram_hndl_1
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
   
    move.w #0x0018, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_vram_hndl_2
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.w #0x0100, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_vram_hndl_3
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.w #0x0020, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_vram_hndl_4
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_2, d0
    bsr    VRAMMGR_Free
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_3, d0
    bsr    VRAMMGR_Free
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.w #0x0038, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_vram_hndl_5
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_1, d0
    bsr    VRAMMGR_Free
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_4, d0
    bsr    VRAMMGR_Free
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_5, d0
    bsr    VRAMMGR_Free

    bsr    SPR_CommitAndClearTable

    ; Loop forever
    
    bra    @Lp

    ; Asset includes
	include 'engine/assets.asm'

TestSprite:
    dc.l 0x00000000
    dc.l 0x01111110
    dc.l 0x01000000
    dc.l 0x01000000
    dc.l 0x01000000
    dc.l 0x01000000
    dc.l 0x01000000
    dc.l 0x00000000

tst_pal_1:
    dc.w   0x0000
    dc.w   0x0E00
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000

tst_pal_2:
    dc.w   0x0000
    dc.w   0x00E0
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000

tst_pal_3:
    dc.w   0x0000
    dc.w   0x000E
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000

tst_str:
    dc.b   'Hello, world!',0
    even