; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; VDP.ASM - VDP control
; ============================================================================================

VDP_Initialise:
    ; ======================================
    ; Initialises the VDP - writes TMSS,
    ; loads default registers, and clears
    ; VRAM/CRAM/VSRAM.
    ; ======================================
    ; No params
    ; ======================================

    ; Write the TMSS
    bsr    VDP_WriteTMSS

    ; Load default VDP regs
    lea    default_vdp_regs, a0
    bsr    VDP_LoadRegisters

    ; Clear VRAM
    bsr    VRAM_Clear
    bsr    VSRAM_Clear

    ; TODO: CRAM/VSRAM

    rts

VDP_WriteTMSS:
    ; ======================================
    ; Initialises TMSS
    ; ======================================
    ; No params
    ; ======================================

    ; Check version, TMSS only on model 1+
    move.b PORT_HARDWARE_VER, d0
	andi.b #0x0F, d0
	beq @Skip
	move.l #TMSS_SIGNATURE, PORT_VDP_TMSS
	@Skip:

	; Check VDP - hangs if no access
	move.w PORT_VDP_CONTROL, d0

    rts

VDP_LoadRegisters:
    ; ======================================
    ; Loads VDP registers
    ; ======================================
    ; a0   Regs table
    ; ======================================

	INT_DISABLE

    move.w #VDP_CMD_REG_WRITE, d1
    move.w #VDP_NUM_REGISTERS-1, d0
	@RegLp:
	move.b (a0)+, d1                    ; Get reg byte
	move.w d1, PORT_VDP_CONTROL         ; Write
	addi.w #0x0100, d1                  ; Next reg #
	dbra   d0, @RegLp

	INT_RESTORE

    rts
