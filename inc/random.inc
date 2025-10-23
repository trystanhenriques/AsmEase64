IFNDEF RANDOM_INC_GUARD ; header guard
RANDOM_INC_GUARD EQU 1



;---------------------------------------------------------
; rand_seed(new_state)
; RCX = new_state (u64). If 0, the implementation will replace it
; with a fixed non-zero fallback so the PRNG never gets stuck.
; Returns: CF=0, RAX = old_state.
; Notes: does not raise errors; always clears CF on return.
;---------------------------------------------------------
rand_seed           PROTO :QWORD

;---------------------------------------------------------
; rand_u64()
; Returns: CF=0, RAX = next 64-bit random value.
; Notes: core PRNG step (e.g., xorshift64*). No parameters.
;---------------------------------------------------------
rand_u64            PROTO


; Signed 64-bit random.
; Returns: CF=0, RAX = next i64 (bits from PRNG interpreted as signed).
rand_s64            PROTO

;---------------------------------------------------------
; rand_bool()
; Returns: CF=0, AL = 0 or 1 (RAX zero-extended).
; Notes: derived from rand_u64’s low bit (or equivalent).
;---------------------------------------------------------
rand_bool           PROTO

;---------------------------------------------------------
; rand_range(max_exclusive)
; RCX = max_exclusive (u64). Generates a uniform integer in [0, max).
; Returns on success: CF=0, RAX in [0, max).
; Returns on error:   CF=1, RAX = ERR_BADARG when max_exclusive == 0.
; Notes: Implementation should avoid modulo bias (e.g., mulhi trick).
;---------------------------------------------------------
rand_range          PROTO :QWORD

; Signed range: uniform in [min_inclusive, max_exclusive).
; RCX = min_inclusive (i64)
; RDX = max_exclusive (i64)
; Returns: CF=1, RAX=0 if min >= max (bad arg)
;          CF=0, RAX in [min, max) otherwise.
rand_range_i64      PROTO :QWORD, :QWORD

ENDIF