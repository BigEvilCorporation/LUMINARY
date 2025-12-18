; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 8th June 2020
; ============================================================================================
; PREFAB.ASM - Prefabricated group of entities
; ============================================================================================

EPREFAB_MAXCHILDREN                   equ (ENT_MGR_BLOCK_SIZE-SIZEOF_EntityBlockData)/SIZE_WORD

    STRUCT_BEGIN PrefabData
Prefab_TypeId                         rs.w 1
Prefab_ChildCount                     rs.w 1
Prefab_SpawnTable                     rs.l 1
    STRUCT_END

    ENTITY_SPAWN_DATA_BEGIN EPrefab
SDPrefab_Data                         rs.l 1  ; [TAGS=PREFAB_DATA]
    ENTITY_SPAWN_DATA_END

    STRUCT_INHERIT EPrefabChildList,EntityBlockData
EPrefabChildList_Children             rs.w EPREFAB_MAXCHILDREN
    STRUCT_END

    ENTITY_BEGIN EPrefab
EPrefab_Data                          rs.l 1
EPrefab_Children                      rs.w 1
    ENT_COMPONENT ECAnimation
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

	move.w #EPREFAB_MAXCHILDREN, d1
    cmp.w  d2, d1
    bgt    @CountOk
    DBG_RAISE_ERROR "EPrefab_Initialise: Too many children"
    @CountOk:

    ; Create child block
    PUSH.L a0
    bsr    ENT_AllocEntityBlock
    move.l a0, a3
    POP.L  a0
    move.w a3, EPrefab_Children(a0)

    ; Position offset
    move.w Entity_PosX(a0), d4
    move.w Entity_PosY(a0), d5

    move.l  Prefab_SpawnTable(a1), a2        ; Get entity table
    lea     EPrefabChildList_Children(a3), a3; Get instance list      
    subi.w  #0x1, d2
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

    ; Set entity list on anim component
    move.w  Prefab_ChildCount(a1), d2
    ENT_GETCOMPONENT EPrefab,ECAnimation,a0,a1
    movea.w EPrefab_Children(a0), a2
    lea     EPrefabChildList_Children(a2), a2   
    move.w  a2, ECAnimation_ActorList(a1)
    move.w  a0, ECAnimation_RootActor(a1)
    move.w  d2, ECAnimation_ActorCount(a1)
    
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
    move.l  EPrefab_Data(a0), a1
    movea.w EPrefab_Children(a0), a2
    lea     EPrefabChildList_Children(a2), a2   
    move.w  Prefab_ChildCount(a1), d2
    tst.w   d2
    beq     @NoChildren
    subi.w  #0x1, d2
    @EntityLp:

    move.w (a2)+, a0

    PUSHM.L d2/a0-a2
    bsr    ENT_DespawnEntity
    POPM.L d2/a0-a2

    dbra   d2, @EntityLp

    ; Free child list block
    PUSH.L  a0
    movea.w EPrefab_Children(a0), a0
    bsr     ENT_FreeEntityBlock
    POP.L   a0

    @NoChildren:

    rts