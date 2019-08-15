; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 24th July 2019
; ============================================================================================
; VDP.ASM - VDP/VRAM helper macros
; ============================================================================================

; Setup for writing to static VRAM address
VDP_SET_VRAM_WRITE: macro addr
	move.l  #(VDP_CMD_VRAM_WRITE)|((\addr)&$3FFF)<<16|(\addr)>>14, PORT_VDP_CONTROL
	endm

; Setup for reading from static VRAM address
VDP_SET_VRAM_READ: macro addr
	move.l  #(VDP_CMD_VRAM_READ)|((\addr)&$3FFF)<<16|(\addr)>>14, PORT_VDP_CONTROL
	endm
	
; Setup for writing to static CRAM address
VDP_SET_CRAM_WRITE: macro addr
	move.l  #(VDP_CMD_CRAM_WRITE)|((\addr)&$3FFF)<<16|(\addr)>>14, PORT_VDP_CONTROL
	endm

; Setup for writing to static VSRAM address
VDP_SET_VSRAM_WRITE: macro addr
	move.l  #(VDP_CMD_VSRAM_WRITE)|((\addr)&$3FFF)<<16|(\addr)>>14, PORT_VDP_CONTROL
	endm

; Set VDP data address for reading/writing
VDP_SETADDRESS: macro destreg,baseaddr,optype
	; Address bit pattern: --DC BA98 7654 3210 ---- ---- ---- --FE
	andi.l  #0x0000FFFF, \destreg
	add.l   \baseaddr, \destreg		    ; Add VRAM address offset
	rol.l   #0x2,\destreg			    ; Roll bits 14/15 of address to bits 16/17
	lsr.w   #0x2, \destreg			    ; Shift lower word back
	swap    \destreg				    ; Swap address hi/lo
	ori.l   \optype, \destreg		    ; OR in VRAM/CRAM/VSRAM write/read command
	move.l  \destreg, PORT_VDP_CONTROL	; Move dest address to VDP control port
	endm

; Increments a plane A column on an existing VDP command+address longword
; (and wraps around width), and writes new address to VDP control port.
; Assumes plane A at 0xC000.
VDP_VRAM_ADDR_INCREMENT_PLANE_A_X: macro destreg,vdp_ctrl_reg
	addi.l #0x00020000, \destreg
	andi.l #0xFF7FFFFF, \destreg
	move.l \destreg, (\vdp_ctrl_reg)
	endm

; Increments a plane A row on an existing VDP command+address longword
; (and wraps around height), and writes new address to VDP control port.
; Assumes plane A at 0xC000.
VDP_VRAM_ADDR_INCREMENT_PLANE_A_Y: macro destreg,vdp_ctrl_reg
	addi.l #0x00800000, \destreg
	andi.l #0xCFFFFFFF, \destreg
	move.l \destreg, (\vdp_ctrl_reg)
	endm

; Converts cell X/Y coords to VRAM plane byte offset
VRAM_CELL_COORDS_TO_BYTES: macro x,y,output
    move.w \y, \output
    lsl.w  #(VDP_PLANE_WIDTH_SHIFT+1), \output	; Y to row offset in words
    add.w  \x, \output							; +X
	add.w  \x, \output							; ...in words
    endm

; Converts tile count to byte offset
VRAM_TILES_TO_BYTES: macro reg
	lsl.w  #SIZE_TILE_SHIFT_B, \reg
	endm

; Converts tile count to word offset
VRAM_TILES_TO_WORDS: macro reg
	lsl.w  #SIZE_TILE_SHIFT_W, \reg
	endm