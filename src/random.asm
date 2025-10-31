;=========================================================
; random.asm
; Pseudo-random utilities (SplitMix64-based)
;=========================================================
; Provides:
;   - rand_seed / rand_seed_auto (explicit/auto seeding)
;   - rand_u64 / rand_s64 / rand_bool
;   - rand_range / rand_range_s64 (bias-free)
; Uses SAFE_PROLOGUE/SAFE_EPILOGUE and Win64 ABI.
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
; rand_s64()
; Returns:
;   CF=0, RAX = next signed 64-bit random value (i64)
; Notes:
;   - Thin wrapper around `rand_u64`; returns the same 64-bit bit pattern.
;   - Use `io_print_int` in tests to view signed decimal interpretation.
;________________________________________
rand_s64 PROC
    SAFE_PROLOGUE

    call    rand_u64    ; RAX <- next 64-bit pattern (unsigned bits)

    ; Return with CF clear (RET_OK also restores this procs stack)
    RET_OK
rand_s64 ENDP


;________________________________________
; rand_bool()
; Returns:
;   CF=0, AL = 0 or 1 (RAX zero-extended)
; Notes:
;   - Calls `rand_u64` to obtain 64 random bits and returns the least-significant bit.
;   - Deterministic for a given seed; NOT cryptographically secure.
;   - Preserves non-volatile registers (RBX, RBP, RSI, RDI, R12–R15).
;   - Clobbers volatile registers used by `rand_u64` (RAX, RCX, RDX).
;   - Returns with CF cleared on success.
;________________________________________
rand_bool PROC
    SAFE_PROLOGUE
    
    ; Get 64 random bits using rand_u64
    call    rand_u64            ; RAX = random 64-bit value
    
    ; Extract lowest bit (AND with 1)
    and     al, 1              ; AL = RAX & 1 (keeps only bit 0)
                               ; Result is already zero-extended
    
    RET_OK                     ; CF=0, return bool in AL
rand_bool ENDP

;________________________________________
; rand_range(max_exclusive)
; RCX = max (exclusive)
; Returns:
;   CF=1, RAX=0          if max == 0   (bad arg)
;   CF=0, RAX in [0,max) otherwise.
; Notes:
;   - Uses multiply-high rejection sampling to avoid modulo bias:
;       threshold = (-max) % max
;       loop: x = rand_u64(); product = x * max; low = low64(product)
;             if low >= threshold: return high64(product)
;   - Deterministic for a given seed; NOT cryptographically secure.
;   - Preserves non-volatile registers (RBX, RBP, RSI, RDI, R12–R15).
;   - Clobbers volatile registers used by helpers (RAX, RCX, RDX, R8, R9).
;________________________________________
rand_range PROC max_exclusive:QWORD
    SAFE_PROLOGUE

    ; Return error if max == 0
    CHECK_LEN_NONZERO rcx, ERR_BADARG

    ; Save max to a volatile temp because rand_u64 clobbers RCX
    mov     r9, rcx            ; r9 = max

    ; threshold = (-max) % max
    mov     rax, r9
    neg     rax                ; rax = -max (unsigned)
    xor     rdx, rdx
    div     r9                 ; rdx = (-max) % max
    mov     r8, rdx            ; r8 = threshold

@sample:
    call    rand_u64           ; RAX = random64 (rand_u64 clobbers RCX/RDX)
    mul     r9                 ; RDX:RAX = RAX * max
                              ; low64 in RAX, high64 in RDX
    cmp     rax, r8            ; if low < threshold -> reject
    jb      @sample
    mov     rax, rdx           ; return high64(product) in RAX
    RET_OK
rand_range ENDP


;________________________________________
; rand_range_s64(min_inclusive, max_exclusive)
; RCX = min_inclusive (i64)
; RDX = max_exclusive (i64)
; Returns:
;   CF=1, RAX=ERR_BADARG (in EAX) if min >= max
;   CF=0, RAX in [min, max) otherwise.
; Notes:
;   - Computes width = (uint64_t)(max - min), delegates to rand_range(width),
;     then returns min + result.
;   - Preserves non-volatile registers; uses the procedure stack slot to
;     hold `min` across the call to `rand_range`.
;________________________________________
rand_range_s64 PROC min_inclusive:QWORD, max_exclusive:QWORD
    SAFE_PROLOGUE

    ; Validate: min < max (signed)
    cmp     rcx, rdx
    jl      @ok_s64
      RET_ERR ERR_BADARG
@ok_s64:
    ; Save min on the stack (SAFE_PROLOGUE reserved space)
    mov     qword ptr [rsp], rcx

    ; width = max - min  (unsigned arithmetic)
    mov     rax, rdx
    sub     rax, rcx        ; rax = width
    mov     rcx, rax        ; prepare param for rand_range

    call    rand_range
    jc      @prop_err_s64   ; propagate error from rand_range (EAX/CF preserved)

    ; success: add min back to the offset and return
    mov     rdx, qword ptr [rsp]
    add     rax, rdx
    RET_OK

@prop_err_s64:
    ; rand_range left error code in EAX and CF set; return preserving them
    SAFE_EPILOGUE
rand_range_s64 ENDP



END
