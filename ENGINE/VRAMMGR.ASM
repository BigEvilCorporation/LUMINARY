; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; VRAM.ASM - VRAM memory allocator
; ============================================================================================
; Manages VRAM pools, allowing for arbitrary sized blocks of tiles to be allocated and freed.
; ============================================================================================

VRAM_MGR_MAX_ALLOCATIONS                equ 256
VRAM_MGR_BIT_ALLOCATED                  equ 15	
VRAM_MGR_SIZE_MASK                      equ 0x7FFF

    STRUCT_BEGIN VRAMBlock
VRAMBlock_Addr                          rs.w 1  ; Address of block
VRAMBlock_SizeFlags                     rs.w 1  ; Size and alloc flags
VRAMBlock_Prev                          rs.w 1  ; Prev block in table
VRAMBlock_Next                          rs.w 1  ; Next block in table
    IF BLDCONF_VRAM_MGR_DEBUG
VRAMBlock_DebugAllocAddr                rs.l 1  ; Address of callee to Alloc()
    ENDIF
    STRUCT_END

    STRUCT_BEGIN VRAMManager
VRAMManager_BlockTable                  rs.b (SIZEOF_VRAMBlock*VRAM_MGR_MAX_ALLOCATIONS)
VRAMManager_PoolAddr                    rs.w 1
VRAMManager_PoolSize                    rs.w 1
VRAMManager_TilesFree                   rs.w 1
;VRAMManager_LastFreeHandle              rs.w 1
    STRUCT_END

VRAM_BLOCK_IDX_TO_ADDR: macro idxreg
    add.l  a0,\idxreg
    addi.l #VRAMManager_BlockTable,\idxreg
    endm

VRAM_BLOCK_ADDR_TO_IDX: macro idxreg
    sub.l  a0,\idxreg
    subi.l #VRAMManager_BlockTable,\idxreg
    endm

VRAM_ERROR: macro string
    bsr    ERR_ResetForError
    lea    @err_string\@, a0
    bsr    ERR_DrawMessage
    lea    RAM_VRAM_MANAGER, a0
    bsr    VRAMMGR_DrawTable
    bra    *
    @err_string\@:
    dc.b   \string\,0
    even
    endm

VRAMMGR_Initialise:
    ; ======================================
    ; Initialises a VRAM manager
    ; ======================================
    ; No params
    ; ======================================

    lea    RAM_VRAM_MANAGER, a0
    lea    VRAMManager_BlockTable(a0), a1
    move.w #(SIZEOF_VRAMBlock*VRAM_MGR_MAX_ALLOCATIONS), d0
    MEMZERO.B a1,d0

    move.w #0x0, VRAMManager_PoolAddr(a0)
    move.w #0x0, VRAMManager_PoolSize(a0)
    move.w #0x0, VRAMManager_TilesFree(a0)
    ;move.w #0xFFFF, VRAMManager_LastFreeHandle(a0)

    ; TODO: Take initial pools from table
    move.w #0x0000, d0
    move.w #0xB000/SIZE_TILE_B, d1
    bsr    VRAMMGR_AddPool

    rts

VRAMMGR_AddPool:
    ; ======================================
    ; Adds a pool to a VRAM manager
    ; ======================================
    ; d0.w Memory pool address (tiles)
    ; d1.w Memory pool size (tiles)
    ; ======================================

    lea    RAM_VRAM_MANAGER, a0

    ; TODO: Multiple pools
    move.w d0, VRAMManager_PoolAddr(a0)
    move.w d1, VRAMManager_PoolSize(a0)
    move.w d1, VRAMManager_TilesFree(a0)

    ; Initialise as the one and only free block
    lea    VRAMManager_BlockTable(a0), a1
    move.w d0, VRAMBlock_Addr(a1)
    move.w d1, VRAMBlock_SizeFlags(a1)
    move.w #0x0, VRAMBlock_Prev(a1)
    move.w #0x0, VRAMBlock_Next(a1)

    rts

VRAMMGR_Alloc:
    ; ======================================
    ; Allocates a block of VRAM tiles
    ; ======================================
    ; In:
    ; d0.w Allocation size (tiles)
    ; ======================================
    ; Out:
    ; d1.l Allocation handle
    ;       hi word - bookkeeping data
    ;       lo word - address (tiles)
    ; ======================================

    IF BLDCONF_VRAM_MGR_DEBUG
    ; Take address of call site for debugging
    move.l (sp), a6
    ENDIF

    lea    RAM_VRAM_MANAGER, a0

    ; Check if enough memory free
    cmp.w  VRAMManager_TilesFree(a0), d0
    bgt    @Err_OutOfMem

    ; Iterate blocks to find a free one of sufficient size
    lea    VRAMManager_BlockTable(a0), a1
    move.l a1, a5
    adda.w #(SIZEOF_VRAMBlock*VRAM_MGR_MAX_ALLOCATIONS)-SIZEOF_VRAMBlock, a5
    subi.l #SIZEOF_VRAMBlock, a1
    move.l #-SIZEOF_VRAMBlock, d4
    @SearchLp:
    adda.w #SIZEOF_VRAMBlock, a1        ; Next block
    addi.w #SIZEOF_VRAMBlock, d4        ; Next offset
    move.w VRAMBlock_SizeFlags(a1), d2  ; Get size and flags
    btst   #VRAM_MGR_BIT_ALLOCATED, d2  ; Check if free
    bne    @SearchLp
    andi.w #VRAM_MGR_SIZE_MASK, d2      ; Mask size
    cmp.w  d0, d2                       ; Too small?
    beq    @ExactSize
    bgt    @FoundBlock
    cmp.l  a1, a5      					; If not end of list, keep searching
    bne    @SearchLp
    bra    @Err_OutOfMem                ; Out of memory

    ; Found block, split it up
    @FoundBlock:
    move.w d0, VRAMBlock_SizeFlags(a1)  ; Set new size of this block

	move.l #0x0, a2
    move.w VRAMBlock_Next(a1), d5       ; Get next block
    beq    @NewTableEntry               ; End of table?
    move.w d5, a2
    VRAM_BLOCK_IDX_TO_ADDR a2

    ; Resize next block in table (or add a new entry)
    btst   #VRAM_MGR_BIT_ALLOCATED, VRAMBlock_SizeFlags(a2) ; If next block free
    beq    @NextBlockFree               ; If next block is allocated, need a new table entry
    @NewTableEntry:
    move.w d5, d6                       ; Backup next block
    move.l a2, a3
    bsr    VRAMMGR_GetTableEntry    ; Find/alloc new table entry
    move.w d4, VRAMBlock_Prev(a2)       ; Attach to left neighbour (a1)
    move.w d5, VRAMBlock_Next(a1)      
    tst.w  d6
    beq    @NoNext
    move.w d6, VRAMBlock_Next(a2)       ; Attach to right neighbour (a3)
    move.w d5, VRAMBlock_Prev(a3)
    @NoNext:
                                        
    @NextBlockFree:
    sub.w  d0, d2                       ; Set size of next block
    move.w d2, VRAMBlock_SizeFlags(a2)
    move.w VRAMBlock_Addr(a1), VRAMBlock_Addr(a2) ; Set address of next block
    add.w  d0, VRAMBlock_Addr(a2)

    IF BLDCONF_VRAM_MGR_DEBUG
    move.w VRAMBlock_Addr(a2), d6
    move.w VRAMManager_PoolAddr(a0), d5
    cmp.w  d6, d5
    bgt    @Err_BadNewAddr
    add.w  VRAMManager_PoolSize(a0), d5
    cmp.w  d6, d5
    blt    @Err_BadNewAddr
    ENDIF

    @ExactSize:                         ; Found block is exact size, nothing to change

    ; Set block as allocated and populate handle
    swap   d4
    move.w VRAMBlock_Addr(a1), d4       ; Get address
    bset   #VRAM_MGR_BIT_ALLOCATED, VRAMBlock_SizeFlags(a1) ; Set allocated flag
    move.l d4, d1                       ; Return value

    ; Keep count
    sub.w  d0, VRAMManager_TilesFree(a0)

    ; Store callee
    IF BLDCONF_VRAM_MGR_DEBUG
    move.l a6, VRAMBlock_DebugAllocAddr(a1)
    ENDIF

    rts

    @Err_OutOfMem:
    move.w VRAMManager_TilesFree(a0), d6
    VRAM_ERROR "VRAM_MGR: Out of VRAM"

    IF BLDCONF_VRAM_MGR_DEBUG

    @Err_BadNewAddr:
    VRAM_ERROR "VRAM_MGR: Block out of range"

    ENDIF

    rts

VRAMMGR_Free:
    ; ======================================
    ; Frees a block of VRAM tiles
    ; ======================================
    ; In:
    ; d0.l Memory handle
    ; ======================================

    lea    RAM_VRAM_MANAGER, a0

    ; Get table entry
    move.w d0, d1                       ; Backup addr
    move.w #0x0, d0
    swap   d0
    move.w d0, d3                       ; Backup idx
    move.l d0, a1
    VRAM_BLOCK_IDX_TO_ADDR a1

    ; Sanity check - must be allocated
    IF BLDCONF_VRAM_MGR_DEBUG
    btst   #VRAM_MGR_BIT_ALLOCATED, VRAMBlock_SizeFlags(a1)
    beq    @Err_NotAllocd
    ENDIF

    ; Sanity check - handle address must match table entry
    IF BLDCONF_VRAM_MGR_DEBUG
    move.w VRAMBlock_Addr(a1), d2
    cmp.w  d1, d2
    bne    @Err_BadAddr
    ENDIF

    ; Mark as free
    bclr   #VRAM_MGR_BIT_ALLOCATED, VRAMBlock_SizeFlags(a1)

    ; Keep count
    move.w VRAMBlock_SizeFlags(a1), d4
    andi.w #VRAM_MGR_SIZE_MASK, d4
    add.w  d4, VRAMManager_TilesFree(a0)

    ; Sanity check - freed size must not exceed pool size
    IF BLDCONF_VRAM_MGR_DEBUG
    move.w VRAMManager_PoolSize(a0), d4
    cmp.w  VRAMManager_TilesFree(a0), d4
    blt    @Err_ExceededPoolSize
    ENDIF

    ; Get right neighbour
    tst.w  VRAMBlock_Next(a1)
    beq    @NoNext
    move.w VRAMBlock_Next(a1), d4
    move.l #0x0, a2
    move.w d4, a2
    VRAM_BLOCK_IDX_TO_ADDR a2

    ; If right neighbour is free, merge it into this block
    btst   #VRAM_MGR_BIT_ALLOCATED, VRAMBlock_SizeFlags(a2)
    bne    @NoNext
    move.l a1, a3
    move.w d0, d5
    bsr    VRAMMGR_MergeRightNeighbour

    @NoNext:

    ; Get left neighbour
    move.w VRAMBlock_Prev(a1), d5
    cmp.w  d5, d3
    beq    @NoPrev
    move.l #0x0, a3
    move.w d5, a3
    VRAM_BLOCK_IDX_TO_ADDR a3

    ; If left neighbour is free, merge this block into it
    btst   #VRAM_MGR_BIT_ALLOCATED, VRAMBlock_SizeFlags(a3)
    bne    @NoPrev
    bsr    VRAMMGR_MergeRightNeighbour

    @NoPrev:

    rts

    IF BLDCONF_VRAM_MGR_DEBUG

    @Err_NotAllocd:
    VRAM_ERROR "VRAM_MGR: Block not allocated"

    @Err_BadAddr:
    VRAM_ERROR "VRAM_MGR: Address mismatch"

    @Err_ExceededPoolSize:
    VRAM_ERROR "VRAM_MGR: Exceeded pool size"

    ENDIF  ; BLDCONF_VRAM_MGR_DEBUG

    rts

VRAMMGR_GetTableEntry:
    ; ======================================
    ; Finds or creates a new tracking entry
    ; ======================================
    ; In:
    ; a0   VRAM Manager
    ; Out:
    ; d5.w Table entry offset
    ; a2   Table entry addr
    ; ======================================

    lea    VRAMManager_BlockTable(a0), a2
    move.l a2, a5
    adda.w #(SIZEOF_VRAMBlock*VRAM_MGR_MAX_ALLOCATIONS), a5
    moveq  #0x0, d5
    @SearchLp:
    tst.w  VRAMBlock_SizeFlags(a2)
    beq    @Found
    addi.w #SIZEOF_VRAMBlock, d5
    adda.w #SIZEOF_VRAMBlock, a2
    cmp.l  a5, a2
    bne    @SearchLp

    @Err_OutOfHandles:
    VRAM_ERROR "VRAM_MGR: Out of table space"

    @Found:

    rts

VRAMMGR_MergeRightNeighbour:
    ; ======================================
    ; Merges right-hand neighbour into this
    ; block, and invalidates it
    ; ======================================
    ; In:
    ; a0   VRAM Manager
    ; Out:
    ; d5.w Table entry offset
    ; a3   Table entry addr
    ; ======================================
    ; Block must have a right-hand neighbour
    ; Block must be freed
    ; Right neighbour must be freed
    ; ======================================

    ; Sanity check - block must be free
    IF BLDCONF_VRAM_MGR_DEBUG
    btst   #VRAM_MGR_BIT_ALLOCATED, VRAMBlock_SizeFlags(a3)
    bne    @Err_Allocd
    ENDIF
    
    ; Sanity check - block must have right-hand neighbour
    IF BLDCONF_VRAM_MGR_DEBUG
    tst.w  VRAMBlock_Next(a3)
    beq    @Err_NoNeighbour
    ENDIF

    ; Get right-hand neighbour
    move.l #0x0, a2
    move.w VRAMBlock_Next(a3), a2
    VRAM_BLOCK_IDX_TO_ADDR a2

    ; Sanity check - neighbour must be free
    IF BLDCONF_VRAM_MGR_DEBUG
    btst   #VRAM_MGR_BIT_ALLOCATED, VRAMBlock_SizeFlags(a2)
    bne    @Err_NeighbourAllocd
    ENDIF

    ; Merge size
    move.w VRAMBlock_SizeFlags(a2), d6
    andi.w #VRAM_MGR_SIZE_MASK, d6
    add.w  d6, VRAMBlock_SizeFlags(a3)

    ; Get neighbour's next
    moveq  #0x0, d2
    move.w VRAMBlock_Next(a2), d2

    ; Invalidate neighbour
    move.w #0x0000, VRAMBlock_Addr(a2)
    move.w #0x0000, VRAMBlock_SizeFlags(a2)
    move.w #0x0000, VRAMBlock_Prev(a2)
    move.w #0x0000, VRAMBlock_Next(a2)

    IF BLDCONF_VRAM_MGR_DEBUG
    move.l #0x0, VRAMBlock_DebugAllocAddr(a2)
    ENDIF

    ; Link neighbour's next with this
    tst.w  d2
    beq    @NoNextNext                  ; End of list?
    move.w d2, VRAMBlock_Next(a3)       ; This block's next
    move.l d2, a2
    VRAM_BLOCK_IDX_TO_ADDR a2
    move.w d5, VRAMBlock_Prev(a2)       ; Next block's prev

    rts

    @NoNextNext:

    ; Neighbour had no neighbour
    move.w #0x0000, VRAMBlock_Next(a3)

    rts

    IF BLDCONF_VRAM_MGR_DEBUG

    @Err_Allocd:
    VRAM_ERROR "VRAM_MGR: Block not free"

    @Err_NoNeighbour:
    VRAM_ERROR "VRAM_MGR: No block neighbour"

    @Err_NeighbourAllocd:
    VRAM_ERROR "VRAM_MGR: Neighbour block not free"

    ENDIF  ; BLDCONF_VRAM_MGR_DEBUG

    rts

VRAMMGR_DrawTable:
    ; ======================================
    ; Draws VRAM allocation table to screen
    ; (first 16 entries)
    ; ======================================
    ; No params
    ; ======================================
    ; Expects debug font and palette to be
    ; loaded.
    ; ======================================

    IF BLDCONF_VRAM_MGR_DEBUG
    DBG_DRAW_STRING_A #4,#5,"Hndl Ownr Addr Size Prev Next"
    ELSE
    DBG_DRAW_STRING_A #4,#5,"Hndl Hndl Ownr Addr Size Prev Next"
    ENDIF

    PUSH.L a0

    lea    RAM_VRAM_MANAGER, a0
    lea    VRAMManager_BlockTable(a0), a2
    moveq  #0x0, d3

    move.w #0x07, d1                    ; Y
    move.w #16-1, d2                    ; 16 entries
    @EntryLp:
    move.w #0x04, d0                    ; X

    STACK_ALLOC 64, a0                  ; Alloc space for string

    PUSHM.L d0-d3/a0-a2
   
    PUSHM.L d0-d1/a0                    ; Backup string start addr

    ; Handle addr
    move.w d3, d0
    bsr    STR_ItoA_Hex_w
    move.l a1, a0
    move.b #' ', (a0)+

    IF BLDCONF_VRAM_MGR_DEBUG
    ; Owner (callee)
    move.l VRAMBlock_DebugAllocAddr(a2), d0
    bsr    STR_ItoA_Hex_w
    move.l a1, a0
    move.b #' ', (a0)+
    ENDIF

    ; Block addr
    move.w VRAMBlock_Addr(a2), d0
    bsr    STR_ItoA_Hex_w
    move.l a1, a0
    move.b #' ', (a0)+

    ; Block size/flags
    move.w VRAMBlock_SizeFlags(a2), d0
    bsr    STR_ItoA_Hex_w
    move.l a1, a0
    move.b #' ', (a0)+

    ; Prev
    moveq  #0x0, d0
    move.w VRAMBlock_Prev(a2), d0
    bsr    STR_ItoA_Hex_w
    move.l a1, a0
    move.b #' ', (a0)+

    ; Next
    moveq  #0x0, d0
    move.w VRAMBlock_Next(a2), d0
    bsr    STR_ItoA_Hex_w

    POPM.L d0-d1/a0                     ; Restore string start addr                         

    bsr    DBG_DrawStringA               ; Draw string

    POPM.L d0-d3/a0-a2

    STACK_FREE 64                       ; Free string

    addi.w #0x1, d1
    addi.l #SIZEOF_VRAMBlock, a2
    addi.w #SIZEOF_VRAMBlock, d3
    dbra   d2, @EntryLp

    POP.L  a0

    rts