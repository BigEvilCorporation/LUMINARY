; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; MEMMAP.ASM - Memory map for Luminary Engine
; ============================================================================================

    rsset  RAM_START

    ; Interrupt counters
RAM_VBLANK_COUNTER                      rs.l 1

    ; DMA queue
RAM_VDP_DMA_QUEUE                       rs.b (SIZEOF_VDPDMAJob*VDPDMA_MAX_QUEUE_SIZE)
RAM_VDP_DMA_QUEUE_NEXT                  rs.l 1

    ; Debug
RAM_DBG_FONT_VRAM                       rs.l 1

    ; Sprite table
RAM_SPRITE_BLANK                        rs.b SIZEOF_VDPSprite   ; Blank sprite (speeds up linking -1st in table)
RAM_SPRITE_TABLE                        rs.b (SIZEOF_VDPSprite*VDP_MAX_SPRITES)
RAM_SPRITE_TABLE_PTR                    rs.l 1
RAM_SPRITE_NEXT_IDX                     rs.w 1

    ; VRAM manager
    STRUCT_ALLOC VRAMManager,RAM_VRAM_MANAGER

RAM_FRAMEWORK_START                     rs.b 0