; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 6th August 2019
; ============================================================================================
; SCENE.ASM - Scene loading routines
; ============================================================================================

    STRUCT_BEGIN Scene
Scene_EntityCount                       rs.w 1
Scene_SpawnedEntities                   rs.w SCN_MAX_ENTITIES
    STRUCT_END

    STRUCT_BEGIN SceneData
SceneData_GfxTileset                    rs.l 1
SceneData_GfxStampset                   rs.l 1
SceneData_GfxMapFg                      rs.l 1
SceneData_GfxMapBg                      rs.l 1
SceneData_ColTileset                    rs.l 1
SceneData_ColStampset                   rs.l 1
SceneData_ColMap                        rs.l 1
SceneData_Palettes                      rs.l 1
SceneData_StaticEntities                rs.l 1
SceneData_DynamicEntities               rs.l 1
SceneData_GfxTileCount                  rs.w 1
SceneData_GfxStampCount                 rs.w 1
SceneData_GfxMapFgWidthStamps           rs.w 1
SceneData_GfxMapFgHeightStamps          rs.w 1
SceneData_GfxMapBgWidthStamps           rs.w 1
SceneData_GfxMapBgHeightStamps          rs.w 1
SceneData_ColTileCount                  rs.w 1
SceneData_ColStampCount                 rs.w 1
SceneData_ColMapWidthStamps             rs.w 1
SceneData_ColMapHeightStamps            rs.w 1
SceneData_PaletteCount                  rs.w 1
SceneData_StaticEntityCount             rs.w 1
SceneData_DynamicEntityCount            rs.w 1
    STRUCT_END

    STRUCT_BEGIN SceneEntity
SceneEntity_EntityType                  rs.w 1
SceneEntity_SpawnData                   rs.l 1
SceneEntity_PosX                        rs.w 1
SceneEntity_PosY                        rs.w 1
SceneEntity_ExtentsX                    rs.w 1
SceneEntity_ExtentsY                    rs.w 1
    STRUCT_END

SCN_LoadScene:
    ; ======================================
    ; Loads a scene from SceneData data,
    ; and spawns all entities
    ; ======================================
	; a0   Scene
    ; a1   SceneData
    ; ======================================

    ; Set as current scene
    move.l a0, RAM_SCENE_CURRENT
    move.l a1, RAM_SCENE_DATA

    ; Pre-stream FG map
    PUSHM.L a0-a1
    move.w SceneData_GfxTileCount(a1), d0
    move.w SceneData_GfxStampCount(a1), d1
    move.w SceneData_GfxMapFgWidthStamps(a1), d2
    move.w SceneData_GfxMapFgHeightStamps(a1), d3
    move.w SceneData_GfxMapBgWidthStamps(a1), d4
    move.w SceneData_GfxMapBgHeightStamps(a1), d5
    move.l SceneData_GfxStampset(a1), a2
    move.l SceneData_GfxTileset(a1), a3
    move.l SceneData_GfxMapFg(a1), a0
    move.l SceneData_GfxMapBg(a1), a1
    bsr    MAP_PreLoad
    POPM.L a0-a1

    ; Load palettes
    PUSHM.L a0-a1
    move.w SceneData_PaletteCount(a1), d0
    move.l SceneData_Palettes(a1), a0
    bsr    VDP_LoadPalettes
    POPM.L a0-a1

    ; Initialise all static entities
    move.w SceneData_StaticEntityCount(a1), d2
    tst.w  d2
    beq    @NoStaticEntities

    move.l SceneData_StaticEntities(a1), a3
    subi.w #0x1, d2

    @StaticEntLp:
    move.l (a3)+, a0                    ; Get entity
    movea.w Entity_TypeDesc(a0), a2      ; Get type desc
    movea.w EntityTypeDesc_Constructor(a2), a2; Get init func
    PUSHM.L d2/a0-a3
    jsr    (a2)                         ; Update
    POPM.L  d2/a0-a3
    dbra   d2, @StaticEntLp

    @NoStaticEntities:

    ; Spawn all dynamic entities
    move.w SceneData_DynamicEntityCount(a1), d2
    tst.w  d2
    beq    @NoDynamicEntities
    cmp.w  #SCN_MAX_ENTITIES, d2
    bgt    @Err_TooManyEntities

    move.l SceneData_DynamicEntities(a1), a2; Get dynamic entity table
    lea    Scene_SpawnedEntities(a0), a3    ; Get output ptr table
    subi.w #0x1, d2
    @EntityLp:
    PUSHM.L d2/a0-a3

    movea.w SceneEntity_EntityType(a2), a0   ; Extract entity spawn data
    move.l SceneEntity_SpawnData(a2), a1
    move.w SceneEntity_PosX(a2), d0
    move.w SceneEntity_PosY(a2), d1
    move.w SceneEntity_ExtentsX(a2), d2
    move.w SceneEntity_ExtentsY(a2), d3
    bsr    ENT_SpawnEntity                  ; Spawn entity
    move.l a0, a4
    
    POPM.L d2/a0-a3
    move.w a4, (a3)+                        ; Store ptr
    adda.l #SIZEOF_SceneEntity, a2          ; Next entity
    dbra   d2, @EntityLp

    @NoDynamicEntities:

    rts

    @Err_TooManyEntities:
    DBG_RAISE_ERROR "SCN_LoadScene: Too many entities"

    rts