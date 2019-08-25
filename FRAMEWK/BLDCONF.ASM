; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; BLDCONF.ASM - Game framework build config - override with BLDCONF_FRAMEWORK_CUSTOM_DEFINED
; ============================================================================================

    IFND BLDCONF_FRAMEWORK_CUSTOM_DEFINED

; Entity/component system block size
BLDCONF_ENT_MGR_BLOCK_SIZE              equ 32
BLDCONF_ENT_MGR_BLOCK_MAX_BLOCKS        equ 256

; Scene config
BLDCONF_SCN_MAX_ENTITIES                equ 64

; Physics
BLDCONF_PHYS_GRAVITY                    equ 0x00003800
BLDCONF_COLLISION_TILE_WIDTH            equ 8
BLDCONF_COLLISION_TILE_HEIGHT           equ 8

    ENDIF
