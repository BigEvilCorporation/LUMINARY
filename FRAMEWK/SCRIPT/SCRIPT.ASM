; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 15th December 2019
; ============================================================================================
; SCRIPT.ASM - A bytecode scripting system built using macros
; ============================================================================================

    STRUCT_BEGIN ScriptState
ScriptState_Data                        rs.l 1              ; The script
ScriptState_PC                          rs.l 1              ; Program Counter
ScriptState_Params                      rs.l SCR_MAX_PARAMS ; Params table
    STRUCT_END

ScriptState_Run:
    ; ======================================
    ; Begins executing a script
    ; ======================================
	; a0   ScriptState
    ; ======================================

    ; Setup routine in first longword
    move.l ScriptState_Data(a0), a1
    move.l (a1)+, a2
    move.l a1, ScriptState_PC(a0)       ; Set initial PC
    PUSH.L a0
    jsr    (a2)
    POP.L  a0

    rts

ScriptState_Update:
    ; ======================================
    ; Ticks a running script
    ; ======================================
	; a0   ScriptState
    ; a1   Owning entity
    ; ======================================

    ; Decode next action
    move.l ScriptState_PC(a0), a5
    moveq  #0x0, d0
    moveq  #0x0, d1
    move.b (a5)+, d0                        ; Get action index

    ; Get action address and num params from table
    mulu.w #SIZEOF_ScriptAction, d0         ; Index to table offset
    lea    SECT(SECTION_SCRIPT_TABLE), a2   ; Get script table
    add.l  d0, a2                           ; Offset into table
    move.l (a2)+, a3                        ; Get routine address
    move.w (a2)+, d1                        ; Get num params

    ; Read action params
    mulu.w #(ScriptState_ReadParams_7-ScriptState_ReadParams_8), d1
    move.l #ScriptState_ReadParams_0, a4	; Offset into routine to fetch correct number of params
    suba.l d1, a4
    lea    ScriptState_Params(a0), a2
    PUSH.L a0
    jsr    (a4)                             ; Read params
    POP.L  a0

    ; Call routine
    PUSHM.L a0/a5
    jsr    (a3)
    POPM.L  a0/a5

    ; Advance routine if finished
    tst.b  d0
    beq    @NoAdvance
    move.l a5, ScriptState_PC(a0)
    @NoAdvance:

    rts

SCRIPTSTATE_READPARAM: macro data,table,output
    moveq  #0x0, \output                ; Clear output reg
    move.b (\data\)+, \output           ; Read param index from script data
    add.w  \output, \output             ; To longwords
    add.w  \output, \output
    move.l (\table\,\output\.w), \output; Read longword from table
    endm

ScriptState_ReadParams:
    ; ======================================
    ; Reads action param indices from script
    ; data, then reads longword params from
    ; table
    ; ======================================
    ; 0-8 params from d0-d7
    ; ======================================
    ; a1   Script data
    ; a2   Script params table
    ; ======================================
ScriptState_ReadParams_8:
    SCRIPTSTATE_READPARAM a1,a2,d7
ScriptState_ReadParams_7:
    SCRIPTSTATE_READPARAM a1,a2,d6
ScriptState_ReadParams_6:
    SCRIPTSTATE_READPARAM a1,a2,d5
ScriptState_ReadParams_5:
    SCRIPTSTATE_READPARAM a1,a2,d4
ScriptState_ReadParams_4:
    SCRIPTSTATE_READPARAM a1,a2,d3
ScriptState_ReadParams_3:
    SCRIPTSTATE_READPARAM a1,a2,d2
ScriptState_ReadParams_2:
    SCRIPTSTATE_READPARAM a1,a2,d1
ScriptState_ReadParams_1:
    SCRIPTSTATE_READPARAM a1,a2,d0
ScriptState_ReadParams_0:
    rts