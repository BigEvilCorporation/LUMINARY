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

DRAW_VRAM: macro
    PUSH.L a0
    bsr    ERR_ResetForError
    bsr    VRAMMGR_DrawTable
    POP.L  a0
    endm

    ENTITY_SPAWN_DATA_BEGIN EPlayer
SDPlayer_SomeVariable                   rs.w 1
    ENTITY_SPAWN_DATA_END

    ENTITY_BEGIN EPlayer
	ENT_COMPONENT ECPhysicsBody
    ENT_COMPONENT ECSprite
    ENTITY_END

PlayerSpawnData:
    ; SDPlayer
    dc.w   0x000F

    ; SDPhysicsBody
    dc.w   0x1010

    ; SDSprite
    dc.l   TestSprite
    dc.w   1
    dc.b   VDP_SPRITE_LAYOUT_1x1

    even

    ; TODO:
    ; Spawn data for entity and all components merged into one block
    ; ENTITY_SPAWN_DATA_/COMPONENT_SPAWN_DATA_ macros keep track of size
    ; ENTITY_BEGIN/COMPONENT_BEGIN macros add spawn data offsets to ComponentSlotDesc within entity desc

SpawnPlayer:

    ; Spawn player entity
    lea    EPlayer_TypeDesc, a0
    lea    PlayerSpawnData, a1
    ; TODO: Position
    bsr    ENT_SpawnEntity
    
    PUSH.L a0

    ; Set position
    move.w #0x0088, Entity_PosX(a0)
    move.w #0x0088, Entity_PosY(a0)

    ; Init player's physics component
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a0
    move.w #0x0001, ECPhysicsBody_AccelX(a0)
    
    POP.L a0
    
    rts

EPlayer_Initialise:
    ; ======================================
    ; EPlayer constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    move.w SDPlayer_SomeVariable(a1), d0

    rts

EPlayer_Shutdown:
    rts

EPlayer_Update:

    cmp.w  #VDP_SCREEN_WIDTH_PX, Entity_PosX(a0)
    blt    @Ok
    bsr    ENT_DespawnEntity
    bsr    SpawnPlayer
    @Ok:

    rts

Main:
    ; ======================================
    ; Program entry point
    ; ======================================
    ; Called from bootstrap only
    ; ======================================

    ; Initialise entity manager
    bsr    ENT_Initialise

    ;bsr    TestSpawn

    ;; Alloc test sprite
    ;move.w #0x1, d0
    ;bsr    VRAMMGR_Alloc
    ;lea    RAM_TEST_SPRITE, a0
    ;move.l d1, Sprite_VRAMHndl(a0)
    ;move.b #VDP_SPRITE_LAYOUT_1x1, Sprite_Layout(a0)    
    ;SPRITE_SETPALETTE_CONST a0,1
    ;SPRITE_SETFLIPX_CONST a0,1
    ;SPRITE_SETFLIPY_CONST a0,1

    ;; Load test sprite tiles
    ;lea    TestSprite, a0
    ;move.w d1, d0
    ;move.w #0x1, d1
    ;bsr    VDP_LoadTiles

    bsr    SpawnPlayer
    move.w #0x0088, Entity_PosX(a0)
    move.w #0x0088, Entity_PosY(a0)
    
	bsr    SpawnPlayer
    move.w #0x0030, Entity_PosX(a0)
    move.w #0x0100, Entity_PosY(a0)
    
	bsr    SpawnPlayer
    move.w #0x0090, Entity_PosX(a0)
    move.w #0x0110, Entity_PosY(a0)
    
    bsr    SpawnPlayer
    move.w #0x0100, Entity_PosX(a0)
    move.w #0x0120, Entity_PosY(a0)

    ; Load palettes
    lea    tst_pal_0, a0
    move.b #0x0, d0
    bsr    VDP_LoadPalette  

    lea    tst_pal_1, a0
    move.b #0x1, d0
    bsr    VDP_LoadPalette

    lea    tst_pal_2, a0
    move.b #0x2, d0
    bsr    VDP_LoadPalette

    lea    tst_pal_3, a0
    move.b #0x3, d0
    bsr    VDP_LoadPalette
    
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

TestSprite:
    dc.l 0x00000000
    dc.l 0x00111100
    dc.l 0x01100110
    dc.l 0x01000010
    dc.l 0x01000010
    dc.l 0x01100110
    dc.l 0x00111100
    dc.l 0x00000000

tst_pal_0:
    dc.w   0x0E00
    dc.w   0x0EEE
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000

tst_pal_1:
    dc.w   0x0000
    dc.w   0x0E00
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000

tst_pal_2:
    dc.w   0x0000
    dc.w   0x00E0
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000

tst_pal_3:
    dc.w   0x0000
    dc.w   0x000E
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000
    dc.w   0x0000

tst_str:
    dc.b   'Hello, world!',0
    even