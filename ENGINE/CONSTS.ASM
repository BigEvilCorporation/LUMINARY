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
SIZE_TILE_SHIFT_B                       equ 0x05
SIZE_TILE_SHIFT_W                       equ 0x04

; VDP palettes
SIZE_PALETTE_B                          equ 0x20
SIZE_PALETTE_SHIFT                      equ 0x05

; Strings
STR_ASCII_START			                equ 0x20
STR_ASCII_NUMERIC_OFFSET                equ 0x30
STR_ASCII_ALPHA_OFFSET                  equ 0x41

; Stack
STACK_TOP                               equ 0x00FFE000
STACK_SIZE                              equ BLDCONF_STACK_SIZE

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

; Screen
VDP_SCREEN_WIDTH_PX                     equ 0x0140 ; 320 (H40 mode)
VDP_SCREEN_HEIGHT_PX                    equ 0x00E0 ; 224 (V28 mode)
VDP_SPRITE_BORDER_X		                equ 0x0080
VDP_SPRITE_BORDER_Y		                equ 0x0080

; Map streaming
MAP_STREAM_STAMP_WIDTH                  equ BLDCONF_MAP_STREAM_STAMP_WIDTH
MAP_STREAM_STAMP_HEIGHT                 equ BLDCONF_MAP_STREAM_STAMP_HEIGHT
MAP_STREAM_STAMP_WIDTH_SHIFT            equ BLDCONF_MAP_STREAM_STAMP_WIDTH_SHIFT
MAP_STREAM_STAMP_HEIGHT_SHIFT           equ BLDCONF_MAP_STREAM_STAMP_HEIGHT_SHIFT
MAP_STREAM_BUFFER_OFFSET_X              equ (VDP_PLANE_WIDTH/4)  ; Offset streaming window to centre of plane
MAP_STREAM_BUFFER_OFFSET_Y              equ 1                    ; Only 2 cell buffer on Y axis

; Sprites
VDP_MAX_SPRITES                         equ 0x40
VDP_SPRITE_FLAG_FLIPX                   equ 11
VDP_SPRITE_FLAG_FLIPY                   equ 12
VDP_SPRITE_FLAG_PRIO                    equ 15
VDP_SPRITE_FLAG_MASK_FLIPX              equ 0x0800
VDP_SPRITE_FLAG_MASK_FLIPY              equ 0x1000
VDP_SPRITE_FLAG_MASK_PRIO               equ 0x8000
VDP_SPRITE_FLAG_MASK_PAL                equ 0x6000
VDP_SPRITE_FLAG_NMASK_FLIPX             equ 0xF7FF
VDP_SPRITE_FLAG_NMASK_FLIPY             equ 0xEFFF
VDP_SPRITE_FLAG_NMASK_PRIO              equ 0x7FFF
VDP_SPRITE_FLAG_NMASK_PAL               equ 0x9FFF
VDP_SPRITE_FLAG_SHIFT_FLIPX             equ 0x0B
VDP_SPRITE_FLAG_SHIFT_FLIPY             equ 0x0C
VDP_SPRITE_FLAG_SHIFT_PRIO              equ 0x0F
VDP_SPRITE_FLAG_SHIFT_PAL               equ 0x0D
VDP_SPRITE_FLAG_ROR_FLIPX               equ 0x05
VDP_SPRITE_FLAG_ROR_FLIPY               equ 0x04
VDP_SPRITE_FLAG_ROR_PRIO                equ 0x01
VDP_SPRITE_FLAG_ROR_PAL                 equ 0x03

; Sprite layout configurations
VDP_SPRITE_LAYOUT_1x1                   equ %0000
VDP_SPRITE_LAYOUT_1x2                   equ %0001
VDP_SPRITE_LAYOUT_1x3                   equ %0010
VDP_SPRITE_LAYOUT_1x4                   equ %0011
VDP_SPRITE_LAYOUT_2x1                   equ %0100
VDP_SPRITE_LAYOUT_2x2                   equ %0101
VDP_SPRITE_LAYOUT_2x3                   equ %0110
VDP_SPRITE_LAYOUT_2x4                   equ %0111
VDP_SPRITE_LAYOUT_3x1                   equ %1000
VDP_SPRITE_LAYOUT_3x2                   equ %1001
VDP_SPRITE_LAYOUT_3x3                   equ %1010
VDP_SPRITE_LAYOUT_3x4                   equ %1011
VDP_SPRITE_LAYOUT_4x1                   equ %1100
VDP_SPRITE_LAYOUT_4x2                   equ %1101
VDP_SPRITE_LAYOUT_4x3                   equ %1110
VDP_SPRITE_LAYOUT_4x4                   equ %1111

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

; VDP status register bits
VDP_STATUS_FIFOEMPTY                    equ 0x9    ; FIFO Empty
VDP_STATUS_FIFOFULL                     equ 0x8    ; FIFO Full
VDP_STATUS_VINTPENDING                  equ 0x7    ; Vertical interrupt pending
VDP_STATUS_SPRITEOVERFLOW               equ 0x6    ; Sprite overflow on current scan line
VDP_STATUS_SPRITECOLLISION              equ 0x5    ; Sprite collision
VDP_STATUS_ODDFRAME                     equ 0x4    ; Odd frame
VDP_STATUS_VBLANK                       equ 0x3    ; Vertical blanking
VDP_STATUS_HBLANK                       equ 0x2    ; Horizontal blanking
VDP_STATUS_DMA                          equ 0x1    ; DMA in progress
VDP_STATUS_PAL                          equ 0x0    ; PAL mode flag

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

; VDP memory access commands (DMA)
VDP_CMD_DMA_VRAM_WRITE                  equ 0x40000080
VDP_CMD_DMA_CRAM_WRITE                  equ 0xC0000080
VDP_CMD_DMA_VSRAM_WRITE                 equ 0x40000090

; VDP DMA modes
VDP_DMA_MODE_TRANSFER		            equ 0x00
VDP_DMA_MODE_COPY		                equ 0xC0
VDP_DMA_MODE_FILL		                equ 0x80

; VDP DMA top byte address masks
VDP_DMA_ADDR_MASK_WRITE_B               equ 0x7F
VDP_DMA_ADDR_MASK_WRITE_L               equ 0x007FFFFF
VDP_DMA_ADDR_MASK_COPY                  equ 0x3F
VDP_DMA_ADDR_MASK_FILL                  equ 0x3F

; CRAM addresses
CRAM_ADDR_PAL_0			                equ 0x0000
CRAM_ADDR_PAL_1			                equ 0x0020
CRAM_ADDR_PAL_2			                equ 0x0040
CRAM_ADDR_PAL_3			                equ 0x0060

; Gamepad ports
PORT_PAD_DATA_A                         equ 0x00A10003
PORT_PAD_DATA_B                         equ 0x00A10005
PORT_PAD_DATA_C                         equ 0x00A10007
PORT_PAD_CTRL_A                         equ 0x00A10009
PORT_PAD_CTRL_B                         equ 0x00A1000B
PORT_PAD_CTRL_C                         equ 0x00A1000D

PAD_BYTE_LATCH			                equ 0x40

PAD_BUTTON_UP                           equ 0x0
PAD_BUTTON_DOWN                         equ 0x1
PAD_BUTTON_LEFT                         equ 0x2
PAD_BUTTON_RIGHT                        equ 0x3
PAD_BUTTON_A                            equ 0xC
PAD_BUTTON_B                            equ 0x4
PAD_BUTTON_C                            equ 0x5
PAD_BUTTON_START                        equ 0xD

PAD_BUTTON_ALL			                equ 0x303F

; Status register
CPU_STATUS_REG_TRACE		            equ (1<<15)
CPU_STATUS_REG_UNUSED1		            equ (1<<14)
CPU_STATUS_REG_SUPERVISOR	            equ (1<<13)
CPU_STATUS_REG_UNUSED2		            equ (1<<12)
CPU_STATUS_REG_UNUSED3		            equ (1<<11)
CPU_STATUS_REG_INT2			            equ (1<<10)
CPU_STATUS_REG_INT1			            equ (1<<9)
CPU_STATUS_REG_INT0			            equ (1<<8)
CPU_STATUS_REG_UNUSED4		            equ (1<<7)
CPU_STATUS_REG_UNUSED5		            equ (1<<6)
CPU_STATUS_REG_UNUSED6		            equ (1<<5)
CPU_STATUS_REG_CCR_EXTEND	            equ (1<<4)
CPU_STATUS_REG_CCR_NEGATIVE	            equ (1<<3)
CPU_STATUS_REG_CCR_ZERO		            equ (1<<2)
CPU_STATUS_REG_CCR_OVERFLOW	            equ (1<<1)
CPU_STATUS_REG_CCR_CARRY	            equ (1<<0)

CPU_STATUS_REG_INIT			            equ (CPU_STATUS_REG_SUPERVISOR|CPU_STATUS_REG_INT0|CPU_STATUS_REG_INT1)
CPU_STATUS_REG_INT_DISABLE	            equ (CPU_STATUS_REG_INT0|CPU_STATUS_REG_INT1|CPU_STATUS_REG_INT2)
