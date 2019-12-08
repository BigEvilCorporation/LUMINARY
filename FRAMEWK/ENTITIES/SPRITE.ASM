; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th August 2019
; ============================================================================================
; SPRITE.ASM - Sprite entity component
; ============================================================================================

ECSPRITE_STATE_FLAG_PLAYING             equ 0x0 ; Anim playing
ECSPRITE_STATE_FLAG_LOOPING             equ 0x1 ; Loop animation
ECSPRITE_STATE_FLAG_VISIBLE             equ 0x2 ; Sprite visible
ECSPRITE_STATE_FLAG_ONSCREEN            equ 0x3 ; On screen last frame
ECSPRITE_STATE_FLAG_DIRTY               equ 0x4 ; Anim changed, forcefully load frame

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
ECSprite_AnimSubFrame                   rs.l 1  ; Current subframe (16.16)
ECSprite_AnimSpeed                      rs.w 1  ; Animation speed
ECSprite_PosX                           rs.b 1  ; Relative position X
ECSprite_PosY                           rs.b 1  ; Relative position Y
ECSprite_DrawFlags                      rs.b 1  ; Prio/pal/flip flags
ECSprite_StateFlags                     rs.b 1  ; ECSPRITE_STATE_FLAG_*
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
    move.l #0x0, ECSprite_VRAMHndl(a0)
    move.l #0x0, ECSprite_AnimSubFrame(a0)
    move.l #0x0, ECSprite_Animation(a0)
    move.b #0x0, ECSprite_PosX(a0)
    move.b #0x0, ECSprite_PosY(a0)
    move.b #0x0, ECSprite_DrawFlags(a0)
    move.b #(1<<ECSPRITE_STATE_FLAG_VISIBLE)|(1<<ECSPRITE_STATE_FLAG_ONSCREEN), ECSprite_StateFlags(a0)

    ; Load animation
    move.l SDSprite_Animation(a1), a2
    move.l SDSprite_Sheet(a1), a1
    bsr    ECSprite_LoadAnimation

    ; Alloc VRAM and load tile data
    PUSHM.L a0-a1
    bsr    ECSprite_LoadTiles
    POPM.L  a0-a1

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

ECSprite_LoadSheet:
    ; ======================================
    ; Loads a sprite sheet with no animation
    ; ======================================
	; a0   ECSprite component
    ; a1   SpriteSheet
    ; ======================================

    cmp.l  ECSprite_Sheet(a0), a1
    beq    @NoSheetChange

    ; Set sheet and first frame
    move.l a1, ECSprite_Sheet(a0)
    move.l SpriteSheet_FirstFrame(a1), ECSprite_CurrentFrame(a0)

    ; Clear animation
    move.l #0x0, ECSprite_Animation(a0)
    move.w #0x0, ECSprite_AnimSpeed(a0)
    bclr   #ECSPRITE_STATE_FLAG_LOOPING, ECSprite_StateFlags(a0)

    @NoSheetChange:

    rts

ECSprite_LoadAnimation:
    ; ======================================
    ; Loads a sprite sheet and animation,
    ; and begins playing with default parameters
    ; ======================================
	; a0   ECSprite component
    ; a1   SpriteSheet
    ; a2   SpriteAnim
    ; ======================================

    ; Set sheet and first frame
    cmp.l  ECSprite_Sheet(a0), a1
    beq    @NoSheetChange
    move.l a1, ECSprite_Sheet(a0)
    move.l SpriteSheet_FirstFrame(a1), ECSprite_CurrentFrame(a0)
    bset   #ECSPRITE_STATE_FLAG_DIRTY, ECSprite_StateFlags(a0)  ; Load frame on next render
    @NoSheetChange:

    ; If already playing and no anim change, don't reset
    btst   #ECSPRITE_STATE_FLAG_PLAYING, ECSprite_StateFlags(a0)
    beq    @Reset
    cmp.l  ECSprite_Animation(a0), a2
    beq    @NoAnimChange
    @Reset:

    ; Set animation
    move.l a2, ECSprite_Animation(a0)                           ; Set anim
    move.l #0x0, ECSprite_AnimSubFrame(a0)                      ; Reset subframe

    cmpa.w #0x0, a2
    beq    @NoAnim

    move.w SpriteAnim_DefaultSpeed(a2), ECSprite_AnimSpeed(a0)  ; Set default speed
    move.b SpriteAnim_DefaultLoop(a2), d0                       ; Set default loop flag
    andi.b #~(1<<ECSPRITE_STATE_FLAG_LOOPING), ECSprite_StateFlags(a0)
    lsl.b  #ECSPRITE_STATE_FLAG_LOOPING, d0
    or.b   d0, ECSprite_StateFlags(a0)
    bset   #ECSPRITE_STATE_FLAG_PLAYING, ECSprite_StateFlags(a0); Set playing

    rts

    @NoAnim:

    move.w #0x0, ECSprite_AnimSpeed(a0)                         ; Clear speed
    bclr   #ECSPRITE_STATE_FLAG_PLAYING, ECSprite_StateFlags(a0); Clear playing flag
    bclr   #ECSPRITE_STATE_FLAG_LOOPING, ECSprite_StateFlags(a0); Clear loop flag

    @NoAnimChange:
    

    rts

ECSprite_DrawAll:
    ; ======================================
    ; Draws all Sprite entity components
    ; ======================================
	; d4.w Camera bounds left   (object space)
    ; d5.w Camera bounds top    (object space)
    ; d6.w Camera bounds right  (object space)
    ; d7.w Camera bounds bottom (object space)
    ; ======================================

    ; Get sprite list
    ENT_COMPONENT_GET_LIST_HEAD ECSprite, a3
    cmp.w  #0x0, a3
    beq    @NoSprites

    @SpriteLp:
    PUSHM.W d4-d7

    ; Clear on screen flag
    bclr   #ECSPRITE_STATE_FLAG_ONSCREEN, ECSprite_StateFlags(a3)

    ; Check visible
    btst   #ECSPRITE_STATE_FLAG_VISIBLE, ECSprite_StateFlags(a3)
    beq    @NextSprite

    movea.w Component_Owner(a3), a4     ; Get owning entity
    move.b ECSprite_DrawFlags(a3), d3   ; Get draw flags
    lsl.w  #0x8, d3                     ; To hardware format

    ; Check on screen
    move.w Entity_PosX(a4), d0          ; Get X pos

    move.b ECSprite_PosX(a3), d2        ; Add component relative pos X
    ext.w  d2
    btst   #VDP_SPRITE_FLAG_FLIPX, d3
    beq    @NoflipX
    neg.w  d2
    @NoflipX:
    add.w  d2, d0

    move.w d0, d2                       ; Get sprite left
    sub.w  Entity_ExtentsX(a4), d2
	cmp.w  d2, d6					    ; Check sprite left against right border
	ble    @NextSprite
	move.w d0, d2                       ; Get sprite right
	add.w  Entity_ExtentsX(a4), d2
	cmp.w  d2, d4					    ; Check sprite right against left border
	bge    @NextSprite

    move.w Entity_PosY(a4), d1          ; Get Y pos

    move.b ECSprite_PosY(a3), d2        ; Add component relative pos Y
    ext.w  d2
    btst   #VDP_SPRITE_FLAG_FLIPY, d3
    beq    @NoflipY
    neg.w  d2
    @NoflipY:
    add.w  d2, d1

    move.w d1, d2                       ; Get sprite top
    sub.w  Entity_ExtentsY(a4), d2
	cmp.w  d2, d7					    ; Check sprite top against bottom border
	ble    @NextSprite
	move.w d1, d2                       ; Get sprite bottom
	add.w  Entity_ExtentsY(a4), d2
	cmp.w  d2, d5					    ; Check sprite bottom against top border
	bge    @NextSprite

    ; On screen
    bset   #ECSPRITE_STATE_FLAG_ONSCREEN, ECSprite_StateFlags(a3)

    move.l ECSprite_CurrentFrame(a3), a0; Get sprite frame
    move.l ECSprite_VRAMHndl(a3), d2    ; Get VRAM handle

    sub.w  d4, d0                       ; Camera space to sprite space
    sub.w  d5, d1
    addi.w #VDP_SPRITE_BORDER_X, d0
    addi.w #VDP_SPRITE_BORDER_Y, d1

    ; If dirty, skip straight to loading current frame
    btst   #ECSPRITE_STATE_FLAG_DIRTY, ECSprite_StateFlags(a3)
    bne    @ForceLoadFrame

    ; If anim not playing, skip frame advance
    btst   #ECSPRITE_STATE_FLAG_PLAYING, ECSprite_StateFlags(a3)
    beq    @NoAnim

    ; Tick animation
    move.l ECSprite_Animation(a3), a1
    cmpa.w #0x0, a1                     ; If no anim, don't fetch frame from keyframe track
    beq    @AnimNotPlaying
    moveq  #0x0, d4
    move.w ECSprite_AnimSpeed(a3), d4   ; Get speed, bail if 0
    beq    @AnimNotPlaying

    ext.l  d4                           ; Sign extend speed
    move.l ECSprite_AnimSubFrame(a3), d5; Advance subframe
    move.l d5, d6
    add.l  d4, d5
    move.l d5, ECSprite_AnimSubFrame(a3)

	move.w #0x0, d5
    swap   d5                           ; Subframes to frames
    swap   d6
    cmp.w  d5, d6                       ; If no change, bail
    beq    @AnimNoFrameChange

    ; Wrap frame idx and get next frame ptr from keyframe track
    moveq  #0x0, d6
    move.w SpriteAnim_Length(a1), d6    ; Wrap frame
    divs.w d6, d5
    swap   d5

    ; If not looping and this is the last frame, stop playback
    btst   #ECSPRITE_STATE_FLAG_LOOPING, ECSprite_StateFlags(a3)
    bne    @NotEnded
    tst.b  d5
    bne    @NotEnded
    bclr   #ECSPRITE_STATE_FLAG_PLAYING, ECSprite_StateFlags(a3)
    @NotEnded:

	lsl.w  #0x2, d5                     ; Frame to longs
    move.l SpriteAnim_KeyframeTrackFrameId(a1), a0 ; Get keyframe track
    move.l (a0, d5), a0                 ; Get new frame
    move.l a0, ECSprite_CurrentFrame(a3); Store new frame

    @ForceLoadFrame:
    @NoAnim:

    move.l a0, a1                       ; Set frame for loading
	
    ; Load new frame
    PUSHM.L d0-d3/a0-a3
    bclr   #ECSPRITE_STATE_FLAG_DIRTY, ECSprite_StateFlags(a3) ; Clear dirty flag
    move.l ECSprite_VRAMHndl(a3), d0
    move.w SpriteFrame_SizeTiles(a1), d1
    move.l SpriteFrame_TileData(a1), a0 ; Load tiles to VRAM
    lsl.w  #SIZE_TILE_SHIFT_B, d0
    lsl.w  #SIZE_TILE_SHIFT_W, d1
    move.b #VDPDMA_TRANSFER_VRAM, d2
    move.b #SIZE_WORD, d3
    bsr    VDPDMA_AddJob
    POPM.L d0-d3/a0-a3

    @AnimNotPlaying:
    @AnimNoFrameChange:

    ; Draw frame
    bsr    SPR_DrawFrame

    @NextSprite:
    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    POPM.W d4-d7
    bne    @SpriteLp

    @NoSprites:

    rts
