; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 22nd August 2019
; ============================================================================================
; COLLISN.ASM - Macros for collision map reading
; ============================================================================================

COL_TILEID_TO_ADDR: macro index
    ; Converts a collision tile index to address offset
    lsl.w  #COLLISION_TILE_TO_BYTE_SHIFT, \index
    endm

COL_MAP_X_TO_TILE_X: macro xpos
    ; Wraps a map space X position to tile space
    andi.w #COLLISION_TILE_WIDTH-1, \xpos
    endm

COL_MAP_Y_TO_TILE_Y: macro xpos
    ; Wraps a map space Y position to tile space
    andi.w #COLLISION_TILE_HEIGHT-1, \xpos
    endm

COL_GET_STAMP_OFFSET: macro coordx,coordy,mapwidth,stampoffset,remainder,tmpreg
    ; =================================================
    ; Given arbitrary collision map coordinates, returns
    ; the offset to the stamp data, and remainder
    ; x/y offset within it.
    ; =================================================
    ; coordx      - X coordinate in map space
    ; coordy      - Y coordinate in map space
    ; mapwidth    - Map width in stamps
    ; stampoffset - Out: stamp data offset
    ; remainder   - Out: remainder offset to cell
    ;                    within stamp data
    ; tmpreg      - Temporary register, will be trashed
    ; =================================================

    moveq  #0x0, \stampoffset
    moveq  #0x0, \remainder

    ; Y integer
    move.w \coordy, \stampoffset
    lsr.w  #COLLISION_STAMP_HEIGHT_SHIFT-2, \stampoffset    ; Integer (stamp Y) * longwords
    andi.w #0xFFFC, \stampoffset                            ; to nearest longword
    mulu.w \mapwidth, \stampoffset                          ; * map width

    ; Y remainder
    move.w \coordy, \remainder
    andi.w #(COLLISION_STAMP_HEIGHT-1), \remainder          ; Remainder (tile Y)
    lsl.w  #COLLISION_STAMP_HEIGHT_SHIFT+1+COLLISION_NUM_TERRAIN_LAYERS, \remainder ; to rows, in longwords * num layers

    ; X integer
    move.w \coordx, \tmpreg
    lsr.w  #COLLISION_STAMP_WIDTH_SHIFT-2, \tmpreg          ; Integer (stamp X) * longwords
    andi.w #0xFFFC, \tmpreg                                 ; to nearest longword
    add.w  \tmpreg, \stampoffset                            ; add to Y offset
    
    ; X remainder
    move.w \coordx, \tmpreg
    andi.w #(COLLISION_STAMP_WIDTH-1), \tmpreg              ; Remainder (tile X)
    add.w  \tmpreg, \tmpreg						            ; * longword * num layers
    REPT   COLLISION_NUM_TERRAIN_LAYERS
    add.w  \tmpreg, \tmpreg
    ENDR
    add.w  \tmpreg, \remainder                              ; add to Y remainder

    endm