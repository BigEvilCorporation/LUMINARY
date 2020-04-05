; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; VECTRTAB.ASM - 68000 vector table
; ============================================================================================
; Must reside at 0x0000 in ROM
; ============================================================================================

	PUSHS
    Section    SECTION_VECTOR_TABLE

	dc.l   STACK_TOP                    ; Initial stack pointer value
	dc.l   Bootstrap                    ; Start of program
	dc.l   INT_Exc_BusError             ; Bus error
	dc.l   INT_Exc_AddrError            ; Address error
	dc.l   INT_Exc_IllegalInstr         ; Illegal instruction
	dc.l   INT_Exc_DivZero              ; Division by zero
	dc.l   INT_Exc_CHK                  ; CHK CPU_Exception
	dc.l   INT_Exc_TRAPV                ; TRAPV CPU_Exception
	dc.l   INT_Exc_Privilege            ; Privilege violation
	dc.l   INT_Null                     ; TRACE exception
	dc.l   INT_Exc_UnhandledInt         ; Line-A emulator
	dc.l   INT_Exc_UnhandledInt         ; Line-F emulator
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Spurious exception
	dc.l   INT_Null                     ; IRQ level 1
	dc.l   INT_Null                     ; IRQ level 2
	dc.l   INT_Null                     ; IRQ level 3
	dc.l   INT_HBlank                   ; IRQ level 4 (horizontal retrace interrupt)
	dc.l   INT_Null                     ; IRQ level 5
	dc.l   INT_VBlank                   ; IRQ level 6 (vertical retrace interrupt)
	dc.l   INT_Null                     ; IRQ level 7
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #00 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #01 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #02 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #03 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #04 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #05 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #06 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #07 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #08 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #09 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #10 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #11 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #12 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #13 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #14 exception
	dc.l   INT_Exc_UnhandledTrap        ; TRAP #15 exception
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)
	dc.l   INT_Exc_UnhandledInt         ; Unused (reserved)

	POPS