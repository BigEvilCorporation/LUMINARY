; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 2nd August 2019
; ============================================================================================
; REGS.ASM - Default VDP registers
; ============================================================================================

VDP_DEFAULT_REG_0     equ 0x14 ; 0: H interrupt on, palettes on
VDP_DEFAULT_REG_1     equ 0x74 ; 1: V interrupt on, display on, DMA on, Genesis mode on
VDP_DEFAULT_REG_2     equ 0x30 ; 2: Pattern table for Scroll Plane A at VRAM 0xC000 (bits 3-5 = bits 13-15)
VDP_DEFAULT_REG_3     equ 0x2C ; 3: Pattern table for Window Plane at VRAM 0xB000 (bits 1-5 = bits 11-15)
VDP_DEFAULT_REG_4     equ 0x07 ; 4: Pattern table for Scroll Plane B at VRAM 0xE000 (bits 0-2 = bits 11-15)
VDP_DEFAULT_REG_5     equ 0x78 ; 5: Sprite table at VRAM 0xF000 (bits 0-6 = bits 9-15)
VDP_DEFAULT_REG_6     equ 0x00 ; 6: Unused
VDP_DEFAULT_REG_7     equ 0x00 ; 7: Background colour - bits 0-3 = colour, bits 4-5 = palette
VDP_DEFAULT_REG_8     equ 0x00 ; 8: Unused
VDP_DEFAULT_REG_9     equ 0x00 ; 9: Unused
VDP_DEFAULT_REG_A     equ 0xFF ; 10: Frequency of Horiz. interrupt in Rasters (number of lines travelled by the beam)
VDP_DEFAULT_REG_B     equ 0x00 ; 11: External interrupts off, V scroll fullscreen, H scroll fullscreen
VDP_DEFAULT_REG_C     equ 0x81 ; 12: Shadows and highlights off, interlace off, H40 mode (320 x 224 screen res)
VDP_DEFAULT_REG_D     equ 0x3F ; 13: Horiz. scroll table at VRAM 0xFC00 (bits 0-5)
VDP_DEFAULT_REG_E     equ 0x00 ; 14: Unused
VDP_DEFAULT_REG_F     equ 0x02 ; 15: Autoincrement 2 bytes
VDP_DEFAULT_REG_10    equ 0x01 ; 16: Vert. scroll 32, Horiz. scroll 64
VDP_DEFAULT_REG_11    equ 0x00 ; 17: Window Plane X pos 0 left (pos in bits 0-4, left/right in bit 7)
VDP_DEFAULT_REG_12    equ 0x00 ; 18: Window Plane Y pos 0 up (pos in bits 0-4, up/down in bit 7)
VDP_DEFAULT_REG_13    equ 0xFF ; 19: DMA length lo byte
VDP_DEFAULT_REG_14    equ 0xFF ; 20: DMA length hi byte
VDP_DEFAULT_REG_15    equ 0x00 ; 21: DMA source address lo byte
VDP_DEFAULT_REG_16    equ 0x00 ; 22: DMA source address mid byte
VDP_DEFAULT_REG_17    equ 0x80 ; 23: DMA source address hi byte, memory-to-VRAM mode (bits 6-7)

	dc.b VDP_DEFAULT_REG_0
	dc.b VDP_DEFAULT_REG_1
	dc.b VDP_DEFAULT_REG_2
	dc.b VDP_DEFAULT_REG_3
	dc.b VDP_DEFAULT_REG_4
	dc.b VDP_DEFAULT_REG_5
	dc.b VDP_DEFAULT_REG_6
	dc.b VDP_DEFAULT_REG_7
	dc.b VDP_DEFAULT_REG_8
	dc.b VDP_DEFAULT_REG_9
	dc.b VDP_DEFAULT_REG_A
	dc.b VDP_DEFAULT_REG_B
	dc.b VDP_DEFAULT_REG_C
	dc.b VDP_DEFAULT_REG_D
	dc.b VDP_DEFAULT_REG_E
	dc.b VDP_DEFAULT_REG_F
	dc.b VDP_DEFAULT_REG_10
	dc.b VDP_DEFAULT_REG_11
	dc.b VDP_DEFAULT_REG_12
	dc.b VDP_DEFAULT_REG_13
	dc.b VDP_DEFAULT_REG_14
	dc.b VDP_DEFAULT_REG_15
	dc.b VDP_DEFAULT_REG_16
	dc.b VDP_DEFAULT_REG_17