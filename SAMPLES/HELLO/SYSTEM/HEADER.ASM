; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; HEADER.ASM - SEGA Mega Drive header
; ============================================================================================

    PUSHS
    Section    SECTION_HEADER

	dc.b "SEGA MEGA DRIVE "                                                                 ; 16 bytes - Console name
	dc.b "(C)EVIL 2018.MAY"                                                                 ; 16 bytes - Copyright holder and release date
	dc.b "HELLO WORLD - LUMINARY ENGINE                   "                                 ; 48 bytes - Domestic name
	dc.b "HELLO WORLD - LUMINARY ENGINE                   "                                 ; 48 bytes - International name
	dc.b "GM EVIL0000-00"                                                                   ; 14 bytes - Game type and product code
	dc.w 0x0000                                                                             ; 02 bytes - Checksum
	dc.b "J               "                                                                 ; 16 bytes - I/O support
	dc.l 0x00000000                                                                         ; 04 bytes - Start address of ROM
	dc.l 0x00000000                                                                         ; 04 bytes - End address of ROM
	dc.l 0x00000000                                                                         ; 04 bytes - Start address of RAM
	dc.l 0x00000000                                                                         ; 04 bytes - End address of RAM
	dc.b "    "                                                                             ; 04 bytes - SRAM enabled
	dc.b "    "                                                                             ; 04 bytes - Start address of SRAM
	dc.b "    "                                                                             ; 04 bytes - End address of SRAM
	dc.b "            "                                                                     ; 12 bytes - Modem
	dc.b "                                        "                                         ; 40 bytes - Notes
	dc.b "JUE             "                                                                 ; 16 bytes - Country codes
	                                                                                        ; ------------------------
	                                                                                        ; 256 bytes total

	POPS
