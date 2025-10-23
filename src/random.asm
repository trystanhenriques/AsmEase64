;=========================================================
; random.asm
; Pseudo-random utilities (module scaffold)
;=========================================================
; This file sets up:
;   - Private PRNG state storage
;   - Constants/slots for a future algorithm (e.g., PCG/LCG)
;   - Public procedure stubs (no real RNG yet)
;   - Consistent prologue/epilogue macros from your lib
;
; NOTE: The bodies below are intentional stubs so you can wire
;       the module into the build now. You’ll drop in real
;       implementations later without touching callers.
;=========================================================

INCLUDE macros.inc
INCLUDE errors.inc
INCLUDE random.inc        ; prototypes & comments for this module

;---------------------------------------------------------
; Private state
;---------------------------------------------------------
.data
align 8
g_rand_state    dq 0                ; PRNG state (placeholder seed)

; (Optional) if you plan PCG/LCG later, park constants here now.
.const
align 8
; Example PCG64 constants (documented placeholders; unused for now):
; pcg64_mult      dq 5851F42D4C957F2Dh
; pcg64_inc       dq 14057B7EF767814Fh

;---------------------------------------------------------
; Code
;---------------------------------------------------------
.code

;________________________________________
; rand_seed(state)
; RCX = new 64-bit seed/state
; Returns:
;   CF=0, RAX = previous state
; Notes:
;   - This stub already swaps the state (safe & useful).
;   - Does not force a nonzero seed; you can enforce that later.
;   - Preserves all non-volatile regs it does not modify (none).
;________________________________________
rand_seed PROC state:QWORD
    SAFE_PROLOGUE

    mov     rax, [g_rand_state]     ; old
    mov     [g_rand_state], rcx     ; set new
    RET_OK                          ; CF=0

rand_seed ENDP

;________________________________________
; rand_u64()
; Returns:
;   CF=0, RAX = 0  (stub)
; Notes:
;   - Placeholder. Swap in real step (e.g., PCG/LCG) later.
;________________________________________
rand_u64 PROC
    SAFE_PROLOGUE

    xor     rax, rax                ; stub value
    RET_OK

rand_u64 ENDP

;________________________________________
; rand_bool()
; Returns:
;   CF=0, AL = 0/1  (stub currently always 0)
; Notes:
;   - Placeholder. Later: derive from rand_u64 & mask bit 0.
;________________________________________
rand_bool PROC
    SAFE_PROLOGUE

    xor     eax, eax                ; stub: always 0
    RET_OK

rand_bool ENDP

;________________________________________
; rand_range(max_exclusive)
; RCX = max (exclusive)
; Returns:
;   CF=1, RAX=0          if max == 0   (bad arg)
;   CF=0, RAX in [0,max) (stub currently always 0)
; Notes:
;   - Placeholder. Later: use 128-bit multiply/reject to avoid bias.
;________________________________________
rand_range PROC max_exclusive:QWORD
    SAFE_PROLOGUE

    test    rcx, rcx
    jnz     @ok
      xor     eax, eax              ; RAX = 0
      stc                           ; CF=1 (bad arg)
      SAFE_EPILOGUE
@ok:
    xor     eax, eax                ; stub: always 0 in range
    RET_OK

rand_range ENDP

END
