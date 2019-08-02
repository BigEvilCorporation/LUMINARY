; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; CONSTS.ASM - Global constants for Luminary Engine code
; ============================================================================================

; 68000 ASM
SIZE_WORD                               equ 2
SIZE_LONG                               equ 4

; VDP tiles
SIZE_TILE_B                             equ 0x20
SIZE_TILE_W                             equ SIZE_TILE_B/SIZE_WORD
SIZE_TILE_L                             equ SIZE_TILE_B/SIZE_LONG
SIZE_TILE_SHIFT                         equ 0x05

; VDP palettes
SIZE_PALETTE_B                          equ 0x20
SIZE_PALETTE_SHIFT                      equ 0x05

; Stack
STACK_TOP                               equ 0x00FFE000

; RAM
RAM_SIZE_B				                equ 0x0000FFFF
RAM_SIZE_W				                equ (RAM_SIZE_B/2)
RAM_SIZE_L				                equ (RAM_SIZE_B/4)
RAM_START				                equ 0x00FF0000
RAM_END					                equ (RAM_START+RAM_SIZE_B)

; VRAM
VRAM_SIZE_B				                equ 0x0000FFFF
VRAM_SIZE_W				                equ (VRAM_SIZE_B/2)
VRAM_SIZE_L				                equ (VRAM_SIZE_B/4)
VRAM_START				                equ 0x00000000
VRAM_END					            equ (VRAM_START+VRAM_SIZE_B)

; Planes
VDP_PLANE_WIDTH                         equ 0x40
VDP_PLANE_HEIGHT                        equ 0x20
VDP_PLANE_WIDTH_SHIFT                   equ 0x06

; VRAM addresses
VRAM_ADDR_TILES			                equ 0x0000
VRAM_ADDR_PLANE_A		                equ 0xC000
VRAM_ADDR_PLANE_B		                equ 0xE000
VRAM_ADDR_PLANE_W		                equ 0xB000
VRAM_ADDR_SPRITE_TABLE	                equ 0xF000
VRAM_ADDR_HSCROLL		                equ 0xFC00

; VDP registers
VDP_NUM_REGISTERS                       equ 0x18

; System ports
PORT_HARDWARE_VER	                    equ 0x00A10001

; VDP ports
PORT_VDP_CONTROL                        equ 0x00C00004
PORT_VDP_DATA                           equ 0x00C00000
PORT_VDP_TMSS                           equ 0x00A14000

; TMSS
TMSS_SIGNATURE                          equ 'SEGA'

; VDP memory access commands
VDP_CMD_REG_WRITE		                equ 0x00008000
VDP_CMD_VRAM_WRITE		                equ 0x40000000
VDP_CMD_VRAM_READ		                equ 0x00000000
VDP_CMD_CRAM_WRITE		                equ 0xC0000000
VDP_CMD_CRAM_READ		                equ 0x00000020
VDP_CMD_VSRAM_WRITE		                equ 0x40000010
VDP_CMD_VSRAM_READ		                equ 0x00000010

; Status register
STATUS_REG_TRACE		equ (1<<15)
STATUS_REG_UNUSED1		equ (1<<14)
STATUS_REG_SUPERVISOR	equ (1<<13)
STATUS_REG_UNUSED2		equ (1<<12)
STATUS_REG_UNUSED3		equ (1<<11)
STATUS_REG_INT2			equ (1<<10)
STATUS_REG_INT1			equ (1<<9)
STATUS_REG_INT0			equ (1<<8)
STATUS_REG_UNUSED4		equ (1<<7)
STATUS_REG_UNUSED5		equ (1<<6)
STATUS_REG_UNUSED6		equ (1<<5)
STATUS_REG_CCR_EXTEND	equ (1<<4)
STATUS_REG_CCR_NEGATIVE	equ (1<<3)
STATUS_REG_CCR_ZERO		equ (1<<2)
STATUS_REG_CCR_OVERFLOW	equ (1<<1)
STATUS_REG_CCR_CARRY	equ (1<<0)

STATUS_REG_INIT			equ (STATUS_REG_SUPERVISOR|STATUS_REG_INT0|STATUS_REG_INT1)
STATUS_REG_INT_DISABLE	equ (STATUS_REG_INT0|STATUS_REG_INT1|STATUS_REG_INT2)
