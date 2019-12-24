; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 4th August 2019
; ============================================================================================
; CONSTS.ASM - Global constants for Luminary Game Framework code
; ============================================================================================

; Entity manager
ENT_MGR_BLOCK_SIZE                      equ BLDCONF_ENT_MGR_BLOCK_SIZE
ENT_MGR_MAX_BLOCKS                      equ BLDCONF_ENT_MGR_BLOCK_MAX_BLOCKS
ENT_MGR_BLOCK_FLAG_ALLOCATED            equ 0x1

; Scene manager
SCN_MAX_ENTITIES                        equ BLDCONF_SCN_MAX_ENTITIES

; Script system
SCR_MAX_ACTIONS                         equ 256
SCR_MAX_PARAMS                          equ 8

; Physics
PHYS_VEL_TO_GROUND_SPEED_SHIFT          equ 8
PHYS_GRAVITY_Y                          equ BLDCONF_PHYS_GRAVITY_Y
PHYS_STEP_HEIGHT                        equ 0x04
PHYS_GROUND_SPEED_TO_VEL                equ 0x0100
PHYS_DEFAULT_SLOPE_FACTOR               equ 0x2000>>PHYS_VEL_TO_GROUND_SPEED_SHIFT
PHYS_SLOPE_MIN                          equ 0x10
PHYS_TERRAIN_ANGLE_90                   equ 0x40
PHYS_TERRAIN_SEARCH_QUADRANT_DOWN       equ 0
PHYS_TERRAIN_SEARCH_QUADRANT_RIGHT      equ 1
PHYS_TERRAIN_SEARCH_QUADRANT_UP         equ 2
PHYS_TERRAIN_SEARCH_QUADRANT_LEFT       equ 3
PHYS_TERRAIN_FLAG_CLOSE_TO_FLOOR        equ 0
PHYS_TERRAIN_SNAP_TO_FLOOR              equ 1
PHYS_TERRAIN_DUAL_PROBES                equ 1

    IF PHYS_TERRAIN_DUAL_PROBES
PHYS_TERRAIN_PROBE_OFFSET               equ 0x0009
    ELSE
PHYS_TERRAIN_PROBE_OFFSET               equ 0x0000
    ENDIF

PHYS_DEFAULT_MAX_VEL_X                  equ 0x00080000
PHYS_DEFAULT_MAX_VEL_Y                  equ 0x00100000