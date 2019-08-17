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

    ; Init scroll pos
    ; TODO: from camera
    move.w #0x0000, RAM_SCROLL_PLANE_A_X
    move.w #0x0000, RAM_SCROLL_PLANE_A_Y

    ; Init streaming ptrs, offset one screen to the left so first update fills it
    ; TODO: from camera
    move.w #-VDP_PLANE_WIDTH, RAM_MAP_STREAM_X
    move.w #0x0000, RAM_MAP_STREAM_Y

    ; Update to fill initial screen
    bsr    MAP_UpdateStreaming

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
    neg.w  d0							; Invert
    asr.w  #0x3, d0						; d0 = target column
    ext.l  d0							
    subi.w #MAP_STREAM_BUFFER_OFFSET_X, d0 ; Offset write head to within invisible plane area
    bge    @WithinBoundsX				; Clamp to 0
    move.w #0x0, d0
    @WithinBoundsX:
    
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

    PUSHM.W d0/d2/d4-d6/d7
    PUSH.L  a3

	; Get Y stream coord and map width
    move.w RAM_MAP_STREAM_Y, d2
	moveq  #0x0, d3
    move.w StreamingMap_WidthStamps(a3), d3
    
	; Set intial VRAM write address
    move.w d5, d7   					; Get destination col
    VDP_WRAP_PLANE_X d7                 ; Wrap around plane width
    move.w d2, d6						; Get destination row
    VDP_WRAP_PLANE_Y d6					; Wrap around plane height
    lsl.w  #VDP_PLANE_WIDTH_SHIFT, d6	; To Y
    add.w  d6, d7						; Add to X
    add.w  d7, d7                       ; Dest offset to words
    VDP_SETADDRESS d7, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE
    
    ; Column loop
    move.w #VDP_PLANE_HEIGHT-1, d6
    @StreamCol:

    ; d1 = x coord
    ; d2 = y coord
    ; d3 = map width
    ; d0 = out: offset
    ; d4 = out: remainder
    ; d5 = temp reg
    MAP_GET_STAMP_OFFSET d1,d2,d3,d0,d4,d5

    ; Get stamp address
    add.l  (a0,d0.w), d4                ; Add stamp start offset to remainder
    move.l a1, a3                       ; Get stamp data base addr
    adda.l d4, a3                       ; Add offset
    
    ; Write to VRAM
    move.w a2, a4						; Get tileset VRAM addr
    add.w  (a3), a4						; Add tile index+flags
    move.w a4, (a6)						; Upload to VDP
    addi.w #0x1, d2                     ; Next map Y
    VDP_VRAM_ADDR_INCREMENT_PLANE_A_Y d7,a5 ; Next plane Y (and wrap height)
    dbra   d6, @StreamCol

	POP.L  a3
    POPM.W d0/d2/d4-d6/d7

    add.w  d7, d1                       ; Next map X
    add.w  d7, d5                       ; Next plane X
    add.w  d7, d6						; Compare with target X
    cmp.w  d0, d6
    bne    @StreamX

    move.w d0, RAM_MAP_STREAM_X         ; Done
    @NoStreamX:

    ; ==================================================================================
    ; Stream rows
    ; ==================================================================================

    ; Get desired scroll row
    move.w RAM_SCROLL_PLANE_A_Y, d0
    asr.w  #0x3, d0						; d0 = target row
    ext.l  d0							
    subi.w #MAP_STREAM_BUFFER_OFFSET_Y, d0 ; Offset write head to within invisible plane area
    bge    @WithinBoundsY				; Clamp to 0
    move.w #0x0, d0
    @WithinBoundsY:
    
    ; Get last streamed row
    move.w RAM_MAP_STREAM_Y, d1			; d1 = read row (in map space)
    move.w d1, d5                       ; d5 = write rowcolumn (in plane space)
    move.w d1, d6						; d6 = currently streaming row (in map space)

    ; Determine how many rows to stream, and in which direction
    cmp.w  d0, d1
    beq    @NoStreamY
    blt    @StreamSrcBottom

    @StreamSrcTop:
    move.w #-1, d7                      ; Streaming top of window
    bra    @StreamY

    @StreamSrcBottom:
    move.w #1, d7                       ; Streaming bottom of window
    addi.w #VDP_PLANE_HEIGHT, d1
    addi.w #VDP_PLANE_HEIGHT, d5

    @StreamY:

    PUSHM.W d0/d2/d4-d6/d7
    PUSH.L  a3

	; Get X stream coord and map height
    move.w RAM_MAP_STREAM_X, d2
	moveq  #0x0, d3
    move.w StreamingMap_WidthStamps(a3), d3
    
	; Set intial VRAM write address
    move.w d2, d7   					; Get destination col
    VDP_WRAP_PLANE_X d7                 ; Wrap around plane width
    move.w d5, d6						; Get destination row
    VDP_WRAP_PLANE_Y d6					; Wrap around plane height
    lsl.w  #VDP_PLANE_WIDTH_SHIFT, d6	; To Y
    add.w  d6, d7						; Add to X
    add.w  d7, d7                       ; Dest offset to words
    VDP_SETADDRESS d7, #VRAM_ADDR_PLANE_A, #VDP_CMD_VRAM_WRITE
    
    ; Row loop
    move.w #VDP_PLANE_WIDTH-1, d6
    @StreamRow:

    ; d2 = x coord
    ; d1 = y coord
    ; d3 = map width
    ; d0 = out: offset
    ; d4 = out: remainder
    ; d5 = temp reg
    MAP_GET_STAMP_OFFSET d2,d1,d3,d0,d4,d5

    ; Get stamp address
    add.l  (a0,d0.w), d4                ; Add stamp start offset to remainder
    move.l a1, a3                       ; Get stamp data base addr
    adda.l d4, a3                       ; Add offset
    
    ; Write to VRAM
    move.w a2, a4						; Get tileset VRAM addr
    add.w  (a3), a4						; Add tile index+flags
    move.w a4, (a6)						; Upload to VDP
    addi.w #0x1, d2                     ; Next map X
    VDP_VRAM_ADDR_INCREMENT_PLANE_A_X d7,d4,a5 ; Next plane X (and wrap height)
    dbra   d6, @StreamRow

	POP.L  a3
    POPM.W d0/d2/d4-d6/d7

    add.w  d7, d1                       ; Next map Y
    add.w  d7, d5                       ; Next plane Y
    add.w  d7, d6						; Compare with target Y
    cmp.w  d0, d6
    bne    @StreamY

    move.w d0, RAM_MAP_STREAM_Y         ; Done
    @NoStreamY:

    rts

MAP_ApplyScroll:
    ; ======================================
    ; Applies scroll coords to planes,
    ; and clamps to map bounds.
    ; ======================================
    ; No params
    ; ======================================

    ; Clamp X scroll to map width and apply to VRAM
    lea    RAM_STREAMING_MAP, a0
    move.w RAM_SCROLL_PLANE_A_X, d0
    neg.w  d0
    move.w StreamingMap_WidthStamps(a0), d1
    MAP_STAMPS_TO_PIXELS_X d1
    subi.w #VDP_SCREEN_WIDTH_PX, d1
    CLAMP.W d0,#0x0,d1
    neg.w  d0
    move.w d0, RAM_SCROLL_PLANE_A_X
    VDP_SET_VRAM_WRITE VRAM_ADDR_HSCROLL
    move.w d0, PORT_VDP_DATA

    ; Clamp Y scroll to map height and apply to VSRAM
    move.w RAM_SCROLL_PLANE_A_Y, d0
    move.w StreamingMap_HeightStamps(a0), d1
    MAP_STAMPS_TO_PIXELS_Y d1
    subi.w #VDP_SCREEN_HEIGHT_PX, d1
    CLAMP.W d0,#0x0,d1
    move.w d0, RAM_SCROLL_PLANE_A_Y
    VDP_SET_VSRAM_WRITE 0x0000
    move.w d0, PORT_VDP_DATA

    

    rts