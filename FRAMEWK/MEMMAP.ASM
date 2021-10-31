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
    ENT_COMPONENT_LIST ECScript
    ENT_COMPONENT_LIST ECSprite
    ENT_COMPONENT_LIST ECPhysBodyChar
    ENT_COMPONENT_LIST ECPhysBodyBasic
    ENT_COMPONENT_LIST ECPlatform

    ; Scene
RAM_SCENE_CURRENT                       rs.l 1
RAM_SCENE_DATA                          rs.l 1

    ; Camera
RAM_CAMERA_CURRENT                  	rs.l 1
    STRUCT_ALLOC Camera,RAM_CAMERA_DEFAULT

; Dialog system
RAM_DIALOG_VRAM_BUFFER                  rs.l 1  ; VRAM buffer for dialog text
RAM_DIALOG_STRING_LEN                   rs.w 1  ; Current string length
RAM_DIALOG_TYPEWRITER_LEN               rs.w 1  ; Current string length being drawn
RAM_DIALOG_TYPEWRITER_TIMER             rs.w 1  ; Frames until next character
RAM_DIALOG_WAIT_INPUT                   rs.b 1  ; Currently waiting for user input
RAM_DIALOG_LAST_CHOICE                  rs.b 1  ; Last choice selected by user
    STRUCT_ALIGN

; Yarn
RAM_YARN_ENTRY_ADDR                     rs.l 1  ; Re-entry address into a script after an rts
RAM_YARN_STACK                          rs.l YARN_STACK_SIZE_L ; Yarn stack
RAM_YARN_STACK_PTR                      rs.l 1  ; Current stack ptr
RAM_YARN_FONT                           rs.l 1  ; Address of current font
RAM_YARN_STATE                          rs.b 1  ; Current state
    STRUCT_ALIGN

    STRUCT_ALIGN
RAM_GAME_START                          rs.b 0

    ; Keep entity table in upper 32kb, so movea.w
    ; sign extends to RAM addr
    rsset (STACK_TOP-STACK_SIZE)-(ENT_MGR_BLOCK_SIZE*ENT_MGR_MAX_BLOCKS)
RAM_ENTITYBLOCKTABLE                    rs.b (ENT_MGR_BLOCK_SIZE*ENT_MGR_MAX_BLOCKS)