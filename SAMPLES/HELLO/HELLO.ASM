; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; HELLO.ASM - "Hello world" using Luminary Engine
; ============================================================================================

    ; Code includes
    include 'bootstrp.asm'
    include 'samples/hello/system/header.asm'
    include 'luminary.asm'
    include 'samples/hello/system/memmap.asm'
    include 'samples/hello/data/scenes/scene1.asm'
    include 'samples/hello/data/sprites/test.asm'
    include 'samples/hello/data/palettes/test.asm'

DRAW_VRAM: macro
    PUSH.L a0
    bsr    ERR_ResetForError
    bsr    VRAMMGR_DrawTable
    POP.L  a0
    endm

    ENTITY_SPAWN_DATA_BEGIN EPlayer
    ENTITY_SPAWN_DATA_END

    ENTITY_BEGIN EPlayer
EPlayer_SpawnPosX                       rs.w 1
EPlayer_SpawnPosY                       rs.w 1
	ENT_COMPONENT ECPhysicsBody
    ENT_COMPONENT ECSprite
    ENTITY_END

EPlayer_Initialise:
    ; ======================================
    ; EPlayer constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    move.w Entity_PosX(a0), EPlayer_SpawnPosX(a0)
    move.w Entity_PosY(a0), EPlayer_SpawnPosY(a0)

    ; Init player's physics component
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a0
    move.w #0x0001, ECPhysicsBody_AccelX(a0)

    rts

EPlayer_Shutdown:
    rts

EPlayer_Update:

    cmp.w  #VDP_SCREEN_WIDTH_PX+VDP_SPRITE_BORDER_X, Entity_PosX(a0)
    bgt    @Reset
    cmp.w  #VDP_SCREEN_HEIGHT_PX+VDP_SPRITE_BORDER_Y, Entity_PosY(a0)
    bgt    @Reset
    cmp.w  #VDP_SPRITE_BORDER_X, Entity_PosX(a0)
    blt    @Reset
    cmp.w  #VDP_SPRITE_BORDER_Y, Entity_PosY(a0)
    bge    @End

    @Reset:

    move.w EPlayer_SpawnPosX(a0), Entity_PosX(a0)
    move.w EPlayer_SpawnPosY(a0), Entity_PosY(a0)

    PUSH.L a0
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a0
    move.l #0x0, ECPhysicsBody_VelX(a0)
    move.l #0x0, ECPhysicsBody_VelY(a0)
    move.w ECPhysicsBody_AccelX(a0), d0
    move.w ECPhysicsBody_AccelY(a0), d1
    neg.w  d0
    move.w d1, ECPhysicsBody_AccelX(a0)
    move.w d0, ECPhysicsBody_AccelY(a0)
    POP.L  a0
    
    @End:

    rts

Main:
    ; ======================================
    ; Program entry point
    ; ======================================
    ; Called from bootstrap only
    ; ======================================

    ; Initialise entity manager
    bsr    ENT_Initialise

    ; Load palettes
    lea    palette_test, a0
    move.b #0x0, d0
    bsr    VDP_LoadPalette  

    ; Load scene
    lea    RAM_TESTSCENE1, a0
    lea    SceneData_tst1, a1
    bsr    SCN_LoadScene
    
    @Lp:

    ;DRAW_VRAM

    bsr    ENT_UpdateAll
    bsr    ECPhysicsBody_Step
    bsr    ECSprite_DrawAll
    bsr    SPR_CommitAndClearTable

    ; Loop forever
    bra    @Lp

    ; Asset includes
	include 'engine/assets.asm'
