; ============================================================================================
; THE ALEXANDRA PROJECT / THE NICO EXPERIMENT - a game for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 27th October 2021
; ============================================================================================
; DIALOGUE.ASM - Dialog boxes and option selection
; ============================================================================================

DLG_Initialise:
    ; ======================================
    ; Initialises the dialog system
    ; ======================================
    ; a0   Default font
    ; a1   Default cursor
    ; ======================================

    move.l a0, RAM_DIALOG_DEFAULT_FONT
    move.l a1, RAM_DIALOG_DEFAULT_CURSOR

    ; Load cursor
    move.w #1, d0
    PUSH.L a1
    bsr    VRAMMGR_Alloc
    POP.L  a1
    move.l d1, RAM_DIALOG_VRAM_CURSOR
    VDP_TILES_TO_BYTES d1               ; Tile to bytes
    move.l a1, a0                       ; DMA src
    move.w d1, d0                       ; DMA dest
    move.w #SIZE_TILE_W, d1             ; DMA size
    bsr    VDPDMA_TransferImmediateVRAM

    ; Alloc VRAM text buffer
    move.w #DLG_VRAM_BUFF_SIZE, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_DIALOG_VRAM_BUFFER

    move.l #0, RAM_DIALOG_OPEN_FRAME
    move.l #0, RAM_DIALOG_CHOICE_LIST
    move.b #0, RAM_DIALOG_CHOICE_COUNT
    move.b #0, RAM_DIALOG_WAIT_INPUT
    move.b #0, RAM_DIALOG_CURR_CHOICE

    rts

DLG_Open:
    ; ======================================
    ; Opens a dialog box and begins waiting
    ; for user input
    ; ======================================
	; a0   String
    ; d0.b Wait for user input (0 or 1)
    ; ======================================

    move.b d0, RAM_DIALOG_WAIT_INPUT

    move.w (a0), RAM_DIALOG_STRING_LEN      ; String length
    move.w #1, RAM_DIALOG_TYPEWRITER_LEN    ; Animated string length
    move.w #DLG_DEFAULT_TYPE_DELAY, RAM_DIALOG_TYPEWRITER_TIMER
    move.l #0, RAM_DIALOG_CHOICE_LIST
    move.b #0, RAM_DIALOG_CHOICE_COUNT
    move.l RAM_VBLANK_COUNTER, RAM_DIALOG_OPEN_FRAME

    ; Load glyphs into VRAM
    move.l RAM_DIALOG_VRAM_BUFFER, d0
    move.l RAM_DIALOG_DEFAULT_FONT, a1
    bsr    TXT_LoadSpriteTiles

    rts

DLG_OpenChoice:
    ; ======================================
    ; Opens a dialog box with user choices,
    ; and begins waiting for selection
    ; ======================================
	; a0   String (prefixed w/ word length)
    ; a2   Choice list (str,addr,str,addr...)
    ; d0.b Number of user choices in list
    ; ======================================

    move.l a2, RAM_DIALOG_CHOICE_LIST
    move.b d0, RAM_DIALOG_CHOICE_COUNT
    move.b #0, RAM_DIALOG_CURR_CHOICE
    move.w #0, RAM_DIALOG_STRING_LEN
    move.w #0, RAM_DIALOG_TYPEWRITER_LEN
    move.l RAM_VBLANK_COUNTER, RAM_DIALOG_OPEN_FRAME
    
    move.l RAM_DIALOG_VRAM_BUFFER, d0
    move.l RAM_DIALOG_DEFAULT_FONT, a1

    cmpa.l #0, a0
    beq    @NoQuestion
    move.w (a0), RAM_DIALOG_STRING_LEN      ; String length
    move.w #1, RAM_DIALOG_TYPEWRITER_LEN    ; Animated string length
    move.w #DLG_DEFAULT_TYPE_DELAY, RAM_DIALOG_TYPEWRITER_TIMER

    ; Load glyphs for question string into VRAM
    bsr    TXT_LoadSpriteTiles
    @NoQuestion:

    move.b #1, RAM_DIALOG_WAIT_INPUT

    ; Load glyphs for answer strings into VRAM
    move.l RAM_DIALOG_CHOICE_LIST, a2
    moveq  #0, d1
    move.b RAM_DIALOG_CHOICE_COUNT, d1
    subq   #1, d1
    @ChoiceLp:
    move.l (a2)+, a0        ; String
    adda.w #SIZE_LONG, a2   ; Skip address
    PUSHM.L d1/a1-a2
    bsr    TXT_LoadSpriteTiles
    POPM.L  d1/a1-a2
    dbra   d1, @ChoiceLp

    rts

DLG_Close:
    ; ======================================
    ; Closes the current dialog box
    ; ======================================

    move.l #0, RAM_DIALOG_CHOICE_LIST
    move.w #0, RAM_DIALOG_STRING_LEN
    move.b #0, RAM_DIALOG_CHOICE_COUNT
    move.b #0, RAM_DIALOG_WAIT_INPUT

    rts

DLG_Update:
    ; ======================================
    ; Updates the current dialog box
    ; ======================================

    move.w RAM_DIALOG_TYPEWRITER_LEN, d1
    move.w RAM_DIALOG_STRING_LEN, d2

    ; Don't process input on the same frame the dialog was opened
    move.l RAM_VBLANK_COUNTER, d0
    cmp.l  RAM_DIALOG_OPEN_FRAME, d0
    beq    @EndInput

    ; If waiting for user input
    tst.b  RAM_DIALOG_WAIT_INPUT
    beq    @EndInput

    move.w RAM_GAMEPAD_DBNC_1, d0

    ; If a choice dialog, process up/down
    moveq  #0, d3
    moveq  #0, d4
    move.b RAM_DIALOG_CHOICE_COUNT, d3
    move.b RAM_DIALOG_CURR_CHOICE, d4

    btst   #PAD_BUTTON_UP, d0
    beq    @EndUp
    subq   #1, d4
    bge    @EndUp
    move.b d3, d4
    subq   #1, d4
    @EndUp:

    btst   #PAD_BUTTON_DOWN, d0
    beq    @EndDown
    addq   #1, d4
    cmp    d3, d4
    blt    @EndDown
    move.b #0, d4
    @EndDown:

    move.b d4, RAM_DIALOG_CURR_CHOICE

    ; Process OK button
    btst   #PAD_BUTTON_A, d0
    beq    @EndInput

    ; If still typewriting, first press advances to the end
    cmp.w  d2, d1
    beq    @Close
    move.w d2, RAM_DIALOG_TYPEWRITER_LEN
    rts
    @Close:
    ; If typewriting finished, button closes dialog
    move.b #0, RAM_DIALOG_WAIT_INPUT
    bsr     DLG_Close
    rts
    @EndInput:

    ; Typewriter animation
    cmp.w  d2, d1
    beq    @EndTypewriter                   ; If at end of string
    move.w RAM_DIALOG_TYPEWRITER_TIMER, d0  ; Decrement timer
    subq.w #1, d0
    move.w d0, RAM_DIALOG_TYPEWRITER_TIMER
    bne    @EndTypewriter                   ; If timer not depleted
    addq.w #1, d1                           ; Next char
    move.w d1, RAM_DIALOG_TYPEWRITER_LEN
    move.w #DLG_DEFAULT_TYPE_DELAY, RAM_DIALOG_TYPEWRITER_TIMER
    @EndTypewriter:

    rts

DLG_Render:
    ; ======================================
    ; Draws the current dialog box
    ; ======================================

    ; Draw main text
    tst.w  RAM_DIALOG_STRING_LEN
    beq    @NoMainText
    move.w RAM_DIALOG_TYPEWRITER_LEN, d4; Length to draw
    move.w #DLG_DEFAULT_X+DLG_TEXT_BORDER_X, d0 ; X
    move.w #DLG_DEFAULT_Y+DLG_TEXT_BORDER_Y, d1 ; Y
    move.l RAM_DIALOG_VRAM_BUFFER, d2   ; VRAM buffer
    move.b #0, d3                       ; Palette
    bsr    TXT_DrawLineS
    @NoMainText:

    ; If main text fully drawn, also draw choices and cursor
    tst.b  RAM_DIALOG_CHOICE_COUNT
    beq    @NoChoices
    move.w RAM_DIALOG_TYPEWRITER_LEN, d0
    cmp.w  RAM_DIALOG_STRING_LEN, d0
    bne    @NoChoices

    move.w #DLG_DEFAULT_X+DLG_TEXT_BORDER_X+1, d0 ; X+1
    move.w #DLG_DEFAULT_Y+DLG_TEXT_BORDER_Y+1, d1 ; Y+1
    move.l RAM_DIALOG_VRAM_BUFFER, d2   ; Skip past main text in VRAM buffer
    add.w  RAM_DIALOG_STRING_LEN, d2

    move.l RAM_DIALOG_CHOICE_LIST, a2
    moveq  #0, d3
    move.b RAM_DIALOG_CHOICE_COUNT, d3
    subq   #1, d3
    @ChoiceLp:
    move.l (a2)+, a0                    ; String
    move.w (a0)+, d4                    ; String length
    adda.w #SIZE_LONG, a2               ; Skip address
    PUSHM.L d0-d4/a2
    move.b #0, d3                       ; Palette
    bsr    TXT_DrawLineS
    POPM.L  d0-d4/a2
    add.w  d4, d2						; Next VRAM string
    addq.w #1, d1                       ; Next Y
    dbra   d3, @ChoiceLp
    
    ; Draw cursor
    move.w #DLG_DEFAULT_X+DLG_TEXT_BORDER_X, d0   ; X
    move.w #DLG_DEFAULT_Y+DLG_TEXT_BORDER_Y+1, d1 ; Y + 1 + current choice
    moveq  #0, d2
    move.b RAM_DIALOG_CURR_CHOICE, d2
    add.w  d2, d1

    VDP_TILES_TO_PIXELS d0              ; Coords to sprite space
    VDP_TILES_TO_PIXELS d1
    addi.w #VDP_SPRITE_BORDER_X, d0
    addi.w #VDP_SPRITE_BORDER_Y, d1

    move.l RAM_DIALOG_VRAM_CURSOR, d2   ; Tile
    move.w #0, d3                       ; Palette
    move.b #VDP_SPRITE_LAYOUT_1x1, d4   ; Layout
    bsr    SPR_Draw
    
    @NoChoices:

    rts