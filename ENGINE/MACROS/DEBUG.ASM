; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 3rd August 2019
; ============================================================================================
; DEBUG.ASM - Debugging macros
; ============================================================================================

    ; ======================================
    ; Draws a string to plane A
    ; ======================================
    ; x    Cell pos X
    ; y    Cell pos Y
    ; string - String to draw
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; Does not account for scrolling.
    ; ======================================
DBG_DRAW_STRING: macro x,y,string
    PUSHM.L d0-d3/a0
    lea    @string\@, a0
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawString
    bra    @string_end\@
    @string\@:
    dc.b   \string\,0
    even
    @string_end\@:
    POPM.L d0-d3/a0
    endm

    ; ======================================
    ; Resets the system and draws an error
    ; string, incl. registers and stack,
    ; and halts indefinitely.
    ; ======================================
    ; string - Error string to draw
    ; ======================================
DBG_RAISE_ERROR: macro string
    bsr    ERR_ResetForError
    lea    @err_string\@, a0
    bsr    ERR_DrawMessage
    bra    *
    @err_string\@:
    dc.b   \string\,0
    even
    endm