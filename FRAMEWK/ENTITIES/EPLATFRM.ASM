; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 8th December 2019
; ============================================================================================
; EPLATFRM.ASM - Physics platform entity component
; ============================================================================================

    COMPONENT_SPAWN_DATA_BEGIN ECPlatform
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECPlatform
ECPlatform_OnTouched                    rs.w 1
ECPlatform_OffsetY                      rs.w 1
ECPlatform_VelX                         rs.l 1
ECPlatform_VelY                         rs.l 1
    ENTITY_COMPONENT_END

ECPlatform_Initialise:
    ; ======================================
    ; ECPlatform constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Initialise
    move.w #0x0, ECPlatform_OnTouched(a0)
    move.w #0x0, ECPlatform_OffsetY(a0)
    move.l #0x0, ECPlatform_VelX(a0)
    move.l #0x0, ECPlatform_VelY(a0)

    rts

PHYS_EntityFindPlatform:
    ; ======================================
    ; Searches for platforms downwards,
    ; returns platform height and velocity.
    ; Fires ECPlatform_OnTouched if
    ; entity is making contact.
    ; ======================================
    ; In:
    ;  a0   Entity
    ; Out:
    ;  a3   Found ECPlatform component
    ;  d0.w Platform height (or -1)
    ; ======================================

    ; Probe position
    move.w Entity_PosX(a0), d3          ; Get entity position
    move.w Entity_PosY(a0), d4
    subi.w #PHYS_STEP_HEIGHT, d4        ; - step height
    add.w  Entity_ExtentsY(a0), d4      ; Centre to Y probe offset

    ; Search all platforms
    move.w #-1, d0

    ; TODO: Only platforms in active world grid
    ENT_COMPONENT_GET_LIST_HEAD ECPlatform, a3
    cmp.w  #0x0, a3
    beq    @NoPlatforms

    @PlatformLp:
    movea.w Component_Owner(a3), a4     ; Get owning entity
    move.w Entity_PosX(a4), d1          ; Check probe X > platform X
    move.w d1, d5
    sub.w  Entity_ExtentsX(a4), d1
    cmp.w  d3, d1
    bgt    @NextPlatform
    add.w  Entity_ExtentsX(a4), d5      ; Check probe X < platform X+width
    cmp.w  d3, d5
    blt    @NextPlatform

    move.w Entity_PosY(a4), d0          ; Check platform Y > probe Y
    sub.w  Entity_ExtentsY(a4), d0      ; Platform top
    add.w  ECPlatform_OffsetY(a3), d0   ; + offset
    cmp.w  d4, d0
    blt    @NextPlatform
    addi.w #COLLISION_MAX_TERRAIN_SEARCH_TILES*8, d4 ; Check platform Y < probe Y + search height
    cmp.w  d4, d0
    ble    @Found

    @NextPlatform:
    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @PlatformLp

    @NoPlatforms:

    ; Not found
    move.l #0x0, a3
    move.w #-1, d0

    rts

    @Found:
    sub.w  Entity_ExtentsY(a0), d0      ; Probe offset back to centre

    movea.w ECPlatform_OnTouched(a3), a1; Fire callback
    cmpa.w #0x0, a1
    beq    @EndPlatforms
    jsr    (a1)

    @EndPlatforms:

    rts
