; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 15th December 2019
; ============================================================================================
; SCRIPT.ASM - Macros for defining a script and script actions
; ============================================================================================
; Script action:
;  An assembly routine to be called from script. Can have up to 8 longword params, d0-d7.
; Script param:
;  A named longword parameter, assembles to a byte index.
; Script setup:
;  An assembly routine that matches param byte indices to longwords, run before the script begins.
; Script:
;  The script itself, calling script actions passing script params.
; ============================================================================================

    STRUCT_BEGIN ScriptAction
ScriptAction_Routine                    rs.l 1
ScriptAction_NumArgs                    rs.w 1
    STRUCT_END

; ============================================================================================
; SCRIPT ACTIONS
; ============================================================================================

    ; Current action counter for SCRIPT_ACTION
__SCRIPT_ACTION_TBL_IDX = 0

SCRIPT_ACTION: macro ; name,routine,...
    ; ======================================
    ; Defines a script action and adds it
    ; to the actions table
    ; ======================================
    ; name         Script action name
    ; routine      Routine address
    ; ...          Variable params
    ; ======================================
    ; e.g.:
    ; SCRIPT_ACTION SCREEN_FADE_DN,SCR_ScreenFadeDown,speed,colour
    ; ======================================
__SCRIPT_ACTION_TBL_IDX_\1              equ __SCRIPT_ACTION_TBL_IDX
__SCRIPT_ACTION_NUM_PARAMS_\1           equ narg-2
    PUSHS                               ; Enter script table section
    Section    SECTION_SCRIPT_TABLE
    dc.l \2                             ; Append routine address
    dc.w __SCRIPT_ACTION_NUM_PARAMS_\1  ; Append num args
    POPS
__SCRIPT_ACTION_TBL_IDX = __SCRIPT_ACTION_TBL_IDX+1
    endm

; ============================================================================================
; SCRIPT PARAMS
; ============================================================================================

SCRIPT_PARAMS_BEGIN: macro name
    ; ======================================
    ; Begins a script parameter block
    ; ======================================
    ; name       Script name
    ; ======================================
__SCRIPT_NAME equs "\name\"
__SCRIPT_PARAM_TBL_IDX = 0
    endm

SCRIPT_PARAMS_END: macro
    ; ======================================
    ; End a script parameter block
    ; ======================================
    ; No params
    ; ======================================
    endm

SCRIPT_PARAM: macro name
    ; ======================================
    ; Defines a named parameter ready for
    ; use in script, assigns to a byte index
    ; ======================================
    ; name       Script param name
    ; ======================================
    IF (__SCRIPT_PARAM_TBL_IDX+1=SCR_MAX_PARAMS)
    DBG_STATIC_ERROR "SCRIPT \__SCRIPT_NAME\: TOO MANY SCRIPT PARAMS"
    ENDIF
__SCRIPT_PARAM_IDX_\__SCRIPT_NAME\_\name\   equ __SCRIPT_PARAM_TBL_IDX
__SCRIPT_PARAM_TBL_IDX = __SCRIPT_PARAM_TBL_IDX+1
    endm

; ============================================================================================
; SCRIPT SETUP
; ============================================================================================

SCRIPT_SETUP_BEGIN: macro name
    ; ======================================
    ; Begins a script setup routine
    ; ======================================
    ; name       Script name
    ; ======================================
__SCRIPT_NAME equs "\name\"
__SCRIPT_SETUP_ROUTINE_\name\:
    endm

SCRIPT_SETUP_END: macro
    ; ======================================
    ; End a script setup routine
    ; ======================================
    ; No params
    ; ======================================
    rts
    endm

SCRIPT_PARAM_LOAD: macro name,value
    ; ======================================
    ; Assigns a value to a script param
    ; ======================================
    ; name       Parameter name
    ; value      Parameter value
    ; a0         ScriptState
    ; ======================================
    IFND   __SCRIPT_PARAM_IDX_\__SCRIPT_NAME\_\name
    DBG_STATIC_ERROR "SCRIPT \__SCRIPT_NAME\ PARAM \2\ NOT DEFINED"
    ENDIF
    move.l \value, ScriptState_Params+(__SCRIPT_PARAM_IDX_\__SCRIPT_NAME\_\name*SIZE_LONG)(a0)
    endm

; ============================================================================================
; SCRIPT
; ============================================================================================

SCRIPT_BEGIN: macro name
    ; ======================================
    ; Begins a script
    ; ======================================
    ; name       Script  name
    ; ======================================
__SCRIPT_NAME equs "\name\"
__SCRIPT_DATA_\name\:
    dc.l   __SCRIPT_SETUP_ROUTINE_\name\    ; First longword is script setup routine
    endm

SCRIPT_END: macro
    ; ======================================
    ; Ends a script
    ; ======================================
    ; No params
    ; ======================================
    even
__SCRIPT_DATA_SIZE_\__SCRIPT_NAME         equ *-__SCRIPT_DATA_\__SCRIPT_NAME\
    endm

SCRIPT: macro ;action,params...
    ; ======================================
    ; Runs a script action
    ; ======================================
    ; action     Script action name
    ; params...  Variable params list
    ; ======================================
    IF !(__SCRIPT_ACTION_NUM_PARAMS_\1\=(NARG-1))
    DBG_STATIC_ERROR "SCRIPT '\__SCRIPT_NAME\' ROUTINE '\1\': INVALID PARAM COUNT (required: %d, provided: %d)",__SCRIPT_ACTION_NUM_PARAMS_\1,NARG-1
    ENDIF
    dc.b   __SCRIPT_ACTION_TBL_IDX_\1           ; Opcode
    REPT   (NARG-1)                             ; Loop through params
    IFND   __SCRIPT_PARAM_IDX_\__SCRIPT_NAME\_\2
    DBG_STATIC_ERROR "SCRIPT \__SCRIPT_NAME\ PARAM \2\ NOT DEFINED"
    ENDIF
    dc.b   __SCRIPT_PARAM_IDX_\__SCRIPT_NAME\_\2    ; Param
    SHIFT                                       ; Drop param
    ENDR
    endm

SCRIPT_GET_DATA: macro name,output
    ; ======================================
    ; Get script data address
    ; ======================================
    ; name     Script name
    ; output   Output reg
    ; ======================================
    move.l #__SCRIPT_DATA_\name\, output
    endm

SCRIPT_DATA_DC: macro name
    ; ======================================
    ; Sets script data address as dc.l
    ; ======================================
    ; name     Script name
    ; ======================================
    dc.l   __SCRIPT_DATA_\name
    endm

; ============================================================================================
; Sample script
; ============================================================================================

    ; Script params
    ;SCRIPT_PARAMS_BEGIN TestScript
    ;SCR_PARAM Player1
    ;SCRIPT_PARAM Red
    ;SCRIPT_PARAM FadeSpeed
    ;SCRIPT_PARAMS_END

    ; Script setup
    ;SCRIPT_SETUP_BEGIN TestScript
    ;ENTITY_FIND EPlayer,ent62,a0        ; Find player entity
    ;SCRIPT_PARAM_LOAD Player1,a0
    ;SCRIPT_PARAM_LOAD Red,0x0F00        ; Fade colour
    ;SCRIPT_PARAM_LOAD FadeSpeed,16      ; Fade speed
    ;SCRIPT_SETUP_END

    ; Script
    ;SCRIPT_BEGIN TestScript
    ;SCRIPT SCREEN_FADE_DN,FadeSpeed,Colour
    ;SCRIPT_END