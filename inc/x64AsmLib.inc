
; header guard
IFNDEF MYLIB_INC_GUARD
MYLIB_INC_GUARD EQU 1

; make case sensitive
OPTION casemap:none

ExitProcess    PROTO :DWORD

; include shared macros and errors
INCLUDE macros.inc
INCLUDE errors.inc
INCLUDE win32_console.inc

; pull in all finished modules
INCLUDE array.inc
INCLUDE string.inc
INCLUDE io.inc


; header guard end
ENDIF