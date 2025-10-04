IFNDEF ARRAY_INC_GUARD ; header guard
ARRAY_INC_GUARD EQU 1

; make case sensitive
OPTION casemap:none

INCLUDE macros.inc
INCLUDE errors.inc

; _______________________________________________________
; Array API (QWORD elements; signed/unsigned OK)
; Conventions for ALL arr_*:
;   RCX = base pointer (QWORD[])
;   RDX = length (number of elements)
;   Additional args use R8, R9, then stack (Win64)
; Returns:
;   Success: CF=0, RAX = value (if applicable), otherwise undefined
;   Error:  CF=1, EAX = MYLIB_ERR_* (Constants)
; Clobbers:
;   RAX, RCX, RDX, R8, R9, R10, R11 (volatile)
; _______________________________________________________

; read
arr_get_value      PROTO :QWORD, :QWORD, :QWORD          ; (base, len, index) -> RAX=value

; write / bulk
arr_set_value      PROTO :QWORD, :QWORD, :QWORD, :QWORD  ; (base, len, index, value)
arr_fill           PROTO :QWORD, :QWORD, :QWORD          ; (base, len, value)
arr_copy           PROTO :QWORD, :QWORD, :QWORD          ; (dst, src, len)

; transforms
arr_reverse        PROTO :QWORD, :QWORD                   ; (base, len)
arr_swap           PROTO :QWORD, :QWORD, :QWORD, :QWORD   ; (base, len, i, j)

; queries (UNSIGNED semantics)
arr_max            PROTO :QWORD, :QWORD                   ; (base, len) -> RAX=max
arr_min            PROTO :QWORD, :QWORD                   ; (base, len) -> RAX=min (unsigned)
arr_index_of_max   PROTO :QWORD, :QWORD                   ; (base, len) -> RAX=index
arr_index_of_min   PROTO :QWORD, :QWORD                   ; (base, len) -> RAX=index

; queries (SIGNED semantics)
arr_smax           PROTO :QWORD, :QWORD                   ; (base, len) -> RAX=max (signed)
arr_smin           PROTO :QWORD, :QWORD                   ; (base, len) -> RAX=min (signed)
arr_index_of_smax  PROTO :QWORD, :QWORD                   ; (base, len) -> RAX=index (first signed max)
arr_index_of_smin  PROTO :QWORD, :QWORD                   ; (base, len) -> RAX=index (first signed min)


; NOTE: arr_insert requires capacity & an extra arg (value) on stack; we’ll add it after core ops.
; arr_insert      PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD ; (base, pLen, capacity, index, value) [value may live on stack]


ENDIF ; ARR_INC_GUARD
