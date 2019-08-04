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
    ; a0   In: Entity spawn desc
    ; a0   Out: Entity addr

    move.l a0, a1

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
    move.l a0, (a3)                     ; Set component address on entity
    move.l (a2), a3                     ; Get component constructor addr
    PUSHM.L d0/a0-a2
    jsr    (a3)                         ; Call component constructor
    POPM.L  d0/a0-a2
    POP.L  a3                           ; Restore entity
    addi.l #SIZE_LONG, a2               ; Next component
    dbra   d0, @ConstructorLp

    ; lea RAM_EntityManager
    ; Add count

    rts

ENT_DespawnEntity:
    rts

ENT_AllocEntityBlock:
    ; a0   Out: block addr

    ; lea RAM_EntityManager
    ; lea RAM_EntityBlockTable

    rts

ENT_FreeEntityBlock:
    rts