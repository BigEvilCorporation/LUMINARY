; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 8th December 2019
; ============================================================================================
; PLATFORM.ASM - Physics platform
; ============================================================================================

    COMPONENT_SPAWN_DATA_BEGIN ECPlatform
    COMPONENT_SPAWN_DATA_END
    
    ENTITY_COMPONENT_BEGIN ECPlatform
ECPlatform_VelX                         rs.l 1
ECPlatform_VelY                         rs.l 1
    ENTITY_COMPONENT_END