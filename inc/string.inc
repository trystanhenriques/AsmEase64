IFNDEF STRING_INC_GUARD ; header guard
STRING_INC_GUARD EQU 1

; make case sensitive
OPTION casemap:none

INCLUDE macros.inc

; --- shared error codes are defined once in array.inc (ARR_ERR_*)
;     this module returns CF/EAX using the same codes.

; public constants (string module)
STR_NPOS             EQU -1   ; returned index when "not found" (CF=0, not an error)

; _______________________________________________________
; String API (BYTE elements; explicit lengths/capacities)
; Conventions for ALL str_*:
;   - Buffers are BYTE[] (ASCII-focused); all lengths/capacities are in BYTES.
;   - RCX, RDX, R8, R9 carry the first four args (Win64); extras go on the stack.
; Returns:
;   Success: CF=0, RAX = value (see each PROC), otherwise undefined
;   Error:   CF=1, EAX = ARR_ERR_* (shared constants)
; Clobbers:
;   RAX, RCX, RDX, R8, R9, R10, R11 (volatile)
; Notes:
;   - Null-pointer checks return ARR_ERR_NULLPTR.
;   - Zero-length where non-empty required returns ARR_ERR_LEN_ZERO.
;   - Capacity violations return ARR_ERR_CAPACITY.
;   - Search "not found" returns RAX=STR_NPOS with CF=0 (not an error).
; _______________________________________________________

; copy / concatenate
str_copy           PROTO :QWORD, :QWORD, :QWORD, :QWORD        ; (dst, dst_cap, src, src_len) -> RAX=new_len (==src_len)
str_concat         PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD ; (dst, dst_len, dst_cap, src, src_len) -> RAX=new_len (dst_len+src_len)

; length / compare
str_length         PROTO :QWORD, :QWORD                         ; (base, max_scan) -> RAX=len (up to first NUL); if none, returns max_scan
str_compare        PROTO :QWORD, :QWORD, :QWORD, :QWORD         ; (a, a_len, b, b_len) -> RAX = -1, 0, +1 (lexicographic, unsigned bytes)

; transforms (in-place)
str_trim           PROTO :QWORD, :QWORD                         ; (base, len) -> RAX=new_len after trimming ASCII whitespace
str_to_upper       PROTO :QWORD, :QWORD                         ; (base, len) (ASCII 'a'..'z' -> 'A'..'Z')
str_to_lower       PROTO :QWORD, :QWORD                         ; (base, len) (ASCII 'A'..'Z' -> 'a'..'z')
str_reverse        PROTO :QWORD, :QWORD                         ; (base, len)
str_fill           PROTO :QWORD, :QWORD, :QWORD                 ; (base, len, ch) fill with low 8 bits of ch

; search / replace
str_find_char      PROTO :QWORD, :QWORD, :QWORD                 ; (base, len, ch) -> RAX=index or STR_NPOS (CF=0)
str_replace_char   PROTO :QWORD, :QWORD, :QWORD, :QWORD         ; (base, len, from, to) -> RAX=count replaced

ENDIF ; STRING_INC_GUARD
