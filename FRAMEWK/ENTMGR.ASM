; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 4th August 2019
; ============================================================================================
; ENTMGR.ASM - Entity spawning, despawning, and block management
; ============================================================================================

    STRUCT_BEGIN EntityManager
EntityManager_LastFreeBlock             rs.w 1
EntityManager_EntityCount               rs.w 1
EntityManager_BlocksFree                rs.w 1
    STRUCT_END

ENT_Initialise:
    ; ======================================
    ; Initialises entity manager
    ; ======================================
    ; No params
    ; ======================================

    lea    RAM_ENTITYMANAGER, a0
    move.w #RAM_ENTITYBLOCKTABLE&0xFFFF, EntityManager_LastFreeBlock(a0)
    move.w #0x0, EntityManager_EntityCount(a0)
    move.w #ENT_MGR_MAX_BLOCKS, EntityManager_BlocksFree(a0)

    rts

ENT_SpawnEntity:
    ; ======================================
    ; Allocates and spawns an entity and
    ; its components
    ; ======================================
    ; In:
    ; a0   Entity spawn desc
    ; ======================================
    ; Out:
    ; a0   Entity addr
    ; ======================================

    move.l a0, a1

    ; Check enough space free
    lea    RAM_ENTITYMANAGER, a4
    move.w EntitySpawnDesc_NumComponents(a1), d0	; Component count
    addq   #0x1, d0									; +1 for entity
    move.w EntityManager_BlocksFree(a4), d1
    cmp.w  d0, d1
    blt    @Err_NotEnoughBlocks

    ; Alloc block for entity
    bsr    ENT_AllocEntityBlock
    move.l a0, a3

    ; Alloc all component blocks and call constructors
    move.w EntitySpawnDesc_NumComponents(a1), d0
    move.l EntitySpawnDesc_ConstructorTable(a1), a2
    subi.w #0x1, d0
    @ConstructorLp:
    PUSH.L a3                           ; Backup entity
    bsr    ENT_AllocEntityBlock         ; Allocate block for component
                                        ; TODO: Insert into entity (add entity component offset to table)
    add.w  (a2)+, a3                    ; Component addr offset
    move.w a0, (a3)                     ; Set component address on entity
    move.l (a2)+, a3                    ; Get component constructor addr
    PUSHM.L d0/a0-a4
    jsr    (a3)                         ; Call component constructor
    POPM.L  d0/a0-a4
    POP.L  a3                           ; Restore entity
    dbra   d0, @ConstructorLp

    ; Increment entities allocated
    addi.w #0x1, EntityManager_EntityCount(a4)

    rts

    @Err_NotEnoughBlocks:
    DBG_RAISE_ERROR "ENT_SpawnEntity: Not enough free blocks"

    rts

ENT_DespawnEntity:
    ; ======================================
    ; Despawns and deallocates and entity
    ; and its components
    ; ======================================
    ; a0   Entity addr
    ; ======================================

    rts

ENT_AllocEntityBlock:
    ; ======================================
    ; Allocates an entity/component block
    ; ======================================
    ; Out:
    ; a0   Block addr
    ; ======================================

    lea RAM_ENTITYMANAGER, a4

    ; Check last free block first
    movea.w EntityManager_LastFreeBlock(a4), a0
    cmp.w  #0xFFFF, a0
    bne    @Found

    ; Search all blocks checking ENT_MGR_BLOCK_FLAG_ALLOCATED flag
    lea    RAM_ENTITYBLOCKTABLE, a0
    move.w #ENT_MGR_MAX_BLOCKS-1, d5
    @SearchLp:
    btst   #ENT_MGR_BLOCK_FLAG_ALLOCATED, EntityBlock_Flags(a0)
    beq    @Found
    adda.w #ENT_MGR_BLOCK_SIZE, a0
    dbra   d5, @SearchLp
    bra    @Err_NoFreeBlocks

    @Found:

    ; Set allocated flag
    bset   #ENT_MGR_BLOCK_FLAG_ALLOCATED, EntityBlock_Flags(a0)

    ; Keep count
    subi.w #0x1, EntityManager_BlocksFree(a4)

    ; Invalidate last free block
    move.w #0xFFFF, EntityManager_LastFreeBlock(a4)

    rts

    @Err_NoFreeBlocks:
    DBG_RAISE_ERROR "ENT_AllocEntityBlock: No free blocks"

    rts

ENT_FreeEntityBlock:
    ; ======================================
    ; Frees an entity/component block
    ; ======================================
    ; a0   Block addr
    ; ======================================

    rts