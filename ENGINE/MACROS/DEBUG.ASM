; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 3rd August 2019
; ============================================================================================
; DEBUG.ASM - Error and debugging macros
; ============================================================================================

    ; ======================================
    ; Assembly time static error
    ; ======================================
    ; string - Error string to output
    ; ======================================
DBG_STATIC_ERROR: macro string
    inform 2,\string\,\2,\3,\4
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

    ; ======================================
    ; Draws a string with sprites
    ; ======================================
    ; x    Cell pos X
    ; y    Cell pos Y
    ; string - String to draw
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; ======================================
DBG_DRAW_STRING_S: macro x,y,string
    PUSHM.L d0-d3/a0
    lea    @string\@, a0
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawStringS
    bra    @string_end\@
    @string\@:
    dc.b   \string\,0
    even
    @string_end\@:
    POPM.L d0-d3/a0
    endm

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
DBG_DRAW_STRING_A: macro x,y,string
    PUSHM.L d0-d3/a0
    lea    @string\@, a0
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawStringA
    bra    @string_end\@
    @string\@:
    dc.b   \string\,0
    even
    @string_end\@:
    POPM.L d0-d3/a0
    endm

    ; ======================================
    ; Draws a byte with sprites
    ; ======================================
    ; x    Cell pos X
    ; y    Cell pos Y
    ; byte - byte to draw
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; ======================================
DBG_DRAW_BYTE_S: macro x,y,byte
    PUSHM.L d0-d3/a0-a1
    STACK_ALLOC 4, a0                   ; Alloc space for string
    move.l \byte, d0
    bsr    STR_ItoA_Hex_b
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawStringS
    STACK_FREE 4                        ; Free string
    POPM.L d0-d3/a0-a1
    endm

    ; ======================================
    ; Draws a byte to plane A
    ; ======================================
    ; x    Cell pos X
    ; y    Cell pos Y
    ; byte - byte to draw
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; Does not account for scrolling.
    ; ======================================
DBG_DRAW_BYTE_A: macro x,y,byte
    PUSHM.L d0-d3/a0-a1
    STACK_ALLOC 4, a0                   ; Alloc space for string
    move.l \byte, d0
    bsr    STR_ItoA_Hex_b
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawStringA
    STACK_FREE 4                        ; Free string
    POPM.L d0-d3/a0-a1
    endm

    ; ======================================
    ; Draws a word with sprites
    ; ======================================
    ; x    Cell pos X
    ; y    Cell pos Y
    ; word - word to draw
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; ======================================
DBG_DRAW_WORD_S: macro x,y,word
    PUSHM.L d0-d3/a0-a1
    STACK_ALLOC 6, a0                   ; Alloc space for string
    move.l \word, d0
    bsr    STR_ItoA_Hex_w
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawStringS
    STACK_FREE 6                        ; Free string
    POPM.L d0-d3/a0-a1
    endm

    ; ======================================
    ; Draws a word to plane A
    ; ======================================
    ; x    Cell pos X
    ; y    Cell pos Y
    ; word - word to draw
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; Does not account for scrolling.
    ; ======================================
DBG_DRAW_WORD_A: macro x,y,word
    PUSHM.L d0-d3/a0-a1
    STACK_ALLOC 6, a0                   ; Alloc space for string
    move.l \word, d0
    bsr    STR_ItoA_Hex_w
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawStringA
    STACK_FREE 6                        ; Free string
    POPM.L d0-d3/a0-a1
    endm

    ; ======================================
    ; Draws a longword with sprites
    ; ======================================
    ; x    Cell pos X
    ; y    Cell pos Y
    ; long - Longword to draw
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; Does not account for scrolling.
    ; ======================================
DBG_DRAW_LONG_S: macro x,y,long
    PUSHM.L d0-d3/a0-a1
    STACK_ALLOC 10, a0                  ; Alloc space for string
    move.l \long, d0
    bsr    STR_ItoA_Hex_l
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawStringS
    STACK_FREE 10                       ; Free string
    POPM.L d0-d3/a0-a1
    endm

    ; ======================================
    ; Draws a longword to plane A
    ; ======================================
    ; x    Cell pos X
    ; y    Cell pos Y
    ; long - Longword to draw
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; Does not account for scrolling.
    ; ======================================
DBG_DRAW_LONG_A: macro x,y,long
    PUSHM.L d0-d3/a0-a1
    STACK_ALLOC 10, a0                  ; Alloc space for string
    move.l \long, d0
    bsr    STR_ItoA_Hex_l
    move.w \x, d0
    move.w \y, d1
    bsr    DBG_DrawStringA
    STACK_FREE 10                       ; Free string
    POPM.L d0-d3/a0-a1
    endm
