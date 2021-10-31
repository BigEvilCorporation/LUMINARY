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

    ; Alloc VRAM text buffer
    move.w #DLG_VRAM_BUFF_SIZE, d0
    bsr    VRAMMGR_Alloc
    move.l d1, RAM_DIALOG_VRAM_BUFFER

    move.b #0, RAM_DIALOG_WAIT_INPUT
    move.b #0, RAM_DIALOG_LAST_CHOICE

    rts

DLG_Open:
    ; ======================================
    ; Draws a dialog box and begins waiting
    ; for user input
    ; ======================================
	; a0   String
    ; a1   Font
    ; d0.b Wait for user input (0 or 1)
    ; ======================================

    move.b d0, RAM_DIALOG_WAIT_INPUT

    ; Load glyphs into VRAM
    move.l RAM_DIALOG_VRAM_BUFFER, d0
    bsr    TXT_LoadSpriteTiles

    move.w d1, RAM_DIALOG_STRING_LEN        ; String length
    move.w #1, RAM_DIALOG_TYPEWRITER_LEN    ; Animated string length
    move.w #DLG_DEFAULT_TYPE_DELAY, RAM_DIALOG_TYPEWRITER_TIMER

    rts

DLG_Close:
    ; ======================================
    ; Closes the current dialog box
    ; ======================================

    move.w #0, RAM_DIALOG_STRING_LEN

    rts

DLG_Update:
    ; ======================================
    ; Updates the current dialog box
    ; ======================================

    move.w RAM_DIALOG_TYPEWRITER_LEN, d1
    move.w RAM_DIALOG_STRING_LEN, d2

    ; If waiting for user input
    tst.b  RAM_DIALOG_WAIT_INPUT
    beq    @EndInput
    move.w RAM_GAMEPAD_DBNC_1, d0
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

    ; Draw text
    tst.w  RAM_DIALOG_STRING_LEN
    beq    @NoText
    move.w RAM_DIALOG_TYPEWRITER_LEN, d4; Length to draw
    move.w #DLG_DEFAULT_X+DLG_TEXT_BORDER_X, d0 ; X
    move.w #DLG_DEFAULT_Y+DLG_TEXT_BORDER_Y, d1 ; Y
    move.l RAM_DIALOG_VRAM_BUFFER, d2   ; VRAM buffer
    move.b #0, d3                       ; Palette
    bsr    TXT_DrawLineS
    @NoText:

    rts