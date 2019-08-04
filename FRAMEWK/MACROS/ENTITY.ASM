; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; ENTITY.ASM - Entity and component structure helper macros
; ============================================================================================

    ; ======================================
    ; Entity spawn description, auto-generated
    ; by ENTITY_BEGIN/ENTITY_END.
    ; Do not build directly.
    ; ======================================
    STRUCT_BEGIN EntitySpawnDesc
EntitySpawnDesc_NumComponents           rs.w 1
EntitySpawnDesc_ConstructorTable        rs.l 1
    STRUCT_END

ENTITY_BEGIN: macro name
    ; ======================================
    ; Begins definition of a named entity
    ; ======================================
    ; Name - Entity name
    ; ======================================
__ENTITY_NAME equs "\name\"                     ; Store entity name for ENTITY_END
__ENTITY_COMPONENT_COUNT = 0                    ; Begin counting components
ENTITY_\__ENTITY_NAME\_COMPONENT_CONSTRUCTOR_TABLE:    ; Begin component constructor table
Entity_ListNext                         rs.w 1
Entity_BlockId                          rs.w 1
Entity_PosX                             rs.l 1
Entity_PosY                             rs.l 1
Entity_Flags                            rs.w 1
	endm

ENTITY_END: macro
    ; ======================================
    ; Ends definition of an entity
    ; ======================================
    ; No params
    ; ======================================
__SIZEOF_\__ENTITY_NAME rs.b 0
    IF __SIZEOF_\__ENTITY_NAME>BLDCONF_ENT_BLOCK_SIZE
    DBG_STATIC_ERROR "Entity type \__ENTITY_NAME\ (%d bytes) exceeds block size (%d bytes)", __SIZEOF_\__ENTITY_NAME, BLDCONF_ENT_BLOCK_SIZE
    ENDIF
ENTITY_\__ENTITY_NAME\_COMPONENT_COUNT          equ __ENTITY_COMPONENT_COUNT

    ; Entity spawn descriptor
Entity_\__ENTITY_NAME\_SpawnDesc:
    dc.w   ENTITY_\__ENTITY_NAME\_COMPONENT_COUNT
    dc.l   ENTITY_\__ENTITY_NAME\_COMPONENT_CONSTRUCTOR_TABLE
    even
	endm

ENTITY_COMPONENT_BEGIN: macro name
    ; ======================================
    ; Begins definition of a named component
    ; ======================================
    ; Name - Component name
    ; ======================================
__COMPONENT_NAME equs "\name\"
    rsset 0
\__COMPONENT_NAME\_ListNext             rs.w 1
\__COMPONENT_NAME\_BlockId              rs.w 1
	endm

ENTITY_COMPONENT_END: macro
    ; ======================================
    ; Ends definition of a component
    ; ======================================
    ; No params
    ; ======================================
__SIZEOF_\__COMPONENT_NAME rs.b 0
    IF __SIZEOF_\__COMPONENT_NAME>BLDCONF_ENT_BLOCK_SIZE
    DBG_STATIC_ERROR "Component type \__COMPONENT_NAME\ (%d bytes) exceeds block size (%d bytes)", __SIZEOF_\__COMPONENT_NAME, BLDCONF_ENT_BLOCK_SIZE
    ENDIF
	endm

ENT_COMPONENT: macro component_name
    ; ======================================
    ; Allocates a named component within an
    ; entity structure.
    ; (within ENTITY_BEGIN/ENTITY_END)
    ; ======================================
    ; Name - Component name
    ; ======================================
__ENTITY_COMPONENT_COUNT = __ENTITY_COMPONENT_COUNT+1   ; Increment constructor count
    dc.l   \component_name\_Initialise                  ; Add constructor to table
Entity_\__ENTITY_NAME\_Component_\component_name rs.w 1
    endm

ENT_GETCOMPONENT: macro entity_name,component_name,entity_addr,addr_reg
    ; ======================================
    ; Fetches a component address within
    ; an entity.
    ; ======================================
    ; In:
    ; entity_name    - Name of entity type
    ; component_name - Name of component type
    ; entity_addr    - Entity address
    ; ======================================
    ; Out:
    ; addr_reg       - Component address
    ; ======================================
    movea.w Entity_\entity_name\_Component_\component_name\(\entity_addr\), \addr_reg
    endm