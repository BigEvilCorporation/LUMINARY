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

Main:
    ; ======================================
    ; Program entry point
    ; ======================================
    ; Called from bootstrap only
    ; ======================================

    lea    RAM_VRAM_Manager, a0
    bsr    VRAM_ManagerInit

    move.w #0x0000, d0
    move.w #0xB000/SIZE_TILE_B, d1
    bsr    VRAM_AddPool
    
    @Lp:
    
	lea    RAM_VRAM_Manager, a0
    move.w #0x0030, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_1
    ; 0x00000000
   
    move.w #0x0018, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_2
    ; 0x00080010
    
    move.w #0x0100, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_3
    ; 0x00100020
    
    move.w #0x0020, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_4
    ; 0x00180030
    
    move.l RAM_vram_hndl_2, d0
    bsr    VRAM_ManagerFree
    
    move.l RAM_vram_hndl_3, d0
    bsr    VRAM_ManagerFree
    
    move.w #0x0038, d0
    bsr    VRAM_ManagerAlloc
    move.l d1, RAM_vram_hndl_5
    ; 0x00080010
    
    move.l RAM_vram_hndl_1, d0
    bsr    VRAM_ManagerFree
    
    move.l RAM_vram_hndl_4, d0
    bsr    VRAM_ManagerFree
    
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