; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 13th November 2019
; ============================================================================================
; GEOMETRY.ASM - Geometry collision/intersection tests
; ============================================================================================

GEOM_PointInsideBox:
	; d0 (b)  Return value: 0 = point outside box, 1 = point inside box
	; d1 (ww) Box min XY
	; d2 (ww) Box max XY
	; d3 (ww) Point XY
	;
	; Destructive to:
	; d2
	; d3
	
	move.b #0x0, d0
	
	; If point Y < box min Y, bail
	cmp.w d3, d1
	bgt   @Outside
	
	; If point Y > box max Y, bail
	cmp.w d3, d2
	blt   @Outside
	
	swap  d3
	
	; If point X < box min X, bail
	swap  d1
	cmp.w d3, d1
	bgt   @Outside
	
	; If point X > box man X, bail
	swap  d2
	cmp.w d3, d2
	blt   @Outside
	
	; Success
	move.b #0x1, d0
	
	; Fail
	@Outside:
	rts

GEOM_BoxIntersectBox:
	; d0 (b)  Return value: 0 = no collision, 1 = collision
	; d1 (ww) Box 1 min XY
	; d2 (ww) Box 1 max XY
	; d3 (ww) Box 2 min XY
	; d4 (ww) Box 2 max XY
	;
	; Destructive to:
	; d5
	; d6
	
	move.b #0x0, d0
	
	; If maxY1 < minY2, bail
	cmp.w d2, d3
	bgt @NoIntersect

	; If minY1 > maxY2, bail
	cmp.w d1, d4
	blt @NoIntersect
	
	; If maxX1 < minX2, bail
	move.l d2, d5
	move.l d3, d6
	swap d5
	swap d5
	cmp.w d5, d6
	bgt @NoIntersect
		
	; If minX1 > maxX2, bail
	move.l d1, d5
	move.l d4, d6
	swap d5
	swap d6
	cmp.w d5, d6
	blt @NoIntersect
	
	; Success
	move.b #0x1, d0
	
	; Fail
	@NoIntersect:
	rts

GEOM_BoxInsideBox:
	; d0 (b)  Return value: 0 = box 2 outside box 1, 1 = box 2 inside box 1
	; d1 (ww) Box 1 min XY (outside box)
	; d2 (ww) Box 1 max XY
	; d3 (ww) Box 2 min XY (inside box)
	; d4 (ww) Box 2 max XY
	;
	; Destructive to:
	; d5
	; d6

	move.b #0x0, d0
	
	; If minY1 > minY2, bail
	cmp.w d1, d3
	blt @Outside

	; If maxY1 < maxY2, bail
	cmp.w d2, d4
	bgt @Outside

	; If minX1 > minX2, bail
	move.l d1, d5
	move.l d3, d6
	swap d5
	swap d6
	cmp.w d5, d6
	blt @Outside
	
	; If maxX1 < maxX2, bail
	move.l d2, d5
	move.l d4, d6
	swap d5
	swap d6
	cmp.w d5, d6
	bgt @Outside
	
	; Success
	move.b #0x1, d0
	
	; Fail
	@Outside:
	rts

GEOM_GrowBounds: macro minreg,maxreg,sizereg
	; minreg  (l) Min XY
	; maxreg  (l) Max XY
	; sizereg (l) Size XY
	sub.w \sizereg,\minreg
	add.w \sizereg,\maxreg
	swap  \minreg
	swap  \maxreg
	swap  \sizereg
	sub.w \sizereg,\minreg
	add.w \sizereg,\maxreg
	swap  \minreg
	swap  \maxreg
	endm

GEOM_ShrinkBounds: macro minreg,maxreg,sizereg
	; minreg  (l) Min XY
	; maxreg  (l) Max XY
	; sizereg (l) Size XY
	add.w \sizereg,\minreg
	sub.w \sizereg,\maxreg
	swap  \minreg
	swap  \maxreg
	swap  \sizereg
	add.w \sizereg,\minreg
	sub.w \sizereg,\maxreg
	swap  \minreg
	swap  \maxreg
	endm