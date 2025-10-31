;=========================================================
; iosanity.asm — minimal smoke test for io_print_newline
;=========================================================
OPTION casemap:none
OPTION prologue:none, epilogue:none

INCLUDE AsmEase64.inc
INCLUDE win32_console.inc



.data
msgSuite    db "I/O Sanity Tests",13,10
msgSuiteLen EQU ($-msgSuite)

msgT1       db "T1 (io_print_newline): expect RAX=2 ... "
msgT1Len    EQU ($-msgT1)

msgT2       db "T2 (io_print_newline x2): expect two calls return 2 ... "
msgT2Len    EQU ($-msgT2)

msgPASS     db "PASS",13,10
msgPASSLen  EQU ($-msgPASS)
msgFAIL     db "FAIL",13,10
msgFAILLen  EQU ($-msgFAIL)

hStdout     dq 0

; ---- io_print_char tests ----
msgT3   db "T3 (io_print_char 'A'): expect RAX=1 ... "
msgT3Len EQU ($-msgT3)

msgT4   db "T4 (io_print_char NUL 0x00): expect RAX=1 (may be invisible) ... "
msgT4Len EQU ($-msgT4)

msgT5   db "T5 (io_print_char 0xFF): expect RAX=1 ... "
msgT5Len EQU ($-msgT5)

msgT6   db "T6 (io_print_char x5 burst): expect each call RAX=1 ... "
msgT6Len EQU ($-msgT6)

msgT7     db "T7 (io_print_string NULL): expect ERR_NULLPTR ... ",0
msgT7Len  EQU ($-msgT7-1)

msgT8     db "T8 (io_print_string empty): expect CF=0, RAX=0 ... ",0
msgT8Len  EQU ($-msgT8-1)

msgT9     db "T9 (io_print_string 'ABC'): expect RAX=3 ... ",0
msgT9Len  EQU ($-msgT9-1)

msgT10   db "T10 (io_print_string with embedded NUL): expect 'X' only (1) ... "
msgT10Len EQU ($-msgT10)

strEmpty db 0
strABC   db "ABC", 0


; ---- io_print_uint tests ----
msgT11    db "T11 (io_print_uint 0): expect RAX=1 ... "
msgT11Len EQU ($-msgT11)

msgT12    db "T12 (io_print_uint 7): expect RAX=1 ... "
msgT12Len EQU ($-msgT12)

msgT13    db "T13 (io_print_uint 42): expect RAX=2 ... "
msgT13Len EQU ($-msgT13)

msgT14    db "T14 (io_print_uint 1234567890): expect RAX=10 ... "
msgT14Len EQU ($-msgT14)

msgT15    db "T15 (io_print_uint max u64): expect RAX=20 ... "
msgT15Len EQU ($-msgT15)

msgT16    db "T16 (io_print_uint burst): expect counts 1,2,3 ... "
msgT16Len EQU ($-msgT16)

; ---- io_print_int tests ----
msgT17    db "T17 (io_print_int 0): expect RAX=1 ... "
msgT17Len EQU ($-msgT17)

msgT18    db "T18 (io_print_int -7): expect RAX=2 ... "
msgT18Len EQU ($-msgT18)

msgT19    db "T19 (io_print_int 42): expect RAX=2 ... "
msgT19Len EQU ($-msgT19)

msgT20    db "T20 (io_print_int INT64_MIN): expect RAX=20 ... "
msgT20Len EQU ($-msgT20)

msgT21    db "T21 (io_print_int INT64_MAX): expect RAX=19 ... "
msgT21Len EQU ($-msgT21)

msgT22    db "T22 (io_print_int burst -1,0,123): expect 2,1,3 ... "
msgT22Len EQU ($-msgT22)


; ---- io_print_hex tests ----
msgT23    db "T23 (io_print_hex 0,min=0): expect 1 digit '0' ... "
msgT23Len EQU ($-msgT23)

msgT24    db "T24 (io_print_hex 0,min=8): expect 8 zeros ... "
msgT24Len EQU ($-msgT24)

msgT25    db "T25 (io_print_hex 0xA,min=0): expect 'A' (1) ... "
msgT25Len EQU ($-msgT25)

msgT26    db "T26 (io_print_hex 0xA,min=2): expect '0A' (2) ... "
msgT26Len EQU ($-msgT26)

msgT27    db "T27 (io_print_hex 0x1234ABCD,min=0): expect 8 digits ... "
msgT27Len EQU ($-msgT27)

msgT28    db "T28 (io_print_hex max u64,min=0): expect 16 'F's ... "
msgT28Len EQU ($-msgT28)

msgT29    db "T29 (io_print_hex min_digits clamp>16 -> 16): expect 16 digits ... "
msgT29Len EQU ($-msgT29)


; ---- io_print_binary tests ----
msgT30    db "T30 (io_print_binary 0,min=0): expect '0' (1) ... "
msgT30Len EQU ($-msgT30)

msgT31    db "T31 (io_print_binary 0,min=8): expect 8 zeros ... "
msgT31Len EQU ($-msgT31)

msgT32    db "T32 (io_print_binary 5,min=0): expect '101' (3) ... "
msgT32Len EQU ($-msgT32)

msgT33    db "T33 (io_print_binary 5,min=8): expect '00000101' (8) ... "
msgT33Len EQU ($-msgT33)

msgT34    db "T34 (io_print_binary 1<<63,min=0): expect 64 bits ... "
msgT34Len EQU ($-msgT34)

msgT35    db "T35 (io_print_binary max u64,min=0): expect 64 bits ... "
msgT35Len EQU ($-msgT35)

msgT36    db "T36 (io_print_binary clamp>64 -> 64): expect 64 bits ... "
msgT36Len EQU ($-msgT36)

; ---- io_print_float tests ----
msgT37   db "T37 (io_print_float 0.0, p=0): expect '0' ... "
msgT37Len EQU ($-msgT37)

msgT38   db "T38 (io_print_float 0.0, p=3): expect '0.000' ... "
msgT38Len EQU ($-msgT38)

msgT39   db "T39 (io_print_float 1.0, p=0): expect '1' ... "
msgT39Len EQU ($-msgT39)

msgT40   db "T40 (io_print_float -1.25, p=2): expect '-1.25' ... "
msgT40Len EQU ($-msgT40)

msgT41   db "T41 (io_print_float 3.14159265, p=2): expect '3.14' ... "
msgT41Len EQU ($-msgT41)

msgT42   db "T42 (io_print_float 3.14159265, p=6): expect '3.141593' ... "
msgT42Len EQU ($-msgT42)

msgT43   db "T43 (io_print_float 1234567890123.0, p=0): large int ... "
msgT43Len EQU ($-msgT43)

msgT44   db "T44 (io_print_float 1.999, p=2): rounding -> '2.00' ... "
msgT44Len EQU ($-msgT44)

msgT45   db "T45 (io_print_float +INF, p=3): expect 'inf' ... "
msgT45Len EQU ($-msgT45)

msgT46   db "T46 (io_print_float -INF, p=1): expect '-inf' ... "
msgT46Len EQU ($-msgT46)

msgT47   db "T47 (io_print_float NaN, p=2): expect 'nan' ... "
msgT47Len EQU ($-msgT47)

; ---- double bit patterns ----
d_zero          dq 0000000000000000h
d_one           dq 3FF0000000000000h
d_neg1_25       dq 0BFF4000000000000h
d_pi            dq 400921FB54442D18h
d_large         real8 1234567890123.0
d_1_999         real8 1.999


; IEEE-754 binary64 patterns
;d_pos_inf   dq 7FF0000000000000h   ; +INF
;d_qnan      dq 7FF8000000000000h   ; a common quiet NaN
;d_neg_inf  db  00h,00h,00h,00h, 00h,00h,F0h,0FFh  ; same value




.code

; tiny inline banner writer macro using WriteFile + correct shadow slots
write_lit MACRO p, n
    mov   ecx, STD_OUTPUT_HANDLE
    call  GetStdHandle
    mov   [hStdout], rax

    mov   rcx, [hStdout]
    lea   rdx, p
    mov   r8d, n
    lea   r9,  [rsp+18h]           ; <-- was +28h, FIXED
    mov   qword ptr [rsp+20h], 0
    mov   dword ptr [rsp+18h], 0
    call  WriteFile
ENDM


main PROC
    SAFE_PROLOGUE

    write_lit msgSuite, msgSuiteLen

    ; ===== T1 =====
    write_lit msgT1, msgT1Len
    call io_print_newline
    jc   t1_fail
    cmp  rax, 2
    jne  t1_fail
    write_lit msgPASS, msgPASSLen
    jmp  t2_begin
t1_fail:
    write_lit msgFAIL, msgFAILLen

    ; ===== T2 =====
t2_begin:
    write_lit msgT2, msgT2Len
    call io_print_newline
    jc   t2_fail
    cmp  rax, 2
    jne  t2_fail
    call io_print_newline
    jc   t2_fail
    cmp  rax, 2
    jne  t2_fail
    write_lit msgPASS, msgPASSLen
    jmp t3_begin
t2_fail:
    write_lit msgFAIL, msgFAILLen
    jmp t3_begin

    ; ====== T3: ASCII 'A' ======
t3_begin:
    write_lit msgT3, msgT3Len
    mov  rcx, 'A'                  ; low 8 bits used
    call io_print_char
    jc   t3_fail
    cmp  rax, 1
    jne  t3_fail
    write_lit msgPASS, msgPASSLen
    jmp  t4_begin
t3_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t4_begin

; ====== T4: NUL (0x00) ======
t4_begin:
    write_lit msgT4, msgT4Len
    xor  rcx, rcx                  ; ch = 0x00
    call io_print_char
    jc   t4_fail
    cmp  rax, 1
    jne  t4_fail
    write_lit msgPASS, msgPASSLen
    jmp  t5_begin
t4_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t5_begin

; ====== T5: 0xFF ======
t5_begin:
    write_lit msgT5, msgT5Len
    mov  rcx, 0FFh                 ; ch = 0xFF
    call io_print_char
    jc   t5_fail
    cmp  rax, 1
    jne  t5_fail
    write_lit msgPASS, msgPASSLen
    jmp  t6_begin
t5_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t6_begin

; ====== T6: small burst (5 chars) ======
t6_begin:
    write_lit msgT6, msgT6Len
    mov  ecx, 'H'
    call io_print_char
    cmp  rax, 1
    jne  t6_fail

    mov  ecx, 'e'
    call io_print_char
    cmp  rax, 1
    jne  t6_fail

    mov  ecx, 'l'
    call io_print_char
    cmp  rax, 1
    jne  t6_fail

    mov  ecx, 'l'
    call io_print_char
    cmp  rax, 1
    jne  t6_fail

    mov  ecx, 'o'
    call io_print_char
    cmp  rax, 1
    jne  t6_fail

    write_lit msgPASS, msgPASSLen
    jmp  t7_begin
t6_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t7_begin
    


; ====== T7: NULL -> ERR_NULLPTR ======
t7_begin:
    write_lit msgT7, msgT7Len
    xor  rcx, rcx
    call io_print_string
    jnc  t7_fail
    cmp  eax, ERR_NULLPTR
    jne  t7_fail
    write_lit msgPASS, msgPASSLen
    jmp  t8_begin
t7_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t8_begin

; ====== T8: empty "" -> 0 bytes ======
t8_begin:
    write_lit msgT8, msgT8Len
    lea  rcx, strEmpty
	call io_print_string
    jc   t8_fail
    test rax, rax
    jne  t8_fail
    write_lit msgPASS, msgPASSLen
    jmp  t9_begin
t8_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t9_begin

; ====== T9: "ABC" -> 3 bytes ======
t9_begin:
    write_lit msgT9, msgT9Len
    lea  rcx, strABC
	call io_print_string
    jc   t9_fail
    cmp  rax, 3
    jne  t9_fail
    write_lit msgPASS, msgPASSLen
    ; (skip former T10; it doesn’t apply to C-strings)
    jmp  t10_begin
t9_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t10_begin

    ; ====== T10: embedded NUL -> stops at first NUL, prints 1 byte ('X') ======
t10_begin:
    write_lit msgT10, msgT10Len

    ; Build buffer: 'X', 0, 'Y', 0xFF ... only 'X' should print
    mov  byte ptr [rsp+10h], 'X'
    mov  byte ptr [rsp+11h], 0
    mov  byte ptr [rsp+12h], 'Y'
    mov  byte ptr [rsp+13h], 0FFh

    lea  rcx, [rsp+10h]           ; NUL-terminated string at [rsp+10h]
    call io_print_string          ; should print just 'X'
    jc   t10_fail                 ; CF must be 0
    cmp  rax, 1                   ; must report 1 byte written
    jne  t10_fail

    write_lit msgPASS, msgPASSLen
    jmp  t11_begin

t10_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t11_begin



; ====== T11: 0 -> "0" (1 byte) ======
t11_begin:
    write_lit msgT11, msgT11Len
    xor  rcx, rcx                  ; value = 0
    call io_print_uint
    jc   t11_fail
    cmp  rax, 1
    jne  t11_fail
    write_lit msgPASS, msgPASSLen
    jmp  t12_begin
t11_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t12_begin

; ====== T12: 7 -> "7" (1 byte) ======
t12_begin:
    write_lit msgT12, msgT12Len
    mov  rcx, 7
    call io_print_uint
    jc   t12_fail
    cmp  rax, 1
    jne  t12_fail
    write_lit msgPASS, msgPASSLen
    jmp  t13_begin
t12_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t13_begin

; ====== T13: 42 -> "42" (2 bytes) ======
t13_begin:
    write_lit msgT13, msgT13Len
    mov  rcx, 42
    call io_print_uint
    jc   t13_fail
    cmp  rax, 2
    jne  t13_fail
    write_lit msgPASS, msgPASSLen
    jmp  t14_begin
t13_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t14_begin

; ====== T14: 1234567890 -> 10 bytes ======
t14_begin:
    write_lit msgT14, msgT14Len
    mov  rcx, 1234567890           ; fits in 32-bit imm
    call io_print_uint
    jc   t14_fail
    cmp  rax, 10
    jne  t14_fail
    write_lit msgPASS, msgPASSLen
    jmp  t15_begin
t14_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t15_begin

; ====== T15: MAX U64 -> 20 bytes ======
; 18446744073709551615 = 0xFFFFFFFFFFFFFFFF (bit pattern of -1)
t15_begin:
    write_lit msgT15, msgT15Len
    mov  rcx, -1                   ; same bit-pattern as max u64
    call io_print_uint
    jc   t15_fail
    cmp  rax, 20
    jne  t15_fail
    write_lit msgPASS, msgPASSLen
    jmp  t16_begin
t15_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t16_begin

; ====== T16: small burst (1, 22, 333) -> lengths 1,2,3 ======
t16_begin:
    write_lit msgT16, msgT16Len

    mov  rcx, 1
    call io_print_uint
    cmp  rax, 1
    jne  t16_fail

    mov  rcx, 22
    call io_print_uint
    cmp  rax, 2
    jne  t16_fail

    mov  rcx, 333
    call io_print_uint
    cmp  rax, 3
    jne  t16_fail

    write_lit msgPASS, msgPASSLen
    jmp  t17_begin
t16_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t17_begin


; ====== T17: 0 -> "0" (1 byte) ======
t17_begin:
    write_lit msgT17, msgT17Len
    xor  rcx, rcx
    call io_print_int
    jc   t17_fail
    cmp  rax, 1
    jne  t17_fail
    write_lit msgPASS, msgPASSLen
    jmp  t18_begin
t17_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t18_begin

; ====== T18: -7 -> "-7" (2 bytes) ======
t18_begin:
    write_lit msgT18, msgT18Len
    mov  rcx, -7
    call io_print_int
    jc   t18_fail
    cmp  rax, 2
    jne  t18_fail
    write_lit msgPASS, msgPASSLen
    jmp  t19_begin
t18_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t19_begin

; ====== T19: 42 -> "42" (2 bytes) ======
t19_begin:
    write_lit msgT19, msgT19Len
    mov  rcx, 42
    call io_print_int
    jc   t19_fail
    cmp  rax, 2
    jne  t19_fail
    write_lit msgPASS, msgPASSLen
    jmp  t20_begin
t19_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t20_begin

; ====== T20: INT64_MIN -> "-9223372036854775808" (20 bytes) ======
t20_begin:
    write_lit msgT20, msgT20Len
    mov  rcx, 8000000000000000h     ; bit pattern of INT64_MIN
    neg  rcx                        ; RCX becomes INT64_MIN as signed (-2^63)
    call io_print_int
    jc   t20_fail
    cmp  rax, 20
    jne  t20_fail
    write_lit msgPASS, msgPASSLen
    jmp  t21_begin
t20_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t21_begin

; ====== T21: INT64_MAX -> "9223372036854775807" (19 bytes) ======
t21_begin:
    write_lit msgT21, msgT21Len
    mov  rcx, 7FFFFFFFFFFFFFFFh
    call io_print_int
    jc   t21_fail
    cmp  rax, 19
    jne  t21_fail
    write_lit msgPASS, msgPASSLen
    jmp  t22_begin
t21_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t22_begin

; ====== T22: burst: -1, 0, 123 -> lens 2,1,3 ======
t22_begin:
    write_lit msgT22, msgT22Len

    mov  rcx, -1
    call io_print_int
    cmp  rax, 2
    jne  t22_fail

    xor  rcx, rcx
    call io_print_int
    cmp  rax, 1
    jne  t22_fail

    mov  rcx, 123
    call io_print_int
    cmp  rax, 3
    jne  t22_fail

    write_lit msgPASS, msgPASSLen
    jmp  t23_begin
t22_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t23_begin



; ====== T23: value=0, min=0 -> "0" (1) ======
t23_begin:
    write_lit msgT23, msgT23Len
    xor  rcx, rcx                  ; value = 0
    xor  rdx, rdx                  ; min   = 0
    call io_print_hex
    jc   t23_fail
    cmp  rax, 1
    jne  t23_fail
    write_lit msgPASS, msgPASSLen
    jmp  t24_begin
t23_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t24_begin

; ====== T24: value=0, min=8 -> "00000000" (8) ======
t24_begin:
    write_lit msgT24, msgT24Len
    xor  rcx, rcx
    mov  rdx, 8
    call io_print_hex
    jc   t24_fail
    cmp  rax, 8
    jne  t24_fail
    write_lit msgPASS, msgPASSLen
    jmp  t25_begin
t24_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t25_begin

; ====== T25: value=0xA, min=0 -> "A" (1) ======
t25_begin:
    write_lit msgT25, msgT25Len
    mov  rcx, 0Ah
    xor  rdx, rdx
    call io_print_hex
    jc   t25_fail
    cmp  rax, 1
    jne  t25_fail
    write_lit msgPASS, msgPASSLen
    jmp  t26_begin
t25_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t26_begin

; ====== T26: value=0xA, min=2 -> "0A" (2) ======
t26_begin:
    write_lit msgT26, msgT26Len
    mov  rcx, 0Ah
    mov  rdx, 2
    call io_print_hex
    jc   t26_fail
    cmp  rax, 2
    jne  t26_fail
    write_lit msgPASS, msgPASSLen
    jmp  t27_begin
t26_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t27_begin

; ====== T27: value=0x1234ABCD, min=0 -> 8 digits ======
t27_begin:
    write_lit msgT27, msgT27Len
    mov  rcx, 01234ABCDh
    xor  rdx, rdx
    call io_print_hex
    jc   t27_fail
    cmp  rax, 8
    jne  t27_fail
    write_lit msgPASS, msgPASSLen
    jmp  t28_begin
t27_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t28_begin

; ====== T28: value=-1 (max u64), min=0 -> 16 digits ======
t28_begin:
    write_lit msgT28, msgT28Len
    mov  rcx, -1
    xor  rdx, rdx
    call io_print_hex
    jc   t28_fail
    cmp  rax, 16
    jne  t28_fail
    write_lit msgPASS, msgPASSLen
    jmp  t29_begin
t28_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t29_begin

; ====== T29: min_digits clamp test: value=1, min=32 -> expect 16 ======
t29_begin:
    write_lit msgT29, msgT29Len
    mov  rcx, 1
    mov  rdx, 32
    call io_print_hex
    jc   t29_fail
    cmp  rax, 16
    jne  t29_fail
    write_lit msgPASS, msgPASSLen
    jmp  t30_begin
t29_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t30_begin


; ====== T30: value=0, min=0 -> "0" (1) ======
t30_begin:
    write_lit msgT30, msgT30Len
    xor  rcx, rcx
    xor  rdx, rdx
    call io_print_binary
    jc   t30_fail
    cmp  rax, 1
    jne  t30_fail
    write_lit msgPASS, msgPASSLen
    jmp  t31_begin
t30_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t31_begin

; ====== T31: value=0, min=8 -> "00000000" (8) ======
t31_begin:
    write_lit msgT31, msgT31Len
    xor  rcx, rcx
    mov  rdx, 8
    call io_print_binary
    jc   t31_fail
    cmp  rax, 8
    jne  t31_fail
    write_lit msgPASS, msgPASSLen
    jmp  t32_begin
t31_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t32_begin

; ====== T32: 5 -> "101" (3) ======
t32_begin:
    write_lit msgT32, msgT32Len
    mov  rcx, 5
    xor  rdx, rdx
    call io_print_binary
    jc   t32_fail
    cmp  rax, 3
    jne  t32_fail
    write_lit msgPASS, msgPASSLen
    jmp  t33_begin
t32_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t33_begin

; ====== T33: 5 with min=8 -> "00000101" (8) ======
t33_begin:
    write_lit msgT33, msgT33Len
    mov  rcx, 5
    mov  rdx, 8
    call io_print_binary
    jc   t33_fail
    cmp  rax, 8
    jne  t33_fail
    write_lit msgPASS, msgPASSLen
    jmp  t34_begin
t33_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t34_begin

; ====== T34: 1<<63 -> 64 bits ======
t34_begin:
    write_lit msgT34, msgT34Len
    mov  rcx, 8000000000000000h
    xor  rdx, rdx
    call io_print_binary
    jc   t34_fail
    cmp  rax, 64
    jne  t34_fail
    write_lit msgPASS, msgPASSLen
    jmp  t35_begin
t34_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t35_begin

; ====== T35: -1 (max u64) -> 64 bits ======
t35_begin:
    write_lit msgT35, msgT35Len
    mov  rcx, -1
    xor  rdx, rdx
    call io_print_binary
    jc   t35_fail
    cmp  rax, 64
    jne  t35_fail
    write_lit msgPASS, msgPASSLen
    jmp  t36_begin
t35_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t36_begin

; ====== T36: clamp min_bits>64 -> 64 ======
t36_begin:
    write_lit msgT36, msgT36Len
    mov  rcx, 1
    mov  rdx, 128
    call io_print_binary
    jc   t36_fail
    cmp  rax, 64
    jne  t36_fail
    write_lit msgPASS, msgPASSLen
    jmp  t37_begin
t36_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t37_begin


    ; ====== T37 ======
t37_begin:
    write_lit msgT37, msgT37Len
    mov  rcx, qword ptr [d_zero]
    xor  edx, edx
    call io_print_float
    cmp  rax, 1
    jne  t37_fail
    write_lit msgPASS, msgPASSLen
    jmp  t38_begin
t37_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t38_begin

; ====== T38 ======
t38_begin:
    write_lit msgT38, msgT38Len
    mov  rcx, qword ptr [d_zero]
    mov  edx, 3
    call io_print_float
    cmp  rax, 5
    jne  t38_fail
    write_lit msgPASS, msgPASSLen
    jmp  t39_begin
t38_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t39_begin

; ====== T39 ======
t39_begin:
    write_lit msgT39, msgT39Len
    mov  rcx, qword ptr [d_one]
    xor  edx, edx
    call io_print_float
    cmp  rax, 1
    jne  t39_fail
    write_lit msgPASS, msgPASSLen
    jmp  t40_begin
t39_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t40_begin

; ====== T40 ======
t40_begin:
    write_lit msgT40, msgT40Len
    mov  rcx, qword ptr [d_neg1_25]
    mov  edx, 2
    call io_print_float
    cmp  rax, 5
    jne  t40_fail
    write_lit msgPASS, msgPASSLen
    jmp  t41_begin
t40_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t41_begin

; ====== T41 ======
t41_begin:
    write_lit msgT41, msgT41Len
    mov  rcx, qword ptr [d_pi]
    mov  edx, 2
    call io_print_float
    cmp  rax, 4
    jne  t41_fail
    write_lit msgPASS, msgPASSLen
    jmp  t42_begin
t41_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t42_begin

; ====== T42 ======
t42_begin:
    write_lit msgT42, msgT42Len
    mov  rcx, qword ptr [d_pi]
    mov  edx, 6
    call io_print_float
    cmp  rax, 8
    jne  t42_fail
    write_lit msgPASS, msgPASSLen
    jmp  t43_begin
t42_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t43_begin

; ====== T43 ======
t43_begin:
    write_lit msgT43, msgT43Len
    mov  rcx, qword ptr [d_large]
    xor  edx, edx
    call io_print_float
    cmp  rax, 13
    jne  t43_fail
    write_lit msgPASS, msgPASSLen
    jmp  t44_begin
t43_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t44_begin

; ====== T44 ======
t44_begin:
    write_lit msgT44, msgT44Len
    mov  rcx, qword ptr [d_1_999]
    mov  edx, 2
    call io_print_float
    cmp  rax, 4
    jne  t44_fail
    write_lit msgPASS, msgPASSLen
    jmp  t45_begin
t44_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t45_begin

; ====== T45 ======
t45_begin:
    write_lit msgT45, msgT45Len
    mov  rcx, 7FF0000000000000h          ; +inf literal (starts with '7' so OK)
    mov  edx, 3                          ; precision (whatever your test expects)
    xor  r8d, r8d
    call io_print_float
    cmp  rax, 3
    jne  t45_fail
    write_lit msgPASS, msgPASSLen
    jmp  t46_begin
t45_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t46_begin

; ====== T46 ======
t46_begin:
    write_lit msgT46, msgT46Len
    mov  rcx, 7FF0000000000000h          ; start from +inf pattern
    bts  rcx, 63                          ; set sign bit -> becomes -inf
    mov  edx, 1
    xor  r8d, r8d
    call io_print_float
    cmp  rax, 4
    jne  t46_fail
    write_lit msgPASS, msgPASSLen
    jmp  t47_begin
t46_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  t47_begin

; ====== T47 ======
t47_begin:
    write_lit msgT47, msgT47Len
    mov  rcx, 7FF8000000000000h          ; a common quiet NaN literal
    mov  edx, 2
    xor  r8d, r8d
    call io_print_float
    cmp  rax, 3
    jne  t47_fail
    write_lit msgPASS, msgPASSLen
    jmp  done
t47_fail:
    write_lit msgFAIL, msgFAILLen
    jmp  done




done:
    mov  ecx, 0
    call ExitProcess
main ENDP

END
