; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 22nd August 2019
; ============================================================================================
; CAMERA.ASM - Camera object, clamping, lerping, shaking, applying to scroll
; ============================================================================================

    STRUCT_BEGIN Camera
    ; TODO: list node
Camera_PosX                             rs.l 1  ; X position (16.16)
Camera_PosY                             rs.l 1  ; Y position (16.16)
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

    ; If camera has a target entity, grab its centre position
    move.l Camera_TargetEntity(a0), a1
    cmpa.w #0x0, a1
    beq    @NoTarget
    ; TODO: Get centre pos
    move.l Entity_PosX(a1), d0              ; Get entity pos
    move.l Entity_PosY(a1), d1
    subi.l #VDP_SPRITE_BORDER_X<<16, d0     ; To scroll space
    subi.l #VDP_SPRITE_BORDER_Y<<16, d1
    subi.l #(VDP_SCREEN_WIDTH_PX/2)<<16, d0 ; To screen centre
    subi.l #(VDP_SCREEN_HEIGHT_PX/2)<<16, d1
    move.l d0, Camera_PosX(a0)
    move.l d1, Camera_PosY(a0)
    @NoTarget:

    ; Apply to scroll
    move.w Camera_PosX(a0), d0				; Invert X
    neg.w  d0
    move.w d0, RAM_SCROLL_PLANE_A_X
    move.w Camera_PosY(a0), RAM_SCROLL_PLANE_A_Y

    @NoCamera:

    rts
