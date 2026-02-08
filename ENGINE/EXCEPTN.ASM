;==============================================================
;   http://www.bigevilcorporation.co.uk
;==============================================================
;   SEGA Genesis Framework (c) Matt Phillips 2016
;==============================================================
;   exceptn.asm - 68k exception handler
;==============================================================

ERR_EXCEPTION: macro error_type
	; CPU has already pushed these regs:
	; PC reg (longword)
	; Status reg = (word)
	
	; Pad status reg to longword
	move.w  #0x0, -(sp)

	; Push stack ptr to stack
	move.l  sp, -(sp)
	
	; Push all registers to stack
	movem.l d0-d7/a0-a6, -(sp)

	; Push error type
	move.w #\error_type, -(sp)

	; Draw the exception screen
    jmp    ERR_HandleException

	endm

ERR_EXCEPTION_HEADERPOSX		equ 0x02
ERR_EXCEPTION_HEADERPOSY		equ 0x01
ERR_EXCEPTION_MSGPOSX			equ 0x02
ERR_EXCEPTION_MSGPOSY			equ 0x05
ERR_EXCEPTION_USERPOSX			equ 0x02
ERR_EXCEPTION_USERPOSY			equ 0x03
ERR_EXCEPTION_REGDPOSX			equ 0x02
ERR_EXCEPTION_REGDPOSY			equ 0x07
ERR_EXCEPTION_REGAPOSX			equ 0x0F
ERR_EXCEPTION_REGAPOSY			equ 0x07
ERR_EXCEPTION_REGSPOSX			equ 0x02
ERR_EXCEPTION_REGSPOSY			equ 0x11
ERR_EXCEPTION_STACKPOSX			equ 0x01C
ERR_EXCEPTION_STACKPOSY			equ 0x05
ERR_EXCEPTION_FOOTER1POSX		equ 0x02
ERR_EXCEPTION_FOOTER1POSY		equ 0x18
ERR_EXCEPTION_FOOTER2POSX		equ 0x02
ERR_EXCEPTION_FOOTER2POSY		equ 0x1A
ERR_EXCEPTION_LINESPACE			equ 0x01
ERR_EXCEPTION_REGCOUNTD			equ 0x08	; 8x D regs (d0-d7)
ERR_EXCEPTION_REGCOUNTA			equ 0x07	; 7x A regs (a0-a6)
ERR_EXCEPTION_REGCOUNTS			equ 0x03	; 3x S regs (SP + SR + PC)
ERR_EXCEPTION_MAXSTACK			equ 0x10
ERR_EXCEPTION_REG_STRLEN		equ 0x04
ERR_EXCEPTION_ERROR_STRLEN		equ 0x18
ERR_EXCEPTION_HEART_SYMBOL		equ STR_ASCII_START+(SIZEOF_debug_font/SIZE_TILE_B)

ERR_EXCEPTIONTYPE_ADDRESS		equ 0x0
ERR_EXCEPTIONTYPE_BUS			equ 0x1
ERR_EXCEPTIONTYPE_INSTRUCTION	equ 0x2
ERR_EXCEPTIONTYPE_DIVZERO		equ 0x3
ERR_EXCEPTIONTYPE_CHK			equ 0x4
ERR_EXCEPTIONTYPE_TRAPV			equ 0x5
ERR_EXCEPTIONTYPE_PRIVILEGE		equ 0x6
ERR_EXCEPTIONTYPE_UNHANDLEDINT	equ 0x7
ERR_EXCEPTIONTYPE_UNHANDLEDTRAP	equ 0x8
ERR_EXCEPTIONTYPE_UNKNOWN		equ 0x9
ERR_EXCEPTIONTYPE_ASSERT		equ 0xA

	; 4 byte strings
ERR_Exception_RegNames:
	dc.b "D0 ",0
	dc.b "D1 ",0
	dc.b "D2 ",0
	dc.b "D3 ",0
	dc.b "D4 ",0
	dc.b "D5 ",0
	dc.b "D6 ",0
	dc.b "D7 ",0
	dc.b "A0 ",0
	dc.b "A1 ",0
	dc.b "A2 ",0
	dc.b "A3 ",0
	dc.b "A4 ",0
	dc.b "A5 ",0
	dc.b "A6 ",0
	dc.b "SP ",0
	dc.b "SR ",0
	dc.b "PC ",0
	even

ERR_Exception_Header:
	dc.b "LUMINARY Engine",0
	even

ERR_Exception_Footer_1:
	dc.b "Please reset your Mega Drive console",0
	even

ERR_Exception_Footer_2:
	dc.b "Really sorry about this ",ERR_EXCEPTION_HEART_SYMBOL,0
	even
	
	; 32 byte strings
ERR_Exception_Msgs:
	dc.b "Address Error       ",0,0,0,0
	dc.b "Bus Error           ",0,0,0,0
	dc.b "Illegal Instruction ",0,0,0,0
	dc.b "Divide by Zero      ",0,0,0,0
	dc.b "CHK Exception       ",0,0,0,0
	dc.b "TRAPV Exception     ",0,0,0,0
	dc.b "Privilege Exception ",0,0,0,0
	dc.b "Unhandled Interrupt ",0,0,0,0
	dc.b "Unhandled Trap      ",0,0,0,0
	dc.b "Unhandled Exception ",0,0,0,0
	dc.b "Assertion Failed    ",0,0,0,0
	even

ERR_Exception_Str_Stack:
	dc.b "Stack",0
	even

ERR_Heart:
    dc.l 0x04404440
    dc.l 0x46343354
    dc.l 0x46333354
    dc.l 0x43333354
	dc.l 0x04333540
    dc.l 0x00455400
    dc.l 0x00044000
    dc.l 0x00000000

ERR_HandleException:

	;==============================================================
	
	; Re-initialise VDP, load font
	bsr     ERR_ResetForError

	; Load heart symbol
    lea    ERR_Heart, a0
    move.w #SIZEOF_debug_font/SIZE_TILE_B, d0
	move.w #0x1, d1
    bsr    VDP_LoadTiles

	;==============================================================

	; Draw error header
	lea    ERR_Exception_Header, a0
	move.w #ERR_EXCEPTION_HEADERPOSX, d0
	move.w #ERR_EXCEPTION_HEADERPOSY, d1
	move.b #ERR_TEXT_PAL_TITLE, d2
	bsr    DBG_DrawStringA_Pal

	; Pop error type
	moveq  #0x0, d0
	move.w (sp)+, d0
	
	; Get exception type message
	move.l d0, d1
	mulu   #ERR_EXCEPTION_ERROR_STRLEN, d1 
	lea    ERR_Exception_Msgs, a0
	adda.l d1, a0

	; Draw exception type
	move.w d0, -(sp)
	move.w #ERR_EXCEPTION_MSGPOSX, d0
	move.w #ERR_EXCEPTION_MSGPOSY, d1
	move.b #ERR_TEXT_PAL_LABEL, d2
	bsr    DBG_DrawStringA_Pal
	move.w (sp)+, d0

	cmp.w  #ERR_EXCEPTIONTYPE_ASSERT, d0
	bne    @NotUserError

	; Draw user message
	move.l (sp)+, a0
	move.w #ERR_EXCEPTION_USERPOSX, d0
	move.w #ERR_EXCEPTION_USERPOSY, d1
	move.b #ERR_TEXT_PAL_LABEL, d2
	bsr    DBG_DrawStringA_Pal

	@NotUserError:

	;==============================================================
	
	; Draw D regs
	move.w  #ERR_EXCEPTION_REGDPOSY, d6
	lea     ERR_Exception_RegNames, a5
	moveq   #0x0, d7
	@DRegLoop:
	
	; Draw reg name
	move.l  a5, a0
	adda.l  #ERR_EXCEPTION_REG_STRLEN, a5	; Next reg string
	move.w  #ERR_EXCEPTION_REGDPOSX, d0		; X coord
	move.w  d6, d1							; Y coord
	move.b #ERR_TEXT_PAL_LABEL, d2
	bsr    DBG_DrawStringA_Pal

	; Get next reg value
	move.l  (sp)+, d0

	; Alloc string space
	STACK_ALLOC_STRING #0x10, a0
	
	; Reg value to string
	jsr     STR_Concat_ItoA_Hex_l
	
	; Draw reg value
	move.w  #ERR_EXCEPTION_REGDPOSX+ERR_EXCEPTION_REG_STRLEN-1, d0		; X coord
	move.w  d6, d1							; Y coord
	addi.w  #ERR_EXCEPTION_LINESPACE, d6	; Next line
	bsr     DBG_DrawStringA

	; Free string space
	STACK_FREE #0x10
	
	addq.l  #0x1, d7
	cmp.l   #ERR_EXCEPTION_REGCOUNTD, d7
	bne     @DRegLoop

	;==============================================================

	; Draw A regs
	move.w  #ERR_EXCEPTION_REGAPOSY, d6
	moveq   #0x0, d7
	@ARegLoop:
	
	; Draw reg name
	move.l  a5, a0
	adda.l  #ERR_EXCEPTION_REG_STRLEN, a5	; Next reg string
	move.w  #ERR_EXCEPTION_REGAPOSX, d0		; X coord
	move.w  d6, d1							; Y coord
	move.b #ERR_TEXT_PAL_LABEL, d2
	bsr    DBG_DrawStringA_Pal

	; Get next reg value
	move.l  (sp)+, d0

	; Alloc string space
	STACK_ALLOC_STRING #0x10, a0
	
	; Reg value to string
	jsr     STR_Concat_ItoA_Hex_l
	
	; Draw reg value
	move.w  #ERR_EXCEPTION_REGAPOSX+ERR_EXCEPTION_REG_STRLEN-1, d0		; X coord
	move.w  d6, d1							; Y coord
	addi.w  #ERR_EXCEPTION_LINESPACE, d6	; Next line
	bsr     DBG_DrawStringA

	; Free string space
	STACK_FREE #0x10
	
	addq.l  #0x1, d7
	cmp.l   #ERR_EXCEPTION_REGCOUNTA, d7
	bne     @ARegLoop

	;==============================================================

	; Draw S regs
	move.w  #ERR_EXCEPTION_REGSPOSY, d6
	moveq   #0x0, d7
	@SRegLoop:
	
	; Draw reg name
	move.l  a5, a0
	adda.l  #ERR_EXCEPTION_REG_STRLEN, a5	; Next reg string
	move.w  #ERR_EXCEPTION_REGSPOSX, d0		; X coord
	move.w  d6, d1							; Y coord
	move.b #ERR_TEXT_PAL_LABEL, d2
	bsr    DBG_DrawStringA_Pal

	; Get next reg value
	move.l  (sp)+, d0

	; Alloc string space
	STACK_ALLOC_STRING #0x10, a0
	
	; Reg value to string
	jsr     STR_Concat_ItoA_Hex_l
	
	; Draw reg value
	move.w  #ERR_EXCEPTION_REGSPOSX+ERR_EXCEPTION_REG_STRLEN-1, d0		; X coord
	move.w  d6, d1							; Y coord
	addi.w  #ERR_EXCEPTION_LINESPACE, d6	; Next line
	bsr     DBG_DrawStringA

	; Free string space
	STACK_FREE #0x10
	
	addq.l  #0x1, d7
	cmp.l   #ERR_EXCEPTION_REGCOUNTS, d7
	bne     @SRegLoop

	;==============================================================

	; Draw stack label
	lea     ERR_EXCEPTION_STR_STACK, a0
	move.w  #ERR_EXCEPTION_STACKPOSX, d0
	move.w  #ERR_EXCEPTION_STACKPOSY, d1
	move.b #ERR_TEXT_PAL_LABEL, d2
	bsr    DBG_DrawStringA_Pal

	; Unwind stack
	move.w  #ERR_EXCEPTION_STACKPOSY+2, d6
	move.l  #0x0, d7
	@StackLoop:
	
	; Get next stack value
	move.l  (sp)+, d0
	cmp.l   #STACK_TOP, d0
	bne     @NotStackTop
	move.l  #ERR_EXCEPTION_MAXSTACK-1, d7
	@NotStackTop:

	; Alloc string space
	STACK_ALLOC #0x10, a4
	
	; Stack value to string
	move.l  a4, a0
	jsr     STR_ItoA_Hex_l
	
	move.w  #ERR_EXCEPTION_STACKPOSX, d0; X coord
	move.w  d6, d1						; Y coord
	addi.w  #ERR_EXCEPTION_LINESPACE, d6; Next line
	move.l  a4, a0						; String address
	bsr     DBG_DrawStringA
	
	; Free string space
	STACK_FREE #0x10
	
	addq.l  #0x1, d7
	cmp.l   #ERR_EXCEPTION_MAXSTACK, d7
	bne     @StackLoop

	;==============================================================

	; Draw error footer
	lea    ERR_Exception_Footer_1, a0
	move.w #ERR_EXCEPTION_FOOTER1POSX, d0
	move.w #ERR_EXCEPTION_FOOTER1POSY, d1
	bsr    DBG_DrawStringA

	lea    ERR_Exception_Footer_2, a0
	move.w #ERR_EXCEPTION_FOOTER2POSX, d0
	move.w #ERR_EXCEPTION_FOOTER2POSY, d1
	bsr    DBG_DrawStringA

	;==============================================================

	stop    #0x2700 ; Halt CPU (for emulators that suport it)

	@InfiniteLoop:
	bra     @InfiniteLoop
