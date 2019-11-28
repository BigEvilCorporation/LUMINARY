; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 13th November 2019
; ============================================================================================
; LRSWITCH.ASM - Layer switcher - switches the terrain layer of objects passing through
; ============================================================================================

LAYER_SWITCH_DIRECTION_HORIZONTAL       equ 0x0
LAYER_SWITCH_DIRECTION_VERTICAL         equ 0x1

    STATIC_ENTITY_BEGIN SELayerSwitch
SELayerSwitch_LayerA                    rs.b 1
SELayerSwitch_LayerB                    rs.b 1
SELayerSwitch_Direction                 rs.b 1
    STATIC_ENTITY_END

SELayerSwitch_Update:
    ; ======================================
    ; SELayerSwitch update
    ; ======================================
	; a0   Entity
    ; ======================================

    ; Get player
    move.l RAM_PLAYER_1, a1
    
    ; Check bounds
    ENT_GETBOUNDS a0,d1,d2
    ENT_GETBOUNDS a1,d3,d4
    bsr    GEOM_BoxIntersectBox
    tst.b  d0
    beq    @NoIntersect

    ; Get player physics component
    ENT_GETCOMPONENT EPlayer,ECPhysBodyChar,a1,a2

    move.b SELayerSwitch_LayerA(a0), d0
    move.b ECPhysBodyChar_TerrainQuadrant(a2), d2

    cmp.b  #LAYER_SWITCH_DIRECTION_VERTICAL, SELayerSwitch_Direction(a0)
    beq    @Vertical

    ; Horizontal, compare X
    move.w Entity_PosX(a0), d1
    cmp.w  Entity_PosX(a1), d1
    ble    @LayerB

    ; Must be heading left
    tst.l  ECPhysBodyChar_VelX(a2)
    bgt    @WrongDirection

    ; Layer A
    move.b SELayerSwitch_LayerA(a0), ECPhysBodyChar_TerrainLayer(a2)
    rts

    @Vertical:
    ; Vertical, compare Y
    ; TODO
    ;move.w Entity_PosY(a0), d1
    ;cmp.w  Entity_PosY(a1), d1
    ;ble    @LayerB
    ;move.b SELayerSwitch_LayerA(a0), ECPhysBodyChar_TerrainLayer(a2)
    rts

    @LayerB:
    ; Must be heading right
    tst.l  ECPhysBodyChar_VelX(a2)
    blt    @WrongDirection

    ; Layer B
    move.b SELayerSwitch_LayerB(a0), ECPhysBodyChar_TerrainLayer(a2)

    @NoIntersect:
    @WrongDirection:

    rts
