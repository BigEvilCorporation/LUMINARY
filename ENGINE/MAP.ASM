; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 13th August 2019
; ============================================================================================
; MAP.ASM - Map loading and streaming routines
; ============================================================================================

    STRUCT_BEGIN StreamingMap
StreamingMap_VRAMhndl                   rs.l 1
StreamingMap_StampSet                   rs.l 1
StreamingMap_TileSet                    rs.l 1
StreamingMap_StampMap                   rs.l 1
StreamingMap_NumTiles                   rs.w 1
StreamingMap_NumStamps                  rs.w 1
StreamingMap_WidthStamps                rs.w 1
StreamingMap_HeightStamps               rs.w 1
    STRUCT_END

MAP_PreLoad:
    ; ======================================
    ; Loads one screen's worth of map data
    ; and initialises streaming system
    ; ======================================
	; a0   Map
    ; a1   Stampset
    ; a2   Tileset
    ; d0   Num tiles
    ; d1   Num stamps
    ; d2   Map width (stamps)
    ; d3   Map height (stamps)
    ; ======================================

    ; Init streaming map
    lea    RAM_STREAMING_MAP, a3
    move.l a0, StreamingMap_StampMap(a3)
    move.l a1, StreamingMap_StampSet(a3)
    move.l a2, StreamingMap_TileSet(a3)
    move.w d0, StreamingMap_NumTiles(a3)
    move.w d1, StreamingMap_NumStamps(a3)
    move.w d2, StreamingMap_WidthStamps(a3)
    move.w d3, StreamingMap_HeightStamps(a3)

    ; Alloc VRAM
    bsr    VRAMMGR_Alloc
    lea    RAM_STREAMING_MAP, a3
    move.l d1, StreamingMap_VRAMhndl(a3)

    ; Load tiles
    move.l StreamingMap_Tileset(a3), a0
    move.w StreamingMap_NumTiles(a3), d0
    bsr    VDP_LoadTiles

    rts