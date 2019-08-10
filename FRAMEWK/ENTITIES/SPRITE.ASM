; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; SPRITE.ASM - Sprite entity component
; ============================================================================================

    ; ======================================
    ; Single sprite
    ; ======================================
    COMPONENT_SPAWN_DATA_BEGIN ECSprite
SDSprite_Sheet                          rs.l 1  ; [TAGS=SPRITE_SHEET]
    COMPONENT_SPAWN_DATA_END

    ENTITY_COMPONENT_BEGIN ECSprite
ECSprite_Sheet                          rs.l 1
ECSprite_VRAMHndl                       rs.l 1
ECSprite_DrawFlags                      rs.w 1
    ENTITY_COMPONENT_END

ECSprite_Initialise:
    ; ======================================
    ; ECSprite constructor
    ; ======================================
	; a0   Component
    ; a1   Spawn data
    ; ======================================

    move.w #0x0, ECSprite_DrawFlags(a0)
    move.l #0x0, ECSprite_VRAMHndl(a0)
    move.l SDSprite_Sheet(a1), ECSprite_Sheet(a0)
    bsr    ECSprite_Load

    rts

ECSprite_Shutdown:
    ; ======================================
    ; ECSprite destructor
    ; ======================================
	; a0   Component
    ; ======================================

    move.l ECSprite_VRAMHndl(a0), d0
    beq    @NotLoaded
    bsr    VRAMMGR_Free
    @NotLoaded:

    rts

ECSprite_Load:
    ; ======================================
    ; Allocs VRAM for sprite and loads tiles
    ; ======================================
	; a0   Sprite
    ; ======================================

    move.l ECSprite_Sheet(a0), a1       ; Get sprite sheet
    move.w SpriteSheet_SizeTiles(a1), d0; Get tile count

    ; Alloc tiles
    PUSHM.L a0-a1
    bsr    VRAMMGR_Alloc
    POPM.L  a0-a1
	
    move.l d1, ECSprite_VRAMHndl(a0) ; Store VRAM handle
    move.l d1, d0
    move.w SpriteSheet_SizeTiles(a1), d1
    move.l SpriteSheet_TileData(a1), a0 ; Load tiles to VRAM
    bsr    VDP_LoadTiles

    rts

ECSprite_DrawAll:
    ; ======================================
    ; Draws all Sprite entity components
    ; ======================================
	; No params
    ; ======================================

    ENT_COMPONENT_GET_LIST_HEAD ECSprite, a3
    cmp.w  #0x0, a3
    beq    @NoSprites

    @SpriteLp:
    movea.w Component_Owner(a3), a4     ; Get owning entity
    move.l ECSprite_Sheet(a3), a0       ; Get sprite sheet
    move.l ECSprite_VRAMHndl(a3), d2    ; Get VRAM handle
    move.w ECSprite_DrawFlags(a3), d3   ; Get draw flags
    move.w Entity_PosX(a4), d0          ; Get pos
    move.w Entity_PosY(a4), d1
    bsr    SPR_DrawSheet                ; Draw
    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @SpriteLp

    @NoSprites:

    rts