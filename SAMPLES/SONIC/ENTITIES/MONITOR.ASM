; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 23rd February 2026
; ============================================================================================
; MONITOR.ASM - Sonic 1 breakable monitor object
; ============================================================================================

MONITOR_SCREEN_Y_OFFS   equ -0x2

; Monitor spawn data
    ENTITY_SPAWN_DATA_BEGIN SDMonitor
    ENTITY_SPAWN_DATA_END

; Monitor entity
    ENTITY_BEGIN EMonitor
    ENT_COMPONENT_NAMED ECSprite,Base
    ENT_COMPONENT_NAMED ECSprite,Image
    ENT_COMPONENT ECEnemy
    ENTITY_END

EMonitor_Initialise:
    ; ======================================
    ; EMonitor constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Set image Y offset
    ENT_GETCOMPONENT EMonitor,Image,a0,a2
    move.b #MONITOR_SCREEN_Y_OFFS, ECSprite_PosY(a2)

    ; Set palette
    ; TODO: Better palette management
    move.w #0x2, d0
    ENT_GETCOMPONENT EMonitor,Base,a0,a2
    SPRITE_COMPONENT_SETPALETTE_REG a2,d0
    move.w #0x2, d0
    ENT_GETCOMPONENT EMonitor,Image,a0,a2
    SPRITE_COMPONENT_SETPALETTE_REG a2,d0

    ; Init enemy component
    ENT_GETCOMPONENT EMonitor,ECEnemy,a0,a1
    move.w #EMonitor_OnHit, ECEnemy_CallbackOnHit(a1)

    rts

EMonitor_Shutdown:
    rts

EMonitor_Update:
    ; ======================================
    ; EMonitor movement path update
    ; ======================================
	; a0   Entity
    ; ======================================

    rts

EMonitor_OnHit:
    ; ======================================
    ; EBuzzbomb on player hit callback from
    ; ECEnemy_CheckHit
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
    
    @NotJumping:

    ; If player not spinning, deal damage to player

    POP.L  a1

    rts