; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 5th June 2019
; ============================================================================================
; SCNANIM.ASM - Scene animation
; ============================================================================================

SceneAnim_MaxActors		equ 0x20

    STRUCT_BEGIN SceneAnimation
SceneAnim_ActorList            rs.l 1
SceneAnim_InitialPosList       rs.l 1
SceneAnim_KeyframeTimesList    rs.l 1
SceneAnim_KeyframeTrackListPos rs.l 1
SceneAnim_ActorCount           rs.w 1
SceneAnim_KeyframeCount        rs.w 1
SceneAnim_WorldPosX        	   rs.w 1
SceneAnim_WorldPosY        	   rs.w 1
SceneAnim_Width        	   	   rs.w 1
SceneAnim_Height        	   rs.w 1 
SceneAnim_Looping              rs.b 1
    STRUCT_END

	STRUCT_BEGIN SceneAnimSystem
SceneAnimSystem_ActorVelocities	rs.l (SceneAnim_MaxActors*2)	; Actor velocities
SceneAnimSystem_ActiveAnim		rs.l 1
SceneAnimSystem_AnimPosX		rs.w 1
SceneAnimSystem_AnimPosY		rs.w 1
SceneAnimSystem_Time			rs.w 1
SceneAnimSystem_NextKeyframeIdx	rs.w 1
	STRUCT_END

SCN_InitAnimSystem:

	lea    SceneAnimSystem, a0
	move.l #0x0, SceneAnimSystem_ActiveAnim(a0)
	move.w #0x0, SceneAnimSystem_AnimPosX(a0)
	move.w #0x0, SceneAnimSystem_AnimPosY(a0)
	move.w #0x0, SceneAnimSystem_Time(a0)
	move.w #0x0, SceneAnimSystem_NextKeyframeIdx(a0)

	rts

SCN_PlayAnimation:
	; a0.l - Scene anim

	lea    SceneAnimSystem, a1
	move.l a0, SceneAnimSystem_ActiveAnim(a1)
	move.w #0x0, SceneAnimSystem_Time(a1)
	move.w #0x0, SceneAnimSystem_NextKeyframeIdx(a1)

	; Set initial actor positions
	move.l SceneAnim_ActorList(a0), a3
	move.l SceneAnim_InitialPosList(a0), a4
	move.w SceneAnim_ActorCount(a0), d1
	subi.w #0x1, d1
	@ActorLp:

	; Get actor address
	move.l (a3)+, a5	; Pool location
	move.l (a5), a5		; Pool start addr
	move.l (a3)+, a6	; Object offset
	add.l  a6, a5

	; Set actor pos
	move.w (a4)+, d6
	move.w (a4)+, d7
	move.w d6, Entity_PosX(a5)
	move.w d7, Entity_PosY(a5)

	dbra   d1, @ActorLp

	rts

SCN_SetAnimPosition:
	; a0.l - Scene Anim
	; d0.w - X position
	; d1.w - Y position

	; Set pos
	lea    SceneAnimSystem, a1
	move.w d0, SceneAnimSystem_AnimPosX(a1)
	move.w d1, SceneAnimSystem_AnimPosY(a1)

	; For all actors
	move.l SceneAnim_ActorList(a0), a3
	move.l SceneAnim_InitialPosList(a0), a4
	move.w SceneAnim_ActorCount(a0), d7
	subi.w #0x1, d7
	@ActorLp:

	; Get actor address
	move.l (a3)+, a5	; Pool location
	move.l (a5), a5		; Pool start addr
	move.l (a3)+, a6	; Object offset
	add.l  a6, a5

	; Get actor initial pos
	move.w (a4)+, d3
	move.w (a4)+, d4

	; Offset
	add.w  d0, d3
	add.w  d1, d4

	; Set pos
	move.w d3, Entity_PosX(a5)
	move.w d4, Entity_PosY(a5)

	dbra   d7, @ActorLp

	rts

SCN_UpdateAnimSystem:
	
	lea    SceneAnimSystem, a0
	move.l SceneAnimSystem_ActiveAnim(a0), a1
	cmpa.w #0x0, a1
	beq    @NoAnim
	
	; If this is the last keyframe
	move.w SceneAnimSystem_NextKeyframeIdx(a0), d0
	cmp.w  SceneAnim_KeyframeCount(a1), d0
	bne    @NotAtEnd
	
	; If looping, return to beginning, else stop
	tst.b  SceneAnim_Looping(a1)
	beq    @NotLooping
	move.w #0x0, SceneAnimSystem_NextKeyframeIdx(a0); Reset next keyframe
	move.w #0x0, SceneAnimSystem_Time(a0)			; Reset animation time
	jsr    SceneAnimSystem_ResetActors				; Reset actor positions
	bra    @Looping
	@NotLooping:
	move.l #0x0, SceneAnimSystem_ActiveAnim(a0)		; Stop animation
	@Looping:
	@NotAtEnd:

	; Check if hit next keyframe
	move.w SceneAnimSystem_Time(a0), d1
	move.l SceneAnim_KeyframeTimesList(a1), a2
	moveq  #0x0, d0
	move.w SceneAnimSystem_NextKeyframeIdx(a0), d0	; Get next keyframe index
	move.l d0, d2									; Backup for next keyframe
	move.l d0, d3									; Backup for keyframe offset
	lsl.l  #0x1, d0									; To words
	add.l  d0, a2									; Get keyframe time addr
	cmp.w  (a2), d1									; Check if hit
	bne    @NotAdvanced
	
	; Next keyframe
	addi.w #0x1, d2
	move.w d2, SceneAnimSystem_NextKeyframeIdx(a0)

	; Keyframe to velocity offset (longwords*2)
	lsl.l  #0x3, d3

	; Update all actor velocities
	move.l SceneAnim_ActorList(a1), a3
	move.l SceneAnim_KeyframeTrackListPos(a1), a4
	move.w SceneAnim_ActorCount(a1), d1
	lea    SceneAnimSystem_ActorVelocities(a0), a2
	subi.w #0x1, d1
	@ActorLp:

	; Get actor address
	move.l (a3)+, a5	; Pool location
	move.l (a5), a5		; Pool start addr
	add.l  (a3)+, a5	; Object offset

	; Get actor's keyframe list
	move.l (a4)+, a6

	; Get current keyframe
	add.l  d3, a6
	move.l (a6)+, d5	; X vel
	move.l (a6)+, d6	; Y vel

	; Set actor velocity
	move.l d5, (a2)+
	move.l d6, (a2)+

	dbra   d1, @ActorLp

	@NotAdvanced:

	; Update all actors
	jsr    SceneAnimSystem_UpdateActors

	; Advance time
	move.w SceneAnimSystem_Time(a0), d1
	addi.w #0x1, d1
	move.w d1, SceneAnimSystem_Time(a0)

	@NoAnim:

	rts

SCN_UpdateAnimActors:
	; a0 --- SceneAnimSystem
	; a1 --- SceneAnim

	move.l SceneAnim_ActorList(a1), a3
	move.w SceneAnim_ActorCount(a1), d1
	lea    SceneAnimSystem_ActorVelocities(a0), a4
	subi.w #0x1, d1
	@ActorLp:

	; Get actor address
	move.l (a3)+, a5	; Pool location
	move.l (a5), a5		; Pool start addr
	move.l (a3)+, a6	; Object offset
	add.l  a6, a5

	; Update actor pos
	move.l (a4)+, d2
	move.l (a4)+, d3
	add.l  d2, Entity_PosX(a5)
	add.l  d3, Entity_PosY(a5)

	dbra   d1, @ActorLp

	rts

SCN_ResetAnimActors:
	; a0 --- SceneAnimSystem
	; a1 --- SceneAnim

	; Get pos offset
	move.w SceneAnimSystem_AnimPosX(a0), d5
	move.w SceneAnimSystem_AnimPosY(a0), d6

	; Get initial actor positions
	move.l SceneAnim_ActorList(a1), a3
	move.l SceneAnim_InitialPosList(a1), a4
	move.w SceneAnim_ActorCount(a1), d1
	subi.w #0x1, d1
	@ActorLp:

	; Get actor address
	move.l (a3)+, a5	; Pool location
	move.l (a5), a5		; Pool start addr
	move.l (a3)+, a6	; Object offset
	add.l  a6, a5

	; Get initial actor pos
	move.w (a4)+, d3
	move.w (a4)+, d4

	; Add current offset
	add.w  d5, d3
	add.w  d6, d4

	; Set actor pos
	move.w d3, Entity_PosX(a5)
	move.w d4, Entity_PosY(a5)

	@NextActor:
	dbra   d1, @ActorLp

	rts