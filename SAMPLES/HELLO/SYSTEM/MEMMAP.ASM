; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; MEMMAP.ASM - "Hello world" memory map
; ============================================================================================

    RSSET RAM_GAME_START
RAM_VRAM_HNDL_1                         rs.l 1
RAM_VRAM_HNDL_2                         rs.l 1
RAM_VRAM_HNDL_3                         rs.l 1
RAM_VRAM_HNDL_4                         rs.l 1
RAM_VRAM_HNDL_5                         rs.l 1
RAM_TEST_SPRITE                         rs.b SIZEOF_Sprite