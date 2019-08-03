; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; HELLO.ASM - "Hello world" using Luminary Engine
; ============================================================================================

    ; Code includes
    include 'engine/consts.asm'
    include 'engine/vectrtab.asm'
    include 'samples/hello/system/header.asm'
    include 'luminary.asm'
    include 'samples/hello/system/memmap.asm'

DRAW_VRAM: macro
    PUSH.L a0
    bsr    ERR_ResetForError
    lea    RAM_VRAM_Manager, a0
    bsr    VRAM_ManagerDrawTable
    POP.L  a0
    endm

Main:
    ; ======================================
    ; Program entry point
    ; ======================================
    ; Called from bootstrap only
    ; ======================================
    
    @Lp:

    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
	lea    RAM_VRAM_Manager, a0
    move.w #0x0030, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_1
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
   
    move.w #0x0018, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_2
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.w #0x0100, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_3
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.w #0x0020, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_4
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_2, d0
    bsr    VRAM_ManagerFree
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_3, d0
    bsr    VRAM_ManagerFree
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.w #0x0038, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_5
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_1, d0
    bsr    VRAM_ManagerFree
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_4, d0
    bsr    VRAM_ManagerFree
    DRAW_VRAM
    ;bsr    PAD_WaitAnyButton
    
    move.l RAM_vram_hndl_5, d0
    bsr    VRAM_ManagerFree

    ; Loop forever
    
    bra    @Lp

    ; Asset includes
	include 'engine/assets.asm'

tst_pal:
    dc.w   0x0000
    dc.w   0x0EEE
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