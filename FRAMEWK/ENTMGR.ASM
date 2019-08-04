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
EntityManager_BlocksAllocd              rs.w 1
EntityManager_BlocksFree                rs.w 1
    STRUCT_END

ENT_SpawnEntity:
    ; a0   Entity manager
    ; a1   Entity spawn desc

    ; Alloc all component blocks and call constructors
    move.w EntitySpawnDesc_NumComponents(a1), d0
    move.l EntitySpawnDesc_ConstructorTable(a1), a2
    subi.w #0x1, d0
    @ConstructorLp:
    PUSHM.L d0/a0-a2
    bsr    ENT_AllocEntityBlock         ; Allocate block for component
                                        ; TODO: Insert into entity (add entity component offset to table)
    move.l a1, a0                       ; Set as current
    move.l (a2), a3                     ; Get constructor addr
    jsr    (a3)                         ; Call constructor
    POPM.L  d0/a0-a2
    addi.l #SIZE_LONG, a2               ; Next component
    dbra   d0, @ConstructorLp

    rts

ENT_DespawnEntity:
    rts

ENT_AllocEntityBlock:
    ; a0   Entity manager
    ; a1   Out: block addr

    rts

ENT_FreeEntityBlock:
    rts