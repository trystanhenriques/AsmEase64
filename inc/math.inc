IFNDEF MATH_INC_GUARD ; header guard
MATH_INC_GUARD EQU 1

; make case sensitive
OPTION casemap:none

INCLUDE macros.inc
INCLUDE errors.inc

; _______________________________________________________
; Math API (Windows x64)
; Conventions for ALL math_*:
;   - Pure integer math helpers. No global state.
; Calling convention (Win64):
;   RCX, RDX, R8, R9 = first four arguments; additional go on stack.
; Returns:
;   Success: CF=0, RAX = value as documented per proc.
;   Error:   CF=1, EAX = ERR_* (RAX undefined unless stated).
; Clobbers:
;   RAX, RCX, RDX, R8, R9, R10, R11 (volatile)
; _______________________________________________________

; ---- math primitives ----
; Absolute value: returns the magnitude of 'value' as an unsigned 64-bit.
; Note: For INT64_MIN, the result is 2^63 (no error).
math_abs            PROTO :QWORD                               ; (s64 value) -> RAX=u64 magnitude

; Clamp 'value' into [min, max]. Requires min <= max.
; On min > max: CF=1, EAX=ERR_BADARG.
math_clamp          PROTO :QWORD, :QWORD, :QWORD               ; (s64 value, s64 min, s64 max) -> RAX=clamped

; Sign of 'value': returns -1 if value<0, 0 if value==0, +1 if value>0.
math_sign           PROTO :QWORD                               ; (s64 value) -> RAX in {-1,0,1}

; Integer power: base^exp with non-negative exponent (u64).
;  - 0^0 returns 1.
;  - On arithmetic overflow: CF=1, EAX=ERR_OVERFLOW.
math_power          PROTO :QWORD, :QWORD                       ; (s64 base, u64 exp) -> RAX=s64

; Predicates (boolean results; no errors)
; Returns 1 if even, 0 otherwise
math_is_even        PROTO :QWORD                               ; (u64 value) -> RAX in {0,1}
; Returns 1 if odd, 0 otherwise
math_is_odd         PROTO :QWORD                               ; (u64 value) -> RAX in {0,1}

ENDIF ; MATH_INC_GUARD