; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; MEMMAP.ASM - "Hello world" memory map
; ============================================================================================

    RSSET RAM_GAME_START
        STRUCT_ALLOC Scene,RAM_TESTSCENE1
        ENT_COMPONENT_LIST ECAIBrain