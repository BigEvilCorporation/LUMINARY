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

; Physics
PHYS_GRAVITY_Y                          equ BLDCONF_PHYS_GRAVITY_Y
PHYS_STEP_HEIGHT                        equ 0x04
PHYS_GROUND_SPEED_TO_VEL                equ 0x0100
PHYS_TERRAIN_ANGLE_90                   equ 0x40
PHYS_TERRAIN_SEARCH_QUADRANT_DOWN       equ 0
PHYS_TERRAIN_SEARCH_QUADRANT_RIGHT      equ 1
PHYS_TERRAIN_SEARCH_QUADRANT_UP         equ 2
PHYS_TERRAIN_SEARCH_QUADRANT_LEFT       equ 3
PHYS_TERRAIN_FLAG_CLOSE_TO_FLOOR        equ 0

PHYS_DEFAULT_MAX_GROUND_SPEED           equ 0x0800
PHYS_DEFAULT_MAX_VEL_Y                  equ 0x0010