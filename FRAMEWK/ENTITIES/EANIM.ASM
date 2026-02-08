; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 17th December 2025
; ============================================================================================
; SCNANIM.ASM - Entity animation component
; ============================================================================================

ENT_ANIM_MAX_ACTORS		equ 0x20

    STRUCT_BEGIN ECAnimData
ECAnimData_InitialPosList          rs.l 1
ECAnimData_KeyframeTimesList       rs.l 1
ECAnimData_KeyframeTrackListPos    rs.l 1
ECAnimData_ActorCount              rs.w 1
ECAnimData_KeyframeCount           rs.w 1
ECAnimData_Looping                 rs.b 1
    STRUCT_END

    COMPONENT_SPAWN_DATA_BEGIN ECAnimation
    COMPONENT_SPAWN_DATA_END

	ENTITY_COMPONENT_BEGIN ECAnimation
ECAnimation_ActiveAnim		       rs.l 1
ECAnimation_ActorCount             rs.w 1
ECAnimation_ActorList              rs.w 1
ECAnimation_AnimPosX		       rs.w 1
ECAnimation_AnimPosY		       rs.w 1
ECAnimation_Time			       rs.w 1
ECAnimation_NextKeyframeIdx	       rs.w 1
	ENTITY_COMPONENT_END

ECAnimation_Initialise:
    ; ======================================
    ; ECAnimation constructor
    ; ======================================
	; a0   Component
    ; a1   Component spawn data
    ; ======================================

	move.l #0x0, ECAnimation_ActiveAnim(a0)
    move.w #0x0, ECAnimation_ActorCount(a0)
    move.w #0x0, ECAnimation_ActorList(a0)
	move.w #0x0, ECAnimation_AnimPosX(a0)
	move.w #0x0, ECAnimation_AnimPosY(a0)
	move.w #0x0, ECAnimation_Time(a0)
	move.w #0x0, ECAnimation_NextKeyframeIdx(a0)

	rts

ECAnimation_Play:
	; ======================================
    ; Play an animation
    ; ======================================
	; a0   Component
    ; a1   ECAnimData
    ; ======================================

    move.w ECAnimation_ActorCount(a0), d0
    move.w ECAnimData_ActorCount(a1), d1
    cmp.w  d0, d1
    beq    @CountOk
    DBG_RAISE_ERROR "ECAnimation_Play: Actor count mismatch"
    @CountOk:

	move.l a1, ECAnimation_ActiveAnim(a0)
	move.w #0x0, ECAnimation_Time(a0)
	move.w #0x0, ECAnimation_NextKeyframeIdx(a0)

	; Set initial actor positions
	bsr    ECAnimation_ResetActors

	rts

ECAnimation_Update:
    ; ======================================
    ; ECAnimation update
    ; ======================================
	; a0   Component
    ; d4.w Camera X (sprite space)
    ; d5.w Camera Y (sprite space)
    ; ======================================

	move.l ECAnimation_ActiveAnim(a0), a1
	cmpa.w #0x0, a1
	beq    @NoAnim
	
	; If this is the last keyframe
	move.w ECAnimation_NextKeyframeIdx(a0), d0
	cmp.w  ECAnimData_KeyframeCount(a1), d0
	bne    @NotAtEnd
	
	; If looping, return to beginning, else stop
	tst.b  ECAnimData_Looping(a1)
	beq    @NotLooping
	move.w #0x0, ECAnimation_NextKeyframeIdx(a0); Reset next keyframe
	move.w #0x0, ECAnimation_Time(a0)			; Reset animation time
	jsr    ECAnimation_ResetActors				; Reset actor positions
	bra    @Looping
	@NotLooping:
	move.l #0x0, ECAnimation_ActiveAnim(a0)		; Stop animation
	@Looping:
	@NotAtEnd:

	; Check if hit next keyframe
	move.w ECAnimation_Time(a0), d1
	move.l ECAnimData_KeyframeTimesList(a1), a2
	moveq  #0x0, d0
	move.w ECAnimation_NextKeyframeIdx(a0), d0	; Get next keyframe index
	move.l d0, d2									; Backup for next keyframe
	move.l d0, d3									; Backup for keyframe offset
	lsl.l  #0x1, d0									; To words
	add.l  d0, a2									; Get keyframe time addr
	cmp.w  (a2), d1									; Check if hit
	bne    @NotAdvanced
	
	; Next keyframe
	addi.w #0x1, d2
	move.w d2, ECAnimation_NextKeyframeIdx(a0)

	@NotAdvanced:

	; Update all actors
	move.l d3, d0
	jsr    ECAnimation_UpdateActors

	; Advance time
	move.w ECAnimation_Time(a0), d1
	addi.w #0x1, d1
	move.w d1, ECAnimation_Time(a0)

	@NoAnim:

	rts

ECAnimation_ResetActors:
    ; ============================================
    ; Resets anim actors back to initial positions
    ; ============================================
	; a0   Component
	; a1   EntityAnim
	; ============================================

	; Set initial actor positions (relative to owning actor)
    movea.w Component_Owner(a0), a2
	movea.w ECAnimation_ActorList(a0), a3
	move.l  ECAnimData_InitialPosList(a1), a4

    move.w Entity_PosX(a2), d2
    move.w Entity_PosY(a2), d3

	move.w ECAnimData_ActorCount(a1), d1
	subi.w #0x1, d1
	@ActorLp:

	; Get actor address
	movea.w (a3)+, a6

	; Set actor relative pos
	move.w (a4)+, d6
	move.w (a4)+, d7
    add.w  d2, d6
    add.w  d3, d7
	move.w d6, Entity_PosX(a6)
	move.w d7, Entity_PosY(a6)

	dbra   d1, @ActorLp

	rts

ECAnimation_UpdateActors:
	; a0   Component
	; a1   EntityAnim
	; d0.l Keyframe

	; Keyframe to velocity offset (longwords*2)
	lsl.l  #0x3, d0

	move.l ECAnimation_ActiveAnim(a0), a1
	move.l ECAnimData_KeyframeTrackListPos(a1), a4

	movea.w ECAnimation_ActorList(a0), a3
	move.w  ECAnimData_ActorCount(a1), d1
	subi.w #0x1, d1
	@ActorLp:

	; Get actor address
	movea.w (a3)+, a5

	; Get actor's keyframe list
	move.l (a4)+, a6

	; Get current keyframe
	add.l  d0, a6
	move.l (a6)+, d5	; X vel
	move.l (a6)+, d6	; Y vel

	; Update actor pos
	add.l  d5, Entity_PosX(a5)
	add.l  d6, Entity_PosY(a5)

	dbra   d1, @ActorLp

	rts

ECAnimation_UpdateAll:
    ; ======================================
    ; Updated all animation entity components
    ; ======================================

    ENT_COMPONENT_GET_LIST_HEAD ECAnimation, a0
    cmpa.w #0x0, a0
    beq    @NoAnims

    @AnimLp:
    PUSHM.W d4-d5
    bsr    ECAnimation_Update
    movea.w EntityBlock_Next(a0), a0    ; Next component
    POPM.W d4-d5
    cmp.w  #0x0, a0
    bne    @AnimLp
    
    @NoAnims:
    rts