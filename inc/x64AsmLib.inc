
; header guard
IFNDEF MYLIB_INC_GUARD
MYLIB_INC_GUARD EQU 1

; make case sensitive
OPTION casemap:none

; include shared macros and errors
INCLUDE macros.inc
INCLUDE errors.inc

; common Win32 libs we will need later
INCLUDELIB kernel32.lib
EXTERN ExitProcess:PROC
EXTERN GetStdHandle:PROC
EXTERN WriteConsoleA:PROC

; pull in all finished modules
INCLUDE array.inc



; header guard end
ENDIF