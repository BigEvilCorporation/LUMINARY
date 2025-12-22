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

    ; Palettes
RAM_VDP_PALETTES                        rs.l 4                      ; Current palette addresses
RAM_VDP_PAL_FADE_DST                    rs.l 4                      ; Palette addresses that we're fading to
RAM_VDP_PAL_FADE_SRC                    rs.b (16*3*SIZE_WORD*4)     ; Current palette fade colours (16x RGB 8.8 words per palettes)
RAM_VDP_PAL_FADE_DELTA                  rs.w (16*3*SIZE_WORD*4)     ; Palette fade deltas per frame (16x RGB 8.8 words per palettes)
RAM_VDP_PAL_FADE_TEMP                   rs.b (SIZE_PALETTE_B*4)     ; Last calculated fade palettes
RAM_VDP_PAL_FADE_FRAME                  rs.b 4                      ; Palette fade frames

    ; Debug
RAM_DBG_FONT_VRAM                       rs.l 1

    ; Sprite table
RAM_SPRITE_BLANK                        rs.b SIZEOF_VDPSprite   ; Blank sprite (speeds up linking -1st in table)
RAM_SPRITE_TABLE                        rs.b (SIZEOF_VDPSprite*VDP_MAX_SPRITES)
RAM_SPRITE_TABLE_PTR                    rs.l 1
RAM_SPRITE_NEXT_IDX                     rs.w 1

    ; VRAM manager
    STRUCT_ALLOC VRAMManager,RAM_VRAM_MANAGER

    ; Current streaming maps
    STRUCT_ALLOC StreamingMap,RAM_STREAMING_MAP_A
    STRUCT_ALLOC StreamingMap,RAM_STREAMING_MAP_B

    ; Alternate map streaming updates each frame
RAM_STREAMING_MAP_IDX                   rs.b 1

    STRUCT_ALIGN
RAM_FRAMEWORK_START                     rs.b 0