;==============================================================
; SOFTWARE RENDERING ROUTINES
;==============================================================

CANVAS_MASK_PIXELS                      equ 0
CANVAS_UNROLL_LOOPS                     equ 1
CANVAS_MAX_UNROLL                       equ 0x20
CANVAS_MAX_UNROLL_START                 equ CANVAS_MAX_UNROLL-1

    rsset 0
;-------------------------
Canvas_FrameBuffer  rs.l 1
Canvas_XOffsetTable rs.l 1
Canvas_VRAMHndl     rs.l 1
Canvas_ByteOffset   rs.w 1
Canvas_SizeTiles    rs.w 1
Canvas_SizeBytes    rs.w 1	
Canvas_SizeWords    rs.w 1
Canvas_SizeLongs    rs.w 1
Canvas_WidthBytes   rs.w 1
Canvas_WidthPixels  rs.w 1
Canvas_HeightPixels rs.w 1
Canvas_WidthTiles   rs.b 1
Canvas_HeightTiles  rs.b 1
Canvas_OffsetXTiles rs.b 1
Canvas_OffsetYTiles rs.b 1
Canvas_Plane        rs.b 1
;-------------------------
Canvas_Struct_Size  rs.b 0
    STRUCT_ALIGN
;-------------------------

VDP_CanvasCreate:
    ; --------------------------------------------------------------
    ; Assigns a contiguous region of tile IDs to a rectangular block
    ; in plane A for software rendering.
    ; ** Requires 2 byte VDP autoincrement **
    ; --------------------------------------------------------------
    ; a0   - Canvas
    ; a1   - Frame buffer (width_t*height_t/size_tile_b)
    ; a2   - X offset table (width_px*size_word)
	; d0.b - Width (tiles)
	; d1.b - Height (tiles)
	; d2.b - Offset X
	; d3.b - Offset Y
    ; d4.b - Plane (0=A, 1=B)
    ; --------------------------------------------------------------

    move.b d0, Canvas_WidthTiles(a0)
    move.b d1, Canvas_HeightTiles(a0)
    move.b d2, Canvas_OffsetXTiles(a0)
    move.b d3, Canvas_OffsetYTiles(a0)
    move.b d4, Canvas_Plane(a0)
    move.l a1, Canvas_FrameBuffer(a0)
    move.l a2, Canvas_XOffsetTable(a0)

    andi.l #0x00FF, d0
    andi.l #0x00FF, d1
    andi.w #0x00FF, d2
    andi.w #0x00FF, d3

    ; Alloc VRAM
    PUSHALL
    PUSH.L a0
    mulu   d1, d0
    bsr VRAMMGR_Alloc
    POP.L  a0
    move.l d1, Canvas_VRAMHndl(a0)
    POPALL

    move.w d0, d6                       ; Width pixels
    lsl.w  #0x3, d6
    move.w d6, Canvas_WidthBytes(a0)
    move.w d1, d6                       ; Height pixels
    lsl.w  #0x3, d6
    move.w d6, Canvas_HeightPixels(a0)

    move.w d0, d6
    mulu   d1, d6                       ; Num tiles
    move.w d6, Canvas_SizeTiles(a0)
    mulu   #size_tile_b, d6             ; Num bytes
    move.w d6, Canvas_SizeBytes(a0)
    lsr.w  #0x1, d6                     ; Num words
    move.w d6, Canvas_SizeWords(a0)
    lsr.w  #0x1, d6                     ; Num longs
    move.w d6, Canvas_SizeLongs(a0)

    move.l Canvas_VRAMHndl(a0), d4
    move.w d4, d6
    mulu   #size_tile_b, d6             ; Byte offset
    move.w d6, Canvas_ByteOffset(a0)

    ; --------------------------------------------------------------

    move.w d4, a5

    ; Create X offset table
    moveq  #0x0, d5
    moveq  #0x0, d6
    move.b Canvas_WidthTiles(a0), d5
    move.b Canvas_HeightTiles(a0), d6

    mulu   #size_tile_b, d6             ; Bytes per column

    move.l a1, a4                       ; Framebuffer address

    subi.w #0x1, d5
    @TileX:
    move.w #0x4-1, d4                   ; 2 pixels per byte
    @PixelX:
    move.w a4, (a2)+                    ; Pixel 1 - Only need to write bottom words, we know RAM is at 0x00FF0000
    move.w a4, (a2)+                    ; Pixel 2
    adda.w #0x1, a4                     ; Next column within tile
    dbra   d4, @PixelX
    suba.w #0x4, a4                     ; Next column on map
    adda.w d6, a4
    dbra   d5, @TileX

    move.w a5, d4

    ; --------------------------------------------------------------

    ; Tile pal/prio flags
    ori.w #VDP_CELL_FLAG_HI_PRIO, d4

    ; Fill plane tiles - in column major order (sprite style)
    subi.w #0x1, d0                     ; -1 for count
    subi.w #0x1, d1
    move.w d3, d7                       ; Set initial Y

    moveq  #0x0, d3
    move.b Canvas_WidthTiles(a0), d3

    @LoopTileX:
    move.w d1, d6                       ; Reset height

    ; X/Y coord to tile address
    moveq  #0x0, d5
    move.w d7, d5                       ; Y
    mulu   #vdp_plane_width, d5         ; To line
    add.w  d2, d5                       ; X
    lsl.w  #0x1, d5                     ; To words

    tst.b  Canvas_Plane(a0)
    beq    @PlaneA
    VDP_SETADDRESS d5, #vram_addr_plane_b, #vdp_cmd_vram_write
    bra    @PlaneB
    @PlaneA:
    VDP_SETADDRESS d5, #vram_addr_plane_a, #vdp_cmd_vram_write
    @PlaneB:

    PUSH.W  d4

    @LoopTileY:
    
    move.w d4, port_vdp_data            ; Tile ID to map
    add.w  d3, d4                       ; Next tile row ID

    dbra   d6, @LoopTileY
    POP.W   d4
    addq.w #0x1, d7                     ; Increment X
    addq.w #0x1, d4                     ; Increment tile ID
    dbra   d0, @LoopTileX

    ; --------------------------------------------------------------

    ; Clear canvas
    jsr    VDP_CanvasClear

	rts

VDP_CanvasClear:
    ; --------------------------------------------------------------
    ; Clears a canvas to colour 0
    ; --------------------------------------------------------------
    ; a0   - Canvas
    ; --------------------------------------------------------------

    move.w Canvas_SizeTiles(a0), d0
    move.l Canvas_FrameBuffer(a0), a1

    lsr.w  #0x2, d0                     ; 4 * 8 longs per loop
    subi.w #0x1, d0

    moveq  #0x0, d1
    moveq  #0x0, d2
    moveq  #0x0, d3
    moveq  #0x0, d4
    moveq  #0x0, d5
    moveq  #0x0, d6
    moveq  #0x0, d7
    move.l #0x0, a3

    @Loop:
    movem.l d1-d7/a3, (a1)
    adda.w  #size_long*8, a1
    movem.l d1-d7/a3, (a1)
    adda.w  #size_long*8, a1
    movem.l d1-d7/a3, (a1)
    adda.w  #size_long*8, a1
    movem.l d1-d7/a3, (a1)
    adda.w  #size_long*8, a1
    dbra    d0, @Loop

    rts

VDP_CanvasPresent:
    ; --------------------------------------------------------------
    ; Copies canvas framebuffer to VDP
    ; --------------------------------------------------------------
    ; a0   - Canvas
    ; --------------------------------------------------------------

    PUSH.L  a0

    move.w Canvas_ByteOffset(a0), d0
    move.w Canvas_SizeWords(a0), d1
    move.l Canvas_FrameBuffer(a0), a0

    jsr    VDPDMA_TransferImmediateVRAM

    POP.L   a0

    rts

VDP_CanvasPlotPixel:
    ; --------------------------------------------------------------
    ; Plots a pixel onto a canvas tile
    ; --------------------------------------------------------------
    ; a1   - Framebuffer
    ; a2   - X offset table
	; d0.w - X coord (pixels)
	; d1.w - Y coord (pixels)
    ; d4.b - Colour idx
    ; --------------------------------------------------------------

    ; TODO

    rts

ABS_W macro 
    sub.w  \1,\2 
    subx.w \3,\3 
    eor.w  \3,\2 
    sub.w  \3,\2 
    endm

VDP_CanvasPlotLine:
    ; --------------------------------------------------------------
    ; Plots a line onto a canvas using Bresenham algorithm
    ; --------------------------------------------------------------
    ; a0   - Canvas
    ; d0.l - XY0
    ; d1.l - XY1
    ; d4.b - Colour idx
    ; --------------------------------------------------------------

    move.w d4, a6                       ; Backup colour
    move.l Canvas_FrameBuffer(a0), a1
    move.l Canvas_XOffsetTable(a0), a2

    ; Single pixel?
    cmp.l  d0, d1
    bne    @Multiple
    jsr    VDP_CanvasPlotPixel
    rts
    @Multiple:

    ; Steep? (more Y pixels to draw than X)
    move.w d1, d2   ; (y1 - y0)
    ABS_W  d0, d2, d6
    swap   d0       ; YX0
    swap   d1       ; YX1
    move.w d1, d3   ; (x1 - x0)
    ABS_W  d0, d3, d6

    cmp.w  d3, d2
    bgt    @Steep

    ; Drawing from left to right, so swap if necessary
    cmp.w  d0, d1
    bgt    @LtoR
    exg.l  d0, d1
    @LtoR:

    swap   d0       ; XY0
    swap   d1       ; XY1

    ; Straight line?
    cmp.w  d0, d1
    beq    @StraightX

    jsr    VDP_CanvasPlotLineXMajor
    rts

    @StraightX:

    move.w d0, d2   ; Y
    swap   d0       ; X0
    swap   d1       ; X1
    jsr    VDP_CanvasPlotLineXStraight
    rts

    @Steep:

    ; Straight line?
    cmp.w  d0, d1
    beq    @StraightY
    
    swap   d0       ; XY0
    swap   d1       ; XY1

    ; Drawing from top to bottom, so swap if necessary
    cmp.w  d0, d1
    bgt    @TtoB
    exg.l  d0, d1
    @TtoB:

    jsr    VDP_CanvasPlotLineYMajor
    rts

    @StraightY:

    move.w d0, d2   ; X

    swap   d0       ; XY0
    swap   d1       ; XY1
    
    ; Drawing from top to bottom, so swap if necessary
    cmp.w  d0, d1
    bgt    @TtoB2
    exg.l  d0, d1
    @TtoB2:
    
    jsr    VDP_CanvasPlotLineYStraight

    rts

VDP_CanvasPlotLineYMajor:
    ; --------------------------------------------------------------
    ; a0   - Canvas
    ; a1   - Framebuffer
    ; a2   - X offset table
    ; d0.l - XY0
    ; d1.l - XY1
    ; a6.b - Colour idx
    ; --------------------------------------------------------------

    ; Get initial framebuffer Y offset (4 bytes per pixel row)
    move.w d0, a4
    add.w  a4, a4
    add.w  a4, a4

    move.w d1, d3                       ; dy = y1 - y0
    sub.w  d0, d3

    swap   d0                           ; YX0                           
    swap   d1                           ; YX1

    ; Create pixel masks/shifts
    move.w a6, d2                       ; Get pixel
    lsl.b  #0x4, d2                     ; Pixels for either nibble
    swap   d2
    move.w a6, d2
    move.l #0x000F00F0, d4              ; Masks for either nibble

    btst   #0x0, d0                     ; If even pixel, swap
    bne.s  @OddPixel
    swap   d4
    swap   d2
    @OddPixel:
    move.l d4, a5
    move.l d2, a6

    ; Get initial framebuffer X offset (from lookup table)
    move.w d0, d2                       ; Get X
    add.w  d2, d2                       ; Word table
    adda.w d2, a2
    move.w (a2), a3                     ; Get framebuffer + X offset

    move.w #1, d4                       ; xi = 1

    move.w d1, d2                       ; dx = x1 - x0
    sub.w  d0, d2                       
    bgt    @dxok                        ; if dx < 0
    move.w #-1, d4                      ; xi = -1
    neg.w  d2                           ; dx = -dx
    @dxok:

    move.w d0, d5                       ; x = x0
    
    swap   d0                           ; XY0                           
    swap   d1                           ; XY1

    add.w  d2, d2                       ; 2*dx

    move.w d2, d6                       ; D = 2*dx - dy
    sub.w  d3, d6
    
    sub.w  d0, d1                       ; End - start = num pixels to draw

    move.l a5, d0                       ; Masks
    move.l a6, d7                       ; Pixels

    add.w  d3, d3                       ; 2*dy
    move.w d3, a5

    IF CANVAS_UNROLL_LOOPS

    cmp.w  #CANVAS_MAX_UNROLL, d1       ; Check if small enough to use unrolled loop
    bge    @NoUnroll

    add.w  d1, d1
    add.w  d1, d1
    lea    UnrollPlotYMajorTable, a0
    move.l (a0, d1), a0
    jsr    (a0)

    rts

    @NoUnroll:

    ; Unroll as far as possible, loop the rest
    jsr    UNROLL_PLOT_Y_MAJOR_\#CANVAS_MAX_UNROLL_START
    subi.w #CANVAS_MAX_UNROLL, d1

    ELSE
    subi.w #0x1, d1
    ENDIF

    ; --------------------------------------------------------------
    ; Loop Y axis
    ; --------------------------------------------------------------

    @Lp:

    ; Get pixel framebuffer address
    move.l a3, a0                       ; Framebuffer + X offset
    adda.w a4, a0                       ; Y offset

    ; Mask and set pixel
    IF CANVAS_MASK_PIXELS
    and.b  d0, (a0)
    ENDIF
    or.b   d7, (a0)

    ; Determine if X needs to advance
    tst.w  d6                           ; if D > 0
    blt    @NoAdvX
    add.w  d4, d5                       ; x = x + xi
    sub.w  a5, d6                       ; D = D - 2*dy

    ; X advanced, get new framebuffer X offset
    adda.w d4, a2                       ; Next X table address (words)
    adda.w d4, a2
    move.w (a2), a3                     ; Get framebuffer X offset (framebuffer at 32kb in RAM, so word loads sign extend)

    ; Swap masks and pixel nibbles
    IF CANVAS_MASK_PIXELS
    swap   d0
    ENDIF
    swap   d7

    @NoAdvX:

    add.w  d2, d6                       ; D = D + 2*dx
    addq.w #0x4, a4                     ; Next Y framebuffer offset (4 bytes per pixel row)

    dbra   d1, @Lp

    rts

VDP_CanvasPlotLineXMajor:
    ; --------------------------------------------------------------
    ; a0   - Canvas
    ; a1   - Framebuffer
    ; a2   - X offset table
    ; d0.l - XY0
    ; d1.l - XY1
    ; a6.b - Colour idx
    ; --------------------------------------------------------------

    move.w d0, d5                       ; y = y0

    move.w #1, d4                       ; yi = 1

    move.w d1, d2                       ; dy = y1 - y0
    sub.w  d0, d2
    bgt    @dyok                        ; if dy < 0
    move.w #-1, d4                      ; yi = -1
    neg.w  d2                           ; dy = -dy
    @dyok:

    swap   d0                           ; YX0
    swap   d1                           ; YX1

    ; Create pixel masks/shifts
    move.w a6, d6                       ; Get pixel
    lsl.b  #0x4, d6                     ; Pixels for either nibble
    swap   d6
    move.w a6, d6
    move.l #0x000F00F0, d7              ; Masks for either nibble

    btst   #0x0, d0                     ; If even pixel, swap
    bne.s  @OddPixel
    swap   d7
    swap   d6
    @OddPixel:
    move.l d7, a5
    move.l d6, a6

    move.w d1, d3                       ; dx = x1 - x0
    sub.w  d0, d3

    move.w d0, d6                       ; Get X offset
    add.w  d6, d6                       ; Word table
    adda.w d6, a2                       ; Byte offset

    add.w  d4, d4                       ; 4 bytes per Y offset
    add.w  d4, d4

    add.w  d2, d2                       ; 2*dy

    move.w d2, d6                       ; D = 2*dy - dx
    sub.w  d3, d6

    add.w  d3, d3                       ; 2*dx
    move.w d3, a4

    ; Get initial Y offset
    move.w d5, d3
    add.w  d3, d3
    add.w  d3, d3

    ; --------------------------------------------------------------
    ; Loop X axis
    ; --------------------------------------------------------------
    sub.w  d0, d1                       ; End - start = num pixels to draw

    move.l a5, d0                       ; Masks
    move.l a6, d7                       ; Pixels

    @Lp:

    ; Get pixel framebuffer address
    move.w (a2)+, a0                    ; Get X offset (framebuffer at 32kb in RAM, so word loads sign extend)
    adda.w d3, a0                       ; Add Y offset

    ; Mask and set pixel
    IF CANVAS_MASK_PIXELS
    and.b  d0, (a0)
    ENDIF
    or.b   d7, (a0)

    ; Swap masks and pixel nibbles
    IF CANVAS_MASK_PIXELS
    swap   d0
    ENDIF
    swap   d7

    add.w  d2, d6                       ; D = D + 2*dy

    ; Determine if Y needs to advance                        
    dbgt   d1, @Lp                      ; if D > 0

    add.w  d4, d3                       ; y = y + (yi*longword)
    sub.w  a4, d6                       ; D = D - 2*dx

    tst.w  d1
    dblt   d1, @Lp

    rts

VDP_CanvasPlotLineXStraight:
    ; --------------------------------------------------------------
    ; a0   - Canvas
    ; a1   - Framebuffer
    ; a2   - X offset table
    ; d0.w - X0
    ; d1.w - X1
    ; d2.w - Y
    ; a6.b - Colour idx
    ; --------------------------------------------------------------

    ; Create pixel mask/shift
    move.w a6, d6                       ; Get pixel
    lsl.b  #0x4, d6                     ; Pixels for either nibble
    swap   d6
    move.w a6, d6
    move.l #0x000F00F0, d5              ; Masks for either nibble

    btst   #0x0, d0                     ; If even pixel, swap
    bne.s  @OddPixel
    swap   d5
    swap   d6
    @OddPixel:

    ; Get Y byte offset
    move.w d2, d7
    add.w  d7, d7                       ; Get Y offset (4 bytes per pixel row)
    add.w  d7, d7

    ; Get X table offset
    move.w d0, d4                       ; Get X offset
    add.w  d4, d4                       ; Word table
    adda.w d4, a2

    sub.w  d0, d1                       ; End - start = num pixels to draw

    IF CANVAS_UNROLL_LOOPS

    cmp.w  #CANVAS_MAX_UNROLL, d1       ; Check if small enough to use unrolled loop
    bge    @NoUnroll

    add.w  d1, d1
    add.w  d1, d1
    lea    UnrollPlotXStraightTable, a0
    move.l (a0, d1), a0
    jsr    (a0)

    rts

    @NoUnroll:

    ; Unroll as far as possible, loop the rest
    jsr    UNROLL_PLOT_X_STRAIGHT_\#CANVAS_MAX_UNROLL_START
    subi.w #CANVAS_MAX_UNROLL, d1

    ELSE
    subi.w #0x1, d1
    ENDIF

    @Lp:

    ; Get pixel framebuffer address
    move.w (a2)+, a0                    ; X offset (framebuffer at 32kb in RAM, so word loads sign extend)
    adda.w d7, a0                       ; Y offset

    ; Mask and set pixel
    IF CANVAS_MASK_PIXELS
    and.b  d5, (a0)
    ENDIF
    or.b   d6, (a0)

    ; Swap masks/shifts
    IF CANVAS_MASK_PIXELS
    swap   d5
    ENDIF
    swap   d6
    
    dbra   d1, @Lp

    rts

VDP_CanvasPlotLineYStraight:
    ; --------------------------------------------------------------
    ; a0   - Canvas
    ; a1   - Framebuffer
    ; a2   - X offset table
    ; d0.w - Y0
    ; d1.w - Y1
    ; d2.w - X
    ; a6.b - Colour idx
    ; --------------------------------------------------------------

    ; Create pixel mask/shift
    move.w a6, d6                       ; Get pixel
    lsl.b  #0x4, d6                     ; Pixels for either nibble
    swap   d6
    move.w a6, d6
    move.l #0x000F00F0, d5              ; Masks for either nibble

    btst   #0x0, d2                     ; If even pixel, swap
    bne.s  @OddPixel
    swap   d5
    swap   d6
    @OddPixel:

    ; Get pixel framebuffer address
    move.w d0, d7                       ; Get Y offset (4 bytes per pixel row)
    add.w  d7, d7
    add.w  d7, d7

    move.w d2, d4                       ; Get X offset
    add.w  d4, d4                       ; Word table
    adda.w d4, a2
    move.w (a2), a1                     ; X byte offset (framebuffer at 32kb in RAM, so word loads sign extend)
    adda.w d7, a1                       ; Offset framebuffer

    sub.w  d0, d1                       ; End - start = num pixels to draw

    IF CANVAS_UNROLL_LOOPS

    cmp.w  #CANVAS_MAX_UNROLL, d1       ; Check if small enough to use unrolled loop
    bge    @NoUnroll

    add.w  d1, d1
    add.w  d1, d1
    lea    UnrollPlotYStraightTable, a0
    move.l (a0, d1), a0
    jsr    (a0)

    rts

    @NoUnroll:

    ; Unroll as far as possible, loop the rest
    jsr    UNROLL_PLOT_Y_STRAIGHT_\#CANVAS_MAX_UNROLL_START
    subi.w #CANVAS_MAX_UNROLL, d1

    ELSE
    subi.w #0x1, d1
    ENDIF

    @Lp:

    ; Mask and set pixel
    IF CANVAS_MASK_PIXELS
    and.b  d5, (a1)
    ENDIF
    or.b   d6, (a1)

    ; Next Y
    adda.w #0x4, a1
    
    dbra   d1, @Lp

    rts



;==============================================================



    IF CANVAS_UNROLL_LOOPS
;==============================================================
; Unrolled loop for VDP_CanvasPlotLineYMajor
;==============================================================

UNROLL_IDX = CANVAS_MAX_UNROLL-1
    REPT CANVAS_MAX_UNROLL
UNROLL_PLOT_Y_MAJOR_\#UNROLL_IDX:

    ; Get pixel framebuffer address
    move.l a3, a0                       ; Framebuffer + X offset
    adda.w a4, a0                       ; Y offset

    ; Mask and set pixel
    IF CANVAS_MASK_PIXELS
    and.b  d0, (a0)
    ENDIF
    or.b   d7, (a0)

    ; Determine if X needs to advance
    tst.w  d6                           ; if D > 0
    blt    @NoAdvX_\#UNROLL_IDX
    add.w  d4, d5                       ; x = x + xi
    sub.w  a5, d6                       ; D = D - 2*dy

    ; X advanced, get new framebuffer X offset
    adda.w d4, a2                       ; Next X table address (words)
    adda.w d4, a2
    move.w (a2), a3                     ; Get framebuffer X offset (framebuffer at 32kb in RAM, so word loads sign extend)

    ; Swap masks and pixel nibbles
    IF CANVAS_MASK_PIXELS
    swap   d0
    ENDIF
    swap   d7

    @NoAdvX_\#UNROLL_IDX:

    add.w  d2, d6                       ; D = D + 2*dx
    addq.w #0x4, a4                     ; Next Y framebuffer offset (4 bytes per pixel row)

UNROLL_IDX = UNROLL_IDX-1
    ENDR
    rts

UnrollPlotYMajorTable:
UNROLL_IDX = 0
    REPT CANVAS_MAX_UNROLL
    dc.l UNROLL_PLOT_Y_MAJOR_\#UNROLL_IDX
UNROLL_IDX = UNROLL_IDX+1
    ENDR

;==============================================================

;==============================================================
; Unrolled loop for VDP_CanvasPlotLineXStraight
;==============================================================

UNROLL_IDX = CANVAS_MAX_UNROLL-1
    REPT CANVAS_MAX_UNROLL
UNROLL_PLOT_X_STRAIGHT_\#UNROLL_IDX:

    ; Get pixel framebuffer address
    move.w (a2)+, a0                    ; X offset (framebuffer at 32kb in RAM, so word loads sign extend)
    adda.w d7, a0                       ; Y offset

    ; Mask and set pixel
    IF CANVAS_MASK_PIXELS
    and.b  d5, (a0)
    ENDIF
    or.b   d6, (a0)

    ; Swap masks/shifts
    IF CANVAS_MASK_PIXELS
    swap   d5
    ENDIF
    swap   d6

UNROLL_IDX = UNROLL_IDX-1
    ENDR
    rts

UnrollPlotXStraightTable:
UNROLL_IDX = 0
    REPT CANVAS_MAX_UNROLL
    dc.l UNROLL_PLOT_X_STRAIGHT_\#UNROLL_IDX
UNROLL_IDX = UNROLL_IDX+1
    ENDR

;==============================================================

;==============================================================
; Unrolled loop for VDP_CanvasPlotLineYStraight
;==============================================================

UNROLL_IDX = CANVAS_MAX_UNROLL-1
    REPT CANVAS_MAX_UNROLL
UNROLL_PLOT_Y_STRAIGHT_\#UNROLL_IDX:

    ; Mask and set pixel
    IF CANVAS_MASK_PIXELS
    and.b  d5, (a1)
    ENDIF
    or.b   d6, (a1)

    ; Next Y
    adda.w #0x4, a1

UNROLL_IDX = UNROLL_IDX-1
    ENDR
    rts

UnrollPlotYStraightTable:
UNROLL_IDX = 0
    REPT CANVAS_MAX_UNROLL
    dc.l UNROLL_PLOT_Y_STRAIGHT_\#UNROLL_IDX
UNROLL_IDX = UNROLL_IDX+1
    ENDR

;==============================================================
    ENDIF  ; CANVAS_UNROLL_LOOPS