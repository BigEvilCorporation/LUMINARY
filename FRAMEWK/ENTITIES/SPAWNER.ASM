; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 6th December 2019
; ============================================================================================
; SPAWNER.ASM - Spawns a specified entity when its world grid cell becomes active
; ============================================================================================

    STATIC_ENTITY_BEGIN SESpawner
SESpawner_EntityDesc                    rs.l 1  ; [TAGS=ENTITY_DESC]
SESpawner_SpawnParams                   rs.l 1  ; [TAGS=ENTITY_ARCHETYPE]
    STATIC_ENTITY_END

SESpawner_Initialise:
    ; ======================================
    ; SESpawner static initialise
    ; ======================================
	; a0   Entity
    ; ======================================

    ; Spawn entity
    move.w Entity_PosX(a0), d0
    move.w Entity_PosY(a0), d1
    move.w Entity_ExtentsX(a0), d2
    move.w Entity_ExtentsY(a0), d3
    move.l SESpawner_SpawnParams(a0), a1
    move.l SESpawner_EntityDesc(a0), a0
    bsr    ENT_SpawnEntity

    rts

SESpawner_Update:
    ; ======================================
    ; SESpawner static update
    ; ======================================
	; a0   Entity
    ; ======================================

    ; TODO: Use world grid
    ; Also TODO: Implementing the world grid first might be a good idea

    rts