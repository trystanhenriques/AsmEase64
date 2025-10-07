IFNDEF WIN32_CONSOLE_INC_GUARD
WIN32_CONSOLE_INC_GUARD EQU 1

OPTION casemap:none

; Console handle constants
STD_INPUT_HANDLE   EQU -10
STD_OUTPUT_HANDLE  EQU -11

; Win32 imports for console I/O
EXTERN GetStdHandle:PROC
EXTERN WriteConsoleA:PROC
EXTERN ReadConsoleA:PROC

; Make sure kernel32 gets linked by consumers that include this
INCLUDELIB kernel32.lib

ENDIF ; WIN32_CONSOLE_INC_GUARD
