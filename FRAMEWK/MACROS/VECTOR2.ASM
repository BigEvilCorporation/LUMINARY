; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 9th November 2021
; ============================================================================================
; VECTOR2.ASM - 2D vector routines
; ============================================================================================

VEC2_ADD: macro vec1,vec2
    add.w \vec1, \vec2	; Vec2.y + Vec1.y
	swap  \vec1
	swap  \vec2
	add.w \vec1, \vec2	; Vec2.x + Vec1.x
	swap  \vec1
	swap  \vec2
    endm

VEC2_SUB: macro vec1,vec2
    sub.w \vec1, \vec2	; Vec2.y - Vec1.y
	swap  \vec1
	swap  \vec2
	sub.w \vec1, \vec2	; Vec2.x - Vec1.x
	swap  \vec1
	swap  \vec2
    endm
	
VEC2_DISTSQ: macro vec1,vec2,tmpreg
	; DistSq = sq(v2.x - v1.x) + sq(v2.y - v1.y)
    moveq  #0x0,  \tmpreg
	sub.w  \vec2, \vec1		; Vec2.y - Vec1.y
	move.w \vec1, \tmpreg
	muls   \tmpreg, \tmpreg	; Square
	move.w #0x0, \vec1
	swap   \vec1
	swap   \vec2
	sub.w  \vec2, \vec1		; Vec2.x - Vec1.x
	muls   \vec1, \vec1		; Square
	add.l  \tmpreg, \vec1
    endm

VEC2_DOT: macro vec1,vec2,tmpreg
	; Dot = (v1.x * v2.x + v1.y * v2.y)
	move.w  \vec1, \tmpreg
	muls.w  \vec2, \tmpreg	; Vec2.y * Vec1.y
	swap    \vec1
	swap    \vec2
	muls.w  \vec2, \vec1	; Vec2.x * Vec1.x
	add.l   \tmpreg, \vec1	; Add
    endm

VEC2_REFLECT: macro vec,norm,tmpreg1,tmpreg2,tmpreg3
											; Reflect = vec - (2 * norm * (norm . vec))
	move.l \vec, \tmpreg1
	move.l \norm, \tmpreg2
	VEC2_DOT  \tmpreg1, \tmpreg2, \tmpreg3	;                             (norm . vec)
	muls.w #0x2, \norm						;                 (2 * norm.y)
	muls.w \tmpreg1, \norm					;                           * (norm . vec)
	sub.w  \norm, \vec						;           vec.y -
	swap   \norm
	muls.w #0x2, \norm						;                 (2 * norm.x)
	muls.w \tmpreg1, \norm					;                           * (norm . vec)
	sub.w  \norm, \vec						;           vec.x -
	swap   \norm
	endm