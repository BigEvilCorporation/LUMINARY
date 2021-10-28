; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 25th October 2021
; ============================================================================================
; STRING.ASM - Macros for string manipulation
; ============================================================================================

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
