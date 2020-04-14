;==============================================================
; 3D MATHS ROUTINES
;==============================================================

sintable:
	dc.b 0,3,6,9,12,15,18,21,24,27,30,34,37,39,42,45
	dc.b 48,51,54,57,60,62,65,68,70,73,75,78,80,83,85,87
	dc.b 90,92,94,96,98,100,102,104,105,107,109,110,112,113,115,116
	dc.b 117,118,119,120,121,122,123,124,124,125,125,126,126,126,126,126
	dc.b 126,126,126,126,126,125,125,124,124,123,122,122,121,120,119,118
	dc.b 116,115,114,112,111,109,108,106,104,103,101,99,97,95,93,91
	dc.b 88,86,84,82,79,77,74,72,69,66,64,61,58,55,53,50
	dc.b 47,44,41,38,35,32,29,26,23,20,17,14,10,7,4,1
	dc.b -1,-4,-7,-10,-14,-17,-20,-23,-26,-29,-32,-35,-38,-41,-44,-47
	dc.b -50,-53,-55,-58,-61,-64,-66,-69,-72,-74,-77,-79,-82,-84,-86,-88
	dc.b -91,-93,-95,-97,-99,-101,-103,-104,-106,-108,-109,-111,-112,-114,-115,-116
	dc.b -118,-119,-120,-121,-122,-122,-123,-124,-124,-125,-125,-126,-126,-126,-126,-126
	dc.b -126,-126,-126,-126,-126,-125,-125,-124,-124,-123,-122,-121,-120,-119,-118,-117
	dc.b -116,-115,-113,-112,-110,-109,-107,-105,-104,-102,-100,-98,-96,-94,-92,-90
	dc.b -87,-85,-83,-80,-78,-75,-73,-70,-68,-65,-62,-60,-57,-54,-51,-48
	dc.b -45,-42,-39,-37,-34,-30,-27,-24,-21,-18,-15,-12,-9,-6,-3,0

costable:
	dc.b 127,126,126,126,126,126,125,125,124,123,123,122,121,120,119,118
	dc.b 117,116,114,113,111,110,108,107,105,103,101,99,97,95,93,91
	dc.b 89,87,84,82,80,77,75,72,70,67,64,62,59,56,53,50
	dc.b 48,45,42,39,36,33,30,27,24,21,17,14,11,8,5,2
	dc.b 0,-3,-7,-10,-13,-16,-19,-22,-25,-28,-31,-34,-37,-40,-43,-46
	dc.b -49,-52,-55,-58,-60,-63,-66,-68,-71,-74,-76,-79,-81,-83,-86,-88
	dc.b -90,-92,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-114,-115,-116
	dc.b -117,-118,-120,-121,-121,-122,-123,-124,-124,-125,-125,-126,-126,-126,-126,-126
	dc.b -126,-126,-126,-126,-126,-125,-125,-124,-124,-123,-122,-121,-121,-120,-118,-117
	dc.b -116,-115,-114,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-92,-90
	dc.b -88,-86,-83,-81,-79,-76,-74,-71,-68,-66,-63,-60,-58,-55,-52,-49
	dc.b -46,-43,-40,-37,-34,-31,-28,-25,-22,-19,-16,-13,-10,-7,-3,0
	dc.b 2,5,8,11,14,17,21,24,27,30,33,36,39,42,45,48
	dc.b 50,53,56,59,62,64,67,70,72,75,77,80,82,84,87,89
	dc.b 91,93,95,97,99,101,103,105,107,108,110,111,113,114,116,117
	dc.b 118,119,120,121,122,123,123,124,125,125,126,126,126,126,126,127

M3D_RotatePointX:
    ; d0.b - X
    ; d1.b - Y
    ; d2.b - Z
    ; d3.w - Rotation (0 - 256)

    ; y' = y*cos(r) - z*sin(r)
    ; z' = y*sin(r) + z*cos(r)
    ; x' = x

    moveq  #0x0, d4
    moveq  #0x0, d5
    moveq  #0x0, d6
    moveq  #0x0, d7

    lea    sintable, a2
    lea    costable, a1
    move.b (a2,d3.w), d4 ; Sin(r)
    move.b (a1,d3.w), d5 ; Cos(r)

    ; To word
    ext.w  d1
    ext.w  d2
    ext.w  d4
    ext.w  d5

    move.l d1, a1   ; Backup Y/Z
    move.l d2, a2

    ; Compute Y
    move.w d2, d6   ; Get Z
    muls   d4, d6   ; z*sin(r)
    move.w d1, d7   ; Get Y
    muls   d5, d7   ; y*cos(r)
    sub.w  d6, d7   ; y*cos(r) - z*sin(r)
    asr.w  #7, d7   ; Back in range
    move.b d7, d1	; Y result

    ; Compute Z
    move.l a2, d6   ; Get Z
    muls   d5, d6   ; z*cos(r)
    move.w a1, d7   ; Get Y
    muls   d4, d7   ; y*sin(r)
    add.w  d6, d7   ; y*sin(r) + z*cos(r)
    asr.w  #7, d7   ; Back in range
    move.b d7, d2	; Z result

    rts

M3D_RotatePointY:
    ; d0.b - X
    ; d1.b - Y
    ; d2.b - Z
    ; d3.w - Rotation (0 - 256)

    ; z' = z*cos(r) - x*sin(r)
    ; x' = z*sin(r) + x*cos(r)
    ; y' = y

    moveq  #0x0, d6
    moveq  #0x0, d7

    lea    sintable, a2
    lea    costable, a1
    move.b (a2,d3.w), d4 ; Sin(r)
    move.b (a1,d3.w), d5 ; Cos(r)

    ; To word
    ext.w  d0
    ext.w  d2
    ext.w  d4
    ext.w  d5

    move.l d0, a1   ; Backup X/Z
    move.l d2, a2

    ; Compute X
    move.w d2, d6   ; Get Z
    muls   d4, d6   ; z*sin(r)
    move.w d0, d7   ; Get X
    muls   d5, d7   ; x*cos(r)
    add.w  d7, d6   ; z*sin(r) + x*cos(r)
    asr.w  #7, d6   ; Back in range
    move.b d6, d0	; X result

    ; Compute Z
    move.l a2, d6   ; Get Z
    muls   d5, d6   ; z*cos(r)
    move.l a1, d7   ; Get X
    muls   d4, d7   ; x*sin(r)
    sub.w  d7, d6   ; z*cos(r) - x*sin(r)
    asr.w  #7, d6   ; Back in range
    move.b d6, d2	; Z result

    rts

M3D_RotatePointZ:
    ; d0.b - X
    ; d1.b - Y
    ; d2.b - Z
    ; d3.w - Rotation (0 - 256)

    ; x' = x*cos(r) - y*sin(r)
    ; y' = x*sin(r) + y*cos(r)
    ; z' = z

    moveq  #0x0, d6
    moveq  #0x0, d7

    lea    sintable, a2
    lea    costable, a1
    move.b (a2,d3.w), d4 ; Sin(r)
    move.b (a1,d3.w), d5 ; Cos(r)

    ; To word
    ext.w  d0
    ext.w  d1
    ext.w  d4
    ext.w  d5

    move.l d0, a2   ; Backup X/Y
    move.l d1, a1

    ; Compute X
    move.w d1, d6   ; Get Y
    muls   d4, d6   ; y*sin(r)
    move.w d0, d7   ; Get X
    muls   d5, d7   ; x*cos(r)
    sub.w  d6, d7   ; x*cos(r) - y*sin(r)
    asr.w  #7, d7   ; Back in range
    move.b d7, d0	; X result

    ; Compute Y
    move.l a1, d6   ; Get Y
    muls   d5, d6   ; y*cos(r)
    move.l a2, d7   ; Get X
    muls   d4, d7   ; x*sin(r)
    add.w  d7, d6   ; x*sin(r) + y*cos(r)
    asr.w  #7, d6   ; Back in range
    move.b d6, d1	; Y result

    rts