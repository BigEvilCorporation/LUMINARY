; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; PHYSBODY.ASM - Physics body sprite component
; ============================================================================================

    COMPONENT_SPAWN_DATA_BEGIN ECPhysicsBody
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECPhysicsBody
ECPhysicsBody_VelX                      rs.l 1
ECPhysicsBody_VelY                      rs.l 1
ECPhysicsBody_AccelX                    rs.w 1
ECPhysicsBody_AccelY                    rs.w 1
    ENTITY_COMPONENT_END

ECPhysicsBody_Initialise:
    ; ======================================
    ; ECPhysicsBody constructor
    ; ======================================
	; a0   Component
    ; a1   Component spawn data
    ; ======================================

    move.l #0x0, ECPhysicsBody_VelX(a0)
    move.l #0x0, ECPhysicsBody_VelY(a0)
    move.w #0x0, ECPhysicsBody_AccelX(a0)
    move.w #0x0, ECPhysicsBody_AccelY(a0)

    rts

ECPhysicsBody_Shutdown:
    ; ======================================
    ; ECPhysicsBody destructor
    ; ======================================
	; a0   Component
    ; ======================================

    rts

ECPhysicsBody_Step:
    ; ======================================
    ; Steps all physics bodies and handles
    ; collisions
    ; ======================================
	; No params
    ; ======================================

    ENT_COMPONENT_GET_LIST_HEAD ECPhysicsBody, a3
    cmp.w  #0x0, a3
    beq    @NoBodies

    moveq  #0x0, d4                     ; Clear for accel
    moveq  #0x0, d5

    @BodyLp:
    movea.w Component_Owner(a3), a4     ; Get owning entity

    ; ======================================
    ; Get input
    ; ======================================
    move.l Entity_PosX(a4), d0          ; Get pos
    move.l Entity_PosY(a4), d1

    move.l ECPhysicsBody_VelX(a3), d2   ; Get vel
    move.l ECPhysicsBody_VelY(a3), d3

    move.w ECPhysicsBody_AccelX(a3), d4 ; Get accel
    move.w ECPhysicsBody_AccelY(a3), d5
    ext.l  d4
    ext.l  d5

    ; ======================================
    ; Step
    ; ======================================
    add.l  d4, d2                       ; Apply accel to vel
    add.l  d5, d3

    add.l  d2, d0                       ; Apply vel to pos
    add.l  d3, d1

    ; ======================================
    ; Store output
    ; ======================================

    move.l d0, Entity_PosX(a4)          ; Store pos
    move.l d1, Entity_PosY(a4)

    move.l d2, ECPhysicsBody_VelX(a3)   ; Store vel
    move.l d3, ECPhysicsBody_VelY(a3)

    ; ======================================

    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @BodyLp

    @NoBodies:

    rts