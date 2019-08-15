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
    ; to plane A, and initialises streaming
    ; system.
    ; Assumes autoincrement is 2.
    ; ======================================
	; a0   Map data
    ; a1   Stampset
    ; a2   Tileset
    ; d0.w Num tiles
    ; d1.w Num stamps
    ; d2.w Map width (stamps)
    ; d3.w Map height (stamps)
    ; ======================================

    ;move.l #0x0, d0
    ;@Lp:
    ;move.l d0, d1
    ;add.l  d1, d1
    ;VDP_SETADDRESS d1, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE
    ;addi.l #0x1, d0
    ;bra    @lp

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
    move.l d1, d0
    move.l StreamingMap_Tileset(a3), a0
    move.w StreamingMap_NumTiles(a3), d1
    bsr    VDP_LoadTiles

    ; Stream initial screen
    lea    RAM_STREAMING_MAP, a3
    move.l StreamingMap_StampMap(a3), a0
    move.l StreamingMap_StampSet(a3), a1
    moveq  #0x0, d0
    moveq  #0x0, d1
    move.w StreamingMap_WidthStamps(a3), d2
    move.w StreamingMap_HeightStamps(a3), d3
    move.l StreamingMap_VRAMhndl(a3), d4
    bsr    MAP_StreamAll

    ; Init streaming ptrs
    move.w #-MAP_STREAM_BUFFER_OFFSET_X, RAM_MAP_STREAM_X
    ;move.w #-MAP_STREAM_BUFFER_OFFSET_Y, RAM_MAP_STREAM_Y

    rts

MAP_StreamAll:
    ; ======================================
    ; Streams a whole screen's worth of
    ; map data at the specified camera
    ; position, to plane A.
    ; Assumes autoincrement is 2.
    ; Does not support maps < 2x2 in size.
    ; ======================================
	; a0   Map data
    ; a1   Stampset
    ; d0.w Camera position X
    ; d1.w Camera position Y
    ; d2.w Map width (stamps)
    ; d3.w Map height (stamps)
    ; d4.w Tileset VRAM addr
    ; ======================================

    ; TODO: Camera offset

    VDP_SET_VRAM_WRITE VRAM_ADDR_PLANE_A

    move.w #(VDP_PLANE_WIDTH/MAP_STREAM_STAMP_WIDTH)-1, d0
    move.w #(VDP_PLANE_HEIGHT/MAP_STREAM_STAMP_HEIGHT)-1, d1

	move.w d4, d7                       ; Backup VRAM addr
    move.w d0, d4                       ; Backup X counter

    moveq  #0x0, d5                     ; Reset X stamp coord
    moveq  #0x0, d6                     ; Reset Y stamp coord

    @LoopY:
    move.w d4, d0                       ; Reset X counter
    @LoopX:

    PUSHM.L d0-d7/a1
    move.w d7, d4                       ; VRAM addr
    move.w d5, d7                       ; Calc stamp index offset
    add.w  d6, d7

    move.b (a0,d7), d7                  ; Get stamp index
    bsr    MAP_StreamStamp              ; Load
    POPM.L  d0-d7/a1
	
	add.w  #0x1, d5                     ; Next X stamp coord
    dbra   d0, @LoopX
    add.w  d2, d6                       ; Next Y stamp coord
    dbra   d1, @LoopY

    rts

MAP_StreamStamp:
    ; ======================================
    ; Streams a single stamp to plane A.
    ; Assumes autoincrement is 2.
    ; ======================================
    ; a1   Stampset
    ; d4   Tileset VRAM addr
    ; d5   Stamp coord X
    ; d6   Stamp coord Y
    ; d7   Stamp index
    ; ======================================

    ; Index to stamp data offset
    andi.l #0xFFFF, d7
    lsl.l  #MAP_STREAM_STAMP_WIDTH_SHIFT, d7	; * width
    lsl.l  #MAP_STREAM_STAMP_HEIGHT_SHIFT+1, d7	; * height * words
    adda.l d7, a1
    
    ; Wrap coords around plane
    lsl.w  #MAP_STREAM_STAMP_WIDTH_SHIFT, d5
    lsl.w  #MAP_STREAM_STAMP_HEIGHT_SHIFT, d6
    andi.w #(VDP_PLANE_WIDTH-1), d5
    andi.w #(VDP_PLANE_HEIGHT-1), d6

    ; Coord to plane A offset
    VRAM_CELL_COORDS_TO_BYTES d5,d6,d7
    
    ; Duplicate starting tile ID to upper word, to upload longwords at a time
    move.w d4, d0
    swap   d4
    move.w d0, d4

    ; Stream data
    ;move.w d5, d0
   ; move.w d6, d1
    move.l d7, d2

    ;REPT   MAP_STREAM_STAMP_HEIGHT
    move.w #MAP_STREAM_STAMP_HEIGHT-1, d0
    @LpY:

    VDP_SETADDRESS d2,#VRAM_ADDR_PLANE_A,#VDP_CMD_VRAM_WRITE
    move.w #(MAP_STREAM_STAMP_WIDTH/2)-1, d1
    @LpX:

    ;REPT   MAP_STREAM_STAMP_WIDTH/2
    move.l (a1)+, d3
    add.l  d4, d3
    move.l d3, PORT_VDP_DATA
    ;ENDR

    dbra   d1, @LpX

    addi.w #(VDP_PLANE_WIDTH*SIZE_WORD), d7 ; Next Y
    move.l d7, d2
    ;ENDR
    dbra   d0, @LpY

    rts

MAP_UpdateStreaming:
    ; ======================================
    ; Updates scroll coords from camera,
    ; and streams in new rows/cols if
    ; necessary.
    ; ======================================
    ; No params
    ; ======================================

    ; TEST
    ;subi.w #0x1, RAM_SCROLL_PLANE_A_X
    addi.w #0x1, RAM_SCROLL_PLANE_A_Y

    ; Keep VDP addrs in a5/a6, will be writing a lot
    move.l #PORT_VDP_CONTROL, a5
    move.l #PORT_VDP_DATA, a6
    
    lea    RAM_STREAMING_MAP, a3
    move.l StreamingMap_StampMap(a3), a0
    move.l StreamingMap_StampSet(a3), a1
    move.l StreamingMap_VRAMhndl(a3), a2

    ; ==================================================================================
    ; Stream columns
    ; ==================================================================================

    ; Get desired scroll column
	moveq  #0x0, d0
    move.w RAM_SCROLL_PLANE_A_X, d0
    neg.w  d0							; Invert
    ext.l  d0
    divs   #0x8, d0						; d0 = target column
    subi.w #MAP_STREAM_BUFFER_OFFSET_X, d0 ; Offset write head to within invisible plane area
    
    ; Get last streamed column
    move.w RAM_MAP_STREAM_X, d1			; d1 = read column (from map data)
    move.w d1, d6						; d6 = currently streaming column

    ; Wrap around plane width to get write column
    move.w d1, d5
    ext.l  d5
    divs   #VDP_PLANE_WIDTH, d5
    swap   d5							; d5 = write column (on plane)
    tst.w  d5
    bge    @InRangeX                    ; If < 0, bring back into range
    addi.w #VDP_PLANE_WIDTH, d5         ; (will go -ve at far left hand side, accounting for buffer)
    @InRangeX:

    ; Determine how many cols to stream, and in which direction
    cmp.w  d0, d1
    beq    @NoStreamX
    blt    @StreamSrcRight

    @StreamSrcLeft:
    move.w #-1, d7                      ; Stream from left source
    bra    @StreamX

    @StreamSrcRight:
    move.w #1, d7                       ; Stream from right source
    addi.w #VDP_PLANE_WIDTH, d1

    @StreamX:
    
    ; TODO: Loop from here

    ; Source column to stamp X and tile X offset
    move.w d1, d3
    move.w d1, d4
    lsr.w  #MAP_STREAM_STAMP_WIDTH_SHIFT, d3    ; Integer (stamp X)
    andi.w #(MAP_STREAM_STAMP_WIDTH-1), d4      ; Remainder (tile X)
    
    ; Get stamp index
    moveq  #0x0, d2
    move.b (a0,d3), d2
    
    ; To stamp addr offset
    lsl.l  #MAP_STREAM_STAMP_WIDTH_SHIFT, d2	; * width
    lsl.l  #MAP_STREAM_STAMP_HEIGHT_SHIFT+1, d2	; * height * words
    add.w  d4, d4								; remainder column to words
    add.w  d4, d2								; add remainder
    move.l a1, a3
    adda.l d2, a3
    
    ; Load whole column
    move.w d5, d4   							; Dest addr to words
    add.w  d4, d4
    
    ; Set top of column address
    VDP_SETADDRESS d4, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE
    
    ; TODO: Y src/dst offset
    move.w #MAP_STREAM_STAMP_HEIGHT-1, d2
    @StreamCol:
    move.w a2, a4									; Get tileset VRAM addr
    add.w  (a3), a4									; Add tile index+flags
    move.w a4, (a6)						            ; Upload to VDP
    adda.w #MAP_STREAM_STAMP_WIDTH*SIZE_WORD, a3    ; Next source Y
    VDP_VRAM_ADDR_INCREMENT_PLANE_A_Y d4,a5			; Next dest Y (and wrap height)
    dbra   d2, @StreamCol

    add.w  d7, d1                       			; Next source X
    add.w  d7, d5                       			; Next dest X
    add.w  d7, d6									; Compare with target X
    cmp.w  d0, d6
    bne    @StreamX

    move.w d0, RAM_MAP_STREAM_X         			; Done
    @NoStreamX:

    ; ==================================================================================
    ; Stream rows
    ; ==================================================================================

    ; Get desired scroll row
	moveq  #0x0, d0
    move.w RAM_SCROLL_PLANE_A_Y, d0
    ext.l  d0
    divs   #0x8, d0						; d0 = target row
    ;subi.w #MAP_STREAM_BUFFER_OFFSET_Y, d0 ; Offset write head to within invisible plane area
    
    ; Get last streamed row
    move.w RAM_MAP_STREAM_Y, d1			; d1 = read row (from map data)
    move.w d1, d6						; d6 = currently streaming row

    ; Wrap around plane height to get write row
    move.w d1, d5
    ext.l  d5
    divs   #VDP_PLANE_HEIGHT, d5
    swap   d5							; d5 = write row (on plane)
    tst.w  d5
    bge    @InRangeY                    ; If < 0, bring back into range
    addi.w #VDP_PLANE_HEIGHT, d5         ; (will go -ve at far top, accounting for buffer)
    @InRangeY:
    mulu   #VDP_PLANE_WIDTH, d5			; To word offset

    ; Determine how many rows to stream, and in which direction
    cmp.w  d0, d1
    beq    @NoStreamY
    blt    @StreamSrcBottom

    @StreamSrcTop:
    move.w #-1, d7                      ; Stream from top source
    bra    @StreamY

    @StreamSrcBottom:
    move.w #1, d7                       ; Stream from bottom source
    addi.w #VDP_PLANE_HEIGHT, d1

    @StreamY:
    
    ; TODO: Loop from here

    ; Source row to stamp Y and tile Y offset
    move.w d1, d3
    move.w d1, d4
    lsr.w  #MAP_STREAM_STAMP_HEIGHT_SHIFT, d3    ; Integer (stamp Y)
    andi.w #(MAP_STREAM_STAMP_HEIGHT-1), d4      ; Remainder (tile Y)
    
    ; Get stamp index
    moveq  #0x0, d2
    move.b (a0,d3), d2
    
    ; To stamp addr offset
    lsl.l  #MAP_STREAM_STAMP_WIDTH_SHIFT, d2	; * width
    lsl.l  #MAP_STREAM_STAMP_HEIGHT_SHIFT+1, d2	; * height * words
    lsl.w  #MAP_STREAM_STAMP_WIDTH_SHIFT+1, d4	; remainder row to words
    add.w  d4, d2								; add remainder
    move.l a1, a3
    adda.l d2, a3
    
    ; Load whole row
    move.w d5, d4   							; Dest addr to words
    add.w  d4, d4
    
    ; Set top of column address
    VDP_SETADDRESS d4, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE
    
    ; TODO: X src/dst offset
    move.w #MAP_STREAM_STAMP_WIDTH-1, d2
    @StreamRow:
    move.w a2, a4									; Get tileset VRAM addr
    add.w  (a3)+, a4								; Add tile index+flags
    move.w a4, (a6)						            ; Upload to VDP
    ;VDP_VRAM_ADDR_INCREMENT_PLANE_A_X d4,a5			; Next dest X (and wrap width)
    dbra   d2, @StreamRow

    add.w  d7, d1                       			; Next source Y
    add.w  d7, d5                       			; Next dest Y
    add.w  d7, d6									; Compare with target Y
    cmp.w  d0, d6
    bne    @StreamY

    move.w d0, RAM_MAP_STREAM_Y         			; Done
    @NoStreamY:

    rts

MAP_ApplyScroll:
    ; ======================================
    ; Applies scroll coords to planes
    ; ======================================
    ; No params
    ; ======================================

    VDP_SET_VRAM_WRITE VRAM_ADDR_HSCROLL
    move.w RAM_SCROLL_PLANE_A_X, PORT_VDP_DATA

    VDP_SET_VSRAM_WRITE 0x0000
    move.w RAM_SCROLL_PLANE_A_Y, PORT_VDP_DATA

    

    rts