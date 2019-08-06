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
    ; ======================================
    ; Out:
    ; a0   Entity addr
    ; ======================================

    lea    RAM_ENTITYMANAGER, a4

    move.l a0, a5

    ; Check enough space free
    move.w EntityTypeDesc_NumComponents(a5), d0	; Component count
    addq   #0x1, d0									; +1 for entity
    move.w EntityManager_BlocksFree(a4), d1
    cmp.w  d0, d1
    blt    @Err_NotEnoughBlocks

    ; Alloc block for entity
    bsr    ENT_AllocEntityBlock
    move.l a0, a3

    ; Set type desc
    move.l a5, Entity_TypeDesc(a0)
    
    PUSH.L a0

    ; Alloc all component blocks and call constructors
    move.w EntityTypeDesc_NumComponents(a5), d0
    move.l EntityTypeDesc_ComponentSlots(a5), a2
    subi.w #0x1, d0
    @ConstructorLp:
    PUSHM.L a1/a3                                   ; Backup entity and spawn data
    bsr    ENT_AllocEntityBlock                     ; Allocate block for component
    move.w a3, Component_Owner(a0)                  ; Set entity ptr on component
    add.w  ComponentSlotDesc_AddrOffset(a2), a3     ; Get component ptr offset (within entity)
    add.w  ComponentSlotDesc_SpawnDataOffset(a2), a1; Get component spawn data offset (within spawn data)
    move.w a0, (a3)                                 ; Set component ptr on entity
    move.l ComponentSlotDesc_Constructor(a2), a3    ; Get component constructor addr
    PUSHM.L d0/a0-a5
    jsr    (a3)                                     ; Call component constructor
    POPM.L  d0/a0-a5
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
    move.l EntityTypeDesc_Constructor(a5), a3
    jsr    (a3)

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
    move.l Entity_TypeDesc(a0), a1
    move.l EntityTypeDesc_Destructor(a1), a3
    PUSHM.L a0-a1
    jsr    (a3)
    POPM.L  a0-a1

    ; Free all components
    move.w EntityTypeDesc_NumComponents(a1), d0
    move.l EntityTypeDesc_ComponentSlots(a1), a2
    subi.w #0x1, d0
    @ComponentLp:
    move.l a0, a3												; Get entity
    add.w  ComponentSlotDesc_AddrOffset(a2), a3                 ; Get component addr offset
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
    move.l ComponentSlotDesc_Destructor(a2), a3
    jsr    (a3)
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

    lea    EntityBlockList_Entities, a0
    movea.w EntityBlockList_Head(a0), a0
    cmp.w  #0x0, a0
    beq    @NoEntities

    @EntLp:
    movea.w EntityBlock_Next(a0), a2    ; Get next entity first, update can call destructor
    move.l Entity_TypeDesc(a0), a1      ; Get type desc
    move.l EntityTypeDesc_Update(a1), a1; Get update func
    PUSHM.L a0-a2
    jsr    (a1)                         ; Update
    POPM.L  a0-a2
    move.l a2, a0
    cmp.w  #0x0, a0
    bne    @EntLp

    @NoEntities:

    rts