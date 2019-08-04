; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; MEMMAP.ASM - Memory map for Luminary Engine
; ============================================================================================

    rsset  RAM_START

    ; Debug
RAM_DBG_FONT_VRAM                       rs.l 1

    ; Sprite table
RAM_SPRITE_TABLE                        rs.b (SIZEOF_VDPSprite*VDP_MAX_SPRITES)
RAM_SPRITE_TABLE_PTR                    rs.l 1
RAM_SPRITE_NEXT_IDX                     rs.w 1

    ; VRAM manager
    STRUCT_ALLOC RAM_VRAM_Manager,VRAMManager

RAM_GAME_START                          rs.b 0