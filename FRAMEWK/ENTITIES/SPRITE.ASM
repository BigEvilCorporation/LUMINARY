; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; SPRITE.ASM - Sprite entity component
; ============================================================================================

    ; ======================================
    ; Sprite component
    ; ======================================
    COMPONENT_SPAWN_DATA_BEGIN ECSprite
SDSprite_Sheet                          rs.l 1  ; [TAGS=SPRITE_SHEET]
SDSprite_Animation                      rs.l 1  ; [TAGS=SPRITE_ANIM]
    COMPONENT_SPAWN_DATA_END

    ENTITY_COMPONENT_BEGIN ECSprite
ECSprite_Sheet                          rs.l 1  ; Sprite sheet
ECSprite_CurrentFrame                   rs.l 1  ; Current sprite frame
ECSprite_VRAMHndl                       rs.l 1  ; VRAM allocation
ECSprite_Animation                      rs.l 1  ; Current animation
ECSprite_AnimSubFrame                   rs.l 1  ; Current subframe
ECSprite_AnimSpeed                      rs.w 1  ; Animation speed
ECSprite_DrawFlags                      rs.w 1  ; Prio/pal/flip flags
ECSprite_AnimLoop                       rs.b 1  ; Animation loop flag
    ENTITY_COMPONENT_END

    ; ======================================
    ; Sprite animation
    ; ======================================
    STRUCT_BEGIN SpriteAnim
SpriteAnim_KeyframeTrackFrameId         rs.l 1  ; Frame ID keyframe track
SpriteAnim_Length                       rs.w 1  ; Length in keyframes
SpriteAnim_DefaultSpeed                 rs.w 1  ; Default speed
SpriteAnim_DefaultLoop                  rs.b 1  ; Default loop flag
    STRUCT_END

ECSprite_Initialise:
    ; ======================================
    ; ECSprite constructor
    ; ======================================
	; a0   ECSprite component
    ; a1   SDSprite spawn data
    ; ======================================

    ; Initialise from spawn params
    move.l SDSprite_Sheet(a1), a2
    move.l a2, ECSprite_Sheet(a0)
    move.w #0x0, ECSprite_DrawFlags(a0)
    move.l #0x0, ECSprite_VRAMHndl(a0)
    move.l #0x0, ECSprite_AnimSubFrame(a0)
    move.l #0x0, ECSprite_Animation(a0)

    ; Set first animation frame
    move.l SpriteSheet_FirstFrame(a2), ECSprite_CurrentFrame(a0)
    
    ; Alloc VRAM and load tile data
    bsr    ECSprite_LoadTiles

    ; Load animation
    move.l ECSprite_Animation(a0), a1
    cmp.l  #0x0, a1
    beq    @NoAnim
    bsr    ECSprite_LoadAnimation
    @NoAnim:

    rts

ECSprite_Shutdown:
    ; ======================================
    ; ECSprite destructor
    ; ======================================
	; a0   ECSprite component
    ; ======================================

    move.l ECSprite_VRAMHndl(a0), d0
    beq    @NotLoaded
    bsr    VRAMMGR_Free
    @NotLoaded:

    rts

ECSprite_LoadTiles:
    ; ======================================
    ; Allocs VRAM for sprite and loads tiles
    ; ======================================
	; a0   ECSprite component
    ; ======================================

    move.l ECSprite_Sheet(a0), a1           ; Get sprite sheet
    move.w SpriteSheet_VRAMSizeTiles(a1), d0; Get size of largest frame

    ; Alloc tiles
    PUSH.L a0
    bsr    VRAMMGR_Alloc
    POP.L  a0
    move.l d1, ECSprite_VRAMHndl(a0)    ; Store VRAM handle
	
    ; Load first frame
    move.l d1, d0
    move.l ECSprite_CurrentFrame(a0), a1
    move.w SpriteFrame_SizeTiles(a1), d1
    move.l SpriteFrame_TileData(a1), a0 ; Load tiles to VRAM
    bsr    VDP_LoadTiles

    rts

ECSprite_LoadAnimation:
    ; ======================================
    ; Loads a sprite animation and begins
    ; playing with default parameters
    ; ======================================
	; a0   ECSprite component
    ; a1   SpriteAnim
    ; ======================================

    ;cmp.l  a1, ECSprite_Animation(a0)
    ;beq    @NoChange

    ;move.l a1, ECSprite_Animation(a0)                           ; Set anim
    ;move.w SpriteAnim_DefaultSpeed(a1), ECSprite_AnimSpeed(a0)  ; Set default speed
    ;move.b SpriteAnim_DefaultLoop(a1), ECSprite_AnimLoop(a0)    ; Set default loop flag
    ;move.l #0x0, ECSprite_AnimSubFrame(a0)                      ; Reset subframe

    ;@NoChange:

    rts

ECSprite_UpdateAnim:
    ; ======================================
    ; Ticks a sprite animation, and modifies
    ; draw data to be passed to SPR_DrawSheet
    ; ======================================
    ; In:
    ; a0   SpriteFrame
    ; a1   SpriteAnim
    ; a3   ECSprite component
    ; d0.w Position X
    ; d1.w Position Y
    ; d2.l VRAM hndl
    ; d3.w Draw flags
    ; ======================================
    ; Out:
    ; a0   SpriteFrame
    ; a3   ECSprite component
    ; d0.w Draw position X
    ; d1.w Draw position Y
    ; d2.l VRAM hndl
    ; d3.w Draw flags
    ; ======================================

    moveq  #0x0, d4
    move.w ECSprite_AnimSpeed(a3), d4   ; Get speed, bail if 0
    beq    @NotPlaying

    ext.l  d4                           ; Sign extend speed
    move.l ECSprite_AnimSubFrame(a3), d5; Advance subframe
    move.l d5, d6
    add.l  d4, d5
    move.l d5, ECSprite_AnimSubFrame(a3)

    swap   d5                           ; Subframes to frames
    swap   d6
    cmp.w  d5, d6                       ; If no change, bail
    beq    @NoFrameChange



    @NotPlaying:
    @NoFrameChange:

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
    move.l ECSprite_CurrentFrame(a3), a0; Get sprite frame
    move.l ECSprite_VRAMHndl(a3), d2    ; Get VRAM handle
    move.w ECSprite_DrawFlags(a3), d3   ; Get draw flags
    move.w Entity_PosX(a4), d0          ; Get pos
    move.w Entity_PosY(a4), d1

    ;move.l ECSprite_Animation(a3), a1   ; Tick animation
    ;cmp.l  #0x0, a1                     ; (which modifies draw params if necessary)
    ;beq    @NoAnim
    ;bsr    ECSprite_UpdateAnim
    ;@NoAnim:

    bsr    SPR_DrawFrame                ; Draw
    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @SpriteLp

    @NoSprites:

    rts
