; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; PALETTES.ASM - Palette loading and management routines
; ============================================================================================

VDP_LoadPalette:
    ; ======================================
    ; Loads a palette into CRAM
    ; ======================================
    ; a0   Palette
    ; d0.b Palette index
    ; ======================================

    ; Index to addr offset
    andi.w #0x0F, d0
    move.w d0, d1

    ; To RAM
    lsl.w  #0x2, d1
    lea    RAM_VDP_PALETTES, a1
    adda.w d1, a1
    move.l a0, (a1)

    ; To CRAM
    lsl.w  #SIZE_PALETTE_SHIFT, d0
    VDP_SETADDRESS d0,#0x0000,#VDP_CMD_CRAM_WRITE

    ; 32 bytes
    REPT 8
    move.l (a0)+, PORT_VDP_DATA
    ENDR

    rts

VDP_LoadPalettes:
    ; ======================================
    ; Loads multiple palettes into CRAM,
    ; from index 0
    ; ======================================
    ; a0   Palettes addr
    ; d0.w Palette count
    ; ======================================

    ; To RAM
    lea    RAM_VDP_PALETTES, a1

    ; To CRAM
    VDP_SET_CRAM_WRITE 0x0000

    ; 32 bytes per palette
    subi.w #0x1, d0
    @PalLp:
    move.l a0, (a1)+
    REPT 8
    move.l (a0)+, PORT_VDP_DATA
    ENDR
    dbra   d0, @PalLp

    rts

VDP_ExtractPalette:
    ; ======================================
    ; Extracts colour components from palette
    ; into 8.8 RGB byte array for palette
    ; fade operations.
    ; ======================================
    ; a0   Palette addr
    ; a1   Extracted RGB colour data (16*RGB 8.8)
    ; ======================================

    move.w #16-1, d0
    @PalLp:
    move.w (a0)+, d1  ; B
    move.w d1, d2
    andi.w #0xF, d2
    lsr.w  #0x4, d1   ; G
    move.w d1, d3
    andi.w #0xF, d3
    lsr.w  #0x4, d1   ; R
    move.w d1, d4
    andi.w #0xF, d4
    lsl.w   #0x8, d4        ; To 8.8 range
    lsl.w   #0x8, d3
    lsl.w   #0x8, d2
    move.w d4, (a1)+
    move.w d3, (a1)+
    move.w d2, (a1)+
    dbra   d0, @PalLp

    rts

VDP_FadePalette:
    ; ======================================
    ; Fades from current palette to a new one
    ; ======================================
    ; a0   Palette addr
    ; d0.w Palette index
    ; d1.w Palette fade frames
    ; ======================================

    ; Set fade frames and dest palette
    lea     RAM_VDP_PAL_FADE_FRAME, a3
    lea     RAM_VDP_PAL_FADE_DST, a4
    move.w  d0, d2
    move.w  d0, d3
    lsl.w   #0x1, d2
    lsl.w   #0x2, d3
    adda.w  d2, a3
    adda.w  d3, a4
    move.w  d1, (a3)
    move.l  a0, (a4)

    move.w  d0, d3
    mulu.w  #16*3*SIZE_WORD, d3

    ; Extract colours of current palette
    PUSHM.l a0-a2/d0-d3
    lea     RAM_VDP_PALETTES, a0        ; Get address of current palette
    move.w  d0, d2
    lsl.w   #0x2, d2
    adda.w  d2, a0
    move.l  (a0), a0
    lea     RAM_VDP_PAL_FADE_SRC, a1    ; Get address of palette fade data
    adda.w  d3, a1
    bsr     VDP_ExtractPalette
    POPM.l  a0-a2/d0-d3

    ; Extract colours of new palette
    STACK_ALLOC #16*3*SIZE_WORD, a1
    PUSHM.l a0-a2/d0-d3
    bsr     VDP_ExtractPalette
    POPM.l  a0-a2/d0-d3

    ; Work out deltas between current colour components and dest colour components
    lea     RAM_VDP_PAL_FADE_SRC, a0
    lea     RAM_VDP_PAL_FADE_DELTA, a2
    adda.w  d3, a0
    adda.w  d3, a2
    move.w  #(16*3)-1, d6   ; 16 * RGB
    @ColourLp:
    moveq   #0x0, d3
    move.w  (a0)+, d2       ; Src colour component
    move.w  (a1)+, d3       ; Dst colour component
    sub.w   d2, d3          ; Delta
    divs.w  d1, d3          ; Over frames
    move.w  d3, (a2)+       ; To RAM
    dbra    d6, @ColourLp

    STACK_FREE #16*3*SIZE_WORD

    rts

VDP_FadePalettes:
    ; ======================================
    ; Fades multiple palettes from index 0
    ; ======================================
    ; a0   Palettes addr
    ; d0.w Palette count
    ; d1.w Palette fade frames
    ; ======================================

    move.w  d0, d2
    moveq   #0x0, d0
    subi.w  #0x1, d2
    @PaletteLp:
    PUSHM.l a0/d0-d1
    bsr     VDP_FadePalette
    POPM.l  a0/d0-d1
    addi.w  #0x1, d0
    adda.w  #SIZE_PALETTE_B, a0
    dbra    d2, @PaletteLp

    rts

VDP_UpdatePaletteFade:
    ; ======================================
    ; Palette fade update
    ; ======================================

    lea    RAM_VDP_PAL_FADE_FRAME, a0
    lea    RAM_VDP_PAL_FADE_SRC, a1
    lea    RAM_VDP_PAL_FADE_DST, a2
    lea    RAM_VDP_PAL_FADE_DELTA, a3
    lea    RAM_VDP_PAL_FADE_TEMP, a4
    move.w #4-1, d0
    moveq  #0x0, d2
    @PaletteLp:
    move.w (a0), d1         ; Get fade frame counter for this palette
    cmp.w  #-1, d1
    beq    @NextPalette

    subi.w #0x1, d1         ; Decrement frame counter
    bne    @CalcNewPalette

    ; Last frame, upload dest palette
    PUSHM.l d0-d2/a0-a4
    move.l  (a2), a0
    move.w  d2, d0
    bsr     VDP_LoadPalette
    POPM.l  d0-d2/a0-a4

    ; Disable fade
    move.w  #-1, (a0)

    bra     @NextPalette

    @CalcNewPalette:

    ; Calculate and upload next palette from deltas
    move.w  d1, (a0)        ; Store new frame counter

    PUSHM.l d0-d2/a0-a4
    move.w  #16-1, d3
    @ColourLp:

    ; Update from deltas
    move.w  (a1), d0        ; Current R
    move.w  (a3)+, d4       ; Delta R
    add.w   d4, d0			; Add R
    move.w  d0, (a1)+   	; Back to RAM
    move.w  (a1), d1        ; Current G
    move.w  (a3)+, d4       ; Delta G
    add.w   d4, d1			; Add G
    move.w  d1, (a1)+   	; Back to RAM
    move.w  (a1), d2        ; Current B
    move.w  (a3)+, d4       ; Delta B
    add.w   d4, d2			; Add B
    move.w  d2, (a1)+		; Back to RAM

    ; Create palette colour
    moveq   #0x0, d4
    andi.w  #0x0F00, d0		; R 8.8 to palette
    andi.w  #0x0F00, d1		; G 8.8 to palette
    lsr.w   #0x4, d1
    lsr.w   #0x8, d2		; B 8.8 to palette
    or.w    d1, d0
    or.w    d2, d0
    move.w  d0, (a4)+       ; To palette
    dbra    d3, @ColourLp
    POPM.l  d0-d2/a0-a4

    ; Upload palette
    PUSHM.l d0-d2/a0-a4
    move.l  a4, a0
    move.w  d2, d0
    bsr     VDP_LoadPalette
    POPM.l  d0-d2/a0-a4

    @NextPalette:
    adda.w #SIZE_WORD, a0
    adda.w #16*3*SIZE_WORD, a1
    adda.w #SIZE_LONG, a2
    adda.w #16*3*SIZE_WORD, a3
    adda.w #SIZE_PALETTE_B, a4
    addi.w #0x1, d2
    dbra   d0, @PaletteLp

    rts