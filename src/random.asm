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

RAND_FALLBACK_SEED dq 0DDB2BD6C9BB22173h

; SplitMix64 constants (use memory loads — avoids large immediate errors)
SM64_INC   dq 09E3779B97F4A7C15h
SM64_MUL1  dq 0BF58476D1CE4E5B9h
SM64_MUL2  dq 094D049BB133111EBh

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
;   - If input is 0, uses a non-zero fallback to avoid PRNG getting stuck
;   - Always clears CF on return (no error cases)
;   - Preserves all non-volatile registers
;________________________________________
rand_seed PROC state:QWORD
    SAFE_PROLOGUE
    
    ; Save old state first (required for return value)
    mov     rax, [g_rand_state]     ; old state -> RAX for return

    ; Check if new state is zero
    test    rcx, rcx
    jnz     @use_input              ; if input non-zero, use it directly
    
    ; Zero seed case - use non-zero fallback
    ; Choose a prime number with good bit distribution
    mov     rcx, QWORD PTR [RAND_FALLBACK_SEED] ; Large 64-bit prime as fallback seed

@use_input:
    ; Store new state (either input or fallback)
    mov     [g_rand_state], rcx
    
    ; RAX already contains old state
    RET_OK                          ; CF=0, return old state in RAX

rand_seed ENDP


;________________________________________
; rand_u64()
; Returns:
;   CF=0, RAX = next 64-bit unsigned random value
; Notes:
;   - Implements the SplitMix64 output function:
;       state += SM64_INC
;       z = state
;       z ^= z >> 30; z *= SM64_MUL1
;       z ^= z >> 27; z *= SM64_MUL2
;       z ^= z >> 31
;       return z
;   - Advances the internal PRNG state stored at `g_rand_state`.
;   - Deterministic for a given seed; NOT cryptographically secure.
;   - Uses memory-resident 64-bit constants (`SM64_INC`, `SM64_MUL1`, `SM64_MUL2`)
;     to avoid assembler limitations on large immediates.
;   - Side-effect: updates `g_rand_state`.
;   - Returns with CF cleared (CF=0) on success.
;   - Preserves non-volatile registers (RBX, RBP, RSI, RDI, R12–R15).
;   - Clobbers volatile registers: RAX, RCX, RDX.
;________________________________________
rand_u64 PROC
    SAFE_PROLOGUE

    ; load state, add increment (load increment from memory to avoid imm64)
    mov     rax, [g_rand_state]
    mov     rcx, qword ptr [SM64_INC]
    add     rax, rcx
    mov     [g_rand_state], rax

    ; SplitMix64 transform:
    ; z = rax
    ; z ^= (z >> 30)
    mov     rcx, rax
    shr     rcx, 30
    xor     rax, rcx

    ; z *= 0xBF58476D1CE4E5B9
    mov     rcx, qword ptr [SM64_MUL1]
    mul     rcx                ; RDX:RAX = RAX * RCX, result low64 -> RAX

    ; z ^= (z >> 27)
    mov     rcx, rax
    shr     rcx, 27
    xor     rax, rcx

    ; z *= 0x94D049BB133111EB
    mov     rcx, qword ptr [SM64_MUL2]
    mul     rcx

    ; z ^= (z >> 31)
    mov     rcx, rax
    shr     rcx, 31
    xor     rax, rcx

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
