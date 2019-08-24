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
    ; d5.b Collision flags
    ; d6.b Terrain angle
    ; d7.w Terrain height (map space, -1 if not found)
    ; ======================================

    ; Position to tiles
    move.w d0, d6
    VDP_PIXELS_TO_TILES d6
    VDP_PIXELS_TO_TILES d1

    ; Wrap X around tile width to get column offset
    move.w d0, d7
    COL_MAP_X_TO_TILE_X d7

    ; Loop until terrain found or max search height reached
    move.w #COLLISION_MAX_TERRAIN_SEARCH_TILES-1, d0
    @NextTile:

    ; Get terrain stamp
    ; d6 = x coord (tiles)
    ; d1 = y coord (tiles)
    ; d2 = map width
    ; d3 = out: offset
    ; d4 = out: remainder
    ; d5 = temp reg
    COL_GET_STAMP_OFFSET d6,d1,d2,d3,d4,d5

    ; Get stamp address
    add.l  (a0,d3.w), d4                ; Add stamp start offset to remainder
    move.l a1, a3                       ; Get stamp data base addr
    adda.l d4, a3                       ; Add offset

    ; Read tile data
    move.l (a3), d3                     ; flags (b) + angle (b) in upper word, tileIdx in lower word
    beq    @ZeroHeight                  ; Tile 0 is blank

    ; If tile solid, -1 tile and loop
    ; TODO

    ; Get tile
    moveq  #0x0, d4
    move.w d3, d4
    COL_TILEID_TO_ADDR d4
    move.l a2, a3
    adda.l d4, a3

    ; Get height at column
    move.w #0x0, d3
    move.b (a3,d7.w), d3
    beq    @ZeroHeight

    ; If height==8, +1 tile and loop
    ; TODO

    ; If valid height, subtract from total height (map space is -ve, heightmap is +ve)
    move.w d1, d7
    addi.w #0x1, d7                     ; Tile Y + 1
    VDP_TILES_TO_PIXELS d7              ; Tile Y back to pixels
    sub.w  d3, d7

    rts

    @ZeroHeight:
    addi.w #0x1, d1                     ; No height found, check next tile down
    dbra   d0, @NextTile

    move.w #-1, d7                      ; Terrain not found within search distance

    rts