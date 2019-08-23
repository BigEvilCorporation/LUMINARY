; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 4th August 2019
; ============================================================================================
; MEMMAP.ASM - Memory map for Luminary Game Framework
; ============================================================================================

    rsset  RAM_FRAMEWORK_START

    ; Entity manager
    STRUCT_ALLOC EntityManager,RAM_ENTITYMANAGER

    ; Entity list
    ENT_COMPONENT_LIST Entities

    ; Entity component lists
    ENT_COMPONENT_LIST ECSprite
    ENT_COMPONENT_LIST ECPhysicsBody

    ; Scene
RAM_SCENE_CURRENT                       rs.l 1
RAM_SCENE_DATA                          rs.l 1

    ; Camera
RAM_CAMERA_CURRENT                  	rs.l 1
    STRUCT_ALLOC Camera,RAM_CAMERA_DEFAULT

RAM_GAME_START                          rs.b 0

    ; Keep entity table in upper 32kb, so movea.w
    ; sign extends to RAM addr
    rsset (STACK_TOP-STACK_SIZE)-(ENT_MGR_BLOCK_SIZE*ENT_MGR_MAX_BLOCKS)
RAM_ENTITYBLOCKTABLE                    rs.b (ENT_MGR_BLOCK_SIZE*ENT_MGR_MAX_BLOCKS)