OPTION casemap:none

INCLUDE math.inc

OPTION casemap:none
OPTION prologue:none, epilogue:none

.code

; -------------------------------------------------------
; math_abs (s64 value) -> u64 magnitude
; RCX: input value (s64)
; Returns:
;   CF=0, RAX = |value| as u64 (INT64_MIN -> 0x8000000000000000)
; Clobbers: RAX, RDX
; -------------------------------------------------------
math_abs PROC value:QWORD
    SAFE_PROLOGUE

    ; Branchless absolute value: (x ^ mask) - mask, where mask = x >> 63
    mov     rax, rcx           ; rax = x
    mov     rdx, rcx           ; rdx = x
    sar     rdx, 63            ; rdx = mask (0 if x>=0, -1 if x<0)
    xor     rax, rdx           ; rax = x ^ mask
    sub     rax, rdx           ; rax = (x ^ mask) - mask

    RET_OK
math_abs ENDP


; -------------------------------------------------------
; math_clamp (s64 value, s64 min, s64 max) -> s64 clamped
; RCX: value, RDX: min, R8: max
; Returns:
;   CF=0, RAX = clamped value
;   CF=1, EAX = ERR_BADARG if min > max
; Clobbers: RAX
; -------------------------------------------------------
math_clamp PROC value:QWORD, min:QWORD, max:QWORD
    SAFE_PROLOGUE

    ; Validate range: require min <= max
    CHECK_ORDER rdx, r8, ERR_BADARG

    ; Default result = value
    mov     rax, rcx

    ; if (value < min) result = min;
    cmp     rcx, rdx
    jge     @check_max
    mov     rax, rdx
    jmp     @done

@check_max:
    ; if (value > max) result = max;
    cmp     rcx, r8
    jle     @done
    mov     rax, r8

@done:
    RET_OK
math_clamp ENDP

; -------------------------------------------------------
; math_sign (s64 value) -> -1 if value<0, 0 if value==0, +1 if value>0
; RCX: input value (s64)
; Returns:
;   CF=0, RAX in {-1, 0, 1}
; Clobbers: RAX, RDX
; Notes:
;   Branchless formulation:
;     sign = (x >> 63) | (x != 0)
;     where (x >> 63) is -1 for negatives and 0 otherwise.
; -------------------------------------------------------
math_sign PROC value:QWORD
    SAFE_PROLOGUE

    mov     rax, rcx
    sar     rax, 63            ; rax = -1 if x<0, else 0
    test    rcx, rcx
    setne   dl                 ; dl = 1 if x != 0, else 0
    movzx   rdx, dl            ; rdx = 0 or 1
    or      rax, rdx           ; negatives stay -1, positives become +1, zero stays 0

    RET_OK
math_sign ENDP



; -------------------------------------------------------
; math_power (s64 base, u64 exp) -> s64 result
; RCX: base (s64), RDX: exp (u64, non-negative)
; Returns:
;   Success: CF=0, RAX = base^exp
;   Error:   CF=1, EAX = ERR_OVERFLOW on arithmetic overflow
; Clobbers:
;   RAX, RDX, R8, R9, R10, R11 (volatile)
; Notes:
;   - 0^0 returns 1
;   - Exponentiation by squaring with explicit overflow checks.
;   - Keep the running result in R8 so squaring 'a' (R10) doesn't clobber it.
;   - Final sign applied at end; magnitude bound depends on final sign:
;       INT64_MAX for non-negative, 2^63 for negative final result.
; -------------------------------------------------------
math_power PROC base:QWORD, exp:QWORD
    SAFE_PROLOGUE

    ; Fast path: exp == 0 -> 1 (including 0^0)
    mov     r9, rdx                    ; r9 = exp
    test    r9, r9
    jnz     mp_start
    mov     rax, 1
    RET_OK

mp_start:
    ; a = |base| in r10
    mov     r10, rcx
    mov     rdx, rcx
    sar     rdx, 63
    xor     r10, rdx
    sub     r10, rdx                   ; r10 = |base|

    ; finalNeg = (base<0) && (exp odd)
    mov     r11, rcx
    sar     r11, 63
    and     r11, 1                     ; r11 = baseNeg (0/1)
    test    r9, 1
    setne   al                         ; AL = 1 if exp odd
    and     al, r11b
    mov     byte ptr [rsp+08h], al     ; save final sign

    ; maxAllowed (magnitude bound) depending on final sign
    mov     r11, 7FFFFFFFFFFFFFFFh     ; INT64_MAX
    cmp     byte ptr [rsp+08h], 0
    je      mp_bound_ok
    mov     r11, 8000000000000000h     ; allow up to 2^63 if final negative
mp_bound_ok:

    ; result in R8 (keep separate from RAX used by MUL/DIV)
    mov     r8, 1

mp_loop:
    ; if (exp & 1) result *= a
    test    r9, 1
    jz      mp_after_mul

    ; If a == 0 -> result = 0
    test    r10, r10
    jnz     mp_mul_check
    xor     r8, r8
    jmp     mp_after_mul

mp_mul_check:
    ; Bound check: result <= maxAllowed / a
    mov     rax, r11
    xor     edx, edx
    div     r10                        ; RAX = floor(maxAllowed / a)
    cmp     r8, rax
    ja      mp_overflow

    ; result *= a
    mov     rax, r8
    mul     r10                        ; RDX:RAX = result * a
    ; by bound check, RDX must be 0
    mov     r8, rax

mp_after_mul:
    ; exp >>= 1; if zero, finish
    shr     r9, 1
    test    r9, r9
    jz      mp_done

    ; a = a * a (ensure it fits in 64-bit)
    mov     rax, r10
    mul     r10                        ; RDX:RAX = a*a
    test    rdx, rdx
    jnz     mp_overflow
    mov     r10, rax
    jmp     mp_loop

mp_overflow:
    mov     eax, ERR_OVERFLOW
    stc
    SAFE_EPILOGUE

mp_done:
    ; move result to RAX and apply final sign
    mov     rax, r8
    cmp     byte ptr [rsp+08h], 0
    je      mp_ret_ok
    neg     rax
mp_ret_ok:
    RET_OK
math_power ENDP


; -------------------------------------------------------
; math_is_even (u64 value) -> 1 if even, 0 otherwise
; RCX: input value (u64)
; Returns:
;   CF=0, RAX in {0,1}
; Clobbers: RAX
; Notes:
;   Branchless: test LSB and use SETZ.
; -------------------------------------------------------
math_is_even PROC value:QWORD
    SAFE_PROLOGUE
    test    rcx, 1
    setz    al                 ; AL=1 when (value&1)==0
    movzx   rax, al
    RET_OK
math_is_even ENDP



; -------------------------------------------------------
; math_is_odd (u64 value) -> 1 if odd, 0 otherwise
; RCX: input value (u64)
; Returns:
;   CF=0, RAX in {0,1}
; Clobbers: RAX
; Notes:
;   Branchless: test LSB and use SETNZ.
; -------------------------------------------------------
math_is_odd PROC value:QWORD
    SAFE_PROLOGUE
    test    rcx, 1
    setnz   al                 ; AL=1 when (value&1)!=0
    movzx   rax, al
    RET_OK
math_is_odd ENDP


END