; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; MEMMAP.ASM - "Hello world" memory map
; ============================================================================================

    RSSET RAM_GAME_START

RAM_GAMEPAD_PREV_1                      rs.w 1  ; Prev frame gamepad state

        STRUCT_ALLOC Scene,RAM_TESTSCENE1       ; Current scene