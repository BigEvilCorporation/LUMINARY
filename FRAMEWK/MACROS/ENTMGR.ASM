; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; ENTMGR.ASM - Entity manager helper macros
; ============================================================================================

ENT_SPAWN_ENTITY: macro entity_name
    ; ======================================
    ; Allocates and spawns a new entity
    ; ======================================
    ; Name - Entity type name
    ; ======================================

    lea    \entity_name\_TypeDesc, a0
    bsr    ENT_SpawnEntity

    endm

ENT_COMPONENT_LIST: macro component_name
    ; ======================================
    ; Defines a component list in mem map
    ; ======================================
    ; component_name - Component name
    ; ======================================
    STRUCT_ALLOC EntityBlockList,EntityBlockList_\component_name
    endm

ENT_COMPONENT_GET_LIST_HEAD: macro component_name, dst_reg
    ; ======================================
    ; Gets a component list head
    ; ======================================
    ; component_name - Component name
    ; dts_reg        - Destination reg
    ; ======================================
    lea    EntityBlockList_\component_name, \dst_reg
    movea.w EntityBlockList_Head(\dst_reg), \dst_reg
    endm