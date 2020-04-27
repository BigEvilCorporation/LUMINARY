; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 16th April 2020
; ============================================================================================
; Z80.ASM - Z80 control routines
; ============================================================================================

Z80_Initialise:

	bsr    Z80_RequestReset
	
	; Clear Z80 RAM
	move.l #Z80_RAM_START, a1
	move.l #Z80_RAM_SIZE_B-1, d0
	@CopyZ80:
	move.b #0x0, (a1)+
	dbra d0, @CopyZ80

	bsr    Z80_ReleaseReset
	
	rts

Z80_RequestBus:

	move.w #0x0100, PORT_Z80_BUS_REQUEST

	@WaitZ80Bus:
	btst #0x0, PORT_Z80_BUS_REQUEST
	bne @WaitZ80Bus

	rts

Z80_ReleaseBus:
	move.w #0x0000, PORT_Z80_BUS_REQUEST
	rts

Z80_RequestReset:

	; Hold reset
	move.w #0x0100, PORT_Z80_BUS_REQUEST
	move.w #0x0100, PORT_Z80_BUS_RESET

	; Wait for Z80 bus
	@Wait:
	btst #0x0, PORT_Z80_BUS_REQUEST
	bne @Wait

	rts

Z80_ReleaseReset:

	; Release
	move.w #0x0000, PORT_Z80_BUS_RESET
	move.w #0x0000, PORT_Z80_BUS_REQUEST

	rts