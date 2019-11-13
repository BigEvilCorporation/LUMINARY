; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; ENTITY.ASM - Entity and component structure helper macros
; ============================================================================================

    ; ======================================
    ; Begins definition of a named entity's
    ; spawn data
    ; ======================================
    ; Name - Entity name
    ; ======================================
ENTITY_SPAWN_DATA_BEGIN: macro entity_name
__ENTITY_NAME equs "\entity_name\" 
    RSSET  0
    endm

ENTITY_SPAWN_DATA_END: macro
    STRUCT_ALIGN
__SIZEOF_\__ENTITY_NAME\__SPAWNDATA     rs.b 0
    endm

    ; ======================================
    ; Begins definition of a component's
    ; spawn data
    ; ======================================
    ; Name - Entity name
    ; ======================================
COMPONENT_SPAWN_DATA_BEGIN: macro component_name
    ENTITY_SPAWN_DATA_BEGIN \component_name
    endm

COMPONENT_SPAWN_DATA_END: macro
    ENTITY_SPAWN_DATA_END
    endm

ENTITY_BEGIN: macro name
    ; ======================================
    ; Begins definition of a named entity
    ; ======================================
    ; Name - Entity name
    ; ======================================
__ENTITY_NAME equs "\name\"                                         ; Store entity name for ENTITY_END
__ENTITY_COMPONENT_COUNT = 0                                        ; Begin counting components
__COMPONENT_SPAWN_DATA_OFFSET = __SIZEOF_\__ENTITY_NAME\__SPAWNDATA ; Begin counting component spawn data size
ENTITY_\__ENTITY_NAME\_COMPONENT_SLOTDESC_TABLE:                    ; Begin component slot desc table
    RSSET  SIZEOF_EntityBase
	endm

ENTITY_END: macro
    ; ======================================
    ; Ends definition of an entity
    ; ======================================
    ; No params
    ; ======================================
__SIZEOF_\__ENTITY_NAME rs.b 0
    IF __SIZEOF_\__ENTITY_NAME>ENT_MGR_BLOCK_SIZE
    DBG_STATIC_ERROR "Entity type \__ENTITY_NAME\ (%d bytes) exceeds block size (%d bytes)", __SIZEOF_\__ENTITY_NAME, BLDCONF_ENT_BLOCK_SIZE
    ENDIF
ENTITY_\__ENTITY_NAME\_COMPONENT_COUNT          equ __ENTITY_COMPONENT_COUNT

    ; Fill in EntityTypeDesc data
\__ENTITY_NAME\_TypeDesc:
    dc.w   ENTITY_\__ENTITY_NAME\_COMPONENT_COUNT
    dc.l   ENTITY_\__ENTITY_NAME\_COMPONENT_SLOTDESC_TABLE
    dc.l   \__ENTITY_NAME\_Initialise
    dc.l   \__ENTITY_NAME\_Shutdown
    dc.l   \__ENTITY_NAME\_Update
    even
	endm

    ; ======================================
    ; Begins definition of a static
    ; (read-only data) entity
    ; ======================================
    ; Name - Entity name
    ; ======================================
STATIC_ENTITY_BEGIN: macro name
__ENTITY_NAME equs "\name\"
    RSSET  SIZEOF_EntityBase
    endm

STATIC_ENTITY_END: macro
__SIZEOF_\__ENTITY_NAME rs.b 0
    ; Fill in EntityTypeDesc data
\__ENTITY_NAME\_TypeDesc:
    dc.w   0
    dc.l   0
    dc.l   0
    dc.l   0
    dc.l   \__ENTITY_NAME\_Update
    even
    endm

ENTITY_COMPONENT_BEGIN: macro name
    ; ======================================
    ; Begins definition of a named component
    ; ======================================
    ; Name - Component name
    ; ======================================
__COMPONENT_NAME equs "\name\"
    RSSET  SIZEOF_ComponentBase
	endm

ENTITY_COMPONENT_END: macro
    ; ======================================
    ; Ends definition of a component
    ; ======================================
    ; No params
    ; ======================================
__SIZEOF_\__COMPONENT_NAME rs.b 0
    IF __SIZEOF_\__COMPONENT_NAME>ENT_MGR_BLOCK_SIZE
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
    STRUCT_ALIGN
    dc.w   __RS                                         ; Fill in ComponentSlotDesc data
    dc.w   __COMPONENT_SPAWN_DATA_OFFSET
    dc.l   EntityBlockList_\component_name
    dc.l   \component_name\_Initialise
    dc.l   \component_name\_Shutdown
    STRUCT_ALIGN
__ENTITY_COMPONENT_COUNT = __ENTITY_COMPONENT_COUNT+1   ; Increment constructor count
__COMPONENT_SPAWN_DATA_OFFSET = __COMPONENT_SPAWN_DATA_OFFSET+__SIZEOF_\component_name\__SPAWNDATA  ; Offset spawn data ptr
Entity_\__ENTITY_NAME\_Component_\component_name rs.w 1 ; Struct space for component address
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

ENT_GETBOUNDS: macro ent_addr,topleft_reg,bottomright_reg
    ; ======================================
    ; Extracts entity bounding box, in a
    ; format compatible with GEOM_*
    ; routines.
    ; Returns pixel coordinates.
    ; ======================================
    ; In:
    ; ent_addr           - Entity address
    ; ======================================
    ; Out:
    ; topleft_reg.ww     - Top left coord
    ; bottomright_reg.ww - Bottom right coord
    ; ======================================

	; Left
	move.w Entity_PosX(\ent_addr), \topleft_reg	        ; X pos (top word = integer part)
	move.w \topleft_reg, \bottomright_reg			    ; Copy for right
    sub.w  Entity_ExtentsX(\ent_addr), \topleft_reg     ; Left bounds
	
	; Right
	add.w  Entity_ExtentsX(\ent_addr), \bottomright_reg ; Right bounds
	
    swap   \topleft_reg
    swap   \bottomright_reg

	; Top
	move.w Entity_PosY(\ent_addr), \topleft_reg		    ; Y pos (top word = integer part)
	move.w \topleft_reg, \bottomright_reg				; Copy for bottom
    sub.w  Entity_ExtentsY(\ent_addr), \topleft_reg     ; Top bounds
	
	; Bottom
	add.w  Entity_ExtentsY(\ent_addr), \bottomright_reg ; Bottom bounds

	endm