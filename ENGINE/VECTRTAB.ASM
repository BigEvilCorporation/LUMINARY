; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; VECTRTAB.ASM - 68000 vector table
; ============================================================================================
; Must reside at 0x0000 in ROM
; ============================================================================================

	dc.l   STACK_TOP                    ; Initial stack pointer value
	dc.l   Bootstrap                    ; Start of program
	dc.l   INT_Exception                ; Bus error
	dc.l   INT_Exception                ; Address error
	dc.l   INT_Exception                ; Illegal instruction
	dc.l   INT_Exception                ; Division by zero
	dc.l   INT_Exception                ; CHK CPU_Exception
	dc.l   INT_Exception                ; TRAPV CPU_Exception
	dc.l   INT_Exception                ; Privilege violation
	dc.l   INT_Null                     ; TRACE exception
	dc.l   INT_Null                     ; Line-A emulator
	dc.l   INT_Null                     ; Line-F emulator
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Spurious exception
	dc.l   INT_Null                     ; IRQ level 1
	dc.l   INT_Null                     ; IRQ level 2
	dc.l   INT_Null                     ; IRQ level 3
	dc.l   INT_HBlank                   ; IRQ level 4 (horizontal retrace interrupt)
	dc.l   INT_Null                     ; IRQ level 5
	dc.l   INT_VBlank                   ; IRQ level 6 (vertical retrace interrupt)
	dc.l   INT_Null                     ; IRQ level 7
	dc.l   INT_Null                     ; TRAP #00 exception
	dc.l   INT_Null                     ; TRAP #01 exception
	dc.l   INT_Null                     ; TRAP #02 exception
	dc.l   INT_Null                     ; TRAP #03 exception
	dc.l   INT_Null                     ; TRAP #04 exception
	dc.l   INT_Null                     ; TRAP #05 exception
	dc.l   INT_Null                     ; TRAP #06 exception
	dc.l   INT_Null                     ; TRAP #07 exception
	dc.l   INT_Null                     ; TRAP #08 exception
	dc.l   INT_Null                     ; TRAP #09 exception
	dc.l   INT_Null                     ; TRAP #10 exception
	dc.l   INT_Null                     ; TRAP #11 exception
	dc.l   INT_Null                     ; TRAP #12 exception
	dc.l   INT_Null                     ; TRAP #13 exception
	dc.l   INT_Null                     ; TRAP #14 exception
	dc.l   INT_Null                     ; TRAP #15 exception
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Exception                ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)
	dc.l   INT_Null                     ; Unused (reserved)