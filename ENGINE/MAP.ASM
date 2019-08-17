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
    ;lea    RAM_STREAMING_MAP, a3
    ;move.l StreamingMap_StampMap(a3), a0
    ;move.l StreamingMap_StampSet(a3), a1
    ;moveq  #0x0, d0
    ;moveq  #0x0, d1
    ;move.w StreamingMap_WidthStamps(a3), d2
    ;move.w StreamingMap_HeightStamps(a3), d3
    ;move.l StreamingMap_VRAMhndl(a3), d4
    ;bsr    MAP_StreamAll

    ; Init scroll pos
    move.w #0x0000, RAM_SCROLL_PLANE_A_X
    move.w #0x0000, RAM_SCROLL_PLANE_A_Y

    ; Init streaming ptrs, offset one screen to the left so first update fills it
    move.w #-MAP_STREAM_BUFFER_OFFSET_X-VDP_PLANE_WIDTH, RAM_MAP_STREAM_X
    move.w #-MAP_STREAM_BUFFER_OFFSET_Y, RAM_MAP_STREAM_Y

    ; Update to fill initial screen
    bsr    MAP_UpdateStreaming

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
        
    add.w  d2, d2						; Width to longwords (stampset data = offsets)
    add.w  d2, d2

    move.w #(VDP_PLANE_WIDTH/MAP_STREAM_STAMP_WIDTH)-1, d0
    move.w #(VDP_PLANE_HEIGHT/MAP_STREAM_STAMP_HEIGHT)-1, d1

	move.w d4, d7                       ; Backup VRAM addr
    move.w d0, d4                       ; Backup X counter

    moveq  #0x0, d6                     ; Reset Y stamp addr

    @LoopY:
    move.w d4, d0                       ; Reset X counter
    moveq  #0x0, d5                     ; Reset X stamp addr
    moveq  #0x0, d3						; Reset dest X addr
    @LoopX:

    PUSHM.L d0-d7/a1
    move.w d7, d4                       ; VRAM addr
    move.w d5, d7                       ; Calc stamp addr offset
    add.w  d6, d7
    
    move.w d3, d4						; Dest X

    move.l (a0,d7.w), d7                ; Get stamp offset
    bsr    MAP_StreamStamp              ; Load
    POPM.L  d0-d7/a1
	
	addi.w #SIZE_LONG, d5               ; Next X stamp addr
	addi.w #0x1, d3
    dbra   d0, @LoopX
    add.w  d2, d6                       ; Next Y stamp addr
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
    ; d7   Stamp offset
    ; ======================================

    ; Offset into stampset
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
    move.w RAM_SCROLL_PLANE_A_X, d0
    neg.w  d0								; Invert
    asr.w  #0x3, d0							; d0 = target column
    ext.l  d0							
    subi.w #MAP_STREAM_BUFFER_OFFSET_X, d0	; Offset write head to within invisible plane area
    
    ; Get last streamed column
    move.w RAM_MAP_STREAM_X, d1			; d1 = read column (in map space)
    move.w d1, d5                       ; d5 = write column (in plane space)
    move.w d1, d6						; d6 = currently streaming column (in map space)

    ; Determine how many cols to stream, and in which direction
    cmp.w  d0, d1
    beq    @NoStreamX
    blt    @StreamSrcRight

    @StreamSrcLeft:
    move.w #-1, d7                      ; Streaming left-hand side of window
    bra    @StreamX

    @StreamSrcRight:
    move.w #1, d7                       ; Streaming right-hand side of window
    addi.w #VDP_PLANE_WIDTH, d1
    addi.w #VDP_PLANE_WIDTH, d5

    @StreamX:
    
    ; TODO: Loop from here

    ; Source column to stamp X and tile X offset
    moveq  #0x0, d2
    move.w d1, d3
    move.w d1, d2
    lsr.w  #MAP_STREAM_STAMP_WIDTH_SHIFT-2, d3      ; Integer (stamp X) * longwords
    andi.w #0xFFFC, d3                              ; to nearest longword
    andi.w #(MAP_STREAM_STAMP_WIDTH-1), d2         	; Remainder (tile X)
    add.w  d2, d2								    ; * word
    
    ; Get stamp address offset
    add.l  (a0,d3.w), d2                            ; add offset to remainder
    move.l a1, a3                                   ; get base address
    adda.l d2, a3                                   ; add offset
    
    ; Load whole column
    move.w d5, d4   							    
    VDP_WRAP_PLANE_X d4                             ; Wrap around plane width
    add.w  d4, d4                                   ; Dest coord to words
    
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
    
    rts

    ; Get scroll X
    ;move.w RAM_SCROLL_PLANE_A_X, a4
    move.w #0x0, a4

    ; Get desired scroll row
	moveq  #0x0, d0
    move.w RAM_SCROLL_PLANE_A_Y, d0
    ext.l  d0
    divs   #0x8, d0						; d0 = target row
    subi.w #MAP_STREAM_BUFFER_OFFSET_Y, d0 ; Offset write head to within invisible plane area
    
    ; Get last streamed row
    moveq  #0x0, d1
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

    ; Loading whole row, start from left-hand side
    move.w d5, d4   					; Dest addr to words
    add.w  d4, d4
    VDP_SETADDRESS d4, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE
    
    ; TODO: Loop from here
    PUSHM.W d0-d1/d5/d7/a4

    ; TODO: X src/dst offset
    move.w #VDP_PLANE_WIDTH-1, d2
    @StreamRow:
    
    ; Source row to stamp Y and tile Y offset
    move.w d1, d0
    move.w d1, d3
    lsr.w  #MAP_STREAM_STAMP_HEIGHT_SHIFT, d3    ; Integer (stamp Y)
    ;mulu   StreamingMap_WidthStamps(a3), d3      ; * map width
    andi.w #(MAP_STREAM_STAMP_HEIGHT-1), d0      ; Remainder (tile Y)

    ; Source col to stamp X and tile X offset
    move.w a4, d4
    ;move.w d2, d3
    ;lsr.w  #MAP_STREAM_STAMP_WIDTH_SHIFT, d3    ; Integer (stamp X)
    ;andi.w #(MAP_STREAM_STAMP_WIDTH-1), d2      ; Remainder (tile X)
    
    ; Get stamp index
    moveq  #0x0, d5
    move.b (a0,d3.w), d5
    
    ; To stamp addr offset
    lsl.l  #MAP_STREAM_STAMP_WIDTH_SHIFT, d5	; stamp index * width
    lsl.l  #MAP_STREAM_STAMP_HEIGHT_SHIFT+1, d5	; stamp index * height * words
    lsl.w  #MAP_STREAM_STAMP_HEIGHT_SHIFT+1, d0	; remainder Y to row in words
    add.w  d4, d4								; remainder X to col in words
    add.w  d0, d5								; add remainder Y
    add.w  d4, d5								; add remainder X
    move.l a1, a3
    adda.l d5, a3
    
    ; Write tile id
    move.w a2, d5									; Get tileset VRAM addr
    add.w  (a3)+, d5								; Add tile index+flags
    move.w d5, (a6)						            ; Upload to VDP

    VDP_VRAM_ADDR_INCREMENT_PLANE_A_X d4,d3,a5		; Next dest X (and wrap width)
    addi.w #0x1, a4									; Next source X
    dbra   d2, @StreamRow

    POPM.W  d0-d1/d5/d7/a4

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