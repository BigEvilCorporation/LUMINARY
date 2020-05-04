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

	STRUCT_BEGIN EntityBlockList
EntityBlockList_Head					rs.w 1
EntityBlockList_Tail					rs.w 1
EntityBlockList_Size					rs.w 1
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
    ; a0   Entity type desc
    ; a1   Entity spawn data
    ; d0.w Position X
    ; d1.w Position Y
    ; d2.w Width
    ; d3.w Height
    ; ======================================
    ; Out:
    ; a0   Entity addr
    ; ======================================

    lea    RAM_ENTITYMANAGER, a4

    move.l a0, a5

    ; Check enough space free
    move.w EntityTypeDesc_NumComponents(a5), d4	    ; Component count
    addq   #0x1, d4									; +1 for entity
    move.w EntityManager_BlocksFree(a4), d5
    cmp.w  d4, d5
    blt    @Err_NotEnoughBlocks

    ; Alloc block for entity
    PUSHM.W d0-d1
    bsr    ENT_AllocEntityBlock
    POPM.W  d0-d1
    move.l a0, a3

    IFND FINAL
    ; Set debug name
    PUSHM.L a0-a1
    lea    EntityBlock_DebugName(a0), a0
    lea    EntitySpawnData_DebugName(a1), a1
    bsr    STR_CopyA
    POPM.L a0-a1
	ENDIF

    ; Call base constructor
    bsr    Entity_Initialise
    
    PUSH.L a0

    ; Alloc all component blocks and call constructors
    move.w EntityTypeDesc_NumComponents(a5), d0
    movea.w EntityTypeDesc_ComponentSlots(a5), a2
    subi.w #0x1, d0
    @ConstructorLp:
    PUSHM.L a1/a3                                   ; Backup entity and spawn data
    bsr    ENT_AllocEntityBlock                     ; Allocate block for component
    move.w a3, Component_Owner(a0)                  ; Set entity ptr on component
    adda.w ComponentSlotDesc_AddrOffset(a2), a3     ; Get component ptr offset (within entity)
    adda.w ComponentSlotDesc_SpawnDataOffset(a2), a1; Get component spawn data offset (within spawn data)
    move.w a0, (a3)                                 ; Set component ptr on entity
    movea.w ComponentSlotDesc_Constructor(a2), a3   ; Get component constructor addr
    cmpa.w #0x0, a3
    beq    @NoConstructor
    PUSHM.L d0/a0-a5
    jsr    (a3)                                     ; Call component constructor
    POPM.L  d0/a0-a5
    @NoConstructor:
    PUSHM.L d0/a0-a5
    move.l ComponentSlotDesc_LinkedList(a2), a1     ; Add to component list
    bsr    ENT_LinkEntityBlock
    POPM.L d0/a0-a5
    POPM.L a1/a3                                    ; Restore entity and spawn data
    addi.w #SIZEOF_ComponentSlotDesc, a2            ; Next component
    dbra   d0, @ConstructorLp
    
    POP.L  a0

    ; Increment entities allocated
    addi.w #0x1, EntityManager_EntityCount(a4)

    ; Call constructor
    PUSH.L a0
    movea.w EntityTypeDesc_Constructor(a5), a3
    jsr    (a3)
    POP.L  a0

    ; Add to entity list
    lea    EntityBlockList_Entities, a1
    bsr    ENT_LinkEntityBlock

    rts

    @Err_NotEnoughBlocks:
    DBG_RAISE_ERROR "ENT_SpawnEntity: Not enough free blocks"

    rts

ENT_DespawnEntity:
    ; ======================================
    ; Despawns and deallocates an entity
    ; and its components
    ; ======================================
    ; a0   Entity addr
    ; ======================================

    lea    RAM_ENTITYMANAGER, a4

    ; Remove from entity list
    lea    EntityBlockList_Entities, a1
    bsr    ENT_UnlinkEntityBlock

    ; Call destructor
    movea.w Entity_TypeDesc(a0), a1
    movea.w EntityTypeDesc_Destructor(a1), a3
    PUSHM.L a0-a1
    jsr    (a3)
    POPM.L  a0-a1

    ; Free all components
    move.w EntityTypeDesc_NumComponents(a1), d0
    movea.w EntityTypeDesc_ComponentSlots(a1), a2
    subi.w #0x1, d0
    @ComponentLp:
    move.l a0, a3												; Get entity
    adda.w ComponentSlotDesc_AddrOffset(a2), a3                 ; Get component addr offset
    movea.w (a3), a3                                            ; Get component address
    bclr   #ENT_MGR_BLOCK_FLAG_ALLOCATED, EntityBlock_Flags(a3) ; Clear alloc'd flag
    addi.w #0x1, EntityManager_BlocksFree(a4)                   ; Keep count

    ; Unlink from component list
    PUSHM.L d0/a0-a4
    move.l a3, a0
    move.l ComponentSlotDesc_LinkedList(a2), a1
    bsr    ENT_UnlinkEntityBlock
    POPM.L  d0/a0-a4

    ; Call destructor
    PUSHM.L d0/a0-a4
    move.l a3, a0
    movea.w ComponentSlotDesc_Destructor(a2), a3
    cmpa.w #0x0, a3
    beq    @NoDestructor
    jsr    (a3)
    @NoDestructor:
    POPM.L  d0/a0-a4

    adda.w #SIZEOF_ComponentSlotDesc, a2                        ; Next component
    dbra   d0, @ComponentLp

    ; Free entity
    bclr   #ENT_MGR_BLOCK_FLAG_ALLOCATED, EntityBlock_Flags(a0)
    addi.w #0x1, EntityManager_BlocksFree(a4)

    ; Set last free block
    move.w a0, EntityManager_LastFreeBlock(a4)

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

ENT_LinkEntityBlock:
    ; ======================================
    ; Appends an entity/component block to
    ; a linked list
    ; ======================================
    ; a0   Block addr
    ; a1   Linked list
    ; ======================================

	; Sanity check - make sure block isn't already in a list
	IFND FINAL

	; Check block's next ptr is null
	cmp.w  #0x0, EntityBlock_Next(a0)
	beq    @NoNextLink
	DBG_RAISE_ERROR "ENT_LinkEntityBlock: Already in list"
	@NoNextLink:

	; Check block isn't the list head
	move.w EntityBlockList_Head(a1), a2
	cmp.w  a0, a2
	bne    @NotHead
	DBG_RAISE_ERROR "ENT_LinkEntityBlock: Already in list"
	@NotHead:

	; Check block isn't the list tail
	move.w EntityBlockList_Tail(a1), a2
	cmp.w  a0, a2
	bne    @NotTail
	DBG_RAISE_ERROR "ENT_LinkEntityBlock: Already in list"
	@NotTail:

	ENDIF

	; If first in list, set as head and tail
	cmp.w  #0x0, EntityBlockList_Head(a1)
	bne    @HasHead
	move.w a0, EntityBlockList_Head(a1)
	move.w a0, EntityBlockList_Tail(a1)
	bra    @End
	@HasHead:

    ; else if block has a priority, find its place in the list
    tst.b  EntityBlock_Priority(a0)
    beq    @AppendTail
    move.b EntityBlock_Priority(a0), d0
    movea.w EntityBlockList_Head(a1), a2
    move.l #0x0, a3
    @PrioFindLp:
    cmp.b  EntityBlock_Priority(a2), d0
    ble    @Next
    move.w a2, EntityBlock_Next(a0)                     ; Steal next link
    cmpa.w #0x0, a3                                     ; If no prev, we're the new head
    beq    @NewHead
    move.w a0, EntityBlock_Next(a3)                     ; Set ourself as new next link
    bra    @NotNewHead
    @NewHead:
    move.w a0, EntityBlockList_Head(a1)                 ; Set ourself as new head
    @NotNewHead:
    cmp.w  #0x0, EntityBlock_Next(a2)                   ; If no next, we're also the new tail
    bne    @End
	move.w a0, EntityBlockList_Tail(a1)
    bra    @End
    @Next:
    movea.w a2, a3
    movea.w EntityBlock_Next(a2), a2
    bne    @PrioFindLp                                  ; If end of list, append to tail
    @AppendTail:
	
	; else link to current tail, then set as current tail
	move.w EntityBlockList_Tail(a1), a2
	move.w a0, EntityBlock_Next(a2)
	move.w a0, EntityBlockList_Tail(a1)
	
	@End:
	
	; Increment count
	addq.w #0x1, EntityBlockList_Size(a1)
	
	rts

ENT_UnlinkEntityBlock:
    ; ======================================
    ; Removes an entity/component block from
    ; a linked list
    ; ======================================
    ; a0   Block addr
    ; a1   Linked list
    ; ======================================

	move.w  #0x0, a2
	
	move.w EntityBlockList_Head(a1), a3	; Get list head
	@BlockLp:						    ; For all blocks in list
	cmp.w  a0, a3						; Check if block to remove
	beq    @Found
	move.w a3, a2						; Backup prev
	move.w EntityBlock_Next(a3), a3	    ; Get next ptr
	bra    @BlockLp

	; Error, block wasn't in this list
	IFND FINAL
    DBG_RAISE_ERROR "ENT_UnlinkEntityBlock: Not in list"
    ELSE
    rts
	ENDIF
	
	@Found:
	
	; Check if new head
	cmp.w  #0x0, a2
	beq    @NewHead
	
	; Link next with prev
	move.w EntityBlock_Next(a0), EntityBlock_Next(a2)
	bra    @EndLink
	
	@NewHead:
	
	; Removed block was head, set new head
	move.w EntityBlock_Next(a0), EntityBlockList_Head(a1)
	
	@EndLink:
	
	; Check if new tail
	cmp.w   #0x0, EntityBlock_Next(a0)
	bne     @NotTail
	
	; Removed block was tail, set new tail
	move.w  a2, EntityBlockList_Tail(a1)
	
	@NotTail:
	
	; Clear removed block's next link
	move.w #0x0, EntityBlock_Next(a0)

	; Decrement count
	subq.w #0x1, EntityBlockList_Size(a1)
	
	rts

ENT_UpdateAll:
    ; ======================================
    ; Updates all entities, calling
    ; [EntityName]_Update on each
    ; ======================================
    ; No params
    ; ======================================

    ; Update all static entities
    ; TODO: Only update entities in active grid
    move.l RAM_SCENE_DATA, a2
    move.w SceneData_StaticEntityCount(a2), d2
    tst.w  d2
    beq    @NoStaticEntities

    move.l SceneData_StaticEntities(a2), a3
    subi.w #0x1, d2

    @StaticEntLp:
    move.l (a3)+, a0                    ; Get entity
    movea.w Entity_TypeDesc(a0), a1     ; Get type desc
    movea.w EntityTypeDesc_Update(a1), a1; Get update func
    PUSHM.L d2/a0-a3
    jsr    (a1)                         ; Update
    POPM.L  d2/a0-a3
    dbra   d2, @StaticEntLp

    @NoStaticEntities:

    ; Update all dynamic entities
    lea    EntityBlockList_Entities, a0
    movea.w EntityBlockList_Head(a0), a0
    cmp.w  #0x0, a0
    beq    @NoDynamicEntities

    @DynamicEntLp:
    movea.w EntityBlock_Next(a0), a2    ; Get next entity first, update can call destructor
    movea.w Entity_TypeDesc(a0), a1     ; Get type desc
    movea.w EntityTypeDesc_Update(a1), a1; Get update func
    PUSHM.L a0-a2
    jsr    (a1)                         ; Update
    POPM.L  a0-a2
    move.l a2, a0
    cmp.w  #0x0, a0
    bne    @DynamicEntLp

    @NoDynamicEntities:

    rts

ENT_FindFirstOfType:
    ; ======================================
    ; Linear search for an instantiated
    ; entity by its Entity_TypeDesc
    ; ======================================
    ; In:
    ;  a0   Entity_TypeDesc
    ; Out:
    ;  a1   Entity
    ; ======================================

    movea.w #0x0, a1

    lea     EntityBlockList_Entities, a1
    movea.w EntityBlockList_Head(a1), a1
    cmp.w  #0x0, a1
    beq     @NoDynamicEntities

    @DynamicEntLp:
    cmp.w  Entity_TypeDesc(a1), a0
    beq    @Found
    movea.w EntityBlock_Next(a1), a1
    cmp.w  #0x0, a1
    bne    @DynamicEntLp

    @NoDynamicEntities:
    @Found:

    rts

ENT_DebugDrawMemory:
    ; ======================================
    ; Draw entity allocator debug info to
    ; plane A
    ; ======================================
    ; d0.w Draw X pos (cells)
    ; d1.w Draw Y pos (cells)
    ; ======================================

    lea    RAM_ENTITYMANAGER, a0
    move.w #ENT_MGR_MAX_BLOCKS, d2
    sub.w  EntityManager_BlocksFree(a0), d2
    mulu.w #ENT_MGR_BLOCK_SIZE, d2
    DBG_DRAW_WORD_A d0,d1,d2

    rts