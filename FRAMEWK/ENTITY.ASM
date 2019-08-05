; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 4th August 2019
; ============================================================================================
; ENTITY.ASM - Component based entity system
; ============================================================================================

PHYSICS_FLAG_NOCOLLISION                equ 4
SPRITE_FLAG_FLIP_X                      equ 3

    ENTITY_COMPONENT_BEGIN ECPhysicsBody
ECPhysicsBody_VelocityX                rs.l 1
ECPhysicsBody_VelocityY                rs.l 1
ECPhysicsBody_Flags                    rs.b 1
    ENTITY_COMPONENT_END

    ENTITY_COMPONENT_BEGIN ECSprite
ECSprite_Sprite                        rs.b SIZEOF_Sprite
    ENTITY_COMPONENT_END

    ENTITY_BEGIN EPlayer
	ENT_COMPONENT ECPhysicsBody
    ENT_COMPONENT ECSprite
    ENTITY_END

TestSpawn:

    lea    EPlayer_TypeDesc, a0
    bsr    ENT_SpawnEntity

    bsr    ENT_DespawnEntity

    lea    EPlayer_TypeDesc, a0
    bsr    ENT_SpawnEntity

    rts

ECPhysicsBody_Initialise:
    rts

ECSprite_Initialise:
    rts

EPlayer_Spawn:

    rts

EPlayer_Despawn:

    rts
EPlayer_Update:

    ENT_GETCOMPONENT EPlayer, ECPhysicsBody, a0, a1
    move.l #0x00010000, ECPhysicsBody_VelocityX(a1)
    move.l #0x00008000, ECPhysicsBody_VelocityX(a1)
    bset   #PHYSICS_FLAG_NOCOLLISION, ECPhysicsBody_Flags(a1)

    rts
