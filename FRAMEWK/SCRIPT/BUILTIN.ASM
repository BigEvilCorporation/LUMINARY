; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 15th December 2019
; ============================================================================================
; BUILTIN.ASM - Built-in script actions
; ============================================================================================

SCR_ScreenFadeUp:
    ; ======================================
    ; SCRIPT ACTION
    ; Fade screen up
    ; ======================================
	; a0   ScriptState
    ; a1   Entity
    ; d0.l Fade speed
    ; ======================================
    moveq  #0x0, d0
    rts

SCR_ScreenFadeDown:
    ; ======================================
    ; SCRIPT ACTION
    ; Fade screen down
    ; ======================================
	; a0   ScriptState
    ; a1   Entity
    ; d0.l Fade speed
    ; d1.l Fade colour
    ; ======================================
    moveq  #0x1, d0
    rts

    SCRIPT_ACTION SCREEN_FADE_UP,SCR_ScreenFadeUp,speed
    SCRIPT_ACTION SCREEN_FADE_DN,SCR_ScreenFadeDown,speed,colour

    ; Script params
    SCRIPT_PARAMS_BEGIN TestScript
    ;SCR_PARAM Player1
    SCRIPT_PARAM FadeColour
    SCRIPT_PARAM FadeSpeed
    SCRIPT_PARAMS_END

    ; Script setup
    SCRIPT_SETUP_BEGIN TestScript
    ;ENTITY_FIND EPlayer,ent62,a1        ; Find player entity
    ;SCRIPT_PARAM_LOAD Player1,a1
    SCRIPT_PARAM_LOAD FadeColour,#0x01234567  ; Fade colour
    SCRIPT_PARAM_LOAD FadeSpeed,#0x89ABCDEF       ; Fade speed
    SCRIPT_SETUP_END	

    ; Script
    SCRIPT_BEGIN TestScript
    SCRIPT SCREEN_FADE_DN,FadeSpeed,FadeColour
    SCRIPT SCREEN_FADE_UP,FadeSpeed
    SCRIPT_END
