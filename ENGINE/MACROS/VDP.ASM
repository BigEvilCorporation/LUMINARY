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

VDP_WRAP_PLANE_X: macro offsetreg
; Wraps a plane X coord around width.
	andi.w #VDP_PLANE_WIDTH-1, \offsetreg
	endm

VDP_WRAP_PLANE_Y: macro offsetreg
; Wraps a plane Y coord around height.
	andi.w #VDP_PLANE_HEIGHT-1, \offsetreg
	endm

; Increments a plane A/B column on an existing VDP command+address longword,
; and writes new address to VDP control port.
; Assumes planes in 64x32 mode
VDP_VRAM_ADDR_INCREMENT_PLANE_X: macro destreg,tmpreg,vdp_ctrl_reg
	move.l \destreg, \tmpreg
	addi.l #0x00020000, \tmpreg			; Advance addr by 1 col (2 bytes)
	andi.l #0x007F0000, \tmpreg			; Wrap around 0x?000 - 0x?07F
	andi.l #0xFF80FFFF, \destreg		; Mask addr from original command
	or.l   \tmpreg, \destreg			; OR in new addr
	move.l \destreg, (\vdp_ctrl_reg)
	endm

; Increments a plane A/B row on an existing VDP command+address longword,
; and writes new address to VDP control port.
; Assumes planes in 64x32 mode
VDP_VRAM_ADDR_INCREMENT_PLANE_Y: macro destreg,tmpreg,vdp_ctrl_reg
	move.l \destreg, \tmpreg
	addi.l #0x00800000, \tmpreg			; Advance addr by 1 row (128 bytes)
	andi.l #0x0FFF0000, \tmpreg			; Wrap around 0x?000 - 0x?FFF
	andi.l #0xF000FFFF, \destreg		; Mask addr from original command
	or.l   \tmpreg, \destreg			; OR in new addr
	move.l \destreg, (\vdp_ctrl_reg)
	endm

; Converts cell X/Y coords to VRAM plane byte offset
VDP_CELL_COORDS_TO_BYTES: macro x,y,output
    move.w \y, \output
    lsl.w  #(VDP_PLANE_WIDTH_SHIFT+1), \output	; Y to row offset in words
    add.w  \x, \output							; +X
	add.w  \x, \output							; ...in words
    endm

; Converts tile count to byte offset
VDP_TILES_TO_BYTES: macro reg
	lsl.w  #SIZE_TILE_SHIFT_B, \reg
	endm

; Converts byte offset to tile index
VDP_BYTES_TO_TILES: macro reg
	lsr.w  #SIZE_TILE_SHIFT_B, \reg
	endm

; Converts tile count to word offset
VDP_TILES_TO_WORDS: macro reg
	lsl.w  #SIZE_TILE_SHIFT_W, \reg
	endm

; Converts pixels to tile count
VDP_PIXELS_TO_TILES: macro reg
	lsr.w  #0x3, \reg
	endm

; Converts tile count to pixels
VDP_TILES_TO_PIXELS: macro reg
	lsl.w  #0x3, \reg
	endm