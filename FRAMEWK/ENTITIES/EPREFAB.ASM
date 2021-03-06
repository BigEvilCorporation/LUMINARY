; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 8th June 2020
; ============================================================================================
; PREFAB.ASM - Prefabricated group of entities
; ============================================================================================

EPREFAB_MAXCHILDREN                   equ (ENT_MGR_BLOCK_SIZE-SIZEOF_EntityBase-SIZE_LONG)/SIZE_WORD

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
EPrefab_Children                      rs.w EPREFAB_MAXCHILDREN
    ENTITY_END

EPrefab_Initialise:
    ; ======================================
    ; EPrefab constructor
    ; ======================================
	; a0   Entity
    ; a1   Entity spawn data
    ; ======================================

    ; Init
    move.l SDPrefab_Data(a1), a1
    move.l a1, EPrefab_Data(a0)

    ; Spawn all child entities
    move.w Prefab_ChildCount(a1), d2
    tst.w  d2
    beq    @NoChildren

    ; Position offset
    move.w Entity_PosX(a0), d4
    move.w Entity_PosY(a0), d5

    move.l Prefab_SpawnTable(a1), a2        ; Get entity table
    lea    EPrefab_Children(a0), a3         ; Get instance list
    subi.w #0x1, d2
    @EntityLp:
    PUSHM.L d2-d5/a0-a3

    movea.w SceneEntity_EntityType(a2), a0  ; Extract entity spawn data
    move.l SceneEntity_SpawnData(a2), a1
    move.w SceneEntity_PosX(a2), d0
    move.w SceneEntity_PosY(a2), d1
    move.w SceneEntity_ExtentsX(a2), d2
    move.w SceneEntity_ExtentsY(a2), d3
    add.w  d4, d0                           ; Relative to world pos
    add.w  d5, d1
    bsr    ENT_SpawnEntity                  ; Spawn entity
    move.l a0, a4
    
    POPM.L d2-d5/a0-a3
    move.w a4, (a3)+                        ; Store ptr
    adda.l #SIZEOF_SceneEntity, a2          ; Next entity
    dbra   d2, @EntityLp

    @NoChildren:
    
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
    move.l EPrefab_Data(a0), a1
    lea    EPrefab_Children(a0), a2
    move.w Prefab_ChildCount(a1), d2
    tst.w  d2
    beq    @NoChildren
    subi.w #0x1, d2
    @EntityLp:

    move.w (a2)+, a0

    PUSHM.L d2/a0-a2
    bsr    ENT_DespawnEntity
    POPM.L d2/a0-a2

    dbra   d2, @EntityLp

    @NoChildren:

    rts