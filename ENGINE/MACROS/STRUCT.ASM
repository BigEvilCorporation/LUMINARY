; ============================================================================================
; LUMINARY - a game engine and framework for the SEGA Mega Drive
; ============================================================================================
; Matt Phillips - Big Evil Corporation Ltd - 11th July 2019
; ============================================================================================
; STRUCT.ASM - RS structure helper macros
; ============================================================================================

STRUCT_ALIGN: macro
	if __RS&1
	rs.b 1
	endc
	endm

STRUCT_BEGIN: macro name
__STRUCT_NAME equs "\name\"
	rsset 0
	endm

STRUCT_INHERIT: macro name,parent
__STRUCT_NAME equs "\name\"
	rsset SIZEOF_\parent
	endm

STRUCT_END: macro
	STRUCT_ALIGN
SIZEOF_\__STRUCT_NAME rs.b 0
	endm

STRUCT_ALLOC: macro structname,varname
\varname\: rs.b SIZEOF_\structname
	endm