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
ERR_EXCEPTION_MSGPOSY			equ 0x03
ERR_EXCEPTION_REGPOSX			equ 0x02
ERR_EXCEPTION_REGPOSY			equ 0x05
ERR_EXCEPTION_STACKPOSX			equ 0x014
ERR_EXCEPTION_STACKPOSY			equ 0x05
ERR_EXCEPTION_FOOTER1POSX		equ 0x02
ERR_EXCEPTION_FOOTER1POSY		equ 0x18
ERR_EXCEPTION_FOOTER2POSX		equ 0x02
ERR_EXCEPTION_FOOTER2POSY		equ 0x1A
ERR_EXCEPTION_LINESPACE			equ 0x01
ERR_EXCEPTION_REGCOUNT			equ 0x12	; 18 regs (a0-a6 + d0-d7 + SP + SR + PC)
ERR_EXCEPTION_MAXSTACK			equ 0x10
ERR_EXCEPTION_ERROR_STRLEN		equ 0x18

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

	; 8 byte strings
ERR_Exception_RegNames:
	dc.b "D0: ",0,0,0,0
	dc.b "D1: ",0,0,0,0
	dc.b "D2: ",0,0,0,0
	dc.b "D3: ",0,0,0,0
	dc.b "D4: ",0,0,0,0
	dc.b "D5: ",0,0,0,0
	dc.b "D6: ",0,0,0,0
	dc.b "D7: ",0,0,0,0
	dc.b "A0: ",0,0,0,0
	dc.b "A1: ",0,0,0,0
	dc.b "A2: ",0,0,0,0
	dc.b "A3: ",0,0,0,0
	dc.b "A4: ",0,0,0,0
	dc.b "A5: ",0,0,0,0
	dc.b "A6: ",0,0,0,0
	dc.b "SP: ",0,0,0,0
	dc.b "SR: ",0,0,0,0
	dc.b "PC: ",0,0,0,0
	even

ERR_Exception_Header:
	dc.b "LUMINARY Engine",0
	even

ERR_Exception_Footer_1:
	dc.b "Please reset your Mega Drive console",0
	even

ERR_Exception_Footer_2:
	dc.b "Really sorry about this <3",0
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
	even

ERR_Exception_Str_Stack:
	dc.b "Stack:",0
	even

ERR_HandleException:

	;==============================================================
	
	; Re-initialise VDP, load font
	bsr     ERR_ResetForError

	;==============================================================

	; Draw error header
	lea    ERR_Exception_Header, a0
	adda.l d0, a0
	move.w #ERR_EXCEPTION_HEADERPOSX, d0
	move.w #ERR_EXCEPTION_HEADERPOSY, d1
	bsr    DBG_DrawString

	; Pop error type
	moveq  #0x0, d0
	move.w (sp)+, d0
	mulu   #ERR_EXCEPTION_ERROR_STRLEN, d0 
	
	; Draw error message
	lea    ERR_Exception_Msgs, a0
	adda.l d0, a0
	move.w #ERR_EXCEPTION_MSGPOSX, d0
	move.w #ERR_EXCEPTION_MSGPOSY, d1
	bsr    DBG_DrawString

	;==============================================================
	
	; Draw all regs
	move.w  #ERR_EXCEPTION_REGPOSY, d6
	move.l  #0x0, d7
	@RegLoop:
	
	; Get next reg value
	move.l  (sp)+, d0

	; Alloc string space
	STACK_ALLOC 0x10, a4
	
	; Copy reg name
	move.l  d7, d1
	mulu    #0x8, d1
	move.l  d1, a5
	move.l  ERR_Exception_RegNames(a5), (a4)+	; String first 4 bytes
	
	; Reg value to string
	move.l  a4, a0
	jsr     STR_ItoA_Hex_l
	sub.l   #SIZE_LONG, a4				; String addr back to reg name offset
	
	move.w  #ERR_EXCEPTION_REGPOSX, d0	; X coord
	move.w  d6, d1						; Y coord
	addi.w  #ERR_EXCEPTION_LINESPACE, d6; Next line
	move.l  a4, a0						; String address
	bsr     DBG_DrawString
	
	; Free string space
	STACK_FREE 0x10
	
	addq.l  #0x1, d7
	cmp.l   #ERR_EXCEPTION_REGCOUNT, d7
	bne     @RegLoop

	;==============================================================

	; Draw stack label
	lea     ERR_EXCEPTION_STR_STACK, a0
	move.w  #ERR_EXCEPTION_STACKPOSX, d0
	move.w  #ERR_EXCEPTION_STACKPOSY, d1
	bsr     DBG_DrawString

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
	STACK_ALLOC 0x10, a4
	
	; Stack value to string
	move.l  a4, a0
	jsr     STR_ItoA_Hex_l
	
	move.w  #ERR_EXCEPTION_STACKPOSX, d0; X coord
	move.w  d6, d1						; Y coord
	addi.w  #ERR_EXCEPTION_LINESPACE, d6; Next line
	move.l  a4, a0						; String address
	bsr     DBG_DrawString
	
	; Free string space
	STACK_FREE 0x10
	
	addq.l  #0x1, d7
	cmp.l   #ERR_EXCEPTION_MAXSTACK, d7
	bne     @StackLoop

	;==============================================================

	; Draw error footer
	lea    ERR_Exception_Footer_1, a0
	move.w #ERR_EXCEPTION_FOOTER1POSX, d0
	move.w #ERR_EXCEPTION_FOOTER1POSY, d1
	bsr    DBG_DrawString

	lea    ERR_Exception_Footer_2, a0
	move.w #ERR_EXCEPTION_FOOTER2POSX, d0
	move.w #ERR_EXCEPTION_FOOTER2POSY, d1
	bsr    DBG_DrawString

	;==============================================================

	stop    #0x2700 ; Halt CPU (for emulators that suport it)

	@InfiniteLoop:
	bra     @InfiniteLoop
