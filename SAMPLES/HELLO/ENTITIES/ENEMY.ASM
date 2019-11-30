; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 27th November 2019
; ============================================================================================
; ENEMY.ASM - Enemy entity component
; ============================================================================================

    COMPONENT_SPAWN_DATA_BEGIN ECEnemy
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECEnemy
ECEnemy_CallbackOnHit                   rs.l 1
    ENTITY_COMPONENT_END

ECEnemy_Initialise:
    ; ======================================
    ; ECEnemy constructor
    ; ======================================
	; a0   Component
    ; a1   Component spawn data
    ; ======================================

    rts

ECEnemy_Shutdown:
    ; ======================================
    ; ECEnemy destructor
    ; ======================================
	; a0   Component
    ; ======================================

    rts

ECEnemy_CheckHitAll:
    ; ======================================
    ; Check all ECEnemies for hit against
    ; player
    ; ======================================
    ; In:
    ;   a2    Player
    ;   d1.ww Player top left bounds
    ;   d2.ww Player bottom right bounds
    ; Out:
    ;   d5.b  Damage taken from player
    ;   d6.b  Damage dealt to player
    ; ======================================

    ENT_COMPONENT_GET_LIST_HEAD ECEnemy, a1
    cmp.w  #0x0, a1
    beq    @NoEnemies
    @EnemyLp:

    ; Get next, for list safety
    movea.w EntityBlock_Next(a1), a4

    ; Get entity
    movea.w Component_Owner(a1), a0

    ; Check bounds
    ENT_GETBOUNDS a0,d3,d4
    bsr    GEOM_BoxIntersectBox
    tst.b  d0
    beq    @NextEnemy

    ; Hit detected, run callback
    move.l ECEnemy_CallbackOnHit(a1), a3
    PUSHM.L d1-d4/a0-a4
    jsr    (a3)
    POPM.L  d1-d4/a0-a4

    @NextEnemy:
    move.l a4, a1                       ; Next component
    cmpa.w #0x0, a1
    bne    @EnemyLp

    @NoEnemies:

    rts