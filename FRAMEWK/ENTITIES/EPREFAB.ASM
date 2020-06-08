; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 8th June 2020
; ============================================================================================
; PREFAB.ASM - Prefabricated group of entities
; ============================================================================================

    STRUCT_BEGIN PrefabData
Prefab_TypeId                         rs.w 1
Prefab_ChildCount                     rs.w 1
Prefab_SpawnTable                     rs.l 1
    STRUCT_END

    ENTITY_SPAWN_DATA_BEGIN EPrefab
SDPrefab_Data                         rs.l 1  ; [TAGS=PREFAB_DATA]
    ENTITY_SPAWN_DATA_END

    ENTITY_BEGIN EPrefab
EPrefab_Data                          rs.l 1
    ENTITY_END

EPrefab_Initialise:
    ; ======================================
    ; EPrefab constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Init

    ; Spawn all child entities
    
    rts

EPrefab_Update:
    ; ======================================
    ; EPrefab update
    ; ======================================
	; a0   Entity
    ; ======================================

    rts

EPrefab_Shutdown:
    ; ======================================
    ; EPrefab destructor
    ; ======================================
	; a0   Entity
    ; ======================================

    ; Destroy all child entities

    rts