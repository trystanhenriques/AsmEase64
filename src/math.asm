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


END