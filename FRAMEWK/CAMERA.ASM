; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 22nd August 2019
; ============================================================================================
; CAMERA.ASM - Camera object, clamping, lerping, shaking, applying to scroll
; ============================================================================================

    STRUCT_BEGIN Camera
    ; TODO: list node
Camera_PosX                             rs.l 1  ; X position (16.16) in sprite space
Camera_PosY                             rs.l 1  ; Y position (16.16) in sprite space
Camera_TargetEntity                     rs.l 1  ; Target entity
    STRUCT_END

CAM_Initialise:
    ; ======================================
    ; Initialise camera system with a
    ; default camera.
    ; ======================================
	; No params
    ; ======================================

    lea    RAM_CAMERA_DEFAULT, a0

    move.l #0x0, Camera_PosX(a0)
    move.l #0x0, Camera_PosY(a0)
    move.l #0x0, Camera_TargetEntity(a0)

    move.l a0, RAM_CAMERA_CURRENT

    rts

CAM_UpdateAll:
    ; ======================================
    ; Update all cameras, apply active to scrolling
    ; ======================================
	; No params
    ; ======================================

    ; TODO: Iterate list

    ; Get active camera
    move.l RAM_CAMERA_CURRENT, a0
    cmpa.w #0x0, a0
    beq    @NoCamera

    move.l Camera_PosX(a0), d0
    move.l Camera_PosY(a0), d1

    ; If camera has a target entity, grab its centre position
    move.l Camera_TargetEntity(a0), a1
    cmpa.w #0x0, a1
    beq    @NoTarget
    move.l Entity_PosX(a1), d0
    move.l Entity_PosY(a1), d1
    @NoTarget:

    ; Clamp to bounds
    CLAMP.L d0, #(VDP_SPRITE_BORDER_X+(VDP_SCREEN_WIDTH_PX/2))<<16, #0x7FFFFFFF
    CLAMP.L d1, #(VDP_SPRITE_BORDER_Y+(VDP_SCREEN_HEIGHT_PX/2))<<16, #0x7FFFFFFF

    move.l d0, Camera_PosX(a0)
    move.l d1, Camera_PosY(a0)

    ; Apply to scroll
    swap d0
    swap d1
    subi.w #VDP_SPRITE_BORDER_X+(VDP_SCREEN_WIDTH_PX/2), d0 ; Sprite space to screen centre to scroll space
    subi.w #VDP_SPRITE_BORDER_Y+(VDP_SCREEN_HEIGHT_PX/2), d1
    neg.w  d0                           ; Invert X
    move.w d0, RAM_SCROLL_PLANE_A_X
    move.w d1, RAM_SCROLL_PLANE_A_Y

    @NoCamera:

    rts
