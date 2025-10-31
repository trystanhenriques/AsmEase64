OPTION casemap:none

INCLUDE AsmEase64.inc

.data
; -------------------------------------------------------
; Literals
; -------------------------------------------------------
szRun          db "Running math sanity tests...",13,10,0
szT            db "T",0
szColonSpace   db ": ",0
szAbsOpen      db "abs(",0
szClampOpen    db "clamp(",0
szSignOpen     db "sign(",0
szPowerOpen    db "power(",0
szEvenOpen     db "iseven(",0
szOddOpen      db "isodd(",0
szCommaSpace   db ", ",0
szExpect       db ") -> expect RAX=",0
szExpectCF     db ", CF=0",0
szExpectBad    db ") -> expect EAX=ERR_BADARG, CF=1",0
szExpectOvf    db ") -> expect EAX=ERR_OVERFLOW, CF=1",0
szGot          db "; got RAX=",0
szGotEAX       db "; got EAX=",0
szEllipses     db " ... ",0
szPASS         db "PASS",0
szFAIL         db "FAIL (got RAX=",0
szFAIL_EAX     db "FAIL (got EAX=",0
szCommaCF      db ", CF=",0
szCloseParen   db ")",0

; Expected values as data (u64)
exp0           dq 0
exp1           dq 1
exp123         dq 123456789
expI64Max      dq 07FFFFFFFFFFFFFFFh
expI64MinMag   dq 08000000000000000h      ; 2^63

.code

; -------------------------------------------------------
; Helper macro to run one abs test and print PASS/FAIL line
; Format:
;   T<idx>: abs(<signed>) -> expect RAX=<unsigned>, CF=0; got RAX=<unsigned> ... PASS/FAIL(...)
; Uses R12 (expected) and R13 (got) which are non-volatile.
; -------------------------------------------------------
TEST_ABS MACRO idx:REQ, in_val:REQ, exp_sym:REQ
    LOCAL L_fail, L_pass, L_done

    ; T<idx>:
    lea     rcx, szT
    call    io_print_string
    mov     rcx, idx
    call    io_print_uint
    lea     rcx, szColonSpace
    call    io_print_string

    ; abs(<signed>) -> expect RAX=
    lea     rcx, szAbsOpen
    call    io_print_string
    mov     rcx, in_val
    call    io_print_int
    lea     rcx, szExpect
    call    io_print_string

    ; expected (u64) -> R12
    mov     r12, [exp_sym]
    mov     rcx, r12
    call    io_print_uint

    ; ", CF=0"
    lea     rcx, szExpectCF
    call    io_print_string

    ; call math_abs with input
    mov     rcx, in_val
    call    math_abs
    mov     r13, rax            ; got
    setc    bl                  ; CF snapshot

    ; "; got RAX=<got>"
    lea     rcx, szGot
    call    io_print_string
    mov     rcx, r13
    call    io_print_uint
    lea     rcx, szEllipses
    call    io_print_string

    ; verify
    cmp     r13, r12
    jne     L_fail
    test    bl, bl
    jnz     L_fail
    jmp     L_pass

L_fail:
    ; FAIL (got RAX=<got>, CF=<cf>)
    lea     rcx, szFAIL
    call    io_print_string
    mov     rcx, r13
    call    io_print_uint
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szCloseParen
    call    io_print_string
    call    io_print_newline
    jmp     L_done

L_pass:
    lea     rcx, szPASS
    call    io_print_string
    call    io_print_newline

L_done:
ENDM

; -------------------------------------------------------
; Helper macro for math_clamp success cases
; Format:
;   T<idx>: clamp(v, min, max) -> expect RAX=<signed>, CF=0; got RAX=<signed> ... PASS/FAIL
; Uses R12 (expected) and R13 (got).
; -------------------------------------------------------
TEST_CLAMP_OK MACRO idx:REQ, v:REQ, vmin:REQ, vmax:REQ, expected:REQ
    LOCAL L_fail, L_pass, L_done

    ; T<idx>:
    lea     rcx, szT
    call    io_print_string
    mov     rcx, idx
    call    io_print_uint
    lea     rcx, szColonSpace
    call    io_print_string

    ; clamp(v, min, max)
    lea     rcx, szClampOpen
    call    io_print_string
    mov     rcx, v
    call    io_print_int
    lea     rcx, szCommaSpace
    call    io_print_string
    mov     rcx, vmin
    call    io_print_int
    lea     rcx, szCommaSpace
    call    io_print_string
    mov     rcx, vmax
    call    io_print_int

    ; ") -> expect RAX=<expected>"
    lea     rcx, szExpect
    call    io_print_string
    mov     r12, expected
    mov     rcx, r12
    call    io_print_int

    ; ", CF=0"
    lea     rcx, szExpectCF
    call    io_print_string

    ; call math_clamp(v, vmin, vmax)
    mov     rcx, v
    mov     rdx, vmin
    mov     r8,  vmax
    call    math_clamp
    mov     r13, rax            ; got
    setc    bl                  ; CF snapshot

    ; "; got RAX=<got> ... "
    lea     rcx, szGot
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szEllipses
    call    io_print_string

    ; verify
    cmp     r13, r12
    jne     L_fail
    test    bl, bl
    jnz     L_fail
    jmp     L_pass

L_fail:
    lea     rcx, szFAIL
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szCloseParen
    call    io_print_string
    call    io_print_newline
    jmp     L_done

L_pass:
    lea     rcx, szPASS
    call    io_print_string
    call    io_print_newline

L_done:
ENDM

; -------------------------------------------------------
; Helper macro for math_clamp error case (min > max)
; Format:
;   T<idx>: clamp(v, min, max) -> expect EAX=ERR_BADARG, CF=1; got EAX=<code>, CF=<cf> ... PASS/FAIL
; -------------------------------------------------------
TEST_CLAMP_BAD MACRO idx:REQ, v:REQ, vmin:REQ, vmax:REQ
    LOCAL L_fail, L_pass, L_done

    ; T<idx>:
    lea     rcx, szT
    call    io_print_string
    mov     rcx, idx
    call    io_print_uint
    lea     rcx, szColonSpace
    call    io_print_string

    ; clamp(v, min, max)
    lea     rcx, szClampOpen
    call    io_print_string
    mov     rcx, v
    call    io_print_int
    lea     rcx, szCommaSpace
    call    io_print_string
    mov     rcx, vmin
    call    io_print_int
    lea     rcx, szCommaSpace
    call    io_print_string
    mov     rcx, vmax
    call    io_print_int

    ; ") -> expect EAX=ERR_BADARG, CF=1"
    lea     rcx, szExpectBad
    call    io_print_string

    ; call math_clamp(v, vmin, vmax)
    mov     rcx, v
    mov     rdx, vmin
    mov     r8,  vmax
    call    math_clamp
    setc    bl                  ; CF snapshot
    mov     r13d, eax           ; got error code (zero-extended)

    ; "; got EAX=<code> ... "
    lea     rcx, szGotEAX
    call    io_print_string
    mov     rcx, r13
    call    io_print_uint
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szEllipses
    call    io_print_string

    ; verify: EAX == ERR_BADARG and CF == 1
    cmp     r13d, ERR_BADARG
    jne     L_fail
    test    bl, bl
    jz      L_fail
    jmp     L_pass

L_fail:
    lea     rcx, szFAIL_EAX
    call    io_print_string
    mov     rcx, r13
    call    io_print_uint
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szCloseParen
    call    io_print_string
    call    io_print_newline
    jmp     L_done

L_pass:
    lea     rcx, szPASS
    call    io_print_string
    call    io_print_newline

L_done:
ENDM

; -------------------------------------------------------
; Helper macro for math_sign success cases
; Format:
;   T<idx>: sign(v) -> expect RAX=<signed>, CF=0; got RAX=<signed> ... PASS/FAIL
; Uses R12 (expected) and R13 (got).
; -------------------------------------------------------
TEST_SIGN MACRO idx:REQ, v:REQ, expected:REQ
    LOCAL L_fail, L_pass, L_done

    ; T<idx>:
    lea     rcx, szT
    call    io_print_string
    mov     rcx, idx
    call    io_print_uint
    lea     rcx, szColonSpace
    call    io_print_string

    ; sign(v)
    lea     rcx, szSignOpen
    call    io_print_string
    mov     rcx, v
    call    io_print_int

    ; ") -> expect RAX=<expected>"
    lea     rcx, szExpect
    call    io_print_string
    mov     r12, expected
    mov     rcx, r12
    call    io_print_int

    ; ", CF=0"
    lea     rcx, szExpectCF
    call    io_print_string

    ; call math_sign(v)
    mov     rcx, v
    call    math_sign
    mov     r13, rax            ; got
    setc    bl                  ; CF snapshot

    ; "; got RAX=<got> ... "
    lea     rcx, szGot
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szEllipses
    call    io_print_string

    ; verify
    cmp     r13, r12
    jne     L_fail
    test    bl, bl
    jnz     L_fail
    jmp     L_pass

L_fail:
    lea     rcx, szFAIL
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szCloseParen
    call    io_print_string
    call    io_print_newline
    jmp     L_done

L_pass:
    lea     rcx, szPASS
    call    io_print_string
    call    io_print_newline

L_done:
ENDM

; -------------------------------------------------------
; Helper macro for math_power success cases
; Format:
;   T<idx>: power(base, exp) -> expect RAX=<signed>, CF=0; got RAX=<signed> ... PASS/FAIL
; Uses R12 (expected) and R13 (got).
; -------------------------------------------------------
TEST_POW_OK MACRO idx:REQ, base:REQ, exp:REQ, expected:REQ
    LOCAL L_fail, L_pass, L_done

    ; T<idx>:
    lea     rcx, szT
    call    io_print_string
    mov     rcx, idx
    call    io_print_uint
    lea     rcx, szColonSpace
    call    io_print_string

    ; power(base, exp)
    lea     rcx, szPowerOpen
    call    io_print_string
    mov     rcx, base
    call    io_print_int
    lea     rcx, szCommaSpace
    call    io_print_string
    mov     rcx, exp
    call    io_print_uint

    ; ") -> expect RAX=<expected>"
    lea     rcx, szExpect
    call    io_print_string
    mov     r12, expected
    mov     rcx, r12
    call    io_print_int

    ; ", CF=0"
    lea     rcx, szExpectCF
    call    io_print_string

    ; call math_power(base, exp)
    mov     rcx, base
    mov     rdx, exp
    call    math_power
    mov     r13, rax            ; got
    setc    bl                  ; CF snapshot

    ; "; got RAX=<got> ... "
    lea     rcx, szGot
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szEllipses
    call    io_print_string

    ; verify
    cmp     r13, r12
    jne     L_fail
    test    bl, bl
    jnz     L_fail
    jmp     L_pass

L_fail:
    lea     rcx, szFAIL
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szCloseParen
    call    io_print_string
    call    io_print_newline
    jmp     L_done

L_pass:
    lea     rcx, szPASS
    call    io_print_string
    call    io_print_newline

L_done:
ENDM

; -------------------------------------------------------
; Helper macro for math_power overflow cases
; Format:
;   T<idx>: power(base, exp) -> expect EAX=ERR_OVERFLOW, CF=1; got EAX=<code>, CF=<cf> ... PASS/FAIL
; -------------------------------------------------------
TEST_POW_OVF MACRO idx:REQ, base:REQ, exp:REQ
    LOCAL L_fail, L_pass, L_done

    ; T<idx>:
    lea     rcx, szT
    call    io_print_string
    mov     rcx, idx
    call    io_print_uint
    lea     rcx, szColonSpace
    call    io_print_string

    ; power(base, exp)
    lea     rcx, szPowerOpen
    call    io_print_string
    mov     rcx, base
    call    io_print_int
    lea     rcx, szCommaSpace
    call    io_print_string
    mov     rcx, exp
    call    io_print_uint

    ; ") -> expect EAX=ERR_OVERFLOW, CF=1"
    lea     rcx, szExpectOvf
    call    io_print_string

    ; call math_power(base, exp)
    mov     rcx, base
    mov     rdx, exp
    call    math_power
    setc    bl                  ; CF snapshot
    mov     r13d, eax           ; got error code

    ; "; got EAX=<code> ... "
    lea     rcx, szGotEAX
    call    io_print_string
    mov     rcx, r13
    call    io_print_uint
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szEllipses
    call    io_print_string

    ; verify: EAX == ERR_OVERFLOW and CF == 1
    cmp     r13d, ERR_OVERFLOW
    jne     L_fail
    test    bl, bl
    jz      L_fail
    jmp     L_pass

L_fail:
    lea     rcx, szFAIL_EAX
    call    io_print_string
    mov     rcx, r13
    call    io_print_uint
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szCloseParen
    call    io_print_string
    call    io_print_newline
    jmp     L_done

L_pass:
    lea     rcx, szPASS
    call    io_print_string
    call    io_print_newline

L_done:
ENDM

; -------------------------------------------------------
; Helper macro for math_is_even success cases
; Format:
;   T<idx>: iseven(v) -> expect RAX=<0|1>, CF=0; got RAX=<0|1> ... PASS/FAIL
; Uses R12 (expected) and R13 (got).
; -------------------------------------------------------
TEST_EVEN MACRO idx:REQ, v:REQ, expected:REQ
    LOCAL L_fail, L_pass, L_done

    ; T<idx>:
    lea     rcx, szT
    call    io_print_string
    mov     rcx, idx
    call    io_print_uint
    lea     rcx, szColonSpace
    call    io_print_string

    ; iseven(v)
    lea     rcx, szEvenOpen
    call    io_print_string
    mov     rcx, v
    call    io_print_int

    ; ") -> expect RAX=<expected>"
    lea     rcx, szExpect
    call    io_print_string
    mov     r12, expected
    mov     rcx, r12
    call    io_print_int

    ; ", CF=0"
    lea     rcx, szExpectCF
    call    io_print_string

    ; call math_is_even(v)
    mov     rcx, v
    call    math_is_even
    mov     r13, rax            ; got
    setc    bl                  ; CF snapshot

    ; "; got RAX=<got> ... "
    lea     rcx, szGot
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szEllipses
    call    io_print_string

    ; verify
    cmp     r13, r12
    jne     L_fail
    test    bl, bl
    jnz     L_fail
    jmp     L_pass

L_fail:
    lea     rcx, szFAIL
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szCloseParen
    call    io_print_string
    call    io_print_newline
    jmp     L_done

L_pass:
    lea     rcx, szPASS
    call    io_print_string
    call    io_print_newline

L_done:
ENDM

; -------------------------------------------------------
; Helper macro for math_is_odd success cases
; Format:
;   T<idx>: isodd(v) -> expect RAX=<0|1>, CF=0; got RAX=<0|1> ... PASS/FAIL
; Uses R12 (expected) and R13 (got).
; -------------------------------------------------------
TEST_ODD MACRO idx:REQ, v:REQ, expected:REQ
    LOCAL L_fail, L_pass, L_done

    ; T<idx>:
    lea     rcx, szT
    call    io_print_string
    mov     rcx, idx
    call    io_print_uint
    lea     rcx, szColonSpace
    call    io_print_string

    ; isodd(v)
    lea     rcx, szOddOpen
    call    io_print_string
    mov     rcx, v
    call    io_print_int

    ; ") -> expect RAX=<expected>"
    lea     rcx, szExpect
    call    io_print_string
    mov     r12, expected
    mov     rcx, r12
    call    io_print_int

    ; ", CF=0"
    lea     rcx, szExpectCF
    call    io_print_string

    ; call math_is_odd(v)
    mov     rcx, v
    call    math_is_odd
    mov     r13, rax            ; got
    setc    bl                  ; CF snapshot

    ; "; got RAX=<got> ... "
    lea     rcx, szGot
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szEllipses
    call    io_print_string

    ; verify
    cmp     r13, r12
    jne     L_fail
    test    bl, bl
    jnz     L_fail
    jmp     L_pass

L_fail:
    lea     rcx, szFAIL
    call    io_print_string
    mov     rcx, r13
    call    io_print_int
    lea     rcx, szCommaCF
    call    io_print_string
    movzx   rcx, bl
    call    io_print_uint
    lea     rcx, szCloseParen
    call    io_print_string
    call    io_print_newline
    jmp     L_done

L_pass:
    lea     rcx, szPASS
    call    io_print_string
    call    io_print_newline

L_done:
ENDM

; -------------------------------------------------------
; main () -> returns 0
; -------------------------------------------------------
main PROC
    SAFE_PROLOGUE

    ; optional: initialize I/O (cache handles)
    call    io_init

    ; header
    lea     rcx, szRun
    call    io_print_string

    ; T1..T7 for math_abs
    TEST_ABS 1,  0,                      exp0
    TEST_ABS 2,  1,                      exp1
    TEST_ABS 3, -1,                      exp1
    TEST_ABS 4,  123456789,              exp123
    TEST_ABS 5, -123456789,              exp123
    TEST_ABS 6,  07FFFFFFFFFFFFFFFh,     expI64Max
    TEST_ABS 7, -08000000000000000h,     expI64MinMag   ; INT64_MIN

    ; T8..T15 for math_clamp
    TEST_CLAMP_OK  8,   5,   0,  10,   5
    TEST_CLAMP_OK  9,  -5,   0,  10,   0
    TEST_CLAMP_OK 10,  15,   0,  10,  10
    TEST_CLAMP_OK 11, -10,  -5,   5,  -5
    TEST_CLAMP_OK 12,   3,  -5,   5,   3
    TEST_CLAMP_OK 13,   5,   5,   5,   5
    TEST_CLAMP_BAD 14,   7,   9,   1
    TEST_CLAMP_BAD 15,   0,   1,   0

    ; T16..T22 for math_sign
    TEST_SIGN 16,  0,                       0
    TEST_SIGN 17,  1,                       1
    TEST_SIGN 18, -1,                      -1
    TEST_SIGN 19,  123456789,               1
    TEST_SIGN 20, -123456789,              -1
    TEST_SIGN 21,  07FFFFFFFFFFFFFFFh,      1
    TEST_SIGN 22, -08000000000000000h,     -1

    ; T23..T37 for math_power
    TEST_POW_OK  23,  0,  0,                         1          ; 0^0 -> 1
    TEST_POW_OK  24,  0,  5,                         0          ; 0^5 -> 0
    TEST_POW_OK  25,  1, 20,                         1          ; 1^n
    TEST_POW_OK  26, -1,  0,                         1          ; (-1)^0
    TEST_POW_OK  27, -1,  1,                        -1          ; (-1)^1
    TEST_POW_OK  28, -1,  2,                         1          ; (-1)^2
    TEST_POW_OK  29,  2, 10,                      1024
    TEST_POW_OK  30,  3,  5,                       243
    TEST_POW_OK  31, -2,  3,                        -8
    TEST_POW_OK  32, -2,  4,                        16
    TEST_POW_OK  33, -2, 63, -08000000000000000h                ; (-2)^63 = -2^63

    TEST_POW_OVF 34,  2, 63                                     ; 2^63  -> overflow
    TEST_POW_OVF 35, -2, 64                                     ; (-2)^64 -> +2^64 overflow
    TEST_POW_OVF 36, 10, 19                                     ; 10^19 -> overflow
    TEST_POW_OVF 37,  3, 40                                     ; 3^40  -> overflow

    ; T38..T51 for math_is_even / math_is_odd
    TEST_EVEN 38,  0,                       1
    TEST_EVEN 39,  1,                       0
    TEST_EVEN 40,  2,                       1
    TEST_EVEN 41, -1,                       0
    TEST_EVEN 42, -2,                       1
    TEST_EVEN 43,  07FFFFFFFFFFFFFFFh,      0
    TEST_EVEN 44, -08000000000000000h,      1

    TEST_ODD  45,  0,                       0
    TEST_ODD  46,  1,                       1
    TEST_ODD  47,  2,                       0
    TEST_ODD  48, -1,                       1
    TEST_ODD  49, -2,                       0
    TEST_ODD  50,  07FFFFFFFFFFFFFFFh,      1
    TEST_ODD  51, -08000000000000000h,      0

    xor     eax, eax
    SAFE_EPILOGUE
main ENDP

END