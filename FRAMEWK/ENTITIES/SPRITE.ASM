; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; SPRITE.ASM - Sprite entity component
; ============================================================================================

    ENTITY_COMPONENT_BEGIN ECSprite
ECSprite_SpriteData                    rs.b SIZEOF_Sprite
    ENTITY_COMPONENT_END

ECSprite_Initialise:
    rts

ECSprite_Load:
    ; ======================================
    ; Allocs VRAM for sprite and loads tiles
    ; ======================================
	; a0   Sprite
    ; a1   Tile data
    ; d0.w Size (tiles)
    ; d1.b Sprite layout
    ; ======================================

    lea    ECSprite_SpriteData(a0), a0  ; Get sprite data
    move.b d1, Sprite_Layout(a0)        ; Set layout
    move.w d0, d1                       ; Backup size

    ; Alloc tiles
    PUSHM.L d1/a0-a1
    bsr    VRAMMGR_Alloc
    move.w d1, d0
    POPM.L  d1/a0-a1

    move.l d0, Sprite_VRAMHndl(a0)      ; Store VRAM handle
    move.l a1, a0                       ; Load tiles to VRAM
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
    lea    ECSprite_SpriteData(a3), a0  ; Get sprite data
    move.w Entity_PosX(a4), d0          ; Get pos
    move.w Entity_PosY(a4), d1

    bsr    SPR_DrawSingle               ; Draw
    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @SpriteLp

    @NoSprites:

    rts