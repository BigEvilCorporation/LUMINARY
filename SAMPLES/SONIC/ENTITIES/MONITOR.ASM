; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 23rd February 2026
; ============================================================================================
; MONITOR.ASM - Sonic 1 breakable monitor object
; ============================================================================================

MONITOR_SCREEN_Y_OFFS   equ -0x2

; Monitor spawn data
    ENTITY_SPAWN_DATA_BEGIN SDMonitor
    ENTITY_SPAWN_DATA_END

; Monitor entity
    ENTITY_BEGIN EMonitor
    ENT_COMPONENT_NAMED ECSprite,Base
    ENT_COMPONENT_NAMED ECSprite,Image
    ENT_COMPONENT ECEnemy
    ENTITY_END

EMonitor_Initialise:
    ; ======================================
    ; EMonitor constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Set image Y offset
    ENT_GETCOMPONENT EMonitor,Image,a0,a2
    move.b #MONITOR_SCREEN_Y_OFFS, ECSprite_PosY(a2)

    rts

EMonitor_Shutdown:
    rts

EMonitor_Update:
    ; ======================================
    ; EMonitor movement path update
    ; ======================================
	; a0   Entity
    ; ======================================

    rts
