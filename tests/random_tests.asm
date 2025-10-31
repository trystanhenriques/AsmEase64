option casemap:none

INCLUDE AsmEase64.inc        ; pulls macros.inc, io.inc, errors.inc, etc.

.data
align 8
hdr         db "Random Sanity Tests", 13,10,0
msg_pass    db "PASS", 13,10,0
msg_fail    db "FAIL", 13,10,0

; Prompts
mR1         db "R1 (seed first): expect old=0; got=",0
mR2         db "R2 (seed second -> expect old=0x0123456789ABCDEF): got=",0
mR3         db "R3 (seed with 0 -> expect old=0x0123456789ABCDEF): got=",0
mR4         db "R4 (seed again 0xBEEF -> expect old=<fallback>): got=",0
mR4exp      db "   expected fallback old = 0xDDB2BD6C9BB22173",13,10,0

; Helpers
got_hex     db "0x",0

; Constants used in tests
seed1       dq 0123456789ABCDEFh
seed2       dq 0BEEFh
fallback    dq 0DDB2BD6C9BB22173h     ; must match RAND_FALLBACK_SEED in random.asm

; Storage for returned "old" state (saved immediately after rand_seed)
last_old    dq 0

; R5/R6 helpers (rand_u64 tests)
align 8
mR5         db "R5 (rand_u64 determinism): got=",0
mR6         db "R6 (rand_u64 fallback integration): got=",0

; storage for outputs (R5, R6)
r5_a        dq 0
r5_b        dq 0
r5_c        dq 0
r5_d        dq 0

r6_a        dq 0
r6_b        dq 0

; R7/R8 helpers (rand_s64 tests)
align 8
mR7         db "R7 (rand_s64 determinism): got (hex / int)=",0
mR8         db "R8 (rand_s64 fallback integration): got (hex / int)=",0

; storage for outputs (R7, R8)
r7_a        dq 0
r7_b        dq 0
r7_c        dq 0
r7_d        dq 0

r8_a        dq 0
r8_b        dq 0

; ---------------- R9/R10 helpers (rand_bool tests)
align 8
mR9         db "R9 (rand_bool determinism): got=",0
mR10        db "R10 (rand_bool fallback integration): got=",0

b_a         dq 0
b_b         dq 0
b_c         dq 0
b_d         dq 0
b_e         dq 0
b_f         dq 0


; ---------------- R11-R15 helpers (rand_range tests)
align 8
mR11        db "R11 (rand_range max==0 -> ERR_BADARG): got=",0
mR12        db "R12 (rand_range max==1 -> expect 0): got=",0
mR13        db "R13 (rand_range max==2 determinism): got=",0
mR14        db "R14 (rand_range max==UINT64_MAX determinism): got=",0
mR15        db "R15 (rand_range max==UINT64_MAX fallback): got=",0

r11_code    dq 0
r12_a       dq 0

r13_a       dq 0
r13_b       dq 0
r13_c       dq 0
r13_d       dq 0

r14_a       dq 0
r14_b       dq 0
r14_c       dq 0
r14_d       dq 0

r15_a       dq 0
r15_b       dq 0

max_u64     dq 0FFFFFFFFFFFFFFFFh

; Signed-range tests for rand_range_s64
align 8
mS1        db "S1 (rand_range_s64 min>=max -> ERR_BADARG): got=",0
mS2        db "S2 (rand_range_s64 width==1 -> expect min): got=",0
mS3        db "S3 (rand_range_s64 determinism): got=",0
mS4        db "S4 (rand_range_s64 INT64_MIN..INT64_MIN+2 determinism & fallback): got=",0

s1_min     dq 5
s1_max     dq 5

s2_min     dq 10
s2_max     dq 11
s2_a       dq 0

s3_min     dq -3
s3_max     dq 3
s3_a       dq 0
s3_b       dq 0
s3_c       dq 0
s3_d       dq 0

s4_min     dq 8000000000000000h
s4_max     dq 8000000000000002h
s4_a       dq 0
s4_b       dq 0
s4_c       dq 0
s4_d       dq 0

.code
main PROC
    ; initialize I/O
    call    io_init


    ; Header
    lea     rcx, hdr
    call    io_print_string

    ; ---------------- R1 ----------------
    lea     rcx, mR1
    call    io_print_string

    mov     rcx, qword ptr [seed1]   ; new seed
    call    rand_seed                ; RAX = old
    mov     qword ptr [last_old], rax

    ; print "0x" + hex(old)
    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [last_old]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    ; PASS/FAIL (expect old == 0)
    mov     r8, qword ptr [last_old]
    test    r8, r8
    jz      r1_pass
r1_fail:
    lea     rcx, msg_fail
    call    io_print_string
    jmp     r2
r1_pass:
    lea     rcx, msg_pass
    call    io_print_string

    ; ---------------- R2 ----------------
r2:
    lea     rcx, mR2
    call    io_print_string

    mov     rcx, qword ptr [seed1]
    call    rand_seed
    mov     qword ptr [last_old], rax

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [last_old]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     r8, qword ptr [seed1]
    mov     r9, qword ptr [last_old]
    cmp     r9, r8
    je      r2_pass
    lea     rcx, msg_fail
    call    io_print_string
    jmp     r3
r2_pass:
    lea     rcx, msg_pass
    call    io_print_string

    ; ---------------- R3 ----------------
r3:
    lea     rcx, mR3
    call    io_print_string

    xor     rcx, rcx                 ; seed = 0 (trigger fallback install)
    call     rand_seed
    mov     qword ptr [last_old], rax

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [last_old]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     r8, qword ptr [seed1]
    mov     r9, qword ptr [last_old]
    cmp     r9, r8
    je      r3_pass
    lea     rcx, msg_fail
    call    io_print_string
    jmp     r4
r3_pass:
    lea     rcx, msg_pass
    call    io_print_string

    ; ---------------- R4 ----------------
r4:
    lea     rcx, mR4
    call    io_print_string

    mov     rcx, qword ptr [seed2]
    call     rand_seed
    mov     qword ptr [last_old], rax

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [last_old]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     r8, qword ptr [fallback]
    mov     r9, qword ptr [last_old]
    cmp     r9, r8
    je      r4_pass
    lea     rcx, msg_fail
    call    io_print_string
    lea     rcx, mR4exp
    call    io_print_string
    ; fall through to R5/R6/R7/R8 (do not exit early)
r4_pass:
    lea     rcx, msg_pass
    call    io_print_string

    ; ---------------- R5 ----------------
    lea     rcx, mR5
    call    io_print_string

    ; seed with seed1, produce two outputs (unsigned)
    mov     rcx, qword ptr [seed1]
    call    rand_seed
    call    rand_u64
    mov     qword ptr [r5_a], rax

    call    rand_u64
    mov     qword ptr [r5_b], rax

    ; reseed with same seed1, produce two outputs again
    mov     rcx, qword ptr [seed1]
    call    rand_seed
    call    rand_u64
    mov     qword ptr [r5_c], rax

    call    rand_u64
    mov     qword ptr [r5_d], rax

    ; print the first pair (hex)
    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r5_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r5_b]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    ; check determinism: (a==c) && (b==d)
    mov     rax, qword ptr [r5_a]
    mov     r8,  qword ptr [r5_c]
    cmp     rax, r8
    jne     r5_fail
    mov     rax, qword ptr [r5_b]
    mov     r8,  qword ptr [r5_d]
    cmp     rax, r8
    jne     r5_fail

    lea     rcx, msg_pass
    call    io_print_string
    jmp     r5_done

r5_fail:
    lea     rcx, msg_fail
    call    io_print_string
r5_done:

    ; ---------------- R6 ----------------
    lea     rcx, mR6
    call    io_print_string

    ; seed explicitly with fallback, generate one unsigned output
    mov     rcx, qword ptr [fallback]
    call    rand_seed
    call    rand_u64
    mov     qword ptr [r6_a], rax

    ; seed with zero (rand_seed should install fallback), generate one unsigned output
    xor     rcx, rcx
    call    rand_seed
    call    rand_u64
    mov     qword ptr [r6_b], rax

    ; print R6 outputs (hex)
    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r6_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r6_b]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    ; compare R6 outputs (should be equal)
    mov     rax, qword ptr [r6_a]
    mov     r8,  qword ptr [r6_b]
    cmp     rax, r8
    je      r6_pass

    lea     rcx, msg_fail
    call    io_print_string
    jmp     done

r6_pass:
    lea     rcx, msg_pass
    call    io_print_string

    ; ---------------- R7 (signed determinism) ----------------
    lea     rcx, mR7
    call    io_print_string

    ; seed with seed1, produce two signed outputs
    mov     rcx, qword ptr [seed1]
    call    rand_seed
    call    rand_s64
    mov     qword ptr [r7_a], rax

    call    rand_s64
    mov     qword ptr [r7_b], rax

    ; reseed with same seed1, produce two signed outputs again
    mov     rcx, qword ptr [seed1]
    call    rand_seed
    call    rand_s64
    mov     qword ptr [r7_c], rax

    call    rand_s64
    mov     qword ptr [r7_d], rax

    ; print the first signed result (hex and signed decimal)
    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r7_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    ; signed decimal
    mov     rcx, qword ptr [r7_a]
    call    io_print_int
    call    io_print_newline

    ; print the second signed result (hex and signed decimal)
    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r7_b]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rcx, qword ptr [r7_b]
    call    io_print_int
    call    io_print_newline

    ; check determinism: (a==c) && (b==d)
    mov     rax, qword ptr [r7_a]
    mov     r8,  qword ptr [r7_c]
    cmp     rax, r8
    jne     r7_fail
    mov     rax, qword ptr [r7_b]
    mov     r8,  qword ptr [r7_d]
    cmp     rax, r8
    jne     r7_fail

    lea     rcx, msg_pass
    call    io_print_string
    jmp     r7_done

r7_fail:
    lea     rcx, msg_fail
    call    io_print_string
r7_done:

    ; ---------------- R8 (signed fallback integration) ----------------
    lea     rcx, mR8
    call    io_print_string

    ; seed explicitly with fallback, signed output
    mov     rcx, qword ptr [fallback]
    call    rand_seed
    call    rand_s64
    mov     qword ptr [r8_a], rax

    ; seed with zero (rand_seed should install fallback), signed output
    xor     rcx, rcx
    call    rand_seed
    call    rand_s64
    mov     qword ptr [r8_b], rax

    ; print R8 outputs (hex and signed decimal)
    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r8_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rcx, qword ptr [r8_a]
    call    io_print_int
    call    io_print_newline

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r8_b]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rcx, qword ptr [r8_b]
    call    io_print_int
    call    io_print_newline

    ; compare R8 outputs (should be equal)
    mov     rax, qword ptr [r8_a]
    mov     r8,  qword ptr [r8_b]
    cmp     rax, r8
    je      r8_pass

    lea     rcx, msg_fail
    call    io_print_string
    jmp     done

r8_pass:
    lea     rcx, msg_pass
    call    io_print_string

        ; ---------------- R9 (rand_bool determinism)
    lea     rcx, mR9
    call    io_print_string

    mov     rcx, qword ptr [seed1]
    call    rand_seed
    call    rand_bool
    and     rax, 1
    mov     qword ptr [b_a], rax

    call    rand_bool
    and     rax, 1
    mov     qword ptr [b_b], rax

    mov     rcx, qword ptr [seed1]
    call    rand_seed
    call    rand_bool
    and     rax, 1
    mov     qword ptr [b_c], rax

    call    rand_bool
    and     rax, 1
    mov     qword ptr [b_d], rax

    mov     rcx, qword ptr [b_a]
    call    io_print_int
    call    io_print_newline

    mov     rcx, qword ptr [b_b]
    call    io_print_int
    call    io_print_newline

    mov     rax, qword ptr [b_a]
    mov     r8,  qword ptr [b_c]
    cmp     rax, r8
    jne     r9_fail
    mov     rax, qword ptr [b_b]
    mov     r8,  qword ptr [b_d]
    cmp     rax, r8
    jne     r9_fail

    lea     rcx, msg_pass
    call    io_print_string
    jmp     r9_done

r9_fail:
    lea     rcx, msg_fail
    call    io_print_string
r9_done:

    ; ---------------- R10 (rand_bool fallback integration)
    lea     rcx, mR10
    call    io_print_string

    mov     rcx, qword ptr [fallback]
    call    rand_seed
    call    rand_bool
    and     rax, 1
    mov     qword ptr [b_e], rax

    xor     rcx, rcx
    call    rand_seed
    call    rand_bool
    and     rax, 1
    mov     qword ptr [b_f], rax

    mov     rcx, qword ptr [b_e]
    call    io_print_int
    call    io_print_newline

    mov     rcx, qword ptr [b_f]
    call    io_print_int
    call    io_print_newline

    mov     rax, qword ptr [b_e]
    mov     r8,  qword ptr [b_f]
    cmp     rax, r8
    je      r10_pass

    lea     rcx, msg_fail
    call    io_print_string
    jmp     done

r10_pass:
    lea     rcx, msg_pass
    call    io_print_string


        ; ---------------- R11 (rand_range max==0 -> ERR_BADARG)
    lea     rcx, mR11
    call    io_print_string

    xor     rcx, rcx
    call    rand_range
    jc      r11_err                ; expected: CF=1

    ; unexpected success
    lea     rcx, msg_fail
    call    io_print_string
    jmp     r11_done

r11_err:
    cmp     eax, ERR_BADARG
    je      r11_pass
    lea     rcx, msg_fail
    call    io_print_string
    jmp     r11_done

r11_pass:
    lea     rcx, msg_pass
    call    io_print_string
r11_done:

    ; ---------------- R12 (rand_range max==1 -> must return 0)
    lea     rcx, mR12
    call    io_print_string

    mov     rcx, 1
    call    rand_range
    jc      r12_fail
    mov     qword ptr [r12_a], rax

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r12_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rcx, qword ptr [r12_a]
    call    io_print_int
    call    io_print_newline

    mov     rax, qword ptr [r12_a]
    test    rax, rax
    jz      r12_pass

r12_fail:
    lea     rcx, msg_fail
    call    io_print_string
    jmp     r12_done

r12_pass:
    lea     rcx, msg_pass
    call    io_print_string
r12_done:

    ; ---------------- R13 (rand_range max==2 determinism)
    lea     rcx, mR13
    call    io_print_string

    mov     rcx, qword ptr [seed1]
    call    rand_seed

    mov     rcx, 2
    call    rand_range
    mov     qword ptr [r13_a], rax

    mov     rcx, 2
    call    rand_range
    mov     qword ptr [r13_b], rax

    ; reseed and repeat
    mov     rcx, qword ptr [seed1]
    call    rand_seed

    mov     rcx, 2
    call    rand_range
    mov     qword ptr [r13_c], rax

    mov     rcx, 2
    call    rand_range
    mov     qword ptr [r13_d], rax

    mov     rcx, qword ptr [r13_a]
    call    io_print_int
    call    io_print_newline

    mov     rcx, qword ptr [r13_b]
    call    io_print_int
    call    io_print_newline

    mov     rax, qword ptr [r13_a]
    mov     r8,  qword ptr [r13_c]
    cmp     rax, r8
    jne     r13_fail
    mov     rax, qword ptr [r13_b]
    mov     r8,  qword ptr [r13_d]
    cmp     rax, r8
    jne     r13_fail

    lea     rcx, msg_pass
    call    io_print_string
    jmp     r13_done

r13_fail:
    lea     rcx, msg_fail
    call    io_print_string
r13_done:

    ; ---------------- R14 (rand_range max==UINT64_MAX determinism)
    lea     rcx, mR14
    call    io_print_string

    mov     rcx, qword ptr [seed1]
    call    rand_seed

    mov     rcx, qword ptr [max_u64]
    call    rand_range
    mov     qword ptr [r14_a], rax

    mov     rcx, qword ptr [max_u64]
    call    rand_range
    mov     qword ptr [r14_b], rax

    ; reseed and repeat
    mov     rcx, qword ptr [seed1]
    call    rand_seed

    mov     rcx, qword ptr [max_u64]
    call    rand_range
    mov     qword ptr [r14_c], rax

    mov     rcx, qword ptr [max_u64]
    call    rand_range
    mov     qword ptr [r14_d], rax

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r14_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r14_b]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rax, qword ptr [r14_a]
    mov     r8,  qword ptr [r14_c]
    cmp     rax, r8
    jne     r14_fail
    mov     rax, qword ptr [r14_b]
    mov     r8,  qword ptr [r14_d]
    cmp     rax, r8
    jne     r14_fail

    lea     rcx, msg_pass
    call    io_print_string
    jmp     r14_done

r14_fail:
    lea     rcx, msg_fail
    call    io_print_string
r14_done:

    ; ---------------- R15 (rand_range max==UINT64_MAX fallback integration)
    lea     rcx, mR15
    call    io_print_string

    mov     rcx, qword ptr [fallback]
    call    rand_seed
    mov     rcx, qword ptr [max_u64]
    call    rand_range
    mov     qword ptr [r15_a], rax

    xor     rcx, rcx
    call    rand_seed
    mov     rcx, qword ptr [max_u64]
    call    rand_range
    mov     qword ptr [r15_b], rax

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r15_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [r15_b]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rax, qword ptr [r15_a]
    mov     r8,  qword ptr [r15_b]
    cmp     rax, r8
    je      r15_pass

    lea     rcx, msg_fail
    call    io_print_string
    jmp     done

r15_pass:
    lea     rcx, msg_pass
    call    io_print_string

        ; ---------------- S1 (rand_range_s64 min>=max -> ERR_BADARG)
    lea     rcx, mS1
    call    io_print_string

    mov     rcx, qword ptr [s1_min]
    mov     rdx, qword ptr [s1_max]
    call    rand_range_s64
    jc      s1_err                ; expected: CF=1

    ; unexpected success
    lea     rcx, msg_fail
    call    io_print_string
    jmp     s1_done

s1_err:
    cmp     eax, ERR_BADARG
    je      s1_pass
    lea     rcx, msg_fail
    call    io_print_string
    jmp     s1_done

s1_pass:
    lea     rcx, msg_pass
    call    io_print_string
s1_done:

    ; ---------------- S2 (rand_range_s64 width==1 -> must return min)
    lea     rcx, mS2
    call    io_print_string

    mov     rcx, qword ptr [s2_min]
    mov     rdx, qword ptr [s2_max]
    call    rand_range_s64
    jc      s2_fail
    mov     qword ptr [s2_a], rax

    ; print result (hex + signed)
    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [s2_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rcx, qword ptr [s2_a]
    call    io_print_int
    call    io_print_newline

    mov     rax, qword ptr [s2_a]
    mov     r8, qword ptr [s2_min]
    cmp     rax, r8
    je      s2_pass

s2_fail:
    lea     rcx, msg_fail
    call    io_print_string
    jmp     s2_done

s2_pass:
    lea     rcx, msg_pass
    call    io_print_string
s2_done:

    ; ---------------- S3 (rand_range_s64 determinism)
    lea     rcx, mS3
    call    io_print_string

    ; seed, produce two values
    mov     rcx, qword ptr [seed1]
    call    rand_seed

    mov     rcx, qword ptr [s3_min]
    mov     rdx, qword ptr [s3_max]
    call    rand_range_s64
    mov     qword ptr [s3_a], rax

    mov     rcx, qword ptr [s3_min]
    mov     rdx, qword ptr [s3_max]
    call    rand_range_s64
    mov     qword ptr [s3_b], rax

    ; reseed and repeat
    mov     rcx, qword ptr [seed1]
    call    rand_seed

    mov     rcx, qword ptr [s3_min]
    mov     rdx, qword ptr [s3_max]
    call    rand_range_s64
    mov     qword ptr [s3_c], rax

    mov     rcx, qword ptr [s3_min]
    mov     rdx, qword ptr [s3_max]
    call    rand_range_s64
    mov     qword ptr [s3_d], rax

    ; print first pair (signed)
    mov     rcx, qword ptr [s3_a]
    call    io_print_int
    call    io_print_newline

    mov     rcx, qword ptr [s3_b]
    call    io_print_int
    call    io_print_newline

    mov     rax, qword ptr [s3_a]
    mov     r8,  qword ptr [s3_c]
    cmp     rax, r8
    jne     s3_fail
    mov     rax, qword ptr [s3_b]
    mov     r8,  qword ptr [s3_d]
    cmp     rax, r8
    jne     s3_fail

    lea     rcx, msg_pass
    call    io_print_string
    jmp     s3_done

s3_fail:
    lea     rcx, msg_fail
    call    io_print_string
s3_done:

    ; ---------------- S4 (rand_range_s64 INT64_MIN..INT64_MIN+2 determinism & fallback)
    lea     rcx, mS4
    call    io_print_string

    mov     rcx, qword ptr [seed1]
    call    rand_seed

    mov     rcx, qword ptr [s4_min]
    mov     rdx, qword ptr [s4_max]
    call    rand_range_s64
    mov     qword ptr [s4_a], rax

    mov     rcx, qword ptr [s4_min]
    mov     rdx, qword ptr [s4_max]
    call    rand_range_s64
    mov     qword ptr [s4_b], rax

    ; reseed and repeat
    mov     rcx, qword ptr [seed1]
    call    rand_seed

    mov     rcx, qword ptr [s4_min]
    mov     rdx, qword ptr [s4_max]
    call    rand_range_s64
    mov     qword ptr [s4_c], rax

    mov     rcx, qword ptr [s4_min]
    mov     rdx, qword ptr [s4_max]
    call    rand_range_s64
    mov     qword ptr [s4_d], rax

    ; print outputs (hex)
    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [s4_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [s4_b]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rax, qword ptr [s4_a]
    mov     r8,  qword ptr [s4_c]
    cmp     rax, r8
    jne     s4_fail
    mov     rax, qword ptr [s4_b]
    mov     r8,  qword ptr [s4_d]
    cmp     rax, r8
    jne     s4_fail

    ; fallback integration (seed fallback vs seed 0)
    mov     rcx, qword ptr [fallback]
    call    rand_seed
    mov     rcx, qword ptr [s4_min]
    mov     rdx, qword ptr [s4_max]
    call    rand_range_s64
    mov     qword ptr [s4_a], rax

    xor     rcx, rcx
    call    rand_seed
    mov     rcx, qword ptr [s4_min]
    mov     rdx, qword ptr [s4_max]
    call    rand_range_s64
    mov     qword ptr [s4_b], rax

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [s4_a]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    lea     rcx, got_hex
    call    io_print_string
    mov     rcx, qword ptr [s4_b]
    mov     rdx, 16
    call    io_print_hex
    call    io_print_newline

    mov     rax, qword ptr [s4_a]
    mov     r8,  qword ptr [s4_b]
    cmp     rax, r8
    je      s4_pass

s4_fail:
    lea     rcx, msg_fail
    call    io_print_string
    jmp     s4_done

s4_pass:
    lea     rcx, msg_pass
    call    io_print_string
s4_done:


done:
    xor     ecx, ecx
    ret
main ENDP

END