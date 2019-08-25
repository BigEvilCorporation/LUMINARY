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
    ENTITY_SPAWN_DATA_END

    ENTITY_BEGIN EPlayer
EPlayer_SpawnData                       rs.l 1
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
    move.l a1, EPlayer_SpawnData(a0)
    
    ; Set as camera target
    move.l RAM_CAMERA_CURRENT, a2
    cmpa.l #0x0, a2
    beq    @NoCam
    move.l a0, Camera_TargetEntity(a2)
    @NoCam:

    ; Init player's physics component
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a0
    ;move.w #0x0800, ECPhysicsBody_AccelX(a0)

    rts

EPlayer_Shutdown:
    rts

EPlayer_Update:

    move.l #0x0, d1
    move.l #0x0, d2

    bsr    PAD_ReadPortA
    btst   #PAD_BUTTON_UP, d0
    beq    @NoUp
    move.l #-500, d2
    @NoUp:

    btst   #PAD_BUTTON_DOWN, d0
    beq    @NoDn
    move.l #500, d2
    @NoDn:

    btst   #PAD_BUTTON_LEFT, d0
    beq    @NoLft
    move.l #-500, d1
    @NoLft:

    btst   #PAD_BUTTON_RIGHT, d0
    beq    @NoRt
    move.l #500, d1
    @NoRt:

    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a1
    move.w d1, ECPhysicsBody_AccelX(a1)
    move.w d2, ECPhysicsBody_AccelY(a1)

    rts

    ; If entity out of bounds
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
    move.l EPlayer_SpawnData(a0), d2
    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a1
    move.w ECPhysicsBody_AccelX(a1), d3
    move.w ECPhysicsBody_AccelY(a1), d4

    PUSHM.W d3-d4
    PUSHM.L d0-d2

    ; Remove this entity
    bsr    ENT_DespawnEntity

    ; Spawn a new one
    POPM.L d0-d2
    lea    EPlayer_TypeDesc, a0
    move.l d2, a1
    bsr    ENT_SpawnEntity

    ; Restore state
    POPM.W d3-d4

    ENT_GETCOMPONENT EPlayer,ECPhysicsBody,a0,a1
    neg.w  d3
    move.w d4, ECPhysicsBody_AccelX(a1)
    move.w d3, ECPhysicsBody_AccelY(a1)
    
    @End:

    rts

Main:
    ; ======================================
    ; Program entry point
    ; ======================================
    ; Called from bootstrap only
    ; ======================================

    ; Initialise entity manager
    ; TODO: LuminaryInit
    bsr    ENT_Initialise

    ; Initialise camera
    ; TODO: LuminaryInit
    bsr    CAM_Initialise

    ; Load palettes
    lea    palette_test2, a0
    move.b #0x0, d0
    ;bsr    VDP_LoadPalette  

    ; Load scene
    lea    RAM_TESTSCENE1, a0
    lea    SceneData_tst1_tst1, a1
    bsr    SCN_LoadScene
    
    @Lp:

    ;DRAW_VRAM

    ; Update
    bsr    ENT_UpdateAll
    bsr    ECPhysicsBody_Step
    bsr    CAM_UpdateAll
    bsr    MAP_ClampScroll
    bsr    MAP_UpdateStreaming

    ; Draw
    bsr    ECSprite_DrawAll

    ; Wait vsync
    move.l RAM_VBLANK_COUNTER, d0
    @VSync:
    move.l RAM_VBLANK_COUNTER, d1
    cmp.b  d0, d1
    beq    @VSync

    ; DMA and VDP
    bsr    MAP_ApplyScroll
    bsr    VDPDMA_CommitAndClearQueue
    bsr    SPR_CommitAndClearTable

    ; Loop forever
    bra    @Lp

    ; Asset includes
	include 'engine/assets.asm'

    ; Scene data
    include 'samples/hello/data/scenes/chaptr01/include.asm'

    ; Sprite data
    include 'samples/hello/data/sprites/sprites.asm'
    include 'samples/hello/data/anims/sprtanms.asm'
    include 'samples/hello/data/palettes/sprtpals.asm'
