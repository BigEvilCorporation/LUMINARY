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
    move.w #0x0800, ECPhysicsBody_AccelX(a0)

    rts

EPlayer_Shutdown:
    rts

EPlayer_Update:

    ; If entity out of bounce
    cmp.w  #VDP_SCREEN_WIDTH_PX+VDP_SPRITE_BORDER_X, Entity_PosX(a0)
    bgt    @Reset
    cmp.w  #VDP_SCREEN_HEIGHT_PX+VDP_SPRITE_BORDER_Y, Entity_PosY(a0)
    bgt    @Reset
    cmp.w  #VDP_SPRITE_BORDER_X, Entity_PosX(a0)
    blt    @Reset
    cmp.w  #VDP_SPRITE_BORDER_Y, Entity_PosY(a0)
    bge    @End

    @Reset:

    ; Fetch state
    move.w EPlayer_SpawnPosX(a0), d0
    move.w EPlayer_SpawnPosY(a0), d1
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a1
    move.w ECPhysicsBody_AccelX(a1), d2
    move.w ECPhysicsBody_AccelY(a1), d3

    PUSHM.W d2-d3
    PUSHM.W d0-d1

    ; Remove this entity
    bsr    ENT_DespawnEntity

    ; Spawn a new one
    POPM.W d0-d1
    lea    EPlayer_TypeDesc, a0
    lea    SceneEntitySpawnData_tst1_EPlayer_player1, a1
    bsr    ENT_SpawnEntity

    ; Restore state
    POPM.W d2-d3

    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a1
    neg.w  d2
    move.w d3, ECPhysicsBody_AccelX(a1)
    move.w d2, ECPhysicsBody_AccelY(a1)
    
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

    ; Update and draw
    bsr    ENT_UpdateAll
    bsr    ECPhysicsBody_Step
    bsr    ECSprite_DrawAll
    bsr    SPR_CommitAndClearTable

    ; Wait vsync
    move.l RAM_VBLANK_COUNTER, d0
    @VSync:
    move.l RAM_VBLANK_COUNTER, d1
    cmp.b  d0, d1
    beq    @VSync

    ; Loop forever
    bra    @Lp

    ; Asset includes
	include 'engine/assets.asm'
