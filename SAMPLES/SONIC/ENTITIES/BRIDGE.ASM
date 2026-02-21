; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 8th December 2019
; ============================================================================================
; BRIDGE.ASM - Sonic-style depressed bridge object
; ============================================================================================

; Bridge constants
EBRIDGE_SEGMENT_WIDTH                   equ 0x10
EBRIDGE_NUM_SEGMENTS                    equ 12
EBRIDGE_WIDTH                           equ EBRIDGE_SEGMENT_WIDTH*EBRIDGE_NUM_SEGMENTS
EBRIDGE_HEIGHT                          equ 0x08
EBRIDGE_DEPRESSION_PER_SEGMENT          equ 0x0180  ; 8.8

; ============================================================================================
; BRIDGE RENDER COMPONENT - DRAWS LINE OF SPRITES WITH Y OFFSETS
; ============================================================================================

    COMPONENT_SPAWN_DATA_BEGIN ECBridgeRenderer
SDBridgeRenderer_Sheet                  rs.l 1  ; [TAGS=SPRITE_SHEET]
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECBridgeRenderer
ECBridgeRenderer_SegmentOffsY           rs.b EBRIDGE_NUM_SEGMENTS
ECBridgeRenderer_Sheet                  rs.l 1  ; Sprite sheet
ECBridgeRenderer_VRAMHndl               rs.l 1  ; VRAM allocation
ECBridgeRenderer_DrawFlags              rs.b 1  ; Prio/pal/flip flags
    ENTITY_COMPONENT_END

ECBridgeRenderer_Initialise:
    ; ======================================
    ; ECBridgeRenderer constructor
    ; ======================================
	; a0   ECBridgeRenderer component
    ; a1   ECBridgeRenderer spawn data
    ; ======================================

    ; Initialise from spawn params
    move.l SDBridgeRenderer_Sheet(a1), a3
    move.l a3, ECBridgeRenderer_Sheet(a0)
    move.w #0x0, ECBridgeRenderer_DrawFlags(a0)

    ; Clear height offsets
    move.w #EBRIDGE_NUM_SEGMENTS, d0
    lea    ECBridgeRenderer_SegmentOffsY(a0), a2
    MEMSET.B a2,#0x0,d0

    ; Alloc tiles
    PUSHM.L a0-a3
    move.w SpriteSheet_VRAMSizeTiles(a3), d0    ; Get size of largest frame
    bsr    VRAMMGR_Alloc
    POPM.L  a0-a3
    move.l d1, ECBridgeRenderer_VRAMHndl(a0)    ; Store VRAM handle
	
    ; Load tiles
    move.l d1, d0
    move.l SpriteSheet_FirstFrame(a3), a1
    move.w SpriteFrame_SizeTiles(a1), d1
    move.l SpriteFrame_TileData(a1), a0 ; Load tiles to VRAM
    bsr    VDP_LoadTiles

    rts

ECBridgeRenderer_Shutdown:
    ; ======================================
    ; ECBridgeRenderer destructor
    ; ======================================
	; a0   ECBridgeRenderer component
    ; ======================================

    move.l ECBridgeRenderer_VRAMHndl(a0), d0
    beq    @NotLoaded
    bsr    VRAMMGR_Free
    @NotLoaded:

    rts

ECBridgeRenderer_DrawAll:
    ; ======================================
    ; Draws all bridges
    ; ======================================
	; d4.w Camera bounds left   (object space)
    ; d5.w Camera bounds top    (object space)
    ; d6.w Camera bounds right  (object space)
    ; d7.w Camera bounds bottom (object space)
    ; ======================================

    ; For all bridges
    ENT_COMPONENT_GET_LIST_HEAD ECBridgeRenderer, a3
    cmp.w  #0x0, a3
    beq    @NoBridges

    @BridgeLp:
    PUSHM.W d4-d7                       ; Backup camera

    movea.w Component_Owner(a3), a4     ; Entity
    move.w Entity_PosX(a4), d0          ; X pos
    move.w Entity_PosY(a4), d1          ; Y pos

    ; Check in screen bounds
    ENT_CHECKCAMERABOUNDS a4,d0,d1,d4,d5,d6,d7,d2,d3
    tst.b  d2
    beq    @NextBridge

    ; Camera space to sprite space
    sub.w  d4, d0
    sub.w  d5, d1
    addi.w #VDP_SPRITE_BORDER_X, d0
    addi.w #VDP_SPRITE_BORDER_Y, d1

    ; Start drawing from left-hand side
    subi.w #EBRIDGE_SEGMENT_WIDTH*(EBRIDGE_NUM_SEGMENTS/2)-(EBRIDGE_SEGMENT_WIDTH/2), d0
    move.w d1, d5

    move.l ECBridgeRenderer_Sheet(a3), a1       ; Sprite sheet
    move.l SpriteSheet_FirstFrame(a1), a0       ; Sprite frame
    move.l ECBridgeRenderer_VRAMHndl(a3), d2    ; VRAM handle
    move.w ECBridgeRenderer_DrawFlags(a3), d3   ; Draw flags
    lea    ECBridgeRenderer_SegmentOffsY(a3), a2; Draw offsets

    ; For all segments
    move.w #EBRIDGE_NUM_SEGMENTS-1, d4
    @SegmentLp:

    ; Next Y offset
    move.w d5, d1
    move.b (a2)+, d6
    ext.w  d6
    add.w  d6, d1

    ; Draw segment
    PUSHM.W d0-d5
    PUSH.L a2
    bsr    SPR_DrawFrame
    POP.L  a2
    POPM.W d0-d5

    ; Next X pos
    addi.w #EBRIDGE_SEGMENT_WIDTH, d0

    ; Next segment
    dbra   d4, @SegmentLp

    @NextBridge:
    POPM.W d4-d7                        ; Restore camera
    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @BridgeLp

    @NoBridges:

    rts

; ============================================================================================
; BRIDGE ENTITY
; ============================================================================================

; Bridge spawn data
    ENTITY_SPAWN_DATA_BEGIN EBridge
    ENTITY_SPAWN_DATA_END

; Bridge entity
    ENTITY_BEGIN EBridge
EBridge_LastTouchedSegmentIdx           rs.b 1
    ENT_COMPONENT ECBridgeRenderer
    ENT_COMPONENT ECPlatform
    ENTITY_END

EBridge_Initialise:
    ; ======================================
    ; EBridge constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Initialise
    move.b #-1, EBridge_LastTouchedSegmentIdx(a0)

    ; Set platform OnTouched callback
    ENT_GETCOMPONENT EBridge,ECPlatform,a0,a1
    move.w #EBridge_OnTouched, ECPlatform_OnTouched(a1)

    rts

EBridge_Shutdown:
    ; ======================================
    ; EBridge destructor
    ; ======================================
	; a0   Entity
    ; ======================================

    rts

EBridge_Update:
    ; ======================================
    ; EBridge update
    ; ======================================
	; a0   Entity
    ; ======================================

    ; Get bridge touched segment and depression
    moveq  #0x0, d0                     ; Depression amount per segment (before apex)
    moveq  #0x0, d1                     ; Depression amount per segment (after apex)
    moveq  #0x0, d2                     ; Touched segment index from left-hand side
    moveq  #0x0, d3                     ; Touched segment index from right-hand side
    moveq  #0x0, d4                     ; Depression accumulator
    moveq  #0x0, d6                     ; Max depression amount (new platform height)

    move.b EBridge_LastTouchedSegmentIdx(a0), d2 ; Get segment index from left-hand side
    cmp.b  #-1, d2
    beq    @NoDepression
    move.b #EBRIDGE_NUM_SEGMENTS, d3    ; Get segment index from right-hand side
    sub.b  d2, d3
    addi.b #0x1, d2                     ; Start from 1
    addi.b #0x1, d3

    ; Calculate max depression amount (distance from centre * depression amount per seg)
    move.b d2, d6                       ; Distance from centre
    subi.b #EBRIDGE_NUM_SEGMENTS/2, d6
    ABS.B  d6
    move.b #EBRIDGE_NUM_SEGMENTS/2, d5  ; Invert
    sub.b  d6, d5
    INT_TO_FIXED8 d5                    ; To 8.8 for decimal accuracy
    FIXED8_MUL #EBRIDGE_DEPRESSION_PER_SEGMENT, d5

    ; Set as platform height
    ENT_GETCOMPONENT EBridge,ECPlatform,a0,a1
    move.w d5, d6
    FIXED8_TO_INT d6
    move.w d6, ECPlatform_OffsetY(a1)

    ; Calculate segment depressions before and after apex
    move.w d5, d0
    move.w d5, d1
    divu   d2, d0   ; Depression per segment before apex
    divu   d3, d1   ; Depression per segment after apex
    neg.w  d1       ; On the way back up
    @NoDepression:

    ; Get bridge renderer Y offset array
    ENT_GETCOMPONENT EBridge,ECBridgeRenderer,a0,a1
    lea    ECBridgeRenderer_SegmentOffsY(a1), a1

    ; Starting from left-hand side, depress bridge segments until apex,
    ; then raise until the end
    move.w #EBRIDGE_NUM_SEGMENTS-1, d7
    @SegmentLp:

    add.w  d0, d4                       ; Depress/raise segment
    tst.w  d4                           ; Clamp to 0
    bge    @NoClamp
    move.w #0x0, d4
    @NoClamp:

    move.w d4, d5
    FIXED8_TO_INT d5                    ; 8.8 to integer
    move.b d5, (a1)+                    ; Write and advance segment

    move.w #EBRIDGE_NUM_SEGMENTS-1, d5  ; Invert index
    sub.w  d7, d5
    cmp.b  d5, d2
    bne    @NotApex
    move.w d1, d0                       ; Hit apex, go back up
    @NotApex:

    dbra   d7, @SegmentLp

    rts

EBridge_OnTouched:
    ; ======================================
    ; ECPlatform_OnTouched callback
    ; ======================================
    ; a0   Entity touching platform
    ; a3   ECPlatform component
    ; d0.w Platform height
    ; ======================================

    PUSHM.L d0-d1/a4

	moveq  #0x0, d0
    movea.w Component_Owner(a3), a4     ; Get owning entity
    move.w Entity_PosX(a0), d0          ; Get position offset from bridge left
    move.w Entity_PosX(a4), d1
    sub.w  Entity_ExtentsX(a4), d1
    sub.w  d1, d0
    divu.w #EBRIDGE_SEGMENT_WIDTH, d0   ; To segment index
    move.b d0, EBridge_LastTouchedSegmentIdx(a4)

    POPM.L  d0-d1/a4

    rts