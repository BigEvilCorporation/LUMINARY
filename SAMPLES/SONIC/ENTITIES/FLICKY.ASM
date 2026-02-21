; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 30th November 2019
; ============================================================================================
; FLICKY.ASM - Sonic 1 animal
; ============================================================================================

; Flicky constants
EFLICKY_WIDTH                           equ 0x10
EFLICKY_HEIGHT                          equ 0x10
EFLICKY_VEL_X                           equ 0x00020000
EFLICKY_JUMP_VEL                        equ 0x00040000

; Flicky spawn data
    ENTITY_SPAWN_DATA_BEGIN EFlicky
    ENTITY_SPAWN_DATA_END

; Flicky entity
    ENTITY_BEGIN EFlicky
    ENT_COMPONENT ECPhysBodyBasic
    ENT_COMPONENT ECSprite
    ENTITY_END

; Flicky default spawn data
EFlicky_Default_SpawnData:
	; ECSprite
	dc.l actor_flicky_spritesheet_idle	; SDSprite_Sheet
	dc.l 0x0	                        ; SDSprite_Animation
	even

EFlicky_Initialise:
    ; ======================================
    ; EFlicky constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Set palette
    ; TODO: Better palette management
    ENT_GETCOMPONENT EFlicky,ECSprite,a0,a1
    move.w #0x3, d0
    SPRITE_COMPONENT_SETPALETTE_REG a1,d0

    ; Start in jump state
    ENT_GETCOMPONENT EFlicky,ECPhysBodyBasic,a0,a1
    move.l #EFLICKY_JUMP_VEL, ECPhysBodyBasic_VelY(a1)
    move.w #0x0, ECPhysBodyBasic_DecelX(a1)

    rts

EFlicky_Shutdown:
    rts

EFlicky_Update:
    ; ======================================
    ; EFlicky movement path update
    ; ======================================
	; a0   Entity
    ; ======================================

    ; If off screen, despawn
    ENT_GETCOMPONENT EFlicky,ECSprite,a0,a1
    btst   #ECSPRITE_STATE_FLAG_ONSCREEN, ECSprite_StateFlags(a1)
    bne    @OnScreen

    bsr    ENT_DespawnEntity

    rts
    
    @OnScreen:

    ; If hit floor
    ENT_GETCOMPONENT EFlicky,ECPhysBodyBasic,a0,a1
    btst   #COLLISION_FLAG_BIT_TERRAIN_B, ECPhysBodyBasic_LastTerrainFlags(a1)
    beq    @InAir

    ; Jump
    move.l #-EFLICKY_JUMP_VEL, ECPhysBodyBasic_VelY(a1)

    ; Move
    move.l #-EFLICKY_VEL_X, ECPhysBodyBasic_VelX(a1)

    ; Set flying anim
    PUSH.L a0
    move.b #0x1, d0
    ENT_GETCOMPONENT EFlicky,ECSprite,a0,a0
    SPRITE_COMPONENT_SETFLIPX_REG a0,d0
    move.l #actor_flicky_spritesheet_fly, a1
    move.l #actor_flicky_sheet_fly_anim_fly, a2
    bsr    ECSprite_LoadAnimation
    POP.L  a0

    @InAir:

    rts
