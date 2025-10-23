
; header guard
IFNDEF MYLIB_INC_GUARD
MYLIB_INC_GUARD EQU 1

; make case sensitive
OPTION casemap:none

; include shared macros and errors
INCLUDE macros.inc
INCLUDE errors.inc


; pull in all finished modules
INCLUDE array.inc
INCLUDE string.inc
INCLUDE io.inc
INCLUDE random.inc

; header guard end
ENDIF