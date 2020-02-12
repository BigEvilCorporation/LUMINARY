; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 15th December 2019
; ============================================================================================
; SCRIPT.ASM - Script entity component
; ============================================================================================

    COMPONENT_SPAWN_DATA_BEGIN ECScript
SDScript_ScriptData                     rs.l 1  ; [TAGS=SCRIPT_DATA]
SDScript_FuncStart                      rs.w 1  ; [TAGS=SCRIPTFUNC_OnStart]
SDScript_FuncShutdown                   rs.w 1  ; [TAGS=SCRIPTFUNC_OnShutdown]
SDScript_FuncUpdate                     rs.w 1  ; [TAGS=SCRIPTFUNC_OnUpdate]
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECScript
    STRUCT_ALLOC ScriptState,ECScript_ScriptState
    ENTITY_COMPONENT_END

ECScript_Initialise:
    ; ======================================
    ; ECScript constructor
    ; ======================================
	; a0   Component
    ; a1   Component spawn data
    ; ======================================
    
    PUSH.L a0

    ; Get owning entity
    movea.w Component_Owner(a0), a2
    
    ; Get state
    lea    ECScript_ScriptState(a0), a0
    
    ; Set script data
    move.l SDScript_ScriptData(a1), ScriptState_Data(a0)
    move.l SDScript_FuncStart(a1), ScriptState_FuncStart(a0)
    move.l SDScript_FuncShutdown(a1), ScriptState_FuncShutdown(a0)
    move.l SDScript_FuncUpdate(a1), ScriptState_FuncUpdate(a0)

    ; Run script
    move.l a2, a1
    bsr    ScriptState_Run
    
    POP.L  a0

    rts

ECScript_Shutdown:
    ; ======================================
    ; ECScript destructor
    ; ======================================
	; a0   Component
    ; ======================================

    rts

ECScript_StepAll:
    ; ======================================
    ; Ticks all script components' scripts
    ; ======================================
	; No params
    ; ======================================

    ENT_COMPONENT_GET_LIST_HEAD ECScript, a3
    cmp.w  #0x0, a3
    beq    @NoScripts

    @ScriptLp:
    lea    ECScript_ScriptState(a3), a0 ; Get script
    movea.w Component_Owner(a3), a1     ; Get owning entity
    PUSH.L a3
    bsr    ScriptState_Update           ; Tick
    POP.L  a3
    movea.w EntityBlock_Next(a3), a3    ; Next component
    cmp.w  #0x0, a3
    bne    @ScriptLp

    @NoScripts:

    rts