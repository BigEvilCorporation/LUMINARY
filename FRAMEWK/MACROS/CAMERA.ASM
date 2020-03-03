; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; ENTITY.ASM - Entity and component structure helper macros
; ============================================================================================

CAMERA_GETSCREENBOUNDS: macro left,right,top,bottom
    ; ======================================
    ; Gets the camera bounds
    ; ======================================
    ; left.w   Camera left bounds
    ; right.w  Camera right bounds
    ; top.w    Camera top bounds
    ; bottom.w Camera bottom bounds
    ; ======================================
	move.w RAM_SCROLL_PLANE_A_X, \left
	move.w \left, \right
	addi.w #vdp_sprite_border_x, \left
	addi.w #vdp_sprite_border_x+screen_width, \right
	move.w RAM_SCROLL_PLANE_A_Y, \top
	move.w \top, \bottom
	addi.w #vdp_sprite_border_y, \top
	addi.w #vdp_sprite_border_y+screen_height, \bottom
	endm