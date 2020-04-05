; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; INTERPTS.ASM - Interrupt handling and overriding
; ============================================================================================

; ======================================
; INT_Null - empty interrupt
; ======================================
INT_Null:
    rte

; ======================================
; Error exceptions
; ======================================
INT_Exc_BusError:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_BUS
    rte

INT_Exc_AddrError:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_ADDRESS
    rte

INT_Exc_IllegalInstr:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_INSTRUCTION
    rte

INT_Exc_DivZero:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_DIVZERO
    rte

INT_Exc_CHK:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_CHK
    rte

INT_Exc_TRAPV:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_TRAPV
    rte

INT_Exc_Privilege:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_PRIVILEGE
    rte

INT_Exc_UnhandledInt:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_UNHANDLEDINT
    rte

INT_Exc_UnhandledTrap:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_UNHANDLEDTRAP
    rte

INT_Exc_UnhandledExc:
    ERR_EXCEPTION ERR_EXCEPTIONTYPE_UNKNOWN
    rte

; ======================================
; INT_VBlank - Vertical blank
; ======================================
INT_VBlank:
    addq.l #0x1, RAM_VBLANK_COUNTER
    rte

; ======================================
; INT_HBlank - Horizontal blank
; ======================================
INT_HBlank:
    rte