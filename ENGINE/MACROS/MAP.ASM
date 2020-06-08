; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 17th August 2019
; ============================================================================================
; MAP.ASM - Macros for map loading and streaming
; ============================================================================================

    ; Converts stamp X coord to tiles
MAP_STAMPS_TO_TILES_X: macro valuereg
    lsl.l  #MAP_STREAM_STAMP_WIDTH_SHIFT, \valuereg
    endm

    ; Converts stamp Y coord to tiles
MAP_STAMPS_TO_TILES_Y: macro valuereg
    lsl.l  #MAP_STREAM_STAMP_HEIGHT_SHIFT, \valuereg
    endm

    ; Converts stamp X coord to pixels
MAP_STAMPS_TO_PIXELS_X: macro valuereg
    lsl.l  #MAP_STREAM_STAMP_WIDTH_SHIFT, \valuereg
    lsl.l  #0x3, \valuereg
    endm

    ; Converts stamp Y coord to pixels
MAP_STAMPS_TO_PIXELS_Y: macro valuereg
    lsl.l  #MAP_STREAM_STAMP_HEIGHT_SHIFT, \valuereg
    lsl.l  #0x3, \valuereg
    endm

MAP_GET_STAMP_OFFSET: macro coordx,coordy,mapwidth,stampoffset,remainder,tmpreg
    ; =================================================
    ; Given arbitrary map coordinates, returns
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
    lsr.w  #MAP_STREAM_STAMP_HEIGHT_SHIFT-2, \stampoffset   ; Integer (stamp Y) * longwords
    andi.w #0xFFFC, \stampoffset                            ; to nearest longword
    mulu   \mapwidth, \stampoffset                          ; * map width

    ; Y remainder
    move.w \coordy, \remainder
    andi.w #(MAP_STREAM_STAMP_HEIGHT-1), \remainder         ; Remainder (tile Y)
    lsl.w  #MAP_STREAM_STAMP_HEIGHT_SHIFT+1, \remainder     ; to rows, in words

    ; X integer
    move.w \coordx, \tmpreg
    lsr.w  #MAP_STREAM_STAMP_WIDTH_SHIFT-2, \tmpreg         ; Integer (stamp X) * longwords
    andi.w #0xFFFC, \tmpreg                                 ; to nearest longword
    add.w  \tmpreg, \stampoffset                            ; add to Y offset
    
    ; X remainder
    move.w \coordx, \tmpreg
    andi.w #(MAP_STREAM_STAMP_WIDTH-1), \tmpreg             ; Remainder (tile X)
    add.w  \tmpreg, \tmpreg						            ; * word
    add.w  \tmpreg, \remainder                              ; add to Y remainder

    endm