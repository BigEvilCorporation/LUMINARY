; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 15th December 2019
; ============================================================================================
; SCRIPT.ASM - A bytecode scripting system built using macros
; ============================================================================================

    STRUCT_BEGIN ScriptState
ScriptState_Data                        rs.l 1  ; The script
ScriptState_FuncStart                   rs.w 1  ; Offset to start routine
ScriptState_FuncShutdown                rs.w 1  ; Offset to shutdown routine
ScriptState_FuncUpdate                  rs.w 1  ; Offset to update routine
    STRUCT_END

ScriptState_Run:
    ; ======================================
    ; Begins executing a script
    ; ======================================
	; a0   ScriptState
    ; a1   Owning entity
    ; ======================================

    move.l ScriptState_Data(a0), a3
    adda.w ScriptState_FuncStart(a0), a3
    PUSH.L RAM_SCENE_DATA               ; Scene& scene
    pea    ScriptGlobal_Engine          ; Engine& engine
    PUSH.L a1                           ; this
    jsr    (a3)                         ; ::Start()
    adda.l #0xC, sp

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
    PUSH.L RAM_SCENE_DATA               ; Scene& scene
    pea    ScriptGlobal_Engine          ; Engine& engine
    PUSH.L a1                           ; this
    jsr    (a3)                         ; ::Update()
    adda.l #0xC, sp

    rts
