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
    ;MAP_GET_STAMP_OFFSET d0,d1,d2,d3,d4,d5

    moveq  #0x0, d3
    moveq  #0x0, d4

    ; Y integer
    move.w d1, d3
    VDP_PIXELS_TO_TILES d3
    lsr.w  #COLLISION_STAMP_HEIGHT_SHIFT-2, d3    ; Integer (stamp Y) * longwords
    andi.w #0xFFFC, d3                            ; to nearest longword
    mulu   d2, d3                          ; * map width

    ; Y remainder
    move.w d1, d4
    VDP_PIXELS_TO_TILES d4
    andi.w #(COLLISION_STAMP_HEIGHT-1), d4          ; Remainder (tile Y)
    lsl.w  #COLLISION_STAMP_HEIGHT_SHIFT+2, d4      ; to rows, in longwords

    ; X integer
    move.w d0, d5
    VDP_PIXELS_TO_TILES d5
    lsr.w  #COLLISION_STAMP_WIDTH_SHIFT-2, d5          ; Integer (stamp X) * longwords
    andi.w #0xFFFC, d5                                 ; to nearest longword
    add.w  d5, d3                            ; add to Y offset
    
    ; X remainder
    move.w d0, d5
    VDP_PIXELS_TO_TILES d5
    andi.w #(COLLISION_STAMP_WIDTH-1), d5              ; Remainder (tile X)
    add.w  d5, d5						            ; * longword
    add.w  d5, d5
    add.w  d5, d4                             ; add to Y remainder

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

    ; X map space to tile space
    move.w d0, d4
    COL_MAP_X_TO_TILE_X d4

    ; Get height
    move.b (a3,d4.w), d4

    ; TODO
    move.w d4, d0

    ; If height==8, +1 tile and loop
    ; TODO

    rts