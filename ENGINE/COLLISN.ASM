; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 22nd August 2019
; ============================================================================================
; COLLISN.ASM - Collision map reading
; ============================================================================================

COL_ProbeTerrainDown:
    ; ====================================== 
    ; Collision map lookup at specified
    ; x/y coordinate. Searches downwards
    ; for floor terrain and solid tiles.
    ; Returns terrain height, angle, and
    ; collision flags.
    ; ======================================
    ; In:
    ; a0    Terrain stamp map data
	; a1    Terrain stampset data
    ; a2    Terrain tileset data
    ; d0.w  Position X (map space)
    ; d1.w  Position Y (map space)
    ; d2.w  Map width (stamps)
    ; d5.ww COLLISION_TEST_BIT_*, terrain layer
    ; Out:
    ; d3.w  Collision flags/angle/quadrant
    ; d7.w  Terrain height (map space, -1 if not found)
    ; ======================================

    ; Layer to longwords
    andi.w #0xFF, d5
    lsl.w  #0x2, d5
    
    ; Position to tiles
    move.w d0, d6
    VDP_PIXELS_TO_TILES d6
    VDP_PIXELS_TO_TILES d1
    subi.w #0x1, d1                     ; Start one tile up

    ; Wrap X around tile width to get column offset
    move.w d0, d7
    COL_MAP_X_TO_TILE_X d7

    ; Loop until terrain found or max search height reached
    move.w #COLLISION_MAX_TERRAIN_SEARCH_TILES-1, d0
    @NextTile:

    ; Save layer
    PUSH.W d5

    ; Get terrain stamp
    ; d6 = x coord (tiles)
    ; d1 = y coord (tiles)
    ; d2 = map width
    ; d3 = out: offset
    ; d4 = out: remainder
    ; d5 = temp reg
    COL_GET_STAMP_OFFSET d6,d1,d2,d3,d4,d5

    ; Restore layer
    POP.W  d5

    ; Get stamp address
    add.l  (a0,d3.w), d4     	        ; Add stamp start offset to remainder
    move.l a1, a3                       ; Get stamp data base addr
    adda.l d4, a3                       ; Add offset
    adda.w d5, a3                       ; Add layer

    ; Read tile data
    move.l (a3), d3                     ; flags (b) + angle (b) in upper word, tileIdx in lower word
    beq    @ZeroHeightOrCeiling         ; Tile 0 is blank

    ; If tile solid, success
    btst   #COLLISION_TEST_BIT_SOLID_L, d5      ; Check if testing for solid tiles
    beq    @NoCheckSolid
    btst   #COLLISION_FLAG_BIT_SOLID_B+24, d3   ; Flags in upper byte
    bne    @SolidTile
    @NoCheckSolid:

    ; Get tile
    moveq  #0x0, d4
    move.w d3, d4
    COL_TILEID_TO_ADDR d4
    move.l a2, a3
    adda.l d4, a3

    ; Get height at column
    move.w #0x0, d3
    move.b (a3,d7.w), d3
    tst.b  d3
    ble    @ZeroHeightOrCeiling         ; If 0 or -ve, keep searching

    ; If height==8, +1 tile and loop
    ; TODO

    ; If valid height, subtract from total height (map space is -ve, heightmap is +ve)
    move.w d1, d7
    addi.w #0x1, d7                     ; Tile Y + 1
    VDP_TILES_TO_PIXELS d7              ; Tile Y back to pixels
    sub.w  d3, d7
    swap   d3                           ; Return flags/angle/quadrant

    rts

    @ZeroHeightOrCeiling:
    addi.w #0x1, d1                     ; No +ve height found, check next tile down
    dbra   d0, @NextTile

    move.w #-1, d7                      ; Terrain not found within search distance
    moveq  #0x0, d3

    rts

    @SolidTile:
    move.w d1, d7
    VDP_TILES_TO_PIXELS d7              ; Tile Y back to pixels
    swap   d3                           ; Return flags/angle/quadrant

    rts

COL_ProbeTerrainUp:
    ; ======================================
    ; Collision map lookup at specified
    ; x/y coordinate. Searches upwards
    ; for ceiling terrain and solid tiles.
    ; Returns terrain height, angle, and
    ; collision flags.
    ; ======================================
    ; In:
    ; a0   Terrain stamp map data
	; a1   Terrain stampset data
    ; a2   Terrain tileset data
    ; d0.w Position X (map space)
    ; d1.w Position Y (map space)
    ; d2.w Map width (stamps)
    ; d5.b Terrain layer
    ; Out:
    ; d3.w Collision flags/angle/quadrant
    ; d7.w Terrain height (map space, -1 if not found)
    ; ======================================

    ; Layer to longwords
    andi.w #0xFF, d5
    lsl.w  #0x2, d5

    ; Position to tiles
    move.w d0, d6
    VDP_PIXELS_TO_TILES d6
    VDP_PIXELS_TO_TILES d1
    addi.w #0x1, d1                     ; Start one tile down

    ; Wrap X around tile width to get column offset
    move.w d0, d7
    COL_MAP_X_TO_TILE_X d7

    ; Loop until terrain found or max search height reached
    move.w #COLLISION_MAX_TERRAIN_SEARCH_TILES-1, d0
    @NextTile:

    ; Save layer
    PUSH.W d5

    ; Get terrain stamp
    ; d6 = x coord (tiles)
    ; d1 = y coord (tiles)
    ; d2 = map width
    ; d3 = out: offset
    ; d4 = out: remainder
    ; d5 = temp reg
    COL_GET_STAMP_OFFSET d6,d1,d2,d3,d4,d5

    ; Restore layer
    POP.W  d5

    ; Get stamp address
    add.l  (a0,d3.w), d4                ; Add stamp start offset to remainder
    move.l a1, a3                       ; Get stamp data base addr
    adda.l d4, a3                       ; Add offset
    adda.w d5, a3                       ; Add layer

    ; Read tile data
    move.l (a3), d3                     ; flags (b) + angle (b) in upper word, tileIdx in lower word
    beq    @ZeroHeightOrFloor           ; Tile 0 is blank

    ; If tile solid, success
    btst   #COLLISION_TEST_BIT_SOLID_L, d5    ; Check if testing for solid tiles
    beq    @NoCheckSolid
    btst   #COLLISION_FLAG_BIT_SOLID_B+24, d3 ; Flags in upper byte
    bne    @SolidTile
    @NoCheckSolid:

    ; Get tile
    moveq  #0x0, d4
    move.w d3, d4
    COL_TILEID_TO_ADDR d4
    move.l a2, a3
    adda.l d4, a3

    ; Get height at column
    move.w #0x0, d3
    move.b (a3,d7.w), d3
    tst.b  d3
    bge    @ZeroHeightOrFloor           ; If 0 or +ve, keep searching

    ; If height==-8, -1 tile and loop
    ; TODO

    ; If valid height, add to total height
    move.w d1, d7
    VDP_TILES_TO_PIXELS d7              ; Tile Y back to pixels
    ext.w  d3                           ; Height tile is -ve
    sub.w  d3, d7
    swap   d3                           ; Return flags/angle/quadrant

    rts

    @ZeroHeightOrFloor:
    subi.w #0x1, d1                     ; No -ve height found, check next tile up
    dbra   d0, @NextTile

    move.w #-1, d7                      ; Terrain not found within search distance
    moveq  #0x0, d3

    rts

    @SolidTile:
    move.w d1, d7
    VDP_TILES_TO_PIXELS d7              ; Tile Y back to pixels
    swap   d3                           ; Return flags/angle/quadrant

    rts

COL_ProbeTerrainLeft:
    ; ====================================== 
    ; Collision map lookup at specified
    ; x/y coordinate. Searches left
    ; for wall terrain and solid tiles.
    ; Returns terrain width, angle, and
    ; collision flags.
    ; ======================================
    ; In:
    ; a0   Terrain stamp map data
	; a1   Terrain stampset data
    ; a2   Terrain tileset data
    ; d0.w Position X (map space)
    ; d1.w Position Y (map space)
    ; d2.w Map width (stamps)
    ; d5.b Terrain layer
    ; Out:
    ; d3.w Collision flags/angle/quadrant
    ; d7.w Terrain width (map space, -1 if not found)
    ; ======================================

    ; Layer to longwords
    andi.w #0xFF, d5
    lsl.w  #0x2, d5

    ; Offset tileset addr to read width data
    adda.l #COLLISION_TILE_WIDTH, a2

    ; Wrap Y around tile height to get row offset
    move.w d1, d6
    COL_MAP_Y_TO_TILE_Y d6
    move.w #COLLISION_TILE_HEIGHT-1, d7	; Invert
    sub.w  d6, d7
    
    ; Position to tiles
    move.w d0, d6
    VDP_PIXELS_TO_TILES d6
    VDP_PIXELS_TO_TILES d1
    addi.w #0x1, d6                     ; Start one tile to the right

    ; Loop until terrain found or max search width reached
    move.w #COLLISION_MAX_TERRAIN_SEARCH_TILES-1, d0
    @NextTile:

    ; Save layer
    PUSH.W d5

    ; Get terrain stamp
    ; d6 = x coord (tiles)
    ; d1 = y coord (tiles)
    ; d2 = map width
    ; d3 = out: offset
    ; d4 = out: remainder
    ; d5 = temp reg
    COL_GET_STAMP_OFFSET d6,d1,d2,d3,d4,d5

    ; Restore layer
    POP.W  d5

    ; Get stamp address
    add.l  (a0,d3.w), d4                ; Add stamp start offset to remainder
    move.l a1, a3                       ; Get stamp data base addr
    adda.l d4, a3                       ; Add offset
    adda.w d5, a3                       ; Add layer

    ; Read tile data
    move.l (a3), d3                     ; flags (b) + angle (b) in upper word, tileIdx in lower word
    beq    @ZeroWidthOrRightWall        ; Tile 0 is blank

    ; If tile solid, success
    btst   #COLLISION_TEST_BIT_SOLID_L, d5    ; Check if testing for solid tiles
    beq    @NoCheckSolid
    btst   #COLLISION_FLAG_BIT_SOLID_B+24, d3 ; Flags in upper byte
    bne    @SolidTile
    @NoCheckSolid:

    ; Get tile
    moveq  #0x0, d4
    move.w d3, d4
    COL_TILEID_TO_ADDR d4
    move.l a2, a3
    adda.l d4, a3

    ; Get width at row
    move.w #0x0, d3
    move.b (a3,d7.w), d3
    tst.b  d3
    ble    @ZeroWidthOrRightWall        ; If 0 or -ve, keep searching

    ; If height==8, +1 tile and loop
    ; TODO

    ; If valid width, add to total width
    move.w d6, d7
    VDP_TILES_TO_PIXELS d7              ; Tile X back to pixels
    add.w  d3, d7
    swap   d3                           ; Return flags/angle/quadrant

    rts

    @ZeroWidthOrRightWall:
    subi.w #0x1, d6                     ; No +ve height found, check next tile left
    dbra   d0, @NextTile

    move.w #-1, d7                      ; Terrain not found within search distance
    moveq  #0x0, d3

    rts

    @SolidTile:
    move.w d6, d7
    VDP_TILES_TO_PIXELS d7              ; Tile X back to pixels
    swap   d3                           ; Return flags/angle/quadrant

    rts

COL_ProbeTerrainRight:
    ; ====================================== 
    ; Collision map lookup at specified
    ; x/y coordinate. Searches right
    ; for wall terrain and solid tiles.
    ; Returns terrain width, angle, and
    ; collision flags.
    ; ======================================
    ; In:
    ; a0   Terrain stamp map data
	; a1   Terrain stampset data
    ; a2   Terrain tileset data
    ; d0.w Position X (map space)
    ; d1.w Position Y (map space)
    ; d2.w Map width (stamps)
    ; d5.b Terrain layer
    ; Out:
    ; d3.w Collision flags/angle/quadrant
    ; d7.w Terrain width (map space, -1 if not found)
    ; ======================================

    ; Layer to longwords
    andi.w #0xFF, d5
    lsl.w  #0x2, d5

    ; Offset tileset addr to read width data
    adda.l #COLLISION_TILE_WIDTH, a2

    ; Wrap Y around tile height to get row offset
    move.w d1, d6
    COL_MAP_Y_TO_TILE_Y d6
    move.w #COLLISION_TILE_HEIGHT-1, d7	; Invert
    sub.w  d6, d7
    
    ; Position to tiles
    move.w d0, d6
    VDP_PIXELS_TO_TILES d6
    VDP_PIXELS_TO_TILES d1
    subi.w #0x1, d6                     ; Start one tile to the left

    ; Loop until terrain found or max search width reached
    move.w #COLLISION_MAX_TERRAIN_SEARCH_TILES-1, d0
    @NextTile:

    ; Save layer
    PUSH.W d5

    ; Get terrain stamp
    ; d6 = x coord (tiles)
    ; d1 = y coord (tiles)
    ; d2 = map width
    ; d3 = out: offset
    ; d4 = out: remainder
    ; d5 = temp reg
    COL_GET_STAMP_OFFSET d6,d1,d2,d3,d4,d5

    ; Restore layer
    POP.W  d5

    ; Get stamp address
    add.l  (a0,d3.w), d4                ; Add stamp start offset to remainder
    move.l a1, a3                       ; Get stamp data base addr
    adda.l d4, a3                       ; Add offset
    adda.w d5, a3                       ; Add layer

    ; Read tile data
    move.l (a3), d3                     ; flags (b) + angle (b) in upper word, tileIdx in lower word
    beq    @ZeroWidthOrLeftWall         ; Tile 0 is blank

    ; If tile solid, success
    btst   #COLLISION_TEST_BIT_SOLID_L, d5    ; Check if testing for solid tiles
    beq    @NoCheckSolid
    btst   #COLLISION_FLAG_BIT_SOLID_B+24, d3 ; Flags in upper byte
    bne    @SolidTile
    @NoCheckSolid:

    ; Get tile
    moveq  #0x0, d4
    move.w d3, d4
    COL_TILEID_TO_ADDR d4
    move.l a2, a3
    adda.l d4, a3

    ; Get width at row
    move.w #0x0, d3
    move.b (a3,d7.w), d3
    tst.b  d3
    bge    @ZeroWidthOrLeftWall         ; If 0 or -ve, keep searching

    ; If height==8, +1 tile and loop
    ; TODO

    ; If valid width, subtract from total width
    move.w d6, d7
    addi.w #0x1, d7						; Tile X + 1
    VDP_TILES_TO_PIXELS d7              ; Tile X back to pixels
    ext.w  d3                           ; Width tile is -ve
    add.w  d3, d7
    swap   d3                           ; Return flags/angle/quadrant

    rts

    @ZeroWidthOrLeftWall:
    addi.w #0x1, d6                     ; No +ve height found, check next tile right
    dbra   d0, @NextTile

    move.w #-1, d7                      ; Terrain not found within search distance
    moveq  #0x0, d3

    rts

    @SolidTile:
    move.w d6, d7
    VDP_TILES_TO_PIXELS d7              ; Tile X back to pixels
    swap   d3                           ; Return flags/angle/quadrant

    rts