; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 22nd August 2019
; ============================================================================================
; COLLISN.ASM - Collision map reading
; ============================================================================================

COL_ProbeCollision:
    ; ======================================
    ; Looks up collision at specified x/y
    ; coordinate. Returns terrain height,
    ; angle, and collision flags.
    ; ======================================
    ; In:
    ; a0   Terrain stamp map data
	; a1   Terrain stampset data
    ; a2   Terrain tileset data
    ; d0.w Position X (map space)
    ; d1.w Position Y (map space)
    ; d2.w Map width (stamps)
    ; Out:
    ; d0.w Terrain height (map space)
    ; d1.b Terrain angle
    ; d2.b Collision flags
    ; ======================================

    @NextTile:

    ; Get terrain stamp
    ; d0 = x coord (pixels)
    ; d1 = y coord (pixels)
    ; d2 = map width
    ; d3 = out: offset
    ; d4 = out: remainder
    ; d5 = temp reg
    move.w d0, d6
    move.w d1, d7
    VDP_PIXELS_TO_TILES d6
    VDP_PIXELS_TO_TILES d7
    COL_GET_STAMP_OFFSET d6,d7,d2,d3,d4,d5

    ; Get stamp address
    add.l  (a0,d3.w), d4                ; Add stamp start offset to remainder
    move.l a1, a3                       ; Get stamp data base addr
    adda.l d4, a3                       ; Add offset

    ; Read tile data
    move.l (a3), d3                     ; flags (b) + angle (b) in upper word, tileIdx in lower word

    ; If tile solid, -1 tile and loop
    ; TODO

    ; Get tile
    moveq  #0x0, d4
    move.w d3, d4
    COL_TILEID_TO_ADDR d4
    move.l a2, a3
    adda.l d4, a3

    ; Wrap X around tile width to get column offset
    move.w d0, d4
    COL_MAP_X_TO_TILE_X d4

    ; Get height
    move.b (a3,d4.w), d4

    ; TODO
    move.w d4, d0

    ; If height==8, +1 tile and loop
    ; TODO

    rts