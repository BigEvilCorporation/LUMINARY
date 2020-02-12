; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 15th December 2019
; ============================================================================================
; SCRIPT.ASM - A bytecode scripting system built using macros
; ============================================================================================

    ; 'this' structure passed to script routines
    STRUCT_BEGIN ScriptObject
ScriptObject_Entity                     rs.l 1  ; Entity& entity;
ScriptObject_ComponentTable             rs.l 1  ; Components& components;
    STRUCT_END

    STRUCT_BEGIN ScriptState
ScriptState_Data                        rs.l 1  ; The script
ScriptState_FuncStart                   rs.w 1  ; Offset to start routine
ScriptState_FuncShutdown                rs.w 1  ; Offset to shutdown routine
ScriptState_FuncUpdate                  rs.w 1  ; Offset to update routine
ScriptState_ThisObject                  rs.b SIZEOF_ScriptObject
    STRUCT_END

ScriptState_Run:
    ; ======================================
    ; Begins executing a script
    ; ======================================
	; a0   ScriptState
    ; a1   Owning entity
    ; ======================================

    ; Populate 'this'
    lea    ScriptState_ThisObject(a0), a2
    move.l a1, ScriptObject_Entity(a2)
    move.l a1, ScriptObject_ComponentTable(a2)

	move.w #0x0, d0
    movea.w Entity_TypeDesc(a1), a3     ; Get address of first component offset
    movea.w EntityTypeDesc_ComponentSlots(a3), a3
    move.w  ComponentSlotDesc_AddrOffset(a3), d0
    add.l  d0, ScriptObject_ComponentTable(a2)

    move.l ScriptState_Data(a0), a3
    adda.w ScriptState_FuncStart(a0), a3
    PUSH.L a2                           ; this
    jsr    (a3)                         ; ::Start()
    POP.L  a2

    rts

ScriptState_Update:
    ; ======================================
    ; Ticks a running script
    ; ======================================
	; a0   ScriptState
    ; a1   Owning entity
    ; ======================================

    move.l ScriptState_Data(a0), a3
    adda.w ScriptState_FuncUpdate(a0), a3
    lea    ScriptState_ThisObject(a0), a2

    PUSH.L a2                           ; this
    jsr    (a3)                         ; ::Update()
    POP.L  a2

    rts
