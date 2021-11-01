; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 25th October 2021
; ============================================================================================
; STRING.ASM - Macros for string manipulation
; ============================================================================================

STR_PUSH: macro str,length
    ; ======================================
    ; Pushes a string to the stack (no terminator),
    ; returns length
    ; ======================================
    ; "str"    - String to embed
    ; length.w - Out: string length
    ; ======================================
    move.l \str, a0
    bsr    STR_LenA
    suba.w d0, sp
    move.l sp, a1
    move.w d0, d1
    subq   #1, d1
    @_lp\@:
    move.b (a0)+, (a1)+
    dbra   d1, @_lp\@
    move.w d0, \length
    endm

STR_INLINE: macro str,reg_addr
    ; ======================================
    ; Embeds a string inline into ROM, and
    ; returns address in a register
    ; ======================================
    ; "str"  - String to embed
    ; reg.a  - Destination reg
    ; ======================================
    lea    @_string\@, \reg_addr
    bra    @_end\@
    @_string\@:
    dc.b   \str\,0
    even
    @_end\@:
    endm

STR_PACKLONG: macro str reg
    ; ======================================
    ; Packs 4 chars from a string into a
    ; longword register
    ; ======================================
    ; str.a  - String address
    ; reg.d  - Destination reg
    ; ======================================
    move.b (\str)+, d0
    lsl.w  #0x08, d0
    move.b (\str)+, d0
    lsl.l  #0x08, d0
    move.b (\str)+, d0
    lsl.l  #0x08, d0
    move.b (\str), d0
    endm
