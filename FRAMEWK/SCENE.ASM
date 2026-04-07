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

    STRUCT_BEGIN StampAnim
StampAnim_Name                          rs.b ENT_DEBUG_NAME_LEN
StampAnim_TileSheet                     rs.l 1
StampAnim_Animation                     rs.l 1
StampAnim_TileIndex                     rs.w 1
    STRUCT_END

    STRUCT_BEGIN SceneData
SceneData_StreamingMapFg                rs.l 1 ; StreamingMap
SceneData_StreamingMapBg                rs.l 1 ; StreamingMap
SceneData_ColTileset                    rs.l 1
SceneData_ColStampset                   rs.l 1
SceneData_ColMap                        rs.l 1
SceneData_Palettes                      rs.l 4
SceneData_StaticEntities                rs.l 1
SceneData_DynamicEntities               rs.l 1
SceneData_StampAnimations               rs.l 1
SceneData_ColTileCount                  rs.w 1
SceneData_ColStampCount                 rs.w 1
SceneData_ColMapWidthStamps             rs.w 1
SceneData_ColMapHeightStamps            rs.w 1
SceneData_StaticEntityCount             rs.w 1
SceneData_DynamicEntityCount            rs.w 1
SceneData_StampAnimCount                rs.w 1
    STRUCT_END

    STRUCT_BEGIN SceneEntity
SceneEntity_EntityType                  rs.l 1
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

    ; Pre-stream map
    PUSHM.L a0-a1
    move.l SceneData_StreamingMapFg(a1), a0
    move.l SceneData_StreamingMapBg(a1), a1
    bsr    MAP_PreLoad
    POPM.L a0-a1

    ; Fade in palettes
    PUSHM.L a0-a1
    lea     SceneData_Palettes(a1), a0
    moveq   #0x0, d0
    moveq   #4-1, d1
    @PaletteLp:
    PUSHM.L d0-d1/a0
    move.l  (a0), a0
    move.w  #DEFAULT_PAL_FADE_FRAMES, d1
    bsr     VDP_FadePalette
    POPM.L  d0-d1/a0
    addi.w  #0x1, d0
    adda.w  #SIZE_LONG, a0
    dbra.w  d1, @PaletteLp
    POPM.L a0-a1

    ; Initialise all static entities
    move.w SceneData_StaticEntityCount(a1), d2
    tst.w  d2
    beq    @NoStaticEntities

    move.l SceneData_StaticEntities(a1), a3
    subi.w #0x1, d2

    @StaticEntLp:
    move.l (a3)+, a0                     		; Get entity
    movea.w Entity_TypeDesc(a0), a2      		; Get type desc
    movea.w EntityTypeDesc_Constructor(a2), a2	; Get init func
    PUSHM.L d2/a0-a3
    jsr    (a2)                          		; Call init func
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

    move.l SceneEntity_EntityType(a2), a0   ; Extract entity spawn data
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

    ; Create entities for stamp animations
    move.w SceneData_StampAnimCount(a1), d2
    tst.w  d2
    beq    @NoStampAnims
    move.l SceneData_StampAnimations(a1), a2    ; Get animation table
    subi.w #0x1, d2
    @AnimLp:
    PUSHM.L d2/a2

    ; Calc VRAM handle
    lea    RAM_STREAMING_MAP_A, a3
    move.l StreamingMap_VRAMhndl(a3), d5
    add.w  StampAnim_TileIndex(a2), d5

    ; Alloc temp spawn data on stack
    STACK_ALLOC #ENTITY_EStampAnim_SPAWNDATA_SIZE, a1
    move.l a1, a4

    ; -------- EntitySpawnDataBase
    IFND FINAL
    PUSHM.L a0-a1/d0
    move.l a4, a0
    lea    StampAnim_Name(a2), a1
    move.w #ENT_DEBUG_NAME_LEN, d0
    bsr    STR_CopyA_s                                      ; EntitySpawnData_DebugName
    POPM.L a0-a1/d0
    adda.w #ENT_DEBUG_NAME_LEN, a4
    ENDIF
    move.w #0x0, (a4)+                                      ; EntitySpawnData_Id
    ; -------- EStampAnim
    move.l d5, (a4)+                                        ; SDStampAnim_VRAMHndl
    ; -------- ECSprite
    move.l #0x0, (a4)+                                      ; SDSprite_Actor
    move.l StampAnim_TileSheet(a2), (a4)+                   ; SDSprite_Sheet
    move.l StampAnim_Animation(a2), (a4)+                   ; SDSprite_Animation
    move.b #0x0, (a4)+                                      ; SDSprite_PaletteSlotIdx
    move.b #0x0, (a4)+                                      ; SDSprite_DrawPriority
    move.b #(1<<ECSPRITE_STATE_FLAG_VRAM_UNMANAGED), (a4)+  ; SDSprite_StateFlags
    move.b #0x0, (a4)                                       ; TODO: ALIGN_REG macro?
    ; ------------------

    ; Spawn entity
    moveq  #0x0, d0
    moveq  #0x0, d1
    moveq  #0x0, d2
    moveq  #0x0, d3
    lea    EStampAnim_TypeDesc, a0
    bsr    ENT_SpawnEntity

    STACK_FREE #ENTITY_EStampAnim_SPAWNDATA_SIZE

    POPM.L d2/a2
    adda.l #SIZEOF_StampAnim, a2	; Next animation
    dbra   d2, @AnimLp
    @NoStampAnims:

    rts

    @Err_TooManyEntities:
    DBG_RAISE_ERROR "SCN_LoadScene: Too many entities"

    rts