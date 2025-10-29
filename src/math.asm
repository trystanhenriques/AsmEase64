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


END