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
ECEnemy_CallbackOnHit                   rs.w 1
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

ECEnemy_OnHit:
    ; ======================================
    ; On player hit callback
    ; ======================================
    ; In:
	;   a0    Entity
    ;   a1    ECEnemy component
    ;   a2    Player
    ;   d1.ww Player top left bounds
    ;   d2.ww Player bottom right bounds
    ;   d3.ww Player top left bounds
    ;   d4.ww Player bottom right bounds
    ; Out:
    ;   d5.b  Damage taken from player
    ;   d6.b  Damage dealt to player
    ; ======================================

    PUSH.L a1

    ; If player spinning, take damage
    btst   #PLAYER_FLAG_SPINNING, EPlayer_StateFlags(a2)
    bne    @Spinning

    ; If player jumping, take damage and rebound player
    btst   #PLAYER_FLAG_JUMPING, EPlayer_StateFlags(a2)
    beq    @NotJumping
    ENT_GETCOMPONENT EPlayer,ECPhysBodyChar,a2,a1
    move.l ECPhysBodyChar_VelY(a1), d0
    neg.l  d0
    move.l d0, ECPhysBodyChar_VelY(a1)

    @Spinning:

    ; Despawn
    bsr    ENT_DespawnEntity

    ; Spawn explosion
    VFX_SPAWN VFXExplosion2,Entity_PosX(a0),Entity_PosY(a0)

    ; Spawn Flicky
    PUSHM.L a0-a2
    move.w Entity_PosX(a0), d0
    move.w Entity_PosY(a0), d1
    subi.w #EFLICKY_HEIGHT, d1
    move.w #EFLICKY_WIDTH, d2
    move.w #EFLICKY_HEIGHT, d3
    lea    EFlicky_TypeDesc, a0
    lea    EFlicky_Default_SpawnData, a1
    bsr    ENT_SpawnEntity
    POPM.L a0-a2
    
    @NotJumping:

    ; If player not spinning, deal damage to player

    POP.L  a1

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

    ; Hit detected
    PUSHM.L d1-d4/a0-a4
    bsr     ECEnemy_OnHit
    POPM.L  d1-d4/a0-a4

    @NextEnemy:
    move.l a4, a1                       ; Next component
    cmpa.w #0x0, a1
    bne    @EnemyLp

    @NoEnemies:

    rts