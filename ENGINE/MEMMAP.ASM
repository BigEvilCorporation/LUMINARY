; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; MEMMAP.ASM - Memory map for Luminary Engine
; ============================================================================================

    rsset  RAM_START

    ; Debug
RAM_DBG_FONT_VRAM                       rs.w 1

    ; VRAM manager
    STRUCT_ALLOC RAM_VRAM_Manager,VRAMManager

RAM_GAME_START                          rs.b 0