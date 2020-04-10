; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 29th March 2020
; ============================================================================================
; SCRIPTFN.ASM - Script engine funcs and structure
; ============================================================================================

ScriptGlobal_Engine:
    dc.l ScriptFunc_FindFloor   ; short FindFloor(const Entity& entity, const Scene& scene)

SCRIPTFUNC_GETPARAM: macro index,outreg
    ; ======================================
    ; Fetches a script param from stack
    ; (C++ calling convention)
    ; ======================================
    ; index    Index of param (left to right)
    ; outreg   Reg to copy to
    ; ======================================
    ; Stack:
    ;   0(sp) = return addr
    ;   4(sp) = param 1...
    ;   8(sp) = param 2...
    ;  12(sp) = param 3...
    ; ======================================
    move.l (4+(index*4))(sp), \outreg
    endm

ScriptFunc_FindFloor:
    ; ======================================
    ; Searches for terrain downwards,
    ; returns terrain height and flags.
    ; Terrain layer 0 only.
    ; ======================================
    ; short FindFloor(const Entity& entity, const Scene& scene, short& terrainFlags)
    ; ======================================

    SCRIPTFUNC_GETPARAM 0, a3                           ; const Entity& entity
    SCRIPTFUNC_GETPARAM 1, a4                           ; const Scene& scene

    PUSHM.L a0-a4
    
    ; Check floor
    move.l SceneData_ColMap(a4), a0
    move.l SceneData_ColStampset(a4), a1
    move.l SceneData_ColTileset(a4), a2
    move.w SceneData_ColMapWidthStamps(a4), d2
    bsr    PHYS_EntityFindFloor
    move.w #-1, d0
    btst   #COLLISION_FLAG_BIT_TERRAIN_W, d3
    beq    @NoTerrain
    move.w d7, d0                                       ; Return val
    @NoTerrain:

    POPM.L a0-a4

    SCRIPTFUNC_GETPARAM 2, a5                           ; short& terrainFlags
    move.w d3, (a5)
    
    rts